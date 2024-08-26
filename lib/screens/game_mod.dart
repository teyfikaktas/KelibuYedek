import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kelibu/Models/wordDetaik.dart'; // WordDetail modelinizin importu
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/flash_card.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/screens/classic_kelibu.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/providers/user_provider.dart'; // UserProvider importu
import 'package:kelibu/screens/video_player.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/screens/quiz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../event.dart';
import '../event_bus.dart';
import '../globalDart/urls.dart';
import '../shared_preferences/shared_preferences.dart';
import '../variables.dart';
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
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animasyonu
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: Duration(seconds: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/logo.png', // Logo dosyanızın yolunu buraya girin
                width: 80,
                height: 80,
              ),
            ),
            SizedBox(height: 20),
            // Pulsating efekti
            SpinKitPulse(
              color: Colors.blue,
              size: 50.0,
            ),
            SizedBox(height: 10),
            Text(
              'Yükleniyor...',
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameModeScreen extends StatefulWidget {
  final String studySetName;
  final int classroomId;
  final int studySetId;

  const GameModeScreen({
    Key? key,
    required this.studySetName,
    required this.classroomId,
    required this.studySetId,
  }) : super(key: key);

  @override
  _GameModeScreenState createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> with WidgetsBindingObserver {
  late Future<void> initializationFuture;
  late List<WordDetail> words;
  late Map<int, bool> starredWords;
  bool _showOnlyStarredWords = false;
  bool _isDarkMode = false;
  bool _isMeaningVisible = true;
  bool _isSearchPanelVisible = false;
  FlutterTts flutterTts = FlutterTts();
  TextEditingController _searchController = TextEditingController();
  List<WordDetail> _filteredWords = [];
  int _starredWordCount = 0;

  @override
  void initState() {
    super.initState();
    words = [];
    starredWords = {};
    initializationFuture = _initializeData(); // wordsFuture'ı burada başlatıyoruz.

    _searchController.addListener(_filterWords);

    appEventBus.on<StarredWordsChangedEvent>().listen((event) async {
      await updateStarredWords();
    });
  }

  Future<void> _initializeData() async {
    await _loadDarkModePreference();
    await initializeStarredNotifiers();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkMode = prefs.getBool("darkMode") ?? false;
      });
    }
  }

  Future<void> updateStarredWords() async {
    var starredWordsSet = await StarredWordsService().loadStarredWords(widget.classroomId, widget.studySetId);
    setState(() {
      for (var word in words) {
        starredWords[word.id] = starredWordsSet.contains(word.id);
      }
    });
  }

  Future<void> initializeStarredNotifiers() async {
    String processedString = widget.studySetName.replaceAll('[', '').replaceAll(']', '');

    List<String> stringIds = processedString.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList();

    List<int> wordIds = stringIds.map((id) => int.tryParse(id) ?? 0).toList();
    var starredWordsSet = await StarredWordsService().loadStarredWords(widget.classroomId, widget.studySetId);

    var wordDetails = await ApiService().fetchWordsDetail(wordIds);

    if (mounted) {
      setState(() {
        words = wordDetails;
        _filteredWords = words;
        _starredWordCount = 0; // Başlangıçta sıfırla
        for (var word in words) {
          starredWords[word.id] = starredWordsSet.contains(word.id);
          if (starredWords[word.id]!) {
            _starredWordCount++; // Yıldızlı kelimeleri say
          }
        }
      });
    }
  }

  void _filterWords() {
    setState(() {
      _filteredWords = words
          .where((word) => word.word.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }

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
          backgroundColor: colors["background"],
          title: Text(
            'Oyun Modları',
            style: GoogleFonts.poppins(
              color: colors["text"],
              fontWeight: FontWeight.bold,
            ),
          ),

          iconTheme: IconThemeData(color: colors["text"]),
          actions: [
            _buildRoundedIconButton(Icons.help, Colors.green, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.gamescreen)),
              );
            }),
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
        body: FutureBuilder<void>(
          future: initializationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CustomLoadingIndicator();
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Bir hata oluştu: ${snapshot.error}'),
              );
            } else {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: AnimatedContainer(
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
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => KelimeOyunu(
                                words: words,
                                classroomId: widget.classroomId,
                                studySetId: widget.studySetId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isDarkMode
                                  ? [Colors.deepPurple.shade800, Colors.deepPurple.shade900]
                                  : [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _isDarkMode ? Colors.deepPurple.shade700 : Colors.deepPurple.shade400,
                                  _isDarkMode ? Colors.deepPurple.shade900 : Colors.deepPurple.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(_isDarkMode ? 0.3 : 0.4),
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
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.gamepad, color: Colors.white, size: 28),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.arrow_forward, color: Colors.white, size: 24),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCount,
                      childAspectRatio: aspectRatio,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildGameModeTile(context, "Öğren", Colors.blue, Icons.school, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
                        if (words.length < 4) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  'Ups! Kelimelerimiz Kaçmış!',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[800],
                                  ),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 80,
                                        color: Colors.amber[800],
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        'Öğren modundan en yüksek verimi almanız için en az 4 kelime gerekiyor. Haydi, biraz daha kelime ekleyelim!',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text(
                                      'Tamam',
                                      style: GoogleFonts.poppins(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(
                                words: words,
                                classroomId: widget.classroomId,
                                studySetId: widget.studySetId,
                              ),
                            ),
                          );
                        }
                      }),
                      _buildGameModeTile(context, "Flash Kart", Colors.green, Icons.flash_on, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FlashCardScreen(
                              words: words,
                              classroomId: widget.classroomId,
                              studySetId: widget.studySetId,
                            ),
                          ),
                        );
                      }),
                      _buildGameModeTile(context, "Çalış", Colors.greenAccent, Icons.work, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => StudyScreen(
                              words: words,
                              classroomId: widget.classroomId,
                              studySetId: widget.studySetId,
                            ),
                          ),
                        );
                      }),
                      _buildGameModeTile(context, "Dinle", Colors.deepOrangeAccent, Icons.music_note, TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ListenAndWriteScreen(
                              words: words,
                              classroomId: widget.classroomId,
                              studySetId: widget.studySetId,
                            ),
                          ),
                        );
                      }),
                    ]),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildSettingsCard(
                          icon: _isMeaningVisible ? Icons.visibility : Icons.visibility_off,
                          title: "Anlamları Göster",
                          value: _isMeaningVisible,
                          onChanged: (value) {
                            setState(() {
                              _isMeaningVisible = value;
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildDuolingoStyleStarredWordsIndicator(),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        WordDetail word = _filteredWords[index];
                        bool isStarred = starredWords[word.id] ?? false;

                        if (_showOnlyStarredWords && !isStarred) {
                          return SizedBox.shrink();
                        }
                        return AnimatedBuilder(
                          animation: ValueNotifier(starredWords[word.id] ?? false),
                          builder: (context, child) {
                            bool isStarred = starredWords[word.id] ?? false;
                            return TweenAnimationBuilder(
                              tween: ColorTween(
                                begin: _isDarkMode ? Colors.grey[800] : Colors.white,
                                end: isStarred
                                    ? (_isDarkMode ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber.shade100)
                                    : (_isDarkMode ? Colors.grey[800] : Colors.white),
                              ),
                              duration: Duration(milliseconds: 300),
                              builder: (context, Color? backgroundColor, child) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _navigateToWordDetail(word),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    word.word,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: isStarred
                                                          ? (_isDarkMode ? Colors.amber.shade200 : Colors.amber.shade800)
                                                          : (_isDarkMode ? Colors.white : Colors.black87),
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  IconButton(
                                                    icon: Icon(
                                                      isStarred ? Icons.star : Icons.star_border,
                                                      color: isStarred
                                                          ? (_isDarkMode ? Colors.amber.shade300 : Colors.amber.shade600)
                                                          : (_isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                                                    ),
                                                    onPressed: () async {
                                                      setState(() {
                                                        starredWords[word.id] = !isStarred;
                                                      });
                                                      await toggleStar(word.id, isStarred);
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.volume_up,
                                                        color: _isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700),
                                                    onPressed: () => _speak(word.word),
                                                  ),
                                                ],
                                              ),
                                              if (_isMeaningVisible) ...[
                                                SizedBox(height: 8),
                                                Text(
                                                  word.meaning,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color: isStarred
                                                        ? (_isDarkMode ? Colors.amber.shade100.withOpacity(0.8) : Colors.amber.shade900.withOpacity(0.8))
                                                        : (_isDarkMode ? Colors.white70 : Colors.black54),
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
              );
            }
          },
        ),
      ),
    );
  }
  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: activeColor,
                  ),
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

  Future<void> toggleStar(int wordId, bool isStarred) async {
    await StarredWordsService().toggleWordStarStatus(wordId, !isStarred, widget.classroomId, widget.studySetId);
    setState(() {
      if (!isStarred) {
        _starredWordCount++;
      } else {
        _starredWordCount--;
      }
    });
  }
  Widget _buildDuolingoStyleStarredWordsIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'Yıldızlı Kelimeleri Göster',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_starredWordCount',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Switch(
                value: _showOnlyStarredWords,
                onChanged: (value) {
                  setState(() {
                    _showOnlyStarredWords = value;
                  });
                },
                activeColor: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
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
          onTap: onTap ?? () {
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

  Widget _buildRoundedIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: CircleBorder(),
        padding: EdgeInsets.all(2.sp),
      ),
      child: Icon(icon, color: Colors.white, size: 16.sp),
    );
  }
  bool hasEnoughWords() {
    return words.length < 4;
  }
  Widget _buildWarningWidget() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 100,
            color: Colors.amber[800],
          ),
          SizedBox(height: 20),
          Text(
            'Ups! Kelimelerimiz Kaçmış!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber[800],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Oyun modundan en yüksek verimi almanız için en az 4 kelime gerekiyor. Haydi, biraz daha kelime ekleyelim!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.amber[900],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            child: Text('Kelime Ekle'),
            onPressed: () {
              // Kelime ekleme sayfasına yönlendirme
              Navigator.of(context).pop(); // Örnek olarak, önceki sayfaya dönüş
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.amber[700],
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
