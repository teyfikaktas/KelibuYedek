import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'login_screen.dart'; // Önceden oluşturduğunuz Giriş Ekranı
import 'package:http/http.dart' as http;
import 'package:kelibu/variables.dart'; // Önceden oluşturduğunuz Giriş Ekranı

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty || value.length != 10 || !value.startsWith(RegExp(r'[1-9]')) || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Lütfen geçerli bir telefon numarası giriniz (Örn: 5555555)';
    }
    return null;
  }

  Future<void> sendNewPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://www.kelibu.net/api/send-new-password'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header added
        },
        body: jsonEncode(<String, String>{
          'phone': _phoneController.text,
        }),
      );

      if (response.statusCode == 200) {
        GFToast.showToast(
          'Yeni şifre başarıyla gönderildi.',
          context,
          toastPosition: GFToastPosition.BOTTOM,
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.pink),
          onPressed: () {
            // LoginScreen'e yönlendirir ve Navigator yığınını sıfırlar
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
          },
        ),

        title: Text(
          "Şifremi Unuttum",
          style: TextStyle(
            color: Colors.pink, // Başlık metin rengi pembe
          ),
        ),
        backgroundColor: Colors.white, // AppBar arka plan rengi beyaz
        iconTheme: IconThemeData(color: Colors.pink), // Geri butonu dahil AppBar ikon rengi
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset('assets/logo.png', height: 120),
                  SizedBox(height: 40),
                  Text(
                    "Telefon numaranıza geçici şifre gönderilecektir.",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: "Telefon Numarası",
                      prefixIcon: Icon(Icons.phone, color: Colors.pink), // İkon rengi
                      labelStyle: TextStyle(color: Colors.pink), // Etiket metin rengi
                    ),
                    keyboardType: TextInputType.phone,
                    validator: validatePhoneNumber,
                  ),
                  SizedBox(height: 20),
                  GFButton(
                    onPressed: sendNewPassword,
                    text: "Şifremi Gönder",
                    color: Colors.pink, // Buton rengi
                    textStyle: TextStyle(fontSize: 16), // Buton metin stili
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
