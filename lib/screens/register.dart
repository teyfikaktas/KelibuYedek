import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:kelibu/screens/verify_email.dart';
import 'dart:convert';
import 'package:kelibu/screens/sdk/customShowDialog.dart';
import 'package:kelibu/variables.dart';  // Import the colors.dart file
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false; // Bekleme durumu
  bool _isDarkMode = false;
  final storage = FlutterSecureStorage();
  bool _isPasswordVisible = false; // Şifre görünürlüğü durumu
  bool _isConfirmPasswordVisible = false; // Şifre tekrar görünürlüğü durumu

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

  Future<void> register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      showCustomDialog(context, 'Hata', 'Şifreler eşleşmiyor.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://www.kelibu.net/api/registerCreate'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-Custom-Header': 'Hilal', // İsteğe eklenen özel header
      },
      body: jsonEncode(<String, String>{
        'name': _usernameController.text,
        'email': _emailController.text,
        'phone': '0000000000', // Telefon numarası sabit, isteğe bağlı olarak değiştirilebilir
        'password': _passwordController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyEmailScreen(email: _emailController.text),
        ),
      );
    } else {
      final errorResponse = json.decode(response.body);
      showCustomDialog(context, 'Hata', 'Kayıt işlemi başarısız: ${errorResponse['message']}');
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false, bool isPasswordVisible = false, VoidCallback? togglePasswordVisibility}) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return TextField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(isPassword ? Icons.lock : Icons.email, color: colors["text"]),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: colors["text"],
          ),
          onPressed: togglePasswordVisibility,
        )
            : null,
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
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.07,
      child: ElevatedButton(
        onPressed: register,
        style: ElevatedButton.styleFrom(
          foregroundColor: colors["buttonText"], backgroundColor: colors["buttonBackground"],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          'Kayıt Ol',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width * 0.05,
            color: colors["buttonText"],
          ),
        ),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
      _isConfirmPasswordVisible = _isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: colors["background"],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: MediaQuery.of(context).size.width * 0.3,
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.white : colors["background"], // Dark mode'da beyaz arka plan
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
                    'Kayıt Ol',
                    style: GoogleFonts.roboto(
                      color: colors["text"],
                      fontSize: MediaQuery.of(context).size.width * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildTextField(_emailController, 'E-posta'),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildTextField(_usernameController, 'Kullanıcı Adı'),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildTextField(
                    _passwordController,
                    'Şifre',
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    togglePasswordVisibility: _togglePasswordVisibility,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildTextField(
                    _confirmPasswordController,
                    'Şifre Tekrar',
                    isPassword: true,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    togglePasswordVisibility: _togglePasswordVisibility,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _isLoading
                      ? CircularProgressIndicator() // Bekleme göstergesi
                      : _buildRegisterButton(context),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Geri tuşuna bastığında önceki sayfaya döner
                    },
                    child: Text(
                      'Zaten hesabın var mı? Giriş Yap',
                      style: TextStyle(color: colors["text"]),
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
}
