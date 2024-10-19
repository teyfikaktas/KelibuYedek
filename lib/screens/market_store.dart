import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/home_screen_widgets/home_screen.dart';
import 'package:kelibu/variables.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../main.dart';
import '../providers/sub_provider.dart';
import 'advantages/books_pro.dart';

const Color lightBackground = Color(0xFFF5F5F5);
const Color primaryColor = Color(0xFF2196F3);
const Color secondaryColor = Color(0xFF64B5F6);
const Color accentColor = Color(0xFFBBDEFB);
const Color textColor = Color(0xFF0D47A1);
class MarketPage extends StatefulWidget {
  const MarketPage({Key? key}) : super(key: key);

  @override
  _MarketPageState createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  List<Map<String, dynamic>> products = [];
  bool _isLoading = true;
  bool _hasSeenWelcomeBanner = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadWelcomeBannerPreference();
    await fetchData();
    if (!_hasSeenWelcomeBanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcomeBanner();
      });
    }
  }

  Future<void> _loadWelcomeBannerPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenWelcomeBanner = prefs.getBool('hasSeenWelcomeBanner') ?? false;
  }

  void _setWelcomeBannerSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcomeBanner', true);
  }

  /// Ekran açılır açılmaz gösterilecek banner
  void _showWelcomeBanner() {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı banner'ı kapatmak zorunda
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kelibu Logosu
              Image.asset(
                'assets/logo.png',
                height: 80.h,
              ),
              SizedBox(height: 20.h),
              // İndirim Mesajı
              Text(
                '3 Ay Boyunca %50 İndirim!',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              // Açıklama
              Text(
                'Kelibu PRO üyeliğinizi şimdi alın, avantajları kaçırmayın.',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              // Tamam Butonu
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _setWelcomeBannerSeen();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  padding:
                  EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
                ),
                child: Text(
                  'Tamam',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              // Alt Metin
              Text(
                'Kelibu bir PhD Akademi ürünüdür.',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// API'den Veri Çekme
  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('https://kelibu.net/api/getProductAll'),
        headers: {
          'X-Custom-Header': privacyKey.privacyKeyVariable,
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        products = data.map<Map<String, dynamic>>((item) => {
          "id": item["id"],
          "title": item["title"],
          "description": item["text"],
          "image": item["image"],
          "price": item["price"],
          "classroom_id": item["classroom_id"],
          "word_count": item["word_count"] ?? 0,
          "icon": FontAwesomeIcons.book,
          "count": item["word_count"] ?? 0,
        }).toList();
      } else {
        throw Exception('Ürünler yüklenirken bir hata oluştu');
      }
    } catch (e) {
      _showErrorDialog('Veriler yüklenirken bir hata oluştu: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Hata Dialogu
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hata', style: GoogleFonts.poppins()),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text('Tamam', style: GoogleFonts.poppins()),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => KelibuAdvantagesPage()),
    );
  }

  /// Başarı Dialogu
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        elevation: 16,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Image.asset(
                'assets/logo.png',
                height: 80.h,
              ),
              SizedBox(height: 20.h),
              // Başlık
              Text(
                'Başarılı',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 10.h),
              // Mesaj
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              // Tamam Butonu
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                  EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
                ),
                child: Text(
                  'Tamam',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ürünü Kütüphaneye Ekleme
  Future<void> addToLibrary(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> library = prefs.getStringList('library') ?? [];
    if (!library.contains(productId)) {
      library.add(productId);
      await prefs.setStringList('library', library);
      _showSuccessDialog('Ürün başarıyla kütüphaneye eklendi.');
    } else {
      _showErrorDialog('Bu ürünü zaten kütüphanede bulunduruyorsunuz.');
    }
  }

  /// URL Açma
  void _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorDialog('URL açılamadı: $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RedesignedKelibuAppBar(
        logoPath: 'assets/logo.png',
      ),
      backgroundColor: lightBackground,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, _) {
          bool isSubscribed = subscriptionProvider.isVip;

          return AnimationLimiter(
            child: isSubscribed
                ? VipPage(products)
                : PromotionPage(products),
          );
        },
      ),
    );
  }

  /// "PromotionPage" widget'ı
  Widget PromotionPage(List<Map<String, dynamic>> allSets) {
    return ListView(
      padding: EdgeInsets.only(top: 20),
      children: AnimationConfiguration.toStaggeredList(
        duration: const Duration(milliseconds: 375),
        childAnimationBuilder: (widget) => SlideAnimation(
          horizontalOffset: 50.0,
          child: FadeInAnimation(
            child: widget,
          ),
        ),
        children: [
          _buildLottieHeader(),
          SizedBox(height: 20),
          _buildKelibuProBanner(),
          SizedBox(height: 20),
          EnhancedProBenefitsCard(
            isButtonHide: true,
            onSubscribe: () {
              _showSuccessDialog('PRO üyelik satın alma işlemi başlatıldı.');
            },
          ),
          SizedBox(height: 20),
          _buildUserFeedback(),
          SizedBox(height: 20),
          _buildMySets(allSets),
          SizedBox(height: 20),
          _buildDiscountCampaign(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  /// "VipPage" widget'ı
  Widget VipPage(List<Map<String, dynamic>> allSets) {
    return ListView(
      padding: EdgeInsets.only(top: 20),
      children: AnimationConfiguration.toStaggeredList(
        duration: const Duration(milliseconds: 375),
        childAnimationBuilder: (widget) => SlideAnimation(
          horizontalOffset: 50.0,
          child: FadeInAnimation(
            child: widget,
          ),
        ),
        children: [
          KelibuDoodlePromo(
            color: Colors.lightBlueAccent,
          ),
          ClickableAdvantagesList(),
          SizedBox(height: 20),
          _buildMySets(allSets),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  /// "My Sets" Bölümü
  Widget _buildMySets(List<Map<String, dynamic>> sets, {Color? headerColor}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              'Kelibu Setleri',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: headerColor ?? Colors.black87,
              ),
            ),
          ),
          // Set Kartları
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: sets.length,
              itemBuilder: (context, index) {
                final set = sets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildSetCard(
                    context,
                    set,
                    cardColor: Colors.white,
                    shadowColor: Colors.black26,
                    titleColor: Colors.black87,
                    countColor: Colors.cyan,
                    iconColor: Colors.blue,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// "Set" Kartı
  Widget _buildSetCard(
      BuildContext context,
      Map<String, dynamic> set, {
        Color cardColor = Colors.white,
        Color shadowColor = Colors.black26,
        Color titleColor = Colors.black87,
        Color countColor = Colors.grey,
        Color iconColor = Colors.blue,
      }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double cardHeight = maxWidth * 0.6;
        final double imageHeight = cardHeight * 0.6;
        final double contentPadding = maxWidth * 0.04;

        return GestureDetector(
          onTap: () {
            _showSetDetails(context, set);
          },
          child: Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(maxWidth * 0.05),
            ),
            elevation: 6,
            shadowColor: shadowColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(maxWidth * 0.05)),
                  child: CachedNetworkImage(
                    imageUrl: 'https://kelibu.net/storage/${set["image"]}',
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: imageHeight,
                      color: Colors.grey[300],
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: imageHeight,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey[700],
                        size: maxWidth * 0.1,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              set["title"],
                              style: GoogleFonts.poppins(
                                fontSize: maxWidth * 0.045,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: contentPadding * 0.5),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: maxWidth * 0.05,
                            color: iconColor,
                          ),
                        ],
                      ),
                      SizedBox(height: contentPadding * 0.5),
                      Row(
                        children: [
                          Icon(
                            set["icon"],
                            size: maxWidth * 0.05,
                            color: iconColor,
                          ),
                          SizedBox(width: contentPadding * 0.5),
                          Text(
                            '${set["count"]} Kelime',
                            style: GoogleFonts.poppins(
                              fontSize: maxWidth * 0.035,
                              color: countColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Set Detaylarını Gösterme (Modal Bottom Sheet)
  void _showSetDetails(BuildContext context, Map<String, dynamic> set) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
              maxHeight:
              MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set["title"],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl:
                          'https://kelibu.net/storage/${set["image"]}',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(
                                height: 200,
                                color: Colors.grey[200],
                                child:
                                Center(child: CircularProgressIndicator()),
                              ),
                          errorWidget: (context, url, error) =>
                              Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        set["description"],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Kapat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Lottie Header
  Widget _buildLottieHeader() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Lottie.network(
        'https://assets9.lottiefiles.com/packages/lf20_xlmz9xwm.json',
        fit: BoxFit.cover,
      ),
    );
  }
// Lottie Header

  /// Kelibu PRO Banner
  Widget _buildKelibuProBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor, width: 3),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Bölüm
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Asset logo.png kullanımı
                    Image.asset('assets/logo.png', height: 40),
                    const SizedBox(width: 12),
                    Text(
                      'Kelibu PRO',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AdvantagesPage(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Avantajları Gör',
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Alt Bölüm
            Text(
              'Tüm özelliklere sınırsız erişim!',
              style: GoogleFonts.poppins(
                  fontSize: 18, color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 20),
            // Fiyatlandırma Seçenekleri
            Column(
              children: [
                _buildPricingOption('Aylık', '₺399', '179₺'),
                const SizedBox(height: 8),
                _buildPricingOption('Yıllık', '₺1799', '1,199₺'),
              ],
            ),
            const SizedBox(height: 16),
            // Abone Ol Butonu
            SizedBox(
              width: double.infinity, // Butonu tam genişlik yapar
              child: ElevatedButton(
                onPressed: () {
                  // Satın alma işlemi
                  _showSubscriptionDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: textColor,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Hemen abone ol!',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fiyatlandırma Seçeneği
  Widget _buildPricingOption(
      String period, String originalPrice, String discountedPrice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          period,
          style:
          GoogleFonts.poppins(fontSize: 16, color: Colors.white.withOpacity(0.8)),
        ),
        Row(
          children: [
            Text(
              originalPrice,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              discountedPrice,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Özellik Karşılaştırması
  Widget _buildFeatureComparison() {
    final features = [
      {
        'feature': 'Kelime Setleri',
        'free': 'Sınırlı',
        'pro': 'Sınırsız',
      },
      {
        'feature': 'Canlı Yarış',
        'free': 'Yok',
        'pro': 'Var',
      },
      {
        'feature': 'Özel İndirimler',
        'free': 'Yok',
        'pro': 'Var',
      },
      {
        'feature': 'Reklamlar',
        'free': 'Var',
        'pro': 'Yok',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Ücretsiz vs PRO Sürüm',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              // Başlık Satırı
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Özellikler',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Ücretsiz',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'PRO',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const Divider(thickness: 1.5),
              // Özellik Satırları
              ...features.map((feature) => _buildFeatureRow(feature)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  /// Özellik Satırı
  Widget _buildFeatureRow(Map<String, String> feature) {
    bool isPro = feature['pro']!.toLowerCase() == 'var' || feature['pro']!.toLowerCase() == 'sınırsız';
    bool isFree = feature['free']!.toLowerCase() == 'var' || feature['free']!.toLowerCase() == 'sınırlı';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature['feature']!,
              style: GoogleFonts.poppins(fontSize: 16, color: textColor),
            ),
          ),
          Expanded(
            child: Center(
              child: isFree
                  ? Icon(Icons.check, color: primaryColor)
                  : Icon(Icons.close, color: Colors.red),
            ),
          ),
          Expanded(
            child: Center(
              child: isPro
                  ? Icon(Icons.check, color: primaryColor)
                  : Icon(Icons.close, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUserFeedback() {
    final feedbacks = [
      {
        'user': 'Ahmet Y.',
        'comment': 'Kelibu PRO sayesinde dil öğrenimim hızlandı!',
        'rating': 5
      },
      {
        'user': 'Ayşe K.',
        'comment': 'Uygulama çok kullanışlı ve pratik.',
        'rating': 4
      },
      {
        'user': 'Mehmet D.',
        'comment': 'Kelibu PRO avantajları gerçekten harika.',
        'rating': 5
      },
      {
        'user': 'Elif S.',
        'comment': 'Tavsiye ederim, çok memnunum.',
        'rating': 5
      },
      {
        'user': 'Caner B.',
        'comment': 'Öğrenme sürecimi kolaylaştırdı.',
        'rating': 4
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kullanıcı Yorumları',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Tüm yorumları görüntüleme işlevi
                },
                child: Text(
                  'Tümünü Gör',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              final feedback = feedbacks[index];
              return _buildFeedbackCard(feedback);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    feedback['user'][0],
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback['user'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          5,
                              (index) => Icon(
                            index < feedback['rating'] ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              feedback['comment'],
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  /// Geri Bildirim Kartı

  /// "My Sets" Bölümü

  /// Set Kartı

  /// Set Detaylarını Gösterme (Modal Bottom Sheet)

  /// Özel Kampanya Bölümü
  Widget _buildDiscountCampaign() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [secondaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Özel Kampanya!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '3 ay boyunca %50 indirim',
            style:
            GoogleFonts.poppins(fontSize: 18, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Kampanya detayları
              _launchURL('https://kelibu.com/kampanya-detaylari');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text('FIRSATI YAKALA',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class RedesignedKelibuAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String logoPath; // Logonuzun dosya yolu

  const RedesignedKelibuAppBar({Key? key, required this.logoPath})
      : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: primaryColor, // AppBar arka plan rengi
      elevation: 0,
      centerTitle: true,
      title: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2), // Çerçeve rengi ve kalınlığı
          borderRadius: BorderRadius.circular(8), // Köşe yuvarlama
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logonuzu ekleyin
            Image.asset(
              logoPath,
              height: 30, // Logonuzun yüksekliğini ayarlayın
            ),
            const SizedBox(width: 8),
            Text(
              'Kelibu',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange, // "Pro" yazısı arka plan rengi
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Pro',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      // actions kısmı kaldırıldı
    );
  }
}

/// Avantajlar Sayfası
class AdvantagesPage extends StatelessWidget {
  const AdvantagesPage({Key? key}) : super(key: key);

  void _showSuccessDialogStatic(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Başarılı', style: GoogleFonts.poppins()),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text('Tamam', style: GoogleFonts.poppins()),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelibu Avantajları',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: lightBackground,
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          EnhancedProBenefitsCard(  isButtonHide: true,

            onSubscribe: () {
              _showSuccessDialogStatic(context, 'PRO üyelik satın alma işlemi başlatıldı.');

            },
          ),
        ],
      ),
    );
  }
}

class EnhancedProBenefitsCard extends StatelessWidget {
  final VoidCallback onSubscribe;
  final bool isButtonHide;

  const EnhancedProBenefitsCard({
    Key? key,
    required this.onSubscribe,
    this.isButtonHide = false, // Varsayılan olarak buton görünür
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final benefits = [
      {
        'icon': FontAwesomeIcons.rocket,
        'text': 'Tüm yeni özelliklere erken erişim'
      },
      {
        'icon': FontAwesomeIcons.graduationCap,
        'text': 'PhD Akademi dil kursu üyeliği %10 indirim'
      },
      {
        'icon': FontAwesomeIcons.book,
        'text': 'PhD Akademi Level 1-2-3 kitaplarına ücretsiz erişim'
      },
      {
        'icon': FontAwesomeIcons.mobileScreen,
        'text': 'SelfEnglish uygulamasında Beta erişimi'
      },
      {
        'icon': FontAwesomeIcons.chartLine,
        'text': 'Özelleştirilmiş takip'
      },
      {
        'icon': FontAwesomeIcons.flag,
        'text': 'Sınırsız canlı yarış hakkı!'
      },
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      color: secondaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.crown,
                  color: Colors.amberAccent,
                  size: 28,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Kelibu ",
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        WidgetSpan(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              "PRO",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                        ),
                        TextSpan(
                          text: " Avantajları!",
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ...benefits.asMap().entries.map((entry) {
              final index = entry.key;
              final benefit = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(
                        benefit['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: AutoSizeText(
                        benefit['text'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            color: Colors.white,
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 20.h),
            if (!isButtonHide) // Buton görünürlüğü kontrolü
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      onSubscribe();
                      Navigator.of(context).pop(); // Kartı kapat
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    child: Text(
                      'Kapat',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}/// "Setler" Sayfası
class SetsPage extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const SetsPage({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Özel paketleri filtreleme (classroom_id = 40 gibi)
    List<Map<String, dynamic>> sets =
    products.where((item) => item["classroom_id"] == 40).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Setler',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: lightBackground,
      body: sets.isEmpty
          ? Center(
        child: Text(
          'Gösterilecek set bulunamadı.',
          style: GoogleFonts.poppins(fontSize: 18, color: textColor),
        ),
      )
          : ListView.builder(
        itemCount: sets.length,
        itemBuilder: (context, index) {
          final set = sets[index];
          return _buildSetTile(context, set);
        },
      ),
    );
  }

  /// Set Tile'ı
  Widget _buildSetTile(BuildContext context, Map<String, dynamic> set) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      elevation: 5,
      child: ListTile(
        leading: CachedNetworkImage(
          imageUrl: 'https://kelibu.net/storage/${set['image']}',
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Image.asset(
            'assets/logo.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
        title: Text(
          set['title'],
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(
          set['description'],
          style: GoogleFonts.poppins(color: textColor),
        ),
        trailing: Text(
          '₺${set['price']}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor),
        ),
        onTap: () {
          // Paket detaylarına gitmek için navigasyon ekleyebilirsiniz
        },
      ),
    );
  }
}

// Ana Sayfa
class KelibuAdvantagesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Genel arka plan beyaz yapıldı
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title:  Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logonuzu ekleyin
            Image.asset(
              'assets/logo.png',
              height: 30, // Logonuzun yüksekliğini ayarlayın
            ),
            const SizedBox(width: 8),
            Text(
              'Kelibu',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange, // "Pro" yazısı arka plan rengi
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Pro',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SubscriptionOptions(),
                  SizedBox(height: 24),
                  CustomSectionTitle(
                    mainTitle: 'Kelibu',
                    highlightedText: 'Pro',
                    subTitle: 'ile Neler Kazanıyorsunuz?',
                  ),
                  SizedBox(height: 16),
                  AdvantagesList(),
                  SizedBox(height: 24),
                  AdditionalFeatures(),
                  SizedBox(height: 24),
                  FAQSection(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomSectionTitle extends StatelessWidget {
  final String mainTitle;
  final String highlightedText;
  final String subTitle;

  const CustomSectionTitle({
    Key? key,
    required this.mainTitle,
    required this.highlightedText,
    required this.subTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ekran genişliğini alıyoruz
    final screenWidth = MediaQuery.of(context).size.width;

    // Ekran genişliğine bağlı olarak dinamik font boyutları
    double mainFontSize = screenWidth > 600 ? 24 : 18;
    double subFontSize = screenWidth > 600 ? 24 : 18;
    double proFontSize = screenWidth > 600 ? 16 : 12;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Genişlik kontrolü yaparak responsive düzen oluşturuyoruz
        bool isSmallScreen = constraints.maxWidth < 400;

        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.start,
          children: [
            Text(
              mainTitle,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: mainFontSize,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4, height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange, // "Pro" yazısı arka plan rengi
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                highlightedText,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: proFontSize,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 4, height: 8),
            Text(
              subTitle,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: subFontSize,
                color: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }
}
// SliverAppBar Widget'ı
class KelibuSliverAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 50.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue[700], // AppBar arka plan rengi
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          '',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

}

// Abonelik Seçenekleri Widget'ı
class SubscriptionOptions extends StatefulWidget {
  @override
  _SubscriptionOptionsState createState() => _SubscriptionOptionsState();
}

class _SubscriptionOptionsState extends State<SubscriptionOptions> {
  final Set<String> _kProductIds = Platform.isAndroid
      ? {'com.kelibu.pro'}
      : {'kelibu_pro_month', 'kelibu_pro_year'};
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  bool _loading = true;


  @override
  void initState() {
    super.initState();
    _initializeInAppPurchase();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _initializeInAppPurchase() async {
    setState(() {
      _loading = true;
    });

    try {
      _isAvailable = await InAppPurchase.instance.isAvailable();
      if (!_isAvailable) {
        throw Exception('In-app purchases are not available on this device.');
      }

      final ProductDetailsResponse response =
      await InAppPurchase.instance.queryProductDetails(_kProductIds);

      if (response.error != null) {
        throw Exception('Error querying product details: ${response.error}');
      }

      if (response.productDetails.isEmpty) {
        throw Exception('No products found. Are the IDs correct?');
      }

      setState(() {
        _products = response.productDetails;
        print(_products);
        _loading = false;
      });

// Ürünlerin özelliklerini tek tek yazdırmak için:
      for (var product in _products) {
        print('Ürün adı: ${product.title}, Fiyatı: ${product.price}');
      }

      _subscription = InAppPurchase.instance.purchaseStream.listen(
        _listenToPurchaseUpdated,
        onDone: () => _subscription?.cancel(),
        onError: (error) => throw Exception('Purchase stream error: $error'),
      );
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showErrorDialog('Ürünler yüklenirken bir hata oluştu', e.toString());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text('Tamam', style: GoogleFonts.poppins()),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 80,
                  height: 80,
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                SizedBox(height: 20),
                Text(
                  'İşleminiz gerçekleştiriliyor...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Lütfen bekleyin, bu işlem biraz zaman alabilir.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    _showLoadingDialog(context);
    try {
      for (var purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.status == PurchaseStatus.purchased) {
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _hideLoadingDialog(context);
            _showSuccessDialog(context, purchaseDetails.productID);
          } else {
            _hideLoadingDialog(context);
            _handleError('Satın alma doğrulanamadı.');
          }
        } else if (purchaseDetails.status == PurchaseStatus.pending) {
          // Satın alma beklemede
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          _hideLoadingDialog(context);
          _handleError(purchaseDetails.error?.message ?? 'Satın alma hatası.');
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    } catch (e) {
      _hideLoadingDialog(context);
      _handleError('Beklenmeyen bir hata oluştu: $e');
    }
  }
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    String receipt = purchaseDetails.verificationData.serverVerificationData;
    String productId = purchaseDetails.productID;
    String platform = Platform.isAndroid ? 'android' : 'ios';

    // Abonelik tipini belirlemek için productId kontrolü
    try {
      SubscriptionProvider provider = Provider.of<SubscriptionProvider>(context, listen: false);

      // provider.subscribe metodunu güncelleyerek subscriptionType ve isPriceStartingWith1199 parametrelerini ekleyin
      Map<String, dynamic> result = await provider.subscribe(
        platform,
        receipt,
        productId
      );
      
      print('Abonelik sonucu: $result');

      return result['success'] == true;
    } catch (e) {
      print('Satın alma doğrulanırken hata oluştu: $e');
      return false;
    }
  }

  void _handleError(String message) {
    print('Error: $message');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog(BuildContext context, String productId) async {
    String message;
    if (productId == 'kelibu-pro-month') {
      message = 'Aylık aboneliğiniz başarıyla satın alındı.';
    } else if (productId == 'kelibu-pro-year') {
      message = 'Yıllık aboneliğiniz başarıyla satın alındı.';
    } else {
      message = 'Abonelik başarıyla satın alındı.';
    }

    // VIP durumunu kaydet
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('VIP', true);
    // Ana ekrana yönlendir
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainScreen(),
      ),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _purchaseSubscription(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue!.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildKelibuProHeader(),
          SizedBox(height: 8),
          Row(
            children: _products.map((product) {
              bool isPrimary = product.price.contains('199') || product.price.contains('34');
              return Expanded(
                child: Column(
                  children: [
                    SubscriptionButton(
                      title: product.title,
                      price: product.price,
                      savings: isPrimary ? 'En çok tercih edilen!' : null,
                      onPressed: () => _purchaseSubscription(product),
                      isPrimary: isPrimary,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(delay: 300.ms);
  }

  Widget buildKelibuProHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kelibu',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Pro',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Hemen geçin!',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}


class SubscriptionButton extends StatelessWidget {
  final String title;
  final String price;
  final String? savings;
  final VoidCallback onPressed;
  final bool isPrimary;

  const SubscriptionButton({
    Key? key,
    required this.title,
    required this.price,
    this.savings,
    required this.onPressed,
    this.isPrimary = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.blue.shade50 : Colors.white,
        border: Border.all(color: isPrimary ? Colors.blue : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Colors.blue.shade700 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: isPrimary ? 'Yıllık\n' : 'Aylık\n',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                TextSpan(
                  text: price,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isPrimary ? Colors.blue.shade700 : Colors.black,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          if (savings != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                savings!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              foregroundColor: isPrimary ? Colors.white : Colors.black87, backgroundColor: isPrimary ? Colors.blue : Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Satın Al!'),
          ),
        ],
      ),
    );
  }
}

// Diğer gerekli paketleri eklemeyi unutmayın, örneğin animate_do veya lottie.

class SuccessDialogContent extends StatefulWidget {
  final String subscriptionType;

  const SuccessDialogContent({Key? key, required this.subscriptionType}) : super(key: key);

  @override
  _SuccessDialogContentState createState() => _SuccessDialogContentState();
}

class _SuccessDialogContentState extends State<SuccessDialogContent> with SingleTickerProviderStateMixin {
  int _secondsRemaining = 5;
  Timer? _timer;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupAnimation();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainScreen()),
              (Route<dynamic> route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String message = 'Kelibu PRO aboneliğiniz başarıyla aktifleştirildi.';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 40,
                  height: 40,
                ),
                SizedBox(width: 8),
                Text(
                  'Kelibu',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Color(0xFF58CC02),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pro',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            ScaleTransition(
              scale: _animation,
              child: Lottie.asset(
                'assets/success.json',
                width: 150,
                height: 150,
                repeat: false,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Tebrikler!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF58CC02),
              ),
            ),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            Text(
              '$_secondsRemaining saniye sonra ana sayfaya yönlendirileceksiniz',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity, // Butonu tam genişlikte yapar
              child: ElevatedButton(
                child: Text(
                  'Hemen Ana Sayfaya Git',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // Metin rengini açık yapın
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF58CC02), // Buton arka plan rengi
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Buton köşelerini yuvarlatma
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16), // Dikey padding
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MainScreen()),
                        (Route<dynamic> route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CongratulationsDialog extends StatefulWidget {
  final String message;

  CongratulationsDialog({required this.message});

  @override
  _CongratulationsDialogState createState() => _CongratulationsDialogState();
}

class _CongratulationsDialogState extends State<CongratulationsDialog> {
  int _secondsRemaining = 15;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
        _startTimer();
      } else {
        _navigateToHomeScreen();
        // Ana sayfaya yönlendirme kodunu buraya ekleyebilirsiniz
      }
    });
  }
  void _navigateToHomeScreen() async {
    // SharedPreferences nesnesini al
    final prefs = await SharedPreferences.getInstance();

    // isbuyed değerini true olarak ayarla
    await prefs.setBool('isbuyed', true);

    // Ana sayfaya yönlendir
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(
          message: 'Tebrikler! Ana sayfaya yönlendirildiniz.',
        ),
      ),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                strokeWidth: 6,
                value: 1 - (_secondsRemaining / 15),
              ),
              Image.asset('assets/logo.png', height: 60),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Tebrikler!',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 16),
          Text(
            widget.message,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Dil eğitiminde başarılar ve teşekkürler!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
              SizedBox(width: 16),
              Text(
                'Ana sayfaya yönlendiriliyorsunuz...',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '$_secondsRemaining saniye sonra ana sayfaya yönlendirileceksiniz. Sizin için son ayarlamaları yapıyoruz!' ,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

void showCongratulationsDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => CongratulationsDialog(message: message),
  );
}
// Bölüm Başlığı Widget'ı
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.blue[800],
      ),
    ).animate().fadeIn(duration: 500.ms).slideX();
  }
}

class ClickableAdvantagesList extends StatelessWidget {
  static const List<Map<String, dynamic>> advantages = [
    {
      'icon': FontAwesomeIcons.book,
      'title': 'Setler',
      'description': "Kelibu'nun tüm setlerine erişim",
      'color': Colors.yellow,
      'route': '/home',
      'linkText': 'Sizin için hazırlanmış tüm setlere ücretsiz erişin!',
    },
    {
      'icon': FontAwesomeIcons.rocket,
      'title': 'Erken Erişim',
      'description': 'Tüm yeni özelliklere öncelikli erişim için Beta programına katılın!',
      'color': Colors.orange,
      'route': '/beta-apply',
      'linkText': 'Beta özellikler için tıklayınız',
    },
    {
      'icon': FontAwesomeIcons.graduationCap,
      'title': 'PhD Akademi İndirimi',
      'description': 'Dil kurslarında %10 özel indirim',
      'color': Colors.green,
      'route': '/phd-academy-info',
      'linkText': 'PhD Akademi ön bilgi için tıklayınız',
    },
    {
      'icon': FontAwesomeIcons.mobileScreen,
      'title': 'SelfEnglish Beta',
      'description': 'SelfEnglish uygulamasına özel beta erişimi',
      'color': Colors.blue,
      'route': '/self-english',
      'linkText': 'Self English için tıklayınız',
    },
    {
      'icon': FontAwesomeIcons.flag,
      'title': 'Yarış Modu',
      'description': 'Yarış modunu denemek için tıklayın!',
      'color': Colors.red,
      'route': '/race',
      'linkText': '',
    },
  ];

  const ClickableAdvantagesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: advantages.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final advantage = advantages[index];
        return ClickableAdvantageItem(
          icon: advantage['icon'] as IconData,
          title: advantage['title'] as String,
          description: advantage['description'] as String,
          delay: (index * 200).ms,
          route: advantage['route'] as String,
          linkText: advantage['linkText'] as String,
        );
      },
    );
  }
}

class ClickableAdvantageItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Duration delay;
  final String linkText;
  final String route;

  const ClickableAdvantageItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
    required this.linkText,
    required this.route,
  }) : super(key: key);

  @override
  _ClickableAdvantageItemState createState() => _ClickableAdvantageItemState();
}

class _ClickableAdvantageItemState extends State<ClickableAdvantageItem> {
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
    final Color primaryColor = _isDarkMode ? Colors.tealAccent : Colors.teal;
    final Color backgroundColor = _isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : Colors.black87;
    final Color descriptionColor = _isDarkMode ? Colors.white70 : Colors.black54;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, widget.route),
          child: Container(
            padding: EdgeInsets.all(maxWidth * 0.04),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(maxWidth * 0.04),
              boxShadow: [
                BoxShadow(
                  color: _isDarkMode ? Colors.black26 : Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(maxWidth * 0.03),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(maxWidth * 0.02),
                  ),
                  child: Icon(widget.icon, color: primaryColor, size: maxWidth * 0.06),
                ),
                SizedBox(width: maxWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: maxWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: maxWidth * 0.01),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: maxWidth * 0.035,
                          color: descriptionColor,
                        ),
                      ),
                      SizedBox(height: maxWidth * 0.02),
                      Text(
                        widget.linkText,
                        style: TextStyle(
                          fontSize: maxWidth * 0.035,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: primaryColor, size: maxWidth * 0.05),
              ],
            ),
          ),
        );
      },
    );
  }
}
// Testimonial (Kullanıcı Yorumu) Listesi Widget'ı

// Her bir Testimonial Kartı Widget'ı
class TestimonialCard extends StatelessWidget {
  final Map<String, dynamic> testimonial;

  const TestimonialCard({Key? key, required this.testimonial}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TestimonialHeader(
              name: testimonial['name'] as String,
              rating: testimonial['rating'] as int,
            ),
            SizedBox(height: 12),
            Text(
              testimonial['comment'] as String,
              style: GoogleFonts.poppins(fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(delay: 200.ms);
  }
}

// Testimonial Başlığı Widget'ı
class TestimonialHeader extends StatelessWidget {
  final String name;
  final int rating;

  const TestimonialHeader({Key? key, required this.name, required this.rating}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          child: Text(
            name[0],
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
          ),
          backgroundColor: Colors.blue[100],
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue[800]),
              ),
              Row(
                children: List.generate(
                  5,
                      (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Ek Özellikler Listesi Widget'ı
class AdditionalFeatures extends StatelessWidget {
  final List<Map<String, String>> features = [
    {
      'icon': 'FontAwesomeIcons.trophy',
      'title': 'Sınırsız Canlı Yarışma',
      'description': 'Diğer kullanıcılarla yarışarak öğrenmenizi pekiştirin.',
    },
    {
      'icon': 'FontAwesomeIcons.comments',
      'title': 'Özel Destek',
      'description': 'PRO üyelere özel 7/24 canlı destek hizmeti.',
    },
    {
      'icon': 'FontAwesomeIcons.clockRotateLeft',
      'title': 'İlerleme Geçmişi',
      'description': 'Detaylı ilerleme raporları ve geçmiş performans analizi.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ekran genişliğine göre kolon sayısını belirleme
        int columns = constraints.maxWidth < 800 ? 1 : 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: 'Ek Özellikler'),
            SizedBox(height: 16),
            GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: features.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: constraints.maxWidth < 800 ? 3 : 5, // Yüksekliği ayarlamak için
              ),
              itemBuilder: (context, index) {
                final feature = features[index];
                return FeatureItem(
                  icon: _getIconData(feature['icon']!),
                  title: feature['title']!,
                  description: feature['description']!,
                );
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    // FontAwesomeIcons'dan doğrudan IconData almak daha güvenlidir
    switch (iconName) {
      case 'FontAwesomeIcons.trophy':
        return FontAwesomeIcons.trophy;
      case 'FontAwesomeIcons.comments':
        return FontAwesomeIcons.comments;
      case 'FontAwesomeIcons.clockRotateLeft':
        return FontAwesomeIcons.clockRotateLeft;
      default:
        return Icons.help_outline;
    }
  }
}

// Her bir Ek Özellik Ögesi Widget'ı
class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: Colors.blue[700], size: 20),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideX();
  }
}

// Sıkça Sorulan Sorular (FAQ) Bölümü Widget'ı
class FAQSection extends StatelessWidget {
  final List<Map<String, String>> faqItems = [
    {
      'question': 'Kelibu PRO\'yu nasıl iptal edebilirim?',
      'answer': 'Aboneliğinizi istediğiniz zaman hesap ayarlarınızdan veya müşteri hizmetlerimizle iletişime geçerek iptal edebilirsiniz.'
    },
    {
      'question': 'Ödeme yöntemleri nelerdir?',
      'answer': 'Kredi kartı, banka kartı ve çeşitli online ödeme yöntemlerini kabul ediyoruz.'
    },
    {
      'question': 'İade politikanız nedir?',
      'answer': 'İlk 14 gün içinde herhangi bir sebep belirtmeden tam iade garantisi sunuyoruz.'
    },
    {
      'question': 'Kelibu PRO\'nun avantajları hemen aktif olur mu?',
      'answer': 'Evet, ödemeniz onaylandıktan hemen sonra tüm PRO avantajlarına erişim sağlayabilirsiniz.'
    },
    {
      'question': 'Öğrenci indirimi var mı?',
      'answer': 'Evet, geçerli bir öğrenci kimliği ile %20 indirim sağlıyoruz. Detaylar için müşteri hizmetlerimizle iletişime geçin.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'Sıkça Sorulan Sorular'),
        SizedBox(height: 16),
        ...faqItems.map((item) => FAQItem(
          question: item['question']!,
          answer: item['answer']!,
        )),
      ],
    );
  }
}

// Her bir FAQ Ögesi Widget'ı
class FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const FAQItem({Key? key, required this.question, required this.answer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue[700]),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            answer,
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX();
  }
}

// KelibuDoodlePromo.dart

class KelibuDoodlePromo extends StatelessWidget {
  final Color color;

  const KelibuDoodlePromo({
    Key? key,
    required this.color,
  }) : super(key: key);

  List<Shape> _generateShapes(Size size) {
    final random = Random();
    final List<Shape> shapes = [];

    // Oval şekiller
    for (int i = 0; i < 30; i++) {
      final opacity = 0.05 + random.nextDouble() * 0.1;
      final paintColor = Colors.white.withOpacity(opacity);
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double width = random.nextDouble() * 50 + 10;
      double height = random.nextDouble() * 50 + 10;
      shapes.add(OvalShape(
        rect: Rect.fromLTWH(x, y, width, height),
        color: paintColor,
      ));
    }

    // Çizgiler
    for (int i = 0; i < 20; i++) {
      final opacity = 0.05 + random.nextDouble() * 0.1;
      final paintColor = Colors.white.withOpacity(opacity);
      double startX = random.nextDouble() * size.width;
      double startY = random.nextDouble() * size.height;
      double endX = startX + random.nextDouble() * 30 - 15;
      double endY = startY + random.nextDouble() * 30 - 15;
      double strokeWidth = random.nextDouble() * 2 + 1;
      shapes.add(LineShape(
        start: Offset(startX, startY),
        end: Offset(endX, endY),
        strokeWidth: strokeWidth,
        color: paintColor,
      ));
    }

    return shapes;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final shapes = _generateShapes(size);

        return Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(25, 0, 0, 0),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: DoodleBackgroundPainter(shapes: shapes),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Kelibu ',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          TextSpan(
                            text: 'Doo',
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.purpleAccent,
                              fontFamily: 'Indie Flower',
                            ),
                          ),
                          TextSpan(
                            text: 'dle',
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.tealAccent,
                              fontFamily: 'Indie Flower',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Kelibu\'nun yeni PDF uygulaması KelibuDoodle\'ı PhD Akademi setleri ile deneyin!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => KelibuProListWidget(),
                          ),
                        );
                      },
                      child: Text(
                        'Hemen Dene',
                        style: TextStyle(fontFamily: 'Roboto', color: color),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

abstract class Shape {
  final Color color;

  Shape({required this.color});
}

class OvalShape extends Shape {
  final Rect rect;

  OvalShape({required this.rect, required Color color}) : super(color: color);
}

class LineShape extends Shape {
  final Offset start;
  final Offset end;
  final double strokeWidth;

  LineShape({
    required this.start,
    required this.end,
    required this.strokeWidth,
    required Color color,
  }) : super(color: color);
}

class DoodleBackgroundPainter extends CustomPainter {
  final List<Shape> shapes;

  DoodleBackgroundPainter({required this.shapes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var shape in shapes) {
      paint.color = shape.color;
      if (shape is OvalShape) {
        paint.style = PaintingStyle.fill;
        canvas.drawOval(shape.rect, paint);
      } else if (shape is LineShape) {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = shape.strokeWidth;
        canvas.drawLine(shape.start, shape.end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// DuolingoStyleBackgroundPainter.dart

class DuolingoStyleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Duolingo tarzı dalgalı arka plan
    final path = Path();
    path.moveTo(0, size.height * 0.75);

    for (int i = 0; i < 5; i++) {
      path.quadraticBezierTo(
        size.width * (0.2 + 0.2 * i),
        size.height * (0.7 + (i % 2 == 0 ? 0.1 : -0.1)),
        size.width * (0.4 + 0.2 * i),
        size.height * 0.75,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Doodle ikonları
    drawDoodleIcon(canvas, size, Icons.brush, 0.1, 0.1);
    drawDoodleIcon(canvas, size, Icons.edit, 0.9, 0.2);
    drawDoodleIcon(canvas, size, Icons.color_lens, 0.2, 0.8);
    drawDoodleIcon(canvas, size, Icons.format_paint, 0.8, 0.7);
  }

  void drawDoodleIcon(
      Canvas canvas, Size size, IconData icon, double dx, double dy) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 24,
          fontFamily: icon.fontFamily,
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * dx, size.height * dy));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

