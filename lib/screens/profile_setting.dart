import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/variables.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

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
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Hesap Bilgileri',
          style: GoogleFonts.poppins(
            color: Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.pink,
        ),
      ),
      body:
      Theme(
        data: ThemeData(
          primaryColor: Colors.white54,
        ),
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
                decoration: InputDecoration(
                  labelText: 'İsim',
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.person, color: Colors.pinkAccent),
                  focusedBorder: OutlineInputBorder( // Odaklanıldığında kenarlık
                    borderSide: BorderSide(color: Colors.pinkAccent, width: 3.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

              ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  readOnly: true, // Bu alanı değiştirilemez yapar
                  validator: (value) => value != null && !value.contains('@') ? 'Geçerli bir email giriniz' : null,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.lato(color: Colors.pink), // Google Fonts kullanarak label stilini belirleyin
                    fillColor: Colors.white, // Arka plan rengi
                    filled: true, // fillColor'i etkinleştirir
                    border: OutlineInputBorder( // Kenarlık stilini özelleştir
                      borderSide: BorderSide(color: Colors.pink, width: 3.0), // Pembe kenarlık
                      borderRadius: BorderRadius.circular(8), // Kenarlık yuvarlaklığı
                    ),
                    focusedBorder: OutlineInputBorder( // Odaklanıldığında kenarlık
                      borderSide: BorderSide(color: Colors.pinkAccent, width: 3.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.pinkAccent), // İkon ve ikonun rengi
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Yaş',
                    labelStyle: GoogleFonts.lato(color: Colors.pink), // Google Fonts kullanarak label stilini belirleyin
                    fillColor: Colors.white, // Arka plan rengi
                    filled: true, // fillColor'i etkinleştirir
                    border: OutlineInputBorder( // Kenarlık stilini özelleştir
                      borderSide: BorderSide(color: Colors.pink, width: 3.0), // Pembe kenarlık
                      borderRadius: BorderRadius.circular(8), // Kenarlık yuvarlaklığı
                    ),
                    focusedBorder: OutlineInputBorder( // Odaklanıldığında kenarlık
                      borderSide: BorderSide(color: Colors.pinkAccent, width: 3.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.cake, color: Colors.pinkAccent), // İkon ve ikonun rengi
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _teamController,
                  decoration: InputDecoration(
                    labelText: 'Takım',
                    labelStyle: GoogleFonts.lato(color: Colors.pink), // Google Fonts kullanarak label stilini belirleyin
                    fillColor: Colors.white, // Arka plan rengi
                    filled: true, // fillColor'i etkinleştirir
                    border: OutlineInputBorder( // Kenarlık stilini özelleştir
                      borderSide: BorderSide(color: Colors.pink, width: 3.0), // Pembe kenarlık
                      borderRadius: BorderRadius.circular(8), // Kenarlık yuvarlaklığı
                    ),
                    focusedBorder: OutlineInputBorder( // Odaklanıldığında kenarlık
                      borderSide: BorderSide(color: Colors.pinkAccent, width: 3.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.group, color: Colors.pinkAccent), // İkon ve ikonun rengi
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'Şehir',
                    labelStyle: GoogleFonts.lato(color: Colors.pink), // Google Fonts kullanarak label stilini belirleyin
                    fillColor: Colors.white, // Arka plan rengi
                    filled: true, // fillColor'i etkinleştirir
                    border: OutlineInputBorder( // Kenarlık stilini özelleştir
                      borderSide: BorderSide(color: Colors.pink, width: 3.0), // Pembe kenarlık
                      borderRadius: BorderRadius.circular(8), // Kenarlık yuvarlaklığı
                    ),
                    focusedBorder: OutlineInputBorder( // Odaklanıldığında kenarlık
                      borderSide: BorderSide(color: Colors.pinkAccent, width: 3.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.location_city, color: Colors.pinkAccent), // İkon ve ikonun rengi
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _phoneNumberController,
                  readOnly: false, // Kullanıcıların giriş yapabilmesi için bu alanı düzenlenebilir hale getirir
                  keyboardType: TextInputType.phone, // Klavyeyi telefon numarası girişine uygun hale getirir
                  decoration: InputDecoration(
                    labelText: 'Telefon Numarası',
                    labelStyle: GoogleFonts.lato(color: Colors.pink), // Google Fonts kullanarak label stilini belirleyin
                    fillColor: Colors.white, // Arka plan rengi
                    filled: true, // fillColor'i etkinleştirir
                    border: OutlineInputBorder( // Kenarlık stilini özelleştir
                      borderSide: BorderSide(color: Colors.pink, width: 3.0), // Pembe kenarlık
                      borderRadius: BorderRadius.circular(8), // Kenarlık yuvarlaklığı
                    ),
                    focusedBorder: OutlineInputBorder( // Odaklanıldığında kenarlık
                      borderSide: BorderSide(color: Colors.pinkAccent, width: 3.0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.phone, color: Colors.pinkAccent), // İkon ve ikonun rengi
                  ),
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
                        return ListTile(
                          title: Text(
                            'Şifre Değiştir',
                            style: TextStyle(color: Colors.pink), // Başlık rengini özelleştir
                          ),
                        );
                      },
                      body: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _passwordFormKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _currentPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Eski Şifre',
                                  labelStyle: GoogleFonts.lato(color: Colors.pink),
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.pink, width: 3.0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.pinkAccent, width: 3.0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: Icon(Icons.lock_outline, color: Colors.pinkAccent),
                                ),
                                obscureText: true,
                              ),
                              SizedBox(height: 10), // Alanlar arası boşluk
                              TextFormField(
                                controller: _newPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Yeni Şifre',
                                  labelStyle: GoogleFonts.lato(color: Colors.pink),
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.pink, width: 3.0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.pinkAccent, width: 3.0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: Icon(Icons.lock, color: Colors.pinkAccent),
                                ),
                                obscureText: true,
                              ),
                              SizedBox(height: 10), // Alanlar arası boşluk
                              TextFormField(
                                controller: _confirmNewPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Yeni Şifreyi Onayla',
                                  labelStyle: GoogleFonts.lato(color: Colors.pink),
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.pink, width: 3.0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.pinkAccent, width: 3.0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: Icon(Icons.lock, color: Colors.pinkAccent),
                                ),
                                obscureText: true,
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  if (_passwordFormKey.currentState!.validate()) {
                                    // Şifre güncelleme işlemini burada yap
                                    updatePassword();
                                  }
                                },
                                child: Text('Şifreyi Değiştir'),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.pink, // Buton arka planı
                                  onPrimary: Colors.white, // Buton yazı rengi
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      isExpanded: _isPasswordPanelExpanded,
                    ),
                  ],
                )
        ,
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: updateUserInformation,
                  child: Text(
                    'Bilgileri Güncelle',
                    style: TextStyle(
                      color: Colors.white, // Buton yazı rengi
                      fontSize: 16, // Yazı boyutu
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.pink, // Buton arka planı
                    onPrimary: Colors.white, // (Bu ayar metin rengini etkiler, yukarıdaki Text widget'ında direkt belirtildiyse gerekli olmayabilir)
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12), // İç boşluk
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Kenarlık yuvarlaklığı
                    ),
                    elevation: 5, // Gölgelendirme
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Future<void> updateUserInformation() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Mevcut yılı al
    int currentYear = DateTime.now().year;
    // Kullanıcıdan alınan yaş bilgisini int'e çevir
    int age = int.tryParse(_ageController.text) ?? 0;
    // Doğum yılını hesapla
    int birthYear = currentYear - age;

    // API endpoint URL
    final Uri apiUrl = Uri.parse('https://kelibu.net/api/updateUserInfo');

    // HTTP POST isteği için header ve body
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header added
    };
    final body = jsonEncode({
      'user_id': userProvider.userId.toString(),
      'name': _nameController.text,
      'birth_year': birthYear.toString(), // Doğum yılı hesaplanarak gönderiliyor
      'team': _teamController.text,
      'city': _cityController.text,
    });

    try {
      final response = await http.post(apiUrl, headers: headers, body: body);

      if (response.statusCode == 200) {
        // İşlem başarılı
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
        // Provider güncellemelerini bildir
        userProvider.notifyListeners();
      } else {
        // İşlem başarısız, hata mesajı göster
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
