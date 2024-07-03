import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kelibu/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/variables.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactFormPage extends StatefulWidget {
  @override
  _ContactFormPageState createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Genel Sıkıntı';
  final List<String> _categories = ['Genel Sıkıntı', 'Hata Bildirimi', 'Görüş ve Öneri'];
  String _description = '';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Future<void> sendMessage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    var url = Uri.parse('https://kelibu.net/api/send-message');
    var message = '$_selectedCategory  $_description';
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Add your custom header here
      },
      body: json.encode({
        'user_id': userProvider.userId.toString(),
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gelişmemize verdiğiniz desteklerden dolayı teşekkür ederiz.')),
      );
    } else {
      print('Mesaj gönderilirken bir hata oluştu: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = _isDarkMode ? darkModeColors : lightModeColors;
    final backgroundColor = themeColors["background"];
    final textColor = themeColors["text"];
    final inputBackgroundColor = themeColors["inputBackground"];
    final buttonBackgroundColor = themeColors["buttonBackground"];
    final buttonTextColor = themeColors["buttonText"];
    final appBarColor = _isDarkMode ? Colors.black : Colors.white;
    final appBarTextColor = _isDarkMode ? Colors.white : Colors.pink;
    final iconColor = _isDarkMode ? Colors.white : Colors.pink;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(
          'İletişim Formu',
          style: GoogleFonts.poppins(
            color: appBarTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: iconColor,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButtonFormField(
                decoration: InputDecoration(
                  labelText: 'Kategori Seçin',
                  fillColor: inputBackgroundColor,
                  filled: true,
                  labelStyle: GoogleFonts.lato(color: textColor, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink, width: 3.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.pinkAccent, width: 3.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: GoogleFonts.lato(
                        color: textColor, // Seçeneklerin yazı rengi
                        fontSize: 16, // Yazı boyutu
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue.toString();
                  });
                },
                dropdownColor: inputBackgroundColor, // Açılır menü arka plan rengi
                iconEnabledColor: Colors.pink, // Açılır menü ikon rengi
                style: GoogleFonts.lato(color: textColor), // Seçildikten sonra gösterilen metin rengi
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Açıklamanız',
                  alignLabelWithHint: true,
                  fillColor: inputBackgroundColor,
                  filled: true,
                  labelStyle: GoogleFonts.lato(color: textColor),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.pink, width: 3.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.pinkAccent, width: 3.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 5,
                onChanged: (value) {
                  _description = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir açıklama giriniz.';
                  } else if (value.length > 255) {
                    return 'Mesaj 255 karakterden fazla olamaz.';
                  }
                  return null;
                },
                style: TextStyle(color: textColor),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    sendMessage();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mesajınız gönderiliyor...')),
                    );
                  }
                },
                child: Text('Gönder'),
                style: ElevatedButton.styleFrom(
                  primary: buttonBackgroundColor, // Buton arka planı
                  onPrimary: buttonTextColor, // Buton yazı rengi
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12), // İç boşluk
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Kenarlık yuvarlaklığı
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: backgroundColor, // Arka plan rengi
    );
  }
}