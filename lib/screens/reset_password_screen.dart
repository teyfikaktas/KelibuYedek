import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:kelibu/variables.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kelibu/screens/sdk/customShowDialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  bool _isDarkMode = false;
  bool _isLoading = false;
  final FlutterSecureStorage storage = FlutterSecureStorage();
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
    try {
      String data = await DefaultAssetBundle.of(context).loadString('assets/brain.json');
      List<dynamic> jsonResult = json.decode(data);
      setState(() {
        _brainQuotes = jsonResult.map((item) => item['quote'].toString()).toList();
      });
    } catch (e) {
      print('Brain quotes yüklenirken hata oluştu: $e');
      // Hata durumunda gerekli önlemleri alabilirsiniz
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Lütfen geçerli bir e-posta adresi giriniz';
    }
    return null;
  }

  Future<void> sendNewPassword() async {
    if (_emailFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://www.kelibu.net/api/send-new-password-email'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'X-Custom-Header': privacyKey.privacyKeyVariable,
          },
          body: jsonEncode(<String, String>{
            'email': _emailController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        final responseData = json.decode(response.body);
        print('API Response: $responseData');

        if (response.statusCode == 200) {
          // Dialog'u göstermek ve tamamlanmasını beklemek için await kullanıyoruz
          await showCustomDialog(context, 'Başarılı', 'Yeni şifre E-posta adresinize başarıyla gönderildi. E-posta istenmeyen klasörüne düşebilir. Kontrol etmeyi unutmayın!');

          // Tüm önceki sayfaları kaldırarak LoginScreen'e yönlendirme
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          // Hata durumunda dialog gösterme
          await showCustomDialog(context, 'Hata', responseData['message'] ?? 'Bilinmeyen bir hata oluştu.');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        // Bağlantı hatası gibi durumlarda dialog gösterme
        await showCustomDialog(
          context,
          'Hata',
          'Bağlantı hatası: Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.\n\nHata detayı: ${e.toString()}',
        );
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isEmail = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey),
          prefixIcon: Icon(isEmail ? Icons.email : Icons.phone, color: _isDarkMode ? Colors.white70 : Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.phone,
        validator: isEmail ? validateEmail : null,
      ),
    );
  }

  Widget _buildSendButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        child: _isLoading
            ? CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        )
            : Text(
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Şifremi Unuttum',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Şifre Sıfırlama Başlığı
              Text(
                "Şifremi Unuttum",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 10),
              // Açıklama
              Text(
                "E-posta adresinize geçici şifre gönderilecektir.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
              SizedBox(height: 30),
              // Şifre Sıfırlama Formu
              Container(
                padding: EdgeInsets.all(20),
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
                child: Form(
                  key: _emailFormKey,
                  child: Column(
                    children: [
                      _buildTextField(_emailController, 'E-posta Adresi', isEmail: true),
                      SizedBox(height: 10),
                      _buildSendButton('Şifremi Gönder', Colors.blue, sendNewPassword),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15),
              // Giriş Yap Linki
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                        (Route<dynamic> route) => false,
                  );
                },
                child: Text(
                  'Hesabın var mı? Giriş Yap',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              SizedBox(height: 30),
              // Alıntı
              if (_brainQuotes.isNotEmpty)
                Text(
                  _brainQuotes[DateTime.now().millisecond % _brainQuotes.length],
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: _isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 10),
              // Footer
              Text(
                'Kelibu, bir PhD Akademi ürünüdür.',
                style: TextStyle(
                  fontSize: 14,
                  color: _isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
