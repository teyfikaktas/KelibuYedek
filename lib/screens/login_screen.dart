import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/globalDart/urls.dart';
import 'package:kelibu/main.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:kelibu/screens/privary_policy.dart';
import 'package:kelibu/screens/register.dart';
import 'package:kelibu/screens/reset_password_screen.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:kelibu/variables.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
class LoginScreen extends StatefulWidget {
  final String username;
  final String password;
  final String? warning;

  LoginScreen({this.username = '', this.password = '', this.warning});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
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
    _forgotPasswordButtonScaleAnimation =
        Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _forgotPasswordButtonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _registerButtonScaleAnimation =
        Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _registerButtonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Otomatik doldurulmuş alanlar
    if (widget.username.trim().isNotEmpty &&
        widget.password.trim().isNotEmpty) {
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
    final RegExp emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
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
    setState(() => _isLoading = true);
    _showLoadingDialog();

    try {
      String? fcmToken = await _getFCMToken();
      final responseData = await _apiService.login(
        email: email.trim(),
        password: password.trim(),
        fcmToken: fcmToken ?? '',
      );
      final user = responseData['user'];
      if (user == null) {
        throw Exception('Kullanıcı verisi bulunamadı');
      }
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String userIdR = user['id']?.toString() ?? '0';
      unawaited(_handleRevenueCat(userIdR));

      await userProvider.setUser(
        user['name'] ?? '',
        user['id'] ?? 0,
        user['avatar'] ?? '',
        user['point'] ?? 0,
        user['email'] ?? '',
        user['phone'] ?? '',
        user['phone_verified'] ?? false,
        user['created_at'] ?? '',
        user['city'] ?? '',
        user['birth_year'] ?? 0,
        user['team'] ?? '',
      );
      final token = responseData['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user['id'].toString());
      await prefs.setString('app_version', '3');
      await storage.write(key: 'access_token', value: token);
      Get.back(); // Loading dialog kapat
      await Get.off(
            () => MainScreen(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 300),
      );
    } on ApiException catch (e) {
      Get.back();
      _handleApiError(e);
    } catch (e, stackTrace) {
      Get.back();
      _handleGenericError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<String?> _getFCMToken() async {
    return null;
  }

  Future<void> _handleRevenueCat(String userId) async {
    try {
      await Purchases.logIn(userId);
      await Purchases.syncPurchases();
      await Purchases.getCustomerInfo();
    } catch (e) {
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
      transitionDuration: const Duration(milliseconds: 150),
      // Geçiş süresini kısalt
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          width: Get.width * 0.95,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8F9FF),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.12),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/logo.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.comfortaa(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD32F2F),
                ),
              ),
              if (errorCode != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Kod: $errorCode',
                    style: GoogleFonts.quicksand(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: Get.height * 0.25),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212121),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Tamam',
                      style: GoogleFonts.quicksand(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 250),
      transitionCurve: Curves.easeOutCubic,
    );
  }  // Örnek bir buton oluşturma fonksiyonu
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
                _buildButton('Anladım', () => Navigator.of(context).pop(),
                    const Color(0xFFE53935)),
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
                builder: (context) =>
                    VideoPlayerScreen(videoUrl: AppUrls.login),
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

  Widget _buildInputFields(Map<String, Color?> colors, Size screenSize) {
    return Container(
      padding: EdgeInsets.all(screenSize.width * 0.03),
      decoration: BoxDecoration(
        color: colors["cardBackground"],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            decoration: InputDecoration(
              hintText: 'E-posta',
              hintStyle: TextStyle(
                color: colors["text"]?.withOpacity(0.4),
              ),
              prefixIcon: Icon(
                Icons.email,
                color: colors["text"]?.withOpacity(0.7),
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
                borderSide:
                const BorderSide(color: Color(0xFF4A90E2), width: 2),
              ),
            ),
            style: TextStyle(
              color: colors["text"],
              fontSize: screenSize.width * 0.04,
            ),
          ),
          SizedBox(height: screenSize.height * 0.01),
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            decoration: InputDecoration(
              hintText: 'Şifre',
              hintStyle: TextStyle(
                color: colors["text"]?.withOpacity(0.4),
              ),
              prefixIcon: Icon(
                Icons.lock,
                color: colors["text"]?.withOpacity(0.7),
                size: screenSize.width * 0.05,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: colors["text"]?.withOpacity(0.7),
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
                borderSide:
                const BorderSide(color: Color(0xFF4A90E2), width: 2),
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

  Widget _buildForgotPasswordButton() {
    return CustomButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
      ),
      isDarkMode: _isDarkMode,
      label: 'Şifremi Unuttum',
      icon: Icons.lock_outline,
      lightModeColor: const Color(0xFF2D5DA0),
      // Logo mavi
      darkModeColor: const Color(0xFF1C3B69),
      // Koyu mavi
      lightHoverColor: const Color(0xFFE86548),
      // Logo kırmızı
      darkHoverColor: const Color(0xFFC84E35), // Koyu kırmızı
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
  Widget _buildTermsAndConditionsText(
      Map<String, Color?> colors, Size screenSize) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: screenSize.width * 0.025,
                fontStyle: FontStyle.italic,
                color: colors["text"],
              ),
              children: [
                const TextSpan(
                    text: 'By using the application, you accept the '),
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
                        url =
                            'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
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
                        MaterialPageRoute(
                            builder: (context) => PrivacyPolicyPage()),
                      );
                    },
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: screenSize.width * 0.025,
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
                        url =
                            'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
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
                        MaterialPageRoute(
                            builder: (context) => PrivacyPolicyPage()),
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
                    _buildGoogleSignInButton(screenSize), // BURAYA EKLE
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
  Widget _buildGoogleSignInButton(Size screenSize) {
    return GestureDetector(
      onTap: _isLoading ? null : _loginWithGoogle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : SvgPicture.asset(
              'assets/google_logo.svg',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Google ile Giriş Yap',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _loginWithGoogle() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await GoogleSignIn.instance.signOut();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorDialog('Hata', 'Google token alınamadı.');
        }
        return;
      }

      if (!mounted) return;
      _showLoadingDialog();

      final responseData = await _apiService.googleLogin(idToken: idToken);

      final user = responseData['user'];
      final token = responseData['access_token'];
      final refreshToken = responseData['refresh_token'];

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setUser(
        user['name'] ?? '',
        user['id'] ?? 0,
        user['avatar'] ?? '',
        user['point'] ?? 0,
        user['email'] ?? '',
        user['phone'] ?? '',
        user['phone_verified'] ?? false,
        user['created_at'] ?? '',
        user['city'] ?? '',
        user['birth_year'] ?? 0,
        user['team'] ?? '',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', user['id'].toString());
      await prefs.setString('app_version', '3');
      await storage.write(key: 'access_token', value: token);
      await storage.write(key: 'refresh_token', value: refreshToken);

      unawaited(_handleRevenueCat(user['id'].toString()));

      Get.back();
      await Get.off(() => MainScreen(), transition: Transition.fade);

    } on GoogleSignInException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      if (mounted) _showErrorDialog('Hata', 'Google giriş hatası: ${e.code}');
    } catch (e) {
      Get.back();
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Hata', 'Google ile giriş başarısız: ${e.toString()}');
      }
    }
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

class _LoginButtonState extends State<LoginButton>
    with SingleTickerProviderStateMixin {
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
    final baseColor =
        widget.isDarkMode ? const Color(0xFF1E3A8A) : const Color(0xFF2196F3);
    final hoverColor =
        widget.isDarkMode ? const Color(0xFF2563EB) : const Color(0xFF1976D2);

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
                  color: (widget.isDarkMode ? baseColor : hoverColor)
                      .withOpacity(0.2),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: const Offset(0, 4),
                  spreadRadius: _isHovered ? 2 : 0,
                ),
                if (_isHovered)
                  BoxShadow(
                    color: (widget.isDarkMode ? baseColor : hoverColor)
                        .withOpacity(0.1),
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

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
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
    final baseColor =
        widget.isDarkMode ? widget.darkModeColor : widget.lightModeColor;
    final hoverColor =
        widget.isDarkMode ? widget.darkHoverColor : widget.lightHoverColor;

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

class OneTimePasswordResetScreen extends StatefulWidget {
  final String userEmail;
  final String userName;
  final String accessToken;

  const OneTimePasswordResetScreen({
    Key? key,
    required this.userEmail,
    required this.userName,
    required this.accessToken,
  }) : super(key: key);

  @override
  _OneTimePasswordResetScreenState createState() =>
      _OneTimePasswordResetScreenState();
}

class _OneTimePasswordResetScreenState
    extends State<OneTimePasswordResetScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Beyaz arka plan
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: 40),

                // 🎨 Modern Logo ve Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8E35)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF6B35).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 32),

                // 📝 Başlık
                Text(
                  'Güvenlik Güncellemesi',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                SizedBox(height: 16),

                // 💬 Açıklama Metni - Profesyonel
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFE9ECEF)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Merhaba ${widget.userName} 👋',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Güvenliğinizi ön planda tutuyoruz! Altyapımızı güncellediğimiz için şifrenizi bir kez yenilemenizi rica ediyoruz.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🔒 Bu işlem tek seferlik',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // 🔐 Yeni Şifre Input
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    style: GoogleFonts.inter(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Yeni Şifre',
                      labelStyle: GoogleFonts.inter(color: Color(0xFF6B7280)),
                      prefixIcon:
                          Icon(Icons.lock_rounded, color: Color(0xFFFF6B35)),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                            () => _obscureNewPassword = !_obscureNewPassword),
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xFFFF6B35), width: 2),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // 🔐 Şifre Tekrar Input
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: GoogleFonts.inter(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Şifre Tekrar',
                      labelStyle: GoogleFonts.inter(color: Color(0xFF6B7280)),
                      prefixIcon: Icon(Icons.lock_outline_rounded,
                          color: Color(0xFFFF6B35)),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword),
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Color(0xFFFF6B35), width: 2),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32),

                // 🚀 Güncelle Butonu - Premium Look
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF6B35).withOpacity(0.4),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.security_update, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Şifremi Güncelle',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: 24),

                // 🛡️ Güvenlik Notu
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Color(0xFF0EA5E9).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF0EA5E9),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Şifreniz güvenli bir şekilde şifrelenerek saklanmaktadır.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Color(0xFF0C4A6E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text.length < 6) {
      _showError('Şifre en az 6 karakter olmalıdır.');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Şifreler eşleşmiyor.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Şifre güncelle
      final response = await _apiService.updatePasswordOneTime(
        email: widget.userEmail,
        newPassword: _newPasswordController.text,
        accessToken: widget.accessToken,
      );

      // 2️⃣ Supabase session güncelle
      await _updateSupabaseSession();

      // 3️⃣ Kullanıcı verilerini Supabase Profiles'tan çek
      await _loadUserProfileFromSupabase();

      if (!mounted) return;

      // 4️⃣ Başarı mesajı
      Get.snackbar(
        'Tamamlandı! ✅',
        'Şifreniz güncellendi. Profil bilgileri yükleniyor...',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        icon: Icon(Icons.check_circle, color: Colors.white),
        duration: Duration(seconds: 2),
      );

      await Future.delayed(Duration(milliseconds: 1500));

      if (!mounted) return;
      Get.offAll(() => MainScreen());
    } catch (e) {
      if (!mounted) return;
      _showError('Şifre güncellenirken hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

// 👤 Supabase Profiles'tan kullanıcı verilerini çek
  Future<void> _loadUserProfileFromSupabase() async {
    try {
      // Aktif session'dan user ID'yi al
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.user?.id == null) {
        return;
      }

      final supabaseUserId = session!.user.id;

      // Profiles tablosundan kullanıcı verilerini çek
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', supabaseUserId) // Auth User ID ile eşleş
          .single();

      if (profileResponse != null) {
        // Provider'a yükle
        final UserProvider userProvider =
            Provider.of<UserProvider>(context, listen: false);
        await userProvider.setUser(
          profileResponse['name'] ?? '',
          profileResponse['laravel_id'] ?? 0,
          // Laravel ID
          profileResponse['avatar'] ?? '',
          profileResponse['point'] ?? 0,
          profileResponse['email'] ?? '',
          profileResponse['phone'] ?? '',
          profileResponse['phone_verified'] ?? false,
          profileResponse['created_at'] ?? '',
          profileResponse['city'] ?? '',
          profileResponse['birth_year'] ?? 0,
          profileResponse['team'] ?? '',
          streakCount: 0,
          // Bu alanlar profiles'ta yoksa 0 ver
          dailyRank: 0,
          weeklyRank: 0,
          monthlyRank: 0,
          allTimeRank: 0,
        );

        // SharedPreferences güncelle
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'userId', profileResponse['laravel_id']?.toString() ?? '0');
        await prefs.setString('supabase_user_id', supabaseUserId);
        await prefs.setString('app_version', "3");
      }
    } catch (e) {
      // Fallback: Laravel API'den çek
    }
  }

// 🔄 Fallback: Laravel API'den kullanıcı verilerini çek
  Future<void> _updateSupabaseSession() async {
    try {
      // Supabase'e yeni şifre ile giriş yap
      final AuthResponse authResponse =
          await Supabase.instance.client.auth.signInWithPassword(
        email: widget.userEmail,
        password: _newPasswordController.text,
      );

      if (authResponse.session != null) {
        // Session bilgilerini local storage'a kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'supabase_access_token', authResponse.session!.accessToken);
        await prefs.setString(
            'supabase_refresh_token', authResponse.session!.refreshToken ?? '');
        await prefs.setString('supabase_user_id', authResponse.user!.id);
      } else {
        throw Exception('Supabase session oluşturulamadı');
      }
    } catch (supabaseError) {}
  }

  void _showError(String message) {
    // 🔧 Widget hala aktif mi kontrol et
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 4), // ⏰ Süre ekle
      ),
    );
  }

  @override
  void dispose() {
    // 🧹 Controller'ları temizle
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
