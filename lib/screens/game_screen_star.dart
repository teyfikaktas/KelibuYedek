import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kelibu/Models/wordDetaik.dart'; // WordDetail modelinizin importu
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/flash_card.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/screens/classic_kelibu.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/providers/user_provider.dart'; // UserProvider importu
import 'package:kelibu/screens/flash_card_star.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/screens/quiz.dart';
import 'package:kelibu/screens/quizStar.dart';
import '../event.dart';
import '../event_bus.dart';
import '../shared_preferences/shared_preferences.dart';
import 'study_screen.dart'; // StudyScreen'i içe aktar
import 'listen_write.dart'; // StudyScreen'i içe aktar
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts paketini import edin.
import 'package:kelibu/globalDart/global.dart';
class CustomLoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitChasingDots( // Circle türündeki yükleme göstergesi
        color: Colors.blue, // Yükleme göstergesi rengi
        size: 50.0, // Yükleme göstergesi boyutu
      ),
    );
  }
}

class GameModeStarScreen extends StatefulWidget {
  final String studySetName;
  final int classroomId; // Yeni eklenen alan
  final int studySetId; // Yeni eklenen alan

  const GameModeStarScreen({
    Key? key,
    required this.studySetName,
    required this.classroomId, // Yeni parametre
    required this.studySetId, // Yeni parametre
  }) : super(key: key);
  @override
  _GameModeScreenState createState() => _GameModeScreenState();
}


class _GameModeScreenState extends State<GameModeStarScreen> {
  late Future<List<WordDetail>> wordsFuture;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  GlobalKey<AnimatedListState> animatedListKey = GlobalKey<AnimatedListState>();
  List<WordDetail> starredWordsList = [];
  late Map<int, bool> starredWords;
  Map<int, GlobalKey> _listTileKeys = {};
  List<WordDetail> wordDetails = [];
  Map<int, Color> _tileColors = {};
  Map<int, GlobalKey> _tileKeys = {};
  bool isLoading = true; // Yükleme durumunu takip etmek için

  ValueNotifier<int> starredCountNotifier = ValueNotifier<int>(0);
  bool areGamesClickable = true;
  List<int> wordIds = [];

  FlutterTts flutterTts = FlutterTts();
  final spinkit = SpinKitFadingCircle(
    itemBuilder: (BuildContext context, int index) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: index.isEven ? Colors.red : Colors.green,
        ),
      );
    },
  );

  Future<void> _loadWords() async {
    print('widget.studySetName');

    print(widget.studySetName);
    String processedString = widget.studySetName.replaceAll('[', '').replaceAll(']', '');
    List<String> stringIds = processedString.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
    wordIds = stringIds.map((id) => int.tryParse(id) ?? 0).toList();
    wordsFuture = ApiService().fetchWordsDetailStar(widget.classroomId, wordIds);

    // API çağrısı yapılıp, sonuçlar `wordDetails` listesine atandığını varsayalım
    wordDetails = await wordsFuture;

    // `starredWordsList`'i doldurun
    setState(() {
      starredWordsList = getRandomWordDetails(wordDetails); // Rastgele 100 veya daha az WordDetail seç
      starredCountNotifier.value = wordDetails.length; // Bu satır eklendi
    });
  }
// Rastgele 100 veya daha az sayıda WordDetail seçen fonksiyon
  List<WordDetail> getRandomWordDetails(List<WordDetail> wordDetails) {
    final random = Random();
    if (wordDetails.length <= 100) {
      return wordDetails;
    } else {
      return (wordDetails.toList()..shuffle(random)).take(100).toList();
    }
  }
  Future<void> _removeWord(int index) async {
    WordDetail removedWord = wordDetails.removeAt(index);
    _listKey.currentState!.removeItem(
      index,
          (context, animation) => _buildItem(removedWord, animation, index),
      duration: const Duration(milliseconds: 600),
    );
    setState(() {
      _loadWords();
    });
  }

  Future<void> removeWord(int index) async {
    if (index < starredWordsList.length) {
      WordDetail word = starredWordsList[index];

      // API'den kelimeyi silme işlemini gerçekleştirin
      await StarredWordsService().removeWordFromAll(word.id);

      // UI'dan kelimeyi animasyonlu bir şekilde kaldır
      animatedListKey.currentState?.removeItem(
        index,
            (context, animation) => buildWordTile(context, index, animation),
        duration: Duration(milliseconds: 500),
      );

      // Listenizden kelimeyi kaldırın
      setState(() {
        starredWordsList = List<WordDetail>.from(starredWordsList); // Bu satırı güncelledim
        starredWordsList.removeAt(index);
        starredCountNotifier.value = starredWordsList.length; // Güncelleme
      });
    }
  }

  Widget buildWordTile(BuildContext context, int index, Animation<double> animation) {
    WordDetail word = starredWordsList[index];
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        leading: Icon(Icons.star, color: Colors.amber),
        title: Text(word.word),
        subtitle: Text(word.meaning),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => removeWord(index),
        ),
        onTap: () => _navigateToWordDetail(word),
      ),
    );
  }

  Widget _buildItem(WordDetail word, Animation<double> animation, int index) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        child: ListTile(
          title: Text(word.word),
          trailing: IconButton(
            icon: Icon(Icons.remove_circle_outline),
            onPressed: () => _removeWord(index),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    starredWords = {};
    _loadWords();
    appEventBus.on<StarredWordsChangedEvent>().listen((event) async {
      setState(() {
        // Yıldızlı kelime sayısını event ile güncelle
        starredCountNotifier.value = event.newCount;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;
    var screenSize = MediaQuery.of(context).size;
    int gridCount = screenSize.width > 600 ? 4 : 2;  // Tablet için 4, telefon için 2 sütun
    double aspectRatio = screenSize.width > 600 ? 1.5 : 2;  // Tablet için daha geniş tile'lar
    bool isTablet = screenSize.width > 600;
    bool yatayEkran = MediaQuery.of(context).size.aspectRatio > 1.5;

    int childAspectRatio = isTablet ? 4 : 2;
    double crossAxisCount = yatayEkran ? 4 : 2;
    if (wordDetails == null) {
      // wordsFuture henüz başlatılmamışsa, yükleme göstergesini göster
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Oyun Modları',
            style: GoogleFonts.poppins(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(
            color: Colors.pink,
          ),
        ),
        body: CustomLoadingIndicator(), // Yükleme göstergesi
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Oyun Modları',
          style: GoogleFonts.poppins(
            color: Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.pink,
        ),
      ),
      body: FutureBuilder<List<WordDetail>>(
        future: wordsFuture,
        builder: (context, snapshot) {
          // Kelime listesi kontrolü
          if (snapshot.hasData! && snapshot.data!.isEmpty) {
            // Kelime listesi boşsa, oyun modlarını tıklanamaz yap
            areGamesClickable = false;
          } else {
            // Kelime listesi doluysa, oyun modlarını tıklanabilir yap
            areGamesClickable = true;
          }
          return Column(
            children: [
              InkWell(
                onTap: () {
                  if (areGamesClickable) {
                    print('object');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FutureBuilder<List<WordDetail>>(
                          future: wordsFuture, // Burada Future<List<WordDetail>> türünde bir Future bekleniyor
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              // Veriler yükleniyor ise yükleme göstergesini göster
                              return CustomLoadingIndicator();
                            } else if (snapshot.hasError) {
                              // Eğer bir hata varsa, hata mesajı göster
                              return Text('Hata: ${snapshot.error}');
                            } else if (snapshot.hasData) {
                              // Eğer veriler başarıyla gelmişse
                              if (snapshot.data!.isEmpty) {
                                // Veri yoksa kullanıcıya bilgi ver
                                return Center(child: Text("Yıldızlı kelime bulunamadı, oyun başlatılamıyor!"));
                              } else {
                                return Material(
                                  color: Colors.transparent, // Material widget'ının arka planını transparan yaparak altındaki renkleri etkilemez
                                  child:InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => FutureBuilder<List<WordDetail>>(
                                            future: wordsFuture, // Burada Future<List<WordDetail>> türünde bir Future bekleniyor
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                // Eğer snapshot içinde veri varsa, bu verileri QuizScreen'e gönder
                                                return KelimeOyunu(
                                                  words: snapshot.data!, // wordsFuture'den gelen veriler
                                                  classroomId: widget.classroomId, // Aktarılacak classroomId
                                                  studySetId: widget.studySetId, // Aktarılacak studySetId
                                                );
                                              } else {
                                                // Eğer veri yoksa, yükleme göstergesini göster
                                                return CustomLoadingIndicator();
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16.0),
                                      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple[400],
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.deepPurple.shade900.withOpacity(0.5),
                                            spreadRadius: 2,
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade600],
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.gamepad, color: Colors.white, size: 30),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              "Klasik Kelibu",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 24,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 6.0,
                                                    color: Colors.black.withOpacity(0.5),
                                                    offset: Offset(2, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            } else {
                              // Eğer veri yoksa, boş bir widget döndür
                              return SizedBox();
                            }
                          },
                        ),
                      ),
                    );
                  } else {
                    // Tıklanabilir değilse, kullanıcıya uyarı göster
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Yıldızlı kelime bulunamadı!"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: buildKlasikKelibuTile(context),
              ),
              Expanded(
                flex: 1,
                child: GridView.count(
                  crossAxisCount: childAspectRatio,
                  childAspectRatio: crossAxisCount,
                  children: <Widget>[
                    _buildGameModeTile(context, "Öğren", areGamesClickable ? Colors.blue : Colors.grey, Icons.school, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FutureBuilder<List<WordDetail>>(
                            future: wordsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return QuizStarScreen(
                                  words: snapshot.data!,
                                  classroomId: widget.classroomId, // classroomId değerini burada aktar
                                  studySetId: widget.studySetId, // studySetId değerini burada aktar
                                );
                              } else {
                                return CustomLoadingIndicator();
                              }
                            },
                          ),
                        ),
                      );
                    }),

                    _buildGameModeTile(context, "Flash Kart", areGamesClickable ? Colors.green : Colors.grey, Icons.flash_on, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FutureBuilder<List<WordDetail>>(
                            future: wordsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return FlashCardStarScreen(
                                  words: snapshot.data!,
                                  classroomId: widget.classroomId, // classroomId değerini burada aktar
                                  studySetId: widget.studySetId, // studySetId değerini burada aktar
                                );
                              } else {
                                return CustomLoadingIndicator();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                    _buildGameModeTile(context, "Çalış", areGamesClickable ? Colors.greenAccent : Colors.grey, Icons.work, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FutureBuilder<List<WordDetail>>(
                            future: wordsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return StudyScreen(
                                  words: snapshot.data!,
                                  classroomId: widget.classroomId, // classroomId değerini burada aktar
                                  studySetId: widget.studySetId, // studySetId değerini burada aktar
                                );
                              } else {
                                return CustomLoadingIndicator();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                    _buildGameModeTile(context, "Dinle", areGamesClickable ? Colors.deepOrangeAccent : Colors.grey, Icons.music_note, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FutureBuilder<List<WordDetail>>(
                            future: wordsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return ListenAndWriteScreen(
                                  words: snapshot.data!,
                                );
                              } else {
                                return CustomLoadingIndicator();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ValueListenableBuilder<int>(
                  valueListenable: starredCountNotifier,
                  builder: (context, count, _) {
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueGrey),
                          boxShadow: [
                            BoxShadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Yıldızlı Kelime Sayısı: ${count}',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: FutureBuilder<List<WordDetail>>(
                  future: wordsFuture, // Güncellenmiş future
                  builder: (context, wordSnapshot) {
                    // Yükleme durumu kontrolü
                    if (wordSnapshot.connectionState == ConnectionState.waiting) {
                      // Eğer veri yükleniyorsa, yükleme göstergesi gösterilir
                      return CustomLoadingIndicator();
                    } else if (wordSnapshot.hasError) {
                      // Eğer bir hata oluşmuşsa, hata mesajı gösterilir
                      return Text('Error: ${wordSnapshot.error}');
                    } else if (wordSnapshot.hasData && wordSnapshot.data!.isEmpty) {
                      // Eğer veri yüklendi ancak liste boşsa, kullanıcıya bilgilendirici bir mesaj gösterilir
                      return Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue[100],
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'Yıldızlanmış kelime bulunmuyor. Hemen öğrenmediğiniz kelimeleri yıldızlayın ve öğrenmeye başlayın!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    } else if (wordSnapshot.hasData) {
                      // Eğer veri başarıyla yüklendiyse ve veri varsa, yıldızlanmış kelimeleri listelemek için AnimatedList kullanılır
                      return AnimatedList(
                        key: animatedListKey,
                        initialItemCount: starredWordsList.length,
                        itemBuilder: (context, index, animation) => buildWordTile(context, index, animation),
                      );
                    } else {
                      // Hiçbir veri yoksa, uygun bir uyarı mesajı gösterilir
                      return const Text('No words available');
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildKlasikKelibuTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        color: areGamesClickable ? Colors.deepPurple[400] : Colors.grey, // Tıklanabilir duruma göre renk ayarı
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: areGamesClickable ? Colors.deepPurple.shade900.withOpacity(0.5) : Colors.grey.shade400.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        gradient: areGamesClickable
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade600],
        )
            : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey, Colors.grey[300]!], // Tıklanamaz durumda gri gradient
        ),
      ),
      child: InkWell(
        onTap: areGamesClickable
            ? () {          Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FutureBuilder<List<WordDetail>>(
              future: wordsFuture, // Burada Future<List<WordDetail>> türünde bir Future bekleniyor
              builder: (context, snapshot) {
                List<WordDetail> randomWords = selectRandomWords(snapshot.data!, 100);

                if (snapshot.hasData) {
                  print('snapshot.data');
                  print(snapshot.data);
                  // Eğer snapshot içinde veri varsa, bu verileri QuizScreen'e gönder
                  return KelimeOyunu(
                    words: randomWords!, // wordsFuture'den gelen veriler
                    classroomId: widget.classroomId, // Aktarılacak classroomId
                    studySetId: widget.studySetId, // Aktarılacak studySetId
                  );
                } else {
                  // Eğer veri yoksa, yükleme göstergesini göster
                  return CustomLoadingIndicator();
                }
              },
            ),
          ),
        );}
            : null, // Tıklanabilirlik durumuna göre onTap işlevi
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gamepad, color: Colors.white, size: 30),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Klasik Kelibu",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  shadows: [
                    Shadow(
                      blurRadius: 6.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  List<WordDetail> selectRandomWords(List<WordDetail> words, int count) {
    Random random = Random();
    return (words.toList()..shuffle(random)).take(count).toList();
  }
  Future<void> toggleStar(int wordId, bool isStarred, int userId) async {
    try {
      // Kelimeyi yıldızlı kelime listesinden ekleyip çıkarma işlemi
      await StarredWordsService().toggleWordStarStatus(wordId, true, widget.studySetId, widget.classroomId);

      setState(() {
        _loadWords();
        print('setstate');
      });
    } catch (e) {
      // Hata işleme
      print("An error occurred while toggling the star status: $e");
    }
  }

  Widget _buildGameModeTile(BuildContext context, String title, Color color, IconData? icon, TextStyle textStyle, [VoidCallback? onTap]) {
    // Ekran boyutuna göre dinamik değerler
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = screenWidth < 600 ? 8.0 : 16.0; // Ekran boyutuna göre padding ayarı
    double iconSize = screenWidth < 600 ? 30 : 40; // Ekran boyutuna göre ikon boyutu
    double fontSize = screenWidth < 600 ? textStyle.fontSize ?? 18 : ((textStyle.fontSize ?? 18) + 4); // Ekran boyutuna göre font boyutu

    return Padding(
      padding: EdgeInsets.all(padding), // Dinamik dış boşluk ekleme
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Kenar yuvarlaklığını artır
        ),
        color: color,
        elevation: 10, // Yükselti ve gölge ayarını artır
        child: InkWell(
          onTap: color == Colors.grey ? null : onTap ?? () {
            print('$title tıklandı');
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding), // Dinamik iç boşluk ekleme
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null)
                  Container(
                    padding: EdgeInsets.all(8.0), // İkona sabit padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), // İkon arka planı
                      shape: BoxShape.circle, // Daire şeklinde bir arka plan
                      boxShadow: [
                        // Gölge efekti
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: iconSize), // Dinamik ikon boyutu
                  ),
                if (icon != null) SizedBox(width: padding), // İkon ve metin arasında dinamik boşluk
                Text(
                  title,
                  style: textStyle.copyWith(fontSize: fontSize), // Dinamik font boyutu
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToWordDetail(WordDetail word) {
    // Kelime detay sayfasına yönlendirme yapın
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => StudyScreen(
        words: [word],
        classroomId: widget.classroomId,
        studySetId: widget.studySetId,
      ),
    ));
  }

  Widget _buildGameModeTileInprogress(BuildContext context, String title, [VoidCallback? onTap]) {
    // Ekran boyutuna göre dinamik değerler
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = screenWidth < 600 ? 8.0 : 16.0; // Ekran boyutuna göre padding ayarı
    double iconSize = screenWidth < 600 ? 30 : 40; // Ekran boyutuna göre ikon boyutu
    TextStyle textStyle = Theme.of(context).textTheme.headline6!.copyWith(color: Colors.black); // TextStyle parametresi kaldırıldı, doğrudan burada belirlendi
    double fontSize = screenWidth < 600 ? textStyle.fontSize ?? 18 : ((textStyle.fontSize ?? 18) + 4); // Ekran boyutuna göre font boyutu

    return Padding(
      padding: EdgeInsets.all(padding), // Dinamik dış boşluk ekleme
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Kenar yuvarlaklığını artır
        ),
        color: Colors.grey, // Gri renk sabit olarak ayarlandı
        elevation: 10, // Yükselti ve gölge ayarını artır
        child: InkWell(
          onTap: onTap, // onTap null ise, tıklama işlevselliği devre dışı bırakılır
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding), // Dinamik iç boşluk ekleme
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(8.0), // İkona sabit padding
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // İkon arka planı
                    shape: BoxShape.circle, // Daire şeklinde bir arka plan
                    boxShadow: [
                      // Gölge efekti
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.build_circle, color: Colors.grey, size: iconSize), // Yapım aşaması ikonu
                ),
                SizedBox(width: padding), // İkon ve metin arasında dinamik boşluk
                Text(
                  title,
                  style: textStyle.copyWith(fontSize: fontSize), // Dinamik font boyutu
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
