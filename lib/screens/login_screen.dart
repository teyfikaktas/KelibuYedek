import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/screens/register.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:kelibu/screens/register_screen.dart';
import 'package:kelibu/screens/reset_password_screen.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:kelibu/screens/home_screen.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:kelibu/globalDart/urls.dart';
import 'package:kelibu/variables.dart';

class LoginScreen extends StatefulWidget {
  final String username;
  final String password;

  LoginScreen({this.username = '', this.password = ''});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isDarkMode = false;
  final storage = FlutterSecureStorage();
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;
  int _currentLottieIndex = 0;
  final List<String> _lottieFiles = ['assets/langue.json', 'assets/welcome.json'];

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _slideAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeInOut),
    );

    _fadeAnimationController.forward();
    _slideAnimationController.forward();

    if (widget.username.isNotEmpty && widget.password.isNotEmpty) {
      _usernameController.text = widget.username;
      _passwordController.text = widget.password;
      WidgetsBinding.instance.addPostFrameCallback((_) => login(widget.username, widget.password));
    }

    _startLottieAnimation();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _buttonAnimationController.dispose();
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

  void _startLottieAnimation() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentLottieIndex = (_currentLottieIndex + 1) % _lottieFiles.length;
        });
        _startLottieAnimation();
      }
    });
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('https://kelibu.net/api/login'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-Custom-Header': privacyKey.privacyKeyVariable,
        },
        body: jsonEncode(<String, String>{
          'email': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(
          responseData['name'] ?? '',
          responseData['id'] ?? '',
          responseData['avatar'] ?? '',
          responseData['point'] ?? 0,
          responseData['email'] ?? '',
          responseData['phone'] ?? '',
          responseData['phone_verified'] ?? '',
          responseData['created_at'] ?? '',
          responseData['city'] ?? '',
          int.tryParse(responseData['birth_year'].toString()) ?? 0,
          responseData['team'] ?? '',
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
        // User ID'yi kaydet
        final prefs = await SharedPreferences.getInstance();

        String userId = responseData['id'].toString();
        await prefs.setString('userId', userId);

      } else {
        _showErrorDialog('Giriş başarısız', 'Bilgileriniz hatalı olabilir. Henüz üye değilseniz, hemen üye olabilirsiniz.');
      }
    } catch (e) {
      print(e);
      _showErrorDialog('Bağlantı Hatası', 'Bir hata oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.');
    }
  }


  void _showErrorDialog(String title, String message) {
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
                  spreadRadius: 5,
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
                  _getEsprilyTitle(title),
                  style: GoogleFonts.comfortaa(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53935),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                Text(
                  _getEsprilyMessage(message),
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
                    _buildButton('Anladım.', () => Navigator.of(context).pop(), Color(0xFFE53935)),
                    if (title == 'Giriş başarısız')
                      _buildButton('Üye Ol', () {
                        Navigator.of(context).pop();
                        Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                      }, Color(0xFF4CAF50)),
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
        return 'Ups! Kapı Kilitli Gibi 🔒';
      case 'Hata':
        return 'Houston, Bir Sorunumuz Var! 🚀';
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
                        _buildForgotPasswordButton(colors, screenSize),
                        _buildRegisterButton(colors, screenSize),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    _buildMotivationalText(colors, screenSize),
                    SizedBox(height: screenSize.height * 0.01),
                    _buildPhdAcademyText(colors),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
        _lottieFiles[1],
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
          TextField(
            controller: _usernameController,
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
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
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

  Widget _buildLoginButton(Map<String, Color?> colors, Size screenSize) {
    return GestureDetector(
      onTapDown: (_) => _buttonAnimationController.forward(),
      onTapUp: (_) {
        _buttonAnimationController.reverse();
        login(_usernameController.text, _passwordController.text);
      },
      onTapCancel: () => _buttonAnimationController.reverse(),
      child: ScaleTransition(
        scale: _buttonScaleAnimation,
        child: Container(
          width: screenSize.width * 0.8,
          height: screenSize.height * 0.06,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDarkMode
                  ? [Color(0xFF2A5298), Color(0xFF3A6DB0)]
                  : [Color(0xFF4A90E2), Color(0xFF5AB1FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: (_isDarkMode ? Color(0xFF2A5298) : Color(0xFF4A90E2)).withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Giriş Yap',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.045,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton(Map<String, Color?> colors, Size screenSize) {
    return GestureDetector(
      onTapDown: (_) => _buttonAnimationController.forward(),
      onTapUp: (_) {
        _buttonAnimationController.reverse();
        Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordScreen()));
      },
      child: ScaleTransition(
        scale: _buttonScaleAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.04,
              vertical: screenSize.height * 0.015
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDarkMode
                  ? [Color(0xFFB03060), Color(0xFFD2691E)]
                  : [Color(0xFFFE6B8B), Color(0xFFFF8E53)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.2),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: Colors.white, size: screenSize.width * 0.04),
              SizedBox(width: screenSize.width * 0.02),
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
    return GestureDetector(
      onTapDown: (_) => _buttonAnimationController.forward(),
      onTapUp: (_) {
        _buttonAnimationController.reverse();
        Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
      },
      child: ScaleTransition(
        scale: _buttonScaleAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.04,
              vertical: screenSize.height * 0.015
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDarkMode
                  ? [Color(0xFF1E90FF), Color(0xFF4169E1)]
                  : [Color(0xFF36D1DC), Color(0xFF5B86E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.2),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add_alt_1, color: Colors.white, size: screenSize.width * 0.04),
              SizedBox(width: screenSize.width * 0.02),
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
        '"Bir dil öğrenmek, dünyaya açılan bir pencere daha demektir.- Çin Atasözü',
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
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colors["text"]!.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
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
}