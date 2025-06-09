import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:kelibu/api.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/match_mode_widget.dart';


// 1. Öncelikle, süre seçimi için bir enum ekleyin


// Oyun zorluk seviyeleri


// Öğe tarafı enum
enum ItemSide { left, right }

// Başarı ödülleri enum
enum Achievement {
  perfectScore, // Hatasız bitirme
  speedster, // Hızlı bitirme
  comboMaster, // Yüksek combo
  firstWin, // İlk kazanma
}

// Eşleştirme öğe modeli
class ItemModel {
  final int id;
  final String text;
  bool isSelected;
  Offset position;
  Size size;
  final ItemSide side;
  final GlobalKey key = GlobalKey();
  Animation<double>? fadeAnimation;
  Animation<double>? scaleAnimation;
  Animation<double>? shakeAnimation;
  bool isCorrect = false; // Doğru eşleşme animasyonu için
  bool isWrong = false; // Yanlış eşleşme animasyonu için

  ItemModel({
    required this.id,
    required this.text,
    required this.isSelected,
    required this.position,
    this.size = Size.zero,
    required this.side,
  });

  // Öğenin merkez noktasını hesapla
  Offset get center => Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );

  // Pozisyonu güncelle
  void updatePosition() {
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      position = renderBox.localToGlobal(Offset.zero);
      size = renderBox.size;
    }
  }
}

// Oyun istatistikleri sınıfı
class GameStats {
  int totalGames = 0;
  int wins = 0;
  int perfectGames = 0;
  int bestScore = 0;
  int bestCombo = 0;
  int averageTime = 0;
  List<Achievement> achievements = [];

  GameStats();

  // İstatistikleri yükle
  Future<void> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    totalGames = prefs.getInt('matching_total_games') ?? 0;
    wins = prefs.getInt('matching_wins') ?? 0;
    perfectGames = prefs.getInt('matching_perfect_games') ?? 0;
    bestScore = prefs.getInt('matching_best_score') ?? 0;
    bestCombo = prefs.getInt('matching_best_combo') ?? 0;
    averageTime = prefs.getInt('matching_average_time') ?? 0;
  }

  // İstatistikleri kaydet
  Future<void> saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('matching_total_games', totalGames);
    await prefs.setInt('matching_wins', wins);
    await prefs.setInt('matching_perfect_games', perfectGames);
    await prefs.setInt('matching_best_score', bestScore);
    await prefs.setInt('matching_best_combo', bestCombo);
    await prefs.setInt('matching_average_time', averageTime);
  }
}

class MatchingGame extends StatefulWidget {
  final List<WordDetail> words;
  final int classroomId;
  final int studySetId;
  final MatchType matchType;
  final DifficultyLevel difficulty;
  final TimeSelection timeSelection; // Yeni eklenen parametre
  final String customTimeValue; // Özel süre değeri parametresi eklendi

  const MatchingGame({
    Key? key,
    required this.words,
    required this.classroomId,
    required this.studySetId,
    this.matchType = MatchType.turkishEnglish,
    this.difficulty = DifficultyLevel.medium,
    this.timeSelection = TimeSelection.medium, // Varsayılan değer
    this.customTimeValue = "120", // Varsayılan özel süre değeri
  }) : super(key: key);

  @override
  _MatchingGameState createState() => _MatchingGameState();
}

class _MatchingGameState extends State<MatchingGame>
    with TickerProviderStateMixin {
  late List<WordDetail> _allValidWords; // Tüm geçerli kelimeler
  late List<WordDetail> _gameWords; // Mevcut round için kelimeler
  late List<ItemModel> _leftItems;
  bool _isRoundCompleting = false; // Tur bitme işlemi devam ediyor mu?
  bool _isGameCompleting = false; // Oyun bitme işlemi devam ediyor mu?
  bool _roundCompletionScheduled = false; // Tur bitiş kontrolü zamanlandı mı?
  bool _gameCompletionScheduled = false; // Oyun bitiş kontrolü zamanlandı mı?

  Timer? _roundCompletionTimer; // Tur kontrol timer'ı
  Timer? _gameCompletionTimer; // Oyun kontrol timer'ı

  int _lastLeftItemCount = 0; // Son bilinen sol öğe sayısı
  int _lastRightItemCount = 0; // Son bilinen sağ öğe sayısı
  List<int> _processedMatches = []; // İşlenmiş eşleşmelerin ID'leri

  // Tur durumu kontrol değişkenleri
  bool _roundResultCalculated = false; // Bu tur için sonuç hesaplandı mı?
  ScoreResult? _currentRoundResult; // Mevcut tur sonucu
  bool _isPreparingNextRound = false; // ✅ YENİ EKLENEN
  late ScoreManager _scoreManager;
  late AnimationController _lottieChainController;

  late List<ItemModel> _rightItems;
  late AnimationController _pauseAnimationController;
  int _perfectRoundCount = 0; // Hatasız tamamlanan tur sayısı
  List<String> _perfectRoundMessages = []; // Hatasız turlar için mesajlar
  int _currentUserPoints = 0; // Kullanıcının mevcut puanı
  bool _isLoadingUserPoints =
      true; // Puan yüklenirken gösterilecek yükleme göstergesi
  late AnimationController _pointAnimationController;
  late Animation<double> _pointScaleAnimation;
  int _displayedPoints = 0; // Ekranda gösterilen puan değeri
  int _previousTotalPoints = 0; // Bir önceki toplam puan
  int _newPointsToAdd = 0; // Eklenecek yeni puanlar
  bool _isAddingPoints = false; // Puan ekleme animasyonu durumu
  int _currentRound = 1;
  int _totalRounds = 1;
  int _wordsPerRound = 8;
  int _totalScore = 0; // Tüm roundların toplam skoru
  late AnimationController _seriesSaverAnimationController;
  late Animation<double> _chainBreakAnimation;
  late Animation<double> _chainRepairAnimation;
  bool _showingSeriesSaverAnimation = false;
  ItemModel? _selectedLeftItem;
  ItemModel? _selectedRightItem; // The missing variables:
  bool _usedSeriesSaver = false; // Seri kurtarma jokeri kullanıldı mı?
  bool _hasSeriesSaver = true; // Seri kurtarma jokeri var mı?

  List<ItemModel> _matchedItems = [];
  Map<int, AnimationController> _fadeControllers = {};
  List<Achievement> _earnedAchievements = [];

  int _score = 0;
  int _moves = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _timeRemaining = 120;
  int _initialTime = 120;
  bool _gameOver = false;
  bool _gameWon = false;
  bool _isPaused = false;
  int _perfectMultiplier = 0; // Hatasız eşleşme sayısı
  double _particles = 0.0; // Partikül efekti için

  late AnimationController _controller;
  late AnimationController _shakeController;
  late AnimationController _wrongMatchController;
  late AnimationController _correctMatchController;
  late AnimationController _particleController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _wrongMatchAnimation;
  late Animation<Color?> _correctMatchAnimation;
  late ConfettiController _confettiController;

  late GameStats _gameStats;
  bool _isDarkMode = false;
  bool _showStats = false;

  Size? _screenSize;
  final GlobalKey _gameAreaKey = GlobalKey();

  @override
  void initState() {
    _loadUserPoints();

    _localPointsUpdated = false; // Başlangıçta false
    _initializeScoreManager();
    // ✅ DÜZELTME: Lottie controller'ı sadece bir kez oluştur
    _lottieChainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pointAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _seriesSaverAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _chainBreakAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _seriesSaverAnimationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _chainRepairAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _seriesSaverAnimationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );
    _pointScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_pointAnimationController);

    _pointAnimationController.addListener(() {
      if (_isAddingPoints) {
        // Animasyon sırasında puanı kademeli olarak artır
        setState(() {
          _displayedPoints = _previousTotalPoints +
              (_newPointsToAdd * _pointAnimationController.value).round();
        });
      }
    });

    _pointAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAddingPoints = false;
          _previousTotalPoints = _displayedPoints; // Yeni toplam puanı sakla
        });
      }
    });
    _gameStats = GameStats();
    _gameStats.loadStats();
    _pauseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    // AnimationController'ları başlat
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        setState(() {});
      });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _wrongMatchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _correctMatchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        setState(() {
          _particles = _particleController.value;
        });
      });

    _shakeAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );

    _wrongMatchAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _wrongMatchController,
        curve: Curves.easeInOut,
      ),
    );

    _correctMatchAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.green.withOpacity(0.3),
    ).animate(CurvedAnimation(
      parent: _correctMatchController,
      curve: Curves.easeOut,
    ));

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    _loadDarkModePreference();

    // Geçerli kelimeleri filtrele ve round sayısını hesapla
    _filterValidWords();
    initGame();

    // Oyun zamanlayıcısını başlat
    startTimer();

    // Öğe pozisyonlarını güncellemek için ilk fram sonrası callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAllItemPositions();
    });
    super.initState();
  }

  // 2. SCOREMANAGER'I BAŞLATMA
  void _initializeScoreManager() {
    int initialTime;
    switch (widget.timeSelection) {
      case TimeSelection.short:
        initialTime = 60;
        break;
      case TimeSelection.medium:
        initialTime = 120;
        break;
      case TimeSelection.long:
        initialTime = 180;
        break;
      case TimeSelection.custom:
        int customTime = int.tryParse(widget.customTimeValue) ?? 120;
        initialTime = customTime.clamp(30, 300);
        break;
    }

    _scoreManager = ScoreManager(
      difficulty: widget.difficulty,
      initialTime: initialTime,
      userCurrentPoints: _currentUserPoints,
    );
  }
  void _checkCompletion({String context = "unknown"}) {
    if (!mounted) return;

    print("🔍 [$context] Tamamlanma kontrolü başlatılıyor...");
    print("📊 Mevcut durum - Sol: ${_leftItems.length}, Sağ: ${_rightItems.length}");
    print("🎯 Round: $_currentRound/$_totalRounds");
    print("🔒 States - RoundCompleting: $_isRoundCompleting, GameCompleting: $_isGameCompleting");

    // Eğer zaten bir işlem devam ediyorsa durma
    if (_isRoundCompleting || _isGameCompleting || _gameOver || _gameWon) {
      print("⏸️ İşlem zaten devam ediyor, kontrol iptal edildi");
      return;
    }

    // Öğe sayılarını kontrol et
    bool hasItemsLeft = _leftItems.isNotEmpty && _rightItems.isNotEmpty;
    bool isRoundComplete = _leftItems.isEmpty && _rightItems.isEmpty;

    if (isRoundComplete) {
      print("✅ Tur tamamlandı algılandı!");
      _handleRoundCompletion(context: context);
    } else if (hasItemsLeft) {
      print("🎮 Oyun devam ediyor - ${_leftItems.length} öğe kaldı");
      _updateItemCounts();
    } else {
      print("⚠️ Beklenmeyen durum - Liste durumları tutarsız");
      _handleInconsistentState();
    }
  }
  /// Tur tamamlama işlemi
  void _handleRoundCompletion({String context = "unknown"}) {
    if (_isRoundCompleting || _isGameCompleting) {
      print("⏸️ Tur tamamlama zaten devam ediyor");
      return;
    }

    setState(() {
      _isRoundCompleting = true;
    });

    print("🎯 [$context] Tur $_currentRound tamamlanıyor...");

    // Tur sonucunu hesapla (sadece bir kez)
    if (!_roundResultCalculated) {
      _calculateRoundScore();
      _roundResultCalculated = true;
    }

    // 500ms sonra tur geçiş işlemini gerçekleştir
    _roundCompletionTimer?.cancel();
    _roundCompletionTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _executeRoundTransition();
    });
  }

  /// Tur geçiş işlemini gerçekleştir
  void _executeRoundTransition() {
    if (!mounted) return;

    print("🔄 Tur geçiş işlemi başlatılıyor...");

    if (_currentRound < _totalRounds) {
      print("➡️ Sonraki tura geçiliyor: ${_currentRound + 1}/$_totalRounds");
      _proceedToNextRound();
    } else {
      print("🏆 TÜM TURLAR TAMAMLANDI - Oyun bitişi başlatılıyor");
      _handleGameCompletion();
    }
  }
  void _updateAllItemPositions() {
    setState(() {
      for (var item in [..._leftItems, ..._rightItems]) {
        item.updatePosition();
      }
    });
  }
  void _proceedToNextRound() {
    setState(() {
      _isRoundCompleting = false;
      _roundResultCalculated = false;
      _processedMatches.clear();
    });

    // Tur bitiş ekranını göster (mevcut kodun `_loadNextRound` davranışı)
    _loadNextRound();
  }

  /// Oyun tamamlama işlemi
  void _handleGameCompletion() {
    if (_isGameCompleting) {
      print("⏸️ Oyun tamamlama zaten devam ediyor");
      return;
    }

    setState(() {
      _isGameCompleting = true;
      _isRoundCompleting = false;
    });

    print("🏁 OYUN TAMAMEN BİTİYOR!");

    // 300ms sonra final işlemleri gerçekleştir
    _gameCompletionTimer?.cancel();
    _gameCompletionTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _executeFinalGameCompletion();
    });
  }

  /// Final oyun bitiş işlemi
  void _executeFinalGameCompletion() {
    if (!mounted) return;

    print("🎊 Final oyun bitiş işlemleri gerçekleştiriliyor...");

    _calculateFinalScore();

    setState(() {
      _gameWon = true;
      _gameOver = true;
      _isGameCompleting = false;
      _isRoundCompleting = false;
    });

    _updateStats();
    _confettiController.play();

    print("✨ Oyun başarıyla tamamlandı!");
  }

  // ===== 3. GÜVENLİ EŞLEŞME YÖNETİMİ =====

  /// Güvenli eşleşme kaldırma işlemi
  void _removeMatchedItemsSafely() {
    if (!mounted || _isRoundCompleting || _isGameCompleting) return;

    final int matchedId = _selectedLeftItem!.id;

    // Eşleşmeyi işlenmiş listesine ekle
    if (_processedMatches.contains(matchedId)) {
      print("⚠️ Bu eşleşme zaten işlendi: $matchedId");
      return;
    }
    _processedMatches.add(matchedId);

    print("🗑️ Eşleşen öğeler kaldırılıyor: ID $matchedId");
    print("📊 Kaldırma öncesi - Sol: ${_leftItems.length}, Sağ: ${_rightItems.length}");

    // Animasyon süresince bekle
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _isRoundCompleting || _isGameCompleting) return;

      _performItemRemoval(matchedId);
    });
  }
  void _performItemRemoval(int matchedId) {
    setState(() {
      int leftBefore = _leftItems.length;
      int rightBefore = _rightItems.length;

      // Güvenli kaldırma
      _leftItems.removeWhere((item) => item.id == matchedId);
      _rightItems.removeWhere((item) => item.id == matchedId);

      int leftAfter = _leftItems.length;
      int rightAfter = _rightItems.length;

      print("📊 Kaldırma sonrası - Sol: $leftBefore→$leftAfter, Sağ: $rightBefore→$rightAfter");

      // Seçimleri temizle
      _clearSelections();
    });

    // Pozisyonları güncelle ve tamamlanma kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateAllItemPositions();
        _updateItemCounts();

        // 100ms gecikme ile kontrol (animasyonların bitmesi için)
        Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            _checkCompletion(context: "after_item_removal");
          }
        });
      }
    });
  }

  /// Seçimleri temizle
  void _clearSelections() {
    _selectedLeftItem?.isSelected = false;
    _selectedRightItem?.isSelected = false;
    _selectedLeftItem = null;
    _selectedRightItem = null;
  }

  /// Öğe sayılarını güncelle
  void _updateItemCounts() {
    _lastLeftItemCount = _leftItems.length;
    _lastRightItemCount = _rightItems.length;
  }
  // Seri kurtarma animasyonunu göster
  void _showSeriesSaverAnimation() {
    if (!mounted) return;

    setState(() {
      _showingSeriesSaverAnimation = true;
    });

    // ✅ GÜVENLI ANİMASYON BAŞLATMA
    if (_lottieChainController.isAnimating) {
      _lottieChainController.stop();
    }

    _lottieChainController.reset();

    // Animasyonu başlat
    _lottieChainController.forward().then((_) {
      if (mounted) {
        // İleri oynatma bittikten sonra ters oynat
        _lottieChainController.reverse().then((_) {
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _showingSeriesSaverAnimation = false;
                });
              }
            });
          }
        });
      }
    });

    // Haptic feedback
    HapticFeedback.heavyImpact();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Future<void> _updateUserScore(int newTotalScore) async {
    try {
      UserProvider userProvider =
          Provider.of<UserProvider>(context, listen: false);
      int currentPoints = userProvider.point;


      // Puan düşüşü kontrolü
      if (newTotalScore < currentPoints) {
        // Yine de güncelle, belki kasıtlı
      }

      // ✅ TEK SATIRDA HALLEDİYORUZ
      await ApiService().updateUserPointTimePeriod(
          userProvider.userId,
          newTotalScore, // ✅ Toplam puanı gönder
          0 // time point - oyun süresi istemiyorsan 0 ver
          );

      // ✅ LOCAL STATE'İ GÜNCELLE
      userProvider.addPoint(newTotalScore);

      setState(() {
        _currentUserPoints = newTotalScore;
      });

    } catch (e) {
    }
  }

  Future<void> _loadUserPoints() async {
    setState(() {
      _isLoadingUserPoints = true;
    });
    UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _currentUserPoints =
          userProvider.point; // Kullanıcının genel, oyun dışı puanı
      _displayedPoints =
          userProvider.point; // Ekranda gösterilecek başlangıç puanı
      _previousTotalPoints = userProvider.point; // Animasyon için başlangıç
      _isLoadingUserPoints = false;
    });
  }

  Future<void> _updateLocalUserPoints(int newTotalPoints) async {
    try {
      final prefs = await SharedPreferences.getInstance();


      // ✅ DÜZELTME: Toplam puanı kaydet (ekleme değil, set etme)
      await prefs.setInt('userPoints', newTotalPoints);
      await Future.delayed(const Duration(milliseconds: 100));

    } catch (e) {
    }
  }

  bool _localPointsUpdated = false; // Class seviyesinde değişken ekle

// Kullanıcı puanını yerel olarak güncelleme
// ❌ SORUN: _updateLocalUserPoints'te sadece yeni puanı kaydediyor
// ✅ DÜZELTME: _showSeriesSaverDialog metodundaki joker kullanma kısmını güncelleyin
  void _showSeriesSaverDialog() {
    // ✅ Mevcut seri değerini kaydet (dialog sırasında değişmesin)
    final int currentStreak = _scoreManager.streak;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Text(
                "Seri Kurtarma Jokeri",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Hatalı bir eşleşme yaptınız! $currentStreak serilik zincirinizi kurtarmak için jokerinizi kullanmak ister misiniz?",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "⚠️ Bu jokerinizi oyun boyunca sadece 1 kez kullanabilirsiniz!",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.amber[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 100,
                child: Center(
                  child: _buildChainAnimation(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                print("🚫 Joker kullanılmadı - Normal hata işlemi yapılıyor");
                _processNormalMismatchWithStreakBreak();
              },
              child: Text(
                "Hayır, Jokeri Sakla",
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();

                print("🃏 Joker kullanıldı - Seri korunuyor!");

                _usedSeriesSaver = true;
                _hasSeriesSaver = false;
                _showSeriesSaverAnimation();

                // ✅ Seçimleri sıfırla, seriyi KORUMA (ScoreManager'a bilgi verme)
                setState(() {
                  if (_selectedLeftItem != null) {
                    _selectedLeftItem!.isSelected = false;
                    _selectedLeftItem!.isWrong = false;
                  }
                  if (_selectedRightItem != null) {
                    _selectedRightItem!.isSelected = false;
                    _selectedRightItem!.isWrong = false;
                  }
                  _selectedLeftItem = null;
                  _selectedRightItem = null;
                });
              },
              child: Text(
                "Evet, Seriyi Kurtar!",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _checkSeriesSaverEarning() {
    // Her 10 seride bir joker kazan (sadece bir kez)
    if (_scoreManager.streak == 10 && !_hasSeriesSaver && !_usedSeriesSaver) {
      print("🎁 10 seri tamamlandı - Joker kazanıldı!");
      setState(() {
        _hasSeriesSaver = true;
      });

      // Joker kazanma bildirimi göster
      _showSeriesSaverEarnedDialog();
    }
  }
// ✅ YENİ: Joker kazanma bildirimi
  void _showSeriesSaverEarnedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Text(
                "Joker Kazandınız!",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 60),
              const SizedBox(height: 16),
              Text(
                "Tebrikler! 10 seri yaparak bir Seri Kurtarma Jokeri kazandınız. Bu jokeri bir hata yaptığınızda serinizi korumak için kullanabilirsiniz.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Harika!",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChainAnimation() {
    return AnimatedBuilder(
      animation: _seriesSaverAnimationController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 60),
          painter: ChainPainter(
            breakProgress: _chainBreakAnimation.value,
            repairProgress: _chainRepairAnimation.value,
            isDarkMode: _isDarkMode,
          ),
        );
      },
    );
  }


// ✅ YENİ VE İYİLEŞTİRİLMİŞ SERİ KURTARMA OVERLAY
  Widget _buildSeriesSaverOverlay() {
    if (!_showingSeriesSaverAnimation) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          // ✅ Daha hafif arka plan
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Colors.white.withOpacity(0.4), // Beyaz tonu
              Colors.grey.withOpacity(0.6),
              Colors.black.withOpacity(0.7),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2), // Hafif blur
          child: Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.7 + (0.3 * value),
                  child: Opacity(
                    opacity: value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ ANA KONTEYNER - Daha beyaz ve temiz
                        Container(
                          width: 340, // Biraz daha büyük
                          height: 400, // Lottie için daha yüksek
                          decoration: BoxDecoration(
                            // ✅ Daha beyaz gradient
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _isDarkMode ? const Color(0xFF374151) : Colors.white,
                                _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFFAFBFC),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            // ✅ Daha sade gölgeler
                            boxShadow: [
                              // Ana gölge - daha hafif
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 4,
                                offset: const Offset(0, 6),
                              ),
                              // İkinci katman
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 40,
                                spreadRadius: 8,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            // ✅ Daha sade kenarlık
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // ✅ Hafif parıltı efekti (isteğe bağlı - kaldırılabilir)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.1),
                                        Colors.transparent,
                                        Colors.grey.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Ana içerik
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // ✅ Zincir animasyonu alanı - ÇOK DAHA BÜYÜK
                                    Container(
                                      height: 120, // 80'den 120'ye çıktı
                                      width: double.infinity,
                                      child: _buildEnhancedChainAnimation(),
                                    ),

                                    const SizedBox(height: 12),

                                    // ✅ Ana başlık - Daha sade renkler
                                    Text(
                                      "SERİ KURTARILDI!",
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: _isDarkMode
                                            ? Colors.green[400]
                                            : Colors.green[700], // Yeşil tonu
                                        letterSpacing: 1.0,
                                        shadows: [
                                          Shadow(
                                            color: Colors.green.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // ✅ Alt yazı - Daha sade
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green[600],
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Zinciriniz Onarıldı",
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: _isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green[600],
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ Alt bilgi kartı - Daha temiz
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            // ✅ Beyaz glassmorphism
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.star_outline,
                                  color: Colors.blue[400],
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Jokeriniz Kullanıldı",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
// ✅ GELİŞTİRİLMİŞ ZİNCİR ANİMASYONU
  Widget _buildEnhancedChainAnimation() {
    return Container(
      height: 80,
      width: 500,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ✅ Lottie chain animasyonu
          Lottie.asset(
            'assets/chain.json', // Lottie dosyanızın yolu
            controller: _lottieChainController,
            height: 200,
            width: 500,
            fit: BoxFit.contain,
            // ✅ TERS OYNAMA SEÇENEKLERİ:
            repeat: false, // Tekrar etmesin
            reverse: true, // Controller ile kontrol edeceğiz
            animate: false, // Manuel kontrol
          ),

          // ✅ Ek efektler için overlay (isteğe bağlı)
          if (_lottieChainController.value > 0.5)
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildGameContent(Map<String, Color> colors) {
    // ✅ 1. HAZIRLIK EKRANI - Sonraki tur hazırlanıyor
    if (_isPreparingNextRound) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: colors['cardBackground'],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors['primary']!.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: colors['primary']!.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dönen ikon
              AnimatedBuilder(
                animation: _pauseAnimationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _pauseAnimationController.value * 2 * pi,
                    child: Icon(
                      Icons.refresh,
                      size: 48,
                      color: colors['primary'],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                "Round $_currentRound Hazırlanıyor...",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors['text'],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Kelimeler karıştırılıyor 🎯",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colors['text']?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ 2. ROUND GEÇİŞ EKRANI - Tur tamamlandı, puan gösterimi
// ✅ 2. ROUND GEÇİŞ EKRANI - ScoreManager ile güncellendi
    if (_leftItems.isEmpty &&
        _rightItems.isEmpty &&
        _currentRound <= _totalRounds) {
      // ✅ SCOREMANAGER'DAN PUAN HESAPLAMALARINI AL
      _scoreManager.timeRemaining = _timeRemaining;
      ScoreResult result = _scoreManager.calculateRoundResult();

      // Debug için konsolda yazdır

      return LayoutBuilder(
        builder: (context, constraints) {
          // Responsive değerler
          bool isTablet = constraints.maxWidth > 600;
          bool isMobile = constraints.maxWidth < 400;

          double horizontalPadding = isMobile ? 16 : (isTablet ? 40 : 24);
          double cardPadding = isMobile ? 16 : 24;
          double titleSize = isMobile ? 20 : (isTablet ? 28 : 24);
          double subtitleSize = isMobile ? 16 : (isTablet ? 22 : 20);
          double textSize = isMobile ? 14 : (isTablet ? 18 : 16);

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isMobile ? 16 : 24,
              ),
              child: Column(
                children: [
                  // ✅ ANİMASYONLU BAŞLIK
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors['primary']!,
                                  colors['secondary']!,
                                  colors['primary']!.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                stops: [0.0, 0.5, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: colors['primary']!.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Arka plan pattern
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: CustomPaint(
                                      painter: _PatternPainter(
                                          Colors.white.withOpacity(0.1)),
                                    ),
                                  ),
                                ),
                                // İçerik
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: cardPadding,
                                    vertical: isMobile ? 20 : 24,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.emoji_events,
                                          color: Colors.white,
                                          size: isMobile ? 28 : 36,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Flexible(
                                        child: Column(
                                          children: [
                                            Text(
                                              "Round $_currentRound",
                                              style: GoogleFonts.poppins(
                                                fontSize: titleSize,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    offset: const Offset(0, 2),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              "Tamamlandı! 🎉",
                                              style: GoogleFonts.poppins(
                                                fontSize: textSize,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // ✅ PUAN DETAY KARTI - ScoreManager verilerini kullan
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: colors['cardBackground'],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colors['primary']!.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors['primary']!.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Başlık
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colors['primary']!
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.analytics_outlined,
                                          color: colors['primary'],
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Puan Detayları",
                                        style: GoogleFonts.poppins(
                                          fontSize: subtitleSize,
                                          fontWeight: FontWeight.bold,
                                          color: colors['primary'],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // ✅ SCOREMANAGER VERİLERİNİ KULLAN
                                  // Temel Puanlar (seri bonusu dahil)
                                  _buildAnimatedScoreRow(
                                    "Temel Puanlar (Seri Dahil)",
                                    "${result.baseScore}",
                                    colors,
                                    Icons.star_outline,
                                    Colors.blue,
                                    0,
                                    textSize,
                                  ),

                                  // Zaman bonusu
                                  if (result.timeBonus > 0)
                                    _buildAnimatedScoreRow(
                                      "Hız Bonusu",
                                      "+${result.timeBonus}",
                                      colors,
                                      Icons.flash_on,
                                      Colors.amber,
                                      200,
                                      textSize,
                                    ),

                                  // Mükemmel bonus
                                  if (result.perfectBonus > 0)
                                    _buildAnimatedScoreRow(
                                      "Mükemmel Tur!",
                                      "+${result.perfectBonus}",
                                      colors,
                                      Icons.workspace_premium,
                                      Colors.purple,
                                      400,
                                      textSize,
                                    ),

                                  // En iyi seri bilgisi (puan değil, bilgi olarak)
                                  if (result.bestStreak > 1)
                                    _buildAnimatedScoreRow(
                                      "En İyi Seri",
                                      "x${result.bestStreak}",
                                      colors,
                                      Icons.local_fire_department,
                                      Colors.deepOrange,
                                      300,
                                      textSize,
                                    ),

                                  // Ayırıcı çizgi
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 16),
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          colors['border']!.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Zorluk çarpanı
                                  if (result.difficultyMultiplier != 1.0)
                                    _buildAnimatedScoreRow(
                                      "Zorluk Çarpanı",
                                      "x${result.difficultyMultiplier.toStringAsFixed(1)}",
                                      colors,
                                      Icons.trending_up,
                                      widget.difficulty == DifficultyLevel.hard
                                          ? Colors.red
                                          : Colors.green,
                                      600,
                                      textSize,
                                    ),

                                  const SizedBox(height: 8),

                                  // ✅ TOPLAM PUAN - ScoreManager'dan al
                                  TweenAnimationBuilder(
                                    duration: const Duration(milliseconds: 1200),
                                    tween: Tween<double>(begin: 0, end: 1),
                                    builder: (context, double value, child) {
                                      return Transform.scale(
                                        scale: 0.9 + (0.1 * value),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                colors['primary']!
                                                    .withOpacity(0.1),
                                                colors['secondary']!
                                                    .withOpacity(0.05),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: colors['primary']!
                                                  .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Bu Turun Puanı:",
                                                style: GoogleFonts.poppins(
                                                  fontSize: textSize + 2,
                                                  fontWeight: FontWeight.bold,
                                                  color: colors['text'],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: colors['primary'],
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: colors['primary']!
                                                          .withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  "${result.finalRoundScore}",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: textSize + 6,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // ✅ TOPLAM PUAN KARTI (Son roundda göster)
                  if (_currentRound == _totalRounds)
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 1600),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.withOpacity(0.8),
                                      Colors.orange.withOpacity(0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.emoji_events,
                                            color: Colors.white,
                                            size: isMobile ? 24 : 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            "Oyun Tamamlandı!",
                                            style: GoogleFonts.poppins(
                                              fontSize: titleSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Toplam Puanınız:",
                                            style: GoogleFonts.poppins(
                                              fontSize: textSize + 2,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "${_currentUserPoints}",
                                                style: GoogleFonts.poppins(
                                                  fontSize: textSize,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  decorationColor: Colors.white
                                                      .withOpacity(0.7),
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward,
                                                  color: Colors.white,
                                                  size: 16),
                                              const SizedBox(width: 8),
                                              Text(
                                                "${result.newUserTotal}",
                                                style: GoogleFonts.poppins(
                                                  fontSize: titleSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ));
                      },
                    ),

                  // ✅ BUTONLAR
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1400),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            width: double.infinity,
                            height: isMobile ? 60 : 70,
                            child: _currentRound < _totalRounds
                                ? _buildNextRoundButton(
                                    colors,
                                    result.finalRoundScore,
                                    result.totalGameScore,
                                    isMobile,
                                    textSize)
                                : _buildFinishGameButton(
                                    colors,
                                    result.finalRoundScore,
                                    result.totalGameScore,
                                    isMobile,
                                    textSize),
                          ),
                        ),
                      );
                    },
                  ),

                  // ✅ PROGRESS INDICATOR
                  if (_currentRound < _totalRounds)
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 1600),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: Container(
                            margin: const EdgeInsets.only(top: 20),
                            child: Column(
                              children: [
                                Text(
                                  "İlerleme: $_currentRound / $_totalRounds",
                                  style: GoogleFonts.poppins(
                                    fontSize: textSize - 2,
                                    color: colors['text']?.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colors['border']?.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _currentRound / _totalRounds,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colors['primary']!,
                                            colors['secondary']!
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
    return Column(
      children: [
        _buildScorePanel(colors),
        Expanded(
          child: Container(
            key: _gameAreaKey,
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sol sütun
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Text(
                            widget.matchType == MatchType.turkishEnglish ||
                                    widget.matchType ==
                                        MatchType.definitionTurkish
                                ? "Türkçe"
                                : widget.matchType == MatchType.definitionWord
                                    ? "Tanım"
                                    : "İngilizce",
                            style: GoogleFonts.poppins(
                              color: colors['primary'],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _buildItemsList(
                                _leftItems, constraints, colors),
                          ),
                        ],
                      ),
                    ),

                    // Orta boşluk
                    const SizedBox(width: 20),

                    // Sağ sütun
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Text(
                            widget.matchType == MatchType.turkishEnglish ||
                                    widget.matchType == MatchType.definitionWord
                                ? "İngilizce"
                                : "Türkçe",
                            style: GoogleFonts.poppins(
                              color: colors['primary'],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _buildItemsList(
                                _rightItems, constraints, colors),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

// _buildAchievementBadge metodu - başarı rozeti
  Widget _buildAnimatedScoreRow(
    String title,
    String value,
    Map<String, Color> colors,
    IconData icon,
    Color iconColor,
    int delay,
    double textSize,
  ) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animValue, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: iconColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: textSize,
                        fontWeight: FontWeight.w500,
                        color: colors['text'],
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: textSize,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// ✅ SONRAKİ TUR BUTONU
  Widget _buildNextRoundButton(Map<String, Color> colors, int finalRoundScore,
      int totalGameScore, bool isMobile, double textSize) {
    return AnimatedBuilder(
      animation: _pauseAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors['primary']!, colors['secondary']!],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors['primary']!.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // ✅ ScoreResult kullanarak kullanıcı puanını güncelle
                int newUserPoints = _currentUserPoints + finalRoundScore;
                _updateUserScore(newUserPoints);
                _startNextRoundManually();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(
                        5 * sin(_pauseAnimationController.value * 2 * pi),
                        0,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Sonraki Tura Geç",
                      style: GoogleFonts.poppins(
                        fontSize: textSize + 2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_currentRound + 1}/${_totalRounds}",
                        style: GoogleFonts.poppins(
                          fontSize: textSize - 2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// ✅ OYUNU BİTİR BUTONU
  Widget _buildFinishGameButton(Map<String, Color> colors, int finalRoundScore,
      int newGrandTotal, bool isMobile, double textSize) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _totalScore = newGrandTotal;
              _gameWon = true;
              _gameOver = true;
            });
            _updateStats();
            _confettiController.play();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: isMobile ? 20 : 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Oyunu Tamamla!",
                  style: GoogleFonts.poppins(
                    fontSize: textSize + 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _loadNextRound() {
    // ✅ Round sonucunu hesapla ve sakla
    _scoreManager.timeRemaining = _timeRemaining;
    _currentRoundResult = _scoreManager.calculateRoundResult();

    setState(() {
      _selectedLeftItem = null;
      _selectedRightItem = null;
      _earnedAchievements.clear();
      _isPreparingNextRound = false;
    });

    // ✅ SORUN BURADA: Bu dispose satırını kaldırın!
    // for (var controller in _fadeControllers.values) {
    //   controller.reset();
    //   if (!controller.isAnimating) {
    //     controller.dispose();
    //   }
    // }
    // _lottieChainController.dispose(); // ❌ BUNU KALDIRIN!

    // ✅ DÜZELTME: Sadece fade controller'ları temizle
    for (var controller in _fadeControllers.values) {
      controller.reset();
      controller.dispose();
    }
    _fadeControllers.clear();
  }// 1. Sadece ters oynatma:
  void _playChainReverse() {
    _lottieChainController.reverse(from: 1.0); // Sondan başa doğru
  }


  void _pointAnimationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_localPointsUpdated) {
      _localPointsUpdated = true;
      _updateLocalUserPoints(_currentUserPoints);
    }
  }

  Future<void> _sendRoundPointsToServer(int finalRoundPoints) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        return;
      }

      int gameDuration = _initialTime - _timeRemaining;

      // ✅ Sadece round puanı

      // ✅ DOĞRU: Sunucuya sadece kazanılan puanı gönder
      await ApiService().updateUserPointTimePeriod(
          int.parse(userId),
          finalRoundPoints, // ✅ Sadece bu roundda kazanılan puan
          gameDuration);


      // Log kaydı
      await ApiService().logSetEntry(
          'Eşleştirme Oyunu - Tur $_currentRound',
          '${widget.difficulty.toString().split('.').last.toUpperCase()} zorluğunda $finalRoundPoints puan kazandı.',
          'Süre: $gameDuration sn, Seri: $_bestStreak, Yeni Toplam: $_currentUserPoints');
    } catch (e) {
    }
  }

  void _filterValidWords() {
    // Boş verisi olmayan kelimeleri filtrele
    _allValidWords = widget.words.where((word) {
      bool hasValidData = word.word.isNotEmpty && word.meaning.isNotEmpty;

      // Tanım tipi oyunlar için tanımların dolu olduğunu kontrol et
      if (widget.matchType == MatchType.definitionWord ||
          widget.matchType == MatchType.definitionTurkish) {
        hasValidData = hasValidData &&
            word.defination != null &&
            word.defination!.isNotEmpty;
      }

      return hasValidData;
    }).toList();

    // Zorluk seviyesine göre kelime sayısını ayarla
    switch (widget.difficulty) {
      case DifficultyLevel.easy:
        _wordsPerRound = 5;
        break;
      case DifficultyLevel.medium:
        _wordsPerRound = 8;
        break;
      case DifficultyLevel.hard:
        _wordsPerRound = 10;
        break;
    }

    // Round sayısını hesapla
    _totalRounds = (_allValidWords.length / _wordsPerRound).ceil();
  }

  void initGame() {
    _localPointsUpdated = false; // Her oyun başında sıfırla

    if (_currentRound == 1) {
      _scoreManager.resetGame(_currentUserPoints);
    } else {
      // Yeni round başlat
      _scoreManager.startNewRound();
    }

    // ✅ DÜZELTME: Lottie controller'ı sıfırla ama dispose etme
    if (_lottieChainController.isAnimating) {
      _lottieChainController.stop();
    }
    _lottieChainController.reset();

    // Joker durumunu sıfırla (sadece oyun başında)
    if (_currentRound == 1) {
      _usedSeriesSaver = false;
      _hasSeriesSaver = true;
    }

    _timeRemaining = _scoreManager.initialTime;

    // Süreyi seçilen değere göre ayarla
    switch (widget.timeSelection) {
      case TimeSelection.short:
        _timeRemaining = _initialTime = 60;
        break;
      case TimeSelection.medium:
        _timeRemaining = _initialTime = 120;
        break;
      case TimeSelection.long:
        _timeRemaining = _initialTime = 180;
        break;
      case TimeSelection.custom:
      // Özel süre için girilen değeri al (varsayılan 120, min 30, max 300)
        int customTime = int.tryParse(widget.customTimeValue) ?? 120;
        customTime = customTime.clamp(30, 300);
        _timeRemaining = _initialTime = customTime;
        break;
    }

    // Mevcut round için kelimeleri seç
    final startIndex = (_currentRound - 1) * _wordsPerRound;
    int endIndex = startIndex + _wordsPerRound;

    // Son round'da kalan tüm kelimeleri al
    if (endIndex > _allValidWords.length) {
      endIndex = _allValidWords.length;
    }

    _gameWords = _allValidWords.sublist(startIndex, endIndex);

    // Sol taraf öğelerini oluştur
    _leftItems = _gameWords.asMap().entries.map((entry) {
      int index = entry.key;
      WordDetail word = entry.value;

      String text = '';
      switch (widget.matchType) {
        case MatchType.turkishEnglish:
          text = word.meaning;
          break;
        case MatchType.englishTurkish:
          text = word.word;
          break;
        case MatchType.definitionWord:
          text = word.defination ?? "No definition available";
          break;
        case MatchType.definitionTurkish:
          text = word.defination ?? "No definition available";
          break;
      }

      return ItemModel(
        id: index,
        text: text,
        isSelected: false,
        position: Offset.zero,
        side: ItemSide.left,
      );
    }).toList();

    // Sağ taraf öğelerini oluştur
    _rightItems = _gameWords.asMap().entries.map((entry) {
      int index = entry.key;
      WordDetail word = entry.value;

      String text = '';
      switch (widget.matchType) {
        case MatchType.turkishEnglish:
          text = word.word;
          break;
        case MatchType.englishTurkish:
          text = word.meaning;
          break;
        case MatchType.definitionWord:
          text = word.word;
          break;
        case MatchType.definitionTurkish:
          text = word.meaning;
          break;
      }

      return ItemModel(
        id: index,
        text: text,
        isSelected: false,
        position: Offset.zero,
        side: ItemSide.right,
      );
    }).toList();

    // Sağ tarafı karıştır
    _rightItems.shuffle(Random());

    // ✅ DÜZELTME: Her round için yeni fade controller'lar oluştur
    _fadeControllers.clear();
    for (var item in [..._leftItems, ..._rightItems]) {
      _fadeControllers[item.id] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    }

    // Başlangıç değerlerini sıfırla (round başına)
    // STREAK DEĞİŞKENİNİ SIFIRLAMIYORUZ, ROUNDLAR ARASINDA KORUNACAK
    _score = 0;
    _moves = 0;
    // _streak = 0; -> BU SATIRI KALDIRIYORUZ
    _perfectMultiplier = 0;
    _matchedItems.clear();
    if (_currentRound == 1) {
      _totalScore = 0; // ✅ BU SATIR EKSİK OLMUŞ OLABİLİR!
    }
  }
  List<T> _getRandomSublist<T>(List<T> items, int count) {
    final shuffled = List<T>.from(items)..shuffle(Random());
    return shuffled.take(count).toList();
  }

  void handleItemTap(ItemModel item) {
    if (_gameOver || _isPaused || _isRoundCompleting || _isGameCompleting) return;

    HapticFeedback.lightImpact();

    if (item.side == ItemSide.left) {
      if (_selectedLeftItem != null && _selectedLeftItem!.id == item.id) {
        // Önceden seçili öğeye tıklandıysa seçimi kaldır
        setState(() {
          _selectedLeftItem!.isSelected = false;
          _selectedLeftItem = null;
        });
        return;
      }

      // Önceki seçimi kaldır
      if (_selectedLeftItem != null) {
        _selectedLeftItem!.isSelected = false;
      }

      setState(() {
        _selectedLeftItem = item;
        _selectedLeftItem!.isSelected = true;
      });

      if (_selectedRightItem != null) {
        // ✅ DÜZELTME: Her iki taraftan da öğe seçildiyse eşleştirmeyi kontrol et
        checkMatch();
      }
    } else {
      if (_selectedRightItem != null && _selectedRightItem!.id == item.id) {
        // Önceden seçili öğeye tıklandıysa seçimi kaldır
        setState(() {
          _selectedRightItem!.isSelected = false;
          _selectedRightItem = null;
        });
        return;
      }

      // Önceki seçimi kaldır
      if (_selectedRightItem != null) {
        _selectedRightItem!.isSelected = false;
      }

      setState(() {
        _selectedRightItem = item;
        _selectedRightItem!.isSelected = true;
      });

      if (_selectedLeftItem != null) {
        // ✅ DÜZELTME: Her iki taraftan da öğe seçildiyse eşleştirmeyi kontrol et
        checkMatch();
      }
    }
  }
  Widget _buildUserPointsDisplay(Map<String, Color> colors) {
    return AnimatedBuilder(
      animation: _pointAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isAddingPoints ? _pointScaleAnimation.value : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors['primary']?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: colors['primary']?.withOpacity(0.3) ??
                      Colors.purple.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle,
                  color: colors['primary'],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Toplam Puanınız:",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colors['text']?.withOpacity(0.9),
                  ),
                ),
                const SizedBox(width: 8),
                _isLoadingUserPoints
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colors['primary'] ?? Colors.purple),
                        ),
                      )
                    : Row(
                        children: [
                          // Yeni puan animasyonu sırasında eski puanı göster
                          if (_isAddingPoints)
                            Text(
                              "$_previousTotalPoints",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.lineThrough,
                                decorationColor:
                                    colors['text']?.withOpacity(0.5),
                                color: colors['text']?.withOpacity(0.5),
                              ),
                            ),

                          // Puan animasyonu sırasında oku göster
                          if (_isAddingPoints)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: colors['primary'],
                              ),
                            ),

                          // Gösterilen puan (animasyon sırasında artacak)
                          Text(
                            "$_displayedPoints",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isAddingPoints
                                  ? colors['primary']
                                  : colors['text'],
                            ),
                          ),

                          // Puan artışı göster
                          if (_isAddingPoints)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                "(+${_newPointsToAdd})",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _checkGameCompletionSafely() {
    // ✅ Çoklu çağrı koruması ekle
    if (_gameOver || _gameWon || _isCheckingCompletion) return;

    setState(() {
      _isCheckingCompletion = true;
    });

    // Kısa bir gecikme ile kontrol et
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      bool hasItemsLeft = _leftItems.isNotEmpty && _rightItems.isNotEmpty;

      if (!hasItemsLeft) {
        print("🎯 Oyun tamamlandı - Round: $_currentRound/$_totalRounds");
        _calculateFinalScore();

        if (_currentRound < _totalRounds) {
          _loadNextRound();
        } else {
          setState(() {
            _gameWon = true;
            _gameOver = true;
          });
          _updateStats();
          _confettiController.play();
        }
      }

      setState(() {
        _isCheckingCompletion = false;
      });
    });
  }

// Class seviyesinde değişken ekle
  bool _isCheckingCompletion = false;

  void checkMatch() {
    if (_selectedLeftItem == null || _selectedRightItem == null) return;
    if (_gameOver || _isPaused || _isRoundCompleting || _isGameCompleting) return;

    print("🔍 Eşleşme kontrolü - Sol ID: ${_selectedLeftItem!.id}, Sağ ID: ${_selectedRightItem!.id}");

    if (_selectedLeftItem!.id == _selectedRightItem!.id) {
      // ==================== BAŞARILI EŞLEŞME ====================

      print("✅ Eşleşme başarılı!");

      // Son kelime kontrolü
      bool isLastMatch = (_leftItems.length == 1 && _rightItems.length == 1);

      if (isLastMatch) {
        print("🎯 SON KELİME EŞLEŞTİRİLİYOR!");
        _handleLastMatchSecurely();
        return;
      }

      // Normal eşleşme işlemi
      _handleSuccessfulMatch();

    } else {
      // ==================== BAŞARISIZ EŞLEŞME ====================

      print("❌ Eşleşme başarısız!");

      // ✅ DÜZELTME: Joker kontrolü ÖNCE yapılmalı (seri kesilmeden önce)
      if (_hasSeriesSaver && !_usedSeriesSaver && _scoreManager.streak >= 5) {
        print("🃏 Joker kullanım şartları karşılandı - Dialog gösteriliyor");
        _showSeriesSaverDialog();
        return;
      }

      // Joker yoksa veya kullanılamıyorsa normal işlem
      print("🚫 Joker kullanılamıyor - Normal hata işlemi");
      _processNormalMismatchWithStreakBreak();
    }
  }  /// Başarılı eşleşme işlemi
  void _handleSuccessfulMatch() {
    // ScoreManager'a bildirme
    _scoreManager.addMatchScore();

    // Öğeleri işaretle
    _selectedLeftItem!.isCorrect = true;
    _selectedRightItem!.isCorrect = true;

    setState(() {
      _matchedItems.add(_selectedLeftItem!);
      _matchedItems.add(_selectedRightItem!);
    });

    // Animasyonları başlat
    _startMatchAnimations();

    // Ses efekti
    _playMatchSound();
    _correctMatchController.forward(from: 0.0);

    // Güvenli kaldırma işlemi
    _removeMatchedItemsSafely();
  }

  /// Son kelime güvenli işlemi
  void _handleLastMatchSecurely() {
    print("🔥 Son kelime güvenli işlem başlatıldı");

    // Eğer zaten bir tamamlanma işlemi varsa dur
    if (_isRoundCompleting || _isGameCompleting) {
      print("⏸️ Tamamlanma işlemi zaten devam ediyor");
      return;
    }

    // ScoreManager'a bildirme
    _scoreManager.addMatchScore();

    // Öğeleri işaretle
    _selectedLeftItem!.isCorrect = true;
    _selectedRightItem!.isCorrect = true;

    setState(() {
      _matchedItems.add(_selectedLeftItem!);
      _matchedItems.add(_selectedRightItem!);
    });

    // Ses efekti
    _playMatchSound();
    _correctMatchController.forward(from: 0.0);

    // ✅ KISA ANİMASYON İLE DOĞRUDAN LİSTELERİ TEMİZLE
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || _isRoundCompleting || _isGameCompleting) return;

      print("🎯 Son kelime - listeler temizleniyor");

      setState(() {
        _leftItems.clear();
        _rightItems.clear();
        _clearSelections();
      });

      // Anında tamamlanma kontrolü
      _checkCompletion(context: "last_match_completed");
    });
  }
  /// Tur skorunu hesapla
  void _calculateRoundScore() {
    if (_currentRoundResult != null) {
      print("⚠️ Bu tur için skor zaten hesaplandı");
      return;
    }

    print("📊 Tur $_currentRound skoru hesaplanıyor...");

    _scoreManager.timeRemaining = _timeRemaining;
    _currentRoundResult = _scoreManager.calculateRoundResult();

    print("💰 Tur skoru: ${_currentRoundResult!.finalRoundScore}");
  }

  /// Sonraki tur başlatma (manuel)
  void _startNextRoundManually() {
    if (_isRoundCompleting || _isGameCompleting) {
      print("⏸️ Tur değişimi zaten devam ediyor");
      return;
    }

    print("🎮 Manuel sonraki tur başlatılıyor...");

    // Kullanıcı puanını güncelle
    if (_currentRoundResult != null) {
      int newUserPoints = _currentUserPoints + _currentRoundResult!.finalRoundScore;
      _updateUserScore(newUserPoints);
    }

    setState(() {
      _currentRound++;
      _isPreparingNextRound = true;
      _currentRoundResult = null; // Yeni tur için sıfırla
      _roundResultCalculated = false;
      _processedMatches.clear();
    });

    // Kısa hazırlık animasyonu
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isPreparingNextRound = false;
          initGame(); // Yeni round'u başlat
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateAllItemPositions();
        });
      }
    });
  }

  // ===== 6. HATA YÖNETİMİ =====

  /// Tutarsız durum yönetimi
  void _handleInconsistentState() {
    print("🔧 Tutarsız oyun durumu düzeltiliyor...");

    setState(() {
      _clearSelections();
    });

    // Liste durumlarını kontrol et
    if (_leftItems.length != _rightItems.length) {
      print("⚠️ Liste uzunlukları farklı - Sol: ${_leftItems.length}, Sağ: ${_rightItems.length}");

      // Eğer her iki liste de boşsa, turu tamamla
      if (_leftItems.isEmpty && _rightItems.isEmpty) {
        _checkCompletion(context: "inconsistent_state_both_empty");
      }
    }
  }

  /// Oyun durumu validasyonu
  bool _validateGameState() {
    // Temel kontroller
    if (_leftItems.length != _rightItems.length) {
      print("⚠️ Liste uzunlukları eşit değil! Sol: ${_leftItems.length}, Sağ: ${_rightItems.length}");
      return false;
    }

    // ID benzersizlik kontrolü
    Set<int> leftIds = _leftItems.map((e) => e.id).toSet();
    Set<int> rightIds = _rightItems.map((e) => e.id).toSet();

    if (leftIds.length != _leftItems.length || rightIds.length != _rightItems.length) {
      print("⚠️ Tekrar eden ID'ler bulundu!");
      return false;
    }

    // ID uyumu kontrolü
    if (!leftIds.every((id) => rightIds.contains(id))) {
      print("⚠️ Sol ve sağ listeler farklı ID'lere sahip!");
      return false;
    }

    return true;
  }
// ✅ YENİ METOD: Son kelime özel işlemi
  void _handleLastMatch() {
    print("🔥 Son kelime işlemi başlatıldı");

    // ScoreManager'a doğru eşleşme bildir
    _scoreManager.addMatchScore();

    // Seçili öğeleri işaretle
    _selectedLeftItem!.isCorrect = true;
    _selectedRightItem!.isCorrect = true;

    setState(() {
      _matchedItems.add(_selectedLeftItem!);
      _matchedItems.add(_selectedRightItem!);
    });

    // Ses efekti
    _playMatchSound();
    _correctMatchController.forward(from: 0.0);

    // ✅ Son kelime için kısa animasyon süresi
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      print("🎯 Son kelime animasyonu tamamlandı, oyun bitiriliyor");

      setState(() {
        // Listeleri temizle
        _leftItems.clear();
        _rightItems.clear();

        // Seçimleri temizle
        _selectedLeftItem?.isSelected = false;
        _selectedRightItem?.isSelected = false;
        _selectedLeftItem = null;
        _selectedRightItem = null;
      });

      // ✅ Direkt oyun bitiş kontrolü - gecikme olmadan
      _checkGameCompletionSafely();
    });
  }
  void _checkGameCompletion() {
    // Kısa bir gecikme ile kontrol et (animasyonların başlaması için)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      if (_leftItems.isEmpty && _rightItems.isEmpty) {
        _calculateFinalScore();
        if (_currentRound < _totalRounds) {
          _loadNextRound();
        } else {
          setState(() {
            _gameWon = true;
            _gameOver = true;
          });
          _updateStats();
          _confettiController.play();
        }
      }
    });
  }
  Widget _buildSeriesSaverIndicator(Map<String, Color> colors) {
    if (!_hasSeriesSaver || _usedSeriesSaver) {
      return const SizedBox.shrink(); // Joker yoksa hiçbir şey gösterme
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            "Joker",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

// ✅ DÜZELTME: processNormalMismatchWithStreakBreak metodunu güncelle
  void _processNormalMismatchWithStreakBreak() {
    print("💥 Seri kesiliyor - Önceki seri: ${_scoreManager.streak}");

    // ScoreManager'a yanlış eşleşme bildir (bu seriyi keser)
    _scoreManager.addMissScore();

    print("📉 Yeni seri değeri: ${_scoreManager.streak}");

    _selectedLeftItem!.isWrong = true;
    _selectedRightItem!.isWrong = true;

    _playWrongSound();
    _wrongMatchController
        .forward(from: 0.0)
        .then((_) => _wrongMatchController.reverse());
    _shakeController.forward(from: 0.0).then((_) => _shakeController.reverse());

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _selectedLeftItem
          ?..isSelected = false
          ..isCorrect = false
          ..isWrong = false;
        _selectedRightItem
          ?..isSelected = false
          ..isCorrect = false
          ..isWrong = false;
        _selectedLeftItem = null;
        _selectedRightItem = null;
      });
    });
  }
  void _processNormalMismatch() {

    // ✅ MUTLAKA seriyi kes
    _processNormalMismatchWithStreakBreak();
  }

  // Eşleşen öğeleri kaldır ve kalan öğeleri yeniden düzenle
  void _removeMatchedItemsAndReorganize() {
    final int matchedId = _selectedLeftItem!.id;

    // ✅ Önce animasyonların bitmesini bekle
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        // Güvenli şekilde kaldır
        _leftItems.removeWhere((item) => item.id == matchedId);
        _rightItems.removeWhere((item) => item.id == matchedId);
      });

      // Pozisyonları güncelle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateAllItemPositions();
          // Oyun bitiş kontrolünü en son yap
          _checkGameCompletionSafely();
        }
      });
    });
  }
  void _calculateFinalScore() {

    // ScoreManager'ı güncelle
    _scoreManager.setTotalRounds(_totalRounds);
    _scoreManager.timeRemaining = _timeRemaining;

    // Mükemmel round sayacını güncelle
    if (_perfectMultiplier == _gameWords.length) {
      _scoreManager.markRoundAsPerfect();
    }

    // Final sonuç hesapla
    ScoreResult result = _scoreManager.calculateFinalGameResult();

    // Debug bilgilerini yazdır

    // Kullanıcı puanını güncelle
    _updateUserScore(result.newUserTotal);

    // Başarı kontrolü
    if (result.perfectBonus > 0) {
      _perfectRoundCount++;
      _perfectRoundMessages.add("Mükemmel oyun tamamlandı!");
    }

    // Başarı rozetleri
    if (result.bestStreak > 10) {
      _earnedAchievements.add(Achievement.comboMaster);
    }
    if (_timeRemaining > _scoreManager.initialTime * 0.7) {
      _earnedAchievements.add(Achievement.speedster);
    }
    if (result.perfectBonus > 0) {
      _earnedAchievements.add(Achievement.perfectScore);
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color,
      Map<String, Color> colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colors['text']?.withOpacity(0.9),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors['text'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusRow(String label, int value, Map<String, Color> colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "• $label",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: colors['text']?.withOpacity(0.8),
            ),
          ),
          Text(
            "+$value",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getDifficultyText() {
    switch (widget.difficulty) {
      case DifficultyLevel.easy:
        return "Kolay";
      case DifficultyLevel.medium:
        return "Orta";
      case DifficultyLevel.hard:
        return "Zor";
    }
  }

  void _updateStats() async {
    _gameStats.totalGames++;
    if (_gameWon) {
      _gameStats.wins++;

      if (_gameStats.wins == 1) {
        _earnedAchievements.add(Achievement.firstWin);
      }

      if (_perfectMultiplier == _gameWords.length) {
        _gameStats.perfectGames++;
      }

      if (_score > _gameStats.bestScore) {
        _gameStats.bestScore = _score;
      }

      if (_bestStreak > _gameStats.bestCombo) {
        _gameStats.bestCombo = _bestStreak;
      }

      // Ortalama süre hesapla
      int gameDuration = _initialTime - _timeRemaining;
      if (_gameStats.averageTime == 0) {
        _gameStats.averageTime = gameDuration;
      } else {
        _gameStats.averageTime =
            ((_gameStats.averageTime * (_gameStats.wins - 1)) + gameDuration) ~/
                _gameStats.wins;
      }

      // Zorluğu ve puanı log dosyasına ekleyelim
      String difficultyText = widget.difficulty == DifficultyLevel.hard
          ? "Zor"
          : widget.difficulty == DifficultyLevel.medium
              ? "Orta"
              : "Kolay";

      ApiService().sendUserLog(
          type: "OyunSonucu",
          log:
              "Eşleştirme Oyunu ($difficultyText) - $_score puan, $_perfectRoundCount mükemmel tur, $_bestStreak en iyi seri");
    }

    await _gameStats.saveStats();
  }

  void _playMatchSound() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  void _playWrongSound() {
    HapticFeedback.heavyImpact();
  }

  void startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_gameOver && !_isPaused) {
        // ✅ ROUND GEÇİŞ EKRANINDA TIMER DURDURMAK İÇİN
        bool isRoundTransition = _leftItems.isEmpty &&
            _rightItems.isEmpty &&
            _currentRound < _totalRounds;

        if (!isRoundTransition) {
          // Sadece normal oyunda timer çalışsın
          setState(() {
            if (_timeRemaining > 0) {
              _timeRemaining--;
            } else {
              _gameOver = true;
              _updateStats();
              ApiService().logSetEntry('Eşleştirme Oyunu', 'Süre Doldu', '');
            }
          });
        }

        startTimer(); // Timer'ı tekrar çağır
      }
    });
  }

  // ===== 7. OYUN SIFIRLAMA GÜVENLİĞİ =====
  void resetGame() {
    // Tüm timer'ları iptal et
    _roundCompletionTimer?.cancel();
    _gameCompletionTimer?.cancel();

    setState(() {
      _selectedLeftItem = null;
      _selectedRightItem = null;
      _matchedItems = [];
      _gameOver = false;
      _gameWon = false;
      _earnedAchievements = [];
      _currentRound = 1;
      _perfectRoundCount = 0;
      _perfectRoundMessages = [];

      // ✅ TÜM GÜVENLİK DEĞİŞKENLERİNİ SIFIRLA
      _isRoundCompleting = false;
      _isGameCompleting = false;
      _roundCompletionScheduled = false;
      _gameCompletionScheduled = false;
      _roundResultCalculated = false;
      _currentRoundResult = null;

      _processedMatches.clear();
      _lastLeftItemCount = 0;
      _lastRightItemCount = 0;

      // Joker durumu
      _usedSeriesSaver = false;
      _hasSeriesSaver = true;
      _showingSeriesSaverAnimation = false;
    });

    // ScoreManager'ı sıfırla
    _scoreManager.resetGame(_currentUserPoints);

    // Lottie controller'ı sıfırla
    if (_lottieChainController.isAnimating) {
      _lottieChainController.stop();
    }
    _lottieChainController.reset();

    // Fade controller'ları sıfırla
    for (var controller in _fadeControllers.values) {
      controller.reset();
      controller.dispose();
    }
    _fadeControllers.clear();

    _filterValidWords();
    initGame();
    startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAllItemPositions();
    });
  }

  void togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (!_isPaused) {
      startTimer();
    }
  }

  String getMatchTypeTitle() {
    switch (widget.matchType) {
      case MatchType.turkishEnglish:
        return "Türkçe - İngilizce";
      case MatchType.englishTurkish:
        return "İngilizce - Türkçe";
      case MatchType.definitionWord:
        return "Tanım - İngilizce";
      case MatchType.definitionTurkish:
        return "Tanım - Türkçe";
    }
  }

  // ===== 8. DISPOSE GÜVENLİĞİ =====
  @override
  void dispose() {
    // Tüm timer'ları iptal et
    _roundCompletionTimer?.cancel();
    _gameCompletionTimer?.cancel();

    // Mevcut dispose kodları...
    _controller.dispose();
    _shakeController.dispose();
    _wrongMatchController.dispose();
    _correctMatchController.dispose();
    _particleController.dispose();
    _confettiController.dispose();
    _pointAnimationController.dispose();
    _pauseAnimationController.dispose();
    _seriesSaverAnimationController.dispose();

    if (_lottieChainController.isAnimating) {
      _lottieChainController.stop();
    }
    _lottieChainController.dispose();

    for (var controller in _fadeControllers.values) {
      if (!controller.isAnimating) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  /// Eşleşme animasyonlarını başlat
  void _startMatchAnimations() {
    final leftController = _fadeControllers[_selectedLeftItem!.id]!;
    final rightController = _fadeControllers[_selectedRightItem!.id]!;

    _selectedLeftItem!.fadeAnimation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: leftController, curve: Curves.easeOut));
    _selectedLeftItem!.scaleAnimation = Tween<double>(begin: 1.0, end: 0.7)
        .animate(CurvedAnimation(parent: leftController, curve: Curves.easeOut));

    _selectedRightItem!.fadeAnimation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: rightController, curve: Curves.easeOut));
    _selectedRightItem!.scaleAnimation = Tween<double>(begin: 1.0, end: 0.7)
        .animate(CurvedAnimation(parent: rightController, curve: Curves.easeOut));

    leftController.forward();
    rightController.forward();
  }
  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? _darkModeColors() : _lightModeColors();
    _screenSize = MediaQuery.of(context).size;

    // Her build'de öğe pozisyonlarını güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAllItemPositions();
    });

    return Scaffold(
      backgroundColor: colors['background'],
      appBar: _buildAppBar(colors),
      body: Stack(
        children: [
          _buildGameContent(colors),
          if (_gameOver) _buildGameOverOverlay(colors),
          if (_isPaused) _buildPauseOverlay(colors),
          if (_showStats) _buildStatsOverlay(colors),

          // Puan ekleme bildirimi (isteğe bağlı)
          if (_isAddingPoints) _buildPointsAddedToast(_newPointsToAdd, colors),

          // Combo partikül efekti
          if (_particles > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ParticlePainter(
                    progress: _particles,
                    particleCount: 20,
                    color: colors['accent1'] ?? Colors.red,
                  ),
                ),
              ),
            ),
          if (_showingSeriesSaverAnimation) _buildSeriesSaverOverlay(),

          // Konfeti efekti
          Positioned(
            top: 0,
            left: _screenSize!.width / 2,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 1,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, Color> colors) {
    return AppBar(
      elevation: 0,
      backgroundColor: colors['background'],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDarkMode
                ? [const Color(0xFF1A3A80), const Color(0xFF0E2D6A)]
                : [const Color(0xFF3857B0), const Color(0xFF283890)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.compare_arrows, color: Colors.white, size: 28),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eşleştir',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Round $_currentRound/$_totalRounds',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.analytics, color: Colors.white),
          onPressed: () {
            setState(() {
              _showStats = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: resetGame,
        ),
      ],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

// buildScorePanel metodunu güncelleme
  Widget _buildScorePanel(Map<String, Color> colors) {
    double progressValue = _gameWords.length > 0
        ? 1.0 - (_leftItems.length / _gameWords.length)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors['cardBackground'],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Kullanıcı puanı ve joker göstergesi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: Center(child: _buildUserPointsDisplay(colors))),
              // ✅ YENİ: Joker göstergesi
              _buildSeriesSaverIndicator(colors),
            ],
          ),

          // Skor öğeleri - ScoreManager'dan al
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreItem(
                icon: Icons.timer,
                title: "Süre",
                value:
                    "${_timeRemaining ~/ 60}:${(_timeRemaining % 60).toString().padLeft(2, '0')}",
                color: _timeRemaining < 30
                    ? Colors.red
                    : (colors['text'] ?? Colors.black87),
                iconColor: _timeRemaining < 30
                    ? Colors.red
                    : (colors['primary'] ?? Colors.purple),
              ),
              _buildScoreItem(
                icon: Icons.star,
                title: "Puan",
                value: "${_scoreManager.displayScore}",
                color: colors['text'] ?? Colors.black87,
                iconColor: Colors.amber,
              ),
              _buildScoreItem(
                icon: Icons.swap_horiz,
                title: "Hamle",
                value: "${_scoreManager.moves}",
                color: colors['text'] ?? Colors.black87,
                iconColor: colors['primary'] ?? Colors.purple,
              ),
              _buildScoreItem(
                icon: Icons.local_fire_department,
                title: "Seri",
                value: "${_scoreManager.streak}",
                color: colors['text'] ?? Colors.black87,
                iconColor: _scoreManager.streak > 5
                    ? Colors.red
                    : _scoreManager.streak > 3
                        ? Colors.deepOrange
                        : _scoreManager.streak > 1
                            ? Colors.orangeAccent
                            : colors['text'] ?? Colors.black87,
              ),
            ],
          ),

          // Streak mesajı - ScoreManager'dan
          if (_scoreManager.streak > 1)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _scoreManager.streak > 5
                      ? AnimatedBuilder(
                          animation: _pauseAnimationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale:
                                  1.0 + (_pauseAnimationController.value * 0.3),
                              child: const Icon(Icons.local_fire_department,
                                  color: Colors.red, size: 20),
                            );
                          })
                      : Icon(
                          _scoreManager.streak > 3
                              ? Icons.whatshot
                              : Icons.local_fire_department,
                          color: _scoreManager.streak > 3
                              ? Colors.deepOrange
                              : Colors.orangeAccent,
                          size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _scoreManager.streak > 5
                        ? "${_scoreManager.streak}x SÜPER SERİ!"
                        : _scoreManager.streak > 3
                            ? "${_scoreManager.streak}x Büyük Seri!"
                            : "${_scoreManager.streak}x Combo!",
                    style: GoogleFonts.poppins(
                      color: _scoreManager.streak > 5
                          ? Colors.red
                          : _scoreManager.streak > 3
                              ? Colors.deepOrange
                              : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // İlerleme göstergesi
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: colors['border'],
              valueColor: AlwaysStoppedAnimation<Color>(
                  colors['primary'] ?? Colors.blue),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsAddedToast(int pointsAdded, Map<String, Color> colors) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      bottom:
          _isAddingPoints ? 20 : -100, // Animasyon bitince ekrandan kaybolsun
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors['primary']?.withOpacity(0.9) ??
                Colors.purple.withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_circle,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                "$pointsAdded Puan Kazandınız!",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(List<ItemModel> items, BoxConstraints constraints,
      Map<String, Color> colors) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isMatched = _matchedItems.any(
            (matched) => matched.id == item.id && matched.side == item.side);
        final isSelected = item.isSelected;
        final fadeController = _fadeControllers[item.id]!;

        // Metinin uzunluğuna göre yazı tipi boyutunu dinamik hesaplayalım
        double getFontSize(String text) {
          if (text.length > 40) return 11;
          if (text.length > 25) return 12;
          if (text.length > 15) return 13;
          return 14;
        }

        // Metinin uzunluğuna göre kutu yüksekliğini hesaplayalım
        double getMinHeight(String text) {
          if (text.length > 40) return 90;
          if (text.length > 25) return 80;
          if (text.length > 15) return 70;
          return 60;
        }

        return LayoutBuilder(
          builder: (context, itemConstraints) {
            Matrix4 transformMatrix = Matrix4.identity();
            double scale = 1.0;

            if (isSelected && item.isWrong) {
              transformMatrix.translate(_shakeAnimation.value, 0.0);
              scale = _wrongMatchAnimation.value;
            } else if (isSelected) {
              scale = 1.05;
            }

            return AnimatedBuilder(
              animation: Listenable.merge([
                fadeController,
                _shakeController,
                _wrongMatchController,
                _correctMatchController,
              ]),
              builder: (context, child) {
                double fadeValue = 1.0;
                double itemScale = scale;
                Color? backgroundColor;

                if (item.fadeAnimation != null && item.scaleAnimation != null) {
                  fadeValue = item.fadeAnimation!.value;
                  itemScale = item.scaleAnimation!.value * scale;
                }

                if (item.isCorrect) {
                  backgroundColor = _correctMatchAnimation.value;
                }

                return Opacity(
                  opacity: fadeValue,
                  child: Transform.scale(
                    scale: itemScale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      transform: transformMatrix,
                      child: GestureDetector(
                        onTap: isMatched ? null : () => handleItemTap(item),
                        child: Container(
                          key: item.key,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          constraints: BoxConstraints(
                              minHeight: getMinHeight(item.text)),
                          decoration: BoxDecoration(
                            gradient: isMatched
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.green.shade300,
                                      Colors.green.shade500
                                    ],
                                  )
                                : isSelected
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.blue.shade300,
                                          Colors.blue.shade500
                                        ],
                                      )
                                    : null,
                            color: backgroundColor ??
                                (!isMatched && !isSelected
                                    ? colors['cardBackground'] ?? Colors.white
                                    : null),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isMatched
                                    ? Colors.green.withOpacity(0.3)
                                    : isSelected
                                        ? Colors.blue.withOpacity(0.3)
                                        : Colors.black.withOpacity(0.08),
                                blurRadius: isSelected ? 12 : 8,
                                offset: Offset(0, isSelected ? 4 : 3),
                              ),
                            ],
                            border: Border.all(
                              color: isMatched
                                  ? Colors.green
                                  : isSelected
                                      ? Colors.blue
                                      : item.isWrong
                                          ? Colors.red.withOpacity(0.5)
                                          : colors['border'] ??
                                              Colors.grey.shade300,
                              width: isMatched || isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isMatched)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  item.text,
                                  style: GoogleFonts.poppins(
                                    color: isMatched || isSelected
                                        ? Colors.white
                                        : colors['text'] ?? Colors.black87,
                                    fontSize: getFontSize(item.text),
                                    fontWeight: isMatched || isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    height:
                                        1.2, // Satır yüksekliğini küçültelim
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow
                                      .visible, // Değiştirildi: Taşmaya izin verelim
                                  maxLines: null, // Sınırsız satır
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

// _buildGameOverOverlay metodunu güncelleyin
  Widget _buildGameOverOverlay(Map<String, Color> colors) {
    final bool isWin = _gameWon;

    // ✅ DÜZELTME: Final oyun için özel hesaplama
    final ScoreResult finalResult = _scoreManager.calculateFinalGameResult();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: colors['cardBackground'],
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450.0, minWidth: 300.0),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık
                  Text(
                    isWin ? "🎉 Oyun Tamamlandı!" : "⏰ Süre Doldu!",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors['text'],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ FINAL SKOR DETAYLARI
                  _buildFinalScoreDetails(finalResult, colors),

                  const SizedBox(height: 20),
                  _buildActionButtons(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// ✅ YENİ: Final skor detayları widget'ı
  Widget _buildFinalScoreDetails(
      ScoreResult result, Map<String, Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors['primary']?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colors['primary']?.withOpacity(0.3) ??
                Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🏆 Final Skor Özeti",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors['primary'],
            ),
          ),
          const SizedBox(height: 12),

          // Tüm roundlardan toplanan puanlar
          _buildScoreRow("Tüm Turlardan Toplam", result.baseScore, colors),

          // Final bonuslar
          if (result.gameCompletionBonus != null &&
              result.gameCompletionBonus! > 0)
            _buildScoreRow(
                "🎯 Oyun Bitirme Bonusu", result.gameCompletionBonus!, colors),

          if (result.perfectBonus > 0)
            _buildScoreRow(
                "⭐ Mükemmel Seri Bonusu", result.perfectBonus, colors),

          if (result.consistencyBonus != null && result.consistencyBonus! > 0)
            _buildScoreRow(
                "🔥 Tutarlılık Bonusu", result.consistencyBonus!, colors),

          Divider(color: colors['border']),

          // Zorluk çarpanı
          _buildScoreRow("⚡ Zorluk Çarpanı",
              "x${result.difficultyMultiplier.toStringAsFixed(1)}", colors,
              isMultiplier: true),

          const SizedBox(height: 8),

          // GRAND TOTAL
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.3),
                  Colors.orange.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Toplam:",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors['text'],
                      ),
                    ),
                  ],
                ),
                Text(
                  "${result.finalRoundScore}",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Yeni toplam puan
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors['primary']?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Yeni Toplam Puanınız:",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colors['text'],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.arrow_forward,
                        size: 14, color: colors['primary']),
                    Text(
                      "${result.newUserTotal}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors['primary'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ✅ YENİ: Oyun özeti widget'ı
  Widget _buildGameSummary(ScoreResult result, Map<String, Color> colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors['cardBackground']?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: colors['border']?.withOpacity(0.3) ??
                Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📊 Oyun Özeti",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors['text']?.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem("Tur", "$_currentRound", Icons.flag, colors),
              _buildSummaryItem("En İyi Seri", "${result.bestStreak}",
                  Icons.local_fire_department, colors),
              _buildSummaryItem(
                  "Hamle", "${result.moves}", Icons.swap_horiz, colors),
              _buildSummaryItem(
                  "Mükemmel", "$_perfectRoundCount", Icons.star, colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Map<String, Color> colors) {
    return Column(
      children: [
        Icon(icon, size: 16, color: colors['primary']),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors['text'],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: colors['text']?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreResultDetails(
      ScoreResult result, Map<String, Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors['primary']?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colors['primary']?.withOpacity(0.3) ??
                Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Puan Detayları",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors['primary'],
            ),
          ),
          const SizedBox(height: 12),

          _buildScoreRow("Temel Puan", result.baseScore, colors),
          if (result.timeBonus > 0)
            _buildScoreRow("Zaman Bonusu", result.timeBonus, colors),
          if (result.perfectBonus > 0)
            _buildScoreRow("Mükemmel Bonus", result.perfectBonus, colors),

          Divider(color: colors['border']),

          _buildScoreRow("Zorluk Çarpanı",
              "x${result.difficultyMultiplier.toStringAsFixed(1)}", colors,
              isMultiplier: true),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors['primary']?.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Toplam Kazanılan:",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors['text'],
                  ),
                ),
                Text(
                  "${result.finalRoundScore}",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors['primary'],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Yeni toplam puan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Yeni Toplam Puanınız:",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colors['text'],
                ),
              ),
              Row(
                children: [
                  Text(
                    "${result.newUserTotal - result.totalGameScore}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: colors['text']?.withOpacity(0.6),
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 14, color: colors['primary']),
                  Text(
                    "${result.newUserTotal}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors['primary'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, dynamic value, Map<String, Color> colors,
      {bool isMultiplier = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colors['text']?.withOpacity(0.8),
            ),
          ),
          Text(
            isMultiplier ? value.toString() : "+$value",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isMultiplier ? Colors.purple : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedScoreTable(Map<String, Color> colors, bool isWin) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors['cardBackground']?.withOpacity(0.5) ??
            Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              colors['text']?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // İki kolon yerine 4 kolon yapısı kullandık - daha kompakt
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Puan
              Column(
                children: [
                  Icon(
                    Icons.star,
                    size: 20,
                    color:
                        isWin ? Colors.amber : colors['primary'] ?? Colors.blue,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Puan",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: colors['text']?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    "$_score",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors['text'],
                    ),
                  ),
                ],
              ),

              // Kalan Süre
              Column(
                children: [
                  const Icon(
                    Icons.timer,
                    size: 20,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Süre",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: colors['text']?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    "${_timeRemaining ~/ 60}:${(_timeRemaining % 60).toString().padLeft(2, '0')}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors['text'],
                    ),
                  ),
                ],
              ),

              // Hamle
              Column(
                children: [
                  Icon(
                    Icons.sync_alt,
                    size: 20,
                    color: colors['primary'] ?? Colors.blue,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Hamle",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: colors['text']?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    "$_moves",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors['text'],
                    ),
                  ),
                ],
              ),

              // En İyi Seri
              Column(
                children: [
                  const Icon(
                    Icons.whatshot,
                    size: 20,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "En İyi Seri",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: colors['text']?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    "$_bestStreak",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors['text'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

// Bölücü widget - bölümleri ayırmak için
  Widget _buildDivider(String title, Map<String, Color> colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: colors['text']?.withOpacity(0.2) ??
                  Colors.grey.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors['text']?.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: colors['text']?.withOpacity(0.2) ??
                  Colors.grey.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

// Başarılar widgeti
  Widget _buildAchievements(Map<String, Color> colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _earnedAchievements.map((achievement) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getAchievementIcon(achievement),
                size: 14,
                color: Colors.amber,
              ),
              const SizedBox(width: 4),
              Text(
                _getAchievementText(achievement),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

// Mükemmel turlar widgeti
  Widget _buildPerfectRounds(Map<String, Color> colors) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _perfectRoundMessages.map((message) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 14,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (_perfectRoundCount > 1)
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  "$_perfectRoundCount tur boyunca mükemmel seri!",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

// Butonlar - İstersen sütun halinde veya yan yana görüntüleyebilirsin
  Widget _buildActionButtons(Map<String, Color> colors) {
    // İki butonu alt alta yerleştiren düzen
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
          ),
          label: Text(
            "Tekrar Oyna",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors['primary'],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            minimumSize: const Size(double.infinity, 50), // Genişliği max yapıyoruz
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
            shadowColor: colors['primary']?.withOpacity(0.5),
          ),
          onPressed: resetGame,
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(
            Icons.home_rounded,
            color: Colors.white,
          ),
          label: Text(
            "Ana Sayfa",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors['secondary'],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            minimumSize: const Size(double.infinity, 50), // Genişliği max yapıyoruz
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
            shadowColor: colors['secondary']?.withOpacity(0.5),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );

    /* Yan yana butonlar istenirse bu kodu kullanabilirsiniz
  return Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          icon: Icon(
            Icons.home_rounded,
            color: Colors.white,
            size: 18,
          ),
          label: Text(
            "Ana Sayfa",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors['secondary'],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      SizedBox(width: 10),
      Expanded(
        child: ElevatedButton.icon(
          icon: Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 18,
          ),
          label: Text(
            "Tekrar",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors['primary'],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: resetGame,
        ),
      ),
    ],
  );
  */
  }

  Widget _buildFunButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        shadowColor: color.withOpacity(0.5),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? color, size: 28),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: color.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPauseOverlay(Map<String, Color> colors) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: AnimatedBuilder(
          animation: _pauseAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pauseAnimationController.value * 0.05),
              child: child,
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: colors['primary']?.withOpacity(0.4) ??
                    Colors.blue.withOpacity(0.4),
                width: 2.0,
              ),
            ),
            color: colors['cardBackground'],
            elevation: 20,
            shadowColor: colors['primary']?.withOpacity(0.3) ??
                Colors.blue.withOpacity(0.3),
            child: Container(
              padding: const EdgeInsets.all(32),
              width: _screenSize!.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Eğlenceli pause ikonu
                  AnimatedBuilder(
                      animation: _pauseAnimationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: (_pauseAnimationController.value * 0.2) - 0.1,
                          child: Icon(
                            Icons.emoji_emotions, // Gülen emoji ikonu
                            size: 80,
                            color: Color.lerp(
                              colors['primary'] ?? Colors.blue,
                              colors['secondary'] ?? Colors.orange,
                              _pauseAnimationController.value,
                            ),
                          ),
                        );
                      }),
                  const SizedBox(height: 24),
                  // Dalga efektiyle yazı
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [
                          colors['primary'] ?? Colors.blue,
                          colors['secondary'] ?? Colors.orange,
                          colors['primary'] ?? Colors.blue,
                        ],
                        stops: [0.0, 0.5, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(
                            _pauseAnimationController.value * 2 * 3.14159),
                      ).createShader(bounds);
                    },
                    child: Text(
                      "Mola Zamanı!",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Biraz dinlen, sonra devam et!",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colors['text']?.withOpacity(0.8) ??
                          Colors.black87.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Daha şık ve eğlenceli butonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFunButton(
                        label: "Çıkış",
                        icon: Icons.exit_to_app_rounded,
                        color: colors['secondary'] ?? Colors.orange,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      _buildFunButton(
                        label: "Devam Et",
                        icon: Icons.sports_score_rounded, // Bayrak/Hedef ikonu
                        color: colors['primary'] ?? Colors.blue,
                        onPressed: togglePause,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverlay(Map<String, Color> colors) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: colors['cardBackground'],
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            width: _screenSize!.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "İstatistikler",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors['text'] ?? Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors['text']),
                      onPressed: () {
                        setState(() {
                          _showStats = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildStatCard(
                      icon: Icons.games,
                      title: "Toplam Oyun",
                      value: "${_gameStats.totalGames}",
                      color: colors['primary'] ?? Colors.blue,
                    ),
                    _buildStatCard(
                      icon: Icons.emoji_events,
                      title: "Kazanılan",
                      value: "${_gameStats.wins}",
                      color: Colors.amber,
                    ),
                    _buildStatCard(
                      icon: Icons.star,
                      title: "En Yüksek Skor",
                      value: "${_gameStats.bestScore}",
                      color: Colors.purple,
                    ),
                    _buildStatCard(
                      icon: Icons.whatshot,
                      title: "En İyi Combo",
                      value: "${_gameStats.bestCombo}",
                      color: Colors.deepOrange,
                    ),
                    _buildStatCard(
                      icon: Icons.timer,
                      title: "Ortalama Süre",
                      value: "${_gameStats.averageTime} sn",
                      color: Colors.green,
                    ),
                    _buildStatCard(
                      icon: Icons.workspace_premium,
                      title: "Mükemmel Oyun",
                      value: "${_gameStats.perfectGames}",
                      color: Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon(Achievement achievement) {
    switch (achievement) {
      case Achievement.perfectScore:
        return Icons.star;
      case Achievement.speedster:
        return Icons.speed;
      case Achievement.comboMaster:
        return Icons.whatshot;
      case Achievement.firstWin:
        return Icons.emoji_events;
    }
  }

  String _getAchievementText(Achievement achievement) {
    switch (achievement) {
      case Achievement.perfectScore:
        return "Mükemmel Skor";
      case Achievement.speedster:
        return "Hızlı Bitiş";
      case Achievement.comboMaster:
        return "Combo Ustası";
      case Achievement.firstWin:
        return "İlk Zafer";
    }
  }

  Map<String, Color> _lightModeColors() {
    return {
      'background': Colors.white,
      'primary': const Color(0xFFE42526),
      'secondary': const Color(0xFFF7A823),
      'cardBackground': Colors.white,
      'text': Colors.black87,
      'border': Colors.grey.shade300,
      'accent1': const Color(0xFFE42526),
      'accent2': const Color(0xFFF7A823),
    };
  }

  Map<String, Color> _darkModeColors() {
    return {
      'background': const Color(0xFF121212),
      'cardBackground': const Color(0xFF1E1E1E),
      'primary': Colors.purpleAccent,
      'secondary': Colors.blueAccent,
      'text': Colors.white,
      'border': Colors.grey.shade800,
    };
  }
}

// Partikül efekti için Custom Painter
class ParticlePainter extends CustomPainter {
  final double progress;
  final int particleCount;
  final Color color;

  ParticlePainter({
    required this.progress,
    required this.particleCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(1.0 - progress)
      ..style = PaintingStyle.fill;

    final random = Random(42); // Sabit seed değeri

    for (int i = 0; i < particleCount; i++) {
      final x = size.width * (0.3 + random.nextDouble() * 0.4);
      final y = size.height * (0.3 + random.nextDouble() * 0.4);

      final offsetX = (random.nextDouble() - 0.5) * 200 * progress;
      final offsetY = (random.nextDouble() - 0.5) * 200 * progress;

      final particleSize = (3 + random.nextDouble() * 5) * (1.0 - progress);

      canvas.drawCircle(
        Offset(x + offsetX, y + offsetY),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Zincir çizim sınıfı
class ChainPainter extends CustomPainter {
  final double breakProgress;
  final double repairProgress;
  final bool isDarkMode;

  ChainPainter({
    required this.breakProgress,
    required this.repairProgress,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint chainPaint = Paint()
      ..color = Colors.amber[700]!
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint shadowPaint = Paint()
      ..color = Colors.amber.withOpacity(0.3)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint glowPaint = Paint()
      ..color = Colors.amber.withOpacity(0.7)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double linkWidth = 20;
    final double centerY = size.height / 2;

    // Zincir halkalarını çiz
    for (int i = 0; i < 5; i++) {
      double startX = i * (linkWidth * 2) + 10;

      // Eğer kırık halka ise ayrı çiz
      if (i == 2) {
        // Kırılma animasyonu
        double breakOffset = breakProgress * 10;

        // Alt yarım halka
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(startX + linkWidth / 2, centerY + breakOffset),
            width: linkWidth,
            height: linkWidth,
          ),
          pi,
          pi,
          false,
          chainPaint,
        );

        // Üst yarım halka
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(startX + linkWidth / 2, centerY - breakOffset),
            width: linkWidth,
            height: linkWidth,
          ),
          0,
          pi,
          false,
          chainPaint,
        );

        // Tamir animasyonu
        if (repairProgress > 0) {
          // Tamir glow efekti
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(startX + linkWidth / 2, centerY),
              width: linkWidth,
              height: linkWidth,
            ),
            0,
            pi * 2,
            false,
            glowPaint..color = Colors.amber.withOpacity(repairProgress * 0.5),
          );

          // Alt yarım halka - tamir
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(startX + linkWidth / 2,
                  centerY + (breakOffset * (1 - repairProgress))),
              width: linkWidth,
              height: linkWidth,
            ),
            pi,
            pi,
            false,
            chainPaint,
          );

          // Üst yarım halka - tamir
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(startX + linkWidth / 2,
                  centerY - (breakOffset * (1 - repairProgress))),
              width: linkWidth,
              height: linkWidth,
            ),
            0,
            pi,
            false,
            chainPaint,
          );
        }
      } else {
        // Normal halka
        canvas.drawCircle(
          Offset(startX + linkWidth / 2, centerY),
          linkWidth / 2,
          shadowPaint,
        );

        canvas.drawCircle(
          Offset(startX + linkWidth / 2, centerY),
          linkWidth / 2,
          chainPaint,
        );
      }

      // Halkaları bağlayan çizgiler
      if (i < 4) {
        canvas.drawLine(
          Offset(startX + linkWidth, centerY),
          Offset(startX + linkWidth * 2, centerY),
          chainPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ChainPainter oldDelegate) {
    return oldDelegate.breakProgress != breakProgress ||
        oldDelegate.repairProgress != repairProgress;
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Diagonal çizgiler
    for (double i = 0; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i - size.height, 0),
        Offset(i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Puan Yönetimi Sınıfı
// Puan Yönetimi Sınıfı
class ScoreManager {
  // === TEK KAYNAK PUAN DEĞİŞKENLERİ ===
  int _currentRoundScore = 0; // Bu rounddaki puan
  int _allRoundsScore = 0; // Tüm roundların toplamı
  int _userTotalPoints = 0; // Kullanıcının genel puanı

  // ✅ YENİ: Son hesaplanan round sonucunu sakla
  ScoreResult? _lastRoundResult;

  // Bonus hesaplamaları için
  int _streak = 0;
  int _bestStreak = 0;
  int _perfectMatches = 0;
  int _moves = 0;

  // Oyun ayarları
  final DifficultyLevel difficulty;
  final int initialTime;
  late int timeRemaining;

  ScoreManager(
      {required this.difficulty,
      required this.initialTime,
      required int userCurrentPoints}) {
    timeRemaining = initialTime;
    _userTotalPoints = userCurrentPoints;
  }

  // Round bittiğinde final hesaplama
  ScoreResult calculateRoundResult() {
    // 1. Temel round skoru
    int baseRoundScore = _currentRoundScore;

    // 2. Zaman bonusu
    int timeBonus = _calculateTimeBonus();

    // 3. Mükemmellik bonusu (eğer hiç hata yoksa)
    int perfectBonus = _calculatePerfectBonus();

    // 4. Zorluk çarpanı
    double difficultyMultiplier = _getDifficultyMultiplier();

    // 5. Final round skoru
    int finalRoundScore =
        ((baseRoundScore + timeBonus + perfectBonus) * difficultyMultiplier)
            .round();

    // ✅ DÜZELTME: Sadece ilk hesaplamada toplama ekle
    if (_lastRoundResult == null ||
        _lastRoundResult!.finalRoundScore != finalRoundScore) {
      _allRoundsScore += finalRoundScore;
    }

    // ✅ Son sonucu sakla
    _lastRoundResult = ScoreResult(
      baseScore: baseRoundScore,
      timeBonus: timeBonus,
      perfectBonus: perfectBonus,
      difficultyMultiplier: difficultyMultiplier,
      finalRoundScore: finalRoundScore,
      totalGameScore: _allRoundsScore,
      newUserTotal: _userTotalPoints + _allRoundsScore,
      moves: _moves,
      bestStreak: _bestStreak,
      timeRemaining: timeRemaining,
    );

    return _lastRoundResult!;
  }

  // ✅ Son round sonucunu getir (UI için)
  ScoreResult? getLastRoundResult() => _lastRoundResult;

  // Yeni round başlatma
  void startNewRound() {
    _currentRoundScore = 0;
    _moves = 0;
    _perfectMatches = 0;
    // ✅ _lastRoundResult'ı temizleme, round geçişinde korunacak
  }

  // Oyun sıfırlama
  void resetGame(int newUserPoints) {
    _currentRoundScore = 0;
    _allRoundsScore = 0;
    _userTotalPoints = newUserPoints;
    _streak = 0;
    _bestStreak = 0;
    _perfectMatches = 0;
    _moves = 0;
    _lastRoundResult = null; // ✅ Oyun sıfırlandığında sonucu da temizle
  }

  // ✅ YENİ: Kullanıcı puanını güncelle
  void updateUserPoints(int newTotal) {
    _userTotalPoints = newTotal;
  }

  int _getBaseScore() {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 8;
      case DifficultyLevel.medium:
        return 10;
      case DifficultyLevel.hard:
        return 15;
    }
  }

  int _calculateStreakBonus() {
    if (_streak <= 1) return 0;

    int bonus = (_streak - 1) * 5; // Her seri için 5 puan
    if (_streak > 5) bonus += (_streak - 5) * 3; // 5'ten sonra 3 ek puan
    if (_streak > 10) bonus += (_streak - 10) * 5; // 10'dan sonra 5 ek puan

    return bonus;
  }

  int _calculateTimeBonus() {
    double timeRatio = timeRemaining / initialTime;
    if (timeRatio > 0.7) return 50;
    if (timeRatio > 0.5) return 25;
    if (timeRatio > 0.3) return 10;
    return 0;
  }

  int _calculatePerfectBonus() {
    // Eğer hiç yanlış yapmadıysa (moves == perfectMatches)
    if (_moves > 0 && _moves == _perfectMatches) {
      switch (difficulty) {
        case DifficultyLevel.easy:
          return 80;
        case DifficultyLevel.medium:
          return 100;
        case DifficultyLevel.hard:
          return 150;
      }
    }
    return 0;
  }

  double _getDifficultyMultiplier() {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 0.8;
      case DifficultyLevel.medium:
        return 1.0;
      case DifficultyLevel.hard:
        return 1.2;
    }
  }

  // Doğru eşleşme puanı
// ✅ DÜZELTME: ScoreManager'ın addMatchScore metodunu güncelleyin
  void addMatchScore() {
    _moves++;
    _streak++;
    _perfectMatches++;
    if (_streak > _bestStreak) _bestStreak = _streak;

    // Temel puan
    int baseScore = _getBaseScore();

    // Seri bonusu
    int streakBonus = _calculateStreakBonus();

    // Toplam puan
    int matchScore = baseScore + streakBonus;

    // Round skoruna ekle
    _currentRoundScore += matchScore;


    // ✅ YENİ: Joker kazanma kontrolü
    if (_streak == 10) {
    }
  }

  // Yanlış eşleşme
  void addMissScore() {
    _moves++;
    int oldStreak = _streak;
    _streak = 0; // ✅ Seri MUTLAKA sıfırlanır
  }

  // === GETTER METODLARİ ===
  int get currentRoundScore => _currentRoundScore;
  int get allRoundsScore => _allRoundsScore;
  int get userTotalPoints => _userTotalPoints;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  int get moves => _moves;
  int get perfectMatches => _perfectMatches;

  // Anlık puan bilgisi ekran için
  int get displayScore => _allRoundsScore + _currentRoundScore;
  ScoreResult calculateFinalGameResult() {
    // Son round için normal hesaplama
    ScoreResult lastRound = calculateRoundResult();

    // Final oyun bonusları
    int gameCompletionBonus = 100; // Oyunu bitirme bonusu
    int perfectGameBonus = _calculatePerfectGameBonus();
    int consistencyBonus = _calculateConsistencyBonus();

    // Final bonuslar toplamı
    int finalBonuses =
        gameCompletionBonus + perfectGameBonus + consistencyBonus;

    // Toplam final skor (tüm roundlar + final bonuslar)
    int finalTotalScore = _allRoundsScore + finalBonuses;

    return ScoreResult(
      baseScore: _allRoundsScore, // Tüm roundların toplamı
      timeBonus: gameCompletionBonus,
      perfectBonus: perfectGameBonus,
      difficultyMultiplier: _getDifficultyMultiplier(),
      finalRoundScore: finalTotalScore,
      totalGameScore: finalTotalScore,
      newUserTotal: _userTotalPoints + finalTotalScore,
      moves: _moves,
      bestStreak: _bestStreak,
      timeRemaining: timeRemaining,
      // ✅ YENİ ÖZELLIKLER
      gameCompletionBonus: gameCompletionBonus,
      consistencyBonus: consistencyBonus,
      isGameFinal: true,
    );
  }

  // Mükemmel oyun bonusu hesaplama
  int _calculatePerfectGameBonus() {
    // Eğer tüm turları hatasız tamamladıysa
    if (_perfectRoundCount >= _totalRounds) {
      switch (difficulty) {
        case DifficultyLevel.easy:
          return 200;
        case DifficultyLevel.medium:
          return 300;
        case DifficultyLevel.hard:
          return 500;
      }
    }

    // Çoğu turu mükemmel tamamladıysa
    double perfectRatio = _perfectRoundCount / _totalRounds;
    if (perfectRatio >= 0.8) {
      return (100 * perfectRatio).round();
    }

    return 0;
  }

  // Tutarlılık bonusu (sürekli iyi performans)
  int _calculateConsistencyBonus() {
    if (_bestStreak >= _totalRounds * 3) return 150; // Çok uzun seri
    if (_bestStreak >= _totalRounds * 2) return 100; // Uzun seri
    if (_bestStreak >= _totalRounds) return 50; // Orta seri
    return 0;
  }

  // ✅ YENİ: İstatistik takibi için ek değişkenler
  int _perfectRoundCount = 0;
  int _totalRounds = 1;

  // Round mükemmel tamamlandığında çağır
  void markRoundAsPerfect() {
    _perfectRoundCount++;
  }

  // Toplam round sayısını ayarla
  void setTotalRounds(int total) {
    _totalRounds = total;
  }
}

// Puan sonuç modeli
class ScoreResult {
  final int baseScore;
  final int timeBonus;
  final int perfectBonus;
  final double difficultyMultiplier;
  final int finalRoundScore;
  final int totalGameScore;
  final int newUserTotal;
  final int moves;
  final int bestStreak;
  final int timeRemaining;

  // ✅ YENİ ÖZELLIKLER
  final int? gameCompletionBonus;
  final int? consistencyBonus;
  final bool isGameFinal;

  ScoreResult({
    required this.baseScore,
    required this.timeBonus,
    required this.perfectBonus,
    required this.difficultyMultiplier,
    required this.finalRoundScore,
    required this.totalGameScore,
    required this.newUserTotal,
    required this.moves,
    required this.bestStreak,
    required this.timeRemaining,
    this.gameCompletionBonus,
    this.consistencyBonus,
    this.isGameFinal = false,
  });
}
class ShimmerPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDarkMode;

  ShimmerPainter({required this.animation, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.amber.withOpacity(0.1),
          Colors.orange.withOpacity(0.05),
          Colors.amber.withOpacity(0.1),
        ],
        stops: [
          0.0,
          animation.value,
          1.0,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Diagonal parıltı çizgileri
    for (double i = -size.height; i < size.width + size.height; i += 40) {
      final path = Path();
      path.moveTo(i + (animation.value * 100), 0);
      path.lineTo(i + (animation.value * 100) + 20, 0);
      path.lineTo(i + (animation.value * 100) - 20, size.height);
      path.lineTo(i + (animation.value * 100) - 40, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}

// ✅ GELİŞTİRİLMİŞ ZİNCİR ÇİZİM SINIFI
class UltraChainPainter extends CustomPainter {
  final double breakProgress;
  final double repairProgress;
  final bool isDarkMode;
  final double animationValue;

  UltraChainPainter({
    required this.breakProgress,
    required this.repairProgress,
    required this.isDarkMode,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double linkWidth = 35;
    final double linkHeight = 25;
    final double centerY = size.height / 2;
    final double startX = 25;
    final double linkSpacing = 45;

    // ✅ ZİNCİR HALKALARİNİ ÇİZ
    for (int i = 0; i < 6; i++) {
      double linkX = startX + (i * linkSpacing);
      bool isBrokenLink = (i == 2 || i == 3); // İki ortadaki halka kırık

      if (isBrokenLink) {
        _drawBrokenChainLink(
          canvas,
          linkX,
          centerY,
          linkWidth,
          linkHeight,
          i == 2 ? breakProgress : breakProgress, // Her iki halka da aynı anda kırılır
        );

        // Kırılma sonrası tamir
        if (repairProgress > 0) {
          _drawRepairEffect(canvas, linkX, centerY, linkWidth, linkHeight);
        }
      } else {
        _drawNormalChainLink(canvas, linkX, centerY, linkWidth, linkHeight, i);
      }
    }

    // ✅ HALKALARI BAĞLAYAN ZİNCİR PARÇALARI
    _drawConnectingChains(canvas, startX, centerY, linkSpacing, linkWidth);

    // ✅ KIRIILMA ANİNDA EFEKTLER
    if (breakProgress > 0.3 && breakProgress < 0.8) {
      _drawBreakEffects(canvas, startX + (2.5 * linkSpacing), centerY);
    }

    // ✅ TAMİR ANİNDA BÜYÜ EFEKTLERİ
    if (repairProgress > 0) {
      _drawMagicRepairEffect(canvas, startX + (2.5 * linkSpacing), centerY);
    }
  }

  // ✅ NORMAL ZİNCİR HALKASI
  void _drawNormalChainLink(Canvas canvas, double x, double y, double width, double height, int index) {
    // Derinlik için çoklu gölge
    for (int i = 3; i >= 0; i--) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.1 - (i * 0.02))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 - (i * 2)
        ..strokeCap = StrokeCap.round;

      _drawLinkShape(canvas, x + i, y + i, width, height, shadowPaint);
    }

    // Ana halka - gradient efekti
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.amber[300]!,
        Colors.amber[600]!,
        Colors.amber[800]!,
        Colors.amber[600]!,
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCenter(
        center: Offset(x, y),
        width: width * 2,
        height: height * 2,
      ))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    _drawLinkShape(canvas, x, y, width, height, paint);

    // ✅ METALİK PARLAKLIK EFEKTİ
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Üst kısımda parlak çizgi
    canvas.drawArc(
      Rect.fromCenter(center: Offset(x, y), width: width * 0.7, height: height * 0.7),
      -pi * 0.7,
      pi * 0.4,
      false,
      highlightPaint,
    );

    // ✅ ANİMASYON SIRASINDA PARILTILI EFEKT
    if (animationValue > 0.6) {
      final sparklePaint = Paint()
        ..color = Colors.white.withOpacity((animationValue - 0.6) * 2.5)
        ..style = PaintingStyle.fill;

      // Rastgele parıltı noktaları
      final random = Random(index * 42);
      for (int i = 0; i < 3; i++) {
        final sparkleX = x + (random.nextDouble() - 0.5) * width * 0.6;
        final sparkleY = y + (random.nextDouble() - 0.5) * height * 0.6;
        _drawSparkle(canvas, sparkleX, sparkleY, sparklePaint);
      }
    }
  }

  // ✅ KIRIK ZİNCİR HALKASI
  void _drawBrokenChainLink(Canvas canvas, double x, double y, double width, double height, double progress) {
    final breakOffset = progress * 20;
    final crackWidth = progress * 8;

    // Alt kısım
    final bottomPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.amber[600]!, Colors.red[400]!],
      ).createShader(Rect.fromLTWH(x - width/2, y, width, height/2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(x, y + breakOffset),
        width: width,
        height: height,
      ),
      0,
      pi,
      false,
      bottomPaint,
    );

    // Üst kısım
    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.red[400]!, Colors.amber[600]!],
      ).createShader(Rect.fromLTWH(x - width/2, y - height/2, width, height/2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(x, y - breakOffset),
        width: width,
        height: height,
      ),
      pi,
      pi,
      false,
      topPaint,
    );

    // ✅ KIRILMA NOKTASINDA ÇATLAK EFEKTİ
    if (progress > 0.2) {
      final crackPaint = Paint()
        ..color = Colors.red.withOpacity(0.8)
        ..strokeWidth = crackWidth
        ..strokeCap = StrokeCap.round;

      // Jagged kırılma çizgisi
      final path = Path();
      path.moveTo(x - crackWidth/2, y - breakOffset);
      path.lineTo(x + crackWidth/3, y - breakOffset/2);
      path.lineTo(x - crackWidth/3, y);
      path.lineTo(x + crackWidth/2, y + breakOffset/2);
      path.lineTo(x, y + breakOffset);

      canvas.drawPath(path, crackPaint);
    }
  }

  // ✅ HALKALARİ BAĞLAYAN ZİNCİR PARÇALARI
  void _drawConnectingChains(Canvas canvas, double startX, double centerY, double spacing, double linkWidth) {
    for (int i = 0; i < 5; i++) {
      double x1 = startX + (i * spacing) + linkWidth/2;
      double x2 = startX + ((i + 1) * spacing) - linkWidth/2;

      // Gölge
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x1 + 2, centerY + 2),
        Offset(x2 + 2, centerY + 2),
        shadowPaint,
      );

      // Ana bağlantı
      final connectPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.amber[700]!, Colors.amber[500]!, Colors.amber[700]!],
        ).createShader(Rect.fromLTWH(x1, centerY - 5, x2 - x1, 10))
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x1, centerY), Offset(x2, centerY), connectPaint);

      // Metalik parlak çizgi
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x1, centerY - 2),
        Offset(x2, centerY - 2),
        highlightPaint,
      );
    }
  }

  // ✅ KIRILMA EFEKTLERİ
  void _drawBreakEffects(Canvas canvas, double x, double y) {
    final random = Random(42);

    // Kıvılcım efekti
    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * 40;
      final sparkX = x + cos(angle) * distance;
      final sparkY = y + sin(angle) * distance;

      final sparkPaint = Paint()
        ..color = [Colors.orange, Colors.red, Colors.yellow][random.nextInt(3)]
            .withOpacity(0.8)
        ..strokeWidth = random.nextDouble() * 3 + 1
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(sparkX, sparkY),
        Offset(sparkX + cos(angle) * 8, sparkY + sin(angle) * 8),
        sparkPaint,
      );
    }

    // Patlama dalgası
    final wavePaint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset(x, y),
        i * 20.0,
        wavePaint,
      );
    }
  }

  // ✅ BÜYÜ TAMİR EFEKTİ
  void _drawMagicRepairEffect(Canvas canvas, double x, double y) {
    // Sihirli daire
    final magicPaint = Paint()
      ..color = Colors.cyan.withOpacity(repairProgress * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(Offset(x, y), 50 * repairProgress, magicPaint);

    // Sihirli partiküller
    final random = Random(24);
    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * pi + (animationValue * 2 * pi);
      final radius = 30 + (random.nextDouble() * 20);
      final particleX = x + cos(angle) * radius * repairProgress;
      final particleY = y + sin(angle) * radius * repairProgress;

      final particlePaint = Paint()
        ..color = [Colors.cyan, Colors.blue, Colors.purple, Colors.pink][random.nextInt(4)]
            .withOpacity(repairProgress * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(particleX, particleY), 3, particlePaint);
    }

    // Merkez glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(repairProgress),
          Colors.cyan.withOpacity(repairProgress * 0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 30));

    canvas.drawCircle(Offset(x, y), 30, glowPaint);
  }

  // ✅ TAMİR EFEKTİ
  void _drawRepairEffect(Canvas canvas, double x, double y, double width, double height) {
    if (repairProgress <= 0) return;

    // Tamir edilen halka
    final repairedPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.cyan.withOpacity(repairProgress),
          Colors.blue.withOpacity(repairProgress),
          Colors.purple.withOpacity(repairProgress),
        ],
      ).createShader(Rect.fromCenter(center: Offset(x, y), width: width * 2, height: height * 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    _drawLinkShape(canvas, x, y, width, height, repairedPaint);

    // Healing glow
    final healPaint = Paint()
      ..color = Colors.cyan.withOpacity(repairProgress * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    _drawLinkShape(canvas, x, y, width * 1.2, height * 1.2, healPaint);
  }

  // ✅ HALKA ŞEKLİ ÇİZME HELPER
  void _drawLinkShape(Canvas canvas, double x, double y, double width, double height, Paint paint) {
    final rect = Rect.fromCenter(center: Offset(x, y), width: width, height: height);
    canvas.drawOval(rect, paint);
  }

  // ✅ PARILTILI YILDIZ ÇİZME
  void _drawSparkle(Canvas canvas, double x, double y, Paint paint) {
    final path = Path();
    final size = 4.0;

    // 4 köşeli yıldız
    path.moveTo(x, y - size);
    path.lineTo(x + size/3, y - size/3);
    path.lineTo(x + size, y);
    path.lineTo(x + size/3, y + size/3);
    path.lineTo(x, y + size);
    path.lineTo(x - size/3, y + size/3);
    path.lineTo(x - size, y);
    path.lineTo(x - size/3, y - size/3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(UltraChainPainter oldDelegate) {
    return oldDelegate.breakProgress != breakProgress ||
        oldDelegate.repairProgress != repairProgress ||
        oldDelegate.animationValue != animationValue;
  }
}
// Puan sonuç modeli
