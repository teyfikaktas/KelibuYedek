import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:kelibu/api.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'package:kelibu/providers/volume_provider.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

import '../shared_preferences/shared_preferences.dart';

class WordData {
  final int id;
  final String meaning;
  final String imageUrl;

  WordData({required this.id, required this.meaning, this.imageUrl = ''});
}


class KelimeOyunu extends StatefulWidget {
  final int classroomId;
  final int studySetId;

  final List<WordDetail> words; // Words listesi için yeni parametre
  bool isStarredMode = false; // Yıldız modunun aktif olup olmadığını kontrol etmek için
  List<WordDetail> starredWords = []; // Yıldızlı kelimelerin listesi

  KelimeOyunu({Key? key, required this.classroomId, required this.studySetId, required this.words}) : super(key: key);

  @override
  _KelimeOyunuState createState() => _KelimeOyunuState();
}

class _KelimeOyunuState extends State<KelimeOyunu> with TickerProviderStateMixin, WidgetsBindingObserver {
  late ConfettiController _confettiController;
  double kalanZamanSaniye = 15; // Yeni eklenen değişken, toplam kalan zamanı saklar.
  int totalWordsCount = 0; // Oyun başladığında ve yıldız moduna geçildiğinde toplam kelime sayısını tutacak

  int puan = 0; // Puan göstergesi için
  late Timer zamanlayici; // Zaman çubuğu için zamanlayıcı
  double zamanCubuguDegeri = 1.0; // Zaman çubuğu değeri (1.0 tam dolu, 0.0 boş)
  late AnimationController scoreAnimationController;
  late Animation<Offset> scoreSlideAnimation;
  OverlayEntry? scoreOverlayEntry;
  Map<String, String> kelimeler = {
  };
  late Color correctOptionColor; // Doğru seçenek rengi
  late Color wrongOptionColor; // Yanlış seçenek rengi
  late Color centerCardColor; // Merkez kartı için yeni renk değişkeni
  FlutterTts flutterTts = FlutterTts(); // FlutterTts nesnesi.

  late Color defaultOptionColor; // Varsayılan seçenek rengi
  late Map<int, Color> optionColors; // Her seçenek için renk haritası
  Color rastgeleAcikRenkUret() {
    final rand = Random();
    // Daha açık renkler için daha yüksek RGB değerleri
    final r = 200 + rand.nextInt(56); // 200-255 arası
    final g = 200 + rand.nextInt(56); // 200-255 arası
    final b = 200 + rand.nextInt(56); // 200-255 arası
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
  // Animation for displaying learned words
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
  Future<void> fetchStarredWords() async {
    final service = StarredWordsService();

    List<int> wordIds = widget.words.map((e) => e.id).toList();
    try {
      // Yerel depolamadan yıldızlı kelimelerin listesini çek
      Set<int> starredWordsSet = await service.loadStarredWords(widget.classroomId, widget.studySetId);
      List<WordDetail> tempStarredWords = [];

      // Yıldızlı kelimeleri filtrele
      wordIds.forEach((id) {
        if (starredWordsSet.contains(id)) {
          // Yıldızlı olan kelimeyi bul
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

    flutterTts.setLanguage("en-US"); // Dil ayarı, ihtiyacınıza göre değiştirin.
    flutterTts.setSpeechRate(0.5); // Konuşma hızı, ihtiyacınıza göre ayarlayın.
    // Öncelikle AnimationController'ları initialize edin
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
      duration: Duration(milliseconds: 1500), // Süreyi ihtiyacınıza göre ayarlayın
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

    // Kullanıcı verilerini almak ve diğer başlangıç ayarları
    UserProvider userProviderPoint = Provider.of<UserProvider>(context, listen: false);
    print(userProviderPoint.point);
    score = userProviderPoint.point; // Eğer çevirme başarısız olursa varsayılan olarak 0 değerini kullan

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
    int scoreChange = int.parse(scoreText); // Puan değişimini al
    Color animationColor = scoreChange >= 0 ? Colors.green : Colors.red; // Puan artışı veya azalışına göre renk belirle
    scoreOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2,
        left: MediaQuery.of(context).size.width / 2,
        child: Material(
          color: Colors.transparent, // Şeffaf arkaplan
          child: SlideTransition(
            position: scoreSlideAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.transparent, // Puan değişimine göre renk belirle
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                scoreText,
                style: TextStyle(fontSize: 24.0, color: animationColor, fontWeight: FontWeight.bold), // Yeşil yazı rengi
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
      scoreTextOverlayEntry!.remove(); // Eğer bir önceki overlay varsa kaldır
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
      kalanZamanSaniye = 15; // Yeni soruda zamanı sıfırla
    }
    zamanCubuguDegeri = kalanZamanSaniye / 15; // Görsel zaman çubuğunu güncelle
    zamanlayici = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (kalanZamanSaniye > 0) {
          kalanZamanSaniye -= 1;
          zamanCubuguDegeri = kalanZamanSaniye / 15;
        } else {
          zamanCubuguDegeri = 0; // Değeri 0'ın altına düşürme
          timer.cancel(); // Zaman dolduğunda zamanlayıcıyı durdur
          _isOptionSelectable = false; // Tıklama işlevselliğini devre dışı bırak
          // Doğru cevabı işaretle
          int correctIndex = secenekler.indexOf(kelimeler[aktifKelime]!);
          setState(() {
            optionColors[correctIndex] = correctOptionColor;
          });
          // 1 saniye sonra bir sonraki soruya geç
          Future.delayed(Duration(seconds: 1), () {
            _isOptionSelectable = true; // Tıklama işlevselliğini tekrar etkinleştir
            secenekleriYenile();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    zamanlayici.cancel(); // Zamanlayıcıyı temizle
    _animationController.dispose();
    _learnedWordsAnimationController.dispose();
    zamanlayici.cancel(); // Zamanlayıcıyı temizle
    scoreAnimationController.dispose();
    scoreTextAnimationController.dispose(); // Yeni eklenen controller'ı dispose edin

    _confettiController.dispose();

    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // Uygulama arka plana geçtiğinde zamanlayıcıyı durdurun ve kalan süreyi kaydedin
      zamanlayici.cancel();
      // Kalan süreyi sakla
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar ön plana geldiğinde zamanlayıcıyı kaldığı yerden başlatın
      zamanlayiciyiBaslat(kalanZamandanDevamEt: true); // Kalan zaman parametresi ile zamanlayıcıyı başlat
    }
  }
  void resetGame() {
    // Oyunun başlangıç durumuna geri döndürülmesi gereken tüm değişkenleri sıfırla
    setState(() {

      tamamlananKelimeler.clear();
      kalanZamanSaniye = 15; // Kalan zamanı sıfırla
      zamanCubuguDegeri = 1.0; // Zaman çubuğu değerini sıfırla
      tamamlananKelimeler.clear(); // Tamamlanan kelimeler listesini temizle
      kelimeDogruSayac.clear(); // Her kelimenin doğru sayacını temizle
      _isOptionSelectable = true; // Seçeneklerin seçilebilirliğini tekrar etkinleştir
      // Yıldızlı kelimeler modu aktif ise yıldızlı kelimeleri tekrar yükle

      // Oyunu yeniden başlatmak için gerekli diğer işlemler
      secenekleriYenile(); // Seçenekleri ve aktif kelimeyi yenile
      // Zamanlayıcıyı başlat
      if (zamanlayici.isActive) {
        zamanlayici.cancel(); // Eğer zamanlayıcı aktifse, önce iptal et
      }
      zamanlayiciyiBaslat(); // Zamanlayıcıyı yeniden başlat
    });

    // Konuşma motorunu sıfırla (opsiyonel)
    flutterTts.stop();
  }

  void showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dışarıya dokunarak dialogu kapatamaz
      builder: (BuildContext dialogContext) { // Dialog için yeni bir context oluşturuldu.
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), // Daha yuvarlak köşeler
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
                    Navigator.of(dialogContext).pop(); // İlk olarak dialog'u kapat.
                    Navigator.of(context).popUntil((route) => route.isFirst); // Navigasyon stack'indeki ilk sayfaya dön
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

    Navigator.of(context).pop(); // Varsayılan olarak bir önceki sayfaya dön
  }
  bool isStarredMode = false; // Yıldız modunun aktif olup olmadığını kontrol etmek için
  List<WordDetail> starredWords = []; // Yıldızlı kelimelerin listesi
  void checkCompletionAndShowDialog() {
    // Oyun moduna göre kontrol etmek için kalan kelimelerin sayısını hesaplayın
    int remainingWords = isStarredMode ? starredWords.length : widget.words.length;

    // Eğer tamamlanan kelime sayısı kalan kelime sayısına eşitse veya fazlaysa, oyun tamamlanmıştır
    if (tamamlananKelimeler.length > totalWordsCount) {
      showCompletionDialog(); // Bitiş ekranını göster
    }
  }


  void secenekleriYenile() {
    setState(() {
      print(tamamlananKelimeler.length);
      // Yıldız moduna göre kelimeleri seç
      List<WordDetail> currentWords = isStarredMode ? starredWords : widget.words;

      List<WordDetail> filteredWords = currentWords.where((word) => !tamamlananKelimeler.contains(word.word)).toList();

      // Yıldızlı kelimeler veya tüm kelimelerden rastgele bir kelime seç
      if (filteredWords.isNotEmpty) {
        aktifKelime = filteredWords[Random().nextInt(filteredWords.length)].word;

        // Seçenekleri oluştur
        List<String> tumSecenekler = filteredWords.map((e) => e.meaning).toList()..shuffle();
        int listSize = tumSecenekler.length;
        secenekler = tumSecenekler.sublist(0, min(8, listSize));
        if (!secenekler.contains(kelimeler[aktifKelime])) {
          secenekler[Random().nextInt(secenekler.length)] = kelimeler[aktifKelime]!;
        }
        secenekler.shuffle();

        // Renkleri ve diğer değişkenleri sıfırla
        optionColors.clear();
        for (int i = 0; i < secenekler.length+1; i++) {
          optionColors[i] = defaultOptionColor;
        }

        // Zamanlayıcıyı sıfırla ve yeniden başlat
        if (zamanlayici.isActive) {
          zamanlayici.cancel(); // Mevcut zamanlayıcıyı iptal et
        }
        zamanlayiciyiBaslat(); // Zamanlayıcıyı yeniden başlat

        // Aktif kelimenin söylenmesi
        flutterTts.speak(aktifKelime);
      } else {
        _showCompletionMessage(); // Kullanıcıya tebrik mesajı göster

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isStarredMode ? 'Yıldızlı kelime kalmadı!' : 'Tüm kelimeler soruldu!'),
        ));
      }
    });
  }
  void _showCompletionMessage() {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dialog dışına tıklayarak kapatamaz
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Tebrikler!"),
          content: Text("Tüm kelimeleri başarıyla tamamladınız."),
          actions: <Widget>[
            TextButton(
              child: Text("Tekrar Oyna"),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                _restartGame(); // Oyunu yeniden başlat
              },
            ),
            TextButton(
              child: Text("Bir Önceki Sayfaya Dön"),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                Navigator.of(context).pop(); // Bir önceki sayfaya dön
              },
            ),
          ],
        );
      },
    );
  }


  void _restartGame() {
    setState(() {
      // Temel değişkenlerin sıfırlanması
      puan = 0;
      kalanZamanSaniye = 15;
      zamanCubuguDegeri = 1.0;
      aktifKelime = '';
      secenekler.clear();
      kelimeDogruSayac.clear();
      tamamlananKelimeler.clear();
      optionColors.clear();
      _isOptionSelectable = true;

      // Yıldızlı kelimeler listesini ve modunu sıfırla
      isStarredMode = false; // Varsayılan olarak yıldız modunu pasif yap
      starredWords.clear(); // Yıldızlı kelimeler listesini temizle

      // Oyunu yeniden başlatmak için gereken diğer değişkenler burada sıfırlanabilir.

      // Zamanlayıcıyı yeniden başlat
      if (zamanlayici.isActive) {
        zamanlayici.cancel(); // Eğer zamanlayıcı aktifse, iptal et
      }
      zamanlayiciyiBaslat(); // Zamanlayıcıyı yeniden başlat

      // Seçenekleri ve aktif kelimeyi yenile
      secenekleriYenile();

      // Oyunun görsel ve işlevsel durumunu sıfırla
      // Eğer kullanıyorsanız, ConfettiController veya benzeri animasyonları da resetleyebilirsiniz
    });
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(

          title: Text('Klasik Kelibu'),

        ),
        body: Column(
          children: [
            // AppBar içerisinde, diğer widget'larınızın yanına ekleyin
// AppBar içerisinde, diğer widget'larınızın yanına ekleyin
            IconButton(
              icon: Icon(isStarredMode ? Icons.star : Icons.star_border),
              onPressed: () async {
                if (!isStarredMode) {
                  // Yıldız modu aktif değilse, yıldızlı kelimeleri çek
                  await fetchStarredWords();
                }
                setState(() {
                  isStarredMode = !isStarredMode;
                  // Yıldız moduna geçişte ve çıkışta toplam kelime sayısını güncelle
                  totalWordsCount = isStarredMode ? starredWords.length : widget.words.length;
                  if (isStarredMode && starredWords.isEmpty) {
                    // Eğer yıldız moduna geçildiğinde yıldızlı kelime yoksa, kullanıcıyı bilgilendir
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('En az 1 yıldızlı kelimeniz olması gerekmektedir.'),
                      ),
                    );
                    // Yıldızlı moddan çık
                    isStarredMode = false;
                  } else {
                    // Yıldızlı mod aktifse ve yıldızlı kelimeler varsa, oyunu yıldızlı kelimelerle yenile
                    secenekleriYenile();
                  }
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
      // AppBar içindeki FloatingActionButton widget'ını güncelleyin
                  FloatingActionButton(
                    onPressed: () {
                      // VolumeProvider'a erişim ve mute durumunu değiştirme
                      final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);
                      volumeProvider.toggleVolume();
                      // flutterTts setVolume işlevini kullanarak sesi aç/kapat
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
                    backgroundColor: Colors.teal,
                    elevation: 8.0,
                    hoverElevation: 10.0,
                    splashColor: Colors.greenAccent,
                    tooltip: 'Sesi Aç/Kapat',
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          child: Icon(Icons.star, size: 24, color: Colors.amber), // Puan simgesi olarak yıldız ikonu
                        ),
                        TextSpan(
                          text: ' Puan: $score',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                            letterSpacing: 1.2, // Harfler arası boşluk
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircularPercentIndicator(
                    radius: 30.0, // Daha küçük bir yarıçap
                    lineWidth: 4.0, // Daha ince bir çizgi genişliği
                    animation: true, // Yüzde değişikliğinde animasyon etkisi
                    percent: zamanCubuguDegeri, // Zamanlayıcı değeri (0.0 ile 1.0 arasında)
                    center: Text(
                      "${(15 * zamanCubuguDegeri).round()}s",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal[800]), // Daha küçük ve kalın font
                    ),
                    circularStrokeCap: CircularStrokeCap.round, // Daha yumuşak uçlar
                    progressColor: Colors.teal, // İlerleme rengi olarak tema rengini kullan
                    backgroundColor: Colors.teal.shade100, // Arka plan rengi
                    footer: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Kalan Süre', // Zamanlayıcının altında açıklama
                        style: TextStyle(fontSize: 10, color: Colors.teal[800]),
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
                itemCount: max(secenekler.length + 2, 10), // Ortadaki kart için +1 ekleyin ve en az 9 olacak şekilde ayarlayın
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemBuilder: (BuildContext context, int index) {
                  // Orta kartı kontrol et
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
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '${kelimeDogruSayac[aktifKelime] ?? 0}/3',
                                  style: TextStyle(color: Colors.teal.shade800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Orta kartın index'ini dikkate alarak seçenekler listesinin index'ini ayarla
                    int optionIndex = index < 4 ? index : index - 1;

                    // Eğer seçenekler listesi bu index için bir değer içermiyorsa boş bir Container döndür
                    if (optionIndex >= secenekler.length) {
                      return Container();
                    }

                    // Seçenek kartları için mantık
                    String secenek = secenekler[optionIndex];
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      color: optionColors[optionIndex], // Burada optionIndex kullanılmalı
                      child: InkWell(
                        onTap: () => handleOptionTap(secenek, optionIndex), // Burada optionIndex doğru şekilde kullanılıyor
                        child: Center(
                          child: Text(
                            secenek,
                            style: TextStyle(fontSize: 18, color: Colors.teal.shade800),
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
          color: Colors.teal,
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
    ));
  }

  void showModal(BuildContext context) {
    showPlatformDialog(
      context: context,
      builder: (BuildContext dialogContext) => BasicDialogAlert(
        title: Text("Ayarlar"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // İkonları yan yana yerleştirmek için Row widget'ı kullanılıyor.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Ses Kapatma İkonu
                IconButton(
                  icon: Icon(Icons.volume_off),
                  onPressed: () {
                    // Ses kapatma işlevi
                    Navigator.pop(dialogContext); // Diyalogu kapat
                  },
                ),
                // Türkçe/İngilizce Çeviri İkonu
                IconButton(
                  icon: Icon(Icons.translate),
                  onPressed: () {
                    // Dil değiştirme işlevi
                    Navigator.pop(dialogContext); // Diyalogu kapat
                  },
                ),
                // Resim Gösterme İkonu
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: () {
                    // Resim gösterme işlevi
                    Navigator.pop(dialogContext); // Diyalogu kapat
                  },
                ),
                // Yıldız İkonu
                IconButton(
                  icon: Icon(Icons.star),
                  onPressed: () {
                    // Favorilere ekleme işlevi
                    Navigator.pop(dialogContext); // Diyalogu kapat
                  },
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text("Kapat"),
            onPressed: () {
              Navigator.pop(dialogContext); // Diyalogu kapat
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
          padding: EdgeInsets.all(8),
          height: MediaQuery.of(context).size.height * 0.5,
          child: ListView(
            children: tamamlananKelimeler.map((kelime) => ListTile(
              title: Text(kelime),
              trailing: Icon(Icons.check, color: Colors.green),
            )).toList(),
          ),
        );
      },
    );
  }

  bool _isOptionSelectable = true; // Seçeneklerin seçilebilirliğini kontrol etmek için

  void handleOptionTap(String secenek, int index) {
    if (!_isOptionSelectable) return;

    final bool isCorrect = secenek == kelimeler[aktifKelime];
    // Doğru cevabın index'i, secenekler listesindeki konumu
    int correctIndex = secenekler.indexOf(kelimeler[aktifKelime]!);

    // GridView'da ortadaki kelimenin dikkate alınması gerekiyor, bu yüzden tıklanan seçeneğin gerçek indeksi ayarlanmalı
    // Orta kart (indeksi her zaman 4 olan) sonrası seçenekler için indeks düzeltmesi
    int optionIndex = index;

    // Doğru cevabın da GridView içerisindeki yerini düzeltmek için benzer bir düzeltme yapılmalı
    // Bu durum, doğru cevap ortadaki karttan sonra bir seçenekse önem kazanır

    int remainingSeconds = (15 * zamanCubuguDegeri).round();
    int pointChange = isCorrect ? remainingSeconds : -remainingSeconds;

    setState(() {
      _isOptionSelectable = false;
      if (isCorrect) {
        kelimeDogruSayac[aktifKelime] = (kelimeDogruSayac[aktifKelime] ?? 0) + 1;
        score += pointChange;
        optionColors[optionIndex] = correctOptionColor; // Doğru seçeneği işaretle
        score += pointChange;
        if (kelimeDogruSayac[aktifKelime]! >= 3) {
          tamamlananKelimeler.add(aktifKelime);
          if (isStarredMode) {
            starredWords.removeWhere((word) => word.word == aktifKelime);
          }
          _confettiController.play();
          showScoreTextAnimation(aktifKelime);
          score += 30; // Ekstra puan
        }
      }
       else {
        kelimeDogruSayac[aktifKelime] = 0;
        score += pointChange;
        optionColors[optionIndex] = wrongOptionColor; // Yanlış seçeneği işaretle
        optionColors[correctIndex] = correctOptionColor; // Doğru seçeneği işaretle

      }

      // Puan güncellemesi ve animasyonlar
      showScoreAnimation('${pointChange > 0 ? '+' : ''}$pointChange');
      _updateUserScore(score,pointChange);

      // Bir sonraki soruya geçiş
      Future.delayed(Duration(milliseconds: 1000), () {
        setState(() {
          _isOptionSelectable = true;
          secenekleriYenile();
        });
        checkCompletionAndShowDialog();
      });
    });
  }
  Future<void> _updateUserScore(int score,int pointChange) async {

    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      userID =userProvider.userId;
      print("userid"+userID.toString());
      await ApiService().updateUserPointTimePeriod(userID, score,pointChange);
      userProvider.addPoint(score);
      print("Puan güncellendi: $score");
    } catch (e) {
      print("Puan güncelleme hatası: $e");
    }
  }

  void showFeedback({required bool isCorrect}) {
    final snackBar = SnackBar(
      content: Text(isCorrect ? 'Doğru!' : 'Yanlış! Doğru cevap: ${kelimeler[aktifKelime]}'),
      backgroundColor: isCorrect ? Colors.green : Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
