import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:kelibu/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'package:kelibu/providers/volume_provider.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

import '../shared_preferences/shared_preferences.dart';
import '../variables.dart';

class WordData {
  final int id;
  final String meaning;
  final String imageUrl;

  WordData({required this.id, required this.meaning, this.imageUrl = ''});
}

class KelimeOyunu extends StatefulWidget {
  final int classroomId;
  final int studySetId;
  final List<WordDetail> words;
  bool isStarredMode = false;
  List<WordDetail> starredWords = [];

  KelimeOyunu({Key? key, required this.classroomId, required this.studySetId, required this.words}) : super(key: key);

  @override
  _KelimeOyunuState createState() => _KelimeOyunuState();
}

class _KelimeOyunuState extends State<KelimeOyunu> with TickerProviderStateMixin, WidgetsBindingObserver {
  late ConfettiController _confettiController;
  double kalanZamanSaniye = 15;
  int totalWordsCount = 0;
  int puan = 0;
  late Timer zamanlayici;
  double zamanCubuguDegeri = 1.0;
  late AnimationController scoreAnimationController;
  late Animation<Offset> scoreSlideAnimation;
  OverlayEntry? scoreOverlayEntry;
  Map<String, String> kelimeler = {};
  late Color correctOptionColor;
  late Color wrongOptionColor;
  late Color centerCardColor;
  FlutterTts flutterTts = FlutterTts();

  late Color defaultOptionColor;
  late Map<int, Color> optionColors;
  Color rastgeleAcikRenkUret() {
    final rand = Random();
    final r = 200 + rand.nextInt(12);
    final g = 200 + rand.nextInt(12);
    final b = 200 + rand.nextInt(12);
    return Color.fromRGBO(r, g, b, 1);
  }

  String aktifKelime = '';
  List<String> secenekler = [];
  Map<String, int> kelimeDogruSayac = {};
  Set<String> tamamlananKelimeler = Set();
  String currentImageUrl = "";
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int userID = 2;
  int score = 0;
  late AnimationController scoreTextAnimationController;
  late Animation<Offset> scoreTextSlideAnimation;
  OverlayEntry? scoreTextOverlayEntry;
  late AnimationController _learnedWordsAnimationController;
  late Animation<Offset> _slideAnimation;
  Map<String, Color> secenekRenkleri = {};
  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    _showExitConfirmationDialog();
    return true;
  }

  void _showExitConfirmationDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkmak istediğinize emin misiniz?', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
        content: Text("Bu işlem geri alınamaz.", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hayır', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Evet', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          ),
        ],
      ),
    ).then((value) => value ?? false ? Navigator.of(context).pop(true) : null);
  }

  Future<void> fetchStarredWords() async {
    final service = StarredWordsService();
    List<int> wordIds = widget.words.map((e) => e.id).toList();
    try {
      Set<int> starredWordsSet = await service.loadStarredWords(widget.classroomId, widget.studySetId);
      List<WordDetail> tempStarredWords = [];
      wordIds.forEach((id) {
        if (starredWordsSet.contains(id)) {
          widget.words.forEach((word) {
            if (word.id == id) {
              tempStarredWords.add(word);
            }
          });
        }
      });

      setState(() {
        starredWords = tempStarredWords;
      });
    } catch (e) {
      print("Yıldızlı kelimeler alınırken hata: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.5);
    _loadDarkModePreference();
    scoreAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    scoreSlideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: scoreAnimationController,
      curve: Curves.easeOut,
    ));

    scoreTextAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    scoreTextSlideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: scoreTextAnimationController,
      curve: Curves.easeOut,
    ));

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _learnedWordsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_animationController);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _learnedWordsAnimationController,
      curve: Curves.easeOut,
    ));

    UserProvider userProviderPoint = Provider.of<UserProvider>(context, listen: false);
    print(userProviderPoint.point);
    score = userProviderPoint.point;

    centerCardColor = rastgeleAcikRenkUret();
    correctOptionColor = Colors.lightGreenAccent;
    wrongOptionColor = Colors.redAccent;
    defaultOptionColor = Colors.grey.shade200;
    optionColors = {};

    List<WordDetail> words = widget.words;
    for (var word in words) {
      kelimeler[word.word] = word.meaning;
    }

    widget.words.forEach((word) {
      kelimeDogruSayac[word.word] = 0;
    });

    zamanlayiciyiBaslat();
    secenekleriYenile();
    totalWordsCount = widget.words.length;
  }

  void showScoreAnimation(String scoreText) {
    int scoreChange = int.parse(scoreText);
    Color animationColor = scoreChange >= 0 ? Colors.green : Colors.red;
    scoreOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2,
        left: MediaQuery.of(context).size.width / 2,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: scoreSlideAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                scoreText,
                style: TextStyle(fontSize: 24.0, color: animationColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(scoreOverlayEntry!);
    scoreAnimationController.forward().then((value) {
      Future.delayed(Duration(milliseconds: 500), () {
        scoreOverlayEntry?.remove();
        scoreOverlayEntry = null;
        scoreAnimationController.reset();
      });
    });
  }

  void showScoreTextAnimation(String scoreText) {
    if (scoreTextOverlayEntry != null) {
      scoreTextOverlayEntry!.remove();
    }

    scoreTextOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: MediaQuery.of(context).size.width / 2 - 100,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: scoreTextSlideAnimation,
            child: Container(
              width: 200,
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                scoreText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24.0, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(scoreTextOverlayEntry!);
    scoreTextAnimationController.forward().then((value) {
      Future.delayed(Duration(milliseconds: 500), () {
        scoreTextOverlayEntry?.remove();
        scoreTextOverlayEntry = null;
        scoreTextAnimationController.reset();
      });
    });
  }

  void zamanlayiciyiBaslat({bool kalanZamandanDevamEt = false}) {
    if (!kalanZamandanDevamEt) {
      kalanZamanSaniye = 15;
    }
    zamanCubuguDegeri = kalanZamanSaniye / 15;
    zamanlayici = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (kalanZamanSaniye > 0) {
          kalanZamanSaniye -= 1;
          zamanCubuguDegeri = kalanZamanSaniye / 15;
        } else {
          zamanCubuguDegeri = 0;
          timer.cancel();
          _isOptionSelectable = false;
          int correctIndex = secenekler.indexOf(kelimeler[aktifKelime]!);
          setState(() {
            optionColors[correctIndex] = correctOptionColor;
          });
          Future.delayed(Duration(seconds: 1), () {
            _isOptionSelectable = true;
            secenekleriYenile();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    zamanlayici.cancel();
    _animationController.dispose();
    _learnedWordsAnimationController.dispose();
    zamanlayici.cancel();
    scoreAnimationController.dispose();
    scoreTextAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      zamanlayici.cancel();
    } else if (state == AppLifecycleState.resumed) {
      zamanlayiciyiBaslat(kalanZamandanDevamEt: true);
    }
  }

  void resetGame() {
    setState(() {
      tamamlananKelimeler.clear();
      kalanZamanSaniye = 15;
      zamanCubuguDegeri = 1.0;
      tamamlananKelimeler.clear();
      kelimeDogruSayac.clear();
      _isOptionSelectable = true;
      secenekleriYenile();
      if (zamanlayici.isActive) {
        zamanlayici.cancel();
      }
      zamanlayiciyiBaslat();
    });

    flutterTts.stop();
  }

  void showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.pinkAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: 10),
                Icon(Icons.celebration, size: 60, color: Colors.amberAccent),
                SizedBox(height: 10),
                Text(
                  "Tebrikler!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 15),
                Text(
                  "Oyunu tamamladınız. Diğer kelime setlerimizi incelemeyi unutmayınız.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Icon(Icons.home, color: Colors.white),
                  label: Text("Ana Sayfa", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void returnToHomePage() {
    Navigator.of(context).pop();
  }

  bool isStarredMode = false;
  List<WordDetail> starredWords = [];
  void checkCompletionAndShowDialog() {
    int remainingWords = isStarredMode ? starredWords.length : widget.words.length;
    if (tamamlananKelimeler.length > totalWordsCount) {
      showCompletionDialog();
    }
  }

  void secenekleriYenile() {
    setState(() {
      print(tamamlananKelimeler.length);
      List<WordDetail> currentWords = isStarredMode ? starredWords : widget.words;
      List<WordDetail> filteredWords = currentWords.where((word) => !tamamlananKelimeler.contains(word.word)).toList();
      if (filteredWords.isNotEmpty) {
        aktifKelime = filteredWords[Random().nextInt(filteredWords.length)].word;
        List<String> tumSecenekler = filteredWords.map((e) => e.meaning).toList()..shuffle();
        int listSize = tumSecenekler.length;
        secenekler = tumSecenekler.sublist(0, min(8, listSize));
        if (!secenekler.contains(kelimeler[aktifKelime])) {
          secenekler[Random().nextInt(secenekler.length)] = kelimeler[aktifKelime]!;
        }
        secenekler.shuffle();
        optionColors.clear();
        for (int i = 0; i < secenekler.length + 1; i++) {
          optionColors[i] = defaultOptionColor;
        }
        if (zamanlayici.isActive) {
          zamanlayici.cancel();
        }
        zamanlayiciyiBaslat();
        flutterTts.speak(aktifKelime);
      } else {
        _showCompletionMessage();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isStarredMode ? 'Yıldızlı kelime kalmadı!' : 'Tüm kelimeler soruldu!'),
        ));
      }
    });
  }

  void _showCompletionMessage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Tebrikler!", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: Text("Tüm kelimeleri başarıyla tamamladınız.", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          backgroundColor: _isDarkMode ? Colors.black : Colors.white,
          actions: <Widget>[
            TextButton(
              child: Text("Tekrar Oyna", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
            ),
            TextButton(
              child: Text("Bir Önceki Sayfaya Dön", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _restartGame() {
    setState(() {
      puan = 0;
      kalanZamanSaniye = 15;
      zamanCubuguDegeri = 1.0;
      aktifKelime = '';
      secenekler.clear();
      kelimeDogruSayac.clear();
      tamamlananKelimeler.clear();
      optionColors.clear();
      _isOptionSelectable = true;
      isStarredMode = false;
      starredWords.clear();
      if (zamanlayici.isActive) {
        zamanlayici.cancel();
      }
      zamanlayiciyiBaslat();
      secenekleriYenile();
    });
  }

  bool _isDarkMode = false;

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
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

    return WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop(true);
          return false;
        },
        child: SafeArea(
          child: Scaffold(
            backgroundColor: _isDarkMode ? Colors.black12 : Colors.white,
            appBar: AppBar(
              title: Text('Klasik Kelibu', style: TextStyle(color: _isDarkMode ? Colors.black : Colors.white)),
              actions: [
                IconButton(
                  icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
                  onPressed: _toggleDarkMode,
                  color: _isDarkMode ? Colors.black : Colors.black,
                ),
              ],
            ),
            body: Column(
              children: [
                IconButton(
                  icon: Icon(isStarredMode ? Icons.star : Icons.star_border),
                  onPressed: () async {
                    if (!isStarredMode) {
                      await fetchStarredWords();
                    }
                    setState(() {
                      isStarredMode = !isStarredMode;
                      totalWordsCount = isStarredMode ? starredWords.length : widget.words.length;
                      if (isStarredMode && starredWords.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('En az 1 yıldızlı kelimeniz olması gerekmektedir.', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
                            backgroundColor: _isDarkMode ? Colors.black : Colors.white,
                          ),
                        );
                        isStarredMode = false;
                      } else {
                        secenekleriYenile();
                      }
                    });
                  },
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FloatingActionButton(
                        onPressed: () {
                          final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);
                          volumeProvider.toggleVolume();
                          flutterTts.setVolume(volumeProvider.isVolumeOn ? 0 : 1);
                        },
                        child: Consumer<VolumeProvider>(
                          builder: (context, volumeProvider, child) {
                            return Icon(
                              volumeProvider.isVolumeOn ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                            );
                          },
                        ),
                        backgroundColor: _isDarkMode ? Colors.indigo : Colors.teal,
                        elevation: 8.0,
                        hoverElevation: 10.0,
                        splashColor: Colors.greenAccent,
                        tooltip: 'Sesi Aç/Kapat',
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            WidgetSpan(
                              child: Icon(Icons.star, size: 24, color: Colors.amber),
                            ),
                            TextSpan(
                              text: ' Puan: $score',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : Colors.teal,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 30.0,
                        lineWidth: 4.0,
                        animation: true,
                        percent: zamanCubuguDegeri,
                        center: Text(
                          "${(15 * zamanCubuguDegeri).round()}s",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.teal,
                          ),
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: _isDarkMode ? Colors.indigo : Colors.teal,
                        backgroundColor: _isDarkMode ? Colors.indigo.shade100 : Colors.teal.shade100,
                        footer: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Kalan Süre',
                            style: TextStyle(fontSize: 10, color: _isDarkMode ? Colors.white : Colors.teal[800]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(16),
                    shrinkWrap: true,
                    itemCount: max(secenekler.length + 2, 10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 4) {
                        return Card(
                          color: centerCardColor,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      aktifKelime,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: _isDarkMode ? Colors.white : Colors.teal,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      '${kelimeDogruSayac[aktifKelime] ?? 0}/3',
                                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.teal.shade800),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        int optionIndex = index < 4 ? index : index - 1;
                        if (optionIndex >= secenekler.length) {
                          return Container();
                        }
                        String secenek = secenekler[optionIndex];
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          color: optionColors[optionIndex],
                          child: InkWell(
                            onTap: () => handleOptionTap(secenek, optionIndex),
                            child: Center(
                              child: Text(
                                secenek,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: _isDarkMode ? Colors.black45 : Colors.teal.shade800,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [Colors.green, Colors.blue, Colors.orange, Colors.purple],
                    numberOfParticles: 30,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BottomAppBar(
              color: _isDarkMode ? Colors.indigo : Colors.teal,
              child: Container(
                height: 60.0,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => showLearnedWordsModal(context),
                      child: Text('Öğrenilen Kelimeleri Göster', style: TextStyle(color: Colors.white)),
                    ),
                    Text(
                      isStarredMode ? '${tamamlananKelimeler.length} / ${totalWordsCount}' : '${tamamlananKelimeler.length} / ${totalWordsCount}',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  void showModal(BuildContext context) {
    showPlatformDialog(
      context: context,
      builder: (BuildContext dialogContext) => BasicDialogAlert(
        title: Text("Ayarlar", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.volume_off),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.translate),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.star),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text("Kapat", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            onPressed: () {
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

  void showLearnedWordsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          color: _isDarkMode ? Colors.black : Colors.white,
          padding: EdgeInsets.all(8),
          height: MediaQuery.of(context).size.height * 0.5,
          child: ListView(
            children: tamamlananKelimeler.map((kelime) => ListTile(
              title: Text(kelime, style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
              trailing: Icon(Icons.check, color: Colors.green),
            )).toList(),
          ),
        );
      },
    );
  }

  bool _isOptionSelectable = true;

  void handleOptionTap(String secenek, int index) {
    if (!_isOptionSelectable) return;
    final bool isCorrect = secenek == kelimeler[aktifKelime];
    int correctIndex = secenekler.indexOf(kelimeler[aktifKelime]!);
    int optionIndex = index;
    int remainingSeconds = (15 * zamanCubuguDegeri).round();
    int pointChange = isCorrect ? remainingSeconds : -remainingSeconds;

    setState(() {
      _isOptionSelectable = false;
      if (isCorrect) {
        kelimeDogruSayac[aktifKelime] = (kelimeDogruSayac[aktifKelime] ?? 0) + 1;
        score += pointChange;
        optionColors[optionIndex] = correctOptionColor;
        if (kelimeDogruSayac[aktifKelime]! >= 3) {
          tamamlananKelimeler.add(aktifKelime);
          if (isStarredMode) {
            starredWords.removeWhere((word) => word.word == aktifKelime);
          }
          _confettiController.play();
          showScoreTextAnimation(aktifKelime);
          score += 30;
        }
      } else {
        kelimeDogruSayac[aktifKelime] = 0;
        score += pointChange;
        optionColors[optionIndex] = wrongOptionColor;
        optionColors[correctIndex] = correctOptionColor;
      }

      showScoreAnimation('${pointChange > 0 ? '+' : ''}$pointChange');
      _updateUserScore(score, pointChange);

      Future.delayed(Duration(milliseconds: 1000), () {
        setState(() {
          _isOptionSelectable = true;
          secenekleriYenile();
        });
        checkCompletionAndShowDialog();
      });
    });
  }

  Future<void> _updateUserScore(int score, int pointChange) async {
    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      userID = userProvider.userId;
      print("userid" + userID.toString());
      await ApiService().updateUserPointTimePeriod(userID, score, pointChange);
      userProvider.addPoint(score);
      print("Puan güncellendi: $score");
    } catch (e) {
      print("Puan güncelleme hatası: $e");
    }
  }

  void showFeedback({required bool isCorrect}) {
    final snackBar = SnackBar(
      content: Text(isCorrect ? 'Doğru!' : 'Yanlış! Doğru cevap: ${kelimeler[aktifKelime]}', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
      backgroundColor: isCorrect ? Colors.green : Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
