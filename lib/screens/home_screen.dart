import 'dart:ui';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kelibu/screens/settings_screen.dart';
import 'package:kelibu/screens/study_screen_star.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/variables.dart';
import '../Models/category.dart';
import '../Models/wordDetaik.dart';
import '../providers/user_provider.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/WordListScreen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../screens/leader_screen.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';
import '../providers/darkmodeprovider.dart';
import 'RaceScreen.dart';
import 'library_star.dart';

class RaceScreen extends StatefulWidget {
  const RaceScreen({Key? key}) : super(key: key);

  @override
  _RaceScreenState createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink.shade300, Colors.purple.shade900],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ScaleTransition(
                scale: _animation,
                child: Icon(
                  Icons.videogame_asset,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Canlı Yarış',
                style: GoogleFonts.pressStart2p(
                  textStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8.0),
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/logo.png'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => RaceScreenBuild()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WordOfTheDay {
  final String term;
  final String definition;
  final String? type;

  WordOfTheDay({required this.term, required this.definition, this.type});

  factory WordOfTheDay.fromJson(Map<String, dynamic> json) {
    return WordOfTheDay(
      term: json['terim'],
      definition: json['tanim'],
      type: json['type'],
    );
  }
}

Future<WordOfTheDay> fetchWordOfTheDay() async {
  final uri = Uri.parse('https://kelibu.net/api/daily-word');
  final response = await http.get(uri, headers: {
    "X-Custom-Header": privacyKey.privacyKeyVariable,
  });

  if (response.statusCode == 200) {
    return WordOfTheDay.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load word of the day');
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  WordOfTheDay? _wordOfTheDay;
  Future<List<Package>>? packagesFuture;
  bool isExpanded = false;
  int _userPoint = 0;
  final FlutterTts flutterTts = FlutterTts();
  bool isInitialized = false;
  bool _isDataLoaded = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadWordOfTheDay();
    _getPoint();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Future<void> _saveDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkMode", _isDarkMode);
  }

  Future<void> initializeData() async {
    showLoadingIndicator();
    await syncStarredWords();
    hideLoadingIndicator();
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      _isDataLoaded = true;
    }
  }

  Future<void> syncStarredWords() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await ApiService().syncStarredWordsWithServer(userProvider.userId);
      print('Starred words synced successfully.');
    } catch (e) {
      print('Failed to sync starred words: $e');
    }
  }

  void showLoadingIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              Text("Sistemde gerekli ayarlar yapılıyor..."),
            ],
          ),
        );
      },
    );
  }

  void hideLoadingIndicator() {
    Navigator.pop(context);
  }

  Future<void> _loadWordOfTheDay() async {
    try {
      _wordOfTheDay = await fetchWordOfTheDay();
      await _saveWordToPrefs(_wordOfTheDay);
    } catch (error) {
      print('API Error, loading word from prefs: $error');
      _wordOfTheDay = await _loadWordFromPrefs();
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveWordToPrefs(WordOfTheDay? word) async {
    final prefs = await SharedPreferences.getInstance();
    if (word != null) {
      await prefs.setString('word_term', word.term);
      await prefs.setString('word_definition', word.definition);
      if (word.type != null) {
        await prefs.setString('word_type', word.type!);
      }
    }
  }

  Future<void> savePackagesToPrefs(List<Package> packages) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = json.encode(packages.map((package) => package.toJson()).toList());
    await prefs.setString('packages', encodedData);
  }

  Future<List<Package>> loadPackagesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('packages');
    if (encodedData != null) {
      List<dynamic> decodedData = json.decode(encodedData);
      return decodedData.map((packageJson) => Package.fromJson(packageJson)).toList();
    }
    return [];
  }

  Future<WordOfTheDay?> _loadWordFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final term = prefs.getString('word_term');
    final definition = prefs.getString('word_definition');
    final type = prefs.getString('word_type');
    if (term != null && definition != null) {
      return WordOfTheDay(term: term, definition: definition, type: type);
    }
    return null;
  }

  void _getPoint() async {
    int userId = Provider.of<UserProvider>(context, listen: false).userId;
    String hash = await Provider.of<UserProvider>(context, listen: false).getUsernameHash();
    try {
      Map<String, dynamic> userData = await ApiService().fetchUserPoint(userId);
      int userPoint = userData['point'];
      print('User Point: $userPoint');
      Provider.of<UserProvider>(context, listen: false).addPoint(userPoint);
    } catch (error) {
      print("Error fetching user point: $error");
    }
  }

  void _fetchData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;
    ApiService().fetchStarWordsAllSystem(currentUserId);
    ApiService().fetchUserPoint(currentUserId).then((userData) {
      setState(() {
        _userPoint = userData['point'];
        String newAvatarUrl = userData['avatar'];
        userProvider.addPoint(_userPoint);
        userProvider.updateUserAvatarUrl(newAvatarUrl);
      });
    }).catchError((error) {
      print("Error fetching user data: $error");
    });

    String hash = userProvider.getUsernameHash().toString();
    print('User hash: $hash');
    fetchPackages(currentUserId);
  }

  void fetchPackages(int userId) async {
    try {
      List<Package> packages = await ApiService().fetchCategories(userId);
      await savePackagesToPrefs(packages);
      setState(() {
        packagesFuture = Future.value(packages);
      });
    } catch (error) {
      print("API Error, loading packages from prefs: $error");
      List<Package> packages = await loadPackagesFromPrefs();
      setState(() {
        packagesFuture = Future.value(packages);
      });
    }
  }

  void fetchUserPoints() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;

    ApiService().fetchUserPoint(currentUserId).then((userData) {
      setState(() {
        _userPoint = userData['point'];
      });
    }).catchError((error) {
      print("Error fetching user data: $error");
    });
  }

  void speak(String text) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    final darkModeProvider = Provider.of<DarkModeProvider>(context);

    return Scaffold(
      backgroundColor: colors["background"],
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Spacer(),
                      AnimatedToggleSwitch<bool>.dual(
                        current: _isDarkMode,
                        first: false,
                        second: true,
                        height: 30,
                        indicatorSize: Size(30, 30),
                        onChanged: (b) async {
                          await _toggleDarkMode(b);

                          darkModeProvider.toggleDarkMode();

                          setState(() {
                            _isDarkMode = b;
                          });
                        },
                        iconBuilder: (value) => value
                            ? Icon(Icons.nightlight_round, color: Colors.white)
                            : Icon(Icons.wb_sunny, color: Colors.yellow[700]),
                        textBuilder: (value) => value
                            ? Center(child: Text('', style: TextStyle(color: Colors.white)))
                            : Center(child: Text('', style: TextStyle(color: Colors.black))),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 120,
                  child: _buildUserInfoSection(userProvider),
                ),
                SearchPanel(isDarkMode: _isDarkMode),
                Container(
                  height: 180,
                  child: buildWordCard((String text) => speak(text)),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.label, color: Colors.white),
                            SizedBox(width: 8),
                            Text("Kelime Setlerine Çalış"),
                          ],
                        ),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: colors["buttonBackground"],
                      onPrimary: colors["buttonText"],
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(double.infinity, 50),
                      elevation: 5,
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
                  child: Text(
                    "© PhD Akademi tarafından geliştirilmiştir.",
                    style: TextStyle(
                      fontSize: 14,
                      color: colors["text"],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            if (isExpanded)
              AnimatedOpacity(
                opacity: isExpanded ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isExpanded = false;
                      });
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          width: MediaQuery.of(context).size.width * 0.9,
                          margin: EdgeInsets.only(top: 60),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors["background"],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: colors["iconBackground"],
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                          child: Icon(Icons.library_books, color: colors["iconColor"], size: 28),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          "Kelime Setleri",
                                          style: GoogleFonts.nunito(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: colors["text"],
                                          ),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          isExpanded = false;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: colors["iconBackground"],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.close, color: colors["iconColor"], size: 28),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Expanded(
                                  child: PackageListWidget(
                                    packagesFuture: ApiService().fetchCategories(userProvider.userId),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(UserProvider userProvider) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors["background"],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors["shadowColor"] ?? Colors.grey,
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://kelibu.net/storage/${userProvider.avatar}'),
            backgroundColor: colors["avatarBackground"],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoşgeldiniz, ${userProvider.username}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors["text"]),
                ),
                SizedBox(height: 2),
                Text(
                  'Puanınız: ${userProvider.point}',
                  style: TextStyle(fontSize: 14, color: colors["text"]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: colors["iconColor"], size: 30),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkMode", isDarkMode);
  }


  Widget buildWordCard(Function(String) onSpeak) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return FutureBuilder<WordOfTheDay>(
      future: fetchWordOfTheDay(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors["background"],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors["shadowColor"] ?? Colors.grey,
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Günün Kelimesi',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors["text"],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (snapshot.data != null) {
                            onSpeak(snapshot.data!.term);
                          }
                        },
                        child: Icon(Icons.volume_up, color: colors["iconColor"], size: 24),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          snapshot.data?.term ?? 'Yükleniyor...',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors["text"],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    snapshot.data?.definition ?? 'Tanım yüklenemedi',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: colors["text"],
                    ),
                  ),
                  if (snapshot.data?.type != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Tip: ${snapshot.data!.type}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: colors["text"],
                        ),
                      ),
                    ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

class PackageListWidget extends StatefulWidget {
  final Future<List<Package>> packagesFuture;

  const PackageListWidget({Key? key, required this.packagesFuture}) : super(key: key);

  @override
  _PackageListWidgetState createState() => _PackageListWidgetState();
}

class _PackageListWidgetState extends State<PackageListWidget> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
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

    return FutureBuilder<List<Package>>(
      future: widget.packagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}", style: TextStyle(color: colors["text"])));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          var packages = snapshot.data!;
          return ListView.builder(
            itemCount: packages.length,
            itemBuilder: (context, index) {
              return _buildListItem(context, packages[index], colors);
            },
          );
        } else {
          return Center(child: Text("Kategori verisi yok", style: TextStyle(color: colors["text"])));
        }
      },
    );
  }

  Widget _buildListItem(BuildContext context, Package package, Map<String, Color> colors) {
    return InkWell(
      onTap: () => _onListItemTap(context, package.classroom?.id ?? 0, package.classroom?.title ?? 'Varsayılan Başlık'),
      child: Card(
        margin: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: colors["cardBackground"],
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: colors["iconBackground"],
            child: Icon(Icons.library_books, color: colors["iconColor"]),
          ),
          title: Text(
            package.classroom?.title ?? 'Varsayılan Başlık',
            style: GoogleFonts.poppins(
              color: colors["text"],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _onListItemTap(BuildContext context, int categoryId, String categoryName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 500));

    Navigator.of(context).pop();

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => WordListScreen(
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    ));
  }
}
class WordCard {
  final int id;
  final String? type;
  final String terim;
  final String tanim;

  WordCard({
    required this.id,
    this.type,
    required this.terim,
    required this.tanim,
  });

  factory WordCard.fromJson(Map<String, dynamic> json) {
    return WordCard(
      id: json['id'],
      type: json['type'],
      terim: json['terim'],
      tanim: json['tanim'],
    );
  }
}

class SearchPanel extends StatefulWidget {
  final bool isDarkMode;

  const SearchPanel({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _SearchPanelState createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  TextEditingController _searchController = TextEditingController();

  Future<void> searchWord(String term) async {
    final csvData = await rootBundle.loadString('assets/Model/words.csv');
    final converter = CsvToListConverter(eol: '\n');
    List<List<dynamic>> csvList = converter.convert(csvData);

    List<dynamic>? matchedWord;
    for (var row in csvList) {
      if (row[1] == term) {
        matchedWord = row;
        break;
      }
    }

    if (matchedWord != null) {
      WordDetail wordDetail = WordDetail(
        id: int.parse(matchedWord[0].toString()),
        word: matchedWord[1].toString(),
        meaning: matchedWord[2].toString(),
        type: matchedWord[4]?.toString(),
        image: matchedWord[3]?.toString(),
        collocations: [],
        derivations: [],
        synonyms: [],
      );

      List<WordDetail> allWords = [wordDetail];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LibraryDart(
            words: allWords,
            classroomId: 0,
            studySetId: 0,
          ),
        ),
      );
      await ApiService().fetchAndAttachCollocations(allWords);
      await ApiService().fetchAndAttachDerivations(allWords);
      await ApiService().fetchAndAttachSynonymsToWordDetail(allWords);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kelime bulunamadı')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.isDarkMode ? darkModeColors : lightModeColors;

    return Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors["background"],
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: colors["shadowColor"] ?? Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.library_books, color: colors["text"] ?? Colors.blueGrey, size: 30.0),
              SizedBox(width: 8.0),
              Text(
                'Kelibu Sözlük',
                style: GoogleFonts.nunito(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: colors["text"] ?? Colors.blueGrey,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Kelime ara...',
                    hintStyle: TextStyle(color: colors["text"] ?? Colors.black),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: colors["text"] ?? Colors.black),
                      onPressed: () {
                        searchWord(_searchController.text);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: colors["borderColor"] ?? Colors.grey),
                    ),
                  ),
                  onSubmitted: (value) {
                    searchWord(value);
                  },
                ),
              ),
              SizedBox(width: 8.0),
              IconButton(
                icon: Icon(Icons.clear, color: Colors.redAccent),
                onPressed: () {
                  _searchController.clear();
                },
              ),
            ],
          ),
          SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
