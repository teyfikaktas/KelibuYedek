import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../providers/user_provider.dart';
import '../../variables.dart';

// ScoreDisplay Widget - Kompakt ve responsive
class WordQuizScoreDisplay extends StatefulWidget {
  final ValueNotifier<int> userPointsNotifier;

  const WordQuizScoreDisplay({Key? key, required this.userPointsNotifier})
      : super(key: key);

  @override
  _WordQuizScoreDisplayState createState() => _WordQuizScoreDisplayState();
}

class _WordQuizScoreDisplayState extends State<WordQuizScoreDisplay>
    with TickerProviderStateMixin {
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Color(0xFF58CC02),
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
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Color(0xFFE5E5E5), width: 1),
            boxShadow: [
              BoxShadow(
                color: _colorAnimation.value ?? Colors.transparent,
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                size: 14.sp,
                color: Color(0xFFFFB800),
              ),
              SizedBox(width: 4.w),
              ValueListenableBuilder<int>(
                valueListenable: widget.userPointsNotifier,
                builder: (context, value, child) {
                  return Text(
                    "$value",
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C3C3C),
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

class WordQuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String questionType;

  const WordQuizScreen({
    Key? key,
    required this.questions,
    required this.questionType,
  }) : super(key: key);

  @override
  _WordQuizScreenState createState() => _WordQuizScreenState();
}

class _WordQuizScreenState extends State<WordQuizScreen>
    with TickerProviderStateMixin {
  bool _isDarkMode = false;
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;

  // Puanlama sistemi
  int score = 0;
  int userID = 0;
  ValueNotifier<int> pointValueNotifier = ValueNotifier(0);
  static const int POINTS_PER_CORRECT = 50;

  // TTS
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  int _highlightedWordIndex = -1;

  // Her soru için state tutacağız
  List<bool> answeredQuestions = [];
  List<String?> selectedAnswers = [];
  List<String?> correctAnswersList = [];
  List<List<Map<String, String>>> allOptions = [];

  // Tüm sorular cevaplanınca sonuçları göstermek için
  bool _allAnswered = false;

  // Review ekranı gösterilsin mi
  bool _showReviewScreen = false;

  // İlk soru ipucu gösterildi mi
  bool _firstQuestionHintShown = false;

  late PageController _pageController;
  late AnimationController _shakeController;
  late AnimationController _successController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _initializeTts();
    _pageController = PageController();

    // Tüm sorular için state başlat
    answeredQuestions = List.filled(widget.questions.length, false);
    selectedAnswers = List.filled(widget.questions.length, null);
    correctAnswersList = List.filled(widget.questions.length, null);
    allOptions = List.generate(widget.questions.length, (_) => []);

    // Tüm soruları hazırla
    for (int i = 0; i < widget.questions.length; i++) {
      _prepareQuestionAt(i);
    }

    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _successController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _successAnimation = Tween<double>(begin: 1, end: 1.1).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );

    // Kullanıcı puanını yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserScore();
    });

    ApiService().sendUserLog(
      type: 'screen_entry',
      log: 'Kullanıcı word quiz ekranına giriş yaptı.',
    );
  }

  // ---- TTS ----
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setProgressHandler(
            (String text, int startOffset, int endOffset, String word) {
          if (word.isNotEmpty) {
            String textUpToNow = text.substring(0, startOffset);
            int wordCount =
                textUpToNow.split(' ').where((s) => s.isNotEmpty).length;

            setState(() {
              _highlightedWordIndex = wordCount;
            });
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

  Future<void> _speakQuestion(String text) async {
    // HTML tag'lerini ve dash'leri temizle
    String cleanText = text.replaceAll(RegExp(r'<b>|</b>'), '');
    cleanText = cleanText.replaceAll(RegExp(r'-{3,}'), '...');

    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() {
        _isPlaying = false;
        _highlightedWordIndex = -1;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      await _flutterTts.speak(cleanText);
    }
  }

  // ---- TTS END ----

  void _loadUserScore() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      userID = userProvider.userId;
      score = userProvider.point;
      pointValueNotifier.value = score;
    });
  }

  Future<void> _updateUserScore(int pointsToAdd) async {
    try {
      UserProvider userProvider =
      Provider.of<UserProvider>(context, listen: false);
      int currentPoints = userProvider.point;
      int newScore = currentPoints + pointsToAdd;

      await Future.wait([
        ApiService().updateUserPointTimePeriod(userID, newScore, pointsToAdd),
        userProvider.addPoint(newScore),
      ]);

      setState(() {
        score = newScore;
        pointValueNotifier.value = newScore;
      });
    } catch (e) {
      debugPrint('Puan güncellenirken hata: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pageController.dispose();
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  void _prepareQuestionAt(int index) {
    final question = widget.questions[index];
    final optionsList = question['options'] as List?;

    if (optionsList == null || optionsList.isEmpty) {
      final correctTranslation = question['turkish_translation'] ?? 'Unknown';
      List<String> allTranslations = widget.questions
          .map((q) => q['turkish_translation'] as String?)
          .where((trans) => trans != null && trans.isNotEmpty)
          .cast<String>()
          .toList();
      allTranslations.remove(correctTranslation);
      allTranslations.shuffle();
      List<String> wrongOptions = allTranslations.take(3).toList();
      List<String> finalOptions = [...wrongOptions, correctTranslation];
      finalOptions.shuffle();

      allOptions[index] =
          finalOptions.map((opt) => {'terim': opt, 'tanim': opt}).toList();
      correctAnswersList[index] = correctTranslation;
    } else {
      List<Map<String, String>> options = optionsList.map((opt) {
        final word = opt['word'];
        return {
          'terim':
          word?['terim'] as String? ?? opt['option_text'] as String? ?? '',
          'tanim': word?['tanim'] as String? ?? '',
        };
      }).toList();

      final correctOpt = optionsList.firstWhere(
            (opt) => opt['is_correct'] == true || opt['is_correct'] == 1,
        orElse: () => optionsList[0],
      );

      final correctWord = correctOpt['word'];
      final correctTerim = correctWord?['terim'] as String? ??
          correctOpt['option_text'] as String? ??
          '';

      allOptions[index] = options;
      correctAnswersList[index] = correctTerim;
    }
  }

  void _checkAnswer(int questionIndex, String answer) {
    if (answeredQuestions[questionIndex]) return;

    final isCorrect = answer == correctAnswersList[questionIndex];

    setState(() {
      answeredQuestions[questionIndex] = true;
      selectedAnswers[questionIndex] = answer;

      if (isCorrect) {
        correctAnswers++;
        _successController.forward().then((_) => _successController.reverse());
        _updateUserScore(POINTS_PER_CORRECT);
      } else {
        wrongAnswers++;
        _shakeController.forward().then((_) => _shakeController.reverse());
      }

      // Tüm sorular cevaplandı mı kontrol et
      _allAnswered = answeredQuestions.every((a) => a);
    });

    // İlk soruda cevapladıktan sonra ipucu göster
    if (questionIndex == 0 && !_firstQuestionHintShown) {
      _firstQuestionHintShown = true;
      Future.delayed(Duration(milliseconds: 400), () {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Geçmiş sorulara dönüp şıklara tıklayarak kelimeleri sesli dinleyebilirsin',
                style: GoogleFonts.poppins(fontSize: 11.sp),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Color(0xFF1CB0F6),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              margin: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
            ),
          );
        }
      });
    }

    // Son soru cevaplanınca review ekranına geç
    if (_allAnswered) {
      Future.delayed(Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _showReviewScreen = true;
          });
        }
      });
    } else {
      // Cevaptan sonra otomatik geçiş - son soru değilse
      Future.delayed(Duration(milliseconds: 1200), () {
        if (mounted && questionIndex < widget.questions.length - 1) {
          _nextQuestion();
        }
      });
    }
  }

  void _nextQuestion() {
    // Sayfa geçişinde TTS'i durdur
    if (_isPlaying) {
      _flutterTts.stop();
      setState(() {
        _isPlaying = false;
        _highlightedWordIndex = -1;
      });
    }

    if (currentQuestionIndex < widget.questions.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    // Sayfa geçişinde TTS'i durdur
    if (_isPlaying) {
      _flutterTts.stop();
      setState(() {
        _isPlaying = false;
        _highlightedWordIndex = -1;
      });
    }

    if (currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToQuestion(int index) {
    if (_isPlaying) {
      _flutterTts.stop();
      setState(() {
        _isPlaying = false;
        _highlightedWordIndex = -1;
      });
    }

    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showResults() {
    // Sonuç ekranında TTS'i durdur
    if (_isPlaying) {
      _flutterTts.stop();
      setState(() {
        _isPlaying = false;
        _highlightedWordIndex = -1;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultDialog(),
    );
  }

  Widget _buildResultDialog() {
    final totalQuestions = widget.questions.length;
    final percentage = (correctAnswers / totalQuestions * 100).round();
    final earnedPoints = correctAnswers * POINTS_PER_CORRECT;

    // 5 kademe mesaj sistemi
    String title;
    String subtitle;
    IconData icon;
    Color accentColor;

    if (percentage == 100) {
      title = 'Mükemmel! 🏆';
      subtitle = 'Kusursuz bir performans!';
      icon = Icons.emoji_events;
      accentColor = Color(0xFFFFD700);
    } else if (percentage > 80) {
      title = 'Süper! 🌟';
      subtitle = 'Harika gidiyorsun, böyle devam!';
      icon = Icons.star;
      accentColor = Color(0xFF58CC02);
    } else if (percentage > 50) {
      title = 'Güzel! 👍';
      subtitle = 'İyi iş çıkardın, gelişmeye devam!';
      icon = Icons.thumb_up_alt_rounded;
      accentColor = Color(0xFF1CB0F6);
    } else if (percentage > 20) {
      title = 'Fena Değil 💪';
      subtitle = 'Biraz daha pratik yaparak gelişebilirsin!';
      icon = Icons.fitness_center_rounded;
      accentColor = Color(0xFFFF9600);
    } else {
      title = 'Pes Etme! 📚';
      subtitle = 'Bu sete daha iyi çalışmalısın, tekrar dene!';
      icon = Icons.menu_book_rounded;
      accentColor = Color(0xFFFF6B6B);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40.sp,
                color: accentColor,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C3C3C),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Color(0xFF999999),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '$correctAnswers / $totalQuestions',
              style: GoogleFonts.poppins(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Color(0xFF58CC02),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Doğru Cevap',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Color(0xFF777777),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Color(0xFFFFB74D), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 18.sp,
                    color: Color(0xFFFF9800),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF58CC02),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'DEVAM ET',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- REVIEW SCREEN ----
  Widget _buildReviewScreen() {
    final totalQuestions = widget.questions.length;
    final percentage = (correctAnswers / totalQuestions * 100).round();

    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _showReviewScreen = false;
                  });
                },
                borderRadius: BorderRadius.circular(6.r),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(Icons.arrow_back_rounded,
                      color: Color(0xFF777777), size: 20.sp),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Sonuçların',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C3C3C),
                  ),
                ),
              ),
              WordQuizScoreDisplay(userPointsNotifier: pointValueNotifier),
            ],
          ),
        ),

        // Skor özeti
        Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreStat(
                label: 'Doğru',
                value: '$correctAnswers',
                color: Color(0xFF58CC02),
                icon: Icons.check_circle_rounded,
              ),
              Container(
                width: 1,
                height: 36.h,
                color: Color(0xFFE5E5E5),
              ),
              _buildScoreStat(
                label: 'Yanlış',
                value: '$wrongAnswers',
                color: Color(0xFFFF4B4B),
                icon: Icons.cancel_rounded,
              ),
              Container(
                width: 1,
                height: 36.h,
                color: Color(0xFFE5E5E5),
              ),
              _buildScoreStat(
                label: 'Başarı',
                value: '%$percentage',
                color: Color(0xFF1CB0F6),
                icon: Icons.bar_chart_rounded,
              ),
            ],
          ),
        ),

        // Filtre tabları
        Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            children: [
              _buildFilterTab('Tümü', _reviewFilter == ReviewFilter.all, () {
                setState(() => _reviewFilter = ReviewFilter.all);
              }),
              SizedBox(width: 8.w),
              _buildFilterTab(
                  'Doğru ($correctAnswers)',
                  _reviewFilter == ReviewFilter.correct, () {
                setState(() => _reviewFilter = ReviewFilter.correct);
              }, color: Color(0xFF58CC02)),
              SizedBox(width: 8.w),
              _buildFilterTab(
                  'Yanlış ($wrongAnswers)',
                  _reviewFilter == ReviewFilter.wrong, () {
                setState(() => _reviewFilter = ReviewFilter.wrong);
              }, color: Color(0xFFFF4B4B)),
            ],
          ),
        ),

        SizedBox(height: 8.h),

        // Soru listesi
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: _getFilteredIndices().length,
            itemBuilder: (context, listIndex) {
              final questionIndex = _getFilteredIndices()[listIndex];
              return _buildReviewItem(questionIndex);
            },
          ),
        ),

        // Alt buton
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton(
                onPressed: _showResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF58CC02),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'TAMAMLA',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  ReviewFilter _reviewFilter = ReviewFilter.all;

  List<int> _getFilteredIndices() {
    List<int> indices = [];
    for (int i = 0; i < widget.questions.length; i++) {
      final isCorrect = selectedAnswers[i] == correctAnswersList[i];
      if (_reviewFilter == ReviewFilter.all) {
        indices.add(i);
      } else if (_reviewFilter == ReviewFilter.correct && isCorrect) {
        indices.add(i);
      } else if (_reviewFilter == ReviewFilter.wrong && !isCorrect) {
        indices.add(i);
      }
    }
    return indices;
  }

  Widget _buildScoreStat({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String label, bool isActive, VoidCallback onTap,
      {Color? color}) {
    final activeColor = color ?? Color(0xFF1CB0F6);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: isActive ? activeColor : Color(0xFF999999),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(int questionIndex) {
    final question = widget.questions[questionIndex];
    final selectedAnswer = selectedAnswers[questionIndex];
    final correctAnswer = correctAnswersList[questionIndex];
    final isCorrect = selectedAnswer == correctAnswer;

    final questionText = question['question_text'] ?? '';
    final fullSentence = question['full_sentence'] ??
        question['question_text'] ??
        '';
    final turkishTranslation = question['turkish_translation'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isCorrect
              ? Color(0xFF58CC02).withOpacity(0.4)
              : Color(0xFFFF4B4B).withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCorrect ? Color(0xFF58CC02) : Color(0xFFFF4B4B))
                .withOpacity(0.06),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: soru numarası + doğru/yanlış badge
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Soru ${questionIndex + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF777777),
                  ),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isCorrect ? Color(0xFFD7FFB8) : Color(0xFFFFDFDF),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 12.sp,
                      color: isCorrect ? Color(0xFF58CC02) : Color(0xFFFF4B4B),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      isCorrect ? 'Doğru' : 'Yanlış',
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: isCorrect ? Color(0xFF58A700) : Color(0xFFEA2B2B),
                      ),
                    ),
                  ],
                ),
              ),
              // TTS butonu
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: () => _speakQuestion(fullSentence),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 14.sp,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Cümle (bold parsed)
          Text.rich(
            TextSpan(
              children: _parseHtmlBold(
                fullSentence,
                GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3C3C3C),
                  height: 1.3,
                ),
              ),
            ),
          ),

          // Türkçe çeviri (bold parsed)
          if (turkishTranslation.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text.rich(
              TextSpan(
                children: _parseHtmlBold(
                  turkishTranslation,
                  GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF999999),
                    height: 1.2,
                  ),
                ).map((span) {
                  if (span.style?.fontWeight == FontWeight.w800) {
                    return TextSpan(
                      text: span.text,
                      style: span.style?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3C3C3C),
                      ),
                    );
                  }
                  return span;
                }).toList(),
              ),
            ),
          ],

          SizedBox(height: 8.h),

          // Doğru cevap
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Color(0xFFD7FFB8).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                  color: Color(0xFF58CC02).withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 14.sp, color: Color(0xFF58CC02)),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Doğru: $correctAnswer',
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF58A700),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Yanlış cevap göster (eğer yanlış cevapladıysa)
          if (!isCorrect) ...[
            SizedBox(height: 4.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Color(0xFFFFDFDF).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                    color: Color(0xFFFF4B4B).withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel_rounded,
                      size: 14.sp, color: Color(0xFFFF4B4B)),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Senin cevabın: $selectedAnswer',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEA2B2B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tüm şıkların Türkçe karşılıkları
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Color(0xFFE5E5E5), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Şıklar',
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
                SizedBox(height: 4.h),
                ...allOptions[questionIndex].map((opt) {
                  final terim = opt['terim'] ?? '';
                  final tanim = opt['tanim'] ?? '';
                  final isCorrectOpt = terim == correctAnswer;
                  final isSelectedOpt = terim == selectedAnswer;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCorrectOpt
                              ? Icons.check_circle_rounded
                              : isSelectedOpt
                              ? Icons.cancel_rounded
                              : Icons.circle_outlined,
                          size: 12.sp,
                          color: isCorrectOpt
                              ? Color(0xFF58CC02)
                              : isSelectedOpt
                              ? Color(0xFFFF4B4B)
                              : Color(0xFFCCCCCC),
                        ),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: terim,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.sp,
                                    fontWeight: isCorrectOpt
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isCorrectOpt
                                        ? Color(0xFF58A700)
                                        : isSelectedOpt
                                        ? Color(0xFFEA2B2B)
                                        : Color(0xFF555555),
                                  ),
                                ),
                                if (tanim.isNotEmpty && tanim != terim)
                                  TextSpan(
                                    text: '  —  $tanim',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ---- REVIEW SCREEN END ----

  Widget _buildHighlightedSentence(String questionText, String fullSentence) {
    final cleanQuestionText = questionText.replaceAll(RegExp(r'<b>|</b>'), '');
    final cleanFullSentence = fullSentence.replaceAll(RegExp(r'<b>|</b>'), '');

    final dashPattern = RegExp(r'-{3,}');

    if (!cleanQuestionText.contains(dashPattern)) {
      return Text.rich(
        TextSpan(
          children: _parseHtmlBold(
            fullSentence,
            GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3C3C3C),
              height: 1.3,
            ),
          ),
        ),
        textAlign: TextAlign.center,
      );
    }

    final match = dashPattern.firstMatch(cleanQuestionText);
    if (match == null) {
      return Text.rich(
        TextSpan(
          children: _parseHtmlBold(
            fullSentence,
            GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3C3C3C),
              height: 1.3,
            ),
          ),
        ),
        textAlign: TextAlign.center,
      );
    }

    final beforeDash = cleanQuestionText.substring(0, match.start);
    final afterDash = cleanQuestionText.substring(match.end);

    String boldWord = '';

    if (cleanFullSentence.startsWith(beforeDash)) {
      String remaining = cleanFullSentence.substring(beforeDash.length);

      if (afterDash.isNotEmpty && remaining.contains(afterDash)) {
        int afterIndex = remaining.indexOf(afterDash);
        boldWord = remaining.substring(0, afterIndex);
      } else {
        boldWord = remaining;
      }
    }

    if (boldWord.isEmpty) {
      return Text.rich(
        TextSpan(
          children: _parseHtmlBold(
            fullSentence,
            GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3C3C3C),
              height: 1.3,
            ),
          ),
        ),
        textAlign: TextAlign.center,
      );
    }

    final beforeSpans = _parseHtmlBold(
      beforeDash,
      GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: Color(0xFF3C3C3C),
        height: 1.3,
      ),
    );

    final afterSpans = _parseHtmlBold(
      afterDash,
      GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: Color(0xFF3C3C3C),
        height: 1.3,
      ),
    );

    return Text.rich(
      TextSpan(
        children: [
          ...beforeSpans,
          TextSpan(
            text: boldWord,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: Color(0xFF58CC02),
              height: 1.3,
            ),
          ),
          ...afterSpans,
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  List<TextSpan> _parseHtmlBold(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'<b>(.*?)</b>');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.w800),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }

  Widget _buildQuestionPage(int index) {
    final question = widget.questions[index];
    final options = allOptions[index];
    final isAnswered = answeredQuestions[index];
    final selectedAnswer = selectedAnswers[index];
    final correctAnswer = correctAnswersList[index];

    // TTS için okunacak metin
    final speakText = isAnswered
        ? (question['full_sentence'] ?? question['question_text'] ?? '')
        : (question['question_text'] ?? '');

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Column(
        children: [
          SizedBox(height: 4.h),

          // Question card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1CB0F6).withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Soru metni
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: isAnswered && selectedAnswer != correctAnswer
                          ? Offset(_shakeAnimation.value, 0)
                          : Offset.zero,
                      child: child,
                    );
                  },
                  child: isAnswered
                      ? _buildHighlightedSentence(
                    question['question_text'] ?? '',
                    question['full_sentence'] ??
                        question['question_text'] ??
                        '',
                  )
                      : Text(
                    question['question_text'] ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3C3C3C),
                      height: 1.3,
                    ),
                  ),
                ),

                SizedBox(height: 8.h),

                // TTS Dinle butonu
                GestureDetector(
                  onTap: () {
                    if (!isAnswered) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Soruyu cevapladıktan sonra geri dönerek cümleyi dinleyebilirsiniz',
                            style: GoogleFonts.poppins(fontSize: 11.sp),
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: Color(0xFFFF9800),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          margin: EdgeInsets.symmetric(
                              horizontal: 30.w, vertical: 10.h),
                        ),
                      );
                    } else {
                      _speakQuestion(speakText);
                    }
                  },
                  child: Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _isPlaying
                          ? Color(0xFF1CB0F6).withOpacity(0.1)
                          : Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPlaying
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_rounded,
                          size: 16.sp,
                          color: _isPlaying
                              ? Color(0xFF1CB0F6)
                              : Color(0xFF999999),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _isPlaying ? 'Dur' : 'Dinle',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: _isPlaying
                                ? Color(0xFF1CB0F6)
                                : Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // Options
          ...options.asMap().entries.map((entry) {
            final option = entry.value;
            final terim = option['terim']!;
            final tanim = option['tanim']!;
            final isSelected = selectedAnswer == terim;
            final isCorrect = correctAnswer == terim;

            Color backgroundColor = Colors.white;
            Color borderColor = Color(0xFFE5E5E5);
            Color textColor = Color(0xFF3C3C3C);
            List<BoxShadow>? shadows;

            if (isAnswered) {
              if (isCorrect) {
                backgroundColor = Color(0xFFD7FFB8);
                borderColor = Color(0xFF58CC02);
                textColor = Color(0xFF58A700);
                shadows = [
                  BoxShadow(
                    color: Color(0xFF58CC02).withOpacity(0.15),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ];
              } else if (isSelected) {
                backgroundColor = Color(0xFFFFDFDF);
                borderColor = Color(0xFFFF4B4B);
                textColor = Color(0xFFEA2B2B);
              }
            } else if (isSelected) {
              backgroundColor = Color(0xFFDDF4FF);
              borderColor = Color(0xFF1CB0F6);
              shadows = [
                BoxShadow(
                  color: Color(0xFF1CB0F6).withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ];
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: AnimatedBuilder(
                animation: _successAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isAnswered && isCorrect && isSelected
                        ? _successAnimation.value
                        : 1.0,
                    child: child,
                  );
                },
                child: InkWell(
                  onTap: isAnswered
                      ? () => _speakQuestion(terim)
                      : () => _checkAnswer(index, terim),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: 42.h),
                    padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: borderColor, width: 1.5),
                      boxShadow: shadows,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                terim,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  height: 1.2,
                                ),
                              ),
                              if (isAnswered && tanim.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  tanim,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                    color: textColor.withOpacity(0.7),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isAnswered) ...[
                          SizedBox(width: 6.w),
                          Icon(
                            isCorrect
                                ? Icons.check_circle
                                : (isSelected ? Icons.cancel : null),
                            color: isCorrect
                                ? Color(0xFF58CC02)
                                : Color(0xFFFF4B4B),
                            size: 18.sp,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          SizedBox(height: 10.h),

          // Turkish translation
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Color(0xFFE5E5E5), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.translate_rounded,
                    size: 11.sp, color: Color(0xFF999999)),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: _parseHtmlBold(
                        question['turkish_translation'] ?? '',
                        GoogleFonts.poppins(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF777777),
                          height: 1.2,
                        ),
                      ).map((span) {
                        if (span.style?.fontWeight == FontWeight.w800) {
                          return TextSpan(
                            text: span.text,
                            style: span.style?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3C3C3C),
                            ),
                          );
                        }
                        return span;
                      }).toList(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Swipe hint - sadece cevaplanmamışsa göster
          if (!isAnswered)
            Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe, size: 14.sp, color: Color(0xFFCCCCCC)),
                  SizedBox(width: 4.w),
                  Text(
                    'Kaydırarak geçiş yapabilirsiniz',
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // --- Bottom Navigation Bar ---
  Widget _buildBottomNavBar() {
    final isLastQuestion = currentQuestionIndex == widget.questions.length - 1;
    final isFirstQuestion = currentQuestionIndex == 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soru noktaları (dot indicator)
            _buildQuestionDots(),
            SizedBox(height: 8.h),
            // Navigasyon butonları
            Row(
              children: [
                // Geri butonu
                _buildNavButton(
                  icon: Icons.chevron_left_rounded,
                  label: 'Önceki',
                  onTap: isFirstQuestion ? null : _previousQuestion,
                  isEnabled: !isFirstQuestion,
                ),
                Spacer(),
                // Sonuçlar butonu - tüm sorular cevaplanınca göster
                if (_allAnswered)
                  _buildReviewButton()
                else if (isLastQuestion &&
                    answeredQuestions[currentQuestionIndex])
                  _buildReviewButton(),
                if (!_allAnswered &&
                    !(isLastQuestion &&
                        answeredQuestions[currentQuestionIndex]))
                  SizedBox.shrink(),
                Spacer(),
                // İleri butonu
                _buildNavButton(
                  icon: Icons.chevron_right_rounded,
                  label: 'Sonraki',
                  onTap: isLastQuestion ? null : _nextQuestion,
                  isEnabled: !isLastQuestion,
                  isForward: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isEnabled,
    bool isForward = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.3,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isEnabled ? Color(0xFFF0F0F0) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isForward)
                Icon(icon, size: 18.sp, color: Color(0xFF777777)),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF777777),
                ),
              ),
              if (isForward)
                Icon(icon, size: 18.sp, color: Color(0xFF777777)),
            ],
          ),
        ),
      ),
    );
  }

  // Review ekranına git butonu (eski _buildFinishButton yerine)
  Widget _buildReviewButton() {
    return GestureDetector(
      onTap: () {
        if (_isPlaying) {
          _flutterTts.stop();
          setState(() {
            _isPlaying = false;
            _highlightedWordIndex = -1;
          });
        }
        setState(() {
          _showReviewScreen = true;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Color(0xFF58CC02),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF58CC02).withOpacity(0.3),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rounded, size: 16.sp, color: Colors.white),
            SizedBox(width: 4.w),
            Text(
              'Sonuçlar',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionDots() {
    // Çok fazla soru varsa scroll yapılabilir hale getir
    return SizedBox(
      height: 18.h,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.questions.length, (index) {
              final isAnswered = answeredQuestions[index];
              final isCurrent = currentQuestionIndex == index;
              final isCorrectAnswer = isAnswered &&
                  selectedAnswers[index] == correctAnswersList[index];

              Color dotColor;
              if (isAnswered) {
                dotColor =
                isCorrectAnswer ? Color(0xFF58CC02) : Color(0xFFFF4B4B);
              } else {
                dotColor = Color(0xFFDDDDDD);
              }

              return GestureDetector(
                onTap: () => _goToQuestion(index),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  width: isCurrent ? 18.w : 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(4.r),
                    border: isCurrent
                        ? Border.all(
                      color: Color(0xFF1CB0F6),
                      width: 1.5,
                    )
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Color(0xFF3C3C3C)),
        ),
        body: Center(
          child: Text(
            'Soru bulunamadı',
            style:
            GoogleFonts.poppins(fontSize: 14.sp, color: Color(0xFF3C3C3C)),
          ),
        ),
      );
    }

    // Review ekranı gösterilecekse
    if (_showReviewScreen) {
      return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: SafeArea(
          child: _buildReviewScreen(),
        ),
      );
    }

    final progress = (currentQuestionIndex + 1) / widget.questions.length;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(6.r),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(Icons.close,
                          color: Color(0xFF777777), size: 20.sp),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                        AnimatedFractionallySizedBox(
                          duration: Duration(milliseconds: 300),
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: Color(0xFF58CC02),
                              borderRadius: BorderRadius.circular(6.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF58CC02).withOpacity(0.3),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    '${currentQuestionIndex + 1}/${widget.questions.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF777777),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  WordQuizScoreDisplay(userPointsNotifier: pointValueNotifier),
                ],
              ),
            ),

            // PageView for questions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.questions.length,
                onPageChanged: (index) {
                  // Sayfa değişince TTS'i durdur
                  if (_isPlaying) {
                    _flutterTts.stop();
                    setState(() {
                      _isPlaying = false;
                      _highlightedWordIndex = -1;
                    });
                  }
                  setState(() {
                    currentQuestionIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildQuestionPage(index);
                },
              ),
            ),

            // Bottom navigation bar
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }
}

// Review filtre enum'u
enum ReviewFilter { all, correct, wrong }