import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class TermsAndConditionsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TermsAndConditionsPage(),
    );
  }
}

class TermsAndConditionsPage extends StatelessWidget {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Kullanım şartları',
          style: GoogleFonts.poppins(
            color: Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.pink,
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          termsAndConditionsText,
          style: GoogleFonts.poppins(
            fontSize: 16, // Metin boyutunu ayarla
            fontWeight: FontWeight.w400, // Yazı tipi kalınlığını ayarla
            color: Colors.grey.shade800, // Metin rengini ayarla
          ),
          textAlign: TextAlign.justify, // Metni her iki taraftan hizala
        ),
      ),
    );
  }
}
