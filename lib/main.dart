import 'dart:async';
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';

import 'package:animations/animations.dart';
import 'package:dio/dio.dart'; // ✅ Ekle
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as providerp;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/providers/darkmodeprovider.dart';
import 'package:kelibu/providers/socket.dart';
import 'package:kelibu/providers/sub_provider.dart';
import 'package:kelibu/routes/race/app_routes.dart';
import 'package:kelibu/screens/InternetConnectionCheckPage.dart';
import 'package:kelibu/screens/advantages/books_pro.dart';
import 'package:kelibu/screens/betaprogram/beta_apply.dart';
import 'package:kelibu/screens/betaprogram/phdakademi.dart';
import 'package:kelibu/screens/connectivyplus.dart';
import 'package:kelibu/screens/connectivywrapper.dart';
import 'package:kelibu/screens/home_screen_widgets/home_screen.dart';
import 'package:kelibu/screens/leader_screen.dart';
import 'package:kelibu/screens/login_screen.dart';
import 'package:kelibu/screens/my_learn_path.dart';
import 'package:kelibu/screens/noInternetPage.dart';
import 'package:kelibu/screens/onboarding_screen.dart';
import 'package:kelibu/screens/race/core/services/RoomService.dart';
import 'package:kelibu/screens/src/self_english_beta.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import 'firebase_options.dart';
import 'providers/language_provider.dart';
import 'providers/starred_word_provider.dart';
import 'providers/user_provider.dart';
import 'providers/volume_provider.dart';
import 'screens/market_store.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late UserProvider userProviderGlobal;

class SupabaseConfig {
  static const String url = 'http://159.69.213.19:8080';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzQ5MjQzNjAw>';
}

Future<void> initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
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

    // Bağlantı testi
    await testSupabaseConnection();
  } catch (e) {
    rethrow;
  }
}
Future<void> testSupabaseConnection() async {
  try {
    final client = Supabase.instance.client;
    // 1. Basic health check - rooms tablosuna erişim
    try {
      await client.from('rooms').select('id').limit(1).timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Supabase rooms query timeout');
        },
      );
    } catch (e) {
      throw e;
    }

    // 2. Auth endpoint kontrolü (opsiyonel)
    try {
      final session = client.auth.currentSession;
      if (session != null) {
      } else {
      }
    } catch (e) {
      // Auth hatası kritik değil, devam et
    }

    // 3. Storage kontrolü (opsiyonel)
    try {
      final buckets = await client.storage.listBuckets().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          return [];
        },
      );
    } catch (e) {
      // Storage hatası kritik değil, devam et
    }
  } catch (e) {
    throw e;
  }
}Future<void> initializeSupabaseWithRetry({int maxRetries = 3}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
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
      ).timeout(
        Duration(seconds: 10), // ✅ Timeout ekle
        onTimeout: () {
          throw TimeoutException('Supabase initialization timeout');
        },
      );

      // ✅ Bağlantı test et
      await _testSupabaseConnection();
      return; // Başarılı, fonksiyondan çık

    } catch (e) {
      if (attempt == maxRetries) {
        throw Exception('Failed to initialize Supabase after $maxRetries attempts: $e');
      }

      // ✅ Exponential backoff - her denemede bekleme süresi artar
      final waitTime = Duration(seconds: attempt * 2); // 2s, 4s, 6s...
      await Future.delayed(waitTime);
    }
  }
}

Future<void> _testSupabaseConnection() async {
  try {
    final client = Supabase.instance.client;

    // ✅ Basit bir health check
    await client.from('rooms').select('id').limit(1).timeout(
      Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException('Supabase connection test timeout');
      },
    );
  } catch (e) {
    throw e;
  }
}

Future<void> initializeFirebaseWithRetry({int maxRetries = 3}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Firebase initialization timeout');
        },
      );

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // iOS kontrolleri
      if (Platform.isIOS) {
        try {
          final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken == null) {
            await Future.delayed(Duration(seconds: 2));
            await FirebaseMessaging.instance.getAPNSToken();
          }
        } catch (e) {
        }
      }

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      try {
        await FirebaseMessaging.instance.getToken();
      } catch (e) {
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
        }
      });

      try {
        await FirebaseMessaging.instance.subscribeToTopic('announcements');
      } catch (e) {
      }

      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      });

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      return; // Başarılı

    } catch (e) {
      if (attempt == maxRetries) {
        throw Exception('Failed to initialize Firebase after $maxRetries attempts: $e');
      }

      final waitTime = Duration(seconds: attempt * 2);
      await Future.delayed(waitTime);
    }
  }
}
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  // iOS için özel kontroller
  if (Platform.isIOS) {
    try {
      // APNS token'ı bekle
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();

      // Eğer APNS token null ise biraz bekle ve tekrar dene
      if (apnsToken == null) {
        await Future.delayed(Duration(seconds: 2));
        await FirebaseMessaging.instance.getAPNSToken();
      }
    } catch (e) {}
  }

  // İzinleri iste
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false, // iOS için geçici izin
  );

  // FCM token'ı al
  try {
    await FirebaseMessaging.instance.getToken();
  } catch (e) {}

  // Ön planda bildirim dinleyicisi
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {}
  });
  try {
    await FirebaseMessaging.instance.subscribeToTopic('announcements');
  } catch (e) {}
// Uygulama kapalıyken gelen bildirim tıklaması (initial message)
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      // Zaten uygulamayı açacak, başka bir şey yapmaya gerek yok
    }
  });

// Uygulama arkaplandayken gelen bildirim tıklaması
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // Zaten uygulamayı açacak, başka bir şey yapmaya gerek yok
  });
  // Arka planda bildirim dinleyicisi
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

// Arka plan mesaj işleyici
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void configureLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (record.error != null) {}
    if (record.stackTrace != null) {}
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
  } catch (e) {}
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('tr_TR', null);
// Google Sign-In initialize
    if (Platform.isAndroid) {
      await GoogleSignIn.instance.initialize(
        serverClientId: '859879146409-ph1t7uif3kfr0jj8li0csdqi93nq9ieh.apps.googleusercontent.com',
      );
    }
    // Firebase başlatma - retry mekanizmalı
    try {
      await initializeFirebaseWithRetry(maxRetries: 3);
    } catch (e) {
      // Firebase zorunlu değilse devam et
    }

    // RevenueCat konfigürasyonu
    PurchasesConfiguration configuration;
    if (Platform.isIOS) {
      configuration = PurchasesConfiguration("appl_ZFDqUCgRrrNraIvwMXBcjsqZSPe");
    } else {
      configuration = PurchasesConfiguration("goog_hZjNdDZQBOkrqzJxYoXdYigOJli");
    }

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(configuration); // ✅ timeout kaldırıldı
    } catch (e) {
    }

    configureLogging();

    // Hive ve GetStorage
    try {
      await Hive.initFlutter();
    } catch (e) {
    }

    try {
      await GetStorage.init();
    } catch (e) {
    }

    // Supabase initialization - retry mekanizmalı
    try {
      await initializeSupabaseWithRetry(maxRetries: 3);
    } catch (e) {
      // Supabase olmadan da uygulama çalışabilir (offline mode)
    }

    // Dependency injection
    try {
      Get.put(UserProvider());
      Get.put(RoomService(
        Supabase.instance.client,
        Get.find<UserProvider>(),
      ));
    } catch (e) {
      // Fallback provider'lar
      Get.put(UserProvider());
    }

    // Kayıtlı kullanıcı varsa RevenueCat'e bildir
    String? userId = await _getStoredUserId();
    if (userId != null) {
      try {
        await Purchases.logIn(userId); // ✅ timeout kaldırıldı
      } catch (e) {
      }
    }

    // Servis kontrolleri
    await checkAllServices();

    // Global state yönetimi
    userProviderGlobal = UserProvider();
    bool userLoaded = false;

    try {
      userLoaded = await userProviderGlobal.loadUser().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          return false;
        },
      );
    } catch (e) {
      userLoaded = false;
    }

    // Uygulama başlatma
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
  } catch (e) {
    // Minimal başlatma - hata sayfası göster
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Uygulama Başlatılamadı',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    exit(0);
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Uygulamayı Yeniden Başlat'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
Future<void> checkAllServices() async {
  try {
    final client = Supabase.instance.client;


    try {
      await client.from('rooms').select('id').count();
    } catch (e) {}
  } catch (e) {}
  // Hive Kontrolü
  try {
    final box = await Hive.openBox('testBox');
    await box.put('test', 'OK');
    await box.get('test');
    await box.delete('test');
    await box.close();
  } catch (e) {}

  // GetStorage Kontrolü
  try {
    final storage = GetStorage();
    await storage.write('test', 'OK');
    storage.read('test');
    await storage.remove('test');
  } catch (e) {}

  // RevenueCat Kontrolü
  try {
    await Purchases.getOfferings();
  } catch (e) {}

  // Supabase Kontrolleri


  // User Provider Kontrolü
  try {
    if (userProviderGlobal != null) {
    } else {}
  } catch (e) {}
}

// Kullanıcı ID'sini almak için yardımcı metod
Future<String?> _getStoredUserId() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId'); // veya kullandığınız storage key
  } catch (e) {
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
        getPages: AppPages.routes,
        // Bu satırı ekleyin

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

class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller; // ✅ nullable
  bool _isVideoInitialized = false;
  bool _isNavigating = false;
  bool _mounted = true;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    _safetyTimer = Timer(Duration(seconds: 5), () {
      if (_mounted && !_isNavigating) {
        _checkNavigationFlow();
      }
    });
  }

  Future<void> _checkTokenAndNavigate() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    if (token == null) {
      // Token yok → Login
      Get.offAll(() => LoginScreen());
      return;
    }

    // ✅ Token'ı validate et
    try {
      final apiService = ApiService();
      final response = await apiService.dio.get(
        '/user', // veya '/auth/validate'
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Token geçerli → Ana sayfa
        Get.offAll(() => HomeScreen());
      }
    } catch (e) {
      // Token geçersiz → Sil ve Login'e git
      await storage.delete(key: 'access_token');
      Get.offAll(() => LoginScreen());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_mounted) return;

    if (state == AppLifecycleState.resumed) {
      _controller?.play();
    } else if (state == AppLifecycleState.paused) {
      _controller?.pause();
    }
  }

  Future<void> _initialize() async {
    if (!_mounted) return;
    try {
      bool hasInternet = false;
      try {
        hasInternet = await InternetConnectionChecker()
            .isConnected()
            .timeout(const Duration(seconds: 5), onTimeout: () => false);
      } catch (e) {
        hasInternet = false;
      }

      if (!_mounted) return;

      if (!hasInternet) {
        _navigateToNoInternet();
        return;
      }

      bool videoInitialized = false;
      try {
        _controller = VideoPlayerController.asset('assets/splash_video.mp4');

        await _controller?.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException("Video initialization timeout");
          },
        );

        if (_mounted) {
          setState(() {
            _isVideoInitialized = true;
          });

          // ✅ BURASI DEĞİŞTİ - Listener'ı ekle
          _controller!.addListener(_videoListener);

          await _controller?.play();
          videoInitialized = true;
        }
      } catch (e) {
        videoInitialized = false;
      }

      if (!videoInitialized) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (_mounted) {
            _checkNavigationFlow();
          }
        });
      }

      try {} catch (e) {}

      // User yükleme - arka planda
      try {
        await userProviderGlobal.loadUser().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            return false;
          },
        );
      } catch (e) {}

      try {
        await _updateUserInfo().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            return;
          },
        );
      } catch (e) {}
    } catch (e) {
      if (_mounted) {
        _navigateToLogin();
      }
    }
  }
// 1️⃣ Önce fonksiyonu tanımla (class içinde, en üstte)
  void _videoListener() {
    final controller = _controller;
    if (controller != null &&
        controller.value.isInitialized &&
        controller.value.position >= controller.value.duration) {
      _checkNavigationFlow();
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

      // Versiyon kontrolü
      final storedVersion = prefs.getString('app_version');
      const String CURRENT_VERSION = "3";

      const storage = FlutterSecureStorage();

      final token = await storage.read(key: 'access_token');
      if (storedVersion != CURRENT_VERSION || token == null || token.isEmpty) {
        await _clearAppData();
        _navigateToLogin();
        return;
      }

      bool isTokenValid = await _validateToken(token);

      if (!isTokenValid) {
        await _clearAppData();
        _navigateToLogin();
        return;
      }

      if (await userProviderGlobal.loadUser()) {
        try {
          await _updateUserInfo();
          _navigateToMain();
        } catch (e) {
          _navigateToMain();
        }
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      _navigateToLogin();
    }
  }

  Future<bool> _validateToken(String token) async {
    return await ApiService().validateToken(token);
  }

  void _navigateToLogin() async {
    if (!_mounted) return;

    // Login ekranına gitmeden önce tüm verileri sil
    await _clearAppData();

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

// _clearAppData() fonksiyonunu genişletin ve eksik kaynakları da temizleyin
  Future<void> _clearAppData() async {
    try {
      // SharedPreferences temizliği
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Secure Storage temizliği
      final storage = FlutterSecureStorage();
      await storage.deleteAll();

      // GetStorage temizliği
      try {
        final getStorage = GetStorage();
        await getStorage.erase();
      } catch (e) {}

      // Hive verilerini temizle
      try {
        await Hive.close();
      } catch (e) {}

      try {
        final appDir = await path_provider.getApplicationDocumentsDirectory();
        final appDirPath = appDir.path;

        final directory = Directory(appDirPath);
        if (await directory.exists()) {
          final files = directory.listSync();
          for (var file in files) {
            try {
              await file.delete(recursive: true);
            } catch (e) {}
          }
        }
      } catch (e) {}

      // Kullanıcı provider'ını sıfırla
    } catch (e) {}
  }

  Future<void> _updateUserInfo() async {
    if (!_mounted) return;

    try {
      final userId = userProviderGlobal.userId;
      await userProviderGlobal.getUsernameHash();
      final userData = await ApiService().fetchUserPoint();

      if (_mounted) {
        await userProviderGlobal.addPoint(userData['point']);
      }
    } catch (e) {
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
                    aspectRatio: _controller!.value.aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: Colors.white),
                        VideoPlayer(_controller!),
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
    WidgetsBinding.instance.removeObserver(this);

    // ✅ YENİ KOD - Güvenli dispose
    if (_controller != null) {
      try {
        // Önce listener'ı kaldır
        _controller!.removeListener(_videoListener);

        // Video oynatılıyorsa durdur
        if (_controller!.value.isInitialized) {
          _controller!.pause();
        }

        // Dispose et
        _controller!.dispose();
      } catch (e) {
        // Hata olursa sessizce geç
      }
      _controller = null;
    }

    super.dispose();
  }
}
