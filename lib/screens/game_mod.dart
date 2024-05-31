import 'package:flutter/material.dart';
import 'package:kelibu/Models/wordDetaik.dart'; // WordDetail modelinizin importu
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/flash_card.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/screens/classic_kelibu.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/providers/user_provider.dart'; // UserProvider importu
import 'package:provider/provider.dart';
import 'package:kelibu/screens/quiz.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

import '../event.dart';
import '../event_bus.dart';
import '../shared_preferences/shared_preferences.dart';
import 'loadingIndicator.dart';
import 'study_screen.dart'; // StudyScreen'i içe aktar
import 'listen_write.dart'; // StudyScreen'i içe aktar
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts paketini import edin.

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

class GameModeScreen extends StatefulWidget {
  final String studySetName;
  final int classroomId; // Yeni eklenen alan
  final int studySetId; // Yeni eklenen alan

  const GameModeScreen({
    Key? key,
    required this.studySetName,
    required this.classroomId, // Yeni parametre
    required this.studySetId, // Yeni parametre
  }) : super(key: key);
  @override
  _GameModeScreenState createState() => _GameModeScreenState();
}


class _GameModeScreenState extends State<GameModeScreen> with WidgetsBindingObserver {
  late Future<List<WordDetail>> wordsFuture;
  late Map<int, bool> starredWords;
   Map<int, Color> _tileColors = {};
   Map<int, GlobalKey> _tileKeys = {};
  bool _showOnlyStarredWords = false; // Yıldızlı kelimeleri gösterme durumu

  late Map<int, ValueNotifier<bool>> starredNotifiers;
  ValueNotifier<int> starredCountNotifier = ValueNotifier<int>(0);
  late StarredWordsService _starredWordsService;

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

  @override
  void initState() {
    super.initState();
    _starredWordsService = StarredWordsService(); // StarredWordsService nesnesini başlat
    starredNotifiers = {};
    starredWords = {};
    wordsFuture = initializeStarredNotifiers(); // Future<void> değil, Future<List<WordDetail>> döndürmelidir.

    appEventBus.on<StarredWordsChangedEvent>().listen((event) async {
      await updateStarredWords(); // Yıldızlanmış kelimelerin listesini yeniden yükler
      setState(() {
        // Yıldızlı kelime sayısını event ile güncelle
        starredCountNotifier.value = event.newCount;
      });
    });
  }

  Future<void> updateStarredWords() async {
    var starredWordsSet = await _starredWordsService.loadStarredWords(widget.classroomId, widget.studySetId);
    for (var wordId in starredNotifiers.keys) {
      bool isStarred = starredWordsSet.contains(wordId);
      starredNotifiers[wordId]?.value = isStarred;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Uygulama yeniden odaklandığında (örneğin, geri dönüldüğünde)
      wordsFuture = initializeStarredNotifiers(); // Yıldızlı kelimeleri yeniden yükle
      setState(() {}); // Widget'ı yeniden çizmek için
    }
  }
  void refreshStarredWords() {
    wordsFuture = initializeStarredNotifiers();
    setState(() {});
  }

  Future<List<WordDetail>> initializeStarredNotifiers() async {
    String processedString = widget.studySetName
        .replaceAll('[', '')
        .replaceAll(']', '');

    List<String> stringIds = processedString.split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    List<int> wordIds = stringIds.map((id) => int.tryParse(id) ?? 0).toList();
    var starredWordsSet = await _starredWordsService.loadStarredWords(widget.classroomId, widget.studySetId);

    var wordDetails = await ApiService().fetchWordsDetail(wordIds);


    int initialStarredCount = wordDetails.where((word) => starredWordsSet.contains(word.id)).length;

    setState(() {
      wordsFuture = Future.value(wordDetails);

      _tileKeys.clear();
      starredNotifiers.clear();
      starredWords.clear();
      for (var word in wordDetails) {
        _tileKeys[word.id] = GlobalKey();
        bool isStarred = starredWordsSet.contains(word.id);
        starredNotifiers[word.id] = ValueNotifier<bool>(isStarred);
        starredWords[word.id] = isStarred;
      }

      // Yıldızlanmış kelimelerin başlangıç sayısını ayarlıyoruz.
      starredCountNotifier.value = initialStarredCount;
    });

    return wordDetails;
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }


  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    int gridCount = screenSize.width > 600 ? 4 : 2;  // Tablet için 4, telefon için 2 sütun
    double aspectRatio = screenSize.width > 600 ? 1.5 : 2;  // Tablet için daha geniş tile'lar
    bool isTablet = screenSize.width > 600;
    bool yatayEkran =  MediaQuery.of(context).size.aspectRatio > 1.5;

    int childAspectRatio = isTablet ? 4 : 2;
    double crossAxisCount =  yatayEkran ? 4:2;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;
    if (wordsFuture == null) {
      // wordsFuture henüz başlatılmamışsa, yükleme göstergesini göster
      return WillPopScope(
        onWillPop: () async {
          // Bu kısımda geri tuşuna basıldığında yapılacak işlemleri tanımlayabilirsiniz.
          // True döndürmek, sayfadan çıkılmasına izin verir.
          // False döndürmek, sayfadan çıkılmasını engeller.
          Navigator.of(context).pop(true); // Sayfadan çık
          return true;
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın
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
          body: LogoLoadingIndicator(), // Yükleme göstergesi
        ),
      );
    }
    return WillPopScope(
      onWillPop: () async {
        // Bu kısımda geri tuşuna basıldığında yapılacak işlemleri tanımlayabilirsiniz.
        // True döndürmek, sayfadan çıkılmasına izin verir.
        // False döndürmek, sayfadan çıkılmasını engeller.
        Navigator.of(context).pop(true); // Sayfadan çık
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın
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
        body: Column(
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FutureBuilder<List<WordDetail>>(
                      future: wordsFuture, // Burada Future<List<WordDetail>> türünde bir Future bekleniyor
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          print('snapshot.data');
                          print(snapshot.data);
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
            Expanded(
              flex: 1,

              child: GridView.count(
                crossAxisCount: childAspectRatio,
                childAspectRatio: crossAxisCount ,
                children: <Widget>[
                  _buildGameModeTile(context, "Öğren", Colors.blue, Icons.school, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FutureBuilder<List<WordDetail>>(
                          future: wordsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return QuizScreen(
                                words: snapshot.data!,
                                classroomId: widget.classroomId, // classroomId değerini burada aktar
                                studySetId: widget.studySetId, // studySetId değerini burada aktar
                              );
                            } else {
                              return  CustomLoadingIndicator();
                            }
                          },
                        ),
                      ),
                    );
                  }),

                  _buildGameModeTile(context, "Flash Kart", Colors.green, Icons.flash_on, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FutureBuilder<List<WordDetail>>(
                          future: wordsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return FlashCardScreen(
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
                  _buildGameModeTile(context, "Çalış", Colors.greenAccent, Icons.work, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
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
                              return  CustomLoadingIndicator();                          }
                          },
                        ),
                      ),
                    );
                  }),
                  _buildGameModeTile(context, "Dinle", Colors.deepOrangeAccent, Icons.music_note, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
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
                              return  CustomLoadingIndicator();                          }
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: FutureBuilder<List<WordDetail>>(
                future: wordsFuture,
                builder: (context, wordSnapshot) {
                  if (wordSnapshot.connectionState == ConnectionState.waiting) {
                    return CustomLoadingIndicator();
                  } else if (wordSnapshot.hasError) {
                    return Text('Error: ${wordSnapshot.error}');
                  } else if (!wordSnapshot.hasData) {
                    return Text('No words available');
                  }

                  List<WordDetail> words = wordSnapshot.data!;
                  // Eğer sadece yıldızlı kelimeleri göstermek istiyorsak, filtreleme yap
                  if (_showOnlyStarredWords) {
                    words = words.where((word) => starredNotifiers[word.id]?.value ?? false).toList();
                  }

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showOnlyStarredWords = !_showOnlyStarredWords;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                          decoration: BoxDecoration(
                            color: _showOnlyStarredWords ? Colors.green : Colors.pink[300], // Moda göre arka plan rengi
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
                                'Yıldızlı Kelime Sayısı: ${starredCountNotifier.value}',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: words.length,
                          itemBuilder: (context, index) {
                            WordDetail word = words[index];
                            return ValueListenableBuilder<bool>(
                              valueListenable: starredNotifiers[word.id] ?? ValueNotifier(false),
                              builder: (context, isStarred, _) => ListTile(
                                leading: IconButton(
                                  icon: Icon(isStarred ? Icons.star : Icons.star_border, color: isStarred ? Colors.amber : Colors.grey),
                                  onPressed: () async {
                                    await toggleStar(word.id, isStarred);
                                  },
                                ),
                                title: Text(word.word, style: TextStyle(fontWeight: FontWeight.bold, color: _showOnlyStarredWords ? Colors.green : Colors.pink)),
                                subtitle: Text(word.meaning),
                                trailing: IconButton(
                                  icon: Icon(Icons.volume_up, color: Colors.cyan[400]),
                                  onPressed: () => _speak(word.word),
                                ),
                                onTap: () => _navigateToWordDetail(word),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
            ],
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
  Future<void> toggleStar(int wordId, bool isStarred) async {
    // SharedPreferences kullanarak kelimenin yıldızlı durumunu güncelleyin
    await _starredWordsService.toggleWordStarStatus(wordId, !isStarred, widget.classroomId, widget.studySetId);
    // UI güncellemesi için gerekli işlemler
  }
  Widget _buildGameModeTile(BuildContext context, String title, Color color, IconData? icon, TextStyle textStyle, [VoidCallback? onTap]) {
    // Ekran boyutuna göre dinamik değerler
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = screenWidth < 600 ? 8.0 : 10.0; // Ekran boyutuna göre padding ayarı
    double iconSize = screenWidth < 600 ? 30 : 30; // Ekran boyutuna göre ikon boyutu
    double fontSize = screenWidth < 600 ? textStyle.fontSize ?? 18 : ((textStyle.fontSize ?? 18) + 4); // Ekran boyutuna göre font boyutu
    double tileFontSize = screenWidth < 600 ? 18 : 22;  // Ekran genişliğine göre font boyutu
    return Padding(
      padding: EdgeInsets.all(padding), // Dinamik dış boşluk ekleme
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Kenar yuvarlaklığını artır
        ),
        color: color,
        elevation: 10, // Yükselti ve gölge ayarını artır
        child: InkWell(
          onTap: onTap ?? () {
            print('$title tıklandı');
          },
          borderRadius: BorderRadius.circular(15),
          splashColor: Colors.white.withOpacity(0.5), // Dalga efekti rengi
          highlightColor: Colors.white.withOpacity(0.2), // Dokunulduğunda rengi
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding), // Dinamik iç boşluk ekleme
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) Container(
                  padding: EdgeInsets.all(8.0), // İkona sabit padding
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // İkon arka planı
                    shape: BoxShape.circle, // Daire şeklinde bir arka plan
                    boxShadow: [ // Gölge efekti
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


}