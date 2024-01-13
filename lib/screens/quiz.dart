  import 'package:flutter/material.dart';
  import 'package:kelibu/Models/wordDetaik.dart';
  import 'dart:math';
  import 'dart:async';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:kelibu/api.dart';
  import 'package:audioplayers/audioplayers.dart';
  import '../providers/user_provider.dart';
  import 'package:provider/provider.dart';
  import '../providers/volume_provider.dart';
  import 'package:flutter_tts/flutter_tts.dart';
  import 'package:path/path.dart' as p;
  import 'dart:io';
  import 'dart:typed_data';
  import 'package:path_provider/path_provider.dart';
  import 'package:flutter/services.dart' show rootBundle;
  import 'package:audioplayers/audioplayers.dart';

  class QuizCard extends StatefulWidget {
    final String question;
    final Duration duration;

    const QuizCard({Key? key, required this.question, this.duration = const Duration(seconds: 1)}) : super(key: key);

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
            child: Text(widget.question),
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
    // ValueNotifier değişkenleri tanımla
    ValueNotifier<bool> isRefreshOn = ValueNotifier(true);
    ValueNotifier<bool> isMuteOn = ValueNotifier(true);
    ValueNotifier<bool> isSortOn = ValueNotifier(true);
    ValueNotifier<bool> refresh_off = ValueNotifier(true);
    int _pausedTime = 0;
    int score = 0;
    Future<void> playSoundCorrect(String path) async {
      ByteData data = await rootBundle.load(path);
      Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      String dir = (await getTemporaryDirectory()).path;
      File tempFile = File('$dir/tempSound.wav');
      await tempFile.writeAsBytes(bytes, flush: true);

      AudioPlayer audioPlayer = AudioPlayer();
      await audioPlayer.play(DeviceFileSource(tempFile.path));
    }


    final AudioPlayer audioPlayer = AudioPlayer();
    final FlutterTts flutterTts = FlutterTts();
    bool isSpeaking = false;
    Future<void> playSound(String path) async {
      await audioPlayer.play(AssetSource(path));
    }
    late List<QuizQuestion> questions = [];

    int currentQuestionIndex = 0;
    final PageController _pageController = PageController();
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
    Timer? _timer; // late yerine nullable tanımlama
    int _remainingTime = 15; // Zamanlayıcı için kalan süre
    ValueNotifier<bool> get isStarredNotifier {
      int questionId = questions[currentQuestionIndex].id; // id özelliğini ekledim
      return starredNotifiers[questionId] ?? ValueNotifier(false); // Null-safety kontrolü
    }
    _speak() async {

      final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);

      if (!isSpeaking && volumeProvider.isVolumeOn) {
        isSpeaking = true;
        String wordToSpeak = questions[currentQuestionIndex].term;
        await flutterTts.setLanguage("en-US");
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(wordToSpeak);
        isSpeaking = false;
      }
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

      if (isSortOn.value) {
        // Sıralama modunda, kelimeleri sırala
        newWords = List<WordDetail>.from(widget.words)..sort((a, b) => a.id.compareTo(b.id));
      } else {
        // Karıştırma modunda, kelimeleri karıştır
        newWords = List<WordDetail>.from(widget.words)..shuffle();
      }

      var newQuestions = await generateQuizQuestions(newWords);

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        setState(() {
          userID = userProvider.userId;
        });
        ApiService().fetchUserPoint(userID).then((userPoint) {
          print(userID);
          setState(() {
            score = userPoint;
            print('userPoint: $score');
          });
        }).catchError((error) {
          print("Error fetching user point: $error");
        });
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
        await ApiService().updateUserPoint(userID, finalScore); // API çağrısı
        print('Puan güncellendi: $finalScore');
      } catch (e) {
        print('Puan güncelleme hatası: $e');
      }

      // Quiz tamamlandığında yapılacak diğer işlemler (örneğin, sonuç ekranına yönlendirme)
    }
    void _initializeQuiz() async {
      // Başlangıçta kelimeler sıralı olacak
      var sortedWords = List<WordDetail>.from(widget.words)..sort((a, b) => a.id.compareTo(b.id));
      var generatedQuestions = await generateQuizQuestions(sortedWords);

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
                      color: Colors.pink.shade100,
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
                            style: const TextStyle(color: Colors.white, fontSize: 16),
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
                                return Center(
                                  child: Text(
                                    sentences[index],
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
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
        _goToNextQuestion(); // Bir sonraki soruya geç
      });
    }
    void _toggleStar(WordDetail word, ValueNotifier<bool> isStarredNotifier) async {
      try {
        // API çağrısını yap
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
      super.dispose();
    }
    void resetOptionColors() {
      optionColors = { for (var item in List.generate(4, (index) => index)) item : Colors.white };
    }
    void _answerQuestion(int selectedIndex) {
      var correctIndex = questions[currentQuestionIndex].correctOptionIndex;
      questions[currentQuestionIndex].userAnswer = selectedIndex; // Cevabı kaydet

      setState(() {
        optionColors[selectedIndex] = selectedIndex == correctIndex ? const Color(0xFF4CA64C) : const Color(0xFFFF4C4C);
        if (selectedIndex != correctIndex) {
          optionColors[correctIndex] = const Color(0xFF4CA64C); // Doğru cevabın rengini güncelle
        }
      });
      if (selectedIndex == correctIndex) {
        score += _remainingTime; // Doğru cevap için kalan zaman kadar puan ekle
        playSoundCorrect('assets/correct.wav'); // Doğru cevap sesi çal
      } else {
        playSoundCorrect('assets/wrong.wav'); // Yanlış cevap sesi çal
      }
      setState(() {
        optionColors[selectedIndex] = selectedIndex == correctIndex ? const Color(0xFF4CA64C) : const Color(0xFFFF4C4C);
        if (selectedIndex != correctIndex) {
          optionColors[correctIndex] = const Color(0xFF4CA64C);
          // Doğru cevabın rengini güncelle
        }
        Future.delayed(const Duration(seconds: 1), () {
          if (currentQuestionIndex < questions.length - 1) {
            currentQuestionIndex++;
            _pageController.animateToPage(
              currentQuestionIndex,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
            resetOptionColors();
            startTimer();
          } else {
            // Quiz tamamlandı, sonuç ekranına geçiş yapabilirsiniz.
          }
        });
      });
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

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: GestureDetector(
          onTap: () {
            if (questions[currentQuestionIndex].userAnswer == null) {
              _answerQuestion(index);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300), // Animasyon süresi
            width: MediaQuery.of(context).size.width * 0.8, // Ekran genişliğinin %80'i kadar
            height: 50,
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
                const SizedBox(width: 10),
                Image.asset('assets/logo.png', width: 45, height: 45),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
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
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // İçeriği dikey olarak ortala
          crossAxisAlignment: CrossAxisAlignment.center, // İçeriği yatay olarak ortala
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white, // İçerik arka plan rengi
                      borderRadius: BorderRadius.circular(30.0), // Oval kenarlar
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 7,
                          offset: const Offset(0, 3), // Gölgelendirme
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        question.term, // Güncel sorunun metni
                        style: CustomTextStyle.title,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (question.image != null && question.image!.isNotEmpty) // Resim varsa göster
              _buildImage(question.image!),
            ListView.builder(
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
    Widget _buildImage(String imageUrl) {
      return AnimatedCrossFade(
        duration: const Duration(milliseconds: 500),
        firstChild: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            'https://cloud.argethink.com/uploads/kelibu.net/$imageUrl',
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
    }
    Widget _buildTimer() {
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
                isStarred ? Icons.star : Icons.star_border,
                key: ValueKey<bool>(isStarred),
                color: isStarred ? Colors.yellow : null,
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
      // Eğer sorular yüklenmemişse, bir yükleniyor göstergesi göster
      if (questions.isEmpty) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      var currentQuestion = questions[currentQuestionIndex];
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: _buildTimer(),
          actions: [
            _buildStarIcon(currentQuestion, isStarredNotifier),
          ],
          centerTitle: true,
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
                              color: Colors.grey, // "Puan:" metni gri renkte
                            ),
                          ),
                          TextSpan(
                            text: '$score', // Puanı doğrudan burada göster
                            style: GoogleFonts.openSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Skor değeri siyah renkte
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
                            style: const TextStyle(color: Colors.grey), // Mevcut soru numarası gri renkte
                          ),
                          TextSpan(
                            text: ' / ${questions.length}',
                            style: const TextStyle(color: Colors.black), // Toplam soru sayısı siyah renkte
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
                  color: const Color(0xFFFADADD), // Pastel pembe arka plan
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
                            color: Colors.pink,
                          ),
                          onPressed: () {
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
                            color: value ? Colors.pink : Colors.grey, // Açık ise mavi, kapalı ise gri
                          ),
                          onPressed: () {
                            isRefreshOn.value = !value;
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
                            color: Colors.pink,
                          ),
                          onPressed: () {
                            isMuteOn.value = !value;
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isSortOn.value ? Icons.sort_by_alpha : Icons.shuffle, // Sıralama veya karıştırma ikonu
                        color: Colors.pink,
                      ),
                      onPressed: () {
                        isSortOn.value = !isSortOn.value;
                        _shuffleOrSortWords();
                        // Timer'ı sıfırla veya yeniden başlat
                        _timer?.cancel();
                        startTimer();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: _openBottomSheet,
                    ),
                    IconButton(
                      icon: const Icon(Icons.hearing, color: Colors.pink,),
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
              _buildQuestionNavigationBar(), // Navigasyon barını ekleyin

            ],

          ),
        ),
      );
    }
    Widget _buildQuestionNavigationBar() {
      return SizedBox(
        height: 50, // Navigasyon barının yüksekliği
        child: ListView.builder(
          scrollDirection: Axis.horizontal, // Yatay kaydırma
          itemCount: questions.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0), // Her kutu arasında boşluk
              child: GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 50, // Kutu genişliği
                  alignment: Alignment.center, // Soru numarası
                  decoration: BoxDecoration(
                    color: index == currentQuestionIndex ? Colors.pink : const Color(0xFFFADADD), // Pastel pembe renk
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(25), // Oval şekil
                  ),
                  child: Text('${index + 1}'),
                ),
              ),
            );
          },
        ),
      );
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
    bool get isCorrect => userAnswer == correctOptionIndex; // Doğru cevap kontrolü// WordDetail referansı eklendi
    QuizQuestion({
      required this.id, // id parametresini ekliyorum
      required this.term,
      required this.options,
      required this.correctOptionIndex,
      required this.image,
      this.userAnswer,
      required this.wordDetail, // Yapıcıya eklendi
    });
    bool get isAnsweredCorrectly => userAnswer == correctOptionIndex;

  }
  Future<List<QuizQuestion>> generateQuizQuestions(List<WordDetail> words) async {
    var random = Random();
    var questions = <QuizQuestion>[];

    // Tüm kelimeler için örnek cümleleri çek

    for (var word in words) {
      Set<String> options = {word.meaning};
      while (options.length < 4) {
        options.add(words[random.nextInt(words.length)].meaning);
      }

      var shuffledOptions = options.toList()..shuffle();
      int correctIndex = shuffledOptions.indexOf(word.meaning);

      questions.add(QuizQuestion(
        id: word.id,
        term: word.word,
        options: shuffledOptions,
        correctOptionIndex: correctIndex,
        image: word.image,
        wordDetail: word,
      ));
    }

    return questions;
  }
