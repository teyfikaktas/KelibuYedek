import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiping_card_deck/swiping_card_deck.dart';
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

import '../variables.dart';
class ScoreDisplay extends StatelessWidget {
  final ValueNotifier<int> userPointsNotifier; // Now expects a ValueNotifier

  const ScoreDisplay({Key? key, required this.userPointsNotifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        // Wrap Text widget with ValueListenableBuilder
        child: ValueListenableBuilder<int>(
          valueListenable: userPointsNotifier, // Listen to the ValueNotifier
          builder: (context, value, child) {
            // This builder rebuilds whenever the notifier's value changes
            return Text(
              "Puan: $value", // Display the current value
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }
}

// UserProvider importu
class SwipeHintAnimation extends StatefulWidget {
  final Function onAnimationComplete; // Animasyon tamamlandığında çağrılacak fonksiyon

  SwipeHintAnimation({Key? key, required this.onAnimationComplete}) : super(key: key);

  @override
  _SwipeHintAnimationState createState() => _SwipeHintAnimationState();
}

class _SwipeHintAnimationState extends State<SwipeHintAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000), // Animasyon süresini ayarlayabilirsiniz
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
      end: Offset(1.0, 0.0), // Sağa doğru bir kayma
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward().then((value) {
      widget.onAnimationComplete(); // Animasyon tamamlandığında dışarıya bir sinyal gönder
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation, // Yavaşça kaybol
      child: SlideTransition(
        position: _slideAnimation, // Sağa kaydır
        child: Icon(
          Icons.back_hand_outlined, // Ya da istediğiniz bir ikon
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
  final double width;
  final int currentIndex;
  final int total;

  const AnimatedProgressBar({
    Key? key,
    required this.targetProgress,
    required this.currentIndex,
    required this.total,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  _AnimatedProgressBarState createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.targetProgress,
    ).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });

    _animationController.forward();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  void toggleAnimation(bool isMenuOpen) {
    setState(() {
      if (isMenuOpen) {
        _animationController.stop(); // Menü açıldığında animasyonu durdur
      } else {
        _animationController.forward(); // Menü kapandığında animasyonu devam ettir
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetProgress != oldWidget.targetProgress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.targetProgress,
      ).animate(_animationController);

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
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        children: [
          Container(
            width: widget.width != double.infinity
                ? widget.width
                : MediaQuery.of(context).size.width - 32,
            height: screenHeight * 0.02, // Yükseklik
            decoration: BoxDecoration(
              color: colors["progressBackground"] ?? Colors.grey, // Dark mode veya light mode arka plan rengi
              borderRadius: BorderRadius.circular(10), // Yuvarlatılmış köşeler
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progressAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors["progressForegroundStart"] ?? Colors.pink,
                      colors["progressForegroundEnd"] ?? Colors.purple
                    ], // Dark mode veya light mode gradient renkleri
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10), // Yuvarlatılmış köşeler
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${widget.currentIndex}/${widget.total}",
                    style: TextStyle(color: colors["text"] ?? Colors.black), // Dark mode veya light mode metin rengi
                  ),
                  // Diğer widget'lar veya boş bir widget olabilir
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomProgressBar extends StatelessWidget {
  final double progress;
  final double width;

  const CustomProgressBar({Key? key, required this.progress, this.width = double.infinity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: width,
      height: screenHeight*0.02, // Yükseklik
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFC0CB), Color(0xFFFFD1DC)], // Açık pembe tonları
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),

    );

  }
}
class MyVolumeControl extends StatefulWidget {
  const MyVolumeControl({Key? key}) : super(key: key);

  @override
  MyVolumeControlState createState() => MyVolumeControlState();
}

class MyVolumeControlState extends State<MyVolumeControl> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool("darkMode") ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final volumeProvider = Provider.of<VolumeProvider>(context);
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return IconButton(
      icon: Icon(
        volumeProvider.isVolumeOn ? Icons.volume_up : Icons.volume_off,
        color: colors["inputBackground"],
      ),
      onPressed: () => _toggleVolume(volumeProvider, context),
    );
  }

  void _toggleVolume(VolumeProvider volumeProvider, BuildContext context) {
    volumeProvider.toggleVolume();
    _showCustomFlushbar(
        context,
        volumeProvider.isVolumeOn ? "Ses açıldı" : "Ses kapandı"
    );
  }

  void _showCustomFlushbar(BuildContext context, String message) {
    Flushbar(
      message: message,
      icon: Image.asset('assets/logo.png', width: 56.0, height: 56.0),
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.blueGrey[100]!,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      boxShadows: const [
        BoxShadow(color: Colors.black45, offset: Offset(3, 3), blurRadius: 3),
      ],
      forwardAnimationCurve: Curves.easeInOutCubic,
      reverseAnimationCurve: Curves.easeInOutCubic,
    ).show(context);
  }
}

class CardImage extends StatelessWidget {
  final String text;
  final String imageUrl;
  final ValueNotifier<bool> isVisibleNotifier;
  final bool isImageShow;
  final Color backgroundColor; // Yeni parametre

  const CardImage({
    Key? key,
    required this.text,
    required this.imageUrl,
    required this.isVisibleNotifier,
    required this.isImageShow,
    required this.backgroundColor, // Yeni parametre
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isVisibleNotifier,
      builder: (context, isVisible, child) {
        return Container(
          color: backgroundColor, // Arka plan rengini burada ayarlıyoruz
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (isImageShow)
                AnimatedOpacity(
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width * 0.7,
                    child: Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                        // Burada resim yüklenemediğinde gösterilecek alternatif bir resmi belirleyebilirsiniz.
                        return Image.asset('assets/logo.png', width: 100, height: 100);
                      },
                    ),
                  ),
                ),
              Positioned(
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: Colors.white.withOpacity(0.7),
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: AutoSizeText(
                    text,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.03, // Başlangıç font büyüklüğü
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    minFontSize: 8, // Minimum font büyüklüğü
                    maxLines: 5, // Maksimum satır sayısı
                    overflow: TextOverflow.ellipsis, // Taşma durumunda nasıl davranılacağı
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class FlashCardStarScreen extends StatefulWidget {


  final List<WordDetail> words;
  final int classroomId; // Yeni eklenen alan
  final int studySetId; // Yeni eklenen alan
  const FlashCardStarScreen({
    Key? key,
    required this.words,
    required this.classroomId, // Yeni parametre
    required this.studySetId, // Yeni parametre

  }) : super(key: key);

  @override
  _FlashCardStarScreenState createState() => _FlashCardStarScreenState();
}
class _FlashCardStarScreenState extends State<FlashCardStarScreen> with SingleTickerProviderStateMixin {
  bool isStarred = false;
  ValueNotifier<int> currentWordIndex = ValueNotifier(0); // Mevcut kelime indeksi için ValueNotifier ekle
  int wordId = 0;
  int currentCardIndex = 0; // Mevcut kartın indeksini saklamak için bir değişken
  bool isShuffled = false;
  int totalWords = 0; // Toplam kelime sayısı
  DateTime? lastSwipeTime;
  Map<int, GlobalKey<FlipCardState>> cardKeys = {};
  ValueNotifier<int> starredWordCount = ValueNotifier(0);
  ValueNotifier<Color> borderColorNotifier = ValueNotifier(Colors.white);
  ValueNotifier<int> animatedStarredCount = ValueNotifier(0);
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  String currentWord = ""; // Şu anki kelimeyi takip etmek için değişkens
  ValueNotifier<bool> isVisibilityOn = ValueNotifier(true);
  bool isShuffleOn = true;
  bool isLanguageOn = true;
  bool isVolumeOn = true;
  int userID= 2;
  late UserProvider userProvider;
  ValueNotifier<int> pointValueNotife = ValueNotifier(0);
  bool _isDarkMode = false;

  Future<void> onCardSwiped() async {
    int newPoint = userProvider.point;

    newPoint += 1; // Örnek olarak 3 puan ekleyin
    pointValueNotife.value +=1;

    await ApiService().updateUserPointTimePeriod(userProvider.userId, newPoint,1); // API üzerinden puanı güncelleyin
    userProvider.addPoint(newPoint); // UserProvider'daki puanı güncelleyin

  }
  Map<int, bool> starredStatus = {};
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  bool _isAnimationCompleted = false; // Animasyonun tamamlanıp tamamlanmadığını takip eden değişken
  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    _showExitConfirmationDialog();
    return true;
  }
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
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
  ValueNotifier<Color> backgroundColorNotifier = ValueNotifier(Colors.blue); // Varsayılan olarak mavi renk
  final FlutterTts flutterTts = FlutterTts();
  @override
  void initState() {
    super.initState();

    for (var word in widget.words) {
      cardKeys[word.id] = GlobalKey<FlipCardState>();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.words.isNotEmpty) {
        _speak();
      }
    });
    _loadStarredStatus();
    _loadDarkModePreference();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    currentWordIndex.value = 0; // Başlangıçta mevcut kelime indeksini 0 olarak ayarla

    _borderColorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.green,
    ).animate(_animationController)
      ..addListener(() {
        borderColorNotifier.value = _borderColorAnimation.value ?? Colors.white; // Null kontrolü eklendi
      });
    totalWords = widget.words.length; // Toplam kelime sayısını ayarla
    Future.microtask(() {
      userProvider = Provider.of<UserProvider>(context, listen: false);
      // Now that userProvider is initialized, you can use it safely.
      // If you have any code that depends on userProvider and needs to be executed right away,
      // consider calling it here.

      // Initialize the pointValueNotifier with the user's current points.
      pointValueNotife.value = userProvider.point; // Adjusted initialization
    });
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      _updateStarredWordCount(); // Yıldızlı kelime sayısını güncelle

    } catch (e) {
      print('Hata: $e');
    }
  }
  bool isSpeaking = false;
  bool _showStarredOnly = false;
  void _toggleStarredView() {
    print("Yıldız görünümü değiştiriliyor: $_showStarredOnly");
    showCustomFlushbar(
      context,
      _showStarredOnly ? "Yıldızlı kelimeler modu kapandı." : "Yıldızlı kelimeler modu açıldı.",
    );
    currentWordIndex.value = 0;
    setState(() {
      _showStarredOnly = !_showStarredOnly;
      backgroundColorNotifier.value = _showStarredOnly ? Colors.green : Colors.blue;

      // Yıldızlı kelimelerin listesini filtreleyin
      List<WordDetail> wordsToShow;
      if (_showStarredOnly) {
        wordsToShow = widget.words.where((word) => starredStatus[word.id] ?? false).toList();
      } else {
        wordsToShow = widget.words;
      }

      // İlerleme çubuğunu ve mevcut kelime sayısını sıfırlayın
      currentWordIndex.value = 0;
      totalWords = wordsToShow.length; // Yeni toplam kelime sayısını ayarlayın
    });

    // Eğer sıfırdan farklı bir kelime sayısı istiyorsanız, burada _speak() çağrısını yapabilirsiniz
  }
  _speak() async {
    final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);

    if (!isSpeaking && volumeProvider.isVolumeOn) {
      isSpeaking = true;

      String wordToSpeak = ""; // Başlangıçta boş bir değer atayın
      if (_showStarredOnly) {
        // Yıldızlı mod aktifse, yıldızlı kelimeler listesinden kelime seç
        var starredWords = widget.words.where((word) => starredStatus[word.id] ?? false).toList();
        if (currentWordIndex.value < starredWords.length) {
          wordToSpeak = starredWords[currentWordIndex.value].word;
        }
      } else {
        // Yıldızlı mod değilse, orijinal kelimeler listesinden kelime seç
        if (currentWordIndex.value < widget.words.length) {
          wordToSpeak = widget.words[currentWordIndex.value].word;
        }
      }

      // Sözcüğü seslendir, eğer geçerli bir kelime varsa
      if (wordToSpeak.isNotEmpty) {
        await flutterTts.setLanguage("en-US");
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(wordToSpeak);
      }
      isSpeaking = false;
    }
  }
  Widget _buildStarIcon(WordDetail word, ValueNotifier<bool> isStarredNotifier) {
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
            _toggleStar(word, isStarredNotifier);
            // Opcionalmente, puede reproducir un sonido o efecto adicional aquí
          },
        );
      },
    );
  }
  void _toggleStar(WordDetail word, ValueNotifier<bool> isStarredNotifier) async {
    try {
      // API çağrısını yap
      await ApiService().starWord(word.id, widget.classroomId, widget.studySetId, userID);

      // Yıldızlanma durumunu tersine çevir ve starredStatus map'ini güncelle
      bool newStatus = !isStarredNotifier.value;
      starredStatus[word.id] = newStatus;

      // ValueNotifier'ün değerini güncelle
      isStarredNotifier.value = newStatus;

      // Yıldızlı kelime sayısını güncelle
      _updateStarredWordCount();
    } catch (e) {
      print('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {

    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    userProvider = Provider.of<UserProvider>(context, listen: false);
    // Card listesi oluşturma
    List<Card> cardDeck = widget.words.map((word) {
      return _buildCard(word.type,word.word, word.meaning, word.image, word.id, word, cardKeys[word.id]!);
    }).toList();
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return
      WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop(true);
            return false;
          },
          child: Scaffold(
            backgroundColor: colors["background"], // Arka plan rengini burada ayarlayın

            appBar: AppBar(
              backgroundColor: colors["background"], // Arka plan rengini burada ayarlayın

              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios,color: colors["text"]),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                Spacer(),
                Spacer(),
                Spacer(),

                Spacer(),
                ScoreDisplay(userPointsNotifier: pointValueNotife), // Updated to use the notifier
              ],
            ),
            body: SafeArea(

              child: Column(
                children: <Widget>[
                  // İlerleme çubuğu (progress bar)
                  ValueListenableBuilder<int>(
                    valueListenable: currentWordIndex,
                    builder: (context, index, child) {
                      double progress = (index + 1) / totalWords;
                      return AnimatedProgressBar(
                        targetProgress: progress,
                        currentIndex: index + 1,
                        total: totalWords,
                      );
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                  Flexible(
                    flex: 1, // Menü ve yıldız sayısının boyutunu ayarlar
                    child: Column(
                      children: [
                        // Yıldız sayısı
                        // Menü
                        Container(
                          decoration: BoxDecoration(
                            color: colors["borderColor"], // Pastel pembe arka plan
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
                              // İlk IconButton (Görünürlük Düğmesi)
                              ValueListenableBuilder<bool>(
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
                              ),
                              // İkinci IconButton
// Karıştırma butonu için örnek
                              Expanded(
                                child: IconButton(
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
                                      currentWordIndex.value = 0; // indeksi sıfırla
                                    });
                                    _speak();

                                    showCustomFlushbar(
                                      context,
                                      isShuffled ? "Liste karıştırıldı." : "Liste Sıralandı.",
                                    );
                                  },
                                ),
                              ),
                              // Üçüncü IconButton
                              Expanded(
                                child: Consumer<LanguageProvider>(
                                  builder: (context, languageProvider, child) {
                                    return IconButton(
                                      icon: Icon(
                                        languageProvider.isEnglish
                                            ? Icons.language
                                            : Icons.translate,
                                        color: colors["inputBackground"],
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
                                ),
                              ),
                              // Dördüncü IconButton
                              const Expanded(
                                child: MyVolumeControl(),
                              ),
                              // Beşinci IconButton
                              IconButton(
                                icon:  Icon(Icons.hearing,color: colors["inputBackground"],),
                                onPressed: () {
                                  _speak();
                                },
                              ),
                            ],
                          ),
                        ),
                        // İlerleme çubuğu (progress bar)
                        Align(
                          alignment: Alignment.topCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                    ),
                  ),
                  SwipingCardDeck(
                    cardDeck: _buildCardDeck(),
                    onDeckEmpty: () {
                      // Deck boş olduğunda yapılacak işlemler
                    },
                    onLeftSwipe: (Card card) => _handleSwipe(true),
                    onRightSwipe: (Card card) => _handleSwipe(true),
                    swipeThreshold: MediaQuery.of(context).size.width / 4,
                    minimumVelocity: 1000,
                    cardWidth: MediaQuery.of(context).size.width * 0.85, // Kart genişliğini ekran genişliğine göre ayarla
                  ),
                  if (!_isAnimationCompleted)
                    SwipeHintAnimation(
                      onAnimationComplete: () {
                        // Animasyon tamamlandığında bu blok çalışacak

                      },
                    ),//
                  // Yıldız sayısı ve Menü
                ],
              ),
            ),
          ));

  }
  void _resetCardsToFront() {
    cardKeys.forEach((key, cardKey) {
      // Add null safety checks
      if (cardKey.currentState?.isFront == false) {
        cardKey.currentState?.toggleCard();
      }
    });
  }

  Card _buildCard(String? type,String englishWord, String turkishWord, String? imageUrl, int wordId, WordDetail word, GlobalKey<FlipCardState> cardKey) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    String fullImageUrl = imageUrl != null
        ? "https://cloud.phdakademi.com/uploads/kelibu.net/$imageUrl"
        : "https://kelibu.net/images/defaultimage.png";
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    _speak();

    // Ekran boyutuna göre kart boyutlarını ayarla
    double cardWidth = screenWidth * 0.7; // Ekran genişliğinin %80'i
    double cardHeight = screenHeight * 0.6; // Ekran yüksekliğinin %50'si
    // Yıldızlanma durumunu doğrudan starredStatus Map'inden al
    ValueNotifier<bool> isStarredNotifier = ValueNotifier<bool>(starredStatus[wordId] ?? false);
    var languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0), // Kenarlık yuvarlaklığı
      ),
      elevation: 5, // Gölge efekti
      child: ValueListenableBuilder<Color?>(
        valueListenable: borderColorNotifier,
        builder: (context, borderColor, child) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor ?? Colors.white, // Animasyonun değerini kullan
                width: 10,
              ),
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: cardHeight, // Dinamik yükseklik
                  width: cardWidth,   // Dinamik genişlik
                  child: FlipCard(
                    flipOnTouch: true,
                    key: cardKey,
                    front: Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) =>
                          CardImage(
                              backgroundColor: colors["borderColor"]!,
                              text: languageProvider.isEnglish ? englishWord : turkishWord,
                              imageUrl: fullImageUrl,
                              isVisibleNotifier: isVisibilityOn,
                              isImageShow: false
                          ),

                    ),
                    back: Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) =>
                          Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              CardImage(
                                  backgroundColor: colors["borderColor"]!,
                                  text: languageProvider.isEnglish ? turkishWord : englishWord,
                                  imageUrl: fullImageUrl,
                                  isVisibleNotifier: isVisibilityOn,
                                  isImageShow: true
                              ),
                              Positioned(
                                bottom: 10,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    type ?? 'Bilinmiyor', // Eğer type null ise 'Bilinmiyor' yazacak
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  _swipeCallback(bool isLeftSwipe) {
    // Sol kaydırma işlemi

  }
  void _handleSwipe(bool isLeftSwipe) {
    onCardSwiped(); // Puanı güncellemek için callback fonksiyonunu çağırın
    Color endColor = isLeftSwipe ? Colors.yellow : Colors.green;

    _borderColorAnimation = ColorTween(
      begin: borderColorNotifier.value,
      end: endColor,
    ).animate(_animationController)
      ..addListener(() {
        borderColorNotifier.value = _borderColorAnimation.value ?? Colors.white;
      });
    _animationController
      ..reset()
      ..forward().then((_) {
        // Animasyon tamamlandığında rengi beyaza döndür
        borderColorNotifier.value = Colors.white;
      });
    currentWordIndex.value++; // İndeksi artır
    _speak(); // Ses oynatma işlemini başlat
    _resetCardsToFront();
  }

  void _resetBorderColor() {
    borderColorNotifier.value = Colors.white; // Rengi doğrudan beyaza döndür
  }
  void _updateStarredWordCount() {
    int newCount = starredStatus.values.where((isStarred) => isStarred).length;
    starredWordCount.value = newCount;
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
  List<Card> _buildCardDeck() {
    List<WordDetail> wordsToShow;

    if (_showStarredOnly) {
      // Yalnızca yıldızlanmış kelimeleri göster
      wordsToShow = widget.words.where((word) => starredStatus[word.id] ?? false).toList();
    } else {
      // Tüm kelimeleri göster
      wordsToShow = widget.words;
    }

    return wordsToShow.map((word) {
      return _buildCard(word.type,word.word, word.meaning, word.image, word.id, word, cardKeys[word.id]!);
    }).toList();
  }

}
