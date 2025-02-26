import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/RoomService.dart';
import '../models/question.dart';

class RaceController extends GetxController {
  final RoomService roomService;
  final _supabase = Supabase.instance.client;

  // Oyun durumu
  final roomId = 0.obs;
  final isWaitingForPlayers = true.obs;
  final connectedPlayers = <int>[].obs;
  final gameStarted = false.obs;

  // Soru ve skor durumu
  final currentQuestionIndex = 0.obs;
  final questions = <Question>[].obs;
  final playerScores = <int, PlayerScore>{}.obs;

  // Cevap kontrol durumu
  final showAnswer = false.obs;
  final selectedAnswer = (-1).obs;
  final isAnswerCorrect = false.obs;

  // Stream subscriptions
  StreamSubscription? _gameStateSubscription;

  RaceController({required this.roomService}) {
    print('RaceController constructor çağrıldı');
    try {
      final routeParams = Get.parameters;
      if (!routeParams.containsKey('roomId')) {
        throw Exception('roomId parametresi bulunamadı');
      }

      final parsedRoomId = int.tryParse(routeParams['roomId']!);
      if (parsedRoomId == null) {
        throw Exception('Geçersiz roomId formatı');
      }

      roomId.value = parsedRoomId;
      print('roomId değeri ayarlandı: ${roomId.value}');

    } catch (e) {
      print('Constructor hata: $e');
      throw Exception('RaceController başlatılamadı: $e');
    }
  }
  @override
  void onInit() {
    super.onInit();
    print('RaceController onInit çağrıldı');

    // Kullanıcının bu yarışa erişimi olup olmadığını kontrol et
    _checkRaceAccess().then((_) {
      if (Get.isRegistered<RaceController>()) {
        _initializeGame().then((_) {
          _subscribeToGameState();
        });
      }
    });
  }

  Future<void> _checkRaceAccess() async {
    try {
      print('Yarış erişimi kontrol ediliyor, roomId: ${roomId.value}');

      final userId = roomService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Kullanıcı ID\'si alınamadı');
      }

      // Kullanıcının odada önceden var olup olmadığını kontrol et
      final wasInRoom = await roomService.wasPlayerInRoom(roomId.value, userId);

      if (!wasInRoom) {
        // Kullanıcı daha önce odada değildi, erişimi reddet
        Get.snackbar(
          'Erişim Reddedildi',
          'Bu yarışa katılma yetkiniz yok.',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );

        // Ana sayfaya yönlendir
        Get.offNamed('/home');
        return;
      }

      // Kullanıcı odada, yeniden bağlan
      await roomService.reconnectToRoom(roomId.value, userId);

      // Kullanıcının mevcut oyun durumunu kontrol et
      final scores = await _supabase
          .from('race_scores')
          .select()
          .eq('room_id', roomId.value)
          .eq('player_id', userId)
          .maybeSingle();

      if (scores != null) {
        // Kullanıcının mevcut soru indeksi ve skorunu ayarla
        currentQuestionIndex.value = scores['current_question_index'] as int;

        print('Kullanıcı kaldığı yerden devam ediyor: Soru ${currentQuestionIndex.value + 1}');
      }

    } catch (e) {
      print('Yarış erişimi kontrol hatası: $e');
      Get.snackbar(
        'Hata',
        'Yarış bilgileri kontrol edilirken bir hata oluştu: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );

      // Hata durumunda ana sayfaya yönlendir
      Get.offNamed('/home');
    }
  }
  Future<void> _initializeGame() async {
    try {
      print('_initializeGame başlatılıyor, roomId: ${roomId.value}');

      // 1. Soruları yükle
      final questionsData = await _supabase
          .from('questions')
          .select()
          .limit(10);

      if (questionsData.isEmpty) {
        throw Exception('Soru bulunamadı');
      }
      questions.value = questionsData.map((q) => Question.fromJson(q)).toList();

      // 2. Odadaki oyuncuları al
      final players = await _supabase
          .from('room_players')
          .select('user_id')
          .eq('room_id', roomId.value);

      if (players.isEmpty) {
        throw Exception('Oyuncu bulunamadı');
      }

      // 3. Mevcut race_scores kayıtlarını al
      final existingScores = await _supabase
          .from('race_scores')
          .select()
          .eq('room_id', roomId.value);

      // Mevcut skorları bir Map'e dönüştür
      final Map<int, Map<String, dynamic>> scoresByPlayerId = {};
      for (final score in existingScores) {
        scoresByPlayerId[score['player_id'] as int] = score;
      }

      // 4. Her oyuncu için skorları güncelle veya oluştur
      for (final player in players) {
        final playerId = player['user_id'];

        if (scoresByPlayerId.containsKey(playerId)) {
          // Oyuncunun skoru zaten var, yalnızca playerScores state'ini güncelle
          final existingScore = scoresByPlayerId[playerId]!;
          playerScores[playerId] = PlayerScore(
            currentQuestionIndex: existingScore['current_question_index'],
            score: existingScore['score'],
          );
        } else {
          // Oyuncu için yeni skor kaydı oluştur
          try {
            await _supabase
                .from('race_scores')
                .insert({
              'room_id': roomId.value,
              'player_id': playerId,
              'score': 0,
              'current_question_index': 0,
            });

            // Yerel state güncelleme
            playerScores[playerId] = PlayerScore(
              currentQuestionIndex: 0,
              score: 0,
            );
          } catch (insertError) {
            print('Oyuncu $playerId için insert hatası: $insertError');
            // Burada hata yönetimi ekleyebilirsiniz
          }
        }
      }

      // UI'ı güncellemek için
      playerScores.refresh();
      print('Oyun başarıyla başlatıldı - Oda: ${roomId.value}');

    } catch (e) {
      print('_initializeGame hatası: $e');
      print('Stack trace: ${StackTrace.current}');
      Get.snackbar(
        'Hata',
        'Oyun başlatılırken bir hata oluştu: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 5),
      );
      Future.delayed(const Duration(seconds: 1), () => Get.back());
    }
  }
  void _subscribeToGameState() {
    try {
      print('Game state subscription başlatılıyor...');
      _gameStateSubscription = _supabase
          .from('race_scores')
          .stream(primaryKey: ['id'])
          .eq('room_id', roomId.value)
          .listen(
            (List<Map<String, dynamic>> event) {
          print('Game state event alındı: $event');
          if (event.isNotEmpty) {
            // Bağlı oyuncuları güncelle
            connectedPlayers.value = event.map((e) => e['player_id'] as int).toList();

            // Her oyuncunun skorunu güncelle
            for (var scoreData in event) {
              final playerId = scoreData['player_id'] as int;
              final score = scoreData['score'] as int;
              final questionIndex = scoreData['current_question_index'] as int;

              // Yerel state'i güncelle
              playerScores[playerId] = PlayerScore(
                  currentQuestionIndex: questionIndex,
                  score: score
              );
            }

            // UI'ı强制 yenile
            playerScores.refresh();

            // Eğer bir oyuncu son soruya ulaştıysa
            final maxQuestionIndex = event
                .map((e) => e['current_question_index'] as int)
                .reduce(max);

            if (maxQuestionIndex >= questions.length) {
              print('Bir oyuncu oyunu tamamladı');
              Get.offNamed('/race-results/${roomId.value}');
              return;
            }
          }
        },
        onError: (error) {
          print('Game state subscription hatası: $error');
          Get.snackbar(
            'Bağlantı Hatası',
            'Oyun durumu güncellenirken hata oluştu',
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red,
          );
        },
      );
    } catch (e) {
      print('_subscribeToGameState hatası: $e');
    }
  }

  void _startGame() {
    print('Oyun başlatılıyor...');
    gameStarted.value = true;
  }

  Future<String> getPlayerName(int playerId) async {
    try {
      print('Oyuncu ismi alınıyor, playerId: $playerId');
      final response = await _supabase
          .from('users')
          .select('name')
          .eq('id', playerId)
          .single();
      print('Oyuncu ismi alındı: ${response['name']}');
      return response['name'];
    } catch (e) {
      print('getPlayerName hatası: $e');
      return 'Oyuncu';
    }
  }

  Question getCurrentQuestion() {
    if (questions.isEmpty || currentQuestionIndex.value >= questions.length) {
      print('HATA: Geçerli soru bulunamadı');
      throw Exception('Geçerli soru bulunamadı');
    }
    return questions[currentQuestionIndex.value];
  }

  Future<void> submitAnswer(int selectedIndex) async {
    try {
      if (showAnswer.value) return;

      final userId = roomService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Kullanıcı ID bulunamadı');
      }

      final question = getCurrentQuestion();
      final isCorrect = selectedIndex == question.correctOptionIndex;

      // UI güncelleme
      selectedAnswer.value = selectedIndex;
      isAnswerCorrect.value = isCorrect;
      showAnswer.value = true;

      // Yeni skor hesaplama
      final currentScore = playerScores[userId]?.score ?? 0;
      final newScore = isCorrect ? currentScore + 10 : currentScore;
      final nextQuestionIndex = currentQuestionIndex.value + 1;

      try {
        // Skor güncellemesi
        await _supabase
            .from('race_scores')
            .update({
          'score': newScore,
          'current_question_index': nextQuestionIndex,
        })
            .eq('room_id', roomId.value)
            .eq('player_id', userId);

        // Yerel state güncelleme
        playerScores[userId] = PlayerScore(
            currentQuestionIndex: nextQuestionIndex,
            score: newScore
        );
        playerScores.refresh();

      } catch (e) {
        print('Skor güncelleme hatası: $e');
        throw Exception('Skor güncellenemedi: $e');
      }

      // Sonraki soruya geçiş
      await Future.delayed(const Duration(seconds: 2));

      // UI sıfırlama
      showAnswer.value = false;
      selectedAnswer.value = -1;
      currentQuestionIndex.value = nextQuestionIndex;

      // Oyun bitti mi kontrolü
      if (currentQuestionIndex.value >= questions.length) {
        print('Oyun tamamlandı, sonuç ekranına yönlendiriliyor');
        Get.offNamed('/race-results/${roomId.value}');
        return;
      }

    } catch (e) {
      print('submitAnswer hatası: $e');
      Get.snackbar(
        'Hata',
        'Cevap gönderilirken bir hata oluştu',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }
  Future<void> leaveGame() async {
    try {
      final userId = roomService.getCurrentUserId();
      if (userId == null) return;

      // Stream subscription'ı iptal et
      _gameStateSubscription?.cancel();

      // Oyuncuyu odadan çıkarma, sadece bağlantı durumunu güncelle
      await _supabase
          .from('room_players')
          .update({
        'is_connected': false,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('room_id', roomId.value)
          .eq('user_id', userId);

      Get.offAllNamed('/home'); // Ana sayfaya yönlendir
    } catch (e) {
      print('Oyundan çıkış hatası: $e');
      Get.snackbar(
        'Hata',
        'Oyundan çıkarken bir hata oluştu',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }
  @override
  void onClose() {
    _gameStateSubscription?.cancel();
    super.onClose();
  }
}

class PlayerScore {
  final int currentQuestionIndex;
  final int score;

  PlayerScore({
    required this.currentQuestionIndex,
    required this.score,
  });
}