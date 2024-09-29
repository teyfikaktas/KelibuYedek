import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kelibu/variables.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../providers/user_provider.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import 'loadingIndicator.dart';
import 'login_screen.dart';
import 'privacy_conditions_screen.dart';
import 'privary_policy.dart';
import 'profile_setting.dart';
import 'package:hive/hive.dart';
import 'package:kelibu/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isUploading = false;
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final themeColors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: themeColors["background"],
      appBar: AppBar(
        backgroundColor: themeColors["background"],
        elevation: 0,
        title: Text(
          'Profilim',
          style: GoogleFonts.poppins(
            color: themeColors["text"],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: IconThemeData(color: themeColors["iconColor"]),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              _buildProfileHeader(userProvider),
              SizedBox(height: 30),
              _buildSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildProfileHeader(UserProvider userProvider) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _selectImage(context),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CachedNetworkImage(
                imageUrl: 'https://kelibu.net/storage/${userProvider.avatar}',
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  radius: 60,
                  backgroundImage: imageProvider,
                ),
                placeholder: (context, url) => LogoLoadingIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ],
          ),
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
          userProvider.email,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  Widget _buildSettingsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          _buildSettingsItem(Icons.account_circle, 'Hesap Bilgileri', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AccountPage()));
          }),
          _buildDivider(),
          _buildSettingsItem(Icons.info_outline, 'Hakkımızda', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AboutPage()));
          }),
          _buildDivider(),
          _buildSettingsItem(Icons.contact_support, 'İletişim ve Sorun Bildir', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ContactFormPage()));
          }),
          _buildDivider(),
          _buildSettingsItem(Icons.book, 'Hüküm ve Koşullar', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => TermsAndConditionsPage()));
          }),
          _buildDivider(),
          _buildSettingsItem(Icons.privacy_tip, 'Gizlilik Sözleşmesi', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyPage()));
          }),
          _buildDivider(),
          _buildSettingsItem(Icons.delete, 'Hesabımı Sil', () {
            _confirmDeleteAccount(context, Provider.of<UserProvider>(context, listen: false));
          }, color: Colors.red),
          _buildDivider(),
          _buildSettingsItem(Icons.exit_to_app, 'Çıkış Yap', () => logout(context), color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? (_isDarkMode ? Colors.white : Colors.black)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: color ?? (_isDarkMode ? Colors.white : Colors.black),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: _isDarkMode ? Colors.white70 : Colors.black54),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: _isDarkMode ? Colors.grey[800] : Colors.grey[300],
      height: 1,
      thickness: 1,
    );
  }

  void _confirmDeleteAccount(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Hesabınızı Sil',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.pink,
            ),
          ),
          content: Text(
            'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Hayır',
                style: GoogleFonts.roboto(
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount(userProvider.userId, context, userProvider);
              },
              child: Text(
                'Evet',
                style: GoogleFonts.roboto(
                  color: Colors.pink,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount(int userId, BuildContext context, UserProvider userProvider) async {
    final bool isSuccess = await ApiService().deleteUser(userId);
    if (isSuccess) {
      // Hesap başarıyla silindiğinde
      await _clearUserData(context);
      _navigateToLoginScreen(context);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Hata'),
          content: Text('Hesap silinirken bir hata oluştu.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _clearUserData(BuildContext context) async {
    final box = await Hive.openBox<bool>('loginBox');
    await box.put("isLoggedIn", false);
    Provider.of<UserProvider>(context, listen: false).logout();
  }

  void _navigateToLoginScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => SplashScreen()));
  }

  void logout(BuildContext context) async {
    try {
      // API üzerinden çıkış yapma
      await ApiService().logout();

      // Hive'dan çıkış yapma işlemi
      final box = await Hive.openBox<bool>('loginBox');
      await box.put("isLoggedIn", false);

      // Token ve diğer oturum bilgilerini silme
      final storage = FlutterSecureStorage();
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
      await storage.delete(key: 'token_type');
      await storage.delete(key: 'expires_at');

      // UserProvider'dan çıkış yapma
      Provider.of<UserProvider>(context, listen: false).logout();

      // Tüm sayfaları temizleyip SplashScreen'e yönlendirme
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SplashScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Çıkış yapma sırasında bir hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yapılırken bir hata oluştu. Lütfen tekrar deneyin.')),
      );
    }
  }
  Future _selectImage(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final File imageFile = File(image.path);
      final fileSize = await imageFile.length();

      if (fileSize > 20 * 1024 * 1024) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Hata'),
            content: Text('Dosya boyutu 20MB\'dan büyük olamaz.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Tamam'),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      _showUploadingDialog();

      final compressedImage = await compressImage(imageFile);
      await uploadImageAndUpdateAvatar(compressedImage);

      Navigator.of(context, rootNavigator: true).pop('dialog');

      setState(() {
        _isUploading = false;
      });
    }
  }

  Future compressImage(File file, {int minWidth = 256, int minHeight = 256}) async {
    final img.Image? image = img.decodeImage(await file.readAsBytes());
    img.Image resized = image!;
    if (image.width < minWidth || image.height < minHeight) {
      resized = img.copyResize(image, width: minWidth, height: minHeight);
    } else {
      resized = img.copyResize(image, width: image.width, height: image.height);
    }

    final Directory tempDir = await getTemporaryDirectory();
    final String targetPath = p.join(tempDir.path, "temp_${DateTime.now().millisecondsSinceEpoch}.jpg");
    final File newImageFile = File(targetPath)..writeAsBytesSync(img.encodeJpg(resized, quality: 85));

    return newImageFile;
  }

  Future uploadImageAndUpdateAvatar(File imageFile) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    Uri uri = Uri.parse("https://www.kelibu.net/api/updateAvatar");
    var request = http.MultipartRequest("POST", uri)
      ..fields['user_id'] = userProvider.userId.toString()
      ..files.add(await http.MultipartFile.fromPath('avatar', imageFile.path))
      ..headers.addAll({
        'Content-Type': 'multipart/form-data',
        'X-Custom-Header': privacyKey.privacyKeyVariable,
      });

    try {
      var streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        var response = await http.Response.fromStream(streamedResponse);
        var responseData = json.decode(response.body);

        String newAvatarUrl = responseData['avatar_url'];

        // Eski avatar URL'sini önbellekten temizle
        String oldAvatarUrl = 'https://kelibu.net/storage/${userProvider.avatar}';
        await CachedNetworkImage.evictFromCache(oldAvatarUrl);

        // Yeni avatar URL'sini güncelle
        await userProvider.updateUserAvatarUrl(newAvatarUrl);

        print('Avatar URL güncellendi: $newAvatarUrl');
      } else {
        var response = await http.Response.fromStream(streamedResponse);
        print('Resim yükleme başarısız. Hata: ${response.body}');
      }
    } catch (e) {
      print('Resim yükleme sırasında bir hata oluştu: $e');
    }
  }

  String createRandomFileName(String filePath) {
    final extension = p.extension(filePath);
    final rand = Random();
    final randomNumber = rand.nextInt(10000);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return "image${timestamp}_$randomNumber$extension";
  }

  void _showUploadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Profil resmi değiştiriliyor",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                LogoLoadingIndicator(),
                SizedBox(height: 20),
                Text(
                  "Lütfen bekleyin...",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}