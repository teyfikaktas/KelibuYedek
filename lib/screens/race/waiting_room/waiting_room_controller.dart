// lib/screens/waiting_room/waiting_room_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/RoomService.dart';
import '../models/players.dart';

class WaitingRoomController extends GetxController {
  final RoomService roomService;
  final isLoading = true.obs;
  final roomId = 0.obs; // roomCode yerine roomId kullan, tamsayı olarak
  final players = <Player>[].obs;
  final gameStatus = 'waiting'.obs;
  final isHost = false.obs;

  late StreamSubscription _roomSubscription;
  late StreamSubscription _playersSubscription;

  WaitingRoomController({required this.roomService}) {
    final route = Get.rawRoute;
    if (route != null && route.settings.name != null) {
      final path = route.settings.name!;
      final idString = path.split('/').last; // "/waiting-room/41" -> "41"
      roomId.value = (int.tryParse(idString) ?? 0);
      print(
          'roomId: $roomId'); // Bu da çalışır çünkü .toString() otomatik çağrılır
    }
  }

  @override
  void onInit() {
    super.onInit();
    updateConnectionStatus(true);

    // Kullanıcının bu odaya erişimi olup olmadığını kontrol et
    _checkAccess().then((_) {
      if (Get.isRegistered<WaitingRoomController>()) {
        _initRoom();
      }
    });
  }

  void updateConnectionStatus(bool isConnected) {
    try {
      // roomId.value kullanarak int değerini doğru şekilde alın
      roomService.updatePlayerConnectionStatus(roomId.value, isConnected);
    } catch (e) {
    }
  }

  Future<void> _checkAccess() async {
    try {
      isLoading.value = true;

      final userId = roomService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Kullanıcı ID\'si alınamadı');
      }

      // Oda durumunu kontrol et
      final gameStatus = await roomService.getRoomGameStatus(roomId.value);

      if (gameStatus == 'in_progress' || gameStatus == 'completed') {
        // Oyun başlamış, kullanıcı daha önce odada mıydı kontrol et
        final wasInRoom =
            await roomService.wasPlayerInRoom(roomId.value, userId);

        if (wasInRoom) {
          // Kullanıcı önceden odadaydı, yeniden bağlan
          await roomService.reconnectToRoom(roomId.value, userId);

          // Oyun devam ediyorsa yarış ekranına yönlendir
          if (gameStatus == 'in_progress') {
            Get.offNamed('/race/${roomId.value}');
            return;
          }
        } else {
          // Kullanıcı daha önce odada değildi, erişimi reddet
          Get.snackbar(
            'Erişim Reddedildi',
            'Bu oyun zaten başlamış ve siz bu odanın bir üyesi değilsiniz.',
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red,
          );

          // Ana sayfaya yönlendir
          Get.offNamed('/home');
          return;
        }
      } else {
        // Oyun henüz başlamamış, kullanıcı daha önce odada mıydı kontrol et
        final wasInRoom =
            await roomService.wasPlayerInRoom(roomId.value, userId);

        if (wasInRoom) {
          // Kullanıcı daha önce odadaydı, yeniden bağlan
          await roomService.reconnectToRoom(roomId.value, userId);
        } else {
          // Kullanıcı yeni. Odaya normal katılma işlemine devam edilecek
        }
      }
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Oda bilgileri kontrol edilirken bir hata oluştu: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );

      // Hata durumunda ana sayfaya yönlendir
      Get.offNamed('/home');
    } finally {
      isLoading.value = false;
    }
  }

  bool get canStartGame {
    // 1. Sadece oda sahibi başlatabilir
    if (!isHost.value) return false;

    // 2. En az 2 oyuncu olmalı
    if (players.length < 2) return false;

    // 3. Tüm oyuncular hazır olmalı
    return players.every((player) => player.isReady);
  }

  Future<void> toggleReady() async {
    try {
      final userId = roomService.getCurrentUserId();
      if (userId == null) return;

      // Mevcut oyuncuyu bul
      final currentPlayer = players.firstWhere(
        (player) => player.userId == userId,
        orElse: () => throw Exception('Oyuncu bulunamadı'),
      );

      // Hazır durumunu tersine çevir
      await roomService.updatePlayerStatus(
          roomId.value, !currentPlayer.isReady);
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Durum güncellenirken bir hata oluştu',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> _initRoom() async {
    try {
      final userId = roomService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Kullanıcı ID\'si alınamadı');
      }

      isHost.value = await roomService.isRoomHostById(roomId.value, userId);

      _subscribeToRoom();
      _subscribeToPlayers();
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Oda bilgileri alınamadı: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToRoom() {
    _roomSubscription = roomService.subscribeToRoomById(roomId.value).listen(
      (room) {
        gameStatus.value = room.gameStatus;
        // started_at doluysa veya game_status in_progress ise yönlendir
        if (room.gameStatus == 'in_progress') {
          Get.offNamed('/race/${room.id}');
        }
      },
      onError: (error) {
        Get.snackbar('Hata', 'Oda bilgileri alınamadı: $error');
      },
    );
  }

  void _subscribeToPlayers() {
    _playersSubscription =
        roomService.subscribeToPlayersById(roomId.value).listen(
      (updatedPlayers) {
        print(
            'Received updated players for roomId ${roomId.value}: $updatedPlayers');
        players.value = updatedPlayers; // RxList’i güncelle
      },
      onError: (error) {
        Get.snackbar(
          'Hata',
          'Oyuncu bilgileri alınamadı: $error',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      },
    );
  }

  Future<void> startGame() async {
    try {
      final updateData = {
        'game_status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
      };

      // Önce güncellemeyi yap
      await Supabase.instance.client
          .from('rooms')
          .update(updateData)
          .eq('id', roomId.value);

      // Sonra güncellenmiş veriyi kontrol et
      final updatedRoom = await Supabase.instance.client
          .from('rooms')
          .select()
          .eq('id', roomId.value)
          .single();
      if (updatedRoom['game_status'] != 'in_progress') {
        throw Exception('Oda durumu güncellenemedi');
      }
      await Get.offAllNamed('/race/${roomId.value}');
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Oyun başlatılırken hata: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  @override
  @override
  void onClose() {
    final userId = roomService.getCurrentUserId();
    if (userId != null) {
      // Bağlantıyı takip et ama oyuncuyu odadan çıkarma
      roomService.trackPlayerConnection(roomId.value, userId);
    }
    updateConnectionStatus(false);
    _roomSubscription.cancel();
    _playersSubscription.cancel();
    super.onClose();
  }
}
