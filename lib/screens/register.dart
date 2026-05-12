import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kelibu/screens/sdk/customShowDialog.dart';
import 'package:kelibu/screens/verify_email.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _isDarkMode = false;
  final storage = FlutterSecureStorage();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  List<String> _brainQuotes = [];

  final ApiService _apiService = ApiService();

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
    String data =
        await DefaultAssetBundle.of(context).loadString('assets/brain.json');
    List<dynamic> jsonResult = json.decode(data);
    setState(() {
      _brainQuotes =
          jsonResult.map((item) => item['quote'].toString()).toList();
    });
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isStrongPassword(String password) {
    RegExp regex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$');
    return regex.hasMatch(password);
  }

  Future<String?> _getFCMToken() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        }
      }

      String? token = await FirebaseMessaging.instance.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<void> register() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      // FCM token al
      String? fcmToken = await _getFCMToken();

      final responseData = await _apiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        passwordConfirmation: _confirmPasswordController.text.trim(),
        fcmToken: fcmToken ?? '',
      );

      _handleSuccessfulRegistration(responseData);
    } on ApiException catch (e) {
      _handleApiException(e);
    } catch (e) {
      _handleGeneralException(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      showCustomDialog(
          context, 'Eksik Bilgi', 'Lütfen tüm alanları doldurunuz.');
      return false;
    }

    if (!isValidEmail(_emailController.text.trim())) {
      showCustomDialog(context, 'Geçersiz E-posta',
          'Lütfen geçerli bir e-posta adresi giriniz.');
      return false;
    }

    if (!isStrongPassword(_passwordController.text.trim())) {
      showCustomDialog(context, 'Zayıf Şifre',
          'Şifreniz en az 8 karakter olmalı ve büyük harf, küçük harf ve rakam içermelidir.');
      return false;
    }

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      showCustomDialog(context, 'Şifre Uyuşmazlığı',
          'Girdiğiniz şifreler birbiriyle uyuşmuyor.');
      return false;
    }

    return true;
  }

  void _handleSuccessfulRegistration(Map<String, dynamic> responseData) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              VerifyEmailScreen(email: _emailController.text.trim())),
    );
    showCustomDialog(context, 'Doğrulama Gerekli',
        'Lütfen e-postanıza gönderilen doğrulama kodunu giriniz.');
  }

  void _handleApiException(ApiException e) {
    String message = 'Bir hata oluştu. ';

    if (e.details != null && e.details!.containsKey('errors')) {
      final errors = e.details?['errors'] as List<dynamic>;
      if (errors.isNotEmpty) {
        message = errors.join('\n');
      }
    } else {
      message += 'Lütfen daha sonra tekrar deneyiniz.';
    }

    showCustomDialog(context, 'Kayıt Hatası', message);
  }

  void _handleGeneralException(Object e) {
    String errorMessage = e.toString().toLowerCase();
    String title = 'Beklenmeyen Hata';
    String content = e.toString();

    if (errorMessage.contains('zaten kullanımda') ||
        errorMessage.contains('unique')) {
      title = 'E-posta Kullanımda';
      content =
          'E-posta adresi zaten kullanımda. Giriş ekranından giriş yapabilirsiniz.';
    } else if (errorMessage.contains('e-posta alanı') ||
        errorMessage.contains('email')) {
      title = 'E-posta Hatası';
      if (errorMessage.contains('gereklidir')) {
        content = 'E-posta alanı gereklidir.';
      } else if (errorMessage.contains('geçerli')) {
        content = 'Geçerli bir e-posta adresi girin.';
      }
    } else if (errorMessage.contains('isim alanı')) {
      title = 'İsim Hatası';
      content = 'İsim alanı gereklidir.';
    } else if (errorMessage.contains('şifre')) {
      title = 'Şifre Hatası';
      if (errorMessage.contains('gereklidir')) {
        content = 'Şifre alanı gereklidir.';
      } else if (errorMessage.contains('en az 8')) {
        content = 'Şifreniz en az 8 karakterden oluşmalıdır.';
      } else if (errorMessage.contains('eşleşmiyor')) {
        content = 'Şifreler eşleşmiyor.';
      }
    }
    showCustomDialog(context, title, content);
  }

  Future<bool> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false, bool isConfirm = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
        obscureText: isPassword &&
            !(isConfirm ? _isConfirmPasswordVisible : _isPasswordVisible),
        keyboardType: isConfirm ? TextInputType.visiblePassword : null,
        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey),
          prefixIcon:
              Icon(icon, color: _isDarkMode ? Colors.white70 : Colors.grey),
          suffixIcon: isPassword || isConfirm
              ? IconButton(
                  icon: Icon(
                    isConfirm
                        ? (_isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off)
                        : (_isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                    color: _isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirm) {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      } else {
                        _isPasswordVisible = !_isPasswordVisible;
                      }
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (value) {
          controller.text = value.trim();
          controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length));
        },
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
                                color:
                                    _isDarkMode ? Colors.white : Colors.black,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            IconButton(
                              icon: Icon(Icons.help_outline,
                                  color: _isDarkMode
                                      ? Colors.white
                                      : Colors.black),
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
                            color:
                                _isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildTextField(
                                  _nameController, 'İsim', Icons.person),
                              _buildTextField(
                                  _emailController, 'E-posta', Icons.email),
                              _buildTextField(
                                  _passwordController, 'Şifre', Icons.lock,
                                  isPassword: true),
                              _buildTextField(_confirmPasswordController,
                                  'Şifre Tekrar', Icons.lock,
                                  isPassword: true, isConfirm: true),
                              SizedBox(height: constraints.maxHeight * 0.01),
                              _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : _buildButton(
                                      'Kayıt Ol', Colors.blue, register),
                            ],
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.015),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Zaten hesabın var mı? Giriş Yap',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),
                        Spacer(),
                        if (_brainQuotes.isNotEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: constraints.maxHeight * 0.01),
                              child: Text(
                                _brainQuotes[DateTime.now().millisecond %
                                    _brainQuotes.length],
                                style: TextStyle(
                                  fontSize: constraints.maxWidth * 0.03,
                                  fontStyle: FontStyle.italic,
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.grey,
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
