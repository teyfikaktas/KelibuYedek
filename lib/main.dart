import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/providers/connectivity.dart';
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
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  String csvContent = await rootBundle.loadString('assets/Model/words.csv');

  var connectivityService = ConnectivityService(); // Create an instance of ConnectivityService
  connectivityService.startMonitoring(); // Start monitoring the internet connection

  var userProvider = UserProvider();
  await userProvider.loadUser();
  EventBus eventBus = EventBus();

  // Uygulamayı MultiProvider ile başlatın
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => UserProvider()),
      ChangeNotifierProvider(create: (context) => StarredWordsProvider()),
      ChangeNotifierProvider(create: (context) => VolumeProvider()),
      ChangeNotifierProvider(create: (context) => LanguageProvider()),
      Provider<ConnectivityService>.value(value: connectivityService),
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
          // Video oynatıldıktan sonra 4 saniye bekleyip internet bağlantısını kontrol et
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
    bool userLoaded = await Provider.of<UserProvider>(context, listen: false).loadUser();
    if (!userLoaded) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
    } else {
      // Kullanıcı bilgileri başarılı bir şekilde yüklendiyse, API'den puanı çek
      int userId = Provider.of<UserProvider>(context, listen: false).userId;
      print('hash');
      String hash = await Provider.of<UserProvider>(context, listen: false).getUsernameHash();
      print(hash);

      int userPoint = await ApiService().fetchUserPoint(userId);
      print('checkuser');
      // Puanı Hive veritabanına kaydet
      await Provider.of<UserProvider>(context, listen: false).addPoint(userPoint);

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
  const MainScreen({super.key});

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

  // Sayfa oluşturmak için bir yöntem
  Widget _getPage(int index) {
    // Sadece liderlik ve öğrenme yolculuğu sayfaları için yeni bir instance oluştur
    if (index == 1) { // Liderlik sayfası index'i
      return const LeaderboardPage();
    } else if (index == 4) { // Öğrenme Yolculuğu sayfası index'i
      return const StarredWordsScreen();
    }

    // Diğer sayfalar için IndexedStack içinden sayfayı getir
    return _pages[index];
  }

  // IndexedStack yerine, sayfaların bir listesi
  final List<Widget> _pages = [
    const HomeScreen(),
    const Placeholder(), // Liderlik sayfası için yer tutucu
    MarketPage(),
    SettingsPage(),
    const Placeholder(), // Öğrenme Yolculuğu sayfası için yer tutucu
    // Diğer sayfalarınız burada listelenir
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _getPage(_selectedIndex), // IndexedStack yerine, seçilen sayfayı dinamik olarak getir
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white54,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Liderlik',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Mağaza',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Yıldızlarım',
          ),
          // Diğer sekmeler...
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        onTap: _onItemTapped,
      ),
    );
  }
}
