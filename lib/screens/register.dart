import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:kelibu/screens/verify_email.dart';
import 'dart:convert';
import 'package:kelibu/screens/sdk/customShowDialog.dart';
import 'package:kelibu/variables.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isDarkMode = false;
  final storage = FlutterSecureStorage();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  List<String> _brainQuotes = [];

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _loadBrainQuotes();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Future<void> _loadBrainQuotes() async {
    String data = await DefaultAssetBundle.of(context).loadString('assets/brain.json');
    List<dynamic> jsonResult = json.decode(data);
    setState(() {
      _brainQuotes = jsonResult.map((item) => item['quote'].toString()).toList();
    });
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> register() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://www.kelibu.net/api/registerCreateApi'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-Custom-Header': 'Hilal',
        },
        body: jsonEncode(<String, String>{
          'name': _usernameController.text,
          'email': _emailController.text,
          'phone': '000000000', // Varsayılan değer, gerekirse değiştirin
          'password': _passwordController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      // İçerik tipi JSON mu kontrol et
      if (response.headers['content-type'] != null &&
          response.headers['content-type']!.contains('application/json')) {
        final responseData = json.decode(response.body);
        print(responseData);

        if (response.statusCode == 201) {
          // Yeni kullanıcı başarıyla oluşturuldu
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyEmailScreen(email: _emailController.text),
            ),
          );
          showCustomDialog(context, 'Başarılı', responseData['message']);
        } else if (response.statusCode == 200) {
          // Kullanıcı zaten var, yeni doğrulama kodu gönderildi
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyEmailScreen(email: _emailController.text),
            ),
          );
          showCustomDialog(context, 'Bilgi', responseData['message']);
        } else if (response.statusCode == 422) {
          // Doğrulama hatası
          String errorMessage = 'Girdiğiniz bilgilerde bazı hatalar var:';
          if (responseData['errors'] != null) {
            (responseData['errors'] as Map<String, dynamic>).forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errorMessage += '\n- ${value[0]}';
              }
            });
          } else {
            errorMessage = responseData['message'] ?? 'Bilinmeyen bir doğrulama hatası oluştu.';
          }
          showCustomDialog(context, 'Hata', errorMessage);
        } else if (response.statusCode == 400) {
          // E-posta zaten doğrulanmış veya diğer 400 hataları
          showCustomDialog(context, 'Hata', responseData['message']);
        } else if (response.statusCode == 429) {
          // Çok fazla deneme hatası
          showCustomDialog(context, 'Hata', responseData['message'] ?? 'Çok fazla deneme yapıyorsunuz. Lütfen daha sonra tekrar deneyin.');
        } else {
          // Diğer hatalar
          showCustomDialog(context, 'Hata', responseData['message'] ?? 'Bilinmeyen bir hata oluştu.');
        }
      } else {
        // JSON olmayan yanıtlar için genel hata mesajı
        showCustomDialog(context, 'Hata', 'Sunucudan beklenmeyen bir yanıt alındı.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showCustomDialog(context, 'Hata', 'Bağlantı hatası: Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.\n\nHata detayı: ${e.toString()}');
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey),
          prefixIcon: Icon(icon, color: _isDarkMode ? Colors.white70 : Colors.grey),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: _isDarkMode ? Colors.white70 : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.all(constraints.maxWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: _isDarkMode ? Colors.white : Colors.black,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            IconButton(
                              icon: Icon(Icons.help_outline, color: _isDarkMode ? Colors.white : Colors.black),
                              onPressed: () {
                                // Yardım sayfasına yönlendirme yapılabilir
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: constraints.maxHeight * 0.02),
                        Center(
                          child: Container(
                            width: constraints.maxWidth * 0.25,
                            height: constraints.maxWidth * 0.25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage('assets/logo.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.01),
                        Center(
                          child: Text(
                            "Kelibu'ya Hoş Geldiniz!",
                            style: TextStyle(
                              fontSize: constraints.maxWidth * 0.05,
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.005),
                        Center(
                          child: Text(
                            "Kelime haznenizi genişletmeye hazır mısınız?",
                            style: TextStyle(
                              fontSize: constraints.maxWidth * 0.035,
                              color: _isDarkMode ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.03),
                        Container(
                          padding: EdgeInsets.all(constraints.maxWidth * 0.05),
                          decoration: BoxDecoration(
                            color: _isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildTextField(_usernameController, 'Kullanıcı Adı', Icons.person),
                              _buildTextField(_emailController, 'E-posta', Icons.email),
                              _buildTextField(_passwordController, 'Şifre', Icons.lock, isPassword: true),
                              _buildTextField(_confirmPasswordController, 'Şifre Tekrar', Icons.lock, isPassword: true),
                              SizedBox(height: constraints.maxHeight * 0.01),
                              _isLoading
                                  ? Center(child: CircularProgressIndicator())
                                  : _buildButton('Kayıt Ol', Colors.blue, register),
                            ],
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.015),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Zaten hesabın var mı? Giriş Yap',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),
                        Spacer(),
                        if (_brainQuotes.isNotEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: constraints.maxHeight * 0.01),
                              child: Text(
                                _brainQuotes[DateTime.now().millisecond % _brainQuotes.length],
                                style: TextStyle(
                                  fontSize: constraints.maxWidth * 0.03,
                                  fontStyle: FontStyle.italic,
                                  color: _isDarkMode ? Colors.white70 : Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        Center(
                          child: Text(
                            'Kelibu, bir PhD Akademi ürünüdür.',
                            style: TextStyle(
                              fontSize: constraints.maxWidth * 0.03,
                              color: _isDarkMode ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}