import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart'; // Add Hive package
import 'package:path_provider/path_provider.dart'; // Add path_provider package

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
    _loginBox = await Hive.openBox<bool>('loginBox', path: appDocumentDir.path);
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
      },
      body: jsonEncode(<String, String>{
        'email': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print(responseData);

      final userId = responseData['id'];
      final userName = responseData['name'];
      final profileImage = responseData['avatar'];
      final point = responseData['point'].toString();
      // Call setUser to save the user data in UserProvider
      Provider.of<UserProvider>(context, listen: false).setUser(userName, userId,profileImage,point);

      _loginBox.put('isLogge dIn', true);

      setState(() {
        _isLoggedIn = true;
      });

      Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return const HomeScreen();
    } else {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Container(
            child: Column(
              children: <Widget>[
                Container(
                  height: 400,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/background.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 30,
                        width: 80,
                        height: 200,
                        child: Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/light-1.png'),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        child: Container(
                          margin: const EdgeInsets.only(top: 50),
                          child: const Center(
                            child: Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: <Widget>[
                      _buildTextField(_usernameController, 'Kullanıcı Adı'),
                      const SizedBox(height: 20),
                      _buildTextField(_passwordController, 'Şifre', isPassword: true),
                      const SizedBox(height: 40),
                      _buildLoginButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[700]!, width: 2.0),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => login(_usernameController.text, _passwordController.text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text('Giriş Yap', style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}
