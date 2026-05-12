import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/variables.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyPolicyPage extends StatefulWidget {
  @override
  _PrivacyPolicyPageState createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
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
          'Gizlilik Sözleşmesi',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildProfileHeader(),
              SizedBox(height: 24),
              _buildInfoCard("Gizlilik ve Güvenlik Politikası", [
                _buildParagraph(
                  'www.kelibu.net sitesinde verilen tüm servisler ve hizmetler Fertek Mah. '
                  'Ömer Halisdemir Küme Evleri Teknopark Sitesi Teknopark Blok No:31 İç Kapı '
                  'No:108 Merkez/Niğde kayıtlı PHD AKADEMİ SANAYİ VE TİCARET LİMİTED ŞİRKETİ '
                  'firmamıza aittir ve firmamız tarafından işletilir.',
                  textColor!,
                ),
                _buildParagraph(
                  'Firmamız, çeşitli amaçlarla kişisel veriler toplayabilir. Aşağıda, toplanan '
                  'kişisel verilerin nasıl ve ne şekilde toplandığı, bu verilerin nasıl ve ne '
                  'şekilde korunduğu belirtilmiştir.',
                  textColor!,
                ),
                _buildParagraph(
                  'Firmamız bazı dönemlerde müşterilerine ve üyelerine kampanya bilgileri, yeni ürünler hakkında bilgiler, promosyon teklifleri gönderebilir. Üyelerimiz bu gibi bilgileri alıp almama konusunda her türlü seçimi üye olurken yapabilir, sonrasında üye girişi yaptıktan sonra hesap bilgileri bölümünden bu seçimi değiştirilebilir ya da kendisine gelen bilgilendirme iletisindeki linkle bildirim yapabilir.',
                  textColor!,
                ),
                _buildParagraph(
                  'Firmamız üzerinden veya eposta ile gerçekleştirilen onay sürecinde, üyelerimiz tarafından mağazamıza elektronik ortamdan iletilen kişisel bilgiler, Üyelerimiz ile yaptığımız "Kullanıcı Sözleşmesi" ile belirlenen amaçlar ve kapsam dışında üçüncü kişilere açıklanmayacaktır.',
                  textColor!,
                ),
                _buildParagraph(
                  'Sistemle ilgili sorunların tanımlanması ve verilen hizmet ile ilgili çıkabilecek sorunların veya uyuşmazlıkların hızla çözülmesi için, Firmamız, üyelerinin IP adresini kaydetmekte ve bunu kullanmaktadır. IP adresleri, kullanıcıları genel bir şekilde tanımlamak ve kapsamlı demografik bilgi toplamak amacıyla da kullanılabilir.',
                  textColor!,
                ),
                _buildParagraph(
                  'Firmamız, Üyelik Sözleşmesi ile belirlenen amaçlar ve kapsam dışında da, talep edilen bilgileri kendisi veya işbirliği içinde olduğu kişiler tarafından doğrudan pazarlama yapmak amacıyla kullanabilir. Kişisel bilgiler, gerektiğinde kullanıcıyla temas kurmak için de kullanılabilir. Firmamız tarafından talep edilen bilgiler veya kullanıcı tarafından sağlanan bilgiler veya Mağazamız üzerinden yapılan işlemlerle ilgili bilgiler; Firmamız ve iş birliği içinde olduğu kişiler tarafından, "Üyelik Sözleşmesi" ile belirlenen amaçlar ve kapsam dışında da, üyelerimizin kimliği ifşa edilmeden çeşitli istatistiksel değerlendirmeler, veri tabanı oluşturma ve pazar araştırmalarında kullanılabilir.',
                  textColor!,
                ),
                _buildParagraph(
                  'Firmamız, gizli bilgileri kesinlikle özel ve gizli tutmayı, bunu bir sır saklama yükümü olarak addetmeyi ve gizliliğin sağlanması ve sürdürülmesi, gizli bilginin tamamının veya herhangi bir kısmının kamu alanına girmesini veya yetkisiz kullanımını veya üçüncü bir kişiye ifşasını önlemek için gerekli tüm tedbirleri almayı ve gerekli özeni göstermeyi taahhüt etmektedir.',
                  textColor!,
                ),
              ]),
              SizedBox(height: 24),
              _buildInfoCard("Kredi Kartı Güvenliği", [
                _buildParagraph(
                  'Firmamız, alışveriş sitelerimizden alışveriş yapan kredi kartı sahiplerinin güvenliğini ilk planda tutmaktadır. Kredi kartı bilgileriniz hiçbir şekilde sistemimizde saklanmamaktadır. Ödeme sistemi olarak paytr.com kullanılmaktadır. Ödeme esnasında ilgili ödeme kuruluşuna aktarılmaktadır.',
                  textColor!,
                ),
                _buildParagraph(
                  'İşlemler sürecine girdiğinizde güvenli bir sitede olduğunuzu anlamak için dikkat etmeniz gereken iki şey vardır. Bunlardan biri tarayıcınızın en alt satırında bulunan bir anahtar ya da kilit simgesidir. Bu güvenli bir internet sayfasında olduğunuzu gösterir ve her türlü bilgileriniz şifrelenerek korunur. Bu bilgiler, ancak satış işlemleri sürecine bağlı olarak ve verdiğiniz talimat istikametinde kullanılır. Alışveriş sırasında kullanılan kredi kartı ile ilgili bilgiler alışveriş sitelerimizden bağımsız olarak şifrelenip sorgulanmak üzere ilgili ödeme kuruluşuna ulaştırılır. Kartın kullanılabilirliği onaylandığı takdirde alışverişe devam edilir. Kartla ilgili hiçbir bilgi tarafımızdan görüntülenemediğinden ve kaydedilmediğinden, üçüncü şahısların herhangi bir koşulda bu bilgileri ele geçirmesi engellenmiş olur.',
                  textColor!,
                ),
                _buildParagraph(
                  'Online olarak kredi kartı ile verilen siparişlerin ödeme/fatura/teslimat adresi bilgilerinin güvenilirliği firmamız tarafından Kredi Kartları Dolandırıcılığına karşı denetlenmektedir. Bu yüzden, alışveriş sitelerimizden ilk defa sipariş veren müşterilerin siparişlerinin tedarik ve teslimat aşamasına gelebilmesi için öncelikle finansal ve adres/telefon bilgilerinin doğruluğunun onaylanması gereklidir. Bu bilgilerin kontrolü için gerekirse kredi kartı sahibi müşteri ile veya ilgili banka ile irtibata geçilmektedir.',
                  textColor!,
                ),
                _buildParagraph(
                  'Üye olurken verdiğiniz tüm bilgilere sadece siz ulaşabilir ve siz değiştirebilirsiniz. Üye giriş bilgilerinizi güvenle koruduğunuz takdirde başkalarının sizinle ilgili bilgilere ulaşması ve bunları değiştirmesi mümkün değildir. Bu amaçla, üyelik işlemleri sırasında SSL güvenlik alanı içinde hareket edilir. Bu sistem kırılması mümkün olmayan bir uluslararası şifreleme standardıdır.',
                  textColor!,
                ),
                _buildParagraph(
                  'Bilgi hattı veya müşteri hizmetleri servisi bulunan ve açık adres ve telefon bilgilerinin belirtildiği İnternet alışveriş siteleri günümüzde daha fazla tercih edilmektedir. Bu sayede aklınıza takılan bütün konular hakkında detaylı bilgi alabilir, online alışveriş hizmeti sağlayan firmanın güvenirliği konusunda daha sağlıklı bilgi edinebilirsiniz.',
                  textColor!,
                ),
                _buildParagraph(
                  'Not: İnternet alışveriş sitelerinde firmanın açık adresinin ve telefonun yer almasına dikkat edilmesini tavsiye ediyoruz. Alışveriş yapacaksanız alışverişinizi yapmadan önce ürünü aldığınız mağazanın bütün telefon / adres bilgilerini not edin. Eğer güvenmiyorsanız alışverişten önce telefon ederek teyit edin. Firmamıza ait tüm online alışveriş sitelerimizde firmamıza dair tüm bilgiler ve firma yeri belirtilmiştir.',
                  textColor!,
                ),
              ]),
              SizedBox(height: 24),
              _buildInfoCard("Üçüncü Taraf Web Siteleri ve Uygulamalar", [
                _buildParagraph(
                  'Firmamız, web sitesi dâhilinde başka sitelere link verebilir. Firmamız, bu linkler vasıtasıyla erişilen sitelerin gizlilik uygulamaları ve içeriklerine yönelik herhangi bir sorumluluk taşımamaktadır. Firmamıza ait sitede yayınlanan reklamlar, reklamcılık yapan iş ortaklarımız aracılığı ile kullanıcılarımıza dağıtılır. İş bu sözleşmedeki Gizlilik Politikası Prensipleri, sadece Mağazamızın kullanımına ilişkindir, üçüncü taraf web sitelerini kapsamaz.',
                  textColor!,
                ),
              ]),
              SizedBox(height: 24),
              _buildInfoCard("İstisnai Haller", [
                _buildParagraph(
                  "Aşağıda belirtilen sınırlı hallerde Firmamız, işbu 'Gizlilik Politikası' hükümleri dışında kullanıcılara ait bilgileri üçüncü kişilere açıklayabilir. Bu durumlar sınırlı sayıda olmak üzere;\n\n"
                  "1. Kanun, Kanun Hükmünde Kararname, Yönetmelik v.b. yetkili hukuki otorite tarafından çıkarılan ve yürürlükte olan hukuk kurallarının getirdiği zorunluluklara uymak;\n"
                  "2. Firmamızın kullanıcılarla akdettiği Üyelik Sözleşmesi'nin ve diğer sözleşmelerin gereklerini yerine getirmek ve bunları uygulamaya koymak amacıyla;\n"
                  "3. Yetkili idari ve adli otorite tarafından usulüne göre yürütülen bir araştırma veya soruşturmanın yürütümü amacıyla kullanıcılarla ilgili bilgi talep edilmesi;\n"
                  "4. Kullanıcıların hakları veya güvenliklerini korumak için bilgi vermenin gerekli olduğu hallerdir.",
                  textColor!,
                ),
              ]),
              SizedBox(height: 24),
              _buildInfoCard("E-posta Güvenliği", [
                _buildParagraph(
                  "Firmamızın Müşteri Hizmetlerine, herhangi bir siparişinizle ilgili olarak göndereceğiniz e-postalarda, asla kredi kartı numaranızı veya şifrelerinizi yazmayınız. E-postalarda yer alan bilgiler üçüncü şahıslar tarafından görülebilir. Firmamız e-postalarınızdan aktarılan bilgilerin güvenliğini hiçbir koşulda garanti edemez.",
                  textColor!,
                ),
              ]),
              SizedBox(height: 24),
              _buildInfoCard("Tarayıcı Çerezleri", [
                _buildParagraph(
                  "Firmamız, www.kelibu.net adresini ziyaret eden kullanıcılar ve kullanıcıların web sitesini kullanımı hakkındaki bilgileri teknik bir iletişim dosyası (Çerez-Cookie) kullanarak elde edebilir. Bahsi geçen teknik iletişim dosyaları, ana bellekte saklanmak üzere bir internet sitesinin kullanıcının tarayıcısına (browser) gönderdiği küçük metin dosyalarıdır. Teknik iletişim dosyası site hakkında durum ve tercihleri saklayarak İnternetin kullanımını kolaylaştırır.",
                  textColor!,
                ),
                _buildParagraph(
                    "Teknik iletişim dosyası, siteyi kaç kişinin ziyaret ettiğini, bir kişinin siteyi hangi amaçla, kaç kez ziyaret ettiğini ve ne kadar sitede kaldıkları hakkında istatistiksel bilgileri elde etmeye ve kullanıcılar için özel tasarlanmış kullanıcı sayfalarından dinamik olarak reklam ve içerik üretilmesine yardımcı olur. Teknik iletişim dosyası, ana bellekte veya e-postanızdan veri veya başkaca herhangi bir kişisel bilgi almak için tasarlanmamıştır. Tarayıcıların pek çoğu başta teknik iletişim dosyasını kabul eder biçimde tasarlanmıştır ancak kullanıcılar dilerse teknik iletişim dosyasının gelmemesi veya teknik iletişim dosyasının gönderildiğinde uyarı verilmesini sağlayacak biçimde ayarları değiştirebilirler.",
                    textColor!),
              ]),
              SizedBox(height: 24),
              _buildInfoCard("Gizlilik Politikası Değişiklikleri", [
                _buildParagraph(
                  "Firmamız, işbu Gizlilik Politikası hükümlerini dilediği zaman sitede yayınlamak veya kullanıcılara elektronik posta göndermek veya sitesinde yayınlamak suretiyle değiştirebilir. Gizlilik Politikası hükümleri değiştiği takdirde, yayınlandığı tarihte yürürlük kazanır.",
                  textColor!,
                ),
              ]),
              SizedBox(height: 24),
              _buildInfoCard("Kullanıcı Bilgilerinin Korunması", [
                _buildParagraph(
                  "Firmamız, site üzerinden kullanıcıların ilettiği kişisel bilgileri, Üyelik Sözleşmesi ile belirlenen amaçlar ve kapsam dışında, üçüncü kişilere açıklamayacaktır. Kişisel bilgiler, ancak resmi makamlarca usulü dairesinde bu bilgilerin talep edilmesi halinde ve yürürlükteki emredici mevzuat hükümleri gereğince resmi makamlara açıklama yapılmasının zorunlu olduğu durumlarda resmi makamlara açıklanabilecektir.",
                  textColor!,
                ),
              ]),
              SizedBox(height: 24),
              _buildInfoCard("Güvenlik", [
                _buildParagraph(
                  "Firmamız, kullanıcı bilgilerinin gizliliğini korumak amacıyla bilgi güvenliği standartları ile ilgili gerekli tüm teknik ve idari tedbirleri almaktadır. Ancak, Firmamız, hukuki olmayan yollarla bu bilgilerin üçüncü kişiler tarafından ele geçirilmesini garanti edemez.",
                  textColor!,
                ),
              ]),
              SizedBox(height: 24),
              _buildInfoCard("Kullanıcı Hakları", [
                _buildParagraph(
                  "Kullanıcılar, Firmamıza başvurarak kendileriyle ilgili;\n"
                  "1. Kişisel veri işlenip işlenmediğini öğrenme,\n"
                  "2. Kişisel verileri işlenmişse buna ilişkin bilgi talep etme,\n"
                  "3. Kişisel verilerin işlenme amacını ve bunların amacına uygun kullanılıp kullanılmadığını öğrenme,\n"
                  "4. Yurt içinde veya yurt dışında kişisel verilerin aktarıldığı üçüncü kişileri bilme,\n"
                  "5. Kişisel verilerin eksik veya yanlış işlenmiş olması hâlinde bunların düzeltilmesini isteme,\n"
                  "6. İlgili kanun hükümlerine uygun olarak işlenmiş olmasına rağmen, işlenmesini gerektiren sebeplerin ortadan kalkması hâlinde kişisel verilerin silinmesini veya yok edilmesini isteme,\n"
                  "7. Düzeltme, silme ve yok etme talepleri neticesinde yapılan işlemlerin, kişisel verilerin aktarıldığı üçüncü kişilere bildirilmesini isteme,\n"
                  "8. İşlenen verilerin münhasıran otomatik sistemler vasıtasıyla analiz edilmesi suretiyle kişinin kendisi aleyhine bir sonucun ortaya çıkmasına itiraz etme,\n"
                  "9. Kişisel verilerin kanuna aykırı olarak işlenmesi sebebiyle zarara uğraması hâlinde zararın giderilmesini talep etme, haklarına sahiptir.",
                  textColor,
                ),
              ]),
              SizedBox(height: 24),
              _buildInfoCard("İletişim", [
                _buildParagraph(
                  "Firmamız tarafından yayınlanan gizlilik politikasının uygulanması ve yorumlanması ile ilgili sorularınız veya talepleriniz için aşağıdaki iletişim bilgilerini kullanabilirsiniz:\n\n"
                  "PHD AKADEMİ SANAYİ VE TİCARET LİMİTED ŞİRKETİ\n"
                  "Adres: Fertek Mah. Ömer Halisdemir Küme Evleri Teknopark Sitesi Teknopark Blok No:31 İç Kapı No:108 Merkez/Niğde\n"
                  "E-posta: info@kelibu.net\n"
                  "Telefon: +90 388 225 2148",
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
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
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
              child: Image.asset('assets/logo.png', width: 80, height: 80),
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Gizlilik Politikası",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Kelibu'nun Gizlilik ve Güvenlik Taahhüdü",
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 16),
          ...content,
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
