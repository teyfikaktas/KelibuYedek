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
          '/self-english': (context) => KelibuProListWidget(),
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

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _videoInitialized = false;
  bool _mounted = true;
  final FlutterSecureStorage storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeSplash();
  }
  Future<void> _initializeSplash() async {
    await Future.wait([
      _initializeVideoPlayer(),
      _initializeAppInBackground(),
    ]);
  }

  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.asset('assets/splash_video.mp4');
    await _controller.initialize();
    if (_mounted) {
      setState(() => _videoInitialized = true);
      _controller.play();
    }
    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        _checkUserAndNavigate();
      }
    });
  }

  Future<void> _initializeAppInBackground() async {
    try {
      await WordDataCache.loadAllData();
      // Diğer arka plan yükleme işlemleri buraya eklenebilir
    } catch (e) {
      print('Background initialization error: $e');
    }
  }

  Future<void> _checkUserAndNavigate() async {
    if (!_mounted) return;

    String? token = await storage.read(key: 'access_token');
    if (token == null || token.isEmpty || await _isAccessTokenExpired()) {
      await _handleTokenExpiration();
    } else {
      try {
        await _updateUserInfo();
        if (_mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
        }
      } catch (error) {
        debugPrint("Kullanıcı bilgileri güncellenirken hata oluştu: $error");
        await _handleTokenExpiration();
      }
    }
  }
  Future<bool> _isAccessTokenExpired() async {
    try {
      String? expiresAtStr = await storage.read(key: 'expires_at');
      if (expiresAtStr == null) return true;
      int expiresAtMillis = int.parse(expiresAtStr);
      DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMillis);
      return DateTime.now().isAfter(expiresAt);
    } catch (e) {
      print('Token süresi kontrol edilirken hata oluştu: $e');
      return true;
    }
  }

  Future<void> _handleTokenExpiration() async {
    print('Token süresi doldu veya geçersiz, oturum kapatılıyor...');

    await storage.deleteAll();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Provider.of<UserProvider>(context, listen: false).logout();

    if (_mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            warning: 'Güvenliğiniz için tekrar giriş yapmanız gerekmektedir.',
          ),
        ),
      );
    }
  }

  Future<void> _updateUserInfo() async {
    if (!_mounted) return;
    int userId = Provider.of<UserProvider>(context, listen: false).userId;

    try {
      Map<String, dynamic> userData = await ApiService().fetchUserPoint(userId);
      int userPoint = userData['point'];
      if (_mounted) {
        await Provider.of<UserProvider>(context, listen: false).addPoint(userPoint);
      }
    } catch (error) {
      print("Kullanıcı puanı güncellenirken hata oluştu: $error");
      throw error;
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
      backgroundColor: Colors.white,
      body: Center(
        child: _videoInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : CircularProgressIndicator(),
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
