import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/providers/connectivity.dart';
import 'package:kelibu/providers/darkmodeprovider.dart';
import 'package:kelibu/providers/socket.dart';
import 'package:kelibu/providers/sub_provider.dart';
import 'package:kelibu/screens/connectivyplus.dart';
import 'package:kelibu/screens/connectivywrapper.dart';
import 'package:kelibu/screens/my_learn_path.dart';
import 'package:kelibu/screens/onboarding_screen.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'providers/user_provider.dart';
import 'screens/market_store.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'providers/volume_provider.dart';
import 'providers/language_provider.dart';
import 'providers/starred_word_provider.dart';
import 'package:kelibu/screens/leader_screen.dart';
import 'package:kelibu/screens/home_screen_widgets/home_screen.dart';
import 'package:kelibu/screens/login_screen.dart';
import 'package:kelibu/screens/noInternetPage.dart';
import 'package:kelibu/screens/InternetConnectionCheckPage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late UserProvider userProviderGlobal;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);

  userProviderGlobal = UserProvider();
  await userProviderGlobal.loadUser();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SocketService()),
      ChangeNotifierProvider(create: (_) => userProviderGlobal),
      ChangeNotifierProvider(create: (_) => StarredWordsProvider()),
      ChangeNotifierProvider(create: (_) => VolumeProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => DarkModeProvider()),
      ChangeNotifierProvider<ConnectivityService>(create: (_) => ConnectivityService()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 690),
      builder: (context, child) => MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Kelibu',
        debugShowCheckedModeBanner: false,
        home: ConnectivityWrapper(child: SplashScreen()),
        routes: {
          '/noInternet': (context) => NoInternetPage(),
        },
        builder: (context, child) {
          return ConnectivityWrapper(child: child!);
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _dataLoaded = false;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _loadData();
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.asset('assets/splash_video.mp4')
      ..initialize().then((_) {
        if (_mounted) {
          setState(() {});
          _controller.play().then((_) {
            Future.delayed(const Duration(seconds: 4), _checkInternetAndNavigate);
          });
        }
      });
  }

  Future<void> _loadData() async {
    await WordDataCache.loadAllData();
    if (_mounted) {
      setState(() {
        _dataLoaded = true;
      });
      _checkInternetAndNavigate();
    }
  }

  void _checkInternetAndNavigate() async {
    if (!_dataLoaded || !_mounted) return;

    var internetChecker = InternetConnectionChecker();
    if (await internetChecker.isConnected()) {
      _checkOnboardingStatus();
    } else {
      if (_mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => NoInternetPage()));
      }
    }
  }

  void _checkOnboardingStatus() async {
    if (!_mounted) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (onboardingComplete) {
      _checkUser();
    } else {
      if (_mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OnboardingScreen()));
      }
    }
  }

  void _checkUser() async {
    if (!_mounted) return;
    bool userLoaded = await userProviderGlobal.loadUser();
    String? token = await _getToken();

    if (!_mounted) return;

    if (token != null && token.isNotEmpty) {
      try {
        await _updateUserInfo();
        if (!_mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
      } catch (error) {
        print("Kullanıcı bilgileri güncellenirken hata oluştu: $error");
        if (!_mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
      }
    } else if (!userLoaded) {
      if (!_mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
    } else {
      await _updateUserInfo();
      if (!_mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
    }
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _updateUserInfo() async {
    if (!_mounted) return;
    int userId = userProviderGlobal.userId;
    String hash = await userProviderGlobal.getUsernameHash();

    try {
      Map<String, dynamic> userData = await ApiService().fetchUserPoint(userId);
      int userPoint = userData['point'];
      if (_mounted) {
        await userProviderGlobal.addPoint(userPoint);
      }
    } catch (error) {
      print("Kullanıcı puanı güncellenirken hata oluştu: $error");
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(key: ValueKey('HomeScreen')),
    LeaderboardPage(key: ValueKey('LeaderboardPage')),
    MarketPage(key: ValueKey('MarketPage')),
    StarredWordsScreen(key: ValueKey('StarredWordsScreen')),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: Container(
          key: ValueKey<int>(_selectedIndex),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0F4FF), Color(0xFFE6EEFF)],
            ),
          ),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: SalomonBottomBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index != _selectedIndex) {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          items: [
            SalomonBottomBarItem(
              icon: Icon(Icons.home),
              title: Text("Ana Sayfa"),
              selectedColor: Color(0xFF3D5AFE),
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.leaderboard),
              title: Text("Sıralama"),
              selectedColor: Color(0xFF00BFA5),
            ),
            SalomonBottomBarItem(
              icon: FaIcon(FontAwesomeIcons.crown),
              title: Text("VIP Market"),
              selectedColor: Color(0xFFFFAB40),
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.star),
              title: Text("Favoriler"),
              selectedColor: Color(0xFFFF4081),
            ),
          ],
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}