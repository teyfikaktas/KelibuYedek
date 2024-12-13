import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/providers/connectivity.dart';
import 'package:kelibu/providers/darkmodeprovider.dart';
import 'package:kelibu/providers/socket.dart';
import 'package:kelibu/providers/sub_provider.dart';
import 'package:kelibu/screens/advantages/books_pro.dart';
import 'package:kelibu/screens/betaprogram/beta_apply.dart';
import 'package:kelibu/screens/betaprogram/phdakademi.dart';
import 'package:kelibu/screens/connectivyplus.dart';
import 'package:kelibu/screens/connectivywrapper.dart';
import 'package:kelibu/screens/my_learn_path.dart';
import 'package:kelibu/screens/onboarding_screen.dart';
import 'package:kelibu/screens/src/self_english_beta.dart';
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
import 'package:logging/logging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late UserProvider userProviderGlobal;

void configureLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace:\n${record.stackTrace}');
    }
  });
}

// Uygulama verilerini temizleme fonksiyonu
Future<void> _clearAppData() async {
  try {
    // SharedPreferences temizle
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Secure Storage temizle
    final storage = FlutterSecureStorage();
    await storage.deleteAll();

    // Hive temizle
    await Hive.close();
    final appDir = await path_provider.getApplicationDocumentsDirectory();
    await appDir.delete(recursive: true);

    print('App data cleared successfully');
  } catch (e) {
    print('Error clearing app data: $e');
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    configureLogging();

    // Firebase başlatma
    // Hive başlatma
    final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDirectory.path);

    // Global state yönetimi
    userProviderGlobal = UserProvider();
    bool userLoaded = await userProviderGlobal.loadUser().timeout(
      Duration(seconds: 5),
      onTimeout: () {
        print("User loading timeout");
        return false;
      },
    );

    // Eğer user yüklenemezse, storage'ı temizle
    if (!userLoaded) {
      await _clearAppData();
    }

    runApp(MultiProvider(
      providers: [
        // Firebase servisini provider olarak ekle
        ChangeNotifierProvider(create: (_) => VIPAdvantagesPanelProvider()),
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
  } catch (e, stackTrace) {
    print('Initialization error: $e');
    print('Stack trace: $stackTrace');
    await _clearAppData();
    // Uygulamayı yeniden başlat
    runApp(const MyApp());
  }
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
          '/free-ebooks': (context) => KelibuProListWidget(),
          '/beta-apply': (context) => BetaApplicationPage(),
          '/home': (context) => MainScreen(),
          '/phd-academy-info': (context) => EgitimBasvuruPage(),
          '/self-english': (context) => SelfEnglishBetaApplicationPage(),
          '/race': (context) => RaceScreen(isVip: true,),
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

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _dataLoaded = false;
  bool _mounted = true;
  bool _isVideoInitialized = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _mounted) {
      _controller.play();
    } else if (state == AppLifecycleState.paused && _mounted) {
      _controller.pause();
    }
  }

  Future<void> _initializeApp() async {
    if (!_mounted) return;

    try {
      // Video player'ı başlat
      await _initializeVideoPlayer().timeout(
        Duration(seconds: 3),
        onTimeout: () {
          print("Video initialization timeout");
          throw TimeoutException('Video initialization timeout');
        },
      );

      // Verileri yükle
      await _loadData().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print("Data loading timeout");
          throw TimeoutException('Data loading timeout');
        },
      );
    } catch (e, stackTrace) {
      print("Initialization error: $e");
      print("Stack trace: $stackTrace");

      if (_mounted) {
        await _clearAppData();
        _handleInitializationError();
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (!_mounted) return;

    try {
      _controller = VideoPlayerController.asset('assets/splash_video.mp4');
      await _controller.initialize();

      if (_mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        await _controller.play();

        _controller.addListener(() {
          if (_controller.value.position >= _controller.value.duration) {
            _checkInternetAndNavigate();
          }
        });

        Future.delayed(const Duration(seconds: 4), () {
          if (_mounted && !_isNavigating) {
            _checkInternetAndNavigate();
          }
        });
      }
    } catch (e) {
      print("Video initialization error: $e");
      _handleInitializationError();
    }
  }

  void _handleInitializationError() {
    if (_mounted && !_isNavigating) {
      _checkInternetAndNavigate();
    }
  }

  Future<void> _loadData() async {
    try {
      await WordDataCache.loadAllData();
      if (_mounted) {
        setState(() {
          _dataLoaded = true;
        });
      }
    } catch (e) {
      print("Data load error: $e");
      throw e;  // Üst katmanda yakalanması için yeniden fırlat
    }
  }

  Future<void> _checkInternetAndNavigate() async {
    if (_isNavigating || !_mounted) return;
    _isNavigating = true;

    try {
      var internetChecker = InternetConnectionChecker();
      bool hasInternet = await internetChecker.isConnected();

      if (!_mounted) return;

      if (hasInternet) {
        await _checkOnboardingStatus();
      } else {
        _navigateToNoInternet();
      }
    } catch (e) {
      print("Internet check error: $e");
      _navigateToNoInternet();
    }
  }

  Future<void> _checkOnboardingStatus() async {
    if (!_mounted) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      if (!_mounted) return;

      if (onboardingComplete) {
        await _checkUser();
      } else {
        _navigateToOnboarding();
      }
    } catch (e) {
      print("Onboarding check error: $e");
      _navigateToOnboarding();
    }
  }

  Future<void> _checkUser() async {
    if (!_mounted) return;

    try {
      String? token = await _getToken();
      bool userLoaded = await userProviderGlobal.loadUser();

      if (!_mounted) return;

      if (token != null && token.isNotEmpty) {
        try {
          await _updateUserInfo();
          if (!_mounted) return;
          _navigateToMain();
        } catch (e) {
          print("User info update error: $e");
          _navigateToLogin();
        }
      } else if (!userLoaded) {
        _navigateToLogin();
      } else {
        await _updateUserInfo();
        if (!_mounted) return;
        _navigateToMain();
      }
    } catch (e, stackTrace) {
      print("User check error: $e");
      print("Stack trace: $stackTrace");
      await _clearAppData();  // Hata durumunda verileri temizle
      _navigateToLogin();
    }
  }

  Future<String?> _getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print("Token get error: $e");
      return null;
    }
  }

  Future<void> _updateUserInfo() async {
    if (!_mounted) return;

    try {
      int userId = userProviderGlobal.userId;
      String hash = await userProviderGlobal.getUsernameHash();

      Map<String, dynamic> userData = await ApiService().fetchUserPoint(userId);

      if (_mounted) {
        await userProviderGlobal.addPoint(userData['point']);
      }
    } catch (e) {
      print("User info update error: $e");
      throw e;
    }
  }

  void _navigateToMain() {
    if (!_mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen())
    );
  }

  void _navigateToLogin() {
    if (!_mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen())
    );
  }

  void _navigateToOnboarding() {
    if (!_mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnboardingScreen())
    );
  }

  void _navigateToNoInternet() {
    if (!_mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => NoInternetPage())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Center(
            child: _isVideoInitialized
                ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white),
                  VideoPlayer(_controller),
                ],
              ),
            )
                : Container(
              color: Colors.white,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mounted = false;
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    HomeScreen(),
    LeaderboardPage(),
    MarketPage(),
    StarredWordsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageTransitionSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> primaryAnimation, Animation<double> secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _pages[_selectedIndex],
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
            setState(() {
              _selectedIndex = index;
            });
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