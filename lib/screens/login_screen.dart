import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // inputFormatters için eklenmeli
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final storage = FlutterSecureStorage();

  // Fade ve Slide Animasyon Kontrolcüleri
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Buton Animasyon Kontrolcüleri ve Animasyonları
  late AnimationController _loginButtonAnimationController;
  late Animation<double> _loginButtonScaleAnimation;

  late AnimationController _forgotPasswordButtonAnimationController;
  late Animation<double> _forgotPasswordButtonScaleAnimation;

  late AnimationController _registerButtonAnimationController;
  late Animation<double> _registerButtonScaleAnimation;

  // ApiService örneği
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();

    // Fade Animasyon Kontrolcüsü
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    // Slide Animasyon Kontrolcüsü
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    // Fade ve Slide Animasyonlarını Başlatma
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimationController.forward();
    _slideAnimationController.forward();

    // Buton Animasyon Kontrolcüleri ve Animasyonlar
    _loginButtonAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _loginButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _loginButtonAnimationController, curve: Curves.easeInOut),
    );

    _forgotPasswordButtonAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _forgotPasswordButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _forgotPasswordButtonAnimationController, curve: Curves.easeInOut),
    );

    _registerButtonAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _registerButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _registerButtonAnimationController, curve: Curves.easeInOut),
    );

    // Önceden doldurulmuş kullanıcı adı ve şifre varsa giriş yapma
    if (widget.username.trim().isNotEmpty && widget.password.trim().isNotEmpty) {
      _usernameController.text = widget.username.trim();
      _passwordController.text = widget.password.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) => login(
        _usernameController.text,
        _passwordController.text,
      ));
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

  bool _isLoading = false;

  Future<void> login(String email, String password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Login started');
      final responseData = await _apiService.login(email: email.trim(), password: password.trim());
      print('Login API Response: $responseData');

      // Başarılı giriş işlemleri
      final user = responseData['user'];
      if (user == null) {
        throw Exception('Kullanıcı verisi bulunamadı.');
      }

      print('User data: $user');

      // Token ve expires_at değerlerini saklama
      if (responseData['access_token'] != null && responseData['expires_in'] != null) {
        String accessToken = responseData['access_token'];
        int expiresIn = responseData['expires_in']; // Token süresini saniye cinsinden alabilirsiniz
        int expiresAtMillis = DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;

        await storage.write(key: 'access_token', value: accessToken);
        await storage.write(key: 'expires_at', value: expiresAtMillis.toString());
      } else {
        throw Exception('Token bilgisi eksik.');
      }

      // Kullanıcı verilerini sağlayıcıya ayarlama
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

      print('Provider updated');

      final prefs = await SharedPreferences.getInstance();
      String userId = user['id']?.toString() ?? '0';
      await prefs.setString('userId', userId);
      print('User ID saved to SharedPreferences');

      // Başarı mesajını gösterme
      final message = responseData['message'] ?? 'Giriş başarılı!';
      if (message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Ana ekrana yönlendirme
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));
    } on ApiException catch (e) {
      // Doğrulama hatalarını işleme
      if (e.details != null) {
        List<String> errorMessages = [];
        e.details!.forEach((field, messages) {
          errorMessages.addAll(List<String>.from(messages));
        });
        String combinedMessage = errorMessages.join('\n');
        _showErrorDialog('Hatalar', combinedMessage);
      } else if (e.message.contains('Too Many Requests')) {
        _showErrorDialog('Çok Fazla Deneme', 'Çok fazla giriş denemesi yaptınız. Lütfen biraz bekleyip tekrar deneyin. Bu sistem sizi korumak içindir.');
      } else {
        // Diğer API hatalarını işleme
        _showErrorDialog('Hata', e.message);
      }
    } catch (e) {
      if (e is ApiException && e.message.contains('Too Many Requests')) {
        _showErrorDialog('Çok Fazla Deneme', 'Çok fazla giriş denemesi yaptınız. Lütfen biraz bekleyip tekrar deneyin. Bu sistem sizi korumak içindir.');
      } else {
        _showErrorDialog('Beklenmeyen Hata', 'Bir sorun oluştu. Lütfen daha sonra tekrar deneyin.');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void handleLoginError(String? error, Map<String, dynamic>? details) {
    switch (error) {
      case 'invalid_credentials':
        _showErrorDialog(
          'Giriş Başarısız',
          'E-posta veya şifre yanlış. Lütfen bilgilerinizi kontrol edin.',
          errorCode: 'invalid_credentials',
        );
        break;
      case 'max_sessions_reached':
        _showMaxSessionsReachedDialog(details);
        break;
      case 'token_creation_failed':
        _showErrorDialog(
          'Giriş Hatası',
          'Oturum oluşturulurken bir hata oluştu. Lütfen daha sonra tekrar deneyin.',
        );
        break;
    // Yeni hata durumları ekleyebilirsiniz
      case 'account_locked':
        _showErrorDialog(
          'Hesap Kilitlendi',
          'Güvenlik nedeniyle hesabınız kilitlendi. Lütfen destek ile iletişime geçin.',
        );
        break;
      default:
        _showErrorDialog(
          'Giriş Hatası',
          'Giriş yapılırken bir hata oluştu. Lütfen daha sonra tekrar deneyin.',
        );
    }
  }

  void _showInfoDialog(String title, String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.orange,
                ),
                SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.comfortaa(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    color: _isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Tamam'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMaxSessionsReachedDialog(Map<String, dynamic>? details) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 3),
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
                SizedBox(height: 20),
                Text(
                  'Maksimum Oturum Sayısına Ulaşıldı',
                  style: GoogleFonts.comfortaa(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53935),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                Text(
                  'Şu anda ${details?['active_sessions'] ?? 'birden fazla'} aktif oturumunuz var. '
                      'En fazla ${details?['max_allowed'] ?? 3} cihazda aynı anda oturum açabilirsiniz. '
                      'Lütfen diğer cihazlardan birinde oturumu kapatın ve tekrar deneyin.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                _buildButton('Anladım', () => Navigator.of(context).pop(), Color(0xFFE53935)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String title, String message, {String? errorCode}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 3),
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
                SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.comfortaa(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53935),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton('Anladım', () => Navigator.of(context).pop(), Color(0xFFE53935)),
                    if (errorCode == 'invalid_credentials')
                      _buildButton(
                        'Üye Ol',
                            () {
                          Navigator.of(context).pop();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                        },
                        Color(0xFF4CAF50),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      child: Text(text),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getEsprilyTitle(String title) {
    switch (title) {
      case 'Giriş başarısız':
        return 'Girdiğin bilgiler hatalıdır, lütfen kontrol edip tekrar deneyin.';
      case 'Hata':
        return 'Bir sorun oluştu. Teknik ekibe bilgi verilmiştir.  🚀';
      default:
        return title;
    }
  }

  String _getEsprilyMessage(String message) {
    return message;
  }

  final String _errorIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="45" fill="white" stroke="#E53935" stroke-width="5"/>
  <text x="50" y="70" font-family="Arial" font-size="60" text-anchor="middle" fill="#E53935">!</text>
</svg>
''';

  Widget _buildHeader(Map<String, Color?> colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round, color: colors["text"]),
          onPressed: _toggleDarkMode,
        ),
        IconButton(
          icon: Icon(Icons.help_outline, color: colors["text"]),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.login)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogo(Size screenSize) {
    return Container(
      width: screenSize.width * 0.2,
      height: screenSize.width * 0.2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/logo.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildLottieAnimation(Size screenSize) {
    return Container(
      height: screenSize.height * 0.1,
      child: Lottie.asset(
        'assets/welcome.json',
        fit: BoxFit.contain,
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // E-posta (Username) TextField
          TextField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')), // Boşlukları engeller
            ],
            decoration: InputDecoration(
              hintText: 'E-posta',
              prefixIcon: Icon(Icons.email, color: colors["text"], size: screenSize.width * 0.05),
              filled: true,
              fillColor: colors["inputBackground"],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
              ),
            ),
            style: TextStyle(color: colors["text"], fontSize: screenSize.width * 0.04),
          ),
          SizedBox(height: screenSize.height * 0.01),
          // Şifre TextField
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')), // Boşlukları engeller
            ],
            decoration: InputDecoration(
              hintText: 'Şifre',
              prefixIcon: Icon(Icons.lock, color: colors["text"], size: screenSize.width * 0.05),
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: colors["text"], size: screenSize.width * 0.05),
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
                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
              ),
            ),
            style: TextStyle(color: colors["text"], fontSize: screenSize.width * 0.04),
          ),
        ],
      ),
    );
  }

  // Özel AnimatedButton Widget'ı
  Widget _buildAnimatedButton({
    required String text,
    required VoidCallback onPressed,
    required Gradient gradient,
    required AnimationController controller,
    required Animation<double> scaleAnimation,
    required IconData icon,
    required Color iconColor,
    required double iconSize,
    required double fontSize,
  }) {
    return GestureDetector(
      onTapDown: (_) => controller.forward(),
      onTapUp: (_) {
        controller.reverse();
        onPressed();
      },
      onTapCancel: () => controller.reverse(),
      child: ScaleTransition(
        scale: scaleAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(gradient.colors.first.opacity * 0.3),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: iconSize),
              SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(Map<String, Color?> colors, Size screenSize) {
    return ScaleTransition(
      scale: _loginButtonScaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _loginButtonAnimationController.forward(),
        onTapUp: (_) {
          _loginButtonAnimationController.reverse();
          // Trim uygulaması eklendi
          login(_usernameController.text.trim(), _passwordController.text.trim());
        },
        onTapCancel: () => _loginButtonAnimationController.reverse(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            gradient: _isDarkMode
                ? LinearGradient(
              colors: [Color(0xFF2A5298), Color(0xFF3A6DB0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
                : LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF5AB1FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, color: Colors.white, size: screenSize.width * 0.05),
              SizedBox(width: 10),
              Text(
                'Giriş Yap',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton(Map<String, Color?> colors, Size screenSize) {
    return ScaleTransition(
      scale: _forgotPasswordButtonScaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _forgotPasswordButtonAnimationController.forward(),
        onTapUp: (_) {
          _forgotPasswordButtonAnimationController.reverse();
          Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordScreen()));
        },
        onTapCancel: () => _forgotPasswordButtonAnimationController.reverse(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: _isDarkMode
                ? LinearGradient(
              colors: [Color(0xFFB03060), Color(0xFFD2691E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [Color(0xFFFE6B8B), Color(0xFFFF8E53)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white, size: screenSize.width * 0.04),
              SizedBox(width: 5),
              Text(
                'Şifremi Unuttum',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.035,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(Map<String, Color?> colors, Size screenSize) {
    return ScaleTransition(
      scale: _registerButtonScaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _registerButtonAnimationController.forward(),
        onTapUp: (_) {
          _registerButtonAnimationController.reverse();
          Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
        },
        onTapCancel: () => _registerButtonAnimationController.reverse(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: _isDarkMode
                ? LinearGradient(
              colors: [Color(0xFF1E90FF), Color(0xFF4169E1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.person_add_alt_1, color: Colors.white, size: screenSize.width * 0.04),
              SizedBox(width: 5),
              Text(
                'Kayıt Ol',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.035,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationalText(Map<String, Color?> colors, Size screenSize) {
    return Container(
      padding: EdgeInsets.all(screenSize.width * 0.03),
      decoration: BoxDecoration(
        color: Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '"Bir dil öğrenmek, dünyaya açılan bir pencere daha demektir." - Çin Atasözü',
        style: GoogleFonts.nunito(
          fontSize: screenSize.width * 0.035,
          fontStyle: FontStyle.italic,
          color: Color(0xFF2C3E50),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPhdAcademyText(Map<String, Color?> colors) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildTermsAndConditionsText(Map<String, Color?> colors, Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
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
                TextSpan(text: 'By using the application, you accept the '),
                TextSpan(
                  text: 'Terms of Service (EULA)',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Open the appropriate link in web view
                      String url = '';
                      if (Platform.isIOS) {
                        url = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
                      } else if (Platform.isAndroid) {
                        url = 'https://policies.google.com/terms?hl=en-US';
                      }
                      if (url.isNotEmpty) {
                        _launchURL(url);
                      }
                    },
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy.',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Navigate to PrivacyPolicyPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                      );
                    },
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: screenSize.width * 0.035,
                fontStyle: FontStyle.italic,
                color: colors["text"],
              ),
              children: [
                TextSpan(text: 'Uygulamayı kullanarak '),
                TextSpan(
                  text: 'Hizmet Şartlarını (EULA)',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Open the appropriate link in web view
                      String url = '';
                      if (Platform.isIOS) {
                        url = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
                      } else if (Platform.isAndroid) {
                        url = 'https://policies.google.com/terms?hl=tr';
                      }
                      if (url.isNotEmpty) {
                        _launchURL(url);
                      }
                    },
                ),
                TextSpan(text: ' ve '),
                TextSpan(
                  text: 'Gizlilik Politikasını',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Navigate to PrivacyPolicyPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                      );
                    },
                ),
                TextSpan(text: ' kabul etmiş sayılırsınız.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildForgotPasswordButton(colors, screenSize),
                        _buildRegisterButton(colors, screenSize),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    _buildLoginButton(colors, screenSize),
                    SizedBox(height: screenSize.height * 0.01),
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
