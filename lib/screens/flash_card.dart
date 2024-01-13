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
// UserProvider importu

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
    double fontSize = (text.length > 100) ? 24 : 32;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return ValueListenableBuilder<bool>(
      valueListenable: isVisibleNotifier,
      builder: (context, isVisible, child) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // isImageShow değerine bağlı olarak görüntü gösterimi
            if (isImageShow)
              AnimatedOpacity(
                opacity: isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: SizedBox(
                  width: double.infinity,
                  height: screenWidth*.7,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            // Metin her zaman gösterilecek
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: Colors.white.withOpacity(0.7),
                width: MediaQuery.of(context).size.width * 0.8,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
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
  Map<int, bool> starredStatus = {};
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
// Bu satırı ekleyin

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

    setState(() {
      _showStarredOnly = !_showStarredOnly;

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

    if (!isSpeaking && volumeProvider.isVolumeOn && currentWordIndex.value < widget.words.length) {
      isSpeaking = true;
      String wordToSpeak = widget.words[currentWordIndex.value].word;
      await flutterTts.setLanguage("en-US");
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.speak(wordToSpeak);
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
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    userID = userProvider.userId;

    // Card listesi oluşturma
    List<Card> cardDeck = widget.words.map((word) {
      // Ensure the correct number of arguments is passed to _buildCard
      return _buildCard(word.word, word.meaning, word.image, word.id, word, cardKeys[word.id]!);
    }).toList();
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          // İhtiyaca göre eklemeler yapabilirsiniz
        ],
        centerTitle: true,
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
                              _speak(); // Ses oynatma işlemini başlat
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
                        color: Colors.blueAccent,
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
                        child: GestureDetector(
                          onTap: () {
                            print("Tapped!");
                            setState(() {
                              if (starredWordCount.value > 0) {
                                _toggleStarredView();
                                currentWordIndex.value = 0; // Reset the index
                              } else {
                                // Show a more visually appealing modal (dialog) when there are no starred words
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
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.04,
                                            ),
                                          ),
                                          SizedBox(height: 8), // Add some spacing
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
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog
                                          },
                                          child: Text("OK"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: screenWidth * 0.05,
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable: starredWordCount,
                                builder: (context, count, child) {
                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 500),
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    child: Text(
                                      '$count',
                                      key: ValueKey<int>(count),
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 8, // Flash kartların boyutunu ayarlar
              child: SwipingCardDeck(
                cardDeck: _buildCardDeck(),
                onDeckEmpty: () {
                  // Deck boş olduğunda yapılacak işlemler
                },
                onLeftSwipe: (Card card) {
                  currentWordIndex.value++; // İndeksi artır
                  _speak(); // Ses oynatma işlemini başlat
                  _resetCardsToFront();
                },
                onRightSwipe: (Card card) {
                  currentWordIndex.value++; // İndeksi artır
                  _speak(); // Ses oynatma işlemini başlat
                  _resetCardsToFront();
                },

                swipeThreshold: MediaQuery.of(context).size.width / 4,
                minimumVelocity: 1000,
                cardWidth: MediaQuery.of(context).size.width * 0.85, // Kart genişliğini ekran genişliğine göre ayarla
              ),
            ),
            // Yıldız sayısı ve Menü
          ],
        ),
      ),
    );

  }
  void _resetCardsToFront() {
    cardKeys.forEach((key, cardKey) {
      // Add null safety checks
      if (cardKey.currentState?.isFront == false) {
        cardKey.currentState?.toggleCard();
      }
    });
  }

  Card _buildCard(String englishWord, String turkishWord, String? imageUrl, int wordId, WordDetail word, GlobalKey<FlipCardState> cardKey) {
    String fullImageUrl = imageUrl != null
        ? "https://cloud.argethink.com/uploads/kelibu.net/$imageUrl"
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
                          CardImage(
                              text: languageProvider.isEnglish ? turkishWord : englishWord,
                              imageUrl: fullImageUrl,
                              isVisibleNotifier: isVisibilityOn,
                              isImageShow: true
                          ),
                    ),
                  ),
                ),
                _buildStarIcon(word, isStarredNotifier),
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
  }

  void _resetBorderColor() {
    borderColorNotifier.value = Colors.white; // Rengi doğrudan beyaza döndür
  }
  void _updateStarredWordCount() {
    int newCount = starredStatus.values.where((isStarred) => isStarred).length;
    starredWordCount.value = newCount; // Bu satırı ekledim
    animatedStarredCount.value = newCount; // Bu satırı ekledim
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
      return _buildCard(word.word, word.meaning, word.image, word.id, word, cardKeys[word.id]!);
    }).toList();
  }

}
