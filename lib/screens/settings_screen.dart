import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kelibu/variables.dart'; // FTP bilgilerini içeren dosyayı import et
import 'package:provider/provider.dart';
import '../api.dart';
import '../providers/user_provider.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
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

    // Ekran boyutları için MediaQuery değerlerini al
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    final themeColors = _isDarkMode ? darkModeColors : lightModeColors;
    final backgroundColor = themeColors["background"];
    final textColor = themeColors["text"];
    final buttonBackgroundColor = themeColors["buttonBackground"];
    final buttonTextColor = themeColors["buttonText"];
    final iconColor = themeColors["iconColor"];

    return Scaffold(
      backgroundColor: backgroundColor, // Arka plan rengini burada ayarlayın
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'Profilim',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: iconColor,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                color: Colors.pink,
                height: MediaQuery.of(context).size.height * 0.003,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.95,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => _selectImage(context),
                      child: CircleAvatar(
                        radius: MediaQuery.of(context).size.height * 0.07,
                        backgroundImage: NetworkImage('https://kelibu.net/storage/${userProvider.avatar}'),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    OutlinedButton.icon(
                      onPressed: () => _selectImage(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.pink), // Çerçeve rengi pembe
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: Icon(Icons.camera_alt, color: Colors.pink), // İkon ve rengi
                      label: Text(
                        'Profil Resmini Değiştir',
                        style: TextStyle(color: Colors.pink), // Yazı rengi pembe
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    // SettingsItem widget'ları ve diğer elemanlar burada yer alıyor.
                    SettingsItem(
                      icon: Icons.settings,
                      title: 'Hesap Bilgileri',
                      isDarkMode: _isDarkMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AccountPage()),
                        );
                      },
                    ),
                    SettingsItem(
                      icon: Icons.info_outline,
                      title: 'Hakkımızda',
                      isDarkMode: _isDarkMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AboutPage()),
                        );
                      },
                    ),
                    SettingsItem(
                      icon: Icons.settings,
                      title: 'İletişim ve Sorun Bildir',
                      isDarkMode: _isDarkMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ContactFormPage()),
                        );
                      },
                    ),
                    SettingsItem(
                      icon: Icons.book,
                      title: 'Hüküm ve Koşullar',
                      isDarkMode: _isDarkMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TermsAndConditionsPage()),
                        );
                      },
                    ),
                    SettingsItem(
                      icon: Icons.privacy_tip,
                      title: 'Gizlilik Sözleşmesi',
                      isDarkMode: _isDarkMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                        );
                      },
                    ),
                    SettingsItem(
                      icon: Icons.delete,
                      title: 'Hesabımı Sil',
                      isDarkMode: _isDarkMode,
                      onTap: () {
                        _confirmDeleteAccount(context, userProvider);
                      },
                    ),
                    SettingsItem(
                      icon: Icons.exit_to_app,
                      title: 'Çıkış Yap',
                      isDarkMode: _isDarkMode,
                      onTap: () => logout(context),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey.shade200, thickness: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.black : Colors.white, // Dialog arka plan rengi
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Yuvarlak köşeler
          ),
          title: Text(
            'Hesabınızı Sil',
            style: GoogleFonts.roboto(
              fontSize: 20, // Başlık font boyutu
              fontWeight: FontWeight.bold, // Başlık font kalınlığı
              color: _isDarkMode ? Colors.white : Colors.pink, // Başlık font rengi
            ),
          ),
          content: Text(
            'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
            style: GoogleFonts.roboto(
              fontSize: 16, // İçerik font boyutu
              color: _isDarkMode ? Colors.white : Colors.black, // İçerik font rengi
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Dialog'u kapat
              child: Text(
                'Hayır',
                style: GoogleFonts.roboto(
                  color: Colors.grey, // 'Hayır' butonu font rengi
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                _deleteAccount(userProvider.userId, context, userProvider); // Hesap silme işlemini gerçekleştir
              },
              child: Text(
                'Evet',
                style: GoogleFonts.roboto(
                  color: Colors.pink, // 'Evet' butonu font rengi
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Hesap silme işlemi için API çağrısı yapılacak fonksiyon
  void _deleteAccount(int userId, BuildContext context, UserProvider userProvider) async {
    final bool isSuccess = await ApiService().deleteUser(userId);
    if (isSuccess) {
      // Kullanıcı başarıyla silindi, şimdi çıkış yap.
      logout(context);
    } else {
      // Hesap silinirken bir sorun oluştu, kullanıcıyı bilgilendir.
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

  void logout(BuildContext context) async {
    try {
      print('Hive box açılmaya çalışılıyor...');
      final box = await Hive.openBox<bool>('loginBox');

      print('isLoggedIn durumu false olarak güncelleniyor...');
    await
    box.put("isLoggedIn", false);
      print("isLoggedIn durumu başarıyla güncellendi.");
      Provider.of<UserProvider>(context, listen: false).logout();

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => SplashScreen()));
      print('Yönlendirme başarılı.');
    } catch (e) {
      print('Hive işlemi sırasında bir hata oluştu: $e');
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

      // Yükleme işlemi başlamadan önce yükleme durumunu true olarak güncelle
      setState(() {
        _isUploading = true;
      });

      _showUploadingDialog(); // Dialog'u göster

      // Resmi sıkıştır
      final compressedImage = await compressImage(imageFile);
      // Sıkıştırılmış resmi yükle ve avatar URL'sini güncelle
      await uploadImageAndUpdateAvatar(compressedImage);

      // Dialog'u kapat
      Navigator.of(context, rootNavigator: true).pop('dialog');

      // Yükleme işlemi tamamlandıktan sonra yükleme durumunu false olarak güncelle
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future compressImage(File file, {int minWidth = 256, int minHeight = 256}) async {
    final img.Image? image = img.decodeImage(await file.readAsBytes());
    img.Image resized = image!;
    // Eğer resim belirlenen minimum değerlerden büyükse, yeniden boyutlandır
    if (image.width < minWidth || image.height < minHeight) {
      resized = img.copyResize(image, width: minWidth, height: minHeight);
    } else {
      // Resmi orijinal oranına göre yeniden boyutlandır
      resized = img.copyResize(image, width: image.width, height: image.height);
    }

// Yeniden boyutlandırılmış resmi geçici bir dosyaya yaz
    final Directory tempDir = await getTemporaryDirectory();
    final String targetPath = p.join(tempDir.path, "temp_${DateTime.now().millisecondsSinceEpoch}.jpg");
    final File newImageFile = File(targetPath)..writeAsBytesSync(img.encodeJpg(resized, quality: 85));

    return newImageFile;
  }

  Future uploadImageAndUpdateAvatar(File imageFile) async {
    final userProvider = Provider.of(context, listen: false);
    Uri uri = Uri.parse("https://www.kelibu.net/api/updateAvatar");
    var request = http.MultipartRequest("POST", uri)
      ..fields['user_id'] = userProvider.userId.toString()
      ..files.add(await http.MultipartFile.fromPath('avatar', imageFile.path))
      ..headers.addAll({
        'Content-Type': 'multipart/form-data',
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header added
      });

    try {
      var streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        var response = await http.Response.fromStream(streamedResponse);
        var responseData = json.decode(response.body);

        String newAvatarUrl = responseData['avatar_url'];
        await userProvider.updateUserAvatarUrl(newAvatarUrl); // updateUserAvatarUrl metodunu çağır
        print('Avatar URL güncellendi: $newAvatarUrl');
      } else {
        // Burada yanıtın içeriğini de yazdırıyoruz
        var response = await http.Response.fromStream(streamedResponse);
        print('Resim yükleme başarısız. Hata: ${response.body}');
      }
    } catch (e) {
      // Network hatası veya başka bir hata durumunda hata mesajını yazdır
      print('Resim yükleme sırasında bir hata oluştu: $e');
    }
  }

  String createRandomFileName(String filePath) {
    final extension = p.extension(filePath); // Dosyanın uzantısını al
    final rand = Random();
    final randomNumber = rand.nextInt(10000); // 0 ile 9999 arasında rastgele bir sayı üret
    final timestamp = DateTime.now().millisecondsSinceEpoch; // Zaman damgası
    return "image${timestamp}_$randomNumber$extension"; // Örnek: image_1625496728934_1234.jpg
  }

  void _showUploadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dialog dışına dokunarak kapatamaz
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _isDarkMode ? Colors.black : Colors.white, // Dialog arka plan rengi
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              SizedBox(height: 20),
          Text(
          "Profil resmi değiştirme süresinde lütfen bekleyin",
          textAlign: TextAlign.center,
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black), // Yazı rengi
        ),
        SizedBox(height: 20),
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text(
        "Profil resminiz güncelleniyor",
        textAlign: TextAlign.center,
        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black), // Yazı rengi
        ),
        SizedBox(height: 20),
        ],
        ),
        );
      },
    );
  }
}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isDarkMode;

  const SettingsItem({required this.icon, required this.title, this.onTap, required this.isDarkMode, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColors = isDarkMode ? darkModeColors : lightModeColors;
    final textColor = themeColors["text"];
    final iconColor = themeColors["iconColor"];
    final backgroundColor = themeColors["background"];
    return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
    decoration: BoxDecoration(
    color: backgroundColor, // Arka plan rengi
    border: Border.all(
    color: Colors.grey,
    width: 1.0,
    ),
    borderRadius: BorderRadius.circular(8.0), // Daha oval kenarlar için
    ),
    child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: ListTile(
    leading: Icon(icon, color: iconColor), // İkon rengi
    title: Text(
    title,
    style: GoogleFonts.poppins(
    color: textColor, // Yazı rengi
    fontWeight: FontWeight.bold,
    ),
    ),
    onTap: onTap,
    ),
    ),
    ),
    );
  }
}