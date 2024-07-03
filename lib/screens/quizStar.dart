
import 'package:flutter/material.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/home_screen.dart';
import 'package:kelibu/providers/language_provider.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../providers/volume_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

import '../variables.dart';


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
  final PageController _pageController = PageController();

  Future<void> playSound(String path) async {
    await audioPlayer.play(AssetSource(path));
  }
  double _calculateFontSize(String text) {
    if (text.length < 20) return 2;
    if (text.length < 100) return 2;
    return 2; // Daha uzun metinler için küçük font boyutu
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

class CustomTextStyle {
  static final TextStyle title = GoogleFonts.poppins(
    fontSize: 26, // Biraz daha büyük
    fontWeight: FontWeight.bold,
    color: const Color(0xFFFFB6C1), // Açık pembe renk
    letterSpacing: 1.2,
  );
}

class QuizStarScreen extends StatefulWidget {
  final int classroomId;
  final int studySetId;
  final List<WordDetail> words;

  const QuizStarScreen({
    Key? key,
    required this.words,
    required this.classroomId, // Yeni parametre
    required this.studySetId, // Yeni parametre
  }) : super(key: key);
  @override
  _QuizScreenStarState createState() => _QuizScreenStarState();
}
class _QuizScreenStarState extends State<QuizStarScreen> {
  int currentQuestionIndex = 0;
  PageController _pageController = PageController();
  final ScrollController _navBarScrollController = ScrollController();
  // ValueNotifier değişkenleri tanımla
  ValueNotifier<bool> isRefreshOn = ValueNotifier(true);
  ValueNotifier<bool> isMuteOn = ValueNotifier(true);
  ValueNotifier<bool> isSortOn = ValueNotifier(true);
  ValueNotifier<bool> refresh_off = ValueNotifier(true);
  ValueNotifier<bool> isTurkish = ValueNotifier(false); // Türkçe için false, İngilizce için true
  bool _isDarkMode = false; // Dark mode durumu

  Map<int, bool?> questionStatuses = {};

  int _pausedTime = 0;
  int score = 0;
  ValueNotifier<Color> backgroundColorNotifier = ValueNotifier(Colors.blue); // Varsayılan olarak mavi renk

  Future<void> playSoundCorrect(String path) async {
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.setVolume(0.2); // Ses seviyesini %20 olarak ayarla

    if (!kIsWeb) {
      // Mobil veya masaüstü için
      ByteData data = await rootBundle.load(path);
      Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      String dir = (await getTemporaryDirectory()).path;
      File tempFile = File('$dir/tempSound.wav');
      await tempFile.writeAsBytes(bytes, flush: true);
      await audioPlayer.play(DeviceFileSource(tempFile.path));
    } else {
      // Web için
      ByteData data = await rootBundle.load(path);
      Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      // Doğrudan bellekten ses dosyasını oynat
      await audioPlayer.play(BytesSource(bytes));
    }
  }
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }
  bool showStarredOnly = false; // Yıldızlı kelimeleri gösterme durumunu tutacak

  void resetQuiz() {
    setState(() {
      // Soruları sıfırla ve kullanıcı cevaplarını temizle
      for (var question in questions) {
        question.userAnswer = null;
        questionStatuses[question.id] = null;
      }
      currentQuestionIndex = 0; // İlk soruya dön
      _timer?.cancel(); // Zamanlayıcıyı durdur
      startTimer(); // Zamanlayıcıyı yeniden başlat
    });
  }

  void toggleStarredOnly() {
    setState(() {
      showStarredOnly = !showStarredOnly;
      backgroundColorNotifier.value = showStarredOnly ? Colors.green : Colors.blue;
      showCustomFlushbar(
          context,
          showStarredOnly ? "Yıldızlı kelimeler modu açıldı." : "Yıldızlı kelimeler modu kapandı"
      );
      if (showStarredOnly) {
        // Yıldızlı kelimeleri filtrele ve ilk yıldızlı kelimeye git
        var filteredQuestions = questions.where((q) => starredStatus[q.id] ?? false).toList();
        if (filteredQuestions.isNotEmpty) {
          questions = filteredQuestions;
          resetQuiz(); // Quiz'i sıfırla
        }
      } else {
        // Tüm kelimeleri tekrar yükle ve quiz'i sıfırla
        _initializeQuiz();
        resetQuiz();
      }
      // PageController'ı güncel sayfaya yönlendir
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

  ValueNotifier<int> animatedStarredCount = ValueNotifier(0);
  Map<int, Color> optionColors = {};
  QuizQuestion get currentQuestion => questions[currentQuestionIndex];
  ValueNotifier<bool> isVisibilityOn = ValueNotifier(true);
  Timer? _timer; // late yerine nullable tanımlama
  int _remainingTime = 15; // Zamanlayıcı için kalan süre
  ValueNotifier<bool> get isStarredNotifier {
    int questionId = questions[currentQuestionIndex].id; // id özelliğini ekledim
    return starredNotifiers[questionId] ?? ValueNotifier(false); // Null-safety kontrolü
  }

  _speak() async {
    final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);
    final langueaProvider = Provider.of<LanguageProvider>(context, listen: false);

    // Check if the language is not Turkish and volume is on before speaking
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
    double selectedQuestionOffset = currentQuestionIndex * 50.0; // Örnek genişlik, düzenlenmesi gerekebilir
    _navBarScrollController.animateTo(
      selectedQuestionOffset,
      duration: Duration(milliseconds
          : 300),
      curve: Curves.easeInOut,
    );
  }
  void startTimer({bool resumeFromPausedTime = false}) {
    _timer?.cancel();
    if (resumeFromPausedTime) {
      _remainingTime = _pausedTime; // Durdurulduğu süreden devam et
    } else {
      _remainingTime = 15; // Yeni bir soru için zamanlayıcıyı sıfırla
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_remainingTime == 0) {
        _timer?.cancel(); // Güvenli bir şekilde iptal etme
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
    showCustomFlushbar(
        context,
        isSortOn.value ? "Liste Sıralandı." : "Liste Karıştırıldı."
    );
    if (isSortOn.value) {
      // Sıralama modunda, kelimeleri sırala
      newWords = List<WordDetail>.from(widget.words)..sort((a, b) => a.id.compareTo(b.id));
    } else {
      // Karıştırma modunda, kelimeleri karıştır
      newWords = List<WordDetail>.from(widget.words)..shuffle();
    }

    List<QuizQuestion> newQuestions = await generateQuizQuestions(newWords, isTurkish);


    setState(() {
      questions = newQuestions;
      // Mevcut sorunun indeksini güncelle
      currentQuestionIndex = 0; // veya karıştırılan listedeki uygun indeksi bulun
      // PageController'ı güncel sayfaya yönlendir
      _pageController.jumpToPage(currentQuestionIndex);
    });
  }


  void _changeLang() async {

    List<WordDetail> newWords;
    showCustomFlushbar(
        context,
        isTurkish.value ? "Türkçe Mod açıldı." : "İngilizce Mod açıldı."
    );
    if (isSortOn.value) {
      // Sıralama modunda, kelimeleri sırala
      newWords = List<WordDetail>.from(widget.words)..sort((a, b) => a.id.compareTo(b.id));
    } else {
      // Karıştırma modunda, kelimeleri karıştır
      newWords = List<WordDetail>.from(widget.words)..shuffle();
    }

    List<QuizQuestion> newQuestions = await generateQuizQuestions(newWords, isTurkish);

    setState(() {
      questions = newQuestions;
      // Mevcut sorunun indeksini güncelle
      currentQuestionIndex = 0; // veya karıştırılan listedeki uygun indeksi bulun
      // PageController'ı güncel sayfaya yönlendir
      _pageController.jumpToPage(currentQuestionIndex);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference(); // Dark mode tercihlerini yükle

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      setState(() {
        userID = userProvider.userId;
      });
      _pageController = PageController(initialPage: -1); // Bu örnekte initialPage 0 olarak ayarlandı

      _pageController.addListener(() {
        if (_pageController.page == currentQuestionIndex) {
          _scrollToSelectedQuestion();
        }
      });
      UserProvider userProviderPoint = Provider.of<UserProvider>(context, listen: false);
      print(userProviderPoint.point);
      score = userProviderPoint.point; // Eğer çevirme başarısız olursa varsayılan olarak 0 değerini kullan
      _pageController.addListener(() {
        if (_pageController.page?.round() == _pageController.page) {
          _speak();
        }
      });
      _initializeQuiz(); // Soruları sıralı olarak başlat
      resetOptionColors();
      startTimer();

      _loadStarredStatus();
    });
  }

  void finishQuiz() async {
    int finalScore = score; // Bu fonksiyon, kullanıcının toplam puanını hesaplar.
    try {
      await ApiService().updateUserPointTimePeriod(userID, finalScore,5); // API çağrısı
      print('Puan güncellendi: $finalScore');
    } catch (e) {
      print('Puan güncelleme hatası: $e');
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => QuizResultsScreen(questions: questions),
    ));
    _timer?.cancel();

    // Quiz tamamlandığında yapılacak diğer işlemler (örneğin, sonuç ekranına yönlendirme)
  }
  void _initializeQuiz() async {
    // Başlangıçta kelimeler sıralı olacak
    var sortedWords = List<WordDetail>.from(widget.words)..sort((a, b) => a.id.compareTo(b.id));
    var generatedQuestions = await generateQuizQuestions(sortedWords,isTurkish);

    setState(() {
      questions = generatedQuestions;
    });
  }

  void _updateStarredWordCount() {
    int newCount = starredStatus.values.where((isStarred) => isStarred).length;
    starredWordCount.value = newCount; // Bu satırı ekledim
    animatedStarredCount.value = newCount; // Bu satırı ekledim
  }
  void _loadStarredStatus() async {
    try {
      var initialStatus = await ApiService().checkStarredBulk(
        widget.words.map((e) => e.id).toList(),
        widget.studySetId,
        userID,
      );
      setState(() {
        starredStatus = initialStatus;
        // Her kelime için bir ValueNotifier oluştur
        for (var word in widget.words) {
          starredNotifiers[word.id] = ValueNotifier(initialStatus[word.id] ?? false);

        }
      });
      print(starredNotifiers);
      _updateStarredWordCount(); // Yıldızlı kelime sayısını güncelle

    } catch (e) {
      print('Hata: $e');
    }
  }
  int _calculateScore() {
    // Örnek olarak sabit bir puan döndürülmüştür.
    // Gerçek bir uygulamada bu fonksiyon, kullanıcının cevaplarına göre puanı hesaplar.
    return 100;
  }

  void _showCorrectAnswer() {
    // Doğru cevabı işaretle ve bir sonraki soruya geç
    var correctIndex = questions[currentQuestionIndex].correctOptionIndex;
    setState(() {
      optionColors[correctIndex] = const Color(0xFF4CA64C);
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          resetOptionColors();
          startTimer(); // Yeni soru için zamanlayıcıyı başlat
        });
      } else {
        // Quiz tamamlandı, sonuç ekranına geçiş yapabilirsiniz.
      }
    });
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
        // Her öğeyi String'e dönüştürüp yeni bir liste oluştur
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
      optionColors[correctIndex] = const Color(0xFF4CA64C); // Doğru cevabı işaretle
    });

    Future.delayed(const Duration(milliseconds: 500), () { // Yarım saniye bekle
      if (currentQuestionIndex < questions.length - 1) {
        // Eğer daha soru varsa, bir sonraki soruya geç
        setState(() {
          currentQuestionIndex++;
          resetOptionColors();
          startTimer(); // Yeni soru için zamanlayıcıyı başlat
        });
        _pageController.animateToPage(
          currentQuestionIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        // Eğer soru kalmadıysa, quizi bitir ve sonuç ekranına git
        finishQuiz();
      }
    });
  }

  void _toggleStar(WordDetail word, ValueNotifier<bool> isStarredNotifier) async {
    try {
      // API çağrısını yap
      print(widget.classroomId);
      print(widget.studySetId);
      await ApiService().starWord(word.id, widget.classroomId, widget.studySetId, userID);

      // Yıldızlanma durumunu tersine çevir ve starredStatus map'ini güncelle
      bool newStatus = !isStarredNotifier.value;
      isStarredNotifier.notifyListeners();
      starredStatus[word.id] = newStatus;

      // ValueNotifier'ün değerini güncelle
      isStarredNotifier.value = newStatus;
      isStarredNotifier.notifyListeners();

      // ValueNotifier dinleyicilerine güncellemeyi bildir
      isStarredNotifier.notifyListeners();

      // Sadece yıldıza tıkladığınızda animasyonu başlatmak için ValueNotifier'ı kullanabilirsiniz
      if (newStatus) {
        isStarredNotifier.value = true; // Yıldızı açın
      }
    } catch (e) {
      print('Hata: $e'); // Hata durumunu işleme
    }
    _updateStarredWordCount();

  }

  void _goToNextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        resetOptionColors();
        startTimer(); // Yeni soru için zamanlayıcıyı sıfırla ve başlat
      });
      _pageController.animateToPage(
        currentQuestionIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      finishQuiz();
    }
  }    @override
  void dispose() {
    _timer?.cancel(); // Güvenli bir şekilde iptal etme
    _navBarScrollController.dispose();
    super.dispose();
  }
  void resetOptionColors() {
    optionColors = { for (var item in List.generate(4, (index) => index)) item : Colors.white };
  }
  void _answerQuestion(int selectedIndex) {
    var correctIndex = questions[currentQuestionIndex].correctOptionIndex;
    questions[currentQuestionIndex].userAnswer = selectedIndex; // Cevabı kaydet
    bool isCorrect = selectedIndex == correctIndex;
    int penalty = 15 - _remainingTime; // Örnek: 15 saniyelik bir zamanlayıcı varsayalım
    if (isCorrect) {
      print("correct");
      score += 5; // Sabit puan ekleme
    }
    else {
      // Yanlış cevap durumu, kalan süreye göre puan eksiltme
      if (penalty <= 10) score -= 5; // 10 saniye veya daha az düşünüldüyse
      else score -= 2; // 10 saniyeden fazla düşünüldüyse
    }
    questionStatuses[currentQuestionIndex] = isCorrect;
    _updateUserScore(score);

    setState(() {
      optionColors[selectedIndex] = selectedIndex == correctIndex ? const Color(0xFF4CA64C) : const Color(0xFFFF4C4C);
      if (selectedIndex != correctIndex) {
        optionColors[correctIndex] = const Color(0xFF4CA64C); // Doğru cevabın rengini güncelle
      }
    });

    if (selectedIndex == correctIndex) {
      playSoundCorrect('assets/correct.wav'); // Doğru cevap sesi çal
    } else {
      playSoundCorrect('assets/wrong.wav'); // Yanlış cevap sesi çal
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
        finishQuiz(); // Son soruya ulaştığında quizi bitir ve sonuç ekranına geç
      }
    });
  }
  Future<void> _updateUserScore(int score) async {
    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      int point = userProvider.point.toInt();
      userProvider.addPoint(score);
      await ApiService().updateUserPointTimePeriod(userID, score,5);
    } catch (e) {
      print("Puan güncelleme hatası: $e");
    }
  }
  Widget _buildOption(String option, int index, int correctIndex, int? userAnswer) {
    Color bgColor;
    Color textColor = Colors.black; // Varsayılan metin rengi siyah

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
      padding: EdgeInsets.only(bottom: height * 0.02), // Dinamik padding
      child: GestureDetector(
        onTap: () {
          if (questions[currentQuestionIndex].userAnswer == null) {
            _answerQuestion(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Animasyon süresi
          width: width * 0.8, // Ekran genişliğinin %80'i kadar
          height: height * 0.05, // Ekran yüksekliğinin %8'i kadar, esneklik sağlar
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
                    fontSize: width * 0.03, // Dinamik font boyutu
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
    ValueNotifier<bool> isStarredNotifier = ValueNotifier<bool>(starredStatus[question.id] ?? false);
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, // Vertically center the content
        crossAxisAlignment: CrossAxisAlignment.center, // Horizontally center the content
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Add this to space out elements in the Row
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: colors["background"],
                    borderRadius: BorderRadius.circular(30.0), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 7,
                        offset: const Offset(0, 3), // Shadow direction: down right
                      ),
                    ],
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      child: Text(
                        question.term, // The term or question text
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
          // Add check for question.image being null or empty, then show default logo or image
          _buildImage(question.image?.isEmpty ?? true ? null : question.image!),
          ListView.builder(
            physics: NeverScrollableScrollPhysics(), // Add this to prevent scrolling inside the ListView
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
            opacity: 0.1, // %50 opaklık
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
  }  Widget _buildTimer() {
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
            backgroundColor: Colors.grey.withOpacity(0.2),
          ),
        ),
        Text(
          '$_remainingTime',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  Widget _buildStarIcon(QuizQuestion question, ValueNotifier<bool> isStarredNotifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: isStarredNotifier,
      builder: (context, isStarred, child) {
        return IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              Icons.star,
              key: ValueKey<bool>(isStarred),
              color: Colors.yellow,
            ),
          ),
          onPressed: () {
            _toggleStar(question.wordDetail, isStarredNotifier); // question.wordDetail kullanılıyor
          },
        );
      },
    );
  }
  Widget _buildScore() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        '$score',
        key: ValueKey<int>(score),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
  Widget _buildScoreText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        'Puan: $score',
        key: ValueKey<int>(score),
        style: GoogleFonts.openSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black, // Skor değeri siyah renkte
        ),
      ),
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
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    // Eğer sorular yüklenmemişse, bir yükleniyor göstergesi göster
    if (questions.isEmpty) {
      return const Scaffold(
        backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın

        body: Center(child: CircularProgressIndicator()),
      );
    }
    Future<bool> _updateScoreAndExit() async {
      try {
        // Puanı güncelleyecek API çağrısı
        await ApiService().updateUserPoint(userID, score);
        // Puan başarıyla güncellendiğinde true dönerek sayfadan çıkış yap
        return true;
      } catch (e) {
        // Hata oluşursa konsola yazdır
        print("Puan güncelleme hatası: $e");
        // Hata durumunda da kullanıcıya sayfadan çıkmasına izin ver
        return true;
      }
    }
    var currentQuestion = questions[currentQuestionIndex];
    return
      WillPopScope(
        onWillPop: () async {
      Navigator.of(context).pop(true);
      // Sistem tarafından ek bir pop işlemi yapılmasını engellemek için false dön
      return false;
    },
    child:
      SafeArea(
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
                  titlePadding: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0, bottom: 10.0), // Başlık için padding ayarı
                  title: Row(
                    children: <Widget>[
                      Image.asset('assets/logo.png', width: 40, height: 40), // Logo
                      SizedBox(width: 16), // Logo ile metin arasında boşluk
                      Expanded(
                        child: Text(
                          'Çıkmak istediğinize emin misiniz?',
                          style: TextStyle(
                            fontSize: 18.0, // Metin boyutu
                            fontWeight: FontWeight.bold, // Metin kalınlığı
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Text("Bu işlem geri alınamaz. Devam etmek istiyor musunuz?"), // İçerik metni
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Hayır', style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          // Puanı güncelleme veya diğer işlemleri burada yap
                          Navigator.of(context).pop(true); // İşlem başarılıysa sayfayı kapat
                        } catch (e) {
                          print("Puan güncelleme hatası: $e");
                          Navigator.of(context).pop(true); // Hata olsa bile sayfayı kapat
                        }
                      },
                      child: Text('Evet', style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              );
              if (shouldPop ?? false) {
                Navigator.of(context).pop(); // Kullanıcı 'Evet' dediyse geri dön
              }
            },
          ),
        ),
        body:
        SafeArea(
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
                            text: '$score', // Puanı doğrudan burada göster
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
                            style:  TextStyle(color: colors["text"]), // Toplam soru sayısı siyah renkte
                          ),
                          TextSpan(
                            text: ' / ${questions.length}',
                            style:  TextStyle(color: colors["text"]), // Toplam soru sayısı siyah renkte
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
                  borderRadius: BorderRadius.circular(30.0), // Yuvarlak köşeler
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ValueListenableBuilder<bool>(
                      valueListenable: isVisibilityOn, // Göster/Gizle durumu
                      builder: (context, value, child) {
                        return IconButton(
                          icon: Icon(
                            value ? Icons.visibility_off : Icons.visibility, // İkon durumunu ters çevir
                            color: colors["text"],
                          ),
                          onPressed: () {
                            showCustomFlushbar(
                                context,
                                isVisibilityOn.value ? "Resim Gizleniyor." : "Resim Gösteriliyor."
                            );
                            isVisibilityOn.value = !value;
                          },
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: isRefreshOn, // Yenileme durumu
                      builder: (context, value, child) {
                        return IconButton(
                          icon: Icon(
                            Icons.refresh, // Aynı ikonu kullan
                            color: value ?                            colors["text"] : Colors.grey, // Açık ise mavi, kapalı ise gri
                          ),
                          onPressed: () {
                            showCustomFlushbar(
                                context,
                                isSortOn.value ? "Liste Sıralandı." : "Liste Karıştırıldı."
                            );
                            isSortOn.value = !isSortOn.value;
                            _shuffleOrSortWords();
                            _timer?.cancel();
                          },
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: isMuteOn, // Ses aç/kapat durumu
                      builder: (context, value, child) {
                        return IconButton(
                          icon: Icon(
                            value ? Icons.volume_up : Icons.volume_off, // İkon durumunu ters çevir
                            color: colors["text"],
                          ),
                          onPressed: () {
                            showCustomFlushbar(
                                context,
                                isMuteOn.value ? "Seslendirme kapanıyor." : "Seslendirme açılıyor."
                            );
                            isMuteOn.value = !value;
                            final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);
                            volumeProvider.toggleVolume(); // Bu örnek bir metod çağrısıdır, gerçek metod adı farklı olabilir.
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isTurkish.value ? Icons.language : Icons.translate, // Sıralama veya karıştırma ikonu
                        color:                           colors["text"] ,
                    ),
                      onPressed: () {
                        isTurkish.value = !isTurkish.value;
                        _changeLang();
                        showCustomFlushbar(
                            context,
                            isTurkish.value ? "Dil Türkçe oldu." : "Dil İngilizce oldu.."
                        );
                        _timer?.cancel();
                        startTimer();
                      },
                    ),
                    IconButton(
                        icon:  Icon(Icons.menu, color:   colors["text"] ),
                      onPressed: _openBottomSheet,
                    ),
                    IconButton(
                      icon:  Icon(Icons.hearing, color:   colors["text"]                      ),
                      onPressed: () {
                        _speak();
                      },
                    ),

                    // Kulak ikonu
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Kullanıcı kaydırmayı önle
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
    ));
  }
  Widget _buildQuestionNavigationBar() {
    return SizedBox(
      height: 50, // Navigation bar's height
      child: ListView.builder(
        controller: _navBarScrollController, // Use ScrollController here
        scrollDirection: Axis.horizontal, // Horizontal scrolling
        itemCount: questions.length,
        itemBuilder: (context, index) {
          Color bgColor = Colors.white; // Default background color

          // If the question is answered, determine the color based on the status
          if (questionStatuses[index] != null) {
            bgColor = questionStatuses[index]! ? Colors.green : Colors.red;
          }

          // If it's the current question, use a different color (pink)
          if (index == currentQuestionIndex) {
            bgColor = Colors.pink;
          }

          // Determine text color based on background color
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
                duration: const Duration(milliseconds: 300), // Animation duration
                width: 50, // Box width
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(25), // Rounded shape
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: textColor), // Set text color here
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
  int id; // id özelliğini ekliyorum
  String term;
  List<String> options;
  int correctOptionIndex;
  String? image;
  WordDetail wordDetail;
  int? userAnswer; // Kullanıcının verdiği cevap (null olabilir)
  bool get isCorrect => userAnswer == correctOptionIndex;
  String correctAnswer; // Doğru cevabın metnini ekleyin
// Doğru cevap kontrolü// WordDetail referansı eklendi
  QuizQuestion({
    required this.id, // id parametresini ekliyorum
    required this.term,
    required this.options,
    required this.correctOptionIndex,
    required this.image,
    this.userAnswer,
    required this.wordDetail, // Yapıcıya eklendi
    required this.correctAnswer, // Yapıcıya eklendi

  });
  bool get isAnsweredCorrectly => userAnswer == correctOptionIndex;

}

Future<List<QuizQuestion>> generateQuizQuestions(List<WordDetail> words, ValueNotifier<bool> isLanguageTurkish) async {
  var random = Random();
  var questions = <QuizQuestion>[];

  for (var word in words) {
    Set<String> options = isLanguageTurkish.value ? {word.meaning} : {word.word};
    while (options.length < 4) {
      // Eğer Türkçe ise, anlamlardan rastgele seç, değilse kelimelerden rastgele seç
      var randomWord = words[random.nextInt(words.length)];
      options.add(isLanguageTurkish.value ? randomWord.meaning : randomWord.word);
    }

    var shuffledOptions = options.toList()..shuffle();
    // Doğru seçeneğin index'ini bul
    int correctIndex = isLanguageTurkish.value ? shuffledOptions.indexOf(word.meaning) : shuffledOptions.indexOf(word.word);

    // Soruları ve seçenekleri ayarla
    questions.add(QuizQuestion(
      id: word.id,
      term: isLanguageTurkish.value ? word.word : word.meaning, // Eğer Türkçe ise kelimeyi, değilse anlamı sor
      options: shuffledOptions,
      correctOptionIndex: correctIndex,
      image: word.image,
      wordDetail: word,
      correctAnswer: isLanguageTurkish.value ? word.meaning : word.word, // Eğer Türkçe ise doğru cevap anlam, değilse kelime
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

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Quiz Sonuçları', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()), // 'MainScreen' ana sayfa widget'ınızın adıdır.
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
                    SizedBox(height: 8), // Boşluk eklendi
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
      ),
    );
  }
}

