import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:kelibu/api.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kelibu/screens/video_player.dart';
import '../globalDart/urls.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../providers/volume_provider.dart';
import '../providers/language_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared_preferences/shared_preferences.dart';
import '../variables.dart';
import 'flash_card_star.dart';


class ScoreDisplay extends StatefulWidget {
  final ValueNotifier<int> userPointsNotifier;

  const ScoreDisplay({Key? key, required this.userPointsNotifier}) : super(key: key);

  @override
  _ScoreDisplayState createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends State<ScoreDisplay> with TickerProviderStateMixin {
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.transparent,
    ).animate(_colorController);

    widget.userPointsNotifier.addListener(_onScoreChanged);
  }

  void _onScoreChanged() {
    _colorController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _colorController.dispose();
    widget.userPointsNotifier.removeListener(_onScoreChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _colorAnimation.value ?? Colors.transparent,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/trophy.svg',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<int>(
                valueListenable: widget.userPointsNotifier,
                builder: (context, value, child) {
                  return Text(
                    "$value",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }}
class SwipeHintAnimation extends StatefulWidget {
  final Function onAnimationComplete;

  SwipeHintAnimation({Key? key, required this.onAnimationComplete}) : super(key: key);

  @override
  _SwipeHintAnimationState createState() => _SwipeHintAnimationState();
}
class _SwipeHintAnimationState extends State<SwipeHintAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.0),
      end: Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward().then((value) {
      widget.onAnimationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Icon(
          Icons.back_hand_outlined,
          size: 48.0,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class AnimatedProgressBar extends StatefulWidget {
  final double targetProgress;
  final int currentIndex;
  final int total;
  final double width;
  final double height;

  const AnimatedProgressBar({
    Key? key,
    required this.targetProgress,
    required this.currentIndex,
    required this.total,
    this.width = double.infinity,
    this.height = 20,
  }) : super(key: key);

  @override
  _AnimatedProgressBarState createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.targetProgress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetProgress != oldWidget.targetProgress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.targetProgress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      _animationController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          double safeWidth = constraints.maxWidth > 0 ? constraints.maxWidth : 100;
          return Stack(
            children: [
              _buildBaseBar(safeWidth),
              _buildProgressBar(safeWidth),
              _buildShineEffect(safeWidth),
              _buildProgressText(),
            ],
          );
        }
    );
  }

  Widget _buildBaseBar(double width) {
    return Container(
      width: width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(widget.height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double width) {
    return FractionallySizedBox(
      widthFactor: _progressAnimation.value,
      child: Container(
        width: width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purpleAccent, Colors.deepPurple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShineEffect(double width) {
    return FractionallySizedBox(
      widthFactor: _progressAnimation.value,
      child: FractionallySizedBox(
        widthFactor: 0.3,
        child: Transform.translate(
          offset: Offset(
            _shineAnimation.value * width,
            0,
          ),
          child: Container(
            width: width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.5),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressText() {
    return Positioned.fill(
      child: Center(
        child: Text(
          "${widget.currentIndex} / ${widget.total}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlashCardScreen extends StatefulWidget {
  final List<WordDetail> words;
  final int classroomId;
  final int studySetId;
  final bool isStarred;

  const FlashCardScreen({
    Key? key,
    required this.words,
    required this.classroomId,
    required this.studySetId,
    this.isStarred = false,  // Varsayılan değer false olarak ayarlandı
  }) : super(key: key);

  @override
  _FlashCardScreenState createState() => _FlashCardScreenState();
}
class _FlashCardScreenState extends State<FlashCardScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool isStarred = false;
  ValueNotifier<int> currentWordIndex = ValueNotifier(0);
  int wordId = 0;
  bool isShuffled = false;
  int totalWords = 0;
  DateTime? lastSwipeTime;
  ValueNotifier<bool> isWordStarred = ValueNotifier(false);
  bool _isDarkMode = false;
  bool _isAutoPlaying = false;
  Timer? _autoPlayTimer;
  double _autoPlaySpeed = 7.0; // saniye cinsinden

  late UserProvider userProvider;
  ValueNotifier<int> pointValueNotife = ValueNotifier(0);
  ValueNotifier<bool> isAnimationCompletedNotifier = ValueNotifier(false);
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  ValueNotifier<int> starredWordCountNotifier = ValueNotifier(0);
  void _toggleAutoPlay() {
    setState(() {
      _isAutoPlaying = !_isAutoPlaying;
      if (_isAutoPlaying) {
        _startAutoPlay();
        showCustomFlushbar(
          context,
          "Otomatik oynatma açıldı",
        );
      } else {
        _stopAutoPlay();
        showCustomFlushbar(
          context,
          "Otomatik oynatma kapatıldı",
        );
      }
    });
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(Duration(milliseconds: (_autoPlaySpeed * 1000).toInt()), (timer) {
      if (currentWordIndex.value < _currentWordList.length - 1) {
        final currentWord = _currentWordList[currentWordIndex.value];
        final currentCardKey = cardKeys[currentWord.id];

        // İngilizce kelimeyi oku

        // 2 saniye bekle
        Future.delayed(Duration(seconds: 2), () {
          // Türkçe kelimeyi oku
          if (defaultTargetPlatform == TargetPlatform.iOS) _speak(currentWord.meaning);

          // Kart çevrilmemişse çevir
          if (currentCardKey?.currentState?.isFront ?? false) {
            currentCardKey?.currentState?.toggleCard();
          }
        });

        // Sonraki kelimeye geç
        Future.delayed(Duration(seconds: (_autoPlaySpeed / 2).round()), () {
          setState(() {
            currentWordIndex.value++;
            _pageController.animateToPage(
              currentWordIndex.value,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        });
      } else {
        _stopAutoPlay();
      }
    });
  }
  Widget _buildAutoPlayControls(Map<String, Color> colors) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors["borderColor"]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  "Otomatik Oynatma Hızı",
                  style: TextStyle(
                      color: colors["text"],
                      fontWeight: FontWeight.bold
                  )
              ),
              Text(
                  "${_autoPlaySpeed.toStringAsFixed(1)} sn",
                  style: TextStyle(
                      color: colors["text"]
                  )
              ),
            ],
          ),
          SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors["text"],
              inactiveTrackColor: colors["text"]!.withOpacity(0.3),
              thumbColor: colors["text"],
              overlayColor: colors["text"]!.withOpacity(0.4),
              valueIndicatorColor: colors["text"],
              valueIndicatorTextStyle: TextStyle(color: colors["background"]),
            ),
            child: Slider(
              value: _autoPlaySpeed,
              min: 7.0,
              max: 15.0,
              divisions: 20,
              label: "${_autoPlaySpeed.toStringAsFixed(1)} sn",
              onChanged: (double value) {
                setState(() {
                  _autoPlaySpeed = value;
                  if (_isAutoPlaying) {
                    _startAutoPlay(); // Hızı değiştirirken otomatik oynatmayı yeniden başlat
                  }
                });
              },
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  "İlerleme",
                  style: TextStyle(
                      color: colors["text"],
                      fontWeight: FontWeight.bold
                  )
              ),
              Text(
                  "${currentWordIndex.value + 1} / ${_currentWordList.length}",
                  style: TextStyle(
                      color: colors["text"]
                  )
              ),
            ],
          ),
          SizedBox(height: 5),
          LinearProgressIndicator(
            value: (currentWordIndex.value + 1) / _currentWordList.length,
            backgroundColor: colors["borderColor"],
            valueColor: AlwaysStoppedAnimation<Color>(colors["text"]!),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            child: Text(_isAutoPlaying ? 'Duraklat' : 'Başlat'),
            style: ElevatedButton.styleFrom(
              foregroundColor: colors["background"], backgroundColor: colors["text"],
            ),
            onPressed: _toggleAutoPlay,
          ),
        ],
      ),
    );
  }
  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    if (mounted) {  // Eklenen kontrol
      setState(() {
        _isAutoPlaying = false;
      });
    }
  }
  int score = 0;
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }
  bool canSwipe() {
    final now = DateTime.now();
    if (lastSwipeTime == null) {
      lastSwipeTime = now;
      return true;
    }
    final difference = now.difference(lastSwipeTime!).inSeconds;
    if (difference >= 1) {
      lastSwipeTime = now;
      return true;
    }
    return false;
  }
  Map<int, GlobalKey<FlipCardState>> cardKeys = {};
  ValueNotifier<int> starredWordCount = ValueNotifier(0);
  ValueNotifier<Color> borderColorNotifier = ValueNotifier(Colors.white);
  ValueNotifier<int> animatedStarredCount = ValueNotifier(0);
  final service = StarredWordsService();

  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  String currentWord = "";
  ValueNotifier<bool> isVisibilityOn = ValueNotifier(true);
  bool isShuffleOn = true;
  bool isLanguageOn = true;
  bool _isVolumeOn = true; // Varsayılan değer
  late VolumeProvider volumeProvider;

  bool isVolumeOn = true;
  int userID= 2;
  late int point;
  late PageController _pageController;
  List<WordDetail> _currentWordList = [];
  Map<int, bool> starredStatus = {};
  bool _isAnimationCompleted = false;
  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    _showExitConfirmationDialog();
    return true;
  }

  void _showExitConfirmationDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkmak istediğinize emin misiniz?'),
        content: Text("Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hayır'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Evet'),
          ),
        ],
      ),
    ).then((value) => value ?? false ? Navigator.of(context).pop(true) : null);
  }
  ValueNotifier<Color> backgroundColorNotifier = ValueNotifier(Colors.blue);
  final FlutterTts flutterTts = FlutterTts();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ApiService().logSetEntry('Flash Kart', 'Flash Kartlara ', '');
    _loadVolumeState();

    _currentWordList = widget.words;

    WidgetsBinding.instance.addObserver(this);
    _loadDarkModePreference();
    _initializeStarredStatus();
    _loadStarredStatusAsync();
    _pageController = PageController(viewportFraction: 1.0);

    for (var word in widget.words) {
      cardKeys[word.id] = GlobalKey<FlipCardState>();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.words.isNotEmpty) {
        _speak(_currentWordList[currentWordIndex.value].word);
      }
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    currentWordIndex.value = 0;

    _borderColorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.green,
    ).animate(_animationController)
      ..addListener(() {
        borderColorNotifier.value = _borderColorAnimation.value ?? Colors.white;
      });
    totalWords = widget.words.length;
    Future.microtask(() {
      userProvider = Provider.of<UserProvider>(context, listen: false);
      pointValueNotife.value = userProvider.point;
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startAutoPlay();

      print("Uygulama ön plana döndü, mevcut kart indeksi: ${currentWordIndex.value}");
    }
    else if (state == AppLifecycleState.paused) {
      _stopAutoPlay();

      print("Uygulama ön plana döndü, mevcut kart indeksi: ${currentWordIndex.value}");
    }
  }
  @override
  void dispose() {
    flutterTts.stop();  // TTS'i durdur
    _autoPlayTimer?.cancel();  // Timer'ı iptal et
    _isAutoPlaying = false;  // Doğrudan değeri güncelle, setState kullanma

    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();

    super.dispose();
  }
  Future<void> _loadVolumeState() async {
    final prefs = await SharedPreferences.getInstance();
    bool savedVolumeState = prefs.getBool('isVolumeOn') ?? true;
    setState(() {
      _isVolumeOn = savedVolumeState;
    });

    // Volume provider'ı başlat ve durumu güncelle
    Future.microtask(() {
      volumeProvider = Provider.of<VolumeProvider>(context, listen: false);
      if (savedVolumeState != volumeProvider.isVolumeOn) {
        // Eğer kaydedilen durum ve provider durumu farklıysa, provider'ı kaydedilen duruma getir
        if (!savedVolumeState) { // Özellikle kapalı durumda ise
          volumeProvider.toggleVolume();
        }
      }
    });
  }
  Widget _buildVolumeControl(Color color) {
    return Consumer<VolumeProvider>(
      builder: (context, volumeProvider, child) {
        return IconButton(
          icon: Icon(
            volumeProvider.isVolumeOn ? Icons.volume_up : Icons.volume_off,
            color: color, // colors parametresini kullan
          ),
          onPressed: () async {
            volumeProvider.toggleVolume();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isVolumeOn', volumeProvider.isVolumeOn);
            setState(() {
              _isVolumeOn = volumeProvider.isVolumeOn;
            });

            // Kullanıcıya geri bildirim göster
            showCustomFlushbar(
                context,
                volumeProvider.isVolumeOn ? "Ses açıldı" : "Ses kapatıldı"
            );
          },
        );
      },
    );
  }
  void _initializeStarredStatus() {
    for (var word in widget.words) {
      starredNotifiers[word.id] = ValueNotifier(false);
    }
  }
  void _updateStarredWordCount(ValueNotifier<bool> isStarredNotifier) {
    int newCount = starredWordCountNotifier.value;
    if(isStarredNotifier.value){
      newCount = starredWordCountNotifier.value + 1;
    }
    else{
      if(newCount>0){
        newCount = starredWordCountNotifier.value-1;
      }
    }
    starredWordCountNotifier.value = newCount;
  }
  void _showExampleSentence() {
    if (_currentWordList.isNotEmpty) {
      final currentWord = _currentWordList[currentWordIndex.value];
      _showExampleSentenceDialog(currentWord);
    }
  }

  void _showExampleSentenceDialog(WordDetail word) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: ContentBox(
              content: ExampleSentenceContent(
                word: word,
                onListen: (sentence) => _speakSentence(sentence),
              ),
              icon: Icons.menu_book,
            )
        );
      },
    );
  }

  Future<void> _speakSentence(String sentence) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(sentence);
  }
  void _loadStarredStatusAsync() async {
    final service = StarredWordsService();
    final starredWordIds = await service.loadStarredWords(widget.classroomId, widget.studySetId);
    setState(() {
      int newStarredCount = 0;
      for (var word in widget.words) {
        bool isStarred = starredWordIds.contains(word.id);
        starredNotifiers[word.id]?.value = isStarred;
        starredStatus[word.id] = isStarred;
        if (isStarred) {
          newStarredCount++;
        }
      }
      starredWordCountNotifier.value = newStarredCount;
    });
  }

  bool isSpeaking = false;
  bool _showStarredOnly = false;

  Future<void> _speak(String text) async {
    // Önce widget'ın hala mount edilmiş olup olmadığını kontrol et
    if (!mounted) return;

    try {
      final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);
      if (volumeProvider.isVolumeOn) {
        // TTS işlemlerine geçmeden önce tekrar mounted kontrolü yap
        if (!mounted) return;

        await flutterTts.setLanguage(
            text == _currentWordList[currentWordIndex.value].word ? "en-US" : "tr-TR"
        );

        // Konuşmadan önce son bir mounted kontrolü
        if (!mounted) return;
        await flutterTts.speak(text);
      }
    } catch (e) {
      // TTS sırasında oluşabilecek hataları yakala
      print('_speak metodu hatası: $e');
    }
  }
  void _toggleStar(int wordId, ValueNotifier<bool> isStarredNotifier) async {
    final service = StarredWordsService();
    final newStatus = !isStarredNotifier.value;

    await service.toggleWordStarStatus(wordId, newStatus, widget.classroomId, widget.studySetId);

    setState(() {
      isStarredNotifier.value = newStatus;
      starredStatus[wordId] = newStatus;
      _recalculateStarredWordCount();

      if (_showStarredOnly) {
        _currentWordList = widget.words.where((word) => starredStatus[word.id] ?? false).toList();
        if (_currentWordList.isEmpty) {
          _showStarredOnly = false;
          _currentWordList = widget.words;
          showCustomFlushbar(context, "Yıldızlı kelime kalmadı. Tüm kelimeler gösteriliyor.");
        } else {
          currentWordIndex.value = currentWordIndex.value.clamp(0, _currentWordList.length - 1);
        }
        _pageController.jumpToPage(currentWordIndex.value);
      }
    });
  }

  void _recalculateStarredWordCount() {
    int count = starredStatus.values.where((isStarred) => isStarred).length;
    starredWordCountNotifier.value = count;
  }
  void _toggleStarredView() {
    setState(() {
      _showStarredOnly = !_showStarredOnly;
      _currentWordList = _showStarredOnly
          ? widget.words.where((word) => starredStatus[word.id] ?? false).toList()
          : widget.words;

      if (_currentWordList.isEmpty && _showStarredOnly) {
        _showStarredOnly = false;
        _currentWordList = widget.words;
        showCustomFlushbar(context, "Yıldızlı kelime bulunmamaktadır. Tüm kelimeler gösteriliyor.");
      } else {
        currentWordIndex.value = 0;
        totalWords = _currentWordList.length;
        _pageController.jumpToPage(0);

        showCustomFlushbar(
          context,
          _showStarredOnly ? "Yıldızlı kelimeler modu açıldı." : "Tüm kelimeler gösteriliyor.",
        );
      }

      if (totalWords > 0) {
        _speak(_currentWordList[currentWordIndex.value].word);
      }
    });
  }
  Widget _buildStarIcon(int wordid, ValueNotifier<bool> isStarredNotifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: isStarredNotifier,
      builder: (context, isStarred, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.7),
          ),

          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isStarred ? Icons.star : Icons.star_border,
                key: ValueKey<bool>(isStarred),
                color: isStarred ? Colors.amber : Colors.grey[600],
                size: 30,
              ),
            ),
            onPressed: () {
              _toggleStar(wordid, isStarredNotifier);
           //   _toggleStarredView(); // Yıldızlı kelimeler modunu aç/kapa
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    userProvider = Provider.of<UserProvider>(context, listen: false);
    List<Widget> cardDeck = widget.words.map((word) {
      return _buildCard(word.type, word.word, word.meaning, word.image, word.id, word, cardKeys[word.id]!);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop(true);
            return false;
          },
          child: Scaffold(
            backgroundColor: colors["background"],
            appBar: AppBar(
              backgroundColor: colors["background"],
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: colors["text"]),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: widget.isStarred ? null : _buildStarredWordsButton(),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.format_quote, color: colors["text"]),
                  onPressed: () => _showExampleSentence(),
                ),
                ScoreDisplay(userPointsNotifier: pointValueNotife),
                const SizedBox(width: 16),
                _buildRoundedIconButton(Icons.slow_motion_video_sharp, Colors.green, ()   {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.flashcard)),
                  );
                }),
              ],
            ),
            body: Column(
              children: <Widget>[
                _buildProgressBar(),
                SizedBox(height: screenHeight * 0.02),
                _buildControlPanel(colors, context),
                if (_isAutoPlaying) _buildAutoPlayControls(colors),
                Expanded(
                  child: _buildWordCards(screenWidth, screenHeight),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return ValueListenableBuilder<int>(
      valueListenable: currentWordIndex,
      builder: (context, index, child) {
        double progress = _currentWordList.isNotEmpty ? (index + 1) / _currentWordList.length : 0;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          constraints: BoxConstraints(minHeight: 20, minWidth: 100),
          child: AnimatedProgressBar(
            targetProgress: progress,
            currentIndex: index + 1,
            total: _currentWordList.length,
          ),
        );
      },
    );
  }
  Widget _buildControlPanel(Map<String, Color> colors, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors["borderColor"],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _buildControlButton(
              isVisibilityOn.value ? Icons.visibility : Icons.visibility_off,
              colors["inputBackground"]!,
                  () {
                setState(() {
                  isVisibilityOn.value = !isVisibilityOn.value;
                });
                showCustomFlushbar(
                  context,
                  isVisibilityOn.value ? "Resim açıldı" : "Resim kapandı",
                );
              }
          ),
          _buildControlButton(isShuffled ? Icons.sort : Icons.shuffle, colors["inputBackground"]!, () {
            setState(() {
              isShuffled = !isShuffled;
              if (isShuffled) {
                widget.words.shuffle();
              } else {
                widget.words.sort((a, b) => a.id.compareTo(b.id));
              }
              currentWordIndex.value = 0;
            });
            _speak(_currentWordList[currentWordIndex.value].word);
            showCustomFlushbar(
              context,
              isShuffled ? "Liste karıştırıldı." : "Liste Sıralandı.",
            );
          }),
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return _buildControlButton(
                languageProvider.isEnglish ? Icons.language : Icons.translate,
                colors["inputBackground"]!,
                    () {
                  languageProvider.toggleLanguage();
                  showCustomFlushbar(
                    context,
                    languageProvider.isEnglish
                        ? "Dil İngilizceye çevirildi"
                        : "Dil Türkçeye çevirildi",
                  );
                },
              );
            },
          ),
          _buildVolumeControl(colors["inputBackground"]!), // MyVolumeControl yerine bunu kullanın

          _buildControlButton(Icons.hearing, colors["inputBackground"]!, () {
            _speak(_currentWordList[currentWordIndex.value].word);
          }),
          _buildControlButton(
            _isAutoPlaying ? Icons.pause : Icons.play_arrow,
            colors["inputBackground"]!,
            _toggleAutoPlay,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: onPressed,
    );
  }
  Widget _buildStarredWordsButton() {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    return GestureDetector(
      onTap: _toggleStarredView,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _showStarredOnly ? Icons.star : Icons.star_border,
              color: _showStarredOnly ? Colors.amber : colors["text"],
              size: 20,
            ),
            const SizedBox(width: 4),
            ValueListenableBuilder<int>(
              valueListenable: starredWordCountNotifier,
              builder: (context, count, child) {
                return Text(
                  '$count',
                  style: GoogleFonts.lato(
                    color: colors["text"],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
  Widget buildStarredCountWidget(BuildContext context, bool isDarkMode) {
    final colors = isDarkMode ? darkModeColors : lightModeColors;
    double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _toggleStarredView,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _showStarredOnly ? Icons.star : Icons.star_border,
              color: _showStarredOnly ? Colors.amber : colors["text"],
              size: screenWidth * 0.05,
            ),
            SizedBox(width: 4),
            ValueListenableBuilder<int>(
              valueListenable: starredWordCountNotifier,
              builder: (context, count, child) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    '$count',
                    key: ValueKey<int>(count),
                    style: GoogleFonts.lato(
                      color: colors["text"],
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  void _showNoStarredWordsDialog(BuildContext context, double screenWidth) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Information"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "You don't have any starred words yet.",
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              const SizedBox(height: 8),
              Text(
                "Star words to enhance your learning with Kelibu!",
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }


  Widget _buildVisibilityButton(Map<String, Color> colors) {
    return ValueListenableBuilder<bool>(
      valueListenable: isVisibilityOn,
      builder: (context, value, child) {
        return IconButton(
          icon: Icon(
            value ? Icons.visibility : Icons.visibility_off,
            color: colors["text"],
          ),
          onPressed: () {
            isVisibilityOn.value = !value;
            showCustomFlushbar(
              context,
              value ? "Resim kapandı" : "Resim açıldı",
            );
          },
        );
      },
    );
  }

  Widget _buildShuffleButton(Map<String, Color> colors) {
    return IconButton(
      icon: Icon(
        isShuffled ? Icons.sort : Icons.shuffle,
        color: colors["text"],
      ),
      onPressed: () {
        setState(() {
          isShuffled = !isShuffled;
          if (isShuffled) {
            widget.words.shuffle();
          } else {
            widget.words.sort((a, b) => a.id.compareTo(b.id));
          }
          currentWordIndex.value = 0;
        });
        _speak(_currentWordList[currentWordIndex.value].word);
        showCustomFlushbar(
          context,
          isShuffled ? "Liste karıştırıldı." : "Liste Sıralandı.",
        );
      },
    );
  }

  Widget _buildLanguageButton(Map<String, Color> colors) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return IconButton(
          icon: Icon(
            languageProvider.isEnglish ? Icons.language : Icons.translate,
            color: colors["text"],
          ),
          onPressed: () {
            languageProvider.toggleLanguage();
            showCustomFlushbar(
              context,
              languageProvider.isEnglish
                  ? "Dil İngilizceye çevirildi"
                  : "Dil Türkçeye çevirildi",
            );
          },
        );
      },
    );
  }
  bool isLastWord() {
    return currentWordIndex.value == _currentWordList.length - 1;
  }
  void _showCompletionDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final backgroundColor = isDarkMode ? Colors.grey[850] : Colors.white;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Tebrikler!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Tüm kartları tamamladınız.',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      child: Text('Tekrar Başla'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _pageController.animateToPage(
                          0,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    OutlinedButton(
                      child: Text('Kapat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor, side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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
  Widget _buildWordCards(double screenWidth, double screenHeight) {
    return PageView.builder(
      itemCount: _currentWordList.length,
      controller: _pageController,
      onPageChanged: (index) async {
        if (index > currentWordIndex.value) {
          // Sağa kaydırıldı
          await onCardSwiped();
        }
        currentWordIndex.value = index;
        _speak(_currentWordList[currentWordIndex.value].word);
        if (isLastWord()) {
          _showCompletionDialog();
        }
      },
      itemBuilder: (context, index) {
        final word = _currentWordList[index];
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double value = 1.0;
            if (_pageController.position.haveDimensions) {
              value = (_pageController.page! - index).abs().clamp(0.0, 1.0);
            }
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(value * -0.5),
              alignment: Alignment.center,
              child: Opacity(
                opacity: 1.0 - value,
                child: child,
              ),
            );
          },
          child: _buildCard(word.type, word.word, word.meaning, word.image, word.id, word, cardKeys[word.id]!),
        );
      },
    );
  }

  Future<void> onCardSwiped() async {
    if (canSwipe()) {  // Hızlı kaydırmaları önlemek için
      int newPoint = userProvider.point;
      newPoint += 1;
      pointValueNotife.value += 1;

      await ApiService().updateUserPointTimePeriod(userProvider.userId, newPoint, 1);
      userProvider.addPoint(newPoint);

      // Kullanıcıya geri bildirim vermek için bir Flushbar gösterebilirsiniz
    }
  }
  Widget _buildCard(String? type, String englishWord, String turkishWord, String? imageUrl, int wordId, WordDetail word, GlobalKey<FlipCardState> cardKey) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    String fullImageUrl = imageUrl != null
        ? "https://cloud.phdakademi.com/uploads/kelibu.net/$imageUrl"
        : "https://kelibu.net/images/defaultimage.png";
    ValueNotifier<bool> isStarredNotifier = ValueNotifier<bool>(starredStatus[wordId] ?? false);

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: FlipCard(
            key: cardKey,
            front: _buildCardSide(
              colors,
              fullImageUrl,
              languageProvider.isEnglish ? englishWord : turkishWord,
              type,
              wordId,
              isStarredNotifier,
              true,
            ),
            back: _buildCardSide(
              colors,
              fullImageUrl,
              languageProvider.isEnglish ? turkishWord : englishWord,
              type,
              wordId,
              isStarredNotifier,
              false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardSide(Map<String, Color> colors, String imageUrl, String text, String? type, int wordId, ValueNotifier<bool> isStarredNotifier, bool isFront) {
    print(imageUrl);
    return Container(
      decoration: BoxDecoration(
        color: colors["background"],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ValueListenableBuilder<bool>(
              valueListenable: isVisibilityOn,
              builder: (context, isVisible, _) {
                return isVisible
                    ? Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                      return Center(
                        child: Image.asset(
                          'assets/logo.png', // Path to your local asset image
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      );
                    },
                  ),
                )
                    : Container(color: colors["borderColor"]);
              },
            ),
          ),
          Container(
            constraints: BoxConstraints(minHeight: 100, minWidth: 100), // Bu satırı ekleyin
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: [0.5, 1.0], // Bu satırı ekleyin
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isFront) ...[
                  SizedBox(height: 10),
                  Text(
                    type ?? 'Bilinmiyor',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!widget.isStarred) // isStarred false ise yıldız ikonunu göster
            Positioned(
              top: 20,
              right: 20,
              child: _buildStarIcon(wordId, isStarredNotifier),
            ),
        ],
      ),
    );
  }
  void showCustomFlushbar(BuildContext context, String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Flushbar(
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Container(
        margin: const EdgeInsets.only(left: 8, right: 8),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          radius: 20,
          child: ClipOval(
            child: Image.asset(
              'assets/logo.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: isDarkMode ? Colors.grey[800]! : Colors.white,
      boxShadows: [
        BoxShadow(
          color: Colors.black12,
          offset: Offset(0, 3),
          blurRadius: 6,
        ),
      ],
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      animationDuration: Duration(milliseconds: 400),
      forwardAnimationCurve: Curves.easeOutCirc,
      reverseAnimationCurve: Curves.easeInCirc,
      leftBarIndicatorColor: Colors.green,
    ).show(context);
  }
  Widget _buildRoundedIconButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: onPressed,
        child: Image.asset(
          'assets/videoplayer.png',
          width: 40.sp,
          height: 40.sp,
        ),
      ),
    );
  }

}
// Güncellenen ExampleSentenceContent sınıfı
class ExampleSentenceContent extends StatefulWidget {
  final WordDetail word;
  final Function(String) onListen;

  const ExampleSentenceContent({
    Key? key,
    required this.word,
    required this.onListen,
  }) : super(key: key);

  @override
  _ExampleSentenceContentState createState() => _ExampleSentenceContentState();
}



class _ExampleSentenceContentState extends State<ExampleSentenceContent> {
  String? _selectedLevel;
  String? _selectedType;
  int _maxSentencesToShow = 0;
  String _sentenceSelectionMode = 'traditional'; // 'traditional' veya 'ai' olabilir
  List<Map<String, dynamic>> _filteredSentences = [];
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    // Ekran boyutunu al
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width >= 360 && screenSize.width < 600;
    final isLargeScreen = screenSize.width >= 600;

    // Farklı ekran boyutlarına göre değerler tanımla
    final double headerFontSize = isSmallScreen ? 18 : (isMediumScreen ? 20 : 22);
    final double modeLabelFontSize = isSmallScreen ? 12 : (isMediumScreen ? 14 : 16);
    final double buttonFontSize = isSmallScreen ? 10 : (isMediumScreen ? 12 : 14);
    final double contentHeight = screenSize.height * 0.4; // Ekran yüksekliğinin %40'ı
    final double horizontalPadding = isSmallScreen ? 8 : (isMediumScreen ? 16 : 24);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog başlığı ve filtrele butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AutoSizeText(
                        'Örnek Cümleler',
                        style: GoogleFonts.poppins(
                          fontSize: headerFontSize,
                          fontWeight: FontWeight.bold,
                          color: colors["text"],
                        ),
                        minFontSize: 16,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.info_outline,
                              color: _isDarkMode ? Colors.teal.shade300 : Colors.teal.shade700,
                              size: isSmallScreen ? 20 : 24
                          ),
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                          onPressed: () => _showInfoDialog(context),
                        ),

                        // Filtre butonu - sadece ikon
                        GestureDetector(
                          onTap: () => _showFilterModal(context, widget.word.word),
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                            decoration: BoxDecoration(
                              color: _isDarkMode ? Colors.grey.shade800 : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isDarkMode ? Colors.teal.shade300.withOpacity(0.5) : Colors.teal.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.filter_list_rounded,
                              size: isSmallScreen ? 16 : 18,
                              color: _isDarkMode ? Colors.teal.shade300 : Colors.teal.shade700,
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 8),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: _isDarkMode ? Colors.teal.shade300 : Colors.teal.shade700,
                              size: isSmallScreen ? 20 : 24
                          ),
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
                Divider(color: colors["borderColor"]),

                // Mod seçimi (üst üste düzenlendi)
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          "Eşleşme Modu:",
                          style: GoogleFonts.poppins(
                            fontSize: modeLabelFontSize,
                            fontWeight: FontWeight.w500,
                            color: colors["text"],
                          ),
                          minFontSize: 10,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Row(
                          children: [
                            _buildSelectionButton(
                              label: "Tam Eşleşme",
                              isSelected: _sentenceSelectionMode == 'traditional',
                              onTap: () {
                                setState(() {
                                  _sentenceSelectionMode = 'traditional';
                                });
                              },
                              fontSize: buttonFontSize,
                            ),
                            SizedBox(width: isSmallScreen ? 4 : 8),
                            _buildSelectionButton(
                              label: "Geniş Eşleşme",
                              isSelected: _sentenceSelectionMode == 'ai',
                              onTap: () {
                                setState(() {
                                  _sentenceSelectionMode = 'ai';
                                });
                              },
                              fontSize: buttonFontSize,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 6 : 10),
                // Cümle içeriği
                Container(
                  height: contentHeight,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchSentencesBasedOnMode(widget.word.word, _sentenceSelectionMode),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: Colors.teal),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: AutoSizeText(
                              'Cümleler yüklenirken hata oluştu: ${snapshot.error}',
                              style: GoogleFonts.poppins(color: Colors.red),
                              textAlign: TextAlign.center,
                              minFontSize: 12,
                              maxLines: 3,
                            ),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  Icons.sentiment_dissatisfied,
                                  size: isSmallScreen ? 36 : (isMediumScreen ? 48 : 56),
                                  color: colors["unselectedText"]
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: AutoSizeText(
                                  'Bu kelime için örnek cümle bulunamadı.',
                                  style: GoogleFonts.poppins(color: colors["unselectedText"]),
                                  textAlign: TextAlign.center,
                                  minFontSize: 12,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Filtreleri uygula
                        _filteredSentences = snapshot.data!.where((sentence) {
                          bool levelMatch = _selectedLevel == null || sentence['level'] == _selectedLevel;
                          bool typeMatch = _selectedType == null || sentence['type'] == _selectedType;
                          return levelMatch && typeMatch;
                        }).toList();

                        // Maksimum gösterim sınırı
                        if (_maxSentencesToShow > 0 && _filteredSentences.length > _maxSentencesToShow) {
                          _filteredSentences = _filteredSentences.sublist(0, _maxSentencesToShow);
                        }

                        if (_filteredSentences.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    Icons.filter_list_off,
                                    size: isSmallScreen ? 36 : (isMediumScreen ? 48 : 56),
                                    color: colors["unselectedText"]
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: AutoSizeText(
                                    'Seçili filtrelere uygun cümle bulunamadı.',
                                    style: GoogleFonts.poppins(color: colors["unselectedText"]),
                                    textAlign: TextAlign.center,
                                    minFontSize: 12,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // AnimatedSentenceCarousel widget'ını kullan
                        return AnimatedSentenceCarousel(
                          sentences: _filteredSentences,
                          wordToHighlight: widget.word.word,
                          wordId: widget.word.id,
                          isDarkMode: _isDarkMode,
                          isSmallScreen: isSmallScreen,
                          isMediumScreen: isMediumScreen,
                        );
                      }
                    },
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 20),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 6 : 8
                      ),
                    ),
                    child: AutoSizeText(
                      'Kapat',
                      style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          color: Colors.teal
                      ),
                      minFontSize: 14,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required double fontSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade700 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal.shade700 : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: AutoSizeText(
          label,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
          minFontSize: 8,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
  // Bilgi diyaloğunu göster
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ContentBox(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Örnek Cümleler Hakkında',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 15),
                Text(
                  'Örnek cümleleri oluştururken karşılaşılabilecek durumlar:',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                bulletPoint('Kelimenin farklı anlamda kullanılması'),
                bulletPoint('Benzer kelimelerin karışması (tent/tenth)'),
                SizedBox(height: 15),
                Text(
                  'Bu durumlar, kelimelerin türemiş hallerini görebilmeniz için tercih edilmiştir.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                Text(
                  'Tam Eşleşme: Kelimenin doğrudan kendisini cümle içinde görmeyi sağlar.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                Text(
                  'Geniş Eşleşme: Kelimeyi ve türevlerini çok daha fazla cümlede görmeyi sağlar.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'Anlayışınız için teşekkür ederiz.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Çeviriler yapay zeka çevirisidir ve fikir vermek için hazırlanmıştır. Tam çeviri olmayabilir.',
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'PhD Akademi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Anladım',
                      style: TextStyle(fontSize: 18, color: Colors.teal),
                    ),
                  ),
                ),
              ],
            ),
            icon: Icons.info_outline,
          ),
        );
      },
    );
  }

  Widget bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('• ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
  // Filtre modalını göster
  void _showFilterModal(BuildContext context, String word) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width >= 360 && screenSize.width < 600;

    // Ekran boyutuna göre boyutları ayarla
    final double titleFontSize = isSmallScreen ? 20 : (isMediumScreen ? 24 : 28);
    final double sectionTitleFontSize = isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);
    final double optionFontSize = isSmallScreen ? 12 : (isMediumScreen ? 14 : 16);
    final double buttonFontSize = isSmallScreen ? 14 : (isMediumScreen ? 16 : 18);
    final double padding = isSmallScreen ? 16 : (isMediumScreen ? 20 : 24);

    String? tempSelectedLevel = _selectedLevel;
    String? tempSelectedType = _selectedType;
    int tempMaxSentences = _maxSentencesToShow;

    // Filtreleme için kullanılabilir seviyeleri ve türleri elde et
    Future<Map<String, Set<String>>> _getAvailableFilters(String word) async {
      final sentences = await _fetchSentencesBasedOnMode(word, _sentenceSelectionMode);
      Set<String> levels = {};
      Set<String> types = {};

      for (var sentence in sentences) {
        if (sentence['level'] != null && sentence['level'].toString().isNotEmpty) {
          levels.add(sentence['level']);
        }
        if (sentence['type'] != null && sentence['type'].toString().isNotEmpty) {
          types.add(sentence['type']);
        }
      }

      return {'levels': levels, 'types': types};
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, Set<String>>>(
          future: _getAvailableFilters(word),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.3,
                decoration: BoxDecoration(
                  color: colors["background"],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                ),
              );
            }

            final availableLevels = snapshot.data?['levels'] ?? {};
            final availableTypes = snapshot.data?['types'] ?? {};

            return StatefulBuilder(
                builder: (context, setModalState) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.7,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder: (_, controller) {
                      return Container(
                        decoration: BoxDecoration(
                          color: colors["background"],
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: ListView(
                          controller: controller,
                          padding: EdgeInsets.all(padding),
                          children: [
                            // İşaretçi çizgi
                            Center(
                              child: Container(
                                height: 5,
                                width: 40,
                                margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                                decoration: BoxDecoration(
                                  color: colors["unselectedText"]!.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                            ),

                            // Filtreleme başlığı
                            AutoSizeText(
                              'Cümle Filtreleri',
                              style: GoogleFonts.poppins(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: colors["text"],
                              ),
                              minFontSize: 18,
                              maxLines: 1,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            // Tümünü göster butonu
                            ElevatedButton.icon(
                              icon: Icon(Icons.visibility_outlined,
                                  color: Colors.white,
                                  size: isSmallScreen ? 18 : 22
                              ),
                              label: AutoSizeText(
                                "Tüm Cümleleri Göster",
                                style: GoogleFonts.poppins(
                                  fontSize: optionFontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                minFontSize: 12,
                                maxLines: 1,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade600,
                                padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 8 : 12
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  tempSelectedLevel = null;
                                  tempSelectedType = null;
                                  tempMaxSentences = 0;
                                });
                              },
                            ),
                            SizedBox(height: isSmallScreen ? 20 : 24),

                            // Seviye seçimi
                            AutoSizeText(
                              "Seviye",
                              style: GoogleFonts.poppins(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                              minFontSize: 14,
                              maxLines: 1,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Wrap(
                              spacing: isSmallScreen ? 6 : 10,
                              runSpacing: isSmallScreen ? 6 : 10,
                              children: [
                                _buildFilterOption(
                                  label: "Tümü",
                                  isSelected: tempSelectedLevel == null,
                                  color: Colors.orange.shade400,
                                  onTap: () {
                                    setModalState(() {
                                      tempSelectedLevel = null;
                                    });
                                  },
                                  fontSize: optionFontSize,
                                  smallScreen: isSmallScreen,
                                ),
                                ...availableLevels.map((level) => _buildFilterOption(
                                  label: level,
                                  isSelected: tempSelectedLevel == level,
                                  color: Colors.orange.shade400,
                                  onTap: () {
                                    setModalState(() {
                                      tempSelectedLevel = level;
                                    });
                                  },
                                  fontSize: optionFontSize,
                                  smallScreen: isSmallScreen,
                                )).toList(),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 20 : 24),

                            // Tür seçimi
                            AutoSizeText(
                              "Cümle Tipi",
                              style: GoogleFonts.poppins(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal.shade700,
                              ),
                              minFontSize: 14,
                              maxLines: 1,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Wrap(
                              spacing: isSmallScreen ? 6 : 10,
                              runSpacing: isSmallScreen ? 6 : 10,
                              children: [
                                _buildFilterOption(
                                  label: "Tümü",
                                  isSelected: tempSelectedType == null,
                                  color: Colors.teal.shade400,
                                  onTap: () {
                                    setModalState(() {
                                      tempSelectedType = null;
                                    });
                                  },
                                  fontSize: optionFontSize,
                                  smallScreen: isSmallScreen,
                                ),
                                ...availableTypes.map((type) => _buildFilterOption(
                                  label: type,
                                  isSelected: tempSelectedType == type,
                                  color: Colors.teal.shade400,
                                  onTap: () {
                                    setModalState(() {
                                      tempSelectedType = type;
                                    });
                                  },
                                  fontSize: optionFontSize,
                                  smallScreen: isSmallScreen,
                                )).toList(),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 20 : 24),

                            // Gösterilecek maksimum cümle sayısı
                            AutoSizeText(
                              "Gösterilecek Cümle Sayısı",
                              style: GoogleFonts.poppins(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                              minFontSize: 14,
                              maxLines: 1,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Wrap(
                              spacing: isSmallScreen ? 6 : 10,
                              runSpacing: isSmallScreen ? 6 : 10,
                              children: [
                                for (var count in [0, 5, 10, 20, 30, 50, 100])
                                  _buildNumberOption(
                                    count,
                                    count == 0 ? "Tümü" : count.toString(),
                                    tempMaxSentences,
                                        (value) {
                                      setModalState(() {
                                        tempMaxSentences = value;
                                      });
                                    },
                                    optionFontSize,
                                    isSmallScreen,
                                  ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 24 : 30),

                            // Uygula ve İptal butonları
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    child: AutoSizeText(
                                      "İptal",
                                      style: GoogleFonts.poppins(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      minFontSize: 12,
                                      maxLines: 1,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors["text"],
                                      padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 12 : 16
                                      ),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 8 : 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    child: AutoSizeText(
                                      "Filtreleri Uygula",
                                      style: GoogleFonts.poppins(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      minFontSize: 12,
                                      maxLines: 1,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade700,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 12 : 16
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedLevel = tempSelectedLevel;
                                        _selectedType = tempSelectedType;
                                        _maxSentencesToShow = tempMaxSentences;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
            );
          },
        );
      },
    );
  }

  // Filtre seçeneği widget'ı
  Widget _buildFilterOption({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required double fontSize,
    required bool smallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: smallScreen ? 12 : 16,
            vertical: smallScreen ? 8 : 10
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: AutoSizeText(
          label,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
          minFontSize: 10,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Sayı seçim butonu
  Widget _buildNumberOption(
      int value,
      String label,
      int currentValue,
      Function(int) onSelected,
      double fontSize,
      bool smallScreen,
      ) {
    bool isSelected = currentValue == value;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: smallScreen ? 12 : 16,
            vertical: smallScreen ? 8 : 10
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade500 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade500 : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: AutoSizeText(
          label,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
          minFontSize: 10,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Mod seçimine göre cümle getirme
  Future<List<Map<String, dynamic>>> _fetchSentencesBasedOnMode(String word, String mode) async {
    if (mode == 'traditional') {
      // Geleneksel mod: Tam eşleşme
      try {
        final data = await supabase
            .from('sentences')
            .select()
            .eq('word', word);

        return List<Map<String, dynamic>>.from(data);
      } catch (e) {
        print("Tam eşleşme cümle yüklenirken hata: $e");
        return [];
      }
    } else {
      // AI modu: FTS arama ve daha geniş eşleşme
      return await _searchWords(word);
    }
  }

  // Geniş eşleşme için kelime arama
  Future<List<Map<String, dynamic>>> _searchWords(String word) async {
    // Arama terimini hazırla
    final String searchTerm = word.trim();

    if (searchTerm.contains(' ')) {
      // Phrasal verbs ve çok kelimeli ifadeler için
      final String exactPhraseQuery = searchTerm.split(' ').join(' <-> ');

      try {
        final exactMatches = await supabase
            .from('sentences')
            .select()
            .textSearch('fts', exactPhraseQuery, config: 'english');

        if (exactMatches.length >= 3) {
          return List<Map<String, dynamic>>.from(exactMatches);
        }

        // Daha esnek bir sorgu
        final List<String> words = searchTerm.split(' ');
        String orQuery = words.join(' | ');

        final proximityMatches = await supabase
            .from('sentences')
            .select()
            .textSearch('fts', orQuery, config: 'english');

        // ILIKE ile arama
        List<Map<String, dynamic>> ilikeMatches = [];
        if (exactMatches.length + proximityMatches.length < 3) {
          ilikeMatches = await supabase
              .from('sentences')
              .select()
              .ilike('sentence', '%$searchTerm%');
        }

        // Sonuçları birleştir
        List<Map<String, dynamic>> allResults = List<Map<String, dynamic>>.from(exactMatches);
        allResults.addAll(proximityMatches);
        allResults.addAll(ilikeMatches);

        // Tekrarları kaldır
        final Set<String> uniqueIds = {};
        final List<Map<String, dynamic>> uniqueResults = [];

        for (var item in allResults) {
          String id = item['id'].toString();
          if (!uniqueIds.contains(id)) {
            uniqueIds.add(id);
            uniqueResults.add(item);
          }
        }

        return uniqueResults;
      } catch (e) {
        print("Geniş eşleşme cümle yüklenirken hata: $e");
        return [];
      }
    } else {
      // Tek kelime için
      try {
        final String queryTerm = searchTerm.length > 3 ? "$searchTerm:*" : searchTerm;

        final data = await supabase
            .from('sentences')
            .select()
            .textSearch('fts', queryTerm, config: 'english');

        if (data.length < 3) {
          final ilikeResults = await supabase
              .from('sentences')
              .select()
              .ilike('sentence', '% $searchTerm %');

          List<Map<String, dynamic>> allResults = List<Map<String, dynamic>>.from(data);
          allResults.addAll(ilikeResults);

          // Tekrarları kaldır
          final Set<String> uniqueIds = {};
          final List<Map<String, dynamic>> uniqueResults = [];

          for (var item in allResults) {
            String id = item['id'].toString();
            if (!uniqueIds.contains(id)) {
              uniqueIds.add(id);
              uniqueResults.add(item);
            }
          }

          return uniqueResults;
        }

        return List<Map<String, dynamic>>.from(data);
      } catch (e) {
        print("Geniş eşleşme cümle yüklenirken hata: $e");
        return [];
      }
    }
  }
}

// AnimatedSentenceCarousel sınıfı
class AnimatedSentenceCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> sentences;
  final String wordToHighlight;
  final int wordId;
  final bool isDarkMode;
  final bool isSmallScreen;
  final bool isMediumScreen;

  const AnimatedSentenceCarousel({
    Key? key,
    required this.sentences,
    required this.wordToHighlight,
    required this.wordId,
    required this.isDarkMode,
    required this.isSmallScreen,
    required this.isMediumScreen,
  }) : super(key: key);

  @override
  _AnimatedSentenceCarouselState createState() => _AnimatedSentenceCarouselState();
}

class _AnimatedSentenceCarouselState extends State<AnimatedSentenceCarousel> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  int _highlightedWordIndex = -1;
  Map<int, List<String>> _sentenceWordsMap = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _debounceTimer;
  bool _isAnimating = false;
  bool _isForward = true; // Yön kontrolü için değişken

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initAnimations();
    // Tüm cümleleri kelimelere böl
    for (int i = 0; i < widget.sentences.length; i++) {
      _sentenceWordsMap[i] = _splitSentenceToWords(widget.sentences[i]['sentence'] ?? '');
    }

    // İlk cümlenin hemen görünmesi için animasyonu başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400), // Biraz daha hızlı
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Daha yumuşak bir eğri
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Daha yumuşak bir eğri
    ));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      if (word.isNotEmpty) {
        final words = _sentenceWordsMap[_currentIndex] ?? [];
        String textUpToNow = text.substring(0, startOffset);
        int wordCount = textUpToNow.split(' ').where((s) => s.isNotEmpty).length;

        if (wordCount >= 0 && wordCount < words.length) {
          setState(() {
            _highlightedWordIndex = wordCount;
          });
        }
      }
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isPlaying = false;
        _highlightedWordIndex = -1;
      });
    });

    _flutterTts.setErrorHandler((error) {
      setState(() {
        _isPlaying = false;
        _highlightedWordIndex = -1;
      });
    });
  }

  List<String> _splitSentenceToWords(String sentence) {
    List<String> words = sentence.split(' ');
    List<String> result = [];

    for (var word in words) {
      if (word.isNotEmpty) {
        result.add(word);
      }
    }

    return result;
  }

  Future<void> _speakSentence(String sentence) async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() {
        _isPlaying = false;
        _highlightedWordIndex = -1;
      });
      return;
    }

    setState(() {
      _isPlaying = true;
      _highlightedWordIndex = -1;
    });

    await _flutterTts.speak(sentence);
  }

  void _goToNext() {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _isForward = true; // İleri yönde
    });

    // Önce mevcut içeriği dışarı kaydır (soldan sağa)
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInCubic,
    ));

    _animationController.forward(from: 0.0).then((_) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.sentences.length;
        _highlightedWordIndex = -1;
        if (_isPlaying) {
          _flutterTts.stop();
          _isPlaying = false;
        }

        // Yeni içeriği içeri kaydır (sağdan sola)
        _slideAnimation = Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ));

        _fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ));
      });

      _animationController.forward(from: 0.0);
    });
  }

  void _goToPrevious() {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _isForward = false; // Geri yönde
    });

    // Önce mevcut içeriği dışarı kaydır (sağdan sola)
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.3, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInCubic,
    ));

    _animationController.forward(from: 0.0).then((_) {
      setState(() {
        _currentIndex = (_currentIndex - 1 + widget.sentences.length) % widget.sentences.length;
        _highlightedWordIndex = -1;
        if (_isPlaying) {
          _flutterTts.stop();
          _isPlaying = false;
        }

        // Yeni içeriği içeri kaydır (soldan sağa)
        _slideAnimation = Tween<Offset>(
          begin: const Offset(-0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ));

        _fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ));
      });

      _animationController.forward(from: 0.0);
    });
  }

  void _goToIndex(int index) {
    if (index == _currentIndex || _isAnimating) return;

    setState(() {
      _isAnimating = true;
      _isForward = index > _currentIndex; // Yönü belirle
    });

    // Yöne göre animasyon ayarla
    if (_isForward) {
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.3, 0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInCubic,
      ));
    } else {
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0.3, 0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInCubic,
      ));
    }

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInCubic,
    ));

    _animationController.forward(from: 0.0).then((_) {
      setState(() {
        _currentIndex = index;
        _highlightedWordIndex = -1;
        if (_isPlaying) {
          _flutterTts.stop();
          _isPlaying = false;
        }

        // Yeni içeriği içeri kaydır
        if (_isForward) {
          _slideAnimation = Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ));
        } else {
          _slideAnimation = Tween<Offset>(
            begin: const Offset(-0.3, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ));
        }

        _fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ));
      });

      _animationController.forward(from: 0.0);
    });
  }

  // Throttle function to prevent rapid navigation
  void _throttleNavigation(Function() callback) {
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      callback();
    });
  }

  Widget _buildHighlightedText(List<String> words, String wordToHighlight, int currentWordIndex) {
    final wordToHighlightLower = wordToHighlight.toLowerCase();

    // Ekran boyutuna göre font boyutunu ayarla
    final fontSize = widget.isSmallScreen ? 14.0 : (widget.isMediumScreen ? 16.0 : 18.0);
    final lineHeight = widget.isSmallScreen ? 1.4 : 1.5;

    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          color: widget.isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87,
          height: lineHeight,
        ),
        children: List.generate(words.length, (index) {
          final word = words[index];
          final isWordHighlighted = word.toLowerCase().contains(wordToHighlightLower);
          final isCurrentlyBeingRead = index == currentWordIndex;

          // Reading highlight (current word)
          if (isCurrentlyBeingRead) {
            return TextSpan(
              text: word + (index < words.length - 1 ? ' ' : ''),
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Colors.teal,
                decorationThickness: widget.isSmallScreen ? 1.5 : 2,
                letterSpacing: widget.isSmallScreen ? 0.2 : 0.3,
              ),
            );
          }

          // Search term highlight
          if (isWordHighlighted) {
            return TextSpan(
              text: word + (index < words.length - 1 ? ' ' : ''),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            );
          }

          // Normal word
          return TextSpan(
            text: word + (index < words.length - 1 ? ' ' : ''),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sentences.isEmpty) {
      return Center(
        child: AutoSizeText(
          "Bu kelime için örnek cümle bulunamadı.",
          style: GoogleFonts.poppins(
            fontSize: widget.isSmallScreen ? 14 : 16,
            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          minFontSize: 12,
          maxLines: 2,
        ),
      );
    }

    final currentSentence = widget.sentences[_currentIndex];
    final sentence = currentSentence['sentence'] ?? '';
    final translation = currentSentence['translate'] ?? '';
    final level = currentSentence['level'] ?? '';

    // Ekran boyutuna göre padding değerleri
    final horizontalPadding = widget.isSmallScreen ? 12.0 : (widget.isMediumScreen ? 16.0 : 20.0);
    final verticalPadding = widget.isSmallScreen ? 6.0 : (widget.isMediumScreen ? 8.0 : 10.0);
    final cardPadding = widget.isSmallScreen ? 16.0 : 20.0;
    final iconSize = widget.isSmallScreen ? 18.0 : 24.0;
    final dotSize = widget.isSmallScreen ? 6.0 : 8.0;
    final activeDotWidth = widget.isSmallScreen ? 18.0 : 24.0;
    final labelFontSize = widget.isSmallScreen ? 12.0 : 14.0;
    final translationFontSize = widget.isSmallScreen ? 12.0 : 14.0;

    return Column(
      children: [
        // Navigation and counter
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AutoSizeText(
                "Cümle ${_currentIndex + 1}/${widget.sentences.length}",
                style: GoogleFonts.poppins(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
                minFontSize: 10,
                maxLines: 1,
              ),
              Row(
                children: [
                  if (level.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: widget.isSmallScreen ? 8 : 10,
                          vertical: widget.isSmallScreen ? 3 : 4
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AutoSizeText(
                        level,
                        style: GoogleFonts.poppins(
                          fontSize: widget.isSmallScreen ? 10 : 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        minFontSize: 8,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Main content card with AnimatedBuilder
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // İlk yüklemede animasyon uygulanmaması için kontrol
            if (_currentIndex == 0 && !_animationController.isAnimating && _animationController.status != AnimationStatus.completed) {
              return child!;
            }

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                // Swipe right -> go to previous
                _throttleNavigation(_goToPrevious);
              } else if (details.primaryVelocity! < 0) {
                // Swipe left -> go to next
                _throttleNavigation(_goToNext);
              }
            },
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.isSmallScreen ? 12 : 16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.isSmallScreen ? 12 : 16),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: widget.isDarkMode
                        ? [Colors.grey.shade800, Colors.grey.shade900]
                        : [Colors.white, Colors.teal.shade50],
                  ),
                ),
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main sentence with highlighted word
                    InkWell(
                      onTap: () => _speakSentence(sentence),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildHighlightedText(
                              _sentenceWordsMap[_currentIndex] ?? [],
                              widget.wordToHighlight,
                              _highlightedWordIndex,
                            ),
                          ),
                          // Audio button
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                              color: _isPlaying ? Colors.teal : widget.isDarkMode ? Colors.grey[400] : Colors.grey,
                              size: iconSize,
                            ),
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(widget.isSmallScreen ? 4 : 8),
                            onPressed: () => _speakSentence(sentence),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: widget.isSmallScreen ? 8 : 12),
                    // Turkish translation
                    if (translation.isNotEmpty)
                      AutoSizeText(
                        translation,
                        style: GoogleFonts.poppins(
                          fontSize: translationFontSize,
                          color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                        minFontSize: 10,
                        maxLines: widget.isSmallScreen ? 3 : 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: EdgeInsets.only(top: verticalPadding * 2, bottom: verticalPadding / 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              IconButton(
                onPressed: _currentIndex > 0 ? _goToPrevious : null,
                icon: Icon(Icons.arrow_back_ios, size: widget.isSmallScreen ? 16 : 20),
                constraints: BoxConstraints(),
                padding: EdgeInsets.all(widget.isSmallScreen ? 4 : 8),
                color: _currentIndex > 0
                    ? (widget.isDarkMode ? Colors.teal.shade300 : Colors.teal)
                    : Colors.grey.withOpacity(0.3),
              ),

              // Page indicator dots
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.sentences.length,
                          (index) => GestureDetector(
                        onTap: () => _goToIndex(index),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          margin: EdgeInsets.symmetric(horizontal: widget.isSmallScreen ? 3 : 4),
                          width: index == _currentIndex ? activeDotWidth : dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: index == _currentIndex
                                ? Colors.teal
                                : (widget.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Next button
              IconButton(
                onPressed: _currentIndex < widget.sentences.length - 1 ? _goToNext : null,
                icon: Icon(Icons.arrow_forward_ios, size: widget.isSmallScreen ? 16 : 20),
                constraints: BoxConstraints(),
                padding: EdgeInsets.all(widget.isSmallScreen ? 4 : 8),
                color: _currentIndex < widget.sentences.length - 1
                    ? (widget.isDarkMode ? Colors.teal.shade300 : Colors.teal)
                    : Colors.grey.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _animationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
class ContentBox extends StatelessWidget {
  final Widget content;
  final IconData icon;

  const ContentBox({
    Key? key,
    required this.content,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
            left: 20,
            top: 65 + 20,
            right: 20,
            bottom: 20,
          ),
          margin: EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: content,
        ),
        Positioned(
          left: 20,
          right: 20,
          child: CircleAvatar(
            backgroundColor: Colors.teal,
            radius: 45,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(45)),
              child: Icon(icon, color: Colors.white, size: 50),
            ),
          ),
        ),
      ],
    );
  }
}
class HighlightedText extends StatelessWidget {
  final String text;
  final String highlightedWord;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const HighlightedText({
    Key? key,
    required this.text,
    required this.highlightedWord,
    required this.baseStyle,
    required this.highlightStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: words.map((word) {
          if (word.toLowerCase().contains(highlightedWord.toLowerCase())) {
            return TextSpan(text: '$word ', style: highlightStyle);
          }
          return TextSpan(text: '$word ');
        }).toList(),
      ),
    );
  }
}