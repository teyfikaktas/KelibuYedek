import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/screens/register.dart';
import 'package:kelibu/screens/register_screen.dart';
import 'package:kelibu/screens/sdk/customShowDialog.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globalDart/urls.dart';
import '../main.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kelibu/variables.dart';
import 'reset_password_screen.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  final String username;
  final String password;

  LoginScreen({this.username = '', this.password = ''});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoggedIn = false;
  bool _obscureText = true;
  bool _isDarkMode = false;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    openHiveBox().then((_) {
      checkLoginStatus();
      if (widget.username.isNotEmpty && widget.password.isNotEmpty) {
        _usernameController.text = widget.username;
        _passwordController.text = widget.password;
        login(widget.username, widget.password);
      }
    });
    _loadDarkModePreference();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeMessage());

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

  late Box<bool> _loginBox;

  Future<void> openHiveBox() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    _loginBox = await Hive.openBox<bool>('loginBox');
  }

  Future<void> checkLoginStatus() async {
    bool isLoggedIn = _loginBox.get('isLoggedIn') ?? false;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  Future<void> login(String username, String password) async {
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
      print(responseData);

      final int userId = responseData['id'];
      final String userName = responseData['name'];
      final String profileImage = responseData['avatar'];
      final int point = responseData['point'];
      final String email = responseData['email'].toString();
      final String phone = responseData['phone'].toString();
      final String phoneVerified = responseData['phone_verified'].toString();
      final String createdAt = responseData['created_at'].toString();
      final String city = responseData['city'].toString();
      final int birthYear = int.tryParse(responseData['birth_year'].toString()) ?? 0;
      final String? team = responseData['team'];

      Provider.of<UserProvider>(context, listen: false).setUser(
        userName,
        userId,
        profileImage,
        point,
        email,
        phone,
        phoneVerified,
        createdAt,
        city,
        birthYear,
        team,
      );
      _loginBox.put('isLoggedIn', true);

      setState(() {
        _isLoggedIn = true;
      });

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  MainScreen()));
    } else {
      showCustomDialog(context, 'Hata', 'Kayıt Bulunamadı. Lütfen bilgilerinizi kontrol edip tekrar deneyin.');
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false}) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return TextField(
      controller: controller,
      obscureText: isPassword && _obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(isPassword ? Icons.lock : Icons.email, color: colors["text"]),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: colors["text"]),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        )
            : null,
        labelStyle: TextStyle(color: colors["text"]),
        fillColor: colors["background"],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: colors["borderColor"]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: colors["borderColor"]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: colors["borderColor"]!, width: 2),
        ),
      ),
      style: TextStyle(color: colors["text"]),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.07,
      child: ElevatedButton(
        onPressed: () {
          login(_usernameController.text, _passwordController.text);
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: colors["buttonText"], backgroundColor: colors["buttonBackground"],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          'Giriş Yap',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.05,
            color: colors["buttonText"],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Container(
      width: MediaQuery.of(context).size.width * 0.15,
      height: MediaQuery.of(context).size.width * 0.15,
      decoration: BoxDecoration(
        color: colors["iconBackground"],
        shape: BoxShape.circle,
        border: Border.all(color: colors["borderColor"]!, width: 1),
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: colors["text"]),
        iconSize: MediaQuery.of(context).size.width * 0.07,
      ),
    );
  }



  Future<void> _showWelcomeMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasShownWelcomeMessage = prefs.getBool('hasShownWelcomeMessage') ?? false;

    if (!hasShownWelcomeMessage) {
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 80,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Hoş Geldiniz! 🎉',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Yeni bir maceraya hazır mısınız?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.blue[600]),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.orange),
                      SizedBox(width: 5),
                      Text(
                        'Sağ üst köşedeki "?" işaretini',
                        style: TextStyle(fontSize: 16, color: Colors.orange[700]),
                      ),
                    ],
                  ),
                  Text(
                    'keşfetmeyi unutmayın!',
                    style: TextStyle(fontSize: 16, color: Colors.orange[700]),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Harika sürprizler sizi bekliyor! 🎁✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.green[600],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text(
                      'Anladım, Başlayalım!',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Dialog kapandıktan sonra değeri kaydet
      await prefs.setBool('hasShownWelcomeMessage', true);
    }
  }

  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: colors["background"],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _toggleDarkMode,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors["text"]?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                              color: colors["text"],
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.login)),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors["text"]?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.help_outline,
                              color: colors["text"],
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: MediaQuery.of(context).size.width * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    'Giriş Yap',
                    style: GoogleFonts.roboto(
                      color: colors["text"],
                      fontSize: MediaQuery.of(context).size.width * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildTextField(_usernameController, 'E-posta'),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildTextField(_passwordController, 'Şifre', isPassword: true),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        'Şifremi unuttum?',
                        style: TextStyle(color: colors["text"]),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildLoginButton(context),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Henüz hesabın yok mu? Kayıt ol',
                      style: TextStyle(color: colors["text"]),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    'Yakında aşağıdaki seçeneklerle giriş yapabileceksiniz:',
                    style: TextStyle(color: colors["text"]),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(Icons.g_mobiledata_sharp),
                      _buildSocialButton(Icons.facebook),
                      _buildSocialButton(Icons.apple),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    'Bağlanabileceğiniz seçenekler yakında sizlerle.',
                    style: TextStyle(color: colors["text"]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
