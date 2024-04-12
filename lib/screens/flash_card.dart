import 'package:flutter/material.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

import '../shared_preferences/shared_preferences.dart';

// UserProvider importu

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
  bool _isMenuOpen = false; // Menü durumunu kontrol etmek için bir değişken

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
  }

  void toggleAnimation(bool isMenuOpen) {
    setState(() {
      _isMenuOpen = isMenuOpen;
      if (_isMenuOpen) {
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
            height: screenHeight*0.02, // Yükseklik
            decoration: BoxDecoration(
              color: const Color(0xFFFFD1DC), // Açık pembe arka plan rengi
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
                  gradient: const LinearGradient(
                    colors: [Colors.pink, Colors.purple], // İki renkli gradient
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
                    style: const TextStyle(color: Colors.white),
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

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  CustomAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ses ve dil için provider'lar
    final volumeProvider = Provider.of<VolumeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return AppBar(
      backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın

      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Spacer(), // Boşluk bırakır
          IconButton(
            icon: Icon(Icons.shuffle),
            onPressed: () {
              // Karıştırma işlemi
            },
          ),
          Text("0"), // Yıldızlı kelime sayısı, dinamik olmalı
          IconButton(
            icon: Icon(volumeProvider.isVolumeOn ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              volumeProvider.toggleVolume();
            },
          ),
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              languageProvider.toggleLanguage();
            },
          ),
          Spacer(), // Boşluk bırakır
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
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
  const MyVolumeControl({super.key});

  @override
  MyVolumeControlState createState() => MyVolumeControlState();
}

class MyVolumeControlState extends State<MyVolumeControl> {
  @override
  Widget build(BuildContext context) {
    // VolumeProvider'dan bir örnek al
    final volumeProvider = Provider.of<VolumeProvider>(context);

    return IconButton(
      icon: Icon(
        // VolumeProvider üzerinden isVolumeOn özelliğine eriş
        volumeProvider.isVolumeOn ? Icons.volume_up : Icons.volume_off,
        color: Colors.pink,
      ),
      onPressed: () {
        volumeProvider.toggleVolume();
        showCustomFlushbar(
            context,
            volumeProvider.isVolumeOn ? "Ses açıldı" : "Ses kapandı"
        );
      },
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

class CardImage extends StatelessWidget {
  final String text;
  final String imageUrl;
  final ValueNotifier<bool> isVisibleNotifier;
  final bool isImageShow;

  const CardImage({
    Key? key,
    required this.text,
    required this.imageUrl,
    required this.isVisibleNotifier,
    required this.isImageShow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isVisibleNotifier,
      builder: (context, isVisible, child) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (isImageShow)
              AnimatedOpacity(
                opacity: isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width * 0.7,
                  child:             Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                      // Burada resim yüklenemediğinde gösterilecek alternatif bir resmi belirleyebilirsiniz.
                      return Image.asset('assets/logo.png',                   width: 100,
                        height: 100,);
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
        maxLines:5, // Maksimum satır sayısı
        overflow: TextOverflow.ellipsis, // Taşma durumunda nasıl davranılacağı
        ),
        ),

            ),
          ],
        );
      },
    );
  }
}
class FlashCardScreen extends StatefulWidget {


  final List<WordDetail> words;
  final int classroomId; // Yeni eklenen alan
  final int studySetId; // Yeni eklenen alan
  const FlashCardScreen({
    Key? key,
    required this.words,
    required this.classroomId, // Yeni parametre
    required this.studySetId, // Yeni parametre

  }) : super(key: key);

  @override
  _FlashCardScreenState createState() => _FlashCardScreenState();
}
int currentCardIndex = 0; // Mevcut kartın indeksini saklamak için bir değişken

//...



class _FlashCardScreenState extends State<FlashCardScreen> with SingleTickerProviderStateMixin {
  bool isStarred = false;
  ValueNotifier<int> currentWordIndex = ValueNotifier(0); // Mevcut kelime indeksi için ValueNotifier ekle
  int wordId = 0;
  bool isShuffled = false;
  int totalWords = 0; // Toplam kelime sayısı
  DateTime? lastSwipeTime;
  ValueNotifier<bool> isWordStarred = ValueNotifier(false);

  late UserProvider userProvider;
  ValueNotifier<int> pointValueNotife = ValueNotifier(0);
  ValueNotifier<bool> isAnimationCompletedNotifier = ValueNotifier(false);
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  ValueNotifier<int> starredWordCountNotifier = ValueNotifier(0);

  int score = 0; // Puanı takip etmek için yeni bir değişken
  Future<void> onCardSwiped() async {
    int newPoint = userProvider.point;

    newPoint += 3; // Örnek olarak 3 puan ekleyin
    pointValueNotife.value +=3;

    await ApiService().updateUserPoint(userProvider.userId, newPoint); // API üzerinden puanı güncelleyin
    userProvider.addPoint(newPoint); // UserProvider'daki puanı güncelleyin

  }
  bool canSwipe() {
    final now = DateTime.now();
    if (lastSwipeTime == null) {
      lastSwipeTime = now;
      print('First swipe allowed.');
      return true;
    }

    final difference = now.difference(lastSwipeTime!).inSeconds;
    print('Time since last swipe: $difference seconds');
    if (difference >= 1) {
      lastSwipeTime = now;
      return true;
    }
    print('Swipe too fast, ignoring.');
    return false;
  }
  Map<int, GlobalKey<FlipCardState>> cardKeys = {};
  ValueNotifier<int> starredWordCount = ValueNotifier(0);
  ValueNotifier<Color> borderColorNotifier = ValueNotifier(Colors.white);
  ValueNotifier<int> animatedStarredCount = ValueNotifier(0);
  final service = StarredWordsService();

  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  String currentWord = ""; // Şu anki kelimeyi takip etmek için değişkens
  ValueNotifier<bool> isVisibilityOn = ValueNotifier(true);
  bool isShuffleOn = true;
  bool isLanguageOn = true;
  bool isVolumeOn = true;
  int userID= 2;
  late int point;

  Map<int, bool> starredStatus = {};
  bool _isAnimationCompleted = false; // Animasyonun tamamlanıp tamamlanmadığını takip eden değişken
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
// Bu satırı ekleyin
  ValueNotifier<Color> backgroundColorNotifier = ValueNotifier(Colors.blue); // Varsayılan olarak mavi renk
  final FlutterTts flutterTts = FlutterTts();
  @override
  void initState() {
    super.initState();
    print('state girdi');
    _initializeStarredStatus();
    _loadStarredStatusAsync();

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
    currentWordIndex.value = 0; // Başlangıçta mevcut kelime indeksini 0 olarak ayarla

    _borderColorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.green,
    ).animate(_animationController)
      ..addListener(() {
        borderColorNotifier.value = _borderColorAnimation.value ?? Colors.white; // Null kontrolü eklendi
      });
    totalWords = widget.words.length; // Toplam kelime sayısını ayarla
    // Ensure the context is fully available by deferring the userProvider initialization.
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
  void _initializeStarredStatus() {
    for (var word in widget.words) {
      // Her kelime için, başlangıçta yıldızlı olmadığını varsayarak bir ValueNotifier<bool> ekleyin.
      starredNotifiers[word.id] = ValueNotifier(false);
    }
    // Bu noktada, yıldızlanan kelimelerin sayısını güncellemeyin,
    // çünkü bu veri henüz yüklenmemiş olabilir.
    // `_loadStarredStatusAsync` içinde güncelleyeceğiz.
  }
  void _toggleStarStatus(int wordId) {
    isWordStarred.value = !isWordStarred.value; // Yıldızlanma durumunu değiştirß
      isWordStarred.addListener(() {
        if (isWordStarred.value) {
          starredWordCountNotifier.value++; // Kelime yıldızlandı, sayacı artır
        } else {
          starredWordCountNotifier.value--; // Yıldız kaldırıldı, sayacı azalt
        }
      });


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
    starredWordCountNotifier.value = newCount; // Bu satırı ekledim

  }
  void _loadStarredStatusAsync() async {
    final service = StarredWordsService();
    final starredWordIds = await service.loadStarredWords(widget.classroomId, widget.studySetId);
    print('_loadStarredStatusAsync');
    setState(() {
      int newStarredCount = 0; // Yeni yıldızlanan kelime sayısını tutacak değişken
      for (var word in widget.words) {
        bool isStarred = starredWordIds.contains(word.id);
        starredNotifiers[word.id]?.value = isStarred;
        starredStatus[word.id] = isStarred;
        if (isStarred) {
          newStarredCount++; // Eğer kelime yıldızlanmışsa, sayacı artır
        }
      }
      starredWordCountNotifier.value = newStarredCount; // Toplam yıldızlanan kelime sayısını güncelle
    });
  }

  bool isSpeaking = false;
  bool _showStarredOnly = false;

  void _toggleStarredView() {
    print("Yıldız görünümü değiştiriliyor: $_showStarredOnly");
    showCustomFlushbar(
      context,
      _showStarredOnly ? "Yıldızlı kelimeler modu kapandı." : "Yıldızlı kelimeler modu açıldı.",
    );
    _loadStarredStatusAsync();
    currentWordIndex.value = 0;
    setState(() {
      _showStarredOnly = !_showStarredOnly;
      backgroundColorNotifier.value = _showStarredOnly ? Colors.green : Colors.blue;

      // Yıldızlı kelimelerin listesini filtreleyin
      List<WordDetail> wordsToShow;
      if (_showStarredOnly) {
        wordsToShow = widget.words.where((word) => starredStatus[word.id] ?? false).toList();
        totalWords = starredWordCountNotifier.value;
      } else {
        wordsToShow = widget.words;
        totalWords = wordsToShow.length; // Yeni toplam kelime sayısını ayarlayın

      }

      // İlerleme çubuğunu ve mevcut kelime sayısını sıfırlayın
      currentWordIndex.value = 0;
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
  void _toggleStar(int word, ValueNotifier<bool> isStarredNotifier) async {
    final service = StarredWordsService();
    final newStatus = !isStarredNotifier.value;

    await service.toggleWordStarStatus(word, !isStarredNotifier.value, widget.classroomId, widget.studySetId);

      isStarredNotifier.value = newStatus; // UI'ı güncelleyin
      starredStatus[wordId] = newStatus; // Bu eklemeyi unutmayın

      _updateStarredWordCount(isStarredNotifier);
  }
  Widget _buildStarIcon(int wordId, ValueNotifier<bool> isStarredNotifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: isStarredNotifier,
      builder: (context, isStarred, child) {
        return IconButton(
          icon: Icon(
            isStarred ? Icons.star : Icons.star_border, // Koşullu ifadeyi ValueNotifier'dan gelen değere göre güncelle
            color: isStarred ? Colors.yellow : Colors.grey, // Eğer kelime yıldızlanmışsa sarı, değilse gri ikon
          ),
          onPressed: () {
            _toggleStar(wordId, isStarredNotifier); // _toggleStar fonksiyonunu çağır
          },
        );
      },
    );
  }


  Future<void> _updateStarredWordsInPrefs(int wordId, bool isStarred) async {
    final prefs = await SharedPreferences.getInstance();
    List<int> starredWords = [];
    final starredWordsString = prefs.getString('starredWords');
    if (starredWordsString != null) {
      starredWords = starredWordsString.split(',').map((id) => int.parse(id)).toList();
    }

    if (isStarred) {
      // Kelimeyi listeye ekle
      if (!starredWords.contains(wordId)) {
        starredWords.add(wordId);
      }
    } else {
      // Kelimeyi listeden kaldır
      starredWords.remove(wordId);
    }

    // Listeyi tekrar kaydet
    await prefs.setString('starredWords', starredWords.join(','));
  }
  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın

      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Spacer(),
          Spacer(),
          Spacer(),

          Center(
            child: GestureDetector(
              onTap: () {
                print("Tapped!");
                setState(() {
                  if (starredWordCountNotifier.value > 0) {
                    _toggleStarredView();
                    currentWordIndex.value = 0; // Indexi sıfırla
                  } else {
                    // Yıldızlı kelime yoksa gösterilecek modal
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Information"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "You don't have any starred words yet.",
                                style: TextStyle(fontSize: screenWidth * 0.04),
                              ),
                              SizedBox(height: 8),
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
                              child: Text("OK"),
                            ),
                          ],
                        );
                      },
                    );
                  }
                });
              },
              child: ValueListenableBuilder<Color>(
                valueListenable: backgroundColorNotifier, // Arka plan rengini takip eden ValueNotifier
                builder: (context, color, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color, // Dinamik olarak değişen arka plan rengi
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: screenWidth * 0.05,
                        ),
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
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
                        // İlk IconButton (Görünürlük Düğmesi)
                        ValueListenableBuilder<bool>(
                          valueListenable: isVisibilityOn,
                          builder: (context, value, child) {
                            return IconButton(
                              icon: Icon(
                                value ? Icons.visibility : Icons.visibility_off,
                                color: Colors.pink,
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
                              color: Colors.pink,
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
                                  color: Colors.pink,
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
                          icon: const Icon(Icons.hearing, color: Colors.pink,),
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
                  isAnimationCompletedNotifier.value = true;

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
                _buildStarIcon(word.id, isStarredNotifier),
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


    onCardSwiped(); // Update the score as before

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
        // Reset the border color to white once the animation is complete
        borderColorNotifier.value = Colors.white;
      });
    currentWordIndex.value++; // Increment the index as before
    _speak(); // Play the speech as before
    _resetCardsToFront(); // Reset cards to front view as before
  }

  void _resetBorderColor() {
    borderColorNotifier.value = Colors.white; // Rengi doğrudan beyaza döndür
  }



  void showCustomFlushbar(BuildContext context, String message) {
    Flushbar(
      // Mesajı Google Fonts ile stilize et
      messageText: Text(
        message,
        style: GoogleFonts.lato(
          color: Colors.black, // Yazı rengi siyah
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
      // Çerçeve rengini pembe yap
      boxShadows: const [
        BoxShadow(
          color: Colors.pink, // Çerçeve rengi pembe
          offset: Offset(0, 3),
          blurRadius: 3,
        ),
      ],
      forwardAnimationCurve: Curves.easeInOutCubic,
      reverseAnimationCurve: Curves.easeInOutCubic,
    ).show(context);
  }  List<Card> _buildCardDeck() {
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
