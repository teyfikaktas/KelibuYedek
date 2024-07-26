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
        'X-Custom-Header': privacyKey.privacyKeyVariable,
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
    final backgroundColor = _isDarkMode ? Colors.grey[900] : Colors.blue[700];
    final textColor = themeColors["text"];
    final inputBackgroundColor = themeColors["inputBackground"];
    final buttonBackgroundColor = _isDarkMode ? Colors.green[700] : Colors.green;
    final buttonTextColor = Colors.white;
    final appBarColor = _isDarkMode ? Colors.grey[900] : Colors.blue[700];
    final appBarTextColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(
          'İletişim Formu',
          style: GoogleFonts.nunito(
            color: appBarTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isDarkMode
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue[700]!, Colors.blue[500]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Bize Ulaşın',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField(
                        decoration: InputDecoration(
                          labelText: 'Kategori Seçin',
                          fillColor: Colors.transparent,
                          filled: true,
                          labelStyle: GoogleFonts.nunito(
                            color: _isDarkMode ? Colors.white70 : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        value: _selectedCategory,
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style: GoogleFonts.nunito(
                                color: _isDarkMode ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCategory = newValue.toString();
                          });
                        },
                        dropdownColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                        icon: Icon(Icons.arrow_drop_down, color: _isDarkMode ? Colors.white70 : Colors.blue[700]),
                        style: GoogleFonts.nunito(color: _isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Açıklamanız',
                          alignLabelWithHint: true,
                          fillColor: Colors.transparent,
                          filled: true,
                          labelStyle: GoogleFonts.nunito(
                            color: _isDarkMode ? Colors.white70 : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        style: GoogleFonts.nunito(color: _isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          sendMessage();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Mesajınız gönderiliyor...'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Gönder',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: buttonBackgroundColor,
                        onPrimary: buttonTextColor,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
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