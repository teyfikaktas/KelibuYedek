import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsAndConditionsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TermsAndConditionsPage(),
    );
  }
}

class TermsAndConditionsPage extends StatefulWidget {
  @override
  _TermsAndConditionsPageState createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
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

  final String termsAndConditionsText = '''
Kelibu Kullanım Şartları ve Koşulları

1. Giriş

Bu Hüküm ve Koşullar ("Şartlar"), Kelibu kelime öğrenme uygulamasını ("Uygulama") kullanımınızı düzenler. Uygulama, PhD Akademi ("Şirket") tarafından sunulmaktadır. Uygulamayı indirerek, yükleyerek veya kullanarak, bu Şartları kabul etmiş olursunuz. Eğer bu Şartları kabul etmiyorsanız, Uygulamayı kullanmamalısınız.

2. Hizmetin Kullanımı

Uygulama, kullanıcıların farklı dillerde kelime öğrenmelerine ve dil becerilerini geliştirmelerine yardımcı olmak için tasarlanmıştır. Uygulama içindeki tüm içerik, Şirket tarafından sağlanır ve telif hakkı, ticari marka ve diğer fikri mülkiyet yasaları ile korunmaktadır.

a. Lisans
Şirket, bu Şartları kabul eden kullanıcılara, kişisel ve ticari olmayan kullanım amaçlı sınırlı, iptal edilebilir, dünya çapında, münhasır olmayan bir lisans verir.

b. Kullanım Kuralları
Uygulamayı kullanırken aşağıdaki kurallara uymalısınız:

Herhangi bir yasa dışı faaliyette bulunmamalı,
Başkalarının haklarına zarar vermemeli,
Virüs veya zararlı yazılım yaymamalı,
Şirketin veya başkalarının hizmetlerine zarar verecek veya erişimi engelleyecek faaliyetlerde bulunmamalısınız.

3. Fikri Mülkiyet Hakları

Uygulama ve uygulamada yer alan tüm içerikler (metinler, grafikler, videolar, tasarımlar vb.) Şirketin mülkiyetindedir ve fikri mülkiyet hakları ile korunmaktadır. Bu içerikler, Şirketin yazılı izni olmadan çoğaltılamaz, dağıtılamaz veya başka bir şekilde kullanılamaz.

4. Kullanıcı İçeriği

Uygulama, kullanıcıların kendi içeriklerini yüklemelerine izin verebilir. Kullanıcılar, yükledikleri içeriğin fikri mülkiyet haklarına sahip olduklarını ve bu içeriğin yayınlanmasının üçüncü şahısların haklarını ihlal etmediğini taahhüt ederler.

5. Sorumluluk Reddi

Uygulama "olduğu gibi" sunulur. Şirket, uygulamanın kullanımından doğabilecek herhangi bir zarar veya kayıp için sorumluluk kabul etmez.

6. Değişiklikler

Şirket, bu Şartları herhangi bir zamanda güncelleme hakkını saklı tutar. Değişiklikler, uygulamada yayınlandıktan sonra geçerli olacaktır.

7. Uygulanabilir Hukuk

Bu Şartlar, Türk Hukuku altında yorumlanacak ve uygulanacaktır.

8. İletişim

Herhangi bir sorunuz varsa, lütfen kelibu@kelibu.net üzerinden bizimle iletişime geçin.
''';

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode ? Colors.grey[900] : Colors.blue[700];
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final appBarColor = _isDarkMode ? Colors.grey[900] : Colors.blue[700];
    final appBarTextColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(
          'Kullanım Şartları',
          style: GoogleFonts.nunito(
            color: appBarTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isDarkMode
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue[700]!, Colors.blue[500]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelibu Kullanım Şartları ve Koşulları',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Container(
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
                    padding: EdgeInsets.all(20),
                    child: Text(
                      termsAndConditionsText,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: _isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.justify,
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
