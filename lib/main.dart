import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/providers/connectivity.dart';
import 'package:kelibu/providers/darkmodeprovider.dart';
import 'package:kelibu/providers/socket.dart';
import 'package:kelibu/screens/RaceScreen.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'providers/user_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/market_store.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kelibu/screens/my_learn_path.dart';
import 'providers/volume_provider.dart';
import 'providers/language_provider.dart';
import 'providers/starred_word_provider.dart';
import 'package:kelibu/screens/leader_screen.dart'; // Liderlik tablosu sayfası
import 'package:kelibu/screens/home_screen.dart'; // Ana sayfa ekranı
import 'package:kelibu/screens/login_screen.dart'; // Ana sayfa ekranı
import 'package:kelibu/screens/noInternetPage.dart'; // Ana sayfa ekranı
import 'package:kelibu/screens/InternetConnectionCheckPage.dart'; // Ana sayfa ekranı
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:kelibu/screens/classic_kelibu.dart'; // Liderlik tablosu sayfası
import 'package:kelibu/screens/settings_screen.dart'; // Liderlik tablosu sayfası
import 'package:event_bus/event_bus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart'; // Animasyonlu alt navigasyon çubuğu paketi

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
UserProvider? userProviderGlobal;
EventBus eventBus = EventBus();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  String csvContent = await rootBundle.loadString('assets/Model/words.csv');

  userProviderGlobal = UserProvider();
  await userProviderGlobal?.loadUser();

  // Uygulamayı MultiProvider ile başlatın
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SocketService()),
      ChangeNotifierProvider(create: (context) => userProviderGlobal),
      ChangeNotifierProvider(create: (context) => StarredWordsProvider()),
      ChangeNotifierProvider(create: (context) => VolumeProvider()),
      ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ChangeNotifierProvider(create: (context) => DarkModeProvider()),

    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 690),
      builder: (context, child) => MaterialApp(
        navigatorKey: navigatorKey, // Use the global navigator key
        title: 'Kelibu',
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/noInternet': (context) => NoInternetPage(), // Define no internet page route
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/splash_video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller!.play().then((_) {
          Future.delayed(const Duration(seconds: 4), () {
            _checkInternetAndNavigate();
          });
        });
      });
  }

  void _checkInternetAndNavigate() async {
    var internetChecker = InternetConnectionChecker();
    if (await internetChecker.isConnected()) {
      _checkUser();
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => NoInternetPage()));
    }
  }

  void _checkUser() async {
    // Provider'ı context'ten almak yerine, userProviderGlobal'i kullanın
    bool userLoaded = await userProviderGlobal!.loadUser();
    if (!userLoaded) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
    } else {
      int userId = userProviderGlobal!.userId;
      print('hash');
      String hash = await userProviderGlobal!.getUsernameHash();
      print(hash);

      try {
        Map<String, dynamic> userData = await ApiService().fetchUserPoint(userId);
        int userPoint = userData['point'];
        print('User Point: $userPoint');
        await userProviderGlobal!.addPoint(userPoint);
      } catch (error) {
        print("Error fetching user point: $error");
      }
      print('checkuser');

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
    }
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: Colors.white, // Beyaz arka plan rengi
          child: Center(
            child: _controller!.value.isInitialized
                ? AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            )
                : const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

Future<void> _clearSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  print("Tüm SharedPreferences verileri silindi.");
}


class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  final iconList = <IconData>[
    Icons.home,
    Icons.leaderboard,
    Icons.store,
    Icons.star,
  ];

  final List<Widget> _pages = [
    HomeScreen(),
    const LeaderboardPage(),
    MarketPage(),
    const StarredWordsScreen(),
  ];

  Widget _getPage(int index) {
    return _pages[index];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }
  @override
  Widget build(BuildContext context) {
    final darkModeProvider = Provider.of<DarkModeProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFF212121), // Daha hafif bir siyah ton
      body: _getPage(_selectedIndex),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => RaceScreenBuild(),
          ));
        },
        child: Icon(Icons.videogame_asset, color: Colors.white),
        backgroundColor: Colors.grey[850],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: _selectedIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.smoothEdge,
        backgroundColor: Colors.grey[850],
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        activeColor: Colors.white,
        inactiveColor: Colors.grey,
        splashColor: Colors.white,
        onTap: (index) => _onItemTapped(index),
      ),
    );
  }

}