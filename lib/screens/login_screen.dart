import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/main.dart';
import 'package:kelibu/screens/sdk/customShowDialog.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kelibu/variables.dart';

import 'register_screen.dart';
import 'reset_password_screen.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    openHiveBox().then((_) {
      checkLoginStatus();
    });
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
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header ekleme
      },
      body: jsonEncode(<String, String>{
        'email': username,
        'password': password,
      }),
    );


    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print(responseData);


      // API'den gelen response verisini kullanarak kullanıcı bilgilerini ayarlayan kod bloğu
      final int userId = responseData['id'];
      final String userName = responseData['name'];
      final String profileImage = responseData['avatar'];
      final int point = responseData['point'];
      final String email = responseData['email'].toString();
      final String phone = responseData['phone'].toString();
      final String phoneVerified = responseData['phone_verified'].toString(); // Anahtar ismini düzelttim
      final String createdAt = responseData['created_at'].toString();
      final String city = responseData['city'].toString(); // Yeni alan
      final int birthYear = int.tryParse(responseData['birth_year'].toString()) ?? 0; // Yeni alan, varsayılan değer 0
      final String? team = responseData['team']; // Yeni alan, null olabilir

      Provider.of<UserProvider>(context, listen: false).setUser(
          userName,
          userId,
          profileImage,
          point,
          email,
          phone,
          phoneVerified,
          createdAt,
          city, // Yeni alanı ekliyoruz
          birthYear, // Yeni alanı ekliyoruz
          team // Yeni alanı ekliyoruz, null olabilir
      );
      _loginBox.put('isLoggedIn', true);

      setState(() {
        _isLoggedIn = true;
      });

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    }
    // login fonksiyonunuzun içinde, başarısız giriş denemesi sonrası
    else {
      showCustomDialog(context, 'Hata', 'Kayıt Bulunamadı. Lütfen bilgilerinizi kontrol edip tekrar deneyin.');
    }

  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.pink[300]), // Etiket rengi
        fillColor: Colors.pink[50], // Input alanı arka plan rengi
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.pink[100]!), // Kenarlık rengi
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.pink[100]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.pink[300]!, width: 2), // Odaklanıldığında kenarlık rengi
        ),
      ),
      style: TextStyle(color: Colors.pink[800]), // Metin rengi
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      height: 50, // Buton yüksekliği
      child: ElevatedButton(
        onPressed: () {
           login(_usernameController.text, _passwordController.text);
        },
        style: ElevatedButton.styleFrom(
          primary: Colors.pink[400], // Buton rengi
          onPrimary: Colors.white, // Buton içindeki metin ve ikon rengi
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          'Giriş Yap',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0EAE2), // Arka plan rengi
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Image.asset('assets/logo.png', height: 120),
                        SizedBox(height: 20),
                        Text(
                          'Giriş Yap',
                          style: GoogleFonts.roboto(
                            color: Colors.pink[800], // Başlık metin rengi
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.width * 0.1),
                        _buildTextField(_usernameController, 'E-posta'),
                        SizedBox(height: MediaQuery.of(context).size.width * 0.05),
                        _buildTextField(_passwordController, 'Şifre', isPassword: true),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                              );
                            },
                            child: Text(
                              'Şifremi unuttum?',
                              style: TextStyle(color: Colors.pink[800]), // Link metin rengi
                            ),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.width * 0.2),
                        _buildLoginButton(context),
                        TextButton(
                          onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => WebViewPage()));
                          },
                          child: Text(
                            'Henüz kayıt olmadıysan kayıt ol',
                            style: TextStyle(color: Colors.pink[800]), // Link metin rengi
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
