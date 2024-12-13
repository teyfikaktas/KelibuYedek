import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kelibu/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/variables.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelfEnglishBetaApplicationPage extends StatefulWidget {
  @override
  _SelfEnglishBetaApplicationPageState createState() => _SelfEnglishBetaApplicationPageState();
}

class _SelfEnglishBetaApplicationPageState extends State<SelfEnglishBetaApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
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

  Future<void> sendApplication() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    var url = Uri.parse('https://kelibu.net/api/send-beta-application');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Custom-Header': privacyKey.privacyKeyVariable,
      },
      body: json.encode({
        'user_id': userProvider.userId.toString(),
        'name': _name,
        'email': _email,
        'description': _description,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Başvurunuz için teşekkür ederiz.')),
      );
    } else {
      print('Başvuru gönderilirken bir hata oluştu: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = _isDarkMode ? darkModeColors : lightModeColors;
    final backgroundColor = themeColors["background"];
    final textColor = themeColors["text"];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'SelfEnglish Başvuru',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              _buildProfileHeader(),
              SizedBox(height: 24),
              _buildInfoCard("SelfEnglish Programına Katılın", [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildNameField(),
                      SizedBox(height: 20),
                      _buildEmailField(),
                      SizedBox(height: 20),
                      _buildDescriptionField(),
                      SizedBox(height: 30),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 24 : 36,
            horizontal: isSmallScreen ? 16 : 24,
          ),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isSmallScreen ? 80 : 100,
                height: isSmallScreen ? 80 : 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: isSmallScreen ? 60 : 75,
                    height: isSmallScreen ? 60 : 75,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Text(
                "SelfEnglish Beta Başvuru",
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Erken Erişim İçin Başvurun",
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 18 : 22,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> content) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 24),
          ...content,
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Adınız',
        fillColor: _isDarkMode ? Colors.grey[700] : Colors.grey[200],
        filled: true,
        labelStyle: GoogleFonts.poppins(
          color: _isDarkMode ? Colors.white70 : Colors.grey[700],
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      onChanged: (value) {
        _name = value;
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen adınızı giriniz.';
        }
        return null;
      },
      style: GoogleFonts.poppins(
        color: _isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'E-posta Adresiniz',
        fillColor: _isDarkMode ? Colors.grey[700] : Colors.grey[200],
        filled: true,
        labelStyle: GoogleFonts.poppins(
          color: _isDarkMode ? Colors.white70 : Colors.grey[700],
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      onChanged: (value) {
        _email = value;
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen e-posta adresinizi giriniz.';
        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Lütfen geçerli bir e-posta adresi giriniz.';
        }
        return null;
      },
      style: GoogleFonts.poppins(
        color: _isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Uygulamamız hakkında görüşleriniz nedir?',
        alignLabelWithHint: true,
        fillColor: _isDarkMode ? Colors.grey[700] : Colors.grey[200],
        filled: true,
        labelStyle: GoogleFonts.poppins(
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
          return 'Açıklama 255 karakterden fazla olamaz.';
        }
        return null;
      },
      style: GoogleFonts.poppins(
        color: _isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          sendApplication();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Başvurunuz gönderiliyor...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Text(
        'Başvur',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
    );
  }
}
