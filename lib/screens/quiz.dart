import 'package:flutter/material.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'dart:math';
import 'dart:async';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/providers/language_provider.dart';
import 'package:kelibu/screens/home_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../providers/volume_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import '../variables.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../shared_preferences/shared_preferences.dart';

class QuizCard extends StatefulWidget {
  final String question;
  final Duration duration;
  final int currentQuestionIndex; // Add this line

  const QuizCard({
    Key? key,
    required this.question,
    this.duration = const Duration(seconds: 1),
    required this.currentQuestionIndex, // Add this line
  }) : super(key: key);
  @override
  _QuizCardState createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  double _opacity = 0.0;
  final AudioPlayer audioPlayer = AudioPlayer();
  Future<void> playSound(String path) async {
    await audioPlayer.play(AssetSource(path));
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: widget.duration,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.question,
            style: TextStyle(
              fontSize: 2, // Dinamik font boyutu
            ),
          ),
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final int classroomId;
  final int studySetId;
  final List<WordDetail> words;

  const QuizScreen({
    Key? key,
    required this.words,
    required this.classroomId, // Yeni parametre
    required this.studySetId, // Yeni parametre
  }) : super(key: key);
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  PageController _pageController = PageController();
  final ScrollController _navBarScrollController = ScrollController();
  ValueNotifier<bool> isRefreshOn = ValueNotifier(true);
  ValueNotifier<bool> isMuteOn = ValueNotifier(true);
  ValueNotifier<bool> isSortOn = ValueNotifier(true);
  ValueNotifier<bool> refresh_off = ValueNotifier(true);
  ValueNotifier<bool> isTurkish = ValueNotifier(true);
  ValueNotifier<int> starredWordCountNotifier = ValueNotifier(0);
  bool _isDarkMode = false; // Dark mode durumu


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

  Map<int, bool?> questionStatuses = {};

  int _pausedTime = 0;
  int score = 0;
  ValueNotifier<Color> backgroundColorNotifier = ValueNotifier(Colors.blue);

  Future<void> playSoundCorrect(String path) async {
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.setVolume(0.2);

    if (!kIsWeb) {
      ByteData data = await rootBundle.load(path);
      Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      String dir = (await getTemporaryDirectory()).path;
      File tempFile = File('$dir/tempSound.wav');
      await tempFile.writeAsBytes(bytes, flush: true);
      await audioPlayer.play(DeviceFileSource(tempFile.path));
    } else {
      ByteData data = await rootBundle.load(path);
      Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await audioPlayer.play(BytesSource(bytes));
    }
  }
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }
  bool showStarredOnly = false;

  void resetQuiz() {
    setState(() {
      for (var question in questions) {
        question.userAnswer = null;
        questionStatuses[question.id] = null;
      }
      currentQuestionIndex = 0;
      _timer?.cancel();
      startTimer();
    });
  }

  void toggleStarredOnly() {
    setState(() {
      resetOptionColors();
      showStarredOnly = !showStarredOnly;
      backgroundColorNotifier.value = showStarredOnly ? Colors.green : Colors.blue;
      showCustomFlushbar(context, showStarredOnly ? "Yıldızlı kelimeler modu açıldı." : "Yıldızlı kelimeler modu kapandı");
      if (showStarredOnly) {
        var filteredQuestions = questions.where((q) => starredStatus[q.id] ?? false).toList();
        if (filteredQuestions.isNotEmpty) {
          questions = filteredQuestions;
          resetQuiz();
        }
      } else {
        _initializeQuiz();
        resetQuiz();
      }
      _pageController.jumpToPage(currentQuestionIndex);
    });
  }

  final AudioPlayer audioPlayer = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;

  Future<void> playSound(String path) async {
    await audioPlayer.play(AssetSource(path));
  }

  late List<QuizQuestion> questions = [];

  Map<int, bool> starredWords = {};
  ValueNotifier<int> starredWordCount = ValueNotifier(0);
  bool isStarred = false;
  bool _isBottomSheetOpen = false;
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  Map<int, bool> starredStatus = {};
  int userID = 2;

  ValueNotifier<int> animatedStarredCount = ValueNotifier(0);
  Map<int, Color> optionColors = {};
  QuizQuestion get currentQuestion => questions[currentQuestionIndex];
  ValueNotifier<bool> isVisibilityOn = ValueNotifier(true);
  Timer? _timer;
  int _remainingTime = 15;

  ValueNotifier<bool> get isStarredNotifier {
    int questionId = questions[currentQuestionIndex].id;
    return starredNotifiers[questionId] ?? ValueNotifier(false);
  }

  _speak() async {
    final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);

    if (!isSpeaking && volumeProvider.isVolumeOn && isTurkish.value) {
      isSpeaking = true;
      String wordToSpeak = questions[currentQuestionIndex].term;
      print(wordToSpeak);
      await flutterTts.setLanguage("en-US");
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.speak(wordToSpeak);
      isSpeaking = false;
    }
  }

  void _scrollToSelectedQuestion() {
    double selectedQuestionOffset = currentQuestionIndex * 50.0;
    _navBarScrollController.animateTo(
      selectedQuestionOffset,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void startTimer({bool resumeFromPausedTime = false}) {
    _timer?.cancel();
    if (resumeFromPausedTime) {
      _remainingTime = _pausedTime;
    } else {
      _remainingTime = 15;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_remainingTime == 0) {
        _timer?.cancel();
        _showCorrectAnswerAndGoToNextQuestion();
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  void _shuffleOrSortWords() async {
    List<WordDetail> newWords;
    showCustomFlushbar(context, isSortOn.value ? "Liste Sıralandı." : "Liste Karıştırıldı.");
    if (isSortOn.value) {
      newWords = List<WordDetail>.from(widget.words)..sort((a, b) => a.id.compareTo(b.id));
    } else {
      newWords = List<WordDetail>.from(widget.words)..shuffle();
    }

    List<QuizQuestion> newQuestions = await generateQuizQuestions(newWords, isTurkish);

    setState(() {
      questions = newQuestions;
      currentQuestionIndex = 0;
      _pageController.jumpToPage(currentQuestionIndex);
    });
  }

  void _changeLang() async {
    List<WordDetail> newWords;
    showCustomFlushbar(context, isTurkish.value ? "Türkçe Mod açıldı." : "İngilizce Mod açıldı.");
    if (isSortOn.value) {
      newWords = List<WordDetail>.from(widget.words)..sort((a, b) => a.id.compareTo(b.id));
    } else {
      newWords = List<WordDetail>.from(widget.words)..shuffle();
    }
    List<QuizQuestion> newQuestions = await generateQuizQuestions(newWords, isTurkish);

    setState(() {
      questions = newQuestions;
      currentQuestionIndex = 0;
      _pageController.jumpToPage(currentQuestionIndex);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadStarredStatusAsync();
    _loadDarkModePreference(); // Dark mode tercihlerini yükle

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      setState(() {
        userID = userProvider.userId;
      });
      _pageController = PageController(initialPage: -1);

      _pageController.addListener(() {
        if (_pageController.page == currentQuestionIndex) {
          _scrollToSelectedQuestion();
        }
      });
      UserProvider userProviderPoint = Provider.of<UserProvider>(context, listen: false);
      print(userProviderPoint.point);
      score = (userProviderPoint.point);
      _pageController.addListener(() {
        if (_pageController.page?.round() == _pageController.page) {
          _speak();
        }
      });
      _initializeQuiz();
      resetOptionColors();
      startTimer();

      _loadStarredStatusAsync();
    });
  }

  void finishQuiz() async {
    int finalScore = score;
    try {
      await ApiService().updateUserPointTimePeriod(userID, finalScore, 5);
      print('Puan güncellendi: $finalScore');
    } catch (e) {
      print('Puan güncelleme hatası: $e');
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => QuizResultsScreen(questions: questions),
    ));
    _timer?.cancel();
  }

  void _initializeQuiz() async {
    var sortedWords = List<WordDetail>.from(widget.words)..sort((a, b) => a.id.compareTo(b.id));
    var generatedQuestions = await generateQuizQuestions(sortedWords, isTurkish);

    setState(() {
      questions = generatedQuestions;
    });
  }

  void _updateStarredWordCount(ValueNotifier<bool> isStarredNotifier) {
    int newCount = starredWordCountNotifier.value;
    if (isStarredNotifier.value) {
      newCount = starredWordCountNotifier.value + 1;
    } else {
      if (newCount > 0) {
        newCount = starredWordCountNotifier.value - 1;
      }
    }
    starredWordCountNotifier.value = newCount;
  }

  Future<void> _speakSentence(String sentence) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(sentence);
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

  void _openBottomSheet() async {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    var currentTerm = questions[currentQuestionIndex].term;
    var sentences = await _fetchSentenceForTerm(currentTerm);
    int currentPage = 0;
    var pageController = PageController();
    _pausedTime = _remainingTime;
    _timer?.cancel();

    // Bottom sheet açılmadan önce tüm uygulama üzerindeki tıklamaları devre dışı bırak
    setState(() {
      _isBottomSheetOpen = true;
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return FractionallySizedBox(
                heightFactor: 0.2,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: colors["background"],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${currentPage + 1} / ${sentences.length}",
                          style:  TextStyle(color: colors["borderColor"], fontSize: 16),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: pageController,
                            itemCount: sentences.length,
                            onPageChanged: (int index) {
                              setState(() {
                                currentPage = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _speakSentence(sentences[index]),
                                child: Center(
                                  child: Text(
                                    sentences[index],
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colors["borderColor"],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      // Bottom sheet kapatıldığında tıklamaları tekrar etkinleştir
      setState(() {
        _isBottomSheetOpen = false;
      });
    });

    if (_isBottomSheetOpen) {
      startTimer(resumeFromPausedTime: true);
    }
  }

  void _showCorrectAnswerAndGoToNextQuestion() {
    var correctIndex = questions[currentQuestionIndex].correctOptionIndex;
    setState(() {
      optionColors[correctIndex] = const Color(0xFF4CA64C);
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          resetOptionColors();
          startTimer();
        });
        _pageController.animateToPage(
          currentQuestionIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        finishQuiz();
      }
    });
  }

  void _toggleStar(int word, ValueNotifier<bool> isStarredNotifier) async {
    final service = StarredWordsService();
    final newStatus = !isStarredNotifier.value;

    await service.toggleWordStarStatus(word, newStatus, widget.classroomId, widget.studySetId);

    isStarredNotifier.value = newStatus;
    starredStatus[word] = newStatus;
    _updateStarredWordCount(isStarredNotifier);
  }

  @override
  void dispose() {
    _timer?.cancel();

    _navBarScrollController.dispose();
    super.dispose();
  }

  void resetOptionColors() {
    optionColors = {for (var item in List.generate(4, (index) => index)) item: Colors.white};
  }

  void _answerQuestion(int selectedIndex) {
    var correctIndex = questions[currentQuestionIndex].correctOptionIndex;
    questions[currentQuestionIndex].userAnswer = selectedIndex;
    bool isCorrect = selectedIndex == correctIndex;
    int penalty = 15 - _remainingTime;
    if (isCorrect) {
      print("correct");
      score += 5;
    } else {
      if (penalty <= 10) score -= 5;
      else score -= 2;
    }
    questionStatuses[currentQuestionIndex] = isCorrect;
    _updateUserScore(score);

    setState(() {
      optionColors[selectedIndex] = selectedIndex == correctIndex ? const Color(0xFF4CA64C) : const Color(0xFFFF4C4C);
      if (selectedIndex != correctIndex) {
        optionColors[correctIndex] = const Color(0xFF4CA64C);
      }
    });

    if (selectedIndex == correctIndex) {
      playSoundCorrect('assets/correct.wav');
    } else {
      playSoundCorrect('assets/wrong.wav');
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          resetOptionColors();
          startTimer();
        });
        _pageController.animateToPage(
          currentQuestionIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        finishQuiz();
      }
    });
  }

  Future<void> _updateUserScore(int score) async {
    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      int point = userProvider.point.toInt();
      userProvider.addPoint(point + 5);
      await ApiService().updateUserPointTimePeriod(userID, score, 5);
    } catch (e) {
      print("Puan güncelleme hatası: $e");
    }
  }

  void _loadStarredStatusAsync() async {
    final service = StarredWordsService();
    final starredWordIds = await service.loadStarredWords(widget.classroomId, widget.studySetId);
    print('Yüklenen yıldızlı kelimeler: $starredWordIds');
    int newStarredCount = 0;

    setState(() {
      for (var word in widget.words) {
        bool isStarred = starredWordIds.contains(word.id);
        starredNotifiers[word.id] = ValueNotifier<bool>(isStarred);
        starredStatus[word.id] = isStarred;
        if (isStarred) {
          newStarredCount++;
        }
      }
      _updateStarredWordCount(isStarredNotifier);
    });
    starredWordCountNotifier.value = newStarredCount;
  }

  Widget _buildOption(String option, int index, int correctIndex, int? userAnswer) {
    Color bgColor;
    Color textColor = Colors.black;

    if (userAnswer == null) {
      bgColor = Colors.white;
    } else if (index == correctIndex) {
      bgColor = Colors.green;
      textColor = Colors.white;
    } else if (index == userAnswer) {
      bgColor = Colors.red;
      textColor = Colors.white;
    } else {
      bgColor = Colors.white;
    }

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: height * 0.02),
      child: GestureDetector(
        onTap: () {
          if (questions[currentQuestionIndex].userAnswer == null) {
            _answerQuestion(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: width * 0.8,
          height: height * 0.05,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset('assets/logo.png', width: 45, height: 45),
              Expanded(
                child: Text(
                  option,
                  style: GoogleFonts.poppins(
                    fontSize: width * 0.03,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionContent(QuizQuestion question) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: colors["background"],
                    borderRadius: BorderRadius.circular(30.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      child: Text(
                        question.term,
                        style: TextStyle(
                          fontSize: 26, // Biraz daha büyük
                          fontWeight: FontWeight.bold,
                          color: colors["text"], // Açık pembe renk
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildImage(question.image?.isEmpty ?? true ? null : question.image!),
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: question.options.length,
            itemBuilder: (context, index) {
              return _buildOption(question.options[index], index, question.correctOptionIndex, question.userAnswer);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null) {
      return Image.asset('assets/logo.png', fit: BoxFit.cover);
    }

    return AnimatedCrossFade(

      duration: const Duration(milliseconds: 500),
      firstChild: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          'https://cloud.phdakademi.com/uploads/kelibu.net/$imageUrl',
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) => Opacity(
            opacity: 0.1,
            child: Image.asset('assets/logo.png'),
          ),
        ),
      ),
      secondChild: Image.asset(
        'assets/logo.png',
        fit: BoxFit.cover,
      ),
      crossFadeState: isVisibilityOn.value ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }



  Widget _buildTimer() {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: _remainingTime / 15,
            strokeWidth: 8.0,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
            backgroundColor: colors["text"],
          ),
        ),
        Text(
          '$_remainingTime',
          style:  TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
            color:  colors["text"],
          ),
        ),
      ],
    );
  }

  Widget _buildStarIcon(int wordId) {
    return ValueListenableBuilder<bool>(
      valueListenable: starredNotifiers[wordId]!,
      builder: (context, isStarred, _) {
        return IconButton(
          icon: Icon(isStarred ? Icons.star : Icons.star_border, color: isStarred ? Colors.yellow : Colors.grey),
          onPressed: () {
            _toggleStar(wordId, isStarredNotifier);
          },
        );
      },
    );
  }

  int get totalCorrectAnswers {
    return questions.where((q) => q.isAnsweredCorrectly).length;
  }

  int get totalIncorrectAnswers {
    return questions.where((q) => q.userAnswer != null && !q.isAnsweredCorrectly).length;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    if (questions.isEmpty) {
      return const Scaffold(
        backgroundColor: const Color(0xFFFEFAF6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    var currentQuestion = questions[currentQuestionIndex];
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(true);
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: colors["background"],
          appBar: AppBar(
            backgroundColor: colors["background"],
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios,color: colors["text"]),
              onPressed: () async {
                final shouldPop = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    titlePadding: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0, bottom: 10.0),
                    title: Row(
                      children: <Widget>[
                        Image.asset('assets/logo.png', width: 40, height: 40),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Çıkmak istediğinize emin misiniz?',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    content: Text("Bu işlem geri alınamaz. Devam etmek istiyor musunuz?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Hayır', style: TextStyle(color: Colors.red)),
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await ApiService().updateUserPointTimePeriod(userID, score, 0);
                            Navigator.of(context).pop(true);
                          } catch (e) {
                            print("Puan güncelleme hatası: $e");
                            Navigator.of(context).pop(true);
                          }
                        },
                        child: Text('Evet', style: TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
                );
                if (shouldPop ?? false) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<Color>(
                  valueListenable: backgroundColorNotifier,
                  builder: (context, color, _) {
                    return Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 3,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: toggleStarredOnly,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: screenWidth * 0.05,
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                '${starredWordCountNotifier.value}',
                                key: ValueKey<int>(starredWordCountNotifier.value),
                                style: GoogleFonts.lato(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 10),
                _buildTimer(),
              ],
            ),
            centerTitle: true,
            actions: [
              _buildStarIcon(currentQuestion.id),
            ],
          ),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Puan: ',
                              style: GoogleFonts.openSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors["text"],
                              ),
                            ),
                            TextSpan(
                              text: '$score',
                              style: GoogleFonts.openSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors["text"],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.openSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '${currentQuestionIndex + 1}',
                              style:  TextStyle( color: colors["text"]),
                            ),
                            TextSpan(
                              text: ' / ${questions.length}',
                              style:  TextStyle( color: colors["text"]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color:  colors["buttonBackground"],
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      ValueListenableBuilder<bool>(
                        valueListenable: isVisibilityOn,
                        builder: (context, value, child) {
                          return IconButton(
                            icon: Icon(
                              value ? Icons.visibility_off : Icons.visibility,
                              color: colors["text"],
                            ),
                            onPressed: () {
                              showCustomFlushbar(context, isVisibilityOn.value ? "Resim Gizleniyor." : "Resim Gösteriliyor.");
                              isVisibilityOn.value = !value;
                            },
                          );
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: isRefreshOn,
                        builder: (context, value, child) {
                          return IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: value ? colors["text"] : Colors.grey,
                            ),
                            onPressed: () {
                              showCustomFlushbar(context, isSortOn.value ? "Liste Sıralandı." : "Liste Karıştırıldı.");
                              isSortOn.value = !isSortOn.value;
                              _shuffleOrSortWords();
                              _timer?.cancel();
                            },
                          );
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: isMuteOn,
                        builder: (context, value, child) {
                          return IconButton(
                            icon: Icon(
                              value ? Icons.volume_up : Icons.volume_off,
                              color: colors["text"],
                            ),
                            onPressed: () {
                              showCustomFlushbar(context, isMuteOn.value ? "Seslendirme kapanıyor." : "Seslendirme açılıyor.");
                              isMuteOn.value = !value;
                              final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);
                              volumeProvider.toggleVolume();
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isTurkish.value ? Icons.language : Icons.translate,
                          color: colors["text"],
                        ),
                        onPressed: () {
                          isTurkish.value = !isTurkish.value;
                          _changeLang();
                          showCustomFlushbar(context, isTurkish.value ? "Dil İngilizce oldu." : "Dil Türkçe oldu.");
                          _timer?.cancel();
                          startTimer();
                        },
                      ),
                      IconButton(
                        icon:  Icon(Icons.menu,color: colors["text"]),
                        onPressed: _openBottomSheet,
                      ),
                      IconButton(
                        icon:  Icon(Icons.hearing, color: colors["text"]),
                        onPressed: () {
                          _speak();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionContent(questions[index]);
                    },
                  ),
                ),
                _buildQuestionNavigationBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionNavigationBar() {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _navBarScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        itemBuilder: (context, index) {
          Color? bgColor =colors["buttonBackground"];

          if (questionStatuses[index] != null) {
            bgColor = questionStatuses[index]! ? Colors.green : Colors.red;
          }

          if (index == currentQuestionIndex) {
            bgColor = Colors.pink;
          }

          Color textColor = bgColor == Colors.white ? Colors.black : Colors.white;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void showCustomFlushbar(BuildContext context, String message) {
    Flushbar(
      message: message,
      icon: Image.asset(
        'assets/logo.png',
        width: 56.0,
        height: 56.0,
      ),
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.blueGrey[100]!,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      boxShadows: const [
        BoxShadow(
          color: Colors.black45,
          offset: Offset(3, 3),
          blurRadius: 3,
        ),
      ],
      forwardAnimationCurve: Curves.easeInOutCubic,
      reverseAnimationCurve: Curves.easeInOutCubic,
    ).show(context);
  }
}

class QuizQuestion {
  int id;
  String term;
  List<String> options;
  int correctOptionIndex;
  String? image;
  WordDetail wordDetail;
  int? userAnswer;
  bool get isCorrect => userAnswer == correctOptionIndex;
  String correctAnswer;
  QuizQuestion({
    required this.id,
    required this.term,
    required this.options,
    required this.correctOptionIndex,
    required this.image,
    this.userAnswer,
    required this.wordDetail,
    required this.correctAnswer,
  });
  bool get isAnsweredCorrectly => userAnswer == correctOptionIndex;
}

Future<List<QuizQuestion>> generateQuizQuestions(List<WordDetail> words, ValueNotifier<bool> isLanguageTurkish) async {
  var random = Random();
  var questions = <QuizQuestion>[];

  for (var word in words) {
    Set<String> options = isLanguageTurkish.value ? {word.meaning} : {word.word};
    while (options.length < 4) {
      var randomWord = words[random.nextInt(words.length)];
      options.add(isLanguageTurkish.value ? randomWord.meaning : randomWord.word);
    }

    var shuffledOptions = options.toList()..shuffle();
    int correctIndex = isLanguageTurkish.value ? shuffledOptions.indexOf(word.meaning) : shuffledOptions.indexOf(word.word);

    questions.add(QuizQuestion(
      id: word.id,
      term: isLanguageTurkish.value ? word.word : word.meaning,
      options: shuffledOptions,
      correctOptionIndex: correctIndex,
      image: word.image,
      wordDetail: word,
      correctAnswer: isLanguageTurkish.value ? word.meaning : word.word,
    ));
  }

  return questions;
}

class QuizResultsScreen extends StatelessWidget {
  final List<QuizQuestion> questions;

  QuizResultsScreen({required this.questions});

  @override
  Widget build(BuildContext context) {
    int correctAnswers = questions.where((q) => q.isAnsweredCorrectly).length;
    int incorrectAnswers = questions.length - correctAnswers;

    bool _isDarkMode = false; // Dark mode durumu


    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: colors["background"],
      appBar: AppBar(
        title: Text('Quiz Sonuçları', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Doğru Cevap Sayısı: $correctAnswers', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  SizedBox(height: 8),
                  Text('Yanlış Cevap Sayısı: $incorrectAnswers', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ),
            Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                bool isCorrect = question.isAnsweredCorrectly;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}', style: GoogleFonts.nunito(color: Colors.white)),
                      backgroundColor: isCorrect ? Colors.green : Colors.red,
                    ),
                    title: Text(question.term, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                    subtitle: Text('Doğru Cevap: ${question.options[question.correctOptionIndex]}', style: GoogleFonts.nunito()),
                    trailing: Icon(
                      isCorrect ? Icons.check_circle_outline : Icons.highlight_off,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
