import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:kelibu/api.dart';
import 'package:flutter_tts/flutter_tts.dart';
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

class ScoreDisplay extends StatelessWidget {
  final ValueNotifier<int> userPointsNotifier;

  const ScoreDisplay({Key? key, required this.userPointsNotifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: userPointsNotifier,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.military_tech,
                  color: Colors.blue.shade400,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "$value",
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              _buildBaseBar(),
              _buildProgressBar(),
              _buildShineEffect(),
              _buildProgressText(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBaseBar() {
    return Container(
      width: widget.width,
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

  Widget _buildProgressBar() {
    return FractionallySizedBox(
      widthFactor: _progressAnimation.value,
      child: Container(
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

  Widget _buildShineEffect() {
    return FractionallySizedBox(
      widthFactor: _progressAnimation.value,
      child: FractionallySizedBox(
        widthFactor: 0.3,
        child: Transform.translate(
          offset: Offset(
            _shineAnimation.value * widget.width,
            0,
          ),
          child: Container(
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

  const FlashCardScreen({
    Key? key,
    required this.words,
    required this.classroomId,
    required this.studySetId,
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

  late UserProvider userProvider;
  ValueNotifier<int> pointValueNotife = ValueNotifier(0);
  ValueNotifier<bool> isAnimationCompletedNotifier = ValueNotifier(false);
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  ValueNotifier<int> starredWordCountNotifier = ValueNotifier(0);

  int score = 0;
  Future<void> onCardSwiped() async {
    int newPoint = userProvider.point;
    newPoint += 1;
    pointValueNotife.value +=1;
    await ApiService().updateUserPointTimePeriod(userProvider.userId, newPoint, 1);
    userProvider.addPoint(newPoint);
  }
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
        _speak();
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
      print("Uygulama ön plana döndü, mevcut kart indeksi: ${currentWordIndex.value}");
    }
    else if (state == AppLifecycleState.paused) {
      print("Uygulama ön plana döndü, mevcut kart indeksi: ${currentWordIndex.value}");
    }
  }
  @override
  void dispose() {
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

  void _toggleStarredView() {
    setState(() {
      _showStarredOnly = !_showStarredOnly;
      _currentWordList = _showStarredOnly
          ? widget.words.where((word) => starredStatus[word.id] ?? false).toList()
          : widget.words;
      currentWordIndex.value = 0;
      totalWords = _currentWordList.length;
      _pageController.jumpToPage(0);
    });

    showCustomFlushbar(
      context,
      _showStarredOnly ? "Yıldızlı kelimeler modu açıldı." : "Tüm kelimeler gösteriliyor.",
    );

    if (totalWords > 0) {
      _speak();
    }
  }
  _speak() async {
    final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);

    if (!isSpeaking && volumeProvider.isVolumeOn) {
      isSpeaking = true;
      if (currentWordIndex.value < _currentWordList.length) {
        String wordToSpeak = _currentWordList[currentWordIndex.value].word;
        if (wordToSpeak.isNotEmpty) {
          await flutterTts.setLanguage("en-US");
          await flutterTts.awaitSpeakCompletion(true);
          await flutterTts.speak(wordToSpeak);
        }
      }
      isSpeaking = false;
    }
  }
  void _toggleStar(int word, ValueNotifier<bool> isStarredNotifier) async {
    final service = StarredWordsService();
    final newStatus = !isStarredNotifier.value;

    await service.toggleWordStarStatus(word, !isStarredNotifier.value, widget.classroomId, widget.studySetId);

    isStarredNotifier.value = newStatus;
    starredStatus[wordId] = newStatus;
    _updateStarredWordCount(isStarredNotifier);
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
              actions: [
                _buildStarredWordsButton(),
                const SizedBox(width: 12),
                ScoreDisplay(userPointsNotifier: pointValueNotife),
                const SizedBox(width: 12),
              ],
            ),
            body: Column(
              children: <Widget>[
                _buildProgressBar(),
                SizedBox(height: screenHeight * 0.02),
                _buildControlPanel(colors, context),
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
        double progress = (index + 1) / totalWords;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedProgressBar(
            targetProgress: progress,
            currentIndex: index + 1,
            total: totalWords,
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
          _buildControlButton(Icons.visibility, colors["inputBackground"]!, () {
            isVisibilityOn.value = !isVisibilityOn.value;
            showCustomFlushbar(
              context,
              isVisibilityOn.value ? "Resim açıldı" : "Resim kapandı",
            );
          }),
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
            _speak();
            showCustomFlushbar(
              context,
              isShuffled ? "Liste karıştırıldı." : "Liste Sıralandı.",
            );
          }),
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return _buildControlButton(
                languageProvider.isEnglish ? Icons.language : Icons.translate,
                colors["text"]!,
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
          _buildControlButton(Icons.hearing, colors["inputBackground"]!, _speak),
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
        _speak();
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
      itemCount: widget.words.length,
      controller: _pageController,
      onPageChanged: (index) {
        currentWordIndex.value = index;
        _speak();
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
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                    return Image.asset(
                      'assets/logo.png', // Path to your local asset image
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  },
                )
                    : Container(color: colors["borderColor"]);
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
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
    Flushbar(
      messageText: Text(
        message,
        style: GoogleFonts.lato(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
      icon: Image.asset(
        'assets/logo.png',
        width: 56.0,
        height: 56.0,
      ),
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.white,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      boxShadows: const [
        BoxShadow(
          color: Colors.pink,
          offset: Offset(0, 3),
          blurRadius: 3,
        ),
      ],
      forwardAnimationCurve: Curves.easeInOutCubic,
      reverseAnimationCurve: Curves.easeInOutCubic,
    ).show(context);
  }
}
