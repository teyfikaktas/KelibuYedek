import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
              Image.asset(
                'assets/point.png',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 2),
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
  }
}
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
              primary: colors["text"],
              onPrimary: colors["background"],
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
    _autoPlayTimer?.cancel();  // Timer'ı iptal et
    _isAutoPlaying = false;  // Doğrudan değeri güncelle, setState kullanma

    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();

    super.dispose();
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
    final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);
    if (volumeProvider.isVolumeOn) {
      await flutterTts.setLanguage(text == _currentWordList[currentWordIndex.value].word ? "en-US" : "tr-TR");
      await flutterTts.speak(text);
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
                _buildRoundedIconButton(Icons.help, Colors.green, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.homescreen)),
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
          MyVolumeControl(),
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
                        primary: primaryColor,
                        onPrimary: Colors.white,
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
                        primary: primaryColor,
                        side: BorderSide(color: primaryColor),
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
  Widget _buildRoundedIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        primary: color,
        shape: CircleBorder(),
      ),
      child: Icon(icon, color: Colors.white, size: 16.sp),
    );
  }

}
class ExampleSentenceContent extends StatelessWidget {
  final WordDetail word;
  final Function(String) onListen;

  const ExampleSentenceContent({
    Key? key,
    required this.word,
    required this.onListen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Örnek Cümleler',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () => _showInfoDialog(context),
            ),
          ],
        ),
        SizedBox(height: 20),
        Container(
          height: 300,
          child: FutureBuilder<List<String>>(
            future: _fetchSentenceForTerm(word.word),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.teal));
              } else if (snapshot.hasError) {
                return Text('Hata oluştu: ${snapshot.error}', style: TextStyle(color: Colors.red));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('Örnek cümle bulunamadı.', style: TextStyle(color: Colors.grey));
              } else {
                return PageView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return ExampleSentenceCard(
                      sentence: snapshot.data![index],
                      highlightWord: word.word,
                      onListen: () => onListen(snapshot.data![index]),
                    );
                  },
                );
              }
            },
          ),
        ),
        SizedBox(height: 20),
        Align(
          alignment: Alignment.bottomRight,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Kapat',
              style: TextStyle(fontSize: 18, color: Colors.teal),
            ),
          ),
        ),
      ],
    );
  }
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
                SizedBox(height: 20),
                Text(
                  'Anlayışınız için teşekkür ederiz.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 10),
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

  Future<List<String>> _fetchSentenceForTerm(String term) async {
    try {
      var response = await ApiService().fetchExampleSentences(term);
      if (response.isNotEmpty) {
        return response.map<String>((item) => item['cumle'].toString()).toList();
      } else {
        return ["Cümle bulunamadı"];
      }
    } catch (e) {
      print('Hata: $e');
      return ["Cümle yüklenemedi"];
    }
  }
}

class ExampleSentenceCard extends StatelessWidget {
  final String sentence;
  final String highlightWord;
  final VoidCallback onListen;

  const ExampleSentenceCard({
    Key? key,
    required this.sentence,
    required this.highlightWord,
    required this.onListen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: HighlightedText(
                  text: sentence,
                  highlightedWord: highlightWord,
                  baseStyle: GoogleFonts.nunito(
                    fontSize: 20,
                    color: Color(0xFF4B4B4B),
                  ),
                  highlightStyle: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1CB0F6),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.volume_up, color: Colors.white),
              label: Text('Dinle', style: GoogleFonts.nunito(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              onPressed: onListen,
              style: ElevatedButton.styleFrom(
                primary: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
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