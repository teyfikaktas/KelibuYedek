// lib/screens/race/core/services/RoomService.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../global_user_id_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../models/players.dart';
import '../../models/room.dart';
import '../../waiting_room/waiting_room_controller.dart';

class RoomService {
  final SupabaseClient _supabaseClient;
  final UserProvider _userProvider;

  RoomService(this._supabaseClient, this._userProvider);

  /// Get.context üzerinden Riverpod container'ına erişip global user ID'yi döndürür.
  int? getCurrentUserId() {
    final context = Get.context;
    if (context == null) return null;
    final container = ProviderScope.containerOf(context);
    return container.read(globalUserIdProvider);
  }

  Future<Room> createRoom({
    required String roomCode,
    required int userId,
    required int playerCount,
  }) async {
    try {
      final response = await _supabaseClient
          .from('rooms')
          .insert({
        'room_code': roomCode,
        'created_by': userId,
        'status': 'active',
        'player_count': playerCount,
        'created_at': DateTime.now().toIso8601String(),
        'game_status': 'waiting',
        'current_round': 0,
      })
          .select()
          .single();

      await _supabaseClient.from('room_players').insert({
        'room_id': response['id'],
        'user_id': userId,
        'is_host': true,
        'joined_at': DateTime.now().toIso8601String(),
      });

      final room = Room.fromJson(response);
      print('Oda başarıyla oluşturuldu. Room ID: ${room.id}, Room Code: ${room.roomCode}');
      return room;
    } catch (e) {
      print('Oda oluşturma hatası detay: $e');
      throw Exception('Oda oluşturulurken bir hata oluştu: $e');
    }
  }

  Future<Room?> getRoomByCode(String roomCode) async {
    try {
      final response = await _supabaseClient
          .from('rooms')
          .select()
          .eq('room_code', roomCode)
          .single();

      if (response != null) {
        return Room.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Oda bulunurken hata: $e');
    }
  }

  Future<Room?> getRoomById(int roomId) async {
    try {
      final response = await _supabaseClient
          .from('rooms')
          .select()
          .eq('id', roomId)
          .single();

      if (response != null) {
        return Room.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Oda bulunurken hata: $e');
    }
  }

  Future<List<Room>> getUserRooms(String userId) async {
    try {
      final response = await _supabaseClient
          .from('rooms')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      return (response as List).map((room) => Room.fromJson(room)).toList();
    } catch (e) {
      throw Exception('Odalar listelenirken hata: $e');
    }
  }
  Future<bool> wasPlayerInRoom(int roomId, int userId) async {
    try {
      // room_players tablosunda bu oda ve kullanıcı için kayıt var mı diye kontrol et
      final result = await _supabaseClient
          .from('room_players')
          .select()
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();

      // Sonuç null değilse, oyuncu daha önce odadaydı
      return result != null;
    } catch (e) {
      print('wasPlayerInRoom hatası: $e');
      return false; // Hata durumunda false dön
    }
  }

// Odanın oyun durumunu kontrol eder
  Future<String> getRoomGameStatus(int roomId) async {
    try {
      final result = await _supabaseClient
          .from('rooms')
          .select('game_status')
          .eq('id', roomId)
          .single();

      return result['game_status'] as String;
    } catch (e) {
      print('getRoomGameStatus hatası: $e');
      throw Exception('Oda durumu alınamadı: $e');
    }
  }

// Oyuncunun oturumunu yeniden açar
  Future<void> reconnectToRoom(int roomId, int userId) async {
    try {
      // Oyuncu durumunu aktif olarak işaretle
      await _supabaseClient
          .from('room_players')
          .update({
        'is_connected': true,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('room_id', roomId)
          .eq('user_id', userId);

      print('Oyuncu $userId odaya $roomId yeniden bağlandı');
    } catch (e) {
      print('reconnectToRoom hatası: $e');
      throw Exception('Odaya yeniden bağlanılamadı: $e');
    }
  }

// Oyuncu bağlantı durumunu takip etmek için metot
  void trackPlayerConnection(int roomId, int userId) {
    // Uygulama kapatıldığında veya sayfa değiştirildiğinde çağrılacak
    onClose() async {
      try {
        // Oyuncu durumunu güncelle, ancak silme
        await _supabaseClient
            .from('room_players')
            .update({
          'is_connected': false,
          'updated_at': DateTime.now().toIso8601String()
        })
            .eq('room_id', roomId)
            .eq('user_id', userId);

        print('Oyuncu $userId bağlantısı kesildi');
      } catch (e) {
        print('trackPlayerConnection onClose hatası: $e');
      }
    }
  }
  Future<void> updateRoomStatus(int roomId, String status) async {
    try {
      await _supabaseClient
          .from('rooms')
          .update({'status': status})
          .eq('id', roomId);
    } catch (e) {
      throw Exception('Oda durumu güncellenirken hata: $e');
    }
  }

  Future<void> updatePlayerCount(int roomId, int playerCount) async {
    try {
      await _supabaseClient
          .from('rooms')
          .update({'player_count': playerCount})
          .eq('id', roomId);
    } catch (e) {
      throw Exception('Oyuncu sayısı güncellenirken hata: $e');
    }
  }

  Stream<Room> subscribeToRoom(String roomCode) {
    return _supabaseClient
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('room_code', roomCode)
        .map((data) => Room.fromJson(data.first));
  }

  Stream<Room> subscribeToRoomById(int roomId) {
    print('Subscribing to room updates for roomId: $roomId');
    return _supabaseClient
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .map((data) {
      print('Raw data from rooms stream: $data');
      return Room.fromJson(data.first);
    });
  }
  Stream<List<Player>> subscribeToPlayers(String roomCode) async* {
    try {
      final room = await getRoomByCode(roomCode);
      if (room == null) throw Exception('Oda bulunamadı');

      yield* _supabaseClient
          .from('room_players_with_users')
          .stream(primaryKey: ['rp_id'])
          .eq('room_id', room.id)
          .map((data) => data.map((json) => Player.fromJson(json)).toList());
    } catch (e) {
      throw Exception('Oyuncu listesi alınamadı: $e');
    }
  }
  Future<void> updatePlayerConnectionStatus(int roomId, bool isConnected) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Kullanıcı ID\'si alınamadı');

    try {
      await _supabaseClient
          .from('room_players')
          .update({
        'is_connected': isConnected,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('room_id', roomId)
          .eq('user_id', userId);

      print('Oyuncu $userId bağlantı durumu: ${isConnected ? "bağlı" : "bağlantı kesildi"}');
    } catch (e) {
      print('updatePlayerConnectionStatus hatası: $e');
      throw Exception('Bağlantı durumu güncellenirken hata oluştu: $e');
    }
  }
  Stream<List<Player>> subscribeToPlayersById(int roomId) {
    final channel = _supabaseClient.channel('room_players_room_$roomId');

    // Ana stream için düzeltilmiş sorgu - join kullanarak
    final mainStream = _supabaseClient
        .from('room_players')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((data) async {
      final List<Player> players = [];
      for (var playerData in data) {
        try {
          // Her oyuncu için user bilgilerini al
          final userResponse = await _supabaseClient
              .from('users')
              .select()
              .eq('id', playerData['user_id'])
              .maybeSingle();

          final username = userResponse?['name'] ?? 'Bilinmeyen Kullanıcı';
          final avatar = userResponse?['avatar'];

          players.add(Player(
            id: playerData['id'],
            roomId: roomId,
            userId: playerData['user_id'],
            joinedAt: DateTime.parse(playerData['joined_at']),
            score: playerData['score'] ?? 0,
            isReady: playerData['is_ready'] ?? false,
            isHost: playerData['is_host'] ?? false,
            username: username,
            avatar: avatar,
          ));
        } catch (e) {
          print('User bilgisi alınırken hata: $e');
          // Hata durumunda bile oyuncuyu ekle
          players.add(Player(
            id: playerData['id'],
            roomId: roomId,
            userId: playerData['user_id'],
            joinedAt: DateTime.parse(playerData['joined_at']),
            score: playerData['score'] ?? 0,
            isReady: playerData['is_ready'] ?? false,
            isHost: playerData['is_host'] ?? false,
            username: 'Bilinmeyen Kullanıcı',
            avatar: null,
          ));
        }
      }
      return players;
    })
        .asyncMap((future) => future);

    // Realtime updates için channel'ı subscribe et
    channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'room_players',
        filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId
        ),
        callback: (payload) async {
          try {
            final data = payload.newRecord as Map<String, dynamic>?;
            if (data != null) {
              final userId = data['user_id'] as int;
              final userResponse = await _supabaseClient
                  .from('users')
                  .select()
                  .eq('id', userId)
                  .maybeSingle();

              final username = userResponse?['name'] ?? 'Bilinmeyen Kullanıcı';
              final avatar = userResponse?['avatar'];

              final player = Player(
                id: data['id'],
                roomId: roomId,
                userId: userId,
                joinedAt: DateTime.parse(data['joined_at']),
                score: data['score'] ?? 0,
                isReady: data['is_ready'] ?? false,
                isHost: data['is_host'] ?? false,
                username: username,
                avatar: avatar,
              );

              final controller = Get.find<WaitingRoomController>();
              final currentPlayers = controller.players.toList();
              final existingPlayerIndex = currentPlayers.indexWhere((p) => p.userId == player.userId);

              if (existingPlayerIndex != -1) {
                currentPlayers[existingPlayerIndex] = player;
              } else {
                currentPlayers.add(player);
              }
              controller.players.value = currentPlayers;
            }
          } catch (e) {
            print('Realtime player update hatası: $e');
          }
        }
    );

    channel.subscribe();
    print('Room $roomId için player subscription başlatıldı');

    return mainStream;
  }
  Future<void> updatePlayerStatus(int roomId, bool isReady) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Kullanıcı ID\'si alınamadı');

    try {
      await _supabaseClient
          .from('room_players')
          .update({'is_ready': isReady})
          .eq('room_id', roomId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Oyuncu durumu güncellenirken hata: $e');
    }
  }

  Future<void> startGame(String roomCode) async {
    try {
      await _supabaseClient
          .from('rooms')
          .update({
        'game_status': 'in_progress',
        'start_time': DateTime.now().toIso8601String(),
        'current_round': 1,
      })
          .eq('room_code', roomCode);
    } catch (e) {
      throw Exception('Oyun başlatılırken hata: $e');
    }
  }

  Future<void> startGameById(int roomId) async {
    try {
      await _supabaseClient
          .from('rooms')
          .update({
        'game_status': 'in_progress',
        'start_time': DateTime.now().toIso8601String(),
        'current_round': 1,
      })
          .eq('id', roomId);
    } catch (e) {
      throw Exception('Oyun başlatılırken hata: $e');
    }
  }

  Future<bool> isRoomHostById(int roomId, int userId) async {
    try {
      final response = await _supabaseClient
          .from('room_players')
          .select()
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .eq('is_host', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Oda sahibi kontrolü yapılırken hata: $e');
    }
  }

  Future<bool> isRoomHostByCode(String roomCode, int userId) async {
    try {
      final room = await getRoomByCode(roomCode);
      if (room == null) throw Exception('Oda bulunamadı');

      return isRoomHostById(room.id, userId);
    } catch (e) {
      throw Exception('Oda sahibi kontrolü yapılırken hata: $e');
    }
  }

  Future<void> joinRoom(String roomCode) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Kullanıcı ID\'si alınamadı');

    try {
      final room = await getRoomByCode(roomCode);
      if (room == null) throw Exception('Oda bulunamadı');

      // Kullanıcının daha önce odada olup olmadığını kontrol et
      final existingRecord = await _supabaseClient
          .from('room_players')
          .select()
          .eq('room_id', room.id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingRecord != null) {
        // Kullanıcı zaten odadaysa, sadece bağlantı durumunu güncelle
        print('Kullanıcı $userId zaten odada, bağlantı durumu güncelleniyor');
        await _supabaseClient
            .from('room_players')
            .update({
          'is_connected': true,
          'updated_at': DateTime.now().toIso8601String()
        })
            .eq('room_id', room.id)
            .eq('user_id', userId);
        return;
      }

      // Kullanıcı odada değilse, odada yer olup olmadığını kontrol et
      final currentPlayers = await _supabaseClient
          .from('room_players')
          .select('id')
          .eq('room_id', room.id);

      if ((currentPlayers as List).length >= room.playerCount) {
        throw Exception('Oda dolu');
      }

      // Yeni oyuncuyu ekle
      await _supabaseClient.from('room_players').insert({
        'room_id': room.id,
        'user_id': userId,
        'is_host': false,
        'joined_at': DateTime.now().toIso8601String(),
        'is_connected': true,
        'updated_at': DateTime.now().toIso8601String()
      });
    } catch (e) {
      print('Odaya katılırken hata: $e');
      throw Exception('Odaya katılırken hata: $e');
    }
  }
  Future<void> joinRoomById(int roomId) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Kullanıcı ID\'si alınamadı');

    try {
      final room = await getRoomById(roomId);
      if (room == null) throw Exception('Oda bulunamadı');

      // Kullanıcının daha önce odada olup olmadığını kontrol et
      final existingRecord = await _supabaseClient
          .from('room_players')
          .select()
          .eq('room_id', room.id)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingRecord != null) {
        // Kullanıcı zaten odadaysa, sadece bağlantı durumunu güncelle
        print('Kullanıcı $userId zaten odada, bağlantı durumu güncelleniyor');
        await _supabaseClient
            .from('room_players')
            .update({
          'is_connected': true,
          'updated_at': DateTime.now().toIso8601String()
        })
            .eq('room_id', room.id)
            .eq('user_id', userId);
        return;
      }

      // Kullanıcı odada değilse, odada yer olup olmadığını kontrol et
      final currentPlayers = await _supabaseClient
          .from('room_players')
          .select('id')
          .eq('room_id', room.id);
      print('Current players in room $roomId: ${currentPlayers.length}');

      if ((currentPlayers as List).length >= room.playerCount) {
        throw Exception('Oda dolu');
      }

      // Yeni oyuncuyu ekle
      print('Inserting new player with userId: $userId into room $roomId');
      await _supabaseClient.from('room_players').insert({
        'room_id': room.id,
        'user_id': userId,
        'is_host': false,
        'joined_at': DateTime.now().toIso8601String(),
        'is_connected': true,
        'updated_at': DateTime.now().toIso8601String()
      });
      print('Player inserted successfully');
    } catch (e) {
      print('Error joining room: $e');
      throw Exception('Odaya katılırken hata: $e');
    }
  }
  Future<void> leaveRoom(int roomId) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Kullanıcı ID\'si alınamadı');

    try {
      final isHost = await isRoomHostById(roomId, userId);

      await _supabaseClient
          .from('room_players')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', userId);

      if (isHost) {
        await updateRoomStatus(roomId, 'closed');
      }
    } catch (e) {
      throw Exception('Odadan çıkarken hata: $e');
    }
  }
}