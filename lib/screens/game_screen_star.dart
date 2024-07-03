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
import 'package:shared_preferences/shared_preferences.dart';
import '../event.dart';
import '../event_bus.dart';
import '../shared_preferences/shared_preferences.dart';
import '../variables.dart';
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
      child: SpinKitChasingDots(
        color: Colors.blue,
        size: 50.0,
      ),
    );
  }
}

class GameModeStarScreen extends StatefulWidget {
  final String studySetName;
  final int classroomId;
  final int studySetId;

  const GameModeStarScreen({
    Key? key,
    required this.studySetName,
    required this.classroomId,
    required this.studySetId,
  }) : super(key: key);
  @override
  _GameModeStarScreenState createState() => _GameModeStarScreenState();
}

class _GameModeStarScreenState extends State<GameModeStarScreen> {
  late Future<List<WordDetail>> wordsFuture;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  GlobalKey<AnimatedListState> animatedListKey = GlobalKey<AnimatedListState>();
  List<WordDetail> starredWordsList = [];
  late Map<int, bool> starredWords;
  Map<int, GlobalKey> _listTileKeys = {};
  List<WordDetail> wordDetails = [];
  Map<int, Color> _tileColors = {};
  Map<int, GlobalKey> _tileKeys = {};
  bool isLoading = true;

  ValueNotifier<int> starredCountNotifier = ValueNotifier<int>(0);
  bool areGamesClickable = true;
  List<int> wordIds = [];
  bool _isDarkMode = false;
  bool _isMeaningVisible = true; // Anlam görünürlüğü ayarı
  bool _isSearchPanelVisible = false;
  TextEditingController _searchController = TextEditingController();
  List<WordDetail> _filteredWords = [];

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
    String processedString = widget.studySetName.replaceAll('[', '').replaceAll(']', '');
    List<String> stringIds = processedString.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
    wordIds = stringIds.map((id) => int.tryParse(id) ?? 0).toList();
    wordsFuture = ApiService().fetchWordsDetailStar(widget.classroomId, wordIds);

    wordDetails = await wordsFuture;

    setState(() {
      starredWordsList = getRandomWordDetails(wordDetails);
      _filteredWords = starredWordsList;
      starredCountNotifier.value = wordDetails.length;
    });
  }

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
      await StarredWordsService().removeWordFromAll(word.id);

      animatedListKey.currentState?.removeItem(
        index,
            (context, animation) => buildWordTile(context, index, animation),
        duration: Duration(milliseconds: 500),
      );

      setState(() {
        starredWordsList = List<WordDetail>.from(starredWordsList);
        starredWordsList.removeAt(index);
        starredCountNotifier.value = starredWordsList.length;
      });
    }
  }

  Widget buildWordTile(BuildContext context, int index, Animation<double> animation) {
    if (index >= _filteredWords.length) {
      return Container();
    }
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    WordDetail word = _filteredWords[index];
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: _isDarkMode ? Colors.pinkAccent.withOpacity(0.7) : Colors.pink[50],
        child: ListTile(
          tileColor: colors["background"],
          leading: Icon(Icons.star, color: Colors.amber),
          title: Text(
            word.word,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          subtitle: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: _isMeaningVisible
                ? Text(
              word.meaning,
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black87,
              ),
            )
                : SizedBox.shrink(),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => removeWord(index),
          ),
          onTap: () => _navigateToWordDetail(word),
        ),
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
    _loadDarkModePreference();
    _searchController.addListener(_filterWords);
    appEventBus.on<StarredWordsChangedEvent>().listen((event) async {
      setState(() {
        starredCountNotifier.value = event.newCount;
      });
    });
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  void _filterWords() {
    setState(() {
      _filteredWords = starredWordsList
          .where((word) => word.word.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    int gridCount = screenSize.width > 600 ? 4 : 2;
    double aspectRatio = screenSize.width > 600 ? 1.5 : 2;
    bool isTablet = screenSize.width > 600;
    bool yatayEkran = MediaQuery.of(context).size.aspectRatio > 1.5;

    int childAspectRatio = isTablet ? 4 : 2;
    double crossAxisCount = yatayEkran ? 4 : 2;
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: colors["background"],
      appBar: AppBar(
        backgroundColor: colors["background"],
        title: Text(
          'Oyun Modları',
          style: GoogleFonts.poppins(
            color: colors["text"],
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: colors["text"],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: colors["text"]),
            onPressed: () {
              setState(() {
                _isSearchPanelVisible = !_isSearchPanelVisible;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _isSearchPanelVisible ? 60.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Kelime ara...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: _isDarkMode ? Colors.white60 : Colors.white10,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              if (areGamesClickable) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FutureBuilder<List<WordDetail>>(
                      future: wordsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CustomLoadingIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Hata: ${snapshot.error}');
                        } else if (snapshot.hasData) {
                          if (snapshot.data!.isEmpty) {
                            return Center(child: Text("Yıldızlı kelime bulunamadı, oyun başlatılamıyor!"));
                          } else {
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => FutureBuilder<List<WordDetail>>(
                                        future: wordsFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return KelimeOyunu(
                                              words: snapshot.data!,
                                              classroomId: widget.classroomId,
                                              studySetId: widget.studySetId,
                                            );
                                          } else {
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
                                    color: _isDarkMode ? Colors.deepPurple[700] : Colors.deepPurple[400],
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isDarkMode ? Colors.deepPurple.shade900.withOpacity(0.5) : Colors.deepPurple.shade900.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                    gradient: _isDarkMode
                                        ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade900],
                                    )
                                        : LinearGradient(
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
                          return SizedBox();
                        }
                      },
                    ),
                  ),
                );
              } else {
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
                              classroomId: widget.classroomId,
                              studySetId: widget.studySetId,
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
                              classroomId: widget.classroomId,
                              studySetId: widget.studySetId,
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
                              classroomId: widget.classroomId,
                              studySetId: widget.studySetId,
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
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Anlamları görmek için ikona tıklayın",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isMeaningVisible ? Icons.visibility : Icons.visibility_off,
                      color: _isMeaningVisible ? (_isDarkMode ? Colors.lightGreen : Colors.green) : Colors.red,
                    ),
                    onPressed: () {
                      setState(() {
                        _isMeaningVisible = !_isMeaningVisible;
                      });
                    },
                  ),
                ],
              ),
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
                } else if (wordSnapshot.hasData && wordSnapshot.data!.isEmpty) {
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
                  return AnimatedList(
                    key: animatedListKey,
                    initialItemCount: _filteredWords.length,
                    itemBuilder: (context, index, animation) => buildWordTile(context, index, animation),
                  );
                } else {
                  return const Text('No words available');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildKlasikKelibuTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        color: areGamesClickable ? (_isDarkMode ? Colors.deepPurple[700] : Colors.deepPurple[400]) : Colors.grey,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: areGamesClickable ? (_isDarkMode ? Colors.deepPurple.shade900.withOpacity(0.5) : Colors.deepPurple.shade900.withOpacity(0.5)) : Colors.grey.shade400.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        gradient: areGamesClickable
            ? (_isDarkMode
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade900],
        )
            : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade600],
        ))
            : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey, Colors.grey[300]!],
        ),
      ),
      child: InkWell(
        onTap: areGamesClickable
            ? () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FutureBuilder<List<WordDetail>>(
                future: wordsFuture,
                builder: (context, snapshot) {
                  List<WordDetail> randomWords = selectRandomWords(snapshot.data!, 100);

                  if (snapshot.hasData) {
                    return KelimeOyunu(
                      words: randomWords!,
                      classroomId: widget.classroomId,
                      studySetId: widget.studySetId,
                    );
                  } else {
                    return CustomLoadingIndicator();
                  }
                },
              ),
            ),
          );
        }
            : null,
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
      await StarredWordsService().toggleWordStarStatus(wordId, true, widget.studySetId, widget.classroomId);

      setState(() {
        _loadWords();
      });
    } catch (e) {
      print("An error occurred while toggling the star status: $e");
    }
  }

  Color _adjustColorForDarkMode(BuildContext context, Color color) {
    if (_isDarkMode) {
      double darknessFactor = 0.7;
      int red = (color.red * (1 - darknessFactor)).toInt();
      int green = (color.green * (1 - darknessFactor)).toInt();
      int blue = (color.blue * (1 - darknessFactor)).toInt();
      return Color.fromARGB(color.alpha, red, green, blue);
    }
    return color;
  }

  Widget _buildGameModeTile(BuildContext context, String title, Color color, IconData? icon, TextStyle textStyle, [VoidCallback? onTap]) {
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = screenWidth < 600 ? 8.0 : 16.0;
    double iconSize = screenWidth < 600 ? 30 : 40;
    double fontSize = screenWidth < 600 ? textStyle.fontSize ?? 18 : ((textStyle.fontSize ?? 18) + 4);

    color = _adjustColorForDarkMode(context, color);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: color,
        elevation: 10,
        child: InkWell(
          onTap: color == Colors.grey ? null : onTap ?? () {
            print('$title tıklandı');
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null)
                  Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),
                if (icon != null) SizedBox(width: padding),
                Text(
                  title,
                  style: textStyle.copyWith(fontSize: fontSize),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToWordDetail(WordDetail word) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => StudyScreen(
        words: [word],
        classroomId: widget.classroomId,
        studySetId: widget.studySetId,
      ),
    ));
  }
}
