import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as providerp;
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:kelibu/routes/race/app_routes.dart';
import 'package:kelibu/screens/race/core/services/RoomService.dart';
import 'package:purchases_flutter/models/purchases_configuration.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late UserProvider userProviderGlobal;


Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // iOS için özel kontroller
  if (Platform.isIOS) {
    try {
      // APNS token'ı bekle
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      print('APNS Token: $apnsToken');

      // Eğer APNS token null ise biraz bekle ve tekrar dene
      if (apnsToken == null) {
        await Future.delayed(Duration(seconds: 2));
        final retryToken = await FirebaseMessaging.instance.getAPNSToken();
        print('Retry APNS Token: $retryToken');
      }
    } catch (e) {
      print('APNS token error: $e');
    }
  }

  // İzinleri iste
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false, // iOS için geçici izin
  );

  print('User granted permission: ${settings.authorizationStatus}');

  // FCM token'ı al
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
  } catch (e) {
    print('Error getting FCM token: $e');
  }

  // Ön planda bildirim dinleyicisi
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    }
  });
  try {
    await FirebaseMessaging.instance.subscribeToTopic('announcements');
    print('Topic aboneliği başarılı');
  } catch (e) {
    print('Topic aboneliği hatası: $e');
  }
  // Arka planda bildirim dinleyicisi
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

// Arka plan mesaj işleyici
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("Handling a background message: ${message.messageId}");
}
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

Future<void> _clearAppData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final storage = FlutterSecureStorage();
    await storage.deleteAll();

    await Hive.close();
    final appDir = await path_provider.getApplicationDocumentsDirectory();
    await appDir.delete(recursive: true);

    print('App data cleared successfully');
  } catch (e) {
    print('Error clearing app data: $e');
  }
}
Future<void> initializeOneSignal() async {
  try {
    // Enable OneSignal debugging
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize OneSignal
    OneSignal.initialize("1b7644ee-9086-4bdc-aa32-1071c7b0b0ad");

    // Request notification permissions with proper error handling
    bool allowed = await OneSignal.Notifications.requestPermission(true)
        .timeout(
      Duration(seconds: 10),
      onTimeout: () {
        print('OneSignal permission request timed out');
        return false;
      },
    );

    print('Notification permission allowed: $allowed');

    // Add delay before checking subscription status
    await Future.delayed(Duration(seconds: 2));

    // Get and log detailed subscription status
    final pushSubscription = OneSignal.User.pushSubscription;
    print('Detailed Push Subscription Status:');
    print('- Token: ${pushSubscription.token}');
    print('- OptedIn: ${pushSubscription.optedIn}');
    print('- ID: ${pushSubscription.id}');

    // Set up notification handlers
    OneSignal.Notifications.addClickListener((event) {
      print('Notification clicked:');
      print('- Title: ${event.notification.title}');
      print('- Body: ${event.notification.body}');
      print('- Additional Data: ${event.notification.additionalData}');
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('Notification received in foreground:');
      print('- Title: ${event.notification.title}');
      print('- Body: ${event.notification.body}');
      event.notification.display();
    });

  } catch (e, stackTrace) {
    print('OneSignal initialization error: $e');
    print('Stack trace: $stackTrace');
  }
}
void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await initializeFirebase(); // Firebase başlatma

    // getsnueCat konfigürasyonu
    PurchasesConfiguration configuration;
    if (Platform.isIOS) {
      configuration = PurchasesConfiguration("appl_ZFDqUCgRrrNraIvwMXBcjsqZSPe");
    } else {
      configuration = PurchasesConfiguration("goog_hZjNdDZQBOkrqzJxYoXdYigOJli");
    }
    await Purchases.setLogLevel(LogLevel.verbose);

    // Debug modda logları görmek için
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(configuration);
    configureLogging();
    await Hive.initFlutter();
    await GetStorage.init();
    // Supabase initialization
    await Supabase.initialize(
      url: 'https://zpkpdbbdoatrsbdmdxkz.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpwa3BkYmJkb2F0cnNiZG1keGt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYyMDI3OTEsImV4cCI6MjA1MTc3ODc5MX0.L_DW2qAwsSmwh7TA3Nn9uZn9D3fp2oqlqynC9gsQ9uE',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 10,
      ),
    );
    Get.put(UserProvider()); // Önce UserProvider'ı inject et
    Get.put(RoomService(
      Supabase.instance.client,
      Get.find<UserProvider>(),
    ));
    // Supabase bağlantı kontrolü


    // Kayıtlı kullanıcı varsa RevenueCat'e bildir
    String? userId = await _getStoredUserId(); // Bu metodu oluşturacağız
    if (userId != null) {
      try {
        await Purchases.logIn(userId);
      } catch (e) {
        print('RevenueCat login error: $e');
      }
    }

    // OneSignal

    await checkAllServices();

    // Global state yönetimi
    userProviderGlobal = UserProvider();
    bool userLoaded = await userProviderGlobal.loadUser().timeout(
      Duration(seconds: 5),
      onTimeout: () {
        print("User loading timeout");
        return false;
      },
    );

    if (!userLoaded) {
      await _clearAppData();
    }

    runApp(
      providerp.ProviderScope(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => VIPAdvantagesPanelProvider()),
            ChangeNotifierProvider(create: (_) => SocketService()),
            ChangeNotifierProvider(create: (_) => userProviderGlobal),
            ChangeNotifierProvider(create: (_) => StarredWordsProvider()),
            ChangeNotifierProvider(create: (_) => VolumeProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(create: (_) => DarkModeProvider()),
            ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
          ],
          child: const MyApp(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    print('Initialization error: $e');
    print('Stack trace: $stackTrace');
    await _clearAppData();
    runApp(const MyApp());
  }
}
Future<void> checkAllServices() async {
  print('\n====== SİSTEM DURUM KONTROLÜ BAŞLADI ======');
  print('🕐 Kontrol Zamanı: ${DateTime.now()}');

  // Hive Kontrolü
  try {
    final box = await Hive.openBox('testBox');
    await box.put('test', 'OK');
    final testValue = await box.get('test');
    print('📦 Hive Durumu: ${testValue == 'OK' ? "Çalışıyor ✅" : "Hata ❌"}');
    await box.delete('test');
    await box.close();
  } catch (e) {
    print('📦 Hive Hatası: $e ❌');
  }

  // GetStorage Kontrolü
  try {
    final storage = GetStorage();
    await storage.write('test', 'OK');
    final testValue = storage.read('test');
    print('💾 GetStorage Durumu: ${testValue == 'OK' ? "Çalışıyor ✅" : "Hata ❌"}');
    await storage.remove('test');
  } catch (e) {
    print('💾 GetStorage Hatası: $e ❌');
  }

  // RevenueCat Kontrolü
  try {
    final offerings = await Purchases.getOfferings();
    print('💰 RevenueCat Durumu: ${offerings != null ? "Çalışıyor ✅" : "Hata ❌"}');
  } catch (e) {
    print('💰 RevenueCat Hatası: $e ❌');
  }

  // Supabase Kontrolleri
  try {
    final client = Supabase.instance.client;

    // Bağlantı Kontrolü
    print('\n🔌 SUPABASE KONTROLLER:');
    print('├─ Client: Bağlı ✅');

    // Auth Durumu
    final session = client.auth.currentSession;
    print('├─ Auth: ${session != null ? "Oturum Açık ✅" : "Oturum Kapalı ⚠️"}');

    // Realtime Durumu
    final realtimeState = client.realtime.connectionState;
    print('├─ Realtime: $realtimeState ✅');

    // Rooms Tablosu Kontrolü
    try {
      final roomsCount = await client
          .from('rooms')
          .select('id')
          .count();
      print('└─ Rooms Tablosu: ${roomsCount.count ?? 0} kayıt var ✅');
    } catch (e) {
      print('└─ Rooms Tablosu Hatası: $e ❌');
    }

  } catch (e) {
    print('🔌 Supabase Genel Hata: $e ❌');
  }

  // User Provider Kontrolü
  try {
    if (userProviderGlobal != null) {
      print('\n👤 USER PROVIDER:');
      print('└─ Durum: Yüklendi ✅');
    } else {
      print('\n👤 USER PROVIDER:');
      print('└─ Durum: Yüklenemedi ❌');
    }
  } catch (e) {
    print('👤 User Provider Hatası: $e ❌');
  }

  print('\n====== SİSTEM DURUM KONTROLÜ TAMAMLANDI ======\n');
}
// Kullanıcı ID'sini almak için yardımcı metod
Future<String?> _getStoredUserId() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId'); // veya kullandığınız storage key
  } catch (e) {
    print('Error getting stored user ID: $e');
    return null;
  }
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 690),
      builder: (context, child) => GetMaterialApp(
        navigatorKey: navigatorKey,
        title: 'Kelibu',
        debugShowCheckedModeBanner: false,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectivityService>(
              create: (_) => ConnectivityService(),
            ),
          ],
          child: ConnectivityWrapper(child: SplashScreen()),
        ),
        getPages: AppPages.routes, // Bu satırı ekleyin

        routes: {
          '/noInternet': (context) => NoInternetPage(),
          '/free-ebooks': (context) => KelibuProListWidget(),
          '/beta-apply': (context) => BetaApplicationPage(),
          '/home': (context) => MainScreen(),
          '/phd-academy-info': (context) => EgitimBasvuruPage(),
          '/self-english': (context) => SelfEnglishBetaApplicationPage(),
        },
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
        transitionBuilder: (Widget child, Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation) {
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

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _isNavigating = false;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_mounted) return;

    if (state == AppLifecycleState.resumed) {
      _controller.play();
    } else if (state == AppLifecycleState.paused) {
      _controller.pause();
    }
  }

  Future<void> _initialize() async {
    if (!_mounted) return;

    try {
      // Paralel işlemler
      final results = await Future.wait([
        _initializeVideoPlayer(),
        WordDataCache.loadAllData().timeout(Duration(seconds: 5)),
        SharedPreferences.getInstance(),
        InternetConnectionChecker().isConnected(),
      ], eagerError: true).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Initialization timeout');
        },
      );

      if (!_mounted) return;

      final hasInternet = results[3] as bool;
      if (!hasInternet) {
        _navigateToNoInternet();
        return;
      }

      await _checkNavigationFlow();

    } catch (e, stackTrace) {
      print("Initialization error: $e");
      print("Stack trace: $stackTrace");

      if (_mounted) {
        await _clearAppData();
        _navigateToLogin();
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _controller = VideoPlayerController.asset('assets/splash_video.mp4');
      await _controller.initialize();

      if (_mounted) {
        setState(() => _isVideoInitialized = true);
        await _controller.play();

        _controller.addListener(() {
          if (_controller.value.position >= _controller.value.duration) {
            _checkNavigationFlow();
          }
        });
      }
    } catch (e) {
      print("Video initialization error: $e");
      throw e;
    }
  }

  Future<void> _checkNavigationFlow() async {
    if (_isNavigating || !_mounted) return;
    _isNavigating = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      if (!onboardingComplete) {
        _navigateToOnboarding();
        return;
      }

      // Sadece versiyon kontrolü yap
      final storedVersion = prefs.getString('app_version');
      const String CURRENT_VERSION = "3";

      // Versiyon kontrolü veya userId eksikse login'e yönlendir
      final userId = prefs.getString('userId');
      if (storedVersion != CURRENT_VERSION || userId == null || userId.isEmpty) {
        await _clearAppData();
        _navigateToLogin();
        return;
      }

      // User bilgilerini kontrol et
      if (await userProviderGlobal.loadUser()) {
        try {
          await _updateUserInfo();
          _navigateToMain();
        } catch (e) {
          print("User info update error: $e");
          _navigateToMain();
        }
      } else {
        _navigateToLogin();
      }

    } catch (e) {
      print("Navigation flow error: $e");
      _navigateToLogin();
    }
  }
  Future<void> _clearAppData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final storage = FlutterSecureStorage();
      await storage.deleteAll();

      await Hive.close();
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      await appDir.delete(recursive: true);
    } catch (e) {
      print('Error clearing app data: $e');
    }
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print("Token get error: $e");
      return null;
    }
  }

  Future<void> _updateUserInfo() async {
    if (!_mounted) return;

    try {
      final userId = userProviderGlobal.userId;
      final hash = await userProviderGlobal.getUsernameHash();
      final userData = await ApiService().fetchUserPoint(userId);

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
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MainScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToLogin() {
    if (!_mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToOnboarding() {
    if (!_mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToNoInternet() {
    if (!_mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => NoInternetPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
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
                : CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
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