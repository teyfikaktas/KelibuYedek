import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kelibu/screens/login_screen.dart';
import 'package:kelibu/screens/sdk/customShowDialog.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../main.dart';
import '../variables.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  VerifyEmailScreen({required this.email});

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final TextEditingController _codeController = TextEditingController();
  late Box<bool> _loginBox;
  bool _isLoading = false;
  bool _isDarkMode = false;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    openHiveBox();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    String? darkModePreference = await storage.read(key: "darkMode");
    if (darkModePreference != null) {
      setState(() {
        _isDarkMode = darkModePreference == "true";
      });
    }
  }

  Future<void> openHiveBox() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    _loginBox = await Hive.openBox<bool>('loginBox');
  }

  Future<void> verifyCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://www.kelibu.net/api/verify-email-mobile'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-Custom-Header': 'Hilal',
        },
        body: jsonEncode(<String, String>{
          'email': widget.email,
          'code': _codeController.text,
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
          final String phoneVerified = userData['phone_verified'].toString();
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
            MaterialPageRoute(builder: (context) =>  MainScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          showCustomDialog(context, 'Hata', 'Doğrulama başarısız oldu. Lütfen tekrar deneyin.');
        }
      } else {
        final responseBody = response.body;
        try {
          final errorBody = json.decode(responseBody);
          print('Hata: $responseBody');
          showCustomDialog(context, 'Hata', 'Doğrulama işlemi başarısız. Durum Kodu: ${response.statusCode}, Hata: ${errorBody['error']}');
        } catch (e) {
          print('Yanıt çözümleme hatası: $e');
          showCustomDialog(context, 'Hata', 'Doğrulama işlemi başarısız. Durum Kodu: ${response.statusCode}, Yanıt: $responseBody');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Doğrulama işlemi sırasında hata: $e');
      showCustomDialog(context, 'Hata', 'Doğrulama işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
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

  Widget _buildVerifyButton(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.07,
      child: ElevatedButton(
        onPressed: verifyCode,
        style: ElevatedButton.styleFrom(
          primary: colors["buttonBackground"],
          onPrimary: colors["buttonText"],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          'Doğrula ve Giriş Yap',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.05,
            color: colors["buttonText"],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: colors["background"],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: MediaQuery.of(context).size.width * 0.3,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white : Colors.transparent,
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
                  'E-posta Doğrulama',
                  style: GoogleFonts.roboto(
                    color: colors["text"],
                    fontSize: MediaQuery.of(context).size.width * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildTextField(_codeController, 'Doğrulama Kodu'),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _isLoading
                    ? CircularProgressIndicator() // Bekleme göstergesi
                    : _buildVerifyButton(context),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Geri tuşuna bastığında önceki sayfaya döner
                  },
                  child: Text(
                    'Yanlış kod mu? Tekrar Gönder',
                    style: TextStyle(color: colors["text"]),
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
