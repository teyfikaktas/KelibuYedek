import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/RoomService.dart';
import '../models/question.dart';

class RaceController extends GetxController {
  final RoomService roomService;
  final _supabase = Supabase.instance.client;
  Timer? _lastPlayerTimer;
  final isLastPlayerTimerActive = false.obs;
  final lastPlayerTimeLeft = 30.obs;
  final showVictoryMessage = false.obs;
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
  final playerConnectionStatus = <int, bool>{}.obs;

  // Stream subscriptionsfinal playerConnectionStatus = <int, bool>{}.obs;
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
    SystemChannels.lifecycle.setMessageHandler((msg) {
      print('Lifecycle message: $msg');
      if (msg == AppLifecycleState.paused.toString()) {
        _updateConnectionStatus(false);
      } else if (msg == AppLifecycleState.resumed.toString()) {
        _updateConnectionStatus(true);
      }
      return Future.value(msg);
    });
  }
  Future<void> _updateConnectionStatus(bool isConnected) async {
    try {
      final userId = roomService.getCurrentUserId();
      if (userId == null) return;

      await _supabase
          .from('room_players')
          .update({
        'is_connected': isConnected,
        'last_activity': DateTime.now().toIso8601String()
      })
          .eq('room_id', roomId.value)
          .eq('user_id', userId);

      print('Bağlantı durumu güncellendi: $isConnected');
    } catch (e) {
      print('Bağlantı durumu güncelleme hatası: $e');
    }
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
  Future<void> leaveGame() async {
    try {
      final userId = roomService.getCurrentUserId();
      if (userId == null) return;

      // Eğer tek oyuncu kaldıysa ve zamanlayıcı aktifse, önce zamanlayıcıyı durdur
      if (isLastPlayerTimerActive.value) {
        _lastPlayerTimer?.cancel();
        _lastPlayerTimer = null;
        isLastPlayerTimerActive.value = false;
      }

      // Stream subscription'ları iptal et
      _gameStateSubscription?.cancel();
      _connectionSubscription?.cancel();

      // İstenilen yola yönlendir: /race
      Get.offNamed('/race');

      // Oyuncuyu odadan çıkarma, bağlantı durumunu güncelle
      await _supabase
          .from('room_players')
          .update({
        'is_connected': false,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('room_id', roomId.value)
          .eq('user_id', userId);

      // Odadaki aktif oyuncu sayısı kontrolü
      final activePlayers = await _supabase
          .from('room_players')
          .select('user_id, is_host')
          .eq('room_id', roomId.value)
          .eq('is_connected', true);

      // Çıkan kişi host mu kontrol et
      final isUserHost = await _supabase
          .from('room_players')
          .select('is_host')
          .eq('room_id', roomId.value)
          .eq('user_id', userId)
          .single();

      final bool isHost = isUserHost['is_host'] ?? false;

      // Eğer çıkan kişi host ise veya hiç aktif oyuncu kalmadıysa odayı kapat
      if (isHost || activePlayers.isEmpty) {
        print('Host ayrıldı veya odada yeterli aktif oyuncu kalmadı, oda kapatılıyor...');

        // Rooms tablosunda status ve game_status alanlarını güncelle
        await _supabase
            .from('rooms')
            .update({
          'status': 'closed',
          'game_status': 'finished',
          'updated_at': DateTime.now().toIso8601String()
        })
            .eq('id', roomId.value);

        print('Oda başarıyla kapatıldı: ${roomId.value}');
      }
      // Eğer ayrılan kişi host ise ve odada başka oyuncular varsa, host'u devret
      else if (isHost && activePlayers.isNotEmpty) {
        final newHostId = activePlayers[0]['user_id'];

        await _supabase
            .from('room_players')
            .update({
          'is_host': true,
          'updated_at': DateTime.now().toIso8601String()
        })
            .eq('room_id', roomId.value)
            .eq('user_id', newHostId);

        print('Host rolü $newHostId ID\'li kullanıcıya devredildi');
      }

      // İsteğe bağlı olarak başarılı çıkış mesajı gösterebilirsiniz
      Get.snackbar(
        'Oyundan Çıkıldı',
        'Başarıyla oyundan ayrıldınız.',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Oyundan çıkış hatası: $e');
      Get.snackbar(
        'Hata',
        'Oyundan çıkarken bir hata oluştu: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );

      // Hata durumunda da '/race' sayfasına yönlendir
      if (Get.isDialogOpen == true) {
        Get.back(); // Dialog açıksa kapat
      }
      Get.offNamed('/race');
    }
  }  Future<void> loadAllPlayerConnectionStatuses() async {
    try {
      final players = await _supabase
          .from('room_players')
          .select('user_id, is_connected')
          .eq('room_id', roomId.value);

      for (final player in players) {
        final playerId = player['user_id'] as int;
        final isConnected = player['is_connected'] as bool;
        playerConnectionStatus[playerId] = isConnected;
      }

      playerConnectionStatus.refresh();
    } catch (e) {
      print('Oyuncu bağlantı durumları yükleme hatası: $e');
    }
  }
  Future<bool> isPlayerConnected(int playerId) async {
    try {
      final player = await _supabase
          .from('room_players')
          .select('is_connected')
          .eq('room_id', roomId.value)
          .eq('user_id', playerId)
          .single();

      final isConnected = player['is_connected'] as bool;
      playerConnectionStatus[playerId] = isConnected;
      return isConnected;
    } catch (e) {
      print('Oyuncu bağlantı durumu kontrolü hatası: $e');
      return false;
    }
  }

    Future<void> _initializeGame() async {
    try {
      print('_initializeGame başlatılıyor, roomId: ${roomId.value}');
      await loadAllPlayerConnectionStatuses();

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

      // Race scores tablosunu dinle (mevcut kod)
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

            // UI'ı yenile
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

      // Yeni: Bağlantı durumlarını izle
      _connectionSubscription = _supabase
          .from('room_players')
          .stream(primaryKey: ['id'])
          .eq('room_id', roomId.value)
          .listen(
            (List<Map<String, dynamic>> players) {
          print('Connection state event alındı: $players');

          if (players.isEmpty) return;

          // Bağlı oyuncuları filtrele
          final activePlayers = players.where((p) => p['is_connected'] == true).toList();
          final currentUserId = roomService.getCurrentUserId();

          // Ayrılan oyuncuları tespit et
          for (var player in players) {
            if (player['is_connected'] == false &&
                !_disconnectedPlayerIds.contains(player['user_id'])) {

              _disconnectedPlayerIds.add(player['user_id']);

              // Oyuncu ismini al ve bildirim göster
              getPlayerName(player['user_id']).then((playerName) {
                Get.snackbar(
                  'Oyuncu Ayrıldı',
                  '$playerName odadan ayrıldı.',
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  colorText: Colors.orange,
                  duration: const Duration(seconds: 3),
                );
              });
            }
          }

          // Aktif oyuncu sayısını kontrol et
          if (activePlayers.length == 1 && activePlayers[0]['user_id'] == currentUserId) {
            // Tek oyuncu kaldı, zamanlayıcıyı başlat
            _handleLastPlayerStanding();
          } else {
            // Birden fazla oyuncu var, zamanlayıcıyı iptal et
            _cancelLastPlayerTimer();
          }
        },
        onError: (error) {
          print('Connection subscription hatası: $error');
        },
      );
    } catch (e) {
      print('_subscribeToGameState hatası: $e');
    }
  }
  final _disconnectedPlayerIds = <int>{};
  void _handleLastPlayerStanding() {
    if (_lastPlayerTimer != null) return; // Zaten aktif bir zamanlayıcı varsa

    print('Son oyuncu kaldı, zamanlayıcı başlatılıyor...');
    isLastPlayerTimerActive.value = true;
    lastPlayerTimeLeft.value = 30;

    // Kullanıcıya bildir
    Get.snackbar(
      'Son Oyuncu',
      'Odada tek kaldınız. 30 saniye boyunca odaya dahil olan bir kişi olmazsa kazanan olarak ilan edileceksiniz ve oda kapanacaktır.',
      backgroundColor: Colors.blue.withOpacity(0.1),
      colorText: Colors.blue,
      duration: const Duration(seconds: 5),
    );

    // Zamanlayıcıyı başlat
    _lastPlayerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      lastPlayerTimeLeft.value--;

      if (lastPlayerTimeLeft.value <= 0) {
        _declareVictory();
        timer.cancel();
        _lastPlayerTimer = null;
      }
    });
  }
  void _cancelLastPlayerTimer() {
    if (_lastPlayerTimer != null) {
      _lastPlayerTimer!.cancel();
      _lastPlayerTimer = null;
      isLastPlayerTimerActive.value = false;

      // Eğer aktifse kullanıcıya bildiri
      if (isLastPlayerTimerActive.value) {
        Get.snackbar(
          'Oyun Devam Ediyor',
          'Odaya yeni bir oyuncu katıldı. Oyun devam ediyor!',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

// Zafer ilan eden metod
// _declareVictory metodunu güncelleyelim
  void _declareVictory() async {
    try {
      final userId = roomService.getCurrentUserId();
      if (userId == null) return;

      showVictoryMessage.value = true;

      // Kullanıcıya bildir
      Get.dialog(
        AlertDialog(
          backgroundColor: const Color(0xFF242424),
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Text(
                'Tebrikler!',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'Diğer oyuncular ayrıldı. Kazanan olarak ilan edildiniz!',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Get.offNamed('/race-results/${roomId.value}');
              },
              child: const Text(
                'Sonuçlara Git',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      // Odayı kapat - game_status değeri için doğru enum değerini kullan
      await _supabase
          .from('rooms')
          .update({
        'game_status': 'finished',  // 'closed' yerine 'finished' kullanıyoruz
        'status': 'closed',  // status kolonunu da güncelle
        'winner_id': userId,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('id', roomId.value);

      print('Oda başarıyla kapatıldı: ${roomId.value}');

      // Race scores'u da güncelle - kullanıcının kazandığını işaretle
      await _supabase
          .from('race_scores')
          .update({
        'is_winner': true,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('room_id', roomId.value)
          .eq('player_id', userId);

    } catch (e) {
      print('Zafer ilan etme hatası: $e');
      Get.snackbar(
        'Hata',
        'Oyun sonucu kaydedilirken bir hata oluştu',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }// Yeni bir değişken - bağlantı durumu stream subscription
  StreamSubscription? _connectionSubscription;
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
  @override
  void onClose() {
    _gameStateSubscription?.cancel();
    _connectionSubscription?.cancel();
    _lastPlayerTimer?.cancel();
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