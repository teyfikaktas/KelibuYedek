import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:kelibu/variables.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  bool _isDarkMode = false;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }


  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty || value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Lütfen geçerli bir telefon numarası giriniz (Örn: 5555555555)';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Lütfen geçerli bir e-posta adresi giriniz';
    }
    return null;
  }

  Future<void>  sendNewPassword(String endpoint, String identifierKey, String identifierValue) async {
    try {
      final response = await http.post(
        Uri.parse('https://www.kelibu.net/api/$endpoint'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Custom-Header': privacyKey.privacyKeyVariable,
        },
        body: jsonEncode(<String, String>{
          identifierKey: identifierValue,
        }),
      );

      if (response.statusCode == 200) {
        GFToast.showToast(
          'Yeni şifre başarıyla gönderildi.',
          context,
          toastPosition: GFToastPosition.BOTTOM,
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (Route<dynamic> route) => false,
        );
      } else {
        GFToast.showToast(
          'Hata alındı, lütfen tekrar deneyiniz.',
          context,
          toastPosition: GFToastPosition.BOTTOM,
        );
      }
    } catch (e) {
      GFToast.showToast(
        'Hata alındı, lütfen tekrar deneyiniz.',
        context,
        toastPosition: GFToastPosition.BOTTOM,
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isEmail = false}) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(isEmail ? Icons.email : Icons.phone, color: colors["text"]),
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
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.phone,
      validator: isEmail ? validateEmail : validatePhoneNumber,
    );
  }

  Widget _buildSendButton(BuildContext context, String label, GlobalKey<FormState> formKey, String endpoint, String identifierKey, TextEditingController controller) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.07,
      child: ElevatedButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            sendNewPassword(endpoint, identifierKey, controller.text);
          }
        },
        style: ElevatedButton.styleFrom(
          primary: colors["buttonBackground"],
          onPrimary: colors["buttonText"],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors["text"]),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
          },
        ),
        title: Text(
          "Şifremi Unuttum",
          style: TextStyle(
            color: colors["text"],
          ),
        ),
        backgroundColor: colors["background"],
        iconTheme: IconThemeData(color: colors["text"]),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Telefon ile'),
            Tab(text: 'E-posta ile'),
          ],
          indicatorColor: colors["text"],
          labelColor: colors["text"],
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Telefon ile şifre sıfırlama
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _phoneFormKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        "Telefon numaranıza geçici şifre gönderilecektir.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors["text"]),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      _buildTextField(_phoneController, 'Telefon Numarası'),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      _buildSendButton(context, "Şifremi Gönder", _phoneFormKey, 'send-new-password', 'phone', _phoneController),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // E-posta ile şifre sıfırlama
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _emailFormKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        "E-posta adresinize geçici şifre gönderilecektir.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors["text"]),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      _buildTextField(_emailController, 'E-posta Adresi', isEmail: true),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      _buildSendButton(context, "Şifremi Gönder", _emailFormKey, 'send-new-password-email', 'email', _emailController),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
