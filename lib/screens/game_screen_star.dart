import 'package:auto_size_text/auto_size_text.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/flash_card_star.dart';
import 'package:kelibu/screens/classic_kelibu.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:kelibu/screens/quiz.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/screens/quizStar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../event.dart';
import '../event_bus.dart';
import '../globalDart/urls.dart';
import '../shared_preferences/shared_preferences.dart';
import '../variables.dart';
import 'flash_card.dart';
import 'loadingIndicator.dart';
import 'study_screen.dart';
import 'listen_write.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _GameModeStarScreenState extends State<GameModeStarScreen>
    with TickerProviderStateMixin {
  late Future<List<WordDetail>> wordsFuture;
  late List<WordDetail> words;
  late Map<int, bool> starredWords;
  late Stream<List<WordDetail>> wordsStream;
  double loadingProgress = 0.0;
  bool _showOnlyStarredWords = false;
  bool _isDarkMode = false;
  bool _isMeaningVisible = true;
  bool _isSearchPanelVisible = false;
  FlutterTts flutterTts = FlutterTts();
  TextEditingController _searchController = TextEditingController();
  List<WordDetail> _filteredWords = [];
  bool _isLoading = true;

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    words = [];
    starredWords = {};
    _loadData();
    wordsFuture = _loadWords();

    _searchController.addListener(_filterWords);
    appEventBus.on<StarredWordsChangedEvent>().listen((event) async {
      await updateStarredWords();
    });
  }

  Future<List<WordDetail>> _loadWords() async {
    String processedString =
        widget.studySetName.replaceAll('[', '').replaceAll(']', '');
    List<int> wordIds = processedString
        .split(',')
        .map((id) => int.tryParse(id.trim()) ?? 0)
        .where((id) => id != 0)
        .toList();
    return ApiService().fetchWordsDetailStar(widget.classroomId, wordIds);
  }

  Future<void> _loadData() async {
    await _loadDarkModePreference();
    await initializeStarredNotifiers();
    setState(() {
      _isLoading = false;
      _isDataLoaded = true;
    });
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Future<void> updateStarredWords() async {
    var starredWordsSet = await StarredWordsService()
        .loadStarredWords(widget.classroomId, widget.studySetId);
    setState(() {
      for (var word in words) {
        starredWords[word.id] = starredWordsSet.contains(word.id);
      }
    });
  }

  Future<void> initializeStarredNotifiers() async {
    setState(() {
      loadingProgress = 0.0;
    });

    String processedString =
        widget.studySetName.replaceAll('[', '').replaceAll(']', '');
    List<int> wordIds = processedString
        .split(',')
        .map((id) => int.tryParse(id.trim()) ?? 0)
        .where((id) => id != 0)
        .toList();

    setState(() {
      loadingProgress = 0.2;
    });

    final Future<Set<int>> starredWordsFuture = StarredWordsService()
        .loadStarredWords(widget.classroomId, widget.studySetId);
    final Future<List<WordDetail>> wordDetailsFuture =
        ApiService().fetchWordsDetailStar(widget.classroomId, wordIds);

    final results = await Future.wait([starredWordsFuture, wordDetailsFuture]);

    final Set<int> starredWordsSet = results[0] as Set<int>;
    final List<WordDetail> wordDetails = results[1] as List<WordDetail>;

    setState(() {
      words = wordDetails;
      _filteredWords = words;
      starredWords = {
        for (var word in words) word.id: starredWordsSet.contains(word.id)
      };
      loadingProgress = 1.0;
    });
  }

  void _filterWords() {
    setState(() {
      _filteredWords = words
          .where((word) => word.word
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    var screenSize = MediaQuery.of(context).size;
    int gridCount = screenSize.width > 600 ? 4 : 2;
    double aspectRatio = screenSize.width > 600 ? 1.5 : 2;
    bool isTablet = screenSize.width > 600;
    bool yatayEkran = MediaQuery.of(context).size.aspectRatio > 1.5;
    int childAspectRatio = isTablet ? 4 : 2;
    double crossAxisCount = yatayEkran ? 4 : 2;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(true);
        return true;
      },
      child: Scaffold(
        backgroundColor: colors["background"],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: AutoSizeText(
                  'Yıldızlı Kelimeler Modu',
                  style: GoogleFonts.poppins(
                    color: _isDarkMode ? Colors.amber[100] : Colors.amber[900],
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  minFontSize: 14,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          iconTheme: IconThemeData(color: colors["text"]),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: colors["text"]),
              onPressed: () {
                setState(() {
                  _isSearchPanelVisible = !_isSearchPanelVisible;
                });
              },
            ),
            _buildRoundedIconButton(Icons.slow_motion_video_sharp, Colors.green,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        VideoPlayerScreen(videoUrl: AppUrls.gamescreenstar)),
              );
            }),
          ],
        ),
        body: _isLoading
            ? Center(child: CustomLoadingIndicator())
            : !_isDataLoaded
                ? CustomLoadingIndicator()
                : _filteredWords.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_border,
                                size: 64,
                                color: _isDarkMode
                                    ? Colors.amber[300]
                                    : Colors.amber[700],
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Yıldızlı kelimeniz yok.",
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Dönün ve kelimeleri yıldızlayarak öğrenmenize hemen başlayın!",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Kelime Listesine Dön"),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  backgroundColor: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              height: _isSearchPanelVisible ? 60.0 : 0.0,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Kelime ara...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    filled: true,
                                    fillColor: _isDarkMode
                                        ? Colors.white60
                                        : Colors.white10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        FutureBuilder<List<WordDetail>>(
                                      future: wordsFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return KelimeOyunu(
                                            classroomId: 1,
                                            studySetId: 1,
                                            words: snapshot.data!,
                                          ); // return eklendi
                                        } else {
                                          return CustomLoadingIndicator();
                                        }
                                      },
                                    ),
                                  ));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _isDarkMode
                                          ? [
                                              Colors.deepPurple.shade800,
                                              Colors.deepPurple.shade900
                                            ]
                                          : [
                                              Colors.deepPurple.shade400,
                                              Colors.deepPurple.shade700
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _isDarkMode
                                              ? Colors.deepPurple.shade700
                                              : Colors.deepPurple.shade400,
                                          _isDarkMode
                                              ? Colors.deepPurple.shade900
                                              : Colors.deepPurple.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.deepPurple.withOpacity(
                                              _isDarkMode ? 0.3 : 0.4),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.gamepad,
                                              color: Colors.white, size: 28),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Klasik Kelibu",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.arrow_forward,
                                              color: Colors.white, size: 24),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridCount,
                              childAspectRatio: aspectRatio,
                            ),
                            delegate: SliverChildListDelegate([
                              _buildGameModeTile(
                                  context,
                                  "Öğren",
                                  Colors.blue,
                                  Icons.school,
                                  TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18), () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FutureBuilder<List<WordDetail>>(
                                      future: wordsFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return QuizScreen(
                                            words: snapshot.data!,
                                            classroomId: widget.classroomId,
                                            studySetId: widget.studySetId,
                                            isStarredMode: true,
                                          );
                                        } else {
                                          return CustomLoadingIndicator();
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }),
                              _buildGameModeTile(
                                  context,
                                  "Flash Kart",
                                  Colors.green,
                                  Icons.flash_on,
                                  TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18), () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FutureBuilder<List<WordDetail>>(
                                      future: wordsFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return FlashCardScreen(
                                            words: snapshot.data!,
                                            classroomId: widget.classroomId,
                                            studySetId: widget.studySetId,
                                            isStarred: true,
                                          );
                                        } else {
                                          return CustomLoadingIndicator();
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }),
                              _buildGameModeTile(
                                  context,
                                  "Çalış",
                                  Colors.greenAccent,
                                  Icons.work,
                                  TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18), () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FutureBuilder<List<WordDetail>>(
                                      future: wordsFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return StudyScreen(
                                            words: snapshot.data!,
                                            classroomId: widget.classroomId,
                                            studySetId: widget.studySetId,
                                            isStarred: true,
                                          );
                                        } else {
                                          return CustomLoadingIndicator();
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }),
                              _buildGameModeTile(
                                  context,
                                  "Dinle",
                                  Colors.deepOrangeAccent,
                                  Icons.music_note,
                                  TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18), () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FutureBuilder<List<WordDetail>>(
                                      future: wordsFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return ListenAndWriteScreen(
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
                            ]),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? Colors.grey[850]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _isMeaningVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: _isDarkMode
                                                ? Colors.white70
                                                : Colors.grey[600],
                                            size: 24,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            "Anlamları Göster",
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: _isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Transform.scale(
                                        scale: 0.8,
                                        child: CupertinoSwitch(
                                          value: _isMeaningVisible,
                                          onChanged: (value) {
                                            setState(() {
                                              _isMeaningVisible = value;
                                            });
                                          },
                                          activeColor: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                WordDetail word = _filteredWords[index];
                                return AnimatedBuilder(
                                  animation: ValueNotifier(
                                      starredWords[word.id] ?? false),
                                  builder: (context, child) {
                                    bool isStarred =
                                        starredWords[word.id] ?? false;
                                    return TweenAnimationBuilder(
                                      tween: ColorTween(
                                        begin: _isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.white,
                                        end: isStarred
                                            ? (_isDarkMode
                                                ? Colors.amber.shade900
                                                    .withOpacity(0.3)
                                                : Colors.amber.shade100)
                                            : (_isDarkMode
                                                ? Colors.grey[800]
                                                : Colors.white),
                                      ),
                                      duration: Duration(milliseconds: 300),
                                      builder: (context, Color? backgroundColor,
                                          child) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: backgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                    _isDarkMode ? 0.3 : 0.05),
                                                blurRadius: 10,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () =>
                                                    _navigateToWordDetail(word),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  word.word,
                                                                  style:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: isStarred
                                                                        ? (_isDarkMode
                                                                            ? Colors
                                                                                .amber.shade200
                                                                            : Colors
                                                                                .amber.shade800)
                                                                        : (_isDarkMode
                                                                            ? Colors.white
                                                                            : Colors.black87),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height: 4),
                                                                Text(
                                                                  word.type?.isNotEmpty ==
                                                                          true
                                                                      ? word
                                                                          .type!
                                                                      : "Tip belirsiz",
                                                                  style:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontSize:
                                                                        14,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                    color: _isDarkMode
                                                                        ? Colors
                                                                            .white60
                                                                        : Colors
                                                                            .black45,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons.delete,
                                                              color:
                                                                  Colors.amber,
                                                            ),
                                                            onPressed:
                                                                () async {
                                                              setState(() {
                                                                starredWords[word
                                                                        .id] =
                                                                    false;
                                                              });
                                                              await removeStarredWord(
                                                                  word.id);
                                                              setState(() {
                                                                _filteredWords
                                                                    .removeWhere((w) =>
                                                                        w.id ==
                                                                        word.id);
                                                                words.removeWhere(
                                                                    (w) =>
                                                                        w.id ==
                                                                        word.id);
                                                              });
                                                            },
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                                Icons.volume_up,
                                                                color: _isDarkMode
                                                                    ? Colors
                                                                        .blue
                                                                        .shade300
                                                                    : Colors
                                                                        .blue
                                                                        .shade700),
                                                            onPressed: () =>
                                                                _speak(
                                                                    word.word),
                                                          ),
                                                        ],
                                                      ),
                                                      if (_isMeaningVisible) ...[
                                                        SizedBox(height: 8),
                                                        Text(
                                                          word.meaning,
                                                          style:
                                                              GoogleFonts.inter(
                                                            fontSize: 14,
                                                            color: isStarred
                                                                ? (_isDarkMode
                                                                    ? Colors
                                                                        .amber
                                                                        .shade100
                                                                        .withOpacity(
                                                                            0.8)
                                                                    : Colors
                                                                        .amber
                                                                        .shade900
                                                                        .withOpacity(
                                                                            0.8))
                                                                : (_isDarkMode
                                                                    ? Colors
                                                                        .white70
                                                                    : Colors
                                                                        .black54),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              childCount: _filteredWords.length,
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Future<void> removeStarredWord(int wordId) async {
    await StarredWordsService().removeWordFromAll(wordId);
    await updateStarredWords();
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

  Future<void> toggleStar(int wordId, bool isStarred) async {
    await StarredWordsService().toggleWordStarStatus(
        wordId, !isStarred, widget.classroomId, widget.studySetId);
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

  Widget _buildGameModeTile(BuildContext context, String title, Color color,
      IconData? icon, TextStyle textStyle,
      [VoidCallback? onTap]) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final iconSize = isSmallScreen ? 28.0 : 32.0;
    final fontSize = isSmallScreen ? 16.0 : 20.0;

    color = _adjustColorForDarkMode(context, color);

    return Padding(
      padding: EdgeInsets.all(8),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: InkWell(
          onTap: onTap ??
              () {
                print('$title tıklandı');
              },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: <Widget>[
                if (icon != null) ...[
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: iconSize),
                  ),
                  SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedIconButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: CircleBorder(),
      ),
      child: Icon(icon, color: Colors.white, size: 16.sp),
    );
  }
}
