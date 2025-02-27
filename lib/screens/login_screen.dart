import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // inputFormatters için eklenmeli
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/main.dart';
import 'package:kelibu/screens/privary_policy.dart';
import 'package:kelibu/screens/register.dart';
import 'package:kelibu/screens/register_screen.dart';
import 'package:kelibu/screens/reset_password_screen.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:kelibu/screens/home_screen_widgets/home_screen.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:kelibu/api.dart'; // ApiService'in doğru yolunu kullanın
import 'package:kelibu/globalDart/urls.dart';
import 'package:kelibu/variables.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  final String username;
  final String password;
  final String? warning; // Yeni opsiyonel parametre

  LoginScreen({this.username = '', this.password = '', this.warning});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isDarkMode = false;
  final storage = const FlutterSecureStorage();

  // Fade ve Slide Animasyon Kontrolcüleri
  late final AnimationController _fadeAnimationController;
  late final AnimationController _slideAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Buton Animasyon Kontrolcüleri ve Animasyonları
  late final AnimationController _loginButtonAnimationController;
  late final Animation<double> _loginButtonScaleAnimation;

  late final AnimationController _forgotPasswordButtonAnimationController;
  late final Animation<double> _forgotPasswordButtonScaleAnimation;

  late final AnimationController _registerButtonAnimationController;
  late final Animation<double> _registerButtonScaleAnimation;

  // ApiService örneği
  final ApiService _apiService = ApiService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();

    // Fade Animasyon Kontrolcüsü
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // Slide Animasyon Kontrolcüsü
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Fade ve Slide Animasyonlarını tanımlama
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _slideAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimationController.forward();
    _slideAnimationController.forward();

    // Buton Animasyonları
    _loginButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _forgotPasswordButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _registerButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _loginButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _loginButtonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _forgotPasswordButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _forgotPasswordButtonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _registerButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _registerButtonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Otomatik doldurulmuş alanlar
    if (widget.username.trim().isNotEmpty && widget.password.trim().isNotEmpty) {
      _usernameController.text = widget.username.trim();
      _passwordController.text = widget.password.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateAndLogin(); // Otomatik giriş öncesinde validasyon kontrolü yapılıyor.
      });
    }
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();

    _loginButtonAnimationController.dispose();
    _forgotPasswordButtonAnimationController.dispose();
    _registerButtonAnimationController.dispose();

    super.dispose();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Future<void> _toggleDarkMode() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkMode", _isDarkMode);
  }

  /// Giriş yapmadan önce e-posta ve şifre alanlarını doğrular.
  void _validateAndLogin() {
    String email = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog('Hata', 'Lütfen e-posta adresinizi giriniz.');
      return;
    }
    // Basit bir e-posta doğrulama regex'i
    final RegExp emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegex.hasMatch(email)) {
      _showErrorDialog('Hata', 'Lütfen geçerli bir e-posta adresi giriniz.');
      return;
    }
    if (password.isEmpty) {
      _showErrorDialog('Hata', 'Lütfen şifrenizi giriniz.');
      return;
    }
    if (password.length < 6) {
      _showErrorDialog('Hata', 'Şifreniz en az 6 karakter olmalıdır.');
      return;
    }

    // Tüm kontroller geçerse API çağrısı yapılır.
    login(email, password);
  }

  Future<void> login(String email, String password) async {
    setState(() {
      _isLoading = true;
    });

    // Loading dialogunu başlangıçta göster
    _showLoadingDialog();

    try {
      // FCM token'ını güvenli bir şekilde al
      String? fcmToken = await _getFCMToken();

      // API isteğini yap
      final Map<String, dynamic> responseData = await _apiService.login(
        email: email.trim(),
        password: password.trim(),
        fcmToken: fcmToken ?? '',
      );

      final user = responseData['user'];

      if (user == null) {
        throw Exception('Kullanıcı verisi bulunamadı.');
      }

      // RevenueCat işlemlerini arka planda yap
      final String userIdR = user['id']?.toString() ?? '0';
      unawaited(_handleRevenueCat(userIdR));

      // User Provider güncelleme
      final UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setUser(
        user['name'] ?? '',
        user['id'] != null ? int.tryParse(user['id'].toString()) ?? 0 : 0,
        user['avatar'] ?? '',
        user['point'] ?? 0,
        user['email'] ?? '',
        user['phone'] ?? '',
        user['phone_verified'] ?? false,
        user['created_at'] ?? '',
        user['city'] ?? '',
        user['birth_year'] != null ? int.tryParse(user['birth_year'].toString()) ?? 0 : 0,
        user['team'] ?? '',
        streakCount: user['streak_count'] ?? 0,
        dailyRank: user['daily_rank'] ?? 0,
        weeklyRank: user['weekly_rank'] ?? 0,
        monthlyRank: user['monthly_rank'] ?? 0,
        allTimeRank: user['all_time_rank'] ?? 0,
      );

      // SharedPreferences ile userId ve version kaydı
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user['id']?.toString() ?? '0');
      await prefs.setString('app_version', "3");

      // Loading dialog'u kapat
      Get.back();

      // Ana ekrana geç
      await Get.off(
            () => MainScreen(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 300),
      );

    } on ApiException catch (e) {
      Get.back(); // Loading dialog'u kapat
      _handleApiError(e);
    } catch (e) {
      Get.back(); // Loading dialog'u kapat
      _handleGenericError(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// FCM token'ını güvenli bir şekilde almak için yardımcı metot
  Future<String?> _getFCMToken() async {
    return null;
  }

  Future<void> _handleRevenueCat(String userId) async {
    try {
      await Purchases.logIn(userId);
      await Purchases.syncPurchases();
      await Purchases.getCustomerInfo();
    } catch (e) {
      print('RevenueCat error: $e');
    }
  }

// Loading dialog için yardımcı fonksiyon
  void _showLoadingDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/loading.json',
                width: 70,
                height: 70,
                fit: BoxFit.contain,
                frameRate: FrameRate(60), // Animasyon performansını artır
              ),
              const SizedBox(height: 16),
              Text(
                'Sistem Hazırlanıyor',
                style: GoogleFonts.comfortaa(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF42A5F5),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lütfen bekleyin, sistem ayarları yapılıyor...',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 150), // Geçiş süresini kısalt
      transitionCurve: Curves.easeInOut,
    );
  }

// API hataları için yardımcı fonksiyon
  void _handleApiError(ApiException e) {
    if (e.details != null) {
      final List<String> errorMessages = [];
      e.details!.forEach((field, messages) {
        errorMessages.addAll(List<String>.from(messages));
      });
      _showErrorDialog('Hatalar', errorMessages.join('\n'));
    } else if (e.message.contains('Too Many Requests')) {
      _showErrorDialog(
        'Çok Fazla Deneme',
        'Çok fazla giriş denemesi yaptınız. Lütfen bekleyip tekrar deneyin.',
      );
    } else {
      _showErrorDialog('Hata', e.message);
    }
  }

// Genel hatalar için yardımcı fonksiyon
  void _handleGenericError(dynamic e) {
    String errorMessage = 'Hata Detayı: ${e.toString()}';
    String errorType = 'Hata Türü: ${e.runtimeType}';

    if (e is ApiException && e.message.contains('Too Many Requests')) {
      _showErrorDialog(
        'Çok Fazla Deneme',
        'Çok fazla giriş denemesi yaptınız. Lütfen biraz bekleyip tekrar deneyin.\n\n$errorMessage',
      );
    } else {
      _showErrorDialog(
        'Beklenmeyen Hata',
        'Bir sorun oluştu. Lütfen tekrar deneyin.\n\n$errorMessage\n$errorType',
      );
    }
  }
  void _showErrorDialog(String title, String message, {String? errorCode}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.95, // Daha geniş dialog
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.string(_errorIconSvg,
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.comfortaa(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 12),
              // Kaydırılabilir hata mesajı alanı
              Container(
                height: Get.height * 0.3, // Yükseklik sınırı
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    textAlign: TextAlign.left, // Hata mesajları için sol hizalama daha iyi
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: const Color(0xFFE53935).withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Anladım',
                        style: GoogleFonts.quicksand(
                            color: const Color(0xFFE53935),
                            fontWeight: FontWeight.w600
                        )
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Hata mesajını kopyala
                      Clipboard.setData(ClipboardData(text: message));
                      ScaffoldMessenger.of(Get.context!).showSnackBar(
                        SnackBar(content: Text('Hata mesajı kopyalandı')),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Kopyala',
                        style: GoogleFonts.quicksand(
                            color: const Color(0xFF2196F3),
                            fontWeight: FontWeight.w600
                        )
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 200),
      transitionCurve: Curves.easeInOut,
    );
  }

  // Örnek bir buton oluşturma fonksiyonu
  Widget _buildButton(String text, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Text(text),
    );
  }

  // “En fazla oturum sayısına ulaştınız” diyalogu örneği
  void _showMaxSessionsReachedDialog(Map<String, dynamic>? details) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.string(
                  _errorIconSvg,
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  'Maksimum Oturum Sayısına Ulaşıldı',
                  style: GoogleFonts.comfortaa(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE53935),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Text(
                  'Şu anda ${details?['active_sessions'] ?? 'birden fazla'} aktif oturumunuz var. '
                      'En fazla ${details?['max_allowed'] ?? 3} cihazda aynı anda oturum açabilirsiniz. '
                      'Lütfen diğer cihazlardan oturumu kapatarak tekrar deneyin.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                _buildButton('Anladım', () => Navigator.of(context).pop(), const Color(0xFFE53935)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Örnek Icon (SVG) verisi
  final String _errorIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="45" fill="white" stroke="#E53935" stroke-width="5"/>
  <text x="50" y="70" font-family="Arial" font-size="60" text-anchor="middle" fill="#E53935">!</text>
</svg>
''';

  // Üst bar: Karanlık modu değiştiren buton, yardım ikonu
  Widget _buildHeader(Map<String, Color?> colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
            color: colors["text"],
          ),
          onPressed: _toggleDarkMode,
        ),
        IconButton(
          icon: Icon(Icons.help_outline, color: colors["text"]),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.login),
              ),
            );
          },
        ),
      ],
    );
  }

  // Logo bölümü
  Widget _buildLogo(Size screenSize) {
    return Container(
      width: screenSize.width * 0.2,
      height: screenSize.width * 0.2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          // Hafif gölge
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/logo.png', fit: BoxFit.cover),
      ),
    );
  }

  // Lottie animasyonu
  Widget _buildLottieAnimation(Size screenSize) {
    return SizedBox(
      height: screenSize.height * 0.1,
      child: Lottie.asset(
        'assets/welcome.json',
        fit: BoxFit.contain,
      ),
    );
  }

  // Hoş geldiniz yazısı
  Widget _buildWelcomeText(Map<String, Color?> colors, Size screenSize) {
    return Column(
      children: [
        Text(
          'Kelibu\'ya Hoş Geldiniz!',
          style: GoogleFonts.nunito(
            fontSize: screenSize.width * 0.05,
            fontWeight: FontWeight.bold,
            color: colors["text"],
          ),
        ),
        SizedBox(height: screenSize.height * 0.005),
        Text(
          'Kelime haznenizi genişletmeye hazır mısınız?',
          style: GoogleFonts.nunito(
            fontSize: screenSize.width * 0.035,
            color: colors["text"],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Giriş alanları (E-posta, Şifre)
  Widget _buildInputFields(Map<String, Color?> colors, Size screenSize) {
    return Container(
      padding: EdgeInsets.all(screenSize.width * 0.03),
      decoration: BoxDecoration(
        color: colors["cardBackground"],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Tek tip hafif gölge
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // E-posta TextField
          TextField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')), // Boşlukları engeller
            ],
            decoration: InputDecoration(
              hintText: 'E-posta',
              prefixIcon: Icon(
                Icons.email,
                color: colors["text"],
                size: screenSize.width * 0.05,
              ),
              filled: true,
              fillColor: colors["inputBackground"],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
              ),
            ),
            style: TextStyle(
              color: colors["text"],
              fontSize: screenSize.width * 0.04,
            ),
          ),
          SizedBox(height: screenSize.height * 0.01),
          // Şifre TextField
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            decoration: InputDecoration(
              hintText: 'Şifre',
              prefixIcon: Icon(
                Icons.lock,
                color: colors["text"],
                size: screenSize.width * 0.05,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: colors["text"],
                  size: screenSize.width * 0.05,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              ),
              filled: true,
              fillColor: colors["inputBackground"],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
              ),
            ),
            style: TextStyle(
              color: colors["text"],
              fontSize: screenSize.width * 0.04,
            ),
          ),
        ],
      ),
    );
  }

  // “Şifremi Unuttum” butonu
  Widget _buildForgotPasswordButton() {
    return CustomButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
      ),
      isDarkMode: _isDarkMode,
      label: 'Şifremi Unuttum',
      icon: Icons.lock_outline,
      lightModeColor: const Color(0xFF2D5DA0),  // Logo mavi
      darkModeColor: const Color(0xFF1C3B69),   // Koyu mavi
      lightHoverColor: const Color(0xFFE86548),  // Logo kırmızı
      darkHoverColor: const Color(0xFFC84E35),   // Koyu kırmızı
    );
  }
  // “Kayıt Ol” butonu
  Widget _buildRegisterButton() {
    return CustomButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RegisterScreen()),
      ),
      isDarkMode: _isDarkMode,
      label: 'Kayıt Ol',
      icon: Icons.person_add_alt_1,
      lightModeColor: const Color(0xFF36D1DC),
      darkModeColor: const Color(0xFF1E90FF),
      lightHoverColor: const Color(0xFF5B86E5),
      darkHoverColor: const Color(0xFF4169E1),
    );
  }
  // “Giriş Yap” butonu
// _buildLoginButton yerine bu kodu ekle
  Widget _buildLoginButton(Map<String, Color?> colors, Size screenSize) {
    return LoginButton(
      onPressed: () {
        _validateAndLogin(); // Giriş yapmadan önce validasyon
      },
      isDarkMode: _isDarkMode,
    );
  }

  // Sayfanın en üstünde görünen “PhD Akademi ürünüdür.” metni
  Widget _buildPhdAcademyText(Map<String, Color?> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        'Kelibu, bir PhD Akademi ürünüdür.',
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: colors["text"]?.withOpacity(0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Kullanım şartları, gizlilik politikası linkleri
  Widget _buildTermsAndConditionsText(Map<String, Color?> colors, Size screenSize) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: screenSize.width * 0.035,
                fontStyle: FontStyle.italic,
                color: colors["text"],
              ),
              children: [
                const TextSpan(text: 'By using the application, you accept the '),
                TextSpan(
                  text: 'Terms of Service (EULA)',
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      String url = '';
                      if (Platform.isIOS) {
                        url = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
                      } else if (Platform.isAndroid) {
                        url = 'https://policies.google.com/terms?hl=en-US';
                      }
                      if (url.isNotEmpty) _launchURL(url);
                    },
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy.',
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                      );
                    },
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: screenSize.width * 0.035,
                fontStyle: FontStyle.italic,
                color: colors["text"],
              ),
              children: [
                const TextSpan(text: 'Uygulamayı kullanarak '),
                TextSpan(
                  text: 'Hizmet Şartlarını (EULA)',
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      String url = '';
                      if (Platform.isIOS) {
                        url = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
                      } else if (Platform.isAndroid) {
                        url = 'https://policies.google.com/terms?hl=tr';
                      }
                      if (url.isNotEmpty) _launchURL(url);
                    },
                ),
                const TextSpan(text: ' ve '),
                TextSpan(
                  text: 'Gizlilik Politikasını',
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                      );
                    },
                ),
                const TextSpan(text: ' kabul etmiş sayılırsınız.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    // lightModeColors ve darkModeColors, projenizde tanımlı Map<String,Color?>
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(screenSize.width * 0.05),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildPhdAcademyText(colors),
                    _buildHeader(colors),
                    SizedBox(height: screenSize.height * 0.02),
                    _buildLogo(screenSize),
                    SizedBox(height: screenSize.height * 0.02),
                    _buildLottieAnimation(screenSize),
                    SizedBox(height: screenSize.height * 0.02),
                    _buildWelcomeText(colors, screenSize),
                    SizedBox(height: screenSize.height * 0.02),
                    _buildInputFields(colors, screenSize),
                    SizedBox(height: screenSize.height * 0.02),


                    _buildLoginButton(colors, screenSize),
                    SizedBox(height: screenSize.height * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildForgotPasswordButton(),
                        _buildRegisterButton(),
                      ],
                    ),
                    _buildTermsAndConditionsText(colors, screenSize),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class LoginButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isDarkMode;
  final String? label;

  const LoginButton({
    Key? key,
    required this.onPressed,
    required this.isDarkMode,
    this.label = 'Giriş Yap',
  }) : super(key: key);

  @override
  _LoginButtonState createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDarkMode ? const Color(0xFF1E3A8A) : const Color(0xFF2196F3);
    final hoverColor = widget.isDarkMode ? const Color(0xFF2563EB) : const Color(0xFF1976D2);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) {
            _animationController.reverse();
            widget.onPressed();
          },
          onTapCancel: () => _animationController.reverse(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
            decoration: BoxDecoration(
              color: _isHovered ? hoverColor : baseColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (widget.isDarkMode ? baseColor : hoverColor).withOpacity(0.2),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: const Offset(0, 4),
                  spreadRadius: _isHovered ? 2 : 0,
                ),
                if (_isHovered)
                  BoxShadow(
                    color: (widget.isDarkMode ? baseColor : hoverColor).withOpacity(0.1),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: 3,
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.login_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label ?? 'Giriş Yap',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class CustomButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isDarkMode;
  final String label;
  final IconData icon;
  final Color lightModeColor;
  final Color darkModeColor;
  final Color lightHoverColor;
  final Color darkHoverColor;

  const CustomButton({
    Key? key,
    required this.onPressed,
    required this.isDarkMode,
    required this.label,
    required this.icon,
    required this.lightModeColor,
    required this.darkModeColor,
    required this.lightHoverColor,
    required this.darkHoverColor,
  }) : super(key: key);

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDarkMode ? widget.darkModeColor : widget.lightModeColor;
    final hoverColor = widget.isDarkMode ? widget.darkHoverColor : widget.lightHoverColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) {
            _animationController.reverse();
            widget.onPressed();
          },
          onTapCancel: () => _animationController.reverse(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: _isHovered ? hoverColor : baseColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(0.2),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: const Offset(0, 4),
                  spreadRadius: _isHovered ? 2 : 0,
                ),
                if (_isHovered)
                  BoxShadow(
                    color: baseColor.withOpacity(0.1),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: 3,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}