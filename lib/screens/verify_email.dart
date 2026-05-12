import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:kelibu/providers/user_provider.dart';
import 'package:kelibu/screens/sdk/customShowDialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../variables.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  VerifyEmailScreen({required this.email});

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  late Box<bool> _loginBox;
  bool _isLoading = false;
  bool _isDarkMode = false;
  final storage = FlutterSecureStorage();
  bool _canResend = false;
  int _resendCooldown = 60;
  List<String> _enteredDigits = ['', '', '', '', '', ''];
  List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
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
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    _startInitialCooldown();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
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
      _canResend = false;
      _resendCooldown = 60;
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
        showCustomDialog(context, 'Başarılı',
            'Yeni doğrulama kodu e-posta adresinize gönderildi.');
        _startInitialCooldown();
      } else {
        final responseBody = json.decode(response.body);
        showCustomDialog(
            context,
            'Hata',
            responseBody['message'] ??
                'Bir hata oluştu. Lütfen tekrar deneyin.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _canResend = true;
      });
      showCustomDialog(
          context, 'Hata', 'Bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _verifyCode() async {
    final enteredCode = _enteredDigits.join();

    if (enteredCode.length != 6) {
      showCustomDialog(context, 'Uyarı',
          'Lütfen 6 haneli doğrulama kodunu eksiksiz giriniz.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

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

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('user')) {
          final userData = responseData['user'];

          final int userId = userData['id'];
          final String userName = userData['name'];
          final String profileImage = userData['avatar'];
          final int point = userData['point'];
          final String email = userData['email'].toString();
          final String phone = userData['phone'].toString();
          final bool phoneVerified = userData['phone_verified'] ?? false;
          final String createdAt = userData['created_at'].toString();
          final String city = userData['city'].toString();
          final int birthYear =
              int.tryParse(userData['birth_year'].toString()) ?? 0;
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
              team);

          _loginBox.put('isLoggedIn', true);

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => MainScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          showCustomDialog(context, 'Hata',
              'Doğrulama başarısız oldu. Lütfen tekrar deneyin.');
        }
      } else {
        final responseBody = response.body;
        try {
          final errorBody = json.decode(responseBody);
          showCustomDialog(context, 'Hata', 'Hata: ${errorBody['message']}');
        } catch (e) {
          showCustomDialog(context, 'Hata', 'Yanıt: $responseBody');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showCustomDialog(
          context, 'Hata', 'Doğrulama işlemi sırasında bir hata oluştu: $e');
    }
  }

  void _onDigitChanged(String value, int index) {
    setState(() {
      _enteredDigits[index] = value;
    });

    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    if (_enteredDigits.every((digit) => digit.isNotEmpty)) {
      _verifyCode();
    }
  }

  Widget _buildCodeInputField(int index) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    return Container(
      width: 48,
      height: 60,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors["inputBackground"],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: _focusNodes[index].hasFocus
                ? colors["blue"]!
                : colors["borderColor"]!,
            width: _focusNodes[index].hasFocus ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.poppins(
            fontSize: 24, color: colors["text"], fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counter: Offstage(),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (value) => _onDigitChanged(value, index),
        // İleriye keypress event ekleyerek, klavye kullanımını daha da iyileştirebilirsiniz
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, Color> colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: 8),
        Hero(
          tag: 'logo',
          child: Container(
            width: 36,
            height: 36,
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: colors["iconBackground"],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors["cardBorder"]!.withOpacity(0.15),
                  blurRadius: 5,
                  offset: Offset(0, 2),
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
        SizedBox(width: 8),
        Text(
          'Kelibu',
          style: GoogleFonts.poppins(
            color: colors["text"],
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colors["background"],
      appBar: AppBar(
        backgroundColor: colors["background"],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: colors["text"], size: 22),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Geri',
        ),
        title: _buildHeader(context, colors),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: screenSize.width * 0.25,
                    height: screenSize.width * 0.25,
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
                    child: Icon(
                      Icons.email_outlined,
                      size: screenSize.width * 0.12,
                      color: colors["blue"],
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'E-posta Doğrulama',
                    style: GoogleFonts.poppins(
                      color: colors["text"],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${widget.email} adresine gönderilen 6 haneli kodu giriniz',
                      style: GoogleFonts.poppins(
                        color: colors["text"]!.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 32),
                  // Kod girişi için field'ları içeren Container
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors["cardBackground"],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colors["cardBorder"]!.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Doğrulama Kodu',
                            style: GoogleFonts.poppins(
                              color: colors["text"],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                              6, (index) => _buildCodeInputField(index)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  _isLoading
                      ? CircularProgressIndicator(
                          color: colors["buttonBackground"])
                      : ElevatedButton(
                          onPressed: _verifyCode,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: colors["buttonText"],
                            backgroundColor: colors["buttonBackground"],
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            'Doğrula',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                  SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: _canResend ? _resendVerificationCode : null,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: _canResend
                          ? colors["blue"]
                          : colors["unselectedText"],
                    ),
                    label: Text(
                      _canResend
                          ? 'Yeni kod gönder'
                          : 'Yeni kod gönder ($_resendCooldown)',
                      style: GoogleFonts.poppins(
                        color: _canResend
                            ? colors["blue"]
                            : colors["unselectedText"],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'E-posta adresini değiştir',
                      style: GoogleFonts.poppins(
                        color: colors["text"]!.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                      ),
                    ),
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
