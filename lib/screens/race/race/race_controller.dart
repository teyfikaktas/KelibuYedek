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
  Timer? _connectionUpdateTimer;

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
    print('RaceController onInit çağrıldı - Oda ID: ${roomId.value}');

    // Tüm veri yapılarını sıfırla
    _resetAllData();

    // BuildContext içinde async çağrı yapmak yerine, önce init tamamlansın
    // ve sonra async işlemleri çalıştıralım
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Kullanıcının bu yarışa erişimi olup olmadığını kontrol et
      _checkRaceAccess().then((_) {
        if (Get.isRegistered<RaceController>()) {
          _initializeGame().then((_) {
            _subscribeToGameState();
          });
        }
      });
    });
    _connectionUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      updateRaceScoreConnectionStatus(true);
    });
    // Uygulama durumu değiştiğinde race_scores tablosundaki bağlantı durumunu güncelle
    SystemChannels.lifecycle.setMessageHandler((msg) {
      print('Lifecycle message: $msg');
      if (msg == AppLifecycleState.paused.toString()) {
        updateRaceScoreConnectionStatus(false);
      } else if (msg == AppLifecycleState.resumed.toString()) {
        updateRaceScoreConnectionStatus(true);
      }
      return Future.value(msg);
    });
    _resetAllConnectionStatuses();

  }

  void _resetAllData() {
    print('RaceController verileri sıfırlanıyor');

    // Soru ve skor durumunu sıfırla
    currentQuestionIndex.value = 0;
    questions.clear();
    playerScores.clear();

    // Cevap kontrol durumunu sıfırla
    showAnswer.value = false;
    selectedAnswer.value = -1;
    isAnswerCorrect.value = false;

    // Bağlantı durumlarını sıfırla
    playerConnectionStatus.clear();
    connectedPlayers.clear();

    // Diğer durumları sıfırla
    isWaitingForPlayers.value = true;
    gameStarted.value = false;
    isLastPlayerTimerActive.value = false;
    lastPlayerTimeLeft.value = 30;
    showVictoryMessage.value = false;

    // Zamanlayıcıyı da iptal et
    _lastPlayerTimer?.cancel();
    _lastPlayerTimer = null;

    // Ayrılmış oyuncular listesini temizle
    _disconnectedPlayerIds.clear();

    update(); // GetBuilder için state güncelleme
  }  Future<void> _updateConnectionStatus(bool isConnected) async {
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

      print('Oyundan çıkılıyor - Oda ID: ${roomId.value}');

      // Eğer tek oyuncu kaldıysa ve zamanlayıcı aktifse, önce zamanlayıcıyı durdur
      if (isLastPlayerTimerActive.value) {
        _lastPlayerTimer?.cancel();
        _lastPlayerTimer = null;
        isLastPlayerTimerActive.value = false;
      }

      // Stream subscription'ları iptal et
      _gameStateSubscription?.cancel();
      _connectionSubscription?.cancel();

      // Race scores bağlantı durumunu false yap
      await updateRaceScoreConnectionStatus(false);

      // Önce GetX geçmişini temizleyelim
      Get.delete<RaceController>();

      // İstenilen yola yönlendir: /race
      Get.offNamed('/race');

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
  }
  Future<void> loadAllPlayerConnectionStatuses() async {
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
  Future<void> updateRaceScoreConnectionStatus(bool isConnected) async {
    try {
      final userId = roomService.getCurrentUserId();
      if (userId == null) return;

      // Sadece race_scores tablosunu güncelle, room_players'a dokunma
      await _supabase
          .from('race_scores')
          .update({
        'is_connected': isConnected,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('room_id', roomId.value)
          .eq('player_id', userId);

      print('Oyuncu $userId race_scores bağlantı durumu güncellendi: $isConnected');
    } catch (e) {
      print('Race score bağlantı durumu güncelleme hatası: $e');
    }
  }

// RaceController sınıfında _initializeGame metodunu güncelleyelim

  Future<void> _initializeGame() async {
    try {
      print('_initializeGame başlatılıyor, roomId: ${roomId.value}');

      // 1. İlk olarak odanın genel durumunu kontrol et
      final roomData = await _supabase
          .from('rooms')
          .select()
          .eq('id', roomId.value)
          .single();

      final roomStatus = roomData['status'] as String;
      final gameStatus = roomData['game_status'] as String;

      print('Oda durumu - status: $roomStatus, game_status: $gameStatus');

      // Eğer oda zaten kapatılmışsa veya oyun bitmişse ana ekrana dön
      if (roomStatus == 'closed' || gameStatus == 'finished') {
        print('Bu oda kapalı veya oyun bitmiş, ana sayfaya yönlendiriliyorsunuz');
        Get.snackbar(
          'Bilgi',
          'Bu yarış zaten tamamlanmış.',
          backgroundColor: Colors.blue.withOpacity(0.1),
          colorText: Colors.blue,
        );
        await Future.delayed(const Duration(seconds: 2));
        Get.offNamed('/race');
        return;
      }

      // 2. Soruları yükle
      final questionsData = await _supabase
          .from('questions')
          .select()
          .limit(10);

      if (questionsData.isEmpty) {
        print('Veri tabanında soru bulunamadı!');
        Get.snackbar(
          'Hata',
          'Soru verileri yüklenemedi',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        throw Exception('Soru bulunamadı');
      }

      // Soru listesini temizle ve yeniden doldur
      questions.clear();

      // Questions listesini güvenli bir şekilde doldur
      try {
        List<Question> loadedQuestions = [];
        for (var q in questionsData) {
          try {
            loadedQuestions.add(Question.fromJson(q));
          } catch (e) {
            print('Soru dönüştürme hatası: $e');
            // Hatalı soruyu atla, devam et
          }
        }

        if (loadedQuestions.isEmpty) {
          throw Exception('Geçerli soru yüklenemedi');
        }

        // Tüm soruları ekledikten sonra questions listesini güncelle
        questions.value = loadedQuestions;
        print('${questions.length} soru başarıyla yüklendi');
      } catch (e) {
        print('Soru dönüştürme genel hatası: $e');
        throw Exception('Sorular yüklenemedi: $e');
      }

      // 3. Odadaki oyuncuları al (race_scores tablosunda kaydı olmayanları bulmak için)
      final players = await _supabase
          .from('room_players')
          .select('user_id, is_connected')
          .eq('room_id', roomId.value);

      if (players.isEmpty) {
        throw Exception('Odada hiç oyuncu bulunamadı');
      }

      print('Odadaki oyuncular: $players');

      // 4. Mevcut race_scores kayıtlarını al
      final existingScores = await _supabase
          .from('race_scores')
          .select()
          .eq('room_id', roomId.value);

      print('Mevcut skorlar: $existingScores');

      // Mevcut skorları bir Map'e dönüştür
      final Map<int, Map<String, dynamic>> scoresByPlayerId = {};
      for (final score in existingScores) {
        scoresByPlayerId[score['player_id'] as int] = score;
      }

      // 5. Mevcut kullanıcının ID'sini al
      final currentUserId = roomService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Mevcut kullanıcı ID bulunamadı');
      }

      // 6. Her oyuncu için skorları güncelle veya oluştur
      bool allPlayersHaveScores = true;

      for (final player in players) {
        final playerId = player['user_id'];
        final isConnected = player['is_connected'] as bool? ?? true;

        // Bağlantı durumunu önce güncelle
        playerConnectionStatus[playerId] = isConnected;

        try {
          // Oyuncu için yeni skor kaydı oluştur
          await _supabase
              .from('race_scores')
              .insert({
            'room_id': roomId.value,
            'player_id': playerId,
            'score': 0,
            'current_question_index': 0,
            'is_connected': true, // ÖNEMLİ: Her iki oyuncu için de true olmalı
            'updated_at': DateTime.now().toIso8601String(),
          });

          // Yerel state güncelleme
          playerScores[playerId] = PlayerScore(
            currentQuestionIndex: 0,
            score: 0,
          );
        } catch (insertError) {
          print('Oyuncu $playerId için insert hatası: $insertError');
        }
      }

      // 7. Eğer tüm oyuncuların skoru varsa ve en az 2 oyuncu bağlıysa, oyunu başlat
      print('Tüm oyuncuların skoru var mı: $allPlayersHaveScores');

      // Bağlı oyuncu sayısını hesapla
      final connectedPlayerCount = playerConnectionStatus.entries
          .where((entry) => entry.value == true)
          .length;

      print('Bağlı oyuncu sayısı: $connectedPlayerCount');

      // Odanın game_status bilgisini 'started' olarak güncelle
      if (gameStatus != 'started') {
        await _supabase
            .from('rooms')
            .update({
          'game_status': 'in_progress',
          'updated_at': DateTime.now().toIso8601String()
        })
            .eq('id', roomId.value);

        print('Oda durumu "started" olarak güncellendi');
      }

      // UI'ı güncellemek için
      playerScores.refresh();
      playerConnectionStatus.refresh();

      // Oyun başladı olarak işaretle
      isWaitingForPlayers.value = false;
      gameStarted.value = true;
      update(); // GetBuilder için state güncelleme

      print('Oyun başarıyla başlatıldı - Oda: ${roomId.value}, Sorular: ${questions.length}, Oyuncular: ${playerScores.length}');

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

      // Uygulamayı anında geri döndürmek yerine bir süre bekle
      await Future.delayed(const Duration(seconds: 2));
      if (Get.isRegistered<RaceController>()) {
        Get.delete<RaceController>();
      }
      Get.offNamed('/race');
    }
  }
  Future<void> _resetAllConnectionStatuses() async {
    try {
      // Tüm oyuncuların bağlantı durumunu true yap
      await _supabase
          .from('race_scores')
          .update({
        'is_connected': true,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('room_id', roomId.value);

      print('Tüm oyuncuların bağlantı durumları sıfırlandı');

      // Yerel state'i de güncelle
      playerConnectionStatus.forEach((key, value) {
        playerConnectionStatus[key] = true;
      });
      playerConnectionStatus.refresh();

      // Son oyuncu kaldı zamanlayıcısını iptal et
      _cancelLastPlayerTimer();
    } catch (e) {
      print('Bağlantı durumu sıfırlama hatası: $e');
    }
  }
  void _subscribeToGameState() {
    try {
      // Önce mevcut abonelikleri temizle
      _gameStateSubscription?.cancel();
      _connectionSubscription?.cancel();

      print('Game state subscription başlatılıyor - Oda ID: ${roomId.value}');

      // Önemli: race_scores tablosunu dinlerken sadece bu odaya ait kayıtları filtreleme
      _gameStateSubscription = _supabase
          .from('race_scores')
          .stream(primaryKey: ['id'])
          .eq('room_id', roomId.value)
          .listen(
            (List<Map<String, dynamic>> event) {
          print('Race scores event alındı (Oda ${roomId.value}): ${event.length} kayıt');

          if (event.isEmpty) return;

          // Mevcut oda ID'sini kontrol et
          if (roomId.value <= 0) {
            print('Geçersiz oda ID: ${roomId.value}, event işlenmeyecek');
            return;
          }

          // Mevcut kullanıcı ID'sini al
          final currentUserId = roomService.getCurrentUserId();
          if (currentUserId == null) {
            print('Mevcut kullanıcı ID bulunamadı, işlem yapılmayacak');
            return;
          }

          // Skorları bir değişkene kaydedelim, UI güncellemeleri için
          bool scoresChanged = false;

          // Skorboard verileri - bağlantı durumuna bakmaksızın TÜM oyuncuları göster
          for (var scoreData in event) {
            final playerId = scoreData['player_id'] as int;
            final score = scoreData['score'] as int;
            final questionIndex = scoreData['current_question_index'] as int;
            final isConnected = scoreData['is_connected'] as bool? ?? true;

            // Eğer skor farklıysa veya soru indeksi farklıysa, değişiklik var demektir
            if (playerScores[playerId]?.score != score ||
                playerScores[playerId]?.currentQuestionIndex != questionIndex) {
              scoresChanged = true;
            }

            // Her oyuncu için skorları güncelle
            playerScores[playerId] = PlayerScore(
                currentQuestionIndex: questionIndex,
                score: score
            );

            // Bağlantı durumunu güncelle
            playerConnectionStatus[playerId] = isConnected;

            // Oyuncu ayrıldı/katıldı bildirimlerini işle
            _handlePlayerConnectionChange(playerId, isConnected);
          }

          // UI yenileme - ÇOK ÖNEMLİ
          // GetX refresh'i sadece widget yeniden oluşturulmadığında gereklidir
          // Ancak GetBuilder kullanıldığında update() da çağrılmalıdır
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Değişiklik varsa UI'ı güncelle
            if (scoresChanged) {
              print('Skor değişikliği tespit edildi, UI güncelleniyor');
              playerScores.refresh(); // .obs özelliklerini güncellemek için
              update(); // GetBuilder widget'larını güncellemek için
            }

            // Bağlantı durumu her zaman güncellenir
            playerConnectionStatus.refresh();
          });

          // Aktif oyuncuları filtrele (is_connected = true olanlar)
          final activeScores = event.where((s) => s['is_connected'] == true).toList();

          // Bağlı oyuncuları güncelle
          connectedPlayers.value = activeScores.map((e) => e['player_id'] as int).toList();

          // Boş oda kontrolü
          if (activeScores.isEmpty) {
            _closeRoomWhenEmpty();
          }

          // Tek aktif oyuncu kaldı mı kontrol et
          if (activeScores.length == 1 && activeScores[0]['player_id'] == currentUserId) {
            // Tek oyuncu kaldı, zamanlayıcıyı başlat
            _handleLastPlayerStanding();
          } else if (activeScores.length > 1) {
            // Birden fazla oyuncu var, zamanlayıcıyı iptal et
            _cancelLastPlayerTimer();
          }

          // Eğer bir oyuncu son soruya ulaştıysa
          if (event.isNotEmpty && questions.isNotEmpty) {
            final maxQuestionIndex = event
                .map((e) => e['current_question_index'] as int)
                .reduce(max);

            if (maxQuestionIndex >= questions.length) {
              print('Bir oyuncu oyunu tamamladı');
              // Ancak kendi skorumuz da eğer son soruya ulaştıysa, sonuç sayfasına git
              if (playerScores[currentUserId]?.currentQuestionIndex == questions.length) {
                Get.offNamed('/race-results/${roomId.value}');
              }
            }
          }
        },
        onError: (error) {
          print('Game state subscription hatası (Oda ${roomId.value}): $error');
          Get.snackbar(
            'Bağlantı Hatası',
            'Oyun durumu güncellenirken hata oluştu',
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red,
          );
        },
      );

      // Ayrıca room_players tablosundaki bağlantı durumlarını da dinle
      _connectionSubscription = _supabase
          .from('room_players')
          .stream(primaryKey: ['id'])
          .eq('room_id', roomId.value)
          .listen(
            (List<Map<String, dynamic>> event) {
          print('Room players event alındı: ${event.length} kayıt');

          for (var player in event) {
            final playerId = player['user_id'] as int;
            final isConnected = player['is_connected'] as bool? ?? true;

            // Bağlantı durumunu güncelle
            playerConnectionStatus[playerId] = isConnected;
          }

          // UI yenileme
          WidgetsBinding.instance.addPostFrameCallback((_) {
            playerConnectionStatus.refresh();
          });
        },
        onError: (error) {
          print('Connection subscription hatası: $error');
        },
      );
    } catch (e) {
      print('_subscribeToGameState hatası (Oda ${roomId.value}): $e');
    }
  }
  void _handlePlayerConnectionChange(int playerId, bool isConnected) {
    // Daha önce oyuncu bağlantısı kesildiyse ve şimdi bağlıysa
    if (isConnected && _disconnectedPlayerIds.contains(playerId)) {
      _disconnectedPlayerIds.remove(playerId);

      // Oyuncu geri döndü bildirimi
      getPlayerName(playerId).then((playerName) {
        Get.snackbar(
          'Oyuncu Döndü',
          '$playerName oyuna geri döndü.',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 3),
        );
      });
    }
    // Oyuncu bağlantısı daha önce varken şimdi kesilmişse
    else if (!isConnected && !_disconnectedPlayerIds.contains(playerId)) {
      _disconnectedPlayerIds.add(playerId);

      // Oyuncu ayrıldı bildirimi
      getPlayerName(playerId).then((playerName) {
        Get.snackbar(
          'Oyuncu Ayrıldı',
          '$playerName oyundan ayrıldı.',
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange,
          duration: const Duration(seconds: 3),
        );
      });
    }
  }
  Future<void> _closeRoomWhenEmpty() async {
    try {
      print('Odada aktif oyuncu kalmadı, oda kapatılıyor: ${roomId.value}');

      // Odayı kapat - game_status finished olarak güncelle
      await _supabase
          .from('rooms')
          .update({
        'game_status': 'finished',
        'status': 'closed',
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('id', roomId.value);

      print('Oda başarıyla kapatıldı: ${roomId.value}');

    } catch (e) {
      print('Odayı kapatma hatası: $e');
    }
  }
  final _disconnectedPlayerIds = <int>{};
  void _handleLastPlayerStanding() {
    if (_lastPlayerTimer != null) return; // Zaten aktif bir zamanlayıcı varsa

    print('Son oyuncu kaldı, zamanlayıcı başlatılıyor...');

    // State değişikliklerini bir frame sonrasına bırakalım
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });

    // Zamanlayıcıyı başlat
    _lastPlayerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // UI güvenliği için state değişikliklerini güvenli şekilde yapalım
      WidgetsBinding.instance.addPostFrameCallback((_) {
        lastPlayerTimeLeft.value--;
      });

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
    // Güvenli soru erişimi
    if (questions.isEmpty) {
      print('UYARI: Soru listesi boş!');
      return Question.empty(); // Default boş bir soru döndür
    }

    if (currentQuestionIndex.value >= questions.length) {
      print('UYARI: Soru indeksi sınırları aşıyor! Index: ${currentQuestionIndex.value}, Toplam soru: ${questions.length}');
      return Question.empty(); // Default boş bir soru döndür
    }

    return questions[currentQuestionIndex.value];
  }

  Future<void> submitAnswer(int selectedIndex) async {
    try {
      // Eğer cevap gösteriliyorsa, tekrar cevap vermeyi engelle
      if (showAnswer.value) return;

      // Mevcut kullanıcı ID'sini al
      final userId = roomService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Kullanıcı ID bulunamadı');
      }

      // Soruyu ve cevabın doğruluğunu kontrol et
      final question = getCurrentQuestion();
      final isCorrect = selectedIndex == question.correctOptionIndex;

      // UI güncellemesi
      selectedAnswer.value = selectedIndex;
      isAnswerCorrect.value = isCorrect;
      showAnswer.value = true;

      // Yeni skor ve soru indeksini hesapla
      final currentScore = playerScores[userId]?.score ?? 0;
      final newScore = isCorrect ? currentScore + 10 : currentScore;
      final nextQuestionIndex = currentQuestionIndex.value + 1;

      print('Cevap seçildi: $selectedIndex, Doğru mu: $isCorrect, Yeni skor: $newScore');

      // Kendi state'imizi HEMEN güncelle
      // Stream'den veri gelene kadar UI'da bekleme olmasın
      playerScores[userId] = PlayerScore(
          currentQuestionIndex: currentQuestionIndex.value, // Hemen değiştirme, görsel olarak kesintiye yol açabilir
          score: newScore
      );
      playerScores.refresh();
      update(); // GetBuilder için

      // Veritabanını güncelle
      await _supabase
          .from('race_scores')
          .update({
        'score': newScore,
        'current_question_index': nextQuestionIndex,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('room_id', roomId.value)
          .eq('player_id', userId);

      print('Veritabanı güncellendi');

      // Sonraki soruya geçiş için bekle
      await Future.delayed(const Duration(seconds: 2));

      // UI sıfırlama
      showAnswer.value = false;
      selectedAnswer.value = -1;
      currentQuestionIndex.value = nextQuestionIndex;

      // Oyuncu skorunu güncelle - bu sefer soru indeksini de güncelle
      playerScores[userId] = PlayerScore(
          currentQuestionIndex: nextQuestionIndex,
          score: newScore
      );
      playerScores.refresh();
      update();

      // Oyun bitti mi kontrolü
      if (nextQuestionIndex >= questions.length) {
        print('Oyun tamamlandı');
        await _calculateWinner();
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

// Oyun bitiminde kazananı hesapla
  Future<void> _calculateWinner() async {
    try {
      // En yüksek skoru bul
      int maxScore = -1;
      int winnerId = -1;

      playerScores.forEach((playerId, score) {
        if (score.score > maxScore) {
          maxScore = score.score;
          winnerId = playerId;
        }
      });

      if (winnerId != -1) {
        // Kazananı veritabanında işaretle
        await _supabase
            .from('rooms')
            .update({
          'game_status': 'finished',
          'winner_id': winnerId,
          'updated_at': DateTime.now().toIso8601String()
        })
            .eq('id', roomId.value);

        // Kazananın skorunu işaretle
        await _supabase
            .from('race_scores')
            .update({
          'is_winner': true
        })
            .eq('room_id', roomId.value)
            .eq('player_id', winnerId);

        print('Kazanan belirlendi: $winnerId');

        // Kazananı bildir
        getPlayerName(winnerId).then((name) {
          Get.snackbar(
            'Oyun Bitti',
            'Kazanan: $name',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
            duration: const Duration(seconds: 5),
          );
        });
      }
    } catch (e) {
      print('Kazanan belirleme hatası: $e');
    }
  }
  Future<void> resetConnectionStatus(int roomId) async {
    try {
      // Odadaki tüm oyuncuların room_players tablosunda is_connected değerini true yap
      await _supabase
          .from('room_players')
          .update({
        'is_connected': true,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('room_id', roomId);

      // Aynı şekilde race_scores tablosunda da güncelle
      await _supabase
          .from('race_scores')
          .update({
        'is_connected': true,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('room_id', roomId);

      print('Oda $roomId için tüm bağlantı durumları sıfırlandı');
    } catch (e) {
      print('Bağlantı durumu sıfırlama hatası: $e');
    }
  }
// Oyun bitişini ayrı bir metoda taşıyalım
  Future<void> _finalizeGame(int userId) async {
    try {
      // En yüksek skoru bul ve kazananı belirle
      int winnerId = -1; // Default değer
      int maxScore = -1;

      playerScores.forEach((playerId, scoreData) {
        if (scoreData.score > maxScore) {
          maxScore = scoreData.score;
          winnerId = playerId;
        }
      });

      if (winnerId != -1) {
        // Rooms tablosunu güncelle - winner_id ekle
        await _supabase
            .from('rooms')
            .update({
          'game_status': 'finished',
          'status': 'closed',
          'winner_id': winnerId,
          'updated_at': DateTime.now().toIso8601String()
        })
            .eq('id', roomId.value);

        print('Rooms tablosu güncellendi, kazanan: $winnerId');

        // Race_scores tablosunda kazananı işaretle
        await _supabase
            .from('race_scores')
            .update({
          'is_winner': true,
          'updated_at': DateTime.now().toIso8601String()
        })
            .eq('room_id', roomId.value)
            .eq('player_id', winnerId);

        // Kazanan bilgisini göster
        getPlayerName(winnerId).then((name) {
          Get.snackbar(
            'Oyun Bitti',
            'Kazanan: $name',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
            duration: const Duration(seconds: 5),
          );
        });
      }

      // 2 saniye bekleyip sonuç ekranına git
      await Future.delayed(const Duration(seconds: 2));
      print('Sonuç ekranına yönlendiriliyor');
      Get.offNamed('/race-results/${roomId.value}');

    } catch (e) {
      print('Oyun sonlandırma hatası: $e');
      Get.snackbar(
        'Hata',
        'Oyun sonuçları kaydedilirken bir hata oluştu',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );

      // Hata olsa bile sonuç ekranına git
      Get.offNamed('/race-results/${roomId.value}');
    }
  }
  @override
  void onClose() {
    _connectionUpdateTimer?.cancel();

    _gameStateSubscription?.cancel();
    _connectionSubscription?.cancel();
    _lastPlayerTimer?.cancel();
    _resetAllData();
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