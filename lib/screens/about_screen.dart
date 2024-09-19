import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kelibu/variables.dart';

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
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
    final themeColors = _isDarkMode ? darkModeColors : lightModeColors;
    final backgroundColor = themeColors["background"];
    final textColor = themeColors["text"];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Hakkımızda',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildInfoCard("Kelibu'nun Hikayesi", [
                _buildParagraph(
                  "1992'de orta okulu bitirmiş yaz tatilinde bir iş yerinde işe girmiştim. Orta okulun son yılında girdiğim sınavların (O dönemde her kurumun ayrı sınavı olurdu.) sonuçlarını heyecanla bekliyordum. Derken Anadolu Öğretmen Lisesi sınavlarının sonucu geldi ve Akçadağ'ı kazanmıştım.",
                  textColor!,
                ),
                _buildParagraph(
                  "Patronlarım sonuç kağıdını açmıştı ve kazanmışsın dedikten sonraki ilk cümleleri seneye ana dilin gibi İngilizce konuşursun olmuştu. Sınavı kazanmanın sevinci bir yana İngilizce bilecek olmanın heyecanı sarmıştı. Okullar açılana kadar hep içimden tamamen anlamsız şeyler söyleyip seneye böyle İngilizce konuşacağım diye iç geçirdim durdum.",
                  textColor,
                ),
                _buildParagraph(
                  "Derken okullar açıldı hazırlık sınıfına başladık ama çok da öyle hayalimdeki gibi olmadı. Hem yatılı okul koşullarının zorluğundan hem de dönemin siyasi koşullarının okula yansımasından dolayı hazırlığı geçmeme rağmen çok da öğrenmiş hissetmiyordum. Ayrılmadan bir hocama sordum ne yapabilirim diye o da mavi Grammer in Use kitabını al yazın çalış dedi. Babam Elazığ merkezde zar zor buldu. Tüm yaz çalıştım.",
                  textColor,
                ),
                _buildParagraph(
                  "Gramer öğrendim ama maalesef kelime çok zorluyordu. Okula döndüğümde dil adına hala yeterli hissetmemekle birlikte kendime güvenim artmıştı ki şimdi geriye dönüp baktığımda bu durum benim için çok büyük bir artı oluşturmuş. Gramer konularını unutmamak için bir alt sınıftaki hazırlık öğrencilerinden birkaç kişiye her gün konu anlatmakla gramerim iyice pekişmişti. Daha sonra her yıl hazırlıktan sekiz öğrenciye ders vererek devam ettim.",
                  textColor,
                ),
                _buildParagraph(
                  "Artık okuduğumu anlıyordum anlamasına ama kelime hala sorundu hem kendim için hem de ders verdiğim arkadaşlarım için. Ne kadar metot varsa denemeye ve denetmeye çalışırdım. En komiği ise Active Study sözlüğünü tuz döküp yersem acaba ezber olur muydu diye düşünmemdi. Derken derken kelime ezberleyebilme kaygısına hangi kelimeleri ezberlemem gerektiği kaygısı eşlik etmeye başladı. Resmen bitmiyordu uçsuz bucaksız deniz gibiydi.",
                  textColor,
                ),
                _buildParagraph(
                  "Ve okulda dil dersleri alamasam da dilci olmuştum. Hiçbir kelimenin telaffuzunu duymadan da olsa kelime okuma ve ELS dergileri ile sınavı kazandım. Yanımda İngilizce konuşan canlı birini ilk defa Gazi Üniversitesi hazırlık atlama sınavında gördüm. Tabi tam bir fiyasko dediği hiçbir şeyi anlamadım. Telaffuz ile kelime ezberlemedi iseniz dinlemeniz de olmaz tabii.",
                  textColor,
                ),
                _buildParagraph(
                  "Gazi hazırlıkta en çok zorlandığım şey oldu: Dinleme ve telaffuz. Buna rağmen metin çevirisi işine girişmiştim. Gazi Tıbbın çevirilerini almaya başlamıştım ki Ankara'da olduğum süre içinde önemli bir gelir kaynağı oldu. Ders vermeye de devam ediyordum. Gramer, okuma, okuduğunu anlamayı öğretme çok kolaydı ama kelime ezberletme, henüz internetin ve bilgisayarın yaygın olmadığı, cep telefonunun arabadan daha lüks sayıldığı dönemin koşullarında telaffuz üzerinde durmak da zordu.",
                  textColor,
                ),
                _buildParagraph(
                  "İlk bilgisayarım ile pascal ve visual basic dersi alıp kelime ezber programı ile kelime ezber ve telaffuz zorluğunu aşmaya çalıştım. Zamanın koşullarında çok ileri bir çaba olsa da günümüz için çok ilkel idi.",
                  textColor,
                ),
                _buildParagraph(
                  "Milli eğitime öğretmen olarak Konya, Ereğli'ye atandım. Çok büyük bir şans eseri ilk öğrencilerim dilci sınıfıydı ve Reader at Work okutarak ve o kitap üzerinden kelime ezberleterek işe koyulmuş, iki çantalı hoca (biri o zaman için uzaylı gibi görünmeme sebep olan laptop) diye tanınmıştım. Derken MEB'den istifa biraz özel dershane deneyimi ve sonunda Niğde Üniversitesinde Öğretim görevliliği bir birini takip etti.",
                  textColor,
                ),
              ]),
              SizedBox(height: 24),
              _buildInfoCard("Kelibu'nun Gelişimi", [
                _buildParagraph(
                  "Elektronik mühendisliğinden bir öğrencim (Sevgili Ömer Anar) ile ilk Android uygulamamız olan Kelibu'yu tasarladık. 2010 yılı ve test edecek telefon bulmakta çok zorlandık çünkü henüz kızaklı samsung devri idi 😊. Yine de Kelibu kısa zamanda kelime ezberinde etkililiğini ortaya koydu. Telaffuz, onlarca örnek cümle ve oyun mantığı oldukça faydalı olmuştu, ahhh bir de resim yükleyebilseydik ama ne dönemin telefon teknolojisi ile ne de internet teknolojisi ile bunu yapmak pek mümkün değildi.",
                  textColor,
                ),
                _buildParagraph(
                  "Zaman ilerledikçe ve teknoloji geliştikçe kullanıcı sayımız 100.000'e yaklaştı ve derken Rahip Burunson olayı ile ABD Türk Android geliştiricilerin 250.000 tanesinin uygulamasını kaldırdı. Maalesef Kelibu da kaldırıldı ama her kriz fırsatını doğurur. Zaten Kelibu'yu yeniden ele almak gerekiyordu.",
                  textColor,
                ),
                _buildParagraph(
                  "Niğde Teknopark'ta PhD Akademi şirketi ile birlikte Kelibu'yu eşi bulunmaz bir uygulama haline getirmeye ve Akademik İngilizce için ise PhD Akademi Uygulamasını hazırlamaya karar verdik. Artık akademik İngilizce öğretmek de kelime ezberletmek de çok kolay olacaktı ve şimdiye binlerce kişiye ulaşmayı başardık,",
                  textColor,
                ),
                _buildParagraph(
                  "Son bir şey daha vardı yapmamız gereken: A1 ve A2 seviyesinde insanların kendi başlarına çalışmalarını sağlayacak oyuna dayalı bol pratik yaptıracak, videolarla desteklenecek bir çok insanın dil öğrenme korkusunu yenmeye yardımcı olacak hem bireysel öğrencilerin olarak hem de dil öğretim kurumlarının vazgeçemeyeceği bir uygulama yapmak.",
                  textColor,
                ),
                _buildParagraph(
                  "Ve kolları sıvadık çok yakında PhD Akademi'nin yeni projesi ve ürünü olarak karşınıza çıkacak bir uygulama 😊: Adını henüz koymadık, her öneriye açığız ama ipucu verecek olursak Sos tablosu tabanlı olacak ve tüm A1, A2 ve B1 gramer konularını kolayca öğretecek, pratik yaptıracak, hem telaffuz içeren hem de telaffuzunuzu kontrol eden cümle kurmanızı sağlayan bir uyguma olacak.",
                  textColor,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
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
          Image.asset('assets/logo.png', width: 150, height: 150),
          SizedBox(height: 16),
          Text(
            "Kelibu",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Text(
            "Kelime Öğrenmenin En Etkili Yolu",
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.green,
            ),
          ),
        ],
      ),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Image.asset('assets/logo.png', width: 60, height: 60),
            ),
          ),
          SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 24),
          ...content.map((widget) => Align(
            alignment: Alignment.center,
            child: Container(
              constraints: BoxConstraints(maxWidth: 600),
              child: widget,
            ),
          )).toList(),
        ],
      ),
    );
  }
  Widget _buildParagraph(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: textColor,
          height: 1.5,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}