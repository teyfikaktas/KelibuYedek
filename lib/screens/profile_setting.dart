import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/variables.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _ageController;
  late TextEditingController _teamController;
  late TextEditingController _cityController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmNewPasswordController;
  bool _isDarkMode = false;

  bool _isPasswordPanelExpanded = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    _nameController = TextEditingController(text: userProvider.username);
    _emailController = TextEditingController(text: userProvider.email);
    _phoneNumberController = TextEditingController(text: userProvider.phone);
    _ageController = TextEditingController(text: (DateTime.now().year - userProvider.birthYear).toString());
    _teamController = TextEditingController(text: userProvider.team);
    _cityController = TextEditingController(text: userProvider.city);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmNewPasswordController = TextEditingController();

    _loadDarkModePreference();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _ageController.dispose();
    _teamController.dispose();
    _cityController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> updatePassword() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final response = await http.post(
      Uri.parse('https://kelibu.net/api/reset-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header added
      },
      body: jsonEncode(<String, String>{
        'user_id': userProvider.userId.toString(),
        'old_password': _currentPasswordController.text,
        'password': _newPasswordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      String message = responseBody['message'] ?? 'Şifre başarıyla güncellendi';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } else {
      final responseBody = jsonDecode(response.body);
      String errorMessage = responseBody['error_message'] ?? 'Şifre güncellenemedi';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  InputDecoration _buildInputDecoration(String labelText, IconData iconData, Color fillColor, Color textColor) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.lato(color: textColor),
      fillColor: fillColor,
      filled: true,
      prefixIcon: Icon(iconData, color: textColor),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: textColor, width: 3.0),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: textColor, width: 3.0),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final themeColors = _isDarkMode ? darkModeColors : lightModeColors;
    final textColor = themeColors["text"]!;
    final fillColor = themeColors["inputBackground"]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        title: Text(
          'Hesap Bilgileri',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: textColor,
        ),
      ),
      body: Theme(
        data: ThemeData(
          primaryColor: themeColors["cardBackground"],
        ),
        child: Container(
          color: _isDarkMode ? Colors.black : Colors.white, // Genel arka plan rengi
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage('https://kelibu.net/storage/${userProvider.avatar}'),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    readOnly: true,
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    decoration: _buildInputDecoration('İsim', Icons.person, fillColor, textColor),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    validator: (value) => value != null && !value.contains('@') ? 'Geçerli bir email giriniz' : null,
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    decoration: _buildInputDecoration('Email', Icons.email, fillColor, textColor),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _ageController,
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    decoration: _buildInputDecoration('Yaş', Icons.cake, fillColor, textColor),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _teamController,
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    decoration: _buildInputDecoration('Takım', Icons.group, fillColor, textColor),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _cityController,
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    decoration: _buildInputDecoration('Şehir', Icons.location_city, fillColor, textColor),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    decoration: _buildInputDecoration('Telefon Numarası', Icons.phone, fillColor, textColor),
                  ),
                  SizedBox(height: 20),
                  ExpansionPanelList(
                    expansionCallback: (int index, bool isExpanded) {
                      setState(() {
                        _isPasswordPanelExpanded = !_isPasswordPanelExpanded;
                      });
                    },
                    children: [
                      ExpansionPanel(
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return Container(
                            color: _isDarkMode ? Colors.black : Colors.white, // Arka plan rengini ayarlama
                            child: ListTile(
                              title: Text(
                                'Şifre Değiştir',
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          );
                        },
                        body: Container(
                          color: _isDarkMode ? Colors.black : Colors.white, // Arka plan rengini ayarlama
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Form(
                              key: _passwordFormKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _currentPasswordController,
                                    decoration: _buildInputDecoration('Eski Şifre', Icons.lock_outline, fillColor, textColor),
                                    obscureText: true,
                                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: _newPasswordController,
                                    decoration: _buildInputDecoration('Yeni Şifre', Icons.lock, fillColor, textColor),
                                    obscureText: true,
                                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: _confirmNewPasswordController,
                                    decoration: _buildInputDecoration('Yeni Şifreyi Onayla', Icons.lock, fillColor, textColor),
                                    obscureText: true,
                                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                                  ),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_passwordFormKey.currentState!.validate()) {
                                        updatePassword();
                                      }
                                    },
                                    child: Text("Şifreyi Değiştir"),
                                    style: ElevatedButton.styleFrom(
                                      primary: _isDarkMode ? Colors.black : Colors.white, // Buton arka plan rengi
                                      onPrimary: _isDarkMode ? Colors.white : Colors.black, // Buton yazı rengi
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        isExpanded: _isPasswordPanelExpanded,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: updateUserInformation,
                    child: Text(
                      "Bilgileri Güncelle",
                      style: TextStyle(
                        color: themeColors["buttonText"],
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: themeColors["buttonBackground"],
                      onPrimary: themeColors["buttonText"],
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
    );
  }

  Future updateUserInformation() async {
    final userProvider = Provider.of(context, listen: false);
    int currentYear = DateTime.now().year;
    int age = int.tryParse(_ageController.text) ?? 0;
    int birthYear = currentYear - age;

    final Uri apiUrl = Uri.parse('https://kelibu.net/api/updateUserInfo');

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'X-Custom-Header': privacyKey.privacyKeyVariable,
    };
    final body = jsonEncode({
      'user_id': userProvider.userId.toString(),
      'name': _nameController.text,
      'birth_year': birthYear.toString(),
      'team': _teamController.text,
      'city': _cityController.text,
    });

    try {
      final response = await http.post(apiUrl, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['message'] ?? 'Bilgiler başarıyla güncellendi')),
        );
        await userProvider.setUser(
          _nameController.text,
          userProvider.userId,
          userProvider.avatar,
          userProvider.point,
          _emailController.text,
          _phoneNumberController.text,
          userProvider.phoneVerified,
          userProvider.createdAt,
          _cityController.text,
          birthYear,
          _teamController.text.isEmpty ? null : _teamController.text,
        );
        userProvider.notifyListeners();
      } else {
        final responseBody = jsonDecode(response.body);
        print(responseBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['error_message'] ?? 'Bilgiler güncellenirken bir hata oluştu')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bilgiler güncellenirken bir hata oluştu: $e')),
      );
    }
  }
}