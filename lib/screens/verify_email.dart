import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kelibu/screens/sdk/customShowDialog.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';
import '../variables.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  VerifyEmailScreen({required this.email});

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> with SingleTickerProviderStateMixin {
  late Box<bool> _loginBox;
  bool _isLoading = false;
  bool _isDarkMode = false;
  final storage = FlutterSecureStorage();
  bool _canResend = false;
  int _resendCooldown = 60;
  List<String> _enteredDigits = ['', '', '', '', '', ''];
  List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _openHiveBox();
    _loadDarkModePreference();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    _startInitialCooldown();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _openHiveBox() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    _loginBox = await Hive.openBox<bool>('loginBox');
  }

  Future<void> _loadDarkModePreference() async {
    String? darkModePreference = await storage.read(key: "darkMode");
    if (darkModePreference != null) {
      setState(() {
        _isDarkMode = darkModePreference == "true";
      });
    }
  }

  void _startInitialCooldown() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendVerificationCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://www.kelibu.net/api/resend-verification-code'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-Custom-Header': privacyKey.privacyKeyVariable,
        },
        body: jsonEncode(<String, String>{
          'email': widget.email,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        showCustomDialog(context, 'Başarılı', 'Yeni doğrulama kodu e-posta adresinize gönderildi.');
        _startInitialCooldown();
      } else {
        final responseBody = json.decode(response.body);
        showCustomDialog(context, 'Hata', responseBody['message'] ?? 'Bir hata oluştu. Lütfen tekrar deneyin.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showCustomDialog(context, 'Hata', 'Bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
    });

    final enteredCode = _enteredDigits.join();

    try {
      final response = await http.post(
        Uri.parse('https://www.kelibu.net/api/verify-email-mobile'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-Custom-Header': privacyKey.privacyKeyVariable,
        },
        body: jsonEncode(<String, String>{
          'email': widget.email,
          'code': enteredCode,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('user')) {
          final userData = responseData['user'];

          final int userId = userData['id'];
          final String userName = userData['name'];
          final String profileImage = userData['avatar'];
          final int point = userData['point'];
          final String email = userData['email'].toString();
          final String phone = userData['phone'].toString();
          final bool phoneVerified = userData['phone_verified']??false;
          final String createdAt = userData['created_at'].toString();
          final String city = userData['city'].toString();
          final int birthYear = int.tryParse(userData['birth_year'].toString()) ?? 0;
          final String? team = userData['team'];

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
              team
          );

          _loginBox.put('isLoggedIn', true);

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => MainScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          showCustomDialog(context, 'Hata', 'Doğrulama başarısız oldu. Lütfen tekrar deneyin.');
        }
      } else {
        final responseBody = response.body;
        try {
          final errorBody = json.decode(responseBody);
          showCustomDialog(context, 'Hata', 'Doğrulama işlemi başarısız. Durum Kodu: ${response.statusCode}, Hata: ${errorBody['error']}');
        } catch (e) {
          showCustomDialog(context, 'Hata', 'Doğrulama işlemi başarısız. Durum Kodu: ${response.statusCode}, Yanıt: $responseBody');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showCustomDialog(context, 'Hata', 'Doğrulama işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  Widget _buildCodeInputField(int index) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    return Container(
      width: 50,
      height: 60,
      margin: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: colors["inputBackground"],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors["borderColor"]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.poppins(
            fontSize: 24,
            color: colors["text"],
            fontWeight: FontWeight.w600
        ),
        decoration: InputDecoration(
          counter: Offstage(),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            _enteredDigits[index] = value;
          });
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }
          if (_enteredDigits.every((digit) => digit.isNotEmpty)) {
            _verifyCode();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: colors["background"],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Hero(
                      tag: 'logo',
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: MediaQuery.of(context).size.width * 0.3,
                        decoration: BoxDecoration(
                          color: colors["iconBackground"],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors["cardBorder"]!.withOpacity(0.2),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    Text(
                      'E-posta Doğrulama',
                      style: GoogleFonts.poppins(
                        color: colors["text"],
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      '${widget.email} adresine gönderilen 6 haneli kodu giriniz',
                      style: GoogleFonts.poppins(color: colors["text"], fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) => _buildCodeInputField(index)),
                    ),
                    SizedBox(height: 40),
                    _isLoading
                        ? CircularProgressIndicator(color: colors["buttonBackground"])
                        : ElevatedButton(
                      onPressed: _verifyCode,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: colors["buttonText"],
                        backgroundColor: colors["buttonBackground"],
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'Doğrula',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(height: 25),
                    TextButton(
                      onPressed: _canResend ? _resendVerificationCode : null,
                      child: Text(
                        _canResend
                            ? 'Yeni kod gönder'
                            : 'Yeni kod gönder ($_resendCooldown)',
                        style: GoogleFonts.poppins(
                          color: _canResend
                              ? colors["blue"]
                              : colors["unselectedText"],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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