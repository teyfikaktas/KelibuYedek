import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:kelibu/variables.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _ageController;
  late TextEditingController _teamController;
  late TextEditingController _cityController;
  bool _isDarkMode = false;

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
    super.dispose();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PasswordChangeDialog(isDarkMode: _isDarkMode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final themeColors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        elevation: 0,
        title: Text(
          'Hesap Bilgileri',
          style: GoogleFonts.poppins(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileHeader(userProvider),
              SizedBox(height: 24),
              _buildPasswordChangeCard(),
              SizedBox(height: 24),
              _buildInfoCard('Kişisel Bilgiler', [
                _buildInfoField(Icons.person, 'İsim', _nameController),
                _buildInfoField(Icons.email, 'E-posta', _emailController, readOnly: true),
                _buildInfoField(Icons.phone, 'Telefon', _phoneNumberController),
              ]),
              SizedBox(height: 16),
              _buildInfoCard('Ek Bilgiler', [
                _buildInfoField(Icons.cake, 'Yaş', _ageController),
                _buildInfoField(Icons.group, 'Takım', _teamController),
                _buildInfoField(Icons.location_city, 'Şehir', _cityController),
              ]),
              SizedBox(height: 24),
              _buildUpdateButton(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildProfileHeader(UserProvider userProvider) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: 'https://kelibu.net/storage/${userProvider.avatar}',
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: 50,
              backgroundImage: imageProvider,
            ),
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
          SizedBox(height: 16),
          Text(
            userProvider.username,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Text(
            '${userProvider.point} Puan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPasswordChangeCard() {
    return GestureDetector(
      onTap: _showPasswordChangeDialog,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.blue[800] : Colors.blue[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock,
              size: 40,
              color: _isDarkMode ? Colors.white : Colors.blue[800],
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Şifre Değiştir',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.blue[800],
                    ),
                  ),
                  Text(
                    'Hesabınızı güvende tutmak için şifrenizi düzenli olarak değiştirin',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _isDarkMode ? Colors.white70 : Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: _isDarkMode ? Colors.white : Colors.blue[800],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> fields) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 16),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildInfoField(IconData icon, String label, TextEditingController controller, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _isDarkMode ? Colors.white70 : Colors.black54),
          labelText: label,
          labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _isDarkMode ? Colors.white30 : Colors.black26),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _isDarkMode ? Colors.white30 : Colors.black26),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue),
          ),
          filled: true,
          fillColor: _isDarkMode ? Colors.grey[700] : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: updateUserInformation,
      child: Text('Bilgileri Güncelle'),
      style: ElevatedButton.styleFrom(
        primary: Colors.green,
        onPrimary: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future updateUserInformation() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
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
        showCustomFlushbar(context, responseBody['message'] ?? 'Bilgiler başarıyla güncellendi');
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
        showCustomFlushbar(context, responseBody['error_message'] ?? 'Bilgiler güncellenirken bir hata oluştu');
      }
    } catch (e) {
      print(e);
      showCustomFlushbar(context, 'Bilgiler güncellenirken bir hata oluştu: $e');
    }
  }

  void showCustomFlushbar(BuildContext context, String message) {
    Flushbar(
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          color: _isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Container(
        margin: const EdgeInsets.only(left: 8, right: 8),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          radius: 20,
          child: ClipOval(
            child: Image.asset(
              'assets/logo.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: _isDarkMode ? Colors.grey[800]! : Colors.white,
      boxShadows: [
        BoxShadow(
          color: Colors.black12,
          offset: Offset(0, 3),
          blurRadius: 6,
        ),
      ],
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      animationDuration: Duration(milliseconds: 400),
      forwardAnimationCurve: Curves.easeOutCirc,
      reverseAnimationCurve: Curves.easeInCirc,
      leftBarIndicatorColor: Colors.green,
    )..show(context);
  }
}

class PasswordChangeDialog extends StatefulWidget {
  final bool isDarkMode;

  PasswordChangeDialog({required this.isDarkMode});

  @override
  _PasswordChangeDialogState createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final _passwordFormKey = GlobalKey<FormState>();
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmNewPasswordController;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmNewPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
        child: Padding(
        padding: const EdgeInsets.all(24.0),
    child: Form(
    key: _passwordFormKey,
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Text(
    'Şifre Değiştir',
    style: GoogleFonts.poppins(fontSize: 24,
      fontWeight: FontWeight.bold,
      color: widget.isDarkMode ? Colors.white : Colors.black,
    ),
    ),
      SizedBox(height: 24),
      _buildPasswordField('Mevcut Şifre', _currentPasswordController, _obscureCurrentPassword, () {
        setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
      }),
      SizedBox(height: 16),
      _buildPasswordField('Yeni Şifre', _newPasswordController, _obscureNewPassword, () {
        setState(() => _obscureNewPassword = !_obscureNewPassword);
      }),
      SizedBox(height: 16),
      _buildPasswordField('Yeni Şifre (Tekrar)', _confirmNewPasswordController, _obscureConfirmPassword, () {
        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
      }),
      SizedBox(height: 32),
      ElevatedButton(
        onPressed: () {
          if (_passwordFormKey.currentState!.validate()) {
            updatePassword();
          }
        },
        child: Text('Şifreyi Değiştir'),
        style: ElevatedButton.styleFrom(
          primary: Colors.green,
          onPrimary: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ],
    ),
    ),
        ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscureText, VoidCallback toggleObscure) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black26),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue),
        ),
        filled: true,
        fillColor: widget.isDarkMode ? Colors.grey[700] : Colors.grey[100],
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
          ),
          onPressed: toggleObscure,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bu alan boş bırakılamaz';
        }
        return null;
      },
    );
  }

  Future<void> updatePassword() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final response = await http.post(
      Uri.parse('https://kelibu.net/api/reset-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Custom-Header': privacyKey.privacyKeyVariable,
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
      Navigator.of(context).pop(); // Dialog'u kapat
      showCustomFlushbar(context, message);
    } else {
      final responseBody = jsonDecode(response.body);
      String errorMessage = responseBody['error_message'] ?? 'Şifre güncellenemedi';
      showCustomFlushbar(context, errorMessage);
    }
  }

  void showCustomFlushbar(BuildContext context, String message) {
    Flushbar(
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          color: widget.isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Container(
        margin: const EdgeInsets.only(left: 8, right: 8),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          radius: 20,
          child: ClipOval(
            child: Image.asset(
              'assets/logo.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: widget.isDarkMode ? Colors.grey[800]! : Colors.white,
      boxShadows: [
        BoxShadow(
          color: Colors.black12,
          offset: Offset(0, 3),
          blurRadius: 6,
        ),
      ],
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      animationDuration: Duration(milliseconds: 400),
      forwardAnimationCurve: Curves.easeOutCirc,
      reverseAnimationCurve: Curves.easeInCirc,
      leftBarIndicatorColor: Colors.green,
    )..show(context);
  }
}