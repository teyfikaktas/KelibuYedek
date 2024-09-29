import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kelibu/screens/home_screen_widgets/phdakademiinfo.dart';
import 'package:kelibu/screens/market_store.dart';
import 'package:kelibu/screens/point/point.dart';
import 'package:kelibu/screens/settings_screen.dart';
import 'package:kelibu/screens/streak_widget.dart';
import 'package:kelibu/screens/study_screen.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/variables.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Models/category.dart';
import '../../Models/wordDetaik.dart';
import '../../globalDart/urls.dart';
import '../../providers/sub_provider.dart';
import '../../providers/user_provider.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/WordListScreen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../leader_screen.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';
import '../../providers/darkmodeprovider.dart';
import '../RaceScreen.dart';
import '../connectivywrapper.dart';
import 'soscial_media.dart';
import '../library_star.dart';
import '../loadingIndicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
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
                  padding: EdgeInsets.all(20.sp),
                  child: ScaleTransition(
                    scale: _animation,
                    child: Icon(
                      Icons.videogame_asset,
                      size: 60.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: AutoSizeText(
                    'Canlı Yarış',
                    style: GoogleFonts.pressStart2p(
                      textStyle: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    maxLines: 1,
                    minFontSize: 16,
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(8.sp),
                  height: 60.h,
                  width: 60.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.sp),
                    child: Image.asset('assets/logo.png'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30.sp),
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
      },
    );
  }
}
class WordOfTheDayService {
  static const String _lastFetchDateKey = 'last_fetch_date';
  static const String _lastWordKey = 'last_word';

  Future<WordOfTheDay> getWordOfTheDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchDate = prefs.getString(_lastFetchDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastFetchDate != today) {
      // Bugün henüz API çağrısı yapılmamış
      final newWord = await fetchWordOfTheDay();
      await _saveWordOfTheDay(newWord, today);
      return newWord;
    } else {
      // Bugün zaten API çağrısı yapılmış, kaydedilmiş kelimeyi kullan
      return _getSavedWordOfTheDay(prefs);
    }
  }

  Future<void> _saveWordOfTheDay(WordOfTheDay word, String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFetchDateKey, date);
    await prefs.setString(_lastWordKey, json.encode({
      'term': word.term,
      'definition': word.definition,
      'type': word.type,
    }));
  }

  WordOfTheDay _getSavedWordOfTheDay(SharedPreferences prefs) {
    final savedWordJson = prefs.getString(_lastWordKey);
    if (savedWordJson != null) {
      final decodedJson = json.decode(savedWordJson);
      return WordOfTheDay.fromJson(decodedJson);
    }
    throw Exception('No saved word of the day found');
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
  String promotionMessage = 'Yükleniyor...';

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
    checkSubscriptionStatus();

    _loadWordOfTheDay();
    _getPoint();
    _loadPromotionMessage();

    _loadDarkModePreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showWelcomeMessage(context);
    });
  }
  Future<void> checkSubscriptionStatus() async {
    SubscriptionProvider provider = Provider.of<SubscriptionProvider>(context, listen: false);
    await provider.fetchSubscriptionStatus();
  }
  Future<void> _loadPromotionMessage() async {
    try {
      String message = await ApiService().fetchPromotionMessage();
      setState(() {
        promotionMessage = message;
      });
    } catch (e) {
      setState(() {
        promotionMessage = 'Mesaj yüklenemedi';
      });
      print(e);
    }
  }
  void showWelcomeMessage(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(24.sp),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AutoSizeText(
                      "Kelibu'ya Hoş Geldiniz! 🎉",
                      style: GoogleFonts.nunito(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      minFontSize: 16,
                    ),
                    SizedBox(height: 20.h),
                    _buildInfoText(
                      "Kelime haznenizi genişletmeye hazır mısınız? Uzman kadrolarımızın titizlikle hazırladığı kelime setleri, sizi dil öğrenme macerasında bir Indiana Jones gibi hissettirmeye hazır!",
                    ),
                    SizedBox(height: 12.h),
                    _buildInfoText(
                      "Size özel bir sürprizimiz var: En popüler kelimelerimizi içeren Demo Set'i ücretsiz olarak hesabınıza tanımladık. Bu set, dil öğrenme yolculuğunuzda size pusula olacak!",
                    ),
                    SizedBox(height: 12.h),
                    _buildInfoText(
                      "Kelibu'yu nasıl en verimli şekilde kullanacağınızı merak ediyorsanız, her modun üstündeki sihirli soru işareti ikonuna tıklayın. Dil öğrenme gurusu Veysel Hoca size tüm püf noktaları anlatacak!",
                    ),
                    SizedBox(height: 12.h),
                    _buildInfoText(
                      "Öneri ve görüşleriniz bizim için altın değerinde! Ayarlar kısmından bize ulaşabilir, daha fazla bilgi için phdakademi.com adresini ziyaret edebilirsiniz.",
                    ),
                    SizedBox(height: 20.h),
                    AutoSizeText(
                      "Haydi, dil öğrenme maceranız başlasın! 🚀",
                      style: GoogleFonts.nunito(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      minFontSize: 14,
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      child: Text("Maceraya Başla!"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.blue[700],
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      await prefs.setBool('isFirstTime', false);
    }
  }
  Widget _buildInfoText(String text) {
    return AutoSizeText(
      text,
      style: GoogleFonts.nunito(fontSize: 14.sp, color: Colors.blue[900]),
      textAlign: TextAlign.center,
      maxLines: 4,
      minFontSize: 10,
    );
  }
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
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
              LogoLoadingIndicator(),
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
    WordOfTheDay? cachedWord = await WordOfTheDayCache.getCachedWordOfTheDay();
    if (cachedWord != null) {
      setState(() {
        _wordOfTheDay = cachedWord;
      });
    } else {
      try {
        _wordOfTheDay = await fetchWordOfTheDay();
        await WordOfTheDayCache.cacheWordOfTheDay(_wordOfTheDay!);
      } catch (error) {
        print('API Error: $error');
        _wordOfTheDay = await _loadWordFromPrefs();
      }
    }
    if (mounted) setState(() {});
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
  late AnimationController _controller;
  late Animation<double> _animation;
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


    try {
      Map<String, dynamic> userData = await ApiService().fetchUserPoint(currentUserId);

      setState(() {
        userProvider.addPoint(userData['point']);
        userProvider.updateUserAvatarUrl(userData['avatar']);
        userProvider.updateRankings(
          streakCount: userData['streakCount'], // Burayı değiştirdik
          dailyRank: userData['dailyRank'] is int ? userData['dailyRank'] as int : 0,
          weeklyRank: userData['weeklyRank'],
          monthlyRank: userData['monthlyRank'],
          allTimeRank: userData['allTimeRank'],
        );

      });
    } catch (error) {
      print("Error fetching user data: $error");
    }
    String hash = await userProvider.getUsernameHash();
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
    final darkModeProvider = Provider.of<DarkModeProvider>(context);
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ConnectivityWrapper(
          child: Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return Scaffold(
                backgroundColor: colors["background"],
                body: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Spacer(),
                              ],
                            ),
                          ),
                          Container(
                            height: 200.h,
                            child: _buildUserInfoSection(userProvider),
                          ),
                          StreakWidget(
                            streakCount: userProvider.streakCount,
                            dailyRank: userProvider.dailyRank,
                            monthlyRank: userProvider.monthlyRank,
                            weeklyRank: userProvider.weeklyRank,
                            allTimeRank: userProvider.allTimeRank,
                          ),
                          LearningPanel(
                            isDarkMode: _isDarkMode,
                            onWordSetsTap: () {
                              setState(() {
                                isExpanded = true;
                              });
                            },
                            onWordOfDayTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return WordOfTheDayDialog(
                                    isDarkMode: _isDarkMode,
                                    onSpeak: speak,
                                  );
                                },
                              );
                            },
                            onDictionaryTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return SearchDialog(isDarkMode: _isDarkMode);
                                },
                              );
                            },
                          ),
                          Container(
                            padding: EdgeInsets.all(16.sp),
                            decoration: BoxDecoration(
                              color: _isDarkMode ? Colors.grey[850] : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _isDarkMode
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                RefinedSocialMediaInfo(),
                                SizedBox(height: 16.h),
                                _buildPromoBanner(),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                    if (isExpanded)
                      if (isExpanded)
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: MediaQuery.of(context).size.height * 0.9,
                          decoration: BoxDecoration(
                            color: _isDarkMode ? Color(0xFF1F1F1F) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildDraggableHeader(),
                              _buildWordSetsHeader(),
                              Expanded(
                                child: _buildWordSetsList(),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  Widget _buildDraggableHeader() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 10) {
          setState(() {
            isExpanded = false;
          });
        }
      },
      child: Container(
        height: 40,
        child: Center(
          child: Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildWordSetsHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF1F1F1F) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(-20 * (1 - value), 0),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF58CC02),
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Kelime Setleriniz",
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Color(0xFF3C3C3C),
                      ),
                    ),
                  ],
                ),
              ),
              _buildCloseButton(),
            ],
          ),
          SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              "Öğrenmeye hazır mısınız? Hadi başlayalım!",
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCloseButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300),
      builder: (context, double value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: child,
          ),
        );
      },
      child: IconButton(
        icon: Icon(
          Icons.close_rounded,
          color: _isDarkMode ? Colors.white70 : Color(0xFF58CC02),
          size: 28,
        ),
        onPressed: () {
          setState(() {
            isExpanded = false;
            _fetchData();
          });
        },
      ),
    );
  }
  Widget _buildWordSetsList() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return FutureBuilder<List<Package>>(
          future: ApiService().fetchCategories(userProvider.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: LogoLoadingIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Hata: ${snapshot.error}"));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return _buildWordSetItem(snapshot.data![index], index);
                },
              );
            } else {
              return _buildEmptyState();
            }
          },
        );
      },
    );
  }
  Widget _buildWordSetItem(Package package, int index) {
    final List<Color> colors = [
      Color(0xFF58CC02),
      Color(0xFF1CB0F6),
      Color(0xFFFFC800),
      Color(0xFFFF9600),
      Color(0xFFFF4B4B),
    ];
    final color = colors[index % colors.length];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0), // Burayı değiştirdik
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _onListItemTap(context, package.classroom?.id ?? 0, package.classroom?.title ?? 'Varsayılan Başlık'),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.school,
                  size: 100,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.classroom?.title ?? 'Varsayılan Başlık',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),

                    SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: 0.7, // İlerleme durumunu buraya ekleyin
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: 80,
            color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            "Henüz kelime setiniz yok",
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Yeni setler ekleyerek öğrenmeye başlayın!",
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: _isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  void _onListItemTap(BuildContext context, int categoryId, String categoryName) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => WordListScreen(
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    ));
  }
  Widget _buildPromoBanner() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            Icons.celebration,
            color: _isDarkMode ? Colors.green[300] : Colors.green,
            size: 24.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: AutoSizeText(
              promotionMessage, // API'den gelen veya önbellekteki mesaj burada gösterilecek
              style: GoogleFonts.poppins(
                color: _isDarkMode ? Colors.green[300] : Colors.green.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
              maxLines: 2,
              minFontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildWebsiteLink() {

    return Column(
      children: [
        Text(
          "Daha fazlası ve güncel eğitimler için:",
          style: GoogleFonts.poppins(
            color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            fontWeight: FontWeight.w400,
            fontSize: 8.sp,
          ),
        ),
        SizedBox(height: 4.h),
        ElevatedButton(
          onPressed: () => _launchURL('https://phdakademi.com'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDarkMode ? Colors.blue.shade800 : Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          ),
          child: Text(
            "phdakademi.com",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 10.sp,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildSocialMediaButton({
    required String icon,
    required String username,
    required VoidCallback onTap,
    required MaterialColor color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: _isDarkMode ? color[900] : color[50],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              width: 12.w,
              height: 12.h,
              color: _isDarkMode ? color[200] : color[700],
            ),
            SizedBox(width: 4.w),
            Text(
              username,
              style: GoogleFonts.poppins(
                color: _isDarkMode ? color[200] : color[700],
                fontWeight: FontWeight.w500,
                fontSize: 7.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _launchPhdAkademiInstagram() async {
    const url = 'https://www.instagram.com/phd.akademi/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
  void _launchInstagram() async {
    const url = 'https://www.instagram.com/kelibunet/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
      // Burada kullanıcıya bir hata mesajı gösterebilirsiniz
    }
  }
  void _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
  Widget _buildUserInfoSection(UserProvider userProvider) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Container(
      margin: EdgeInsets.all(12.sp),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: colors["background"],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors["shadowColor"] ?? Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAvatarWithName(context, userProvider), // Hem context hem de userProvider geçirin
              PointsDisplay(points: 1111111,),
            ],
          ),
          SizedBox(height: 3.h),
          _buildActionButtons(),
          SizedBox(height: 3.h),
          PhdAkademiInfo(isDarkMode:_isDarkMode ,),
        ],
      ),
    );
  }


  Widget _buildAvatarWithName(BuildContext context, UserProvider userProvider) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        bool isSubscribed = subscriptionProvider.isVip;
        return Row(
          children: [
            GestureDetector(
              onTap: () => _showEnlargedAvatar(userProvider.avatar),
              child: Hero(
                tag: 'avatar',
                child: Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSubscribed ? Colors.amber : Colors.green,
                      width: isSubscribed ? 3.0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: 'https://kelibu.net/storage/${userProvider.avatar}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => LogoLoadingIndicator(),
                      errorWidget: (context, url, error) => FaIcon(FontAwesomeIcons.userCircle, size: 25.sp),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userProvider.username,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 4.h),
                if (isSubscribed)
                  Row(
                    children: [
                      Text(
                        "Kelibu",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          "PRO",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MarketPage()),
                      );
                    },
                    child: Text('Hemen VIP ol!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double totalWidth = constraints.maxWidth * 0.8;
        double maxIconSize = 70;
        double minSpacing = 8;

        double iconSize = (totalWidth - (4 * minSpacing)) / 5; // 5 ikon için ayarlandı
        iconSize = iconSize > maxIconSize ? maxIconSize : iconSize;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRoundedIconButton(FontAwesomeIcons.cog, Colors.blue, () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => SettingsPage()));
            }, size: iconSize),
            _buildRoundedIconButton(
                _isDarkMode ? FontAwesomeIcons.moon : FontAwesomeIcons.sun,
                _isDarkMode ? Colors.indigo : Colors.orange,
                _toggleDarkMode,
                size: iconSize
            ),
            _buildRoundedIconButton(FontAwesomeIcons.playCircle, Colors.green, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.homescreen)),
              );
            }, size: iconSize),
            _buildRoundedIconButton(FontAwesomeIcons.shareAlt, Colors.purple, _shareApp, size: iconSize),
            _buildRoundedIconButton(FontAwesomeIcons.search, Colors.teal, () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SearchDialog(isDarkMode: _isDarkMode);
                },
              );
            }, size: iconSize),
          ],
        );
      },
    );
  }

  Widget _buildRoundedIconButton(IconData icon, Color color, VoidCallback onPressed, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: FaIcon(icon, size: size * 0.5, color: color),
          ),
        ),
      ),
    );
  }
  void _shareApp() {
    final String message = """
🚀 Kelibu ile kelime haznenizi genişletin! 🧠💪

Her gün yeni kelimeler öğrenin, eğlenceli quizler çözün ve dil becerilerinizi geliştirin. 📚✨

📱 Kelibu'yu hemen indirin ve kelime dünyasına dalın! 🌊

🍎 iOS kullanıcıları için: 
   Elmanızı bilgiyle parlatın! 🍏✨
   https://apps.apple.com/tr/app/kelibu/id6484268631

🤖 Android severler için:
   Robotunuzu kelimelerle programlayın! 🦾📚
   https://play.google.com/store/apps/details?id=com.phdakademi.kelibu

💻 Web'de takılanlar için:
   Tarayıcınızı bir kelime makinesine dönüştürün! 🕸️📖
   Kelibu.net

Hadi, birlikte öğrenelim ve büyüyelim! 🌟🎉
Kelime öğrenmenin tadını Kelibu ile çıkarın! 🍭📗
  """;

    Share.share(message, subject: 'Kelibu - Eğlenceli Kelime Öğrenme Macerası!');
  }
  void _showEnlargedAvatar(String avatarUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Hero(
              tag: 'avatar',
              child: Image.network(
                'https://kelibu.net/storage/$avatarUrl',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
  void _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('darkMode') ?? false;

    setState(() {
      _isDarkMode = !isDarkMode;
    });

    await prefs.setBool('darkMode', _isDarkMode);
  }
  Widget buildWordOfTheDayButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return WordOfTheDayDialog(
              isDarkMode: _isDarkMode,
              onSpeak: speak,
            );
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb, color: Colors.white, size: 24.sp),
            SizedBox(width: 2.w),
            Text(
              "Günün Kelimesi",
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class PackageListWidget extends StatelessWidget {
  final Future<List<Package>> packagesFuture;

  const PackageListWidget({Key? key, required this.packagesFuture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Package>>(
      future: packagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: LogoLoadingIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}"));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildPackageItem(context, snapshot.data![index]);
            },
          );
        } else {
          return Center(child: Text("Kategori verisi yok"));
        }
      },
    );
  }
  Widget _buildPackageItem(BuildContext context, Package package) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        leading: Icon(Icons.book, color: Colors.white, size: 30.sp),
        title: Text(
          package.classroom?.title ?? 'Varsayılan Başlık',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: () => _onListItemTap(context, package.classroom?.id ?? 0, package.classroom?.title ?? 'Varsayılan Başlık'),
      ),
    );
  }

  void _onListItemTap(BuildContext context, int categoryId, String categoryName) {
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
class SearchPanel extends StatelessWidget {
  final bool isDarkMode;

  const SearchPanel({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SearchDialog(isDarkMode: isDarkMode);
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF3A3A3C) : Color(0xFF58CC02),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, color: isDarkMode ? Colors.grey[300] : Colors.white, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              "Sözlük",
              style: GoogleFonts.nunito(
                color: isDarkMode ? Colors.grey[300] : Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class SearchDialog extends StatefulWidget {
  final bool isDarkMode;

  const SearchDialog({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _SearchDialogState createState() => _SearchDialogState();
}
class _SearchDialogState extends State<SearchDialog> {
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchError = '';
  WordDetail? _searchResult;
  FocusNode _searchFocusNode = FocusNode();
  bool _showSearchPanel = true;

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 20.w, top: 65.h, right: 20.w, bottom: 20.h),
          margin: EdgeInsets.only(top: 45.h),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: widget.isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Kelime Ara",
                    style: GoogleFonts.nunito(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: widget.isDarkMode ? Colors.white : Color(0xFF4B4B4B),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: widget.isDarkMode ? Colors.white : Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              if (_showSearchPanel) _buildSearchPanel() else _buildResultPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPanel() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontSize: 18.sp,
          ),
          decoration: InputDecoration(
            hintText: "Kelime girin...",
            hintStyle: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.grey[600],
              fontSize: 18.sp,
            ),
            filled: true,
            fillColor: widget.isDarkMode ? Color(0xFF2C2C2E) : Color(0xFFF0F0F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.search, color: Color(0xFF58CC02), size: 24.sp),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear, color: widget.isDarkMode ? Colors.white70 : Colors.grey[600]),
              onPressed: () {
                _searchController.clear();
              },
            ),
          ),
          onSubmitted: (term) => performSearch(term),
          textInputAction: TextInputAction.search,
        ),
        SizedBox(height: 15.h),
        if (_searchError.isNotEmpty)
          Text(
            _searchError,
            style: TextStyle(color: Colors.red, fontSize: 16.sp),
          ),
        SizedBox(height: 25.h),
        ElevatedButton(
          child: _isSearching
              ? SizedBox(
            width: 20.w,
            height: 20.h,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Text(
            "Ara",
            style: GoogleFonts.nunito(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF58CC02),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
            elevation: 0,
          ),
          onPressed: _isSearching ? null : () => performSearch(_searchController.text),
        ),
      ],
    );
  }

  Widget _buildResultPanel() {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Color(0xFF2C2C2E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_searchResult!.word}",
                style: GoogleFonts.nunito(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: widget.isDarkMode ? Colors.white : Color(0xFF4B4B4B),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: widget.isDarkMode ? Colors.white70 : Colors.grey[600]),
                onPressed: () {
                  setState(() {
                    _showSearchPanel = true;
                    _searchResult = null;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            "${_searchResult!.meaning}",
            style: GoogleFonts.nunito(
              fontSize: 18.sp,
              color: widget.isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          SizedBox(height: 20.h),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.celebration, color: Colors.white),
              label: Text(
                "Detaylı Keşfet!",
                style: GoogleFonts.nunito(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                elevation: 0,
              ),
              onPressed: () => _navigateToWordDetail(_searchResult!),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> performSearch(String term) async {
    if (term.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      final apiService = ApiService();
      final searchResult = await apiService.searchWord(term);

      if (searchResult != null) {
        setState(() {
          _searchResult = searchResult;
          _showSearchPanel = false;
        });
      } else {
        setState(() {
          _searchError = 'Kelime bulunamadı';
        });
      }
    } catch (e) {
      setState(() {
        _searchError = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _navigateToWordDetail(WordDetail word) async {
    final apiService = ApiService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      List<int> wordIds = [word.id];
      List<WordDetail> detailedWords = await apiService.fetchWordsDetail(wordIds);

      if (detailedWords.isNotEmpty) {
        WordDetail detailedWord = detailedWords.first;
        print("Detailed word loaded:");
        print("Synonyms: ${detailedWord.synonyms.length}");
        print("Collocations: ${detailedWord.collocations.length}");
        print("Derivations: ${detailedWord.derivations.length}");

        Navigator.of(context).pop(); // Loading dialog'u kapat

        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => StudyScreen(
            words: [detailedWord],
            classroomId: 0,
            studySetId: 0,
            isStarred: true,
          ),
        ));
      } else {
        throw Exception('Detaylı kelime bilgisi bulunamadı.');
      }
    } catch (e) {
      print("Error loading word details: $e");
      Navigator.of(context).pop(); // Loading dialog'u kapat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kelime detayları yüklenirken bir hata oluştu.')),
      );
    }
  }
}
class WordOfTheDayCache {
  static const String _keyWord = 'word_of_the_day';
  static const String _keyDefinition = 'definition_of_the_day';
  static const String _keyType = 'type_of_the_day';
  static const String _keyImage = 'image_of_the_day';
  static const String _keyLastFetchDate = 'last_fetch_date';

  static Future<void> cacheWordOfTheDay(WordOfTheDay word) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWord, word.term);
    await prefs.setString(_keyDefinition, word.definition);
    if (word.type != null) {
      await prefs.setString(_keyType, word.type!);
    }
    await prefs.setString(_keyLastFetchDate, DateTime.now().toIso8601String());
  }

  static Future<WordOfTheDay?> getCachedWordOfTheDay() async {
    final prefs = await SharedPreferences.getInstance();
    final term = prefs.getString(_keyWord);
    final definition = prefs.getString(_keyDefinition);
    final type = prefs.getString(_keyType);
    final lastFetchDate = prefs.getString(_keyLastFetchDate);

    if (term != null && definition != null && lastFetchDate != null) {
      final fetchDate = DateTime.parse(lastFetchDate);
      if (DateTime.now().difference(fetchDate).inDays < 1) {
        return WordOfTheDay(term: term, definition: definition, type: type);
      }
    }
    return null;
  }

  static Future<void> cacheImage(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyImage, imageUrl);
  }

  static Future<String?> getCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyImage);
  }
}
class WordOfTheDayDialog extends StatelessWidget {
  final bool isDarkMode;
  final Function(String) onSpeak;

  const WordOfTheDayDialog({
    Key? key,
    required this.isDarkMode,
    required this.onSpeak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      child: ContentBox(isDarkMode: isDarkMode, onSpeak: onSpeak),
    );
  }
}
class ContentBox extends StatelessWidget {
  final bool isDarkMode;
  final Function(String) onSpeak;

  const ContentBox({
    Key? key,
    required this.isDarkMode,
    required this.onSpeak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 20.w, top: 65.h + 20.h, right: 20.w, bottom: 20.h),
          margin: EdgeInsets.only(top: 45.h),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: FutureBuilder<WordOfTheDay>(
            future: fetchWordOfTheDay(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: LogoLoadingIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Hata oluştu'));
              } else if (snapshot.hasData) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      snapshot.data!.term,
                      style: GoogleFonts.nunito(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Text(
                      snapshot.data!.definition,
                      style: GoogleFonts.nunito(
                        fontSize: 16.sp,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => onSpeak(snapshot.data!.term),
                          child: Icon(Icons.volume_up, color: Colors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(15),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _navigateToWordDetail(context, snapshot.data!),
                          child: Text(
                            "Detaylı Keşfet!",
                            style: GoogleFonts.nunito(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Center(child: Text('Veri bulunamadı'));
              }
            },
          ),
        ),
        Positioned(
          left: 20.w,
          right: 20.w,
          child: CircleAvatar(
            backgroundColor: Colors.green,
            radius: 45.h,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(45.h)),
              child: Icon(Icons.lightbulb, color: Colors.white, size: 50.sp),
            ),
          ),
        ),
        Positioned(
          right: -10.w,
          top: -10.h,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(4.sp),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: isDarkMode ? Colors.white : Colors.black,
                size: 20.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToWordDetail(BuildContext context, WordOfTheDay word) {
    WordDetail wordDetail = WordDetail(
      id: 0, // Günün kelimesi için özel bir ID oluşturabilirsiniz
      word: word.term,
      meaning: word.definition,
      type: word.type,
      image: null, // Eğer varsa, günün kelimesinin resmini ekleyebilirsiniz
      collocations: [],
      derivations: [],
      synonyms: [],
    );

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => StudyScreen(
        words: [wordDetail],
        classroomId: 0,
        studySetId: 0,
        isStarred: true,
      ),
    ));
  }
}
class LearningPanel extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onWordOfDayTap;
  final VoidCallback onWordSetsTap;
  final VoidCallback onDictionaryTap;

  const LearningPanel({
    Key? key,
    required this.isDarkMode,
    required this.onWordOfDayTap,
    required this.onWordSetsTap,
    required this.onDictionaryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          WordSetsButton(onTap: onWordSetsTap, isDarkMode: isDarkMode),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.3),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28.sp),
                SizedBox(height: 8.h),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WordSetsButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDarkMode;

  WordSetsButton({required this.onTap, required this.isDarkMode});

  @override
  _WordSetsButtonState createState() => _WordSetsButtonState();
}

class _WordSetsButtonState extends State<WordSetsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Animation Controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Tap Animations
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _shadowAnimation = Tween<double>(begin: 8.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Entrance Animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Start entrance animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse(); // Scale down on tap down
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward(); // Scale up on tap up
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing using MediaQuery
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define relative sizes
    final double paddingHorizontal = screenWidth * 0.05; // %5 of screen width
    final double paddingVertical = screenHeight * 0.01; // %1 of screen height
    final double containerHeight = screenHeight * 0.1; // %10 of screen height
    final double iconSize = screenWidth * 0.07; // %7 of screen width
    final double titleFontSize = screenWidth * 0.045; // %4.5 of screen width
    final double subtitleFontSize = screenWidth * 0.035; // %3.5 of screen width
    final double arrowIconSize = screenWidth * 0.06; // %6 of screen width

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: paddingHorizontal, vertical: paddingVertical),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onTap,
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: () => _controller.forward(),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      height: containerHeight,
                      decoration: BoxDecoration(
                        color: widget.isDarkMode
                            ? Color(0xFF1CB0F6)
                            : Color(0xFF58CC02),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Color(0xFF45A800),
                            blurRadius: _shadowAnimation.value,
                            offset:
                            Offset(0, _shadowAnimation.value / 2),
                          ),
                        ],
                        border: Border.all(
                          color: widget.isDarkMode
                              ? Colors.lightBlueAccent.withOpacity(0.5)
                              : Color(0xFF45A800),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: iconSize,
                                ),
                                SizedBox(width: screenWidth * 0.04),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Kelime Setleri",
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2,
                                            color: Colors.black
                                                .withOpacity(0.3),
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      "Keşfet ve Öğren!",
                                      style: GoogleFonts.nunito(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: subtitleFontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                            EdgeInsets.only(right: screenWidth * 0.05),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: arrowIconSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class ActionButton {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  ActionButton({required this.icon, required this.color, required this.onPressed});
}
class ActionButtons extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleDarkMode;
  final VoidCallback shareApp;

  const ActionButtons({
    Key? key,
    required this.isDarkMode,
    required this.toggleDarkMode,
    required this.shareApp,
  }) : super(key: key);

  List<ActionButton> _getButtons(BuildContext context) => [
    ActionButton(
      icon: FontAwesomeIcons.gear,
      color: Colors.blue,
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => SettingsPage())),
    ),
    ActionButton(
      icon: isDarkMode ? FontAwesomeIcons.moon : FontAwesomeIcons.sun,
      color: isDarkMode ? Colors.indigo : Colors.orange,
      onPressed: toggleDarkMode,
    ),
    ActionButton(
      icon: FontAwesomeIcons.playCircle,
      color: Colors.green,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.homescreen)),
      ),
    ),
    ActionButton(
      icon: FontAwesomeIcons.shareNodes,
      color: Colors.purple,
      onPressed: shareApp,
    ),
    ActionButton(
      icon: FontAwesomeIcons.magnifyingGlass,
      color: Colors.teal,
      onPressed: () => showDialog(
        context: context,
        builder: (BuildContext context) => SearchDialog(isDarkMode: isDarkMode),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final buttons = _getButtons(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double maxIconSize = 70.w;
        final double minSpacing = 8.w;

        double iconSize = (totalWidth - (buttons.length - 1) * minSpacing) / buttons.length;
        iconSize = iconSize.clamp(0, maxIconSize);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: buttons.map((button) => _buildAnimatedButton(button, iconSize)).toList(),
        );
      },
    );
  }

  Widget _buildAnimatedButton(ActionButton button, double size) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: button.color.withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: button.color.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: CircleBorder(),
          onTap: button.onPressed,
          child: Center(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: FaIcon(
                button.icon,
                key: ValueKey<IconData>(button.icon),
                size: size * 0.5,
                color: button.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
