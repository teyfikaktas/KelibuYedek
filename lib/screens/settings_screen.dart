import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kelibu/variables.dart'; // FTP bilgilerini içeren dosyayı import et
import '../api.dart';
import '../providers/user_provider.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import 'privacy_conditions_screen.dart';
import 'privary_policy.dart';
import 'profile_setting.dart';
import 'package:hive/hive.dart';
import 'package:kelibu/main.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Ekran boyutları için MediaQuery değerlerini al
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Profilim',
          style: GoogleFonts.poppins(
            color: Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.pink,
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
                    SettingsItem(Icons.settings, 'Hesap Bilgileri', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AccountPage()),
                      );
                    }),
                    SettingsItem(Icons.info_outline, 'Hakkımızda', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AboutPage()),
                      );
                    }),
                    SettingsItem(Icons.settings, 'İletişim ve Sorun Bildir', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ContactFormPage()),
                      );
                    }),
                    SettingsItem(Icons.book, 'Hüküm ve Koşullar', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TermsAndConditionsPage()),
                      );
                    }),
                    SettingsItem(Icons.privacy_tip, 'Gizlilik Sözleşmesi', onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                      );
                    }),
                    SettingsItem(Icons.delete, 'Hesabımı Sil', onTap: () {
                      _confirmDeleteAccount(context, userProvider);
                    }),
                    SettingsItem(Icons.exit_to_app, 'Çıkış Yap', onTap: () => logout(context)),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Yuvarlak köşeler
          ),
          title: Text(
            'Hesabınızı Sil',
            style: GoogleFonts.roboto(
              fontSize: 20, // Başlık font boyutu
              fontWeight: FontWeight.bold, // Başlık font kalınlığı
              color: Colors.pink, // Başlık font rengi
            ),
          ),
          content: Text(
            'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
            style: GoogleFonts.roboto(
              fontSize: 16, // İçerik font boyutu
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
      await box.put('isLoggedIn', false);
      print('isLoggedIn durumu başarıyla güncellendi.');

      Provider.of<UserProvider>(context, listen: false).logout();

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => SplashScreen()));
      print('Yönlendirme başarılı.');
    } catch (e) {
      print('Hive işlemi sırasında bir hata oluştu: $e');
    }
  }

  Future<void> _selectImage(BuildContext context) async {
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

  Future<File> compressImage(File file, {int minWidth = 256, int minHeight = 256}) async {
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

  Future<void> uploadImageAndUpdateAvatar(File imageFile) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
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

  String _createRandomFileName(String filePath) {
    final extension = p.extension(filePath); // Dosyanın uzantısını al
    final rand = Random();
    final randomNumber = rand.nextInt(10000); // 0 ile 9999 arasında rastgele bir sayı üret
    final timestamp = DateTime.now().millisecondsSinceEpoch; // Zaman damgası
    return 'image_${timestamp}_$randomNumber$extension'; // Örnek: image_1625496728934_1234.jpg
  }

  void _showUploadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dialog dışına dokunarak kapatamaz
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white, // Beyaz arka plan
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20),
              Text("Profil resmi değiştirme süresinde lütfen bekleyin", textAlign: TextAlign.center),
              SizedBox(height: 20),
              // Logo ve dönme animasyonu

              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Profil resminiz güncelleniyor", textAlign: TextAlign.center),
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

  const SettingsItem(this.icon, this.title, {Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Arka plan rengi beyaz olarak ayarlandı
          border: Border.all(
            color: Colors.grey,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0), // Daha oval kenarlar için
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: Icon(icon, color: Colors.pink), // İkon rengi pembe
            title: Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.pink, // Yazı rengi pembe olarak ayarlandı
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
