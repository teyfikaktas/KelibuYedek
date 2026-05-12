import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as mathx;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kelibu/screens/home_screen_widgets/home_screen.dart';
import 'package:kelibu/screens/privary_policy.dart';
import 'package:kelibu/screens/vipanel/vipmain.dart';
import 'package:kelibu/variables.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../providers/sub_provider.dart';

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

  // RevenueCat Offerings
  Offerings? _offerings;
  bool _offeringsLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchRevenueCatOfferings();
  }

  Future<void> _initializeData() async {
    await _loadWelcomeBannerPreference();

    bool isSubscribed = context.read<SubscriptionProvider>().isVip;
    if (!isSubscribed) {
      await checkMIUIOptimizations();
    }

    await fetchData();
  }

  Future<void> _fetchRevenueCatOfferings() async {
    setState(() => _offeringsLoading = true);
    try {
      Offerings offerings = await Purchases.getOfferings();
      setState(() {
        _offerings = offerings;
      });
    } catch (e) {
      debugPrint('RevenueCat offerings hata: $e');
    } finally {
      setState(() => _offeringsLoading = false);
    }
  }

  void showKelibuProPaywall(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => KelibuProPaywall(
        offerings: _offerings,
        isOfferingsLoading: _offeringsLoading,
      ),
    );
  }

  Future<void> checkMIUIOptimizations() async {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 40,
                  color: Colors.amber.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Önemli Bilgi',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Satın alma işlemlerinin sağlıklı çalışması için lütfen pil tasarufu modlarınızı kapatın:',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'Ayarlar > Pil ve Performans\n\nPil Tasarruf modu ağ isteklerini sınırlayacağı için, satın alma işlemlerinde sorun çıkarabilir.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Anladım',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _loadWelcomeBannerPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenWelcomeBanner = prefs.getBool('hasSeenWelcomeBanner') ?? false;
  }

  void _setWelcomeBannerSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcomeBanner', true);
  }

  void _showWelcomeBanner() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
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
              Image.asset(
                'assets/logo.png',
                height: 80.h,
              ),
              SizedBox(height: 20.h),
              Text(
                'Kelibu PRO üyeliğinizi şimdi alın, avantajları kaçırmayın.',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
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
        products = data
            .map<Map<String, dynamic>>((item) => {
                  "id": item["id"],
                  "title": item["title"],
                  "description": item["text"],
                  "image": item["image"],
                  "price": item["price"],
                  "classroom_id": item["classroom_id"],
                  "word_count": item["word_count"] ?? 0,
                  "icon": FontAwesomeIcons.book,
                  "count": item["word_count"] ?? 0,
                })
            .toList();
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
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
              Image.asset(
                'assets/logo.png',
                height: 80.h,
              ),
              SizedBox(height: 20.h),
              Text(
                'Başarılı',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
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
    /// Burada LayoutBuilder ile ekrana göre “isWideScreen” kontrolü yapacağız:
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWideScreen = constraints.maxWidth >= 600;

        return Scaffold(
          appBar: RedesignedKelibuAppBar(
            logoPath: 'assets/logo.png',
          ),
          backgroundColor: lightBackground,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Consumer<SubscriptionProvider>(
                  builder: (context, subscriptionProvider, _) {
                    bool isSubscribed = subscriptionProvider.isVip;
                    return AnimationLimiter(
                      child: isSubscribed
                          ? VipPage(
                              allSets: products, // Burayı düzelttik
                              isWideScreen: isWideScreen,
                            )
                          : PromotionPage(products, isWideScreen: isWideScreen),
                    );
                  },
                ),
        );
      },
    );
  }

  /// Geniş/dar ekran ayrımını PromotionPage tarafına parametre olarak geçiriyoruz.
  Widget PromotionPage(List<Map<String, dynamic>> allSets,
      {required bool isWideScreen}) {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: AnimationConfiguration.toStaggeredList(
        duration: const Duration(milliseconds: 375),
        childAnimationBuilder: (widget) => SlideAnimation(
          horizontalOffset: 50.0,
          child: FadeInAnimation(child: widget),
        ),
        children: [
          buildTermsAndConditionsText(),
          _buildLottieHeader(),
          const SizedBox(height: 20),
          _buildKelibuProBanner(isWideScreen),
          const SizedBox(height: 20),
          EnhancedProBenefitsCard(
            isButtonHide: true,
            onSubscribe: () {
              // Örnek bir işlem
              _showSuccessDialog('PRO üyelik satın alma işlemi başlatıldı.');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// VIP sayfasını da parametre ekleyerek “gerekirse” farklı görünümler sağlayabilirsiniz.

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

  /// “Kelibu Pro” banner’ını da isWideScreen’e göre ayarlayalım
  Widget _buildKelibuProBanner(bool isWideScreen) {
    // Eğer halen _offerings yükleniyorsa veya hata olduysa:
    if (_offeringsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final offering = _offerings?.current;
    if (offering == null || offering.availablePackages.isEmpty) {
      // Hiç paket gelmemişse fallback
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Şu anda mevcut bir abonelik paketi bulunamadı.',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
      );
    }

    final Package? monthlyPackage = offering.availablePackages
            .where((p) => p.packageType == PackageType.monthly)
            .isNotEmpty
        ? offering.availablePackages
            .firstWhere((p) => p.packageType == PackageType.monthly)
        : null;

    final Package? annualPackage = offering.availablePackages
            .where((p) => p.packageType == PackageType.annual)
            .isNotEmpty
        ? offering.availablePackages
            .firstWhere((p) => p.packageType == PackageType.annual)
        : null;

    final String monthlyPriceString =
        monthlyPackage?.storeProduct.priceString ?? '-';
    final String annualPriceString =
        annualPackage?.storeProduct.priceString ?? '-';

    // Geniş/dar ekranda font boyutlarını ufakça farklı yapabilirsiniz
    double bannerTitleSize = isWideScreen ? 30.sp : 28.sp;
    double priceFontSize = isWideScreen ? 22.sp : 20.sp;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: primaryColor, width: 3),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
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
            /// Üst Bölüm
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/logo.png',
                        height: isWideScreen ? 50.h : 40.h),
                  ],
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => AdvantagesPage()),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 2.w),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Avantajlar',
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isWideScreen ? 12.sp : 12.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            /// Alt Bölüm
            Text(
              'Tüm özelliklere sınırsız erişim!',
              style: GoogleFonts.poppins(
                fontSize: isWideScreen ? 20.sp : 18.sp,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 20.h),

            /// Fiyatlandırma Seçenekleri
            Column(
              children: [
                // Ücretsiz Deneme Seçeneği - YENİ
                _buildFreeTrial(
                  isWideScreen: isWideScreen,
                  fontSize: priceFontSize,
                ),
                SizedBox(height: 8.h),
                if (monthlyPackage != null) ...[
                  _buildPricingOption(
                    label: 'Aylık',
                    priceString: monthlyPriceString,
                    package: monthlyPackage,
                    fontSize: priceFontSize,
                  ),
                  SizedBox(height: 8.h),
                ],
                if (annualPackage != null)
                  _buildPricingOption(
                    label: 'Yıllık',
                    priceString: annualPriceString,
                    package: annualPackage,
                    fontSize: priceFontSize,
                  ),
              ],
            ),
            SizedBox(height: 16.h),

            /// Abone Ol Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showKelibuProPaywall(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: textColor,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  'Hemen abone ol!',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: isWideScreen ? 20.sp : 18.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Ücretsiz deneme widget'ı
  Widget _buildFreeTrial(
      {required bool isWideScreen, required double fontSize}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.amber,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7 Gün Ücretsiz Deneme',
                    style: GoogleFonts.poppins(
                      fontSize: fontSize * 0.8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Hemen başla, istediğin zaman iptal et',
                    style: GoogleFonts.poppins(
                      fontSize: fontSize * 0.5,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 16.sp,
          ),
        ],
      ),
    );
  }

  /// Fiyat satırı (Aylık/Yıllık)
  Widget _buildPricingOption({
    required String label,
    required String priceString,
    required Package package,
    required double fontSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: fontSize - 2,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          priceString,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget buildTermsAndConditionsText() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildClickableText(
            baseText: 'By using the application, you accept the ',
            linkTexts: {
              'Terms of Service (EULA)': () => _handleEulaClick(),
              'Privacy Policy': () => _handlePrivacyClick(),
            },
            conjunction: ' and ',
          ),
          const SizedBox(height: 8),
          _buildClickableText(
            baseText: 'Uygulamayı kullanarak ',
            linkTexts: {
              'Hizmet Şartlarını (EULA)': () => _handleEulaClick(),
              'Gizlilik Politikasını': () => _handlePrivacyClick(),
            },
            conjunction: ' ve ',
            suffixText: ' kabul etmiş sayılırsınız.',
          ),
        ],
      ),
    );
  }

  Widget _buildClickableText({
    required String baseText,
    required Map<String, VoidCallback> linkTexts,
    required String conjunction,
    String suffixText = '',
  }) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.black54,
        ),
        children: [
          TextSpan(text: baseText),
          ...linkTexts.entries.map((entry) {
            bool isLast = entry.key == linkTexts.keys.last;
            return TextSpan(
              children: [
                TextSpan(
                  text: entry.key,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = entry.value,
                ),
                if (!isLast) TextSpan(text: conjunction),
              ],
            );
          }).toList(),
          if (suffixText.isNotEmpty) TextSpan(text: suffixText),
        ],
      ),
    );
  }

  void _handleEulaClick() {
    final String url = Platform.isIOS
        ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
        : Platform.isAndroid
            ? 'https://policies.google.com/terms?hl=tr'
            : '';

    if (url.isNotEmpty) {
      _launchURL(url);
    }
  }

  void _handlePrivacyClick() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
    );
  }
}

class KelibuProPaywall extends StatefulWidget {
  final Offerings? offerings;
  final bool isOfferingsLoading;

  const KelibuProPaywall({
    Key? key,
    required this.offerings,
    required this.isOfferingsLoading,
  }) : super(key: key);

  @override
  State<KelibuProPaywall> createState() => _KelibuProPaywallState();
}

class _KelibuProPaywallState extends State<KelibuProPaywall> {
  bool _isPurchasing = false;
  Package? _monthlyPackage;
  Package? _annualPackage;
  int _selectedPackageIndex = 1; // 0: Monthly, 1: Annual

  // Renk paletini logonuzdaki ana renklere göre güncelledim
  static const primaryBlue = Color(0xFF1E3C87); // Logo mavi
  static const secondaryBlue = Color(0xFF2850B8); // Logo koyu mavi
  static const accentYellow = Color(0xFFFFB800); // Logo sarı ton

  @override
  void initState() {
    super.initState();
    _parsePackages();
  }

  void _parsePackages() {
    if (widget.offerings?.current != null) {
      final offering = widget.offerings!.current!;
      try {
        _monthlyPackage = offering.availablePackages.firstWhere(
          (p) => p.packageType == PackageType.monthly,
        );
      } catch (_) {}
      try {
        _annualPackage = offering.availablePackages.firstWhere(
          (p) => p.packageType == PackageType.annual,
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // 600 piksel üzerini "geniş" ekran (örneğin tablet) varsayıyoruz
          final isWideScreen = constraints.maxWidth >= 600;

          final dialogWidth = mathx
              .min(constraints.maxWidth * 0.95, isWideScreen ? 700 : 600)
              .toDouble();
          final dialogHeight = mathx
              .min(constraints.maxHeight * 0.9, isWideScreen ? 800 : 900)
              .toDouble();

          return Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Üstteki renkli header bölümü
                _buildColoredHeader(context),

                // İçerik
                if (widget.isOfferingsLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          // Geniş ekranda daha geniş padding
                          horizontal: isWideScreen ? 40 : 20,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildHeaderSection(isWideScreen),
                            const SizedBox(height: 32),
                            // Paket seçimleri
                            // Geniş ekranda paketin yan yana gösterilmesi istenirse
                            // horizontal layout yapabilirsiniz.
                            _buildPackageSelection(isWideScreen),
                            const SizedBox(height: 24),
                            _buildSubscribeButton(isWideScreen),
                            const SizedBox(height: 32),
                            _buildFeaturesList(isWideScreen),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Alt bölüm (gizlilik politikası, vb.)
                _buildBottomSection(isWideScreen),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColoredHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
            const Spacer(),
            TextButton(
              onPressed: _restorePurchases,
              child: Text(
                'Geri Yükle',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isWideScreen) {
    return Column(
      children: [
        // Burada ister gerçek logonuzu networkten çekin veya asset içinde tutun
        Image.asset(
          'assets/logo.png',
          height: isWideScreen ? 80 : 60,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kelibu ',
              style: GoogleFonts.poppins(
                fontSize: isWideScreen ? 36 : 32,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accentYellow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Pro',
                style: GoogleFonts.poppins(
                  fontSize: isWideScreen ? 36 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tüm özelliklere erişin, kelimeleri kilitsiz görün!',
          style: GoogleFonts.poppins(
            fontSize: isWideScreen ? 18 : 16,
            color: Colors.black54,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPackageSelection(bool isWideScreen) {
    if (_monthlyPackage == null && _annualPackage == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Bir abonelik paketi bulunamadı. Lütfen daha sonra tekrar deneyin.',
          style: GoogleFonts.poppins(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    final packageCards = <Widget>[];
    if (_annualPackage != null) {
      packageCards.add(
        _buildPackageCard(
          _annualPackage!,
          isSelected: _selectedPackageIndex == 1,
          onTap: () => setState(() => _selectedPackageIndex = 1),
          bestValue: true,
          isWideScreen: isWideScreen,
        ),
      );
    }
    if (_monthlyPackage != null) {
      packageCards.add(
        _buildPackageCard(
          _monthlyPackage!,
          isSelected: _selectedPackageIndex == 0,
          onTap: () => setState(() => _selectedPackageIndex = 0),
          isWideScreen: isWideScreen,
        ),
      );
    }

    // Tablet boyutunda yatay layout, telefon boyutunda dikey layout
    if (isWideScreen && packageCards.length > 1) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: packageCards[0]),
          const SizedBox(width: 16),
          if (packageCards.length > 1) Expanded(child: packageCards[1]),
        ],
      );
    } else {
      // Dar ekran: alt alta
      return Column(
        children: [
          for (int i = 0; i < packageCards.length; i++) ...[
            packageCards[i],
            if (i < packageCards.length - 1) const SizedBox(height: 16),
          ]
        ],
      );
    }
  }

  Widget _buildPackageCard(
    Package package, {
    required bool isSelected,
    required VoidCallback onTap,
    bool bestValue = false,
    required bool isWideScreen,
  }) {
    final packageType =
        package.packageType == PackageType.annual ? 'Yıllık' : 'Aylık';
    final priceString = package.storeProduct.priceString;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.grey.shade300,
            width: 2,
          ),
          color: isSelected ? primaryBlue.withOpacity(0.05) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            if (bestValue)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Önerilen',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isWideScreen ? 14 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                // Seçili olan paket için check ikonu
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? primaryBlue : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Icon(
                            Icons.check_circle,
                            size: 20,
                            color: primaryBlue,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageType,
                        style: GoogleFonts.poppins(
                          fontSize: isWideScreen ? 20 : 18,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceString,
                        style: GoogleFonts.poppins(
                          fontSize: isWideScreen ? 24 : 22,
                          fontWeight: FontWeight.bold,
                          color: secondaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Özellik listesi: Sarı (accent) check ikonu yerine, logodaki sarının biraz koyusunu kullandık.
  /// Metin boyutunu isWideScreen'e göre arttırabilirsiniz.
  Widget _buildFeaturesList(bool isWideScreen) {
    final features = [
      'Pro ile tüm kelime setlerine sınırsız erişim',
      'Canlı yarışmalara katılım ve özel modlara erişim',
      'Kelibu Doodle ile kişiselleştirilmiş çalışma deneyimi',
      'SelfEnglish uygulamasına ücretsiz VIP erişim',
      'Reklamsız premium deneyim ve öncelikli destek'
    ];

    return Column(
      children: features
          .map((feature) => _buildFeatureItem(feature, isWideScreen))
          .toList(),
    );
  }

  Widget _buildFeatureItem(String text, bool isWideScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: accentYellow,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: isWideScreen ? 16 : 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(bool isWideScreen) {
    final selectedPackage =
        _selectedPackageIndex == 1 ? _annualPackage : _monthlyPackage;
    if (selectedPackage == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isPurchasing ? null : () => _purchasePackage(selectedPackage),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          padding: EdgeInsets.symmetric(vertical: isWideScreen ? 20 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          _isPurchasing ? 'İşlem yapılıyor...' : 'Hemen Başla',
          style: GoogleFonts.poppins(
            fontSize: isWideScreen ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(bool isWideScreen) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'İstediğin zaman iptal edebilirsin',
              style: GoogleFonts.poppins(
                color: Colors.black54,
                fontSize: isWideScreen ? 14 : 13,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _launchEULA,
              child: Text(
                'Hizmet Şartları ve Gizlilik Politikası',
                style: GoogleFonts.poppins(
                  color: primaryBlue,
                  decoration: TextDecoration.underline,
                  fontSize: isWideScreen ? 14 : 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Satın alma & restore mantığı aşağıdaki gibi aynen korunabilir ---
  Future<void> _purchasePackage(Package package) async {
    setState(() => _isPurchasing = true);
    _showLoadingDialog();

    try {
      PurchaseResult result = await Purchases.purchasePackage(package);
      CustomerInfo customerInfo = result.customerInfo;
      if (customerInfo.entitlements.active.isNotEmpty) {
        _hideLoadingDialog();
        _showSuccessDialog('Teşekkürler, abonelik başarılı!');
      } else {
        _hideLoadingDialog();
        _showErrorDialog(
            'Satın alma tamamlanamadı. Lütfen daha sonra tekrar deneyin.');
      }
    } on PurchasesErrorCode catch (e) {
      _hideLoadingDialog();

      // Hata türüne göre daha kullanıcı dostu mesajlar
      String errorMessage = 'Satın alma işlemi tamamlanamadı.';

      if (e == PurchasesErrorCode.purchaseCancelledError) {
        errorMessage = 'Satın alma işlemi iptal edildi.';
      } else if (e == PurchasesErrorCode.networkError) {
        errorMessage = 'İnternet bağlantınızı kontrol edip tekrar deneyiniz.';
      } else if (e == PurchasesErrorCode.paymentPendingError) {
        errorMessage =
            'Ödemeniz işleniyor. Kısa süre içinde tekrar kontrol ediniz.';
      } else if (e == PurchasesErrorCode.receiptAlreadyInUseError) {
        errorMessage = 'Bu abonelik zaten başka bir hesapta aktif.';
      }

      _showErrorDialog(errorMessage);

      // Hata günlüğü (sadece geliştirici için)
    } catch (e) {
      _hideLoadingDialog();
      _showErrorDialog(
          'Satın alma sırasında beklenmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyiniz.');

      // Hata günlüğü (sadece geliştirici için)
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    _showLoadingDialog();
    try {
      final restored = await Purchases.restorePurchases();
      if (restored.entitlements.active.isNotEmpty) {
        _hideLoadingDialog();
        _showSuccessDialog('Satın almalarınız geri yüklendi!');
      } else {
        _hideLoadingDialog();
        _showErrorDialog('Aktif bir aboneliğiniz bulunamadı.');
      }
    } catch (e) {
      _hideLoadingDialog();
      _showErrorDialog('Geri yükleme hatası: $e');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
              ),
            ],
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        /// Dialog açılır açılmaz 3 saniyelik gecikme başlatıyoruz:
        Future.delayed(const Duration(seconds: 3), () {
          // Dialog halen açıksa kapat
          if (Navigator.canPop(ctx)) {
            Navigator.pop(ctx);
          }
          // Sonra main.dart'a yönlendir (örnek olarak MyHomePage):
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
            (route) => false,
          );
        });

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png', height: 80),
                const SizedBox(height: 20),
                Text(
                  'Başarılı',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // İsterseniz bir "Tamam" butonu da bırakabilirsiniz,
                // ancak 3 saniye sonra otomatik kapanacağı için şart değil.
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Kullanıcı erken kapatmak isterse
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen()),
                      (route) => false,
                    );
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Tamam',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hata!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Tamam',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchEULA() async {
    final url = Uri.parse(
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
    );
    // URL launcher mantığınızı burada uygulayabilirsiniz
  }
}

class RedesignedKelibuAppBar extends StatelessWidget
    implements PreferredSizeWidget {
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
          border: Border.all(color: Colors.white, width: 2),
          // Çerçeve rengi ve kalınlığı
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
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: lightBackground,
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          EnhancedProBenefitsCard(
            isButtonHide: true,
            onSubscribe: () {
              _showSuccessDialogStatic(
                  context, 'PRO üyelik satın alma işlemi başlatıldı.');
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
        'icon': FontAwesomeIcons.book,
        'text':
            'PhD Akademi Level 1-2-3 ve sağlık 0-1 kitaplarına ücretsiz erişim'
      },
      {
        'icon': FontAwesomeIcons.mobileScreen,
        'text': 'SelfEnglish uygulamasında Beta erişimi'
      },
      {'icon': FontAwesomeIcons.chartLine, 'text': 'Özelleştirilmiş takip'},
      {'icon': FontAwesomeIcons.flag, 'text': 'Sınırsız canlı yarış hakkı!'},
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
                            fontSize: 16.sp, color: Colors.white, height: 1.3),
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 12.h),
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
}

/// "Setler" Sayfası

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
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold),
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
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(
          set['description'],
          style: GoogleFonts.poppins(color: textColor),
        ),
        trailing: Text(
          '₺${set['price']}',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: textColor),
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
        title: Row(
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
                ],
              ),
            ),
          ),
        ],
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
  List<Package> _packages = []; // RevenueCat packages

  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  bool _loading = true;

  Future<void> _initializeRevenueCat() async {
    setState(() => _loading = true);

    try {
      // Mevcut paketleri al
      Offerings offerings = await Purchases.getOfferings();

      if (offerings.current != null) {
        setState(() {
          _packages = offerings.current!.availablePackages;
          _loading = false;
        });

        // Debug için paket bilgilerini yazdır
        for (var package in _packages) {
          print(
              'Paket: ${package.identifier}, Fiyat: ${package.storeProduct.priceString}');
        }
      } else {
        throw Exception('No offerings available');
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorDialog('Ürünler yüklenirken bir hata oluştu', e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeRevenueCat();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<bool> _checkHealth() async {
    bool isDialogShowing = true;

    try {
      final response = await http.get(
        Uri.parse('https://kelibu.net/api/health-check'),
        headers: {
          'X-Custom-Header': 'Hilal',
        },
      ).timeout(Duration(seconds: 2));

      // Only close the health check dialog if it's still showing
      if (isDialogShowing && mounted) {
        Navigator.of(context, rootNavigator: true)
            .pop(); // Sadece diyaloğu kapat
        isDialogShowing = false;
      }

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'ok') {
          return true;
        }
      }

      // Show error dialog without affecting the previous navigation
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Sunucu Hatası'),
          content: Text(
              'Satın alma denemesi başarısız oldu. Lütfen pil tasaruf modunu ve ayarlardan ağ isteklerinizi sınırlayıp sınırlamadığınızı kontrol ediniz.'),
          actions: [
            TextButton(
              child: Text('Tamam'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

      return false;
    } catch (e) {
      // Only close the health check dialog if it's still showing
      if (isDialogShowing && mounted) {
        Navigator.of(context).pop(); // Close only the health check dialog
        isDialogShowing = false;
      }

      // Show error dialog without affecting the previous navigation
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Bağlantı Hatası'),
          content: Text('Health Check sırasında hata oluştu: $e'),
          actions: [
            TextButton(
              child: Text('Tamam'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

      return false;
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        child: Dialog(
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
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.red.shade50,
                  ),
                  child: Text(
                    'Tamam',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Future<bool> isBatterySaverEnabled() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 21) {
        // Android 5.0 (API 21) ve üzeri
        final powerManager = const MethodChannel('power_manager');
        try {
          final bool? isPowerSaveMode =
              await powerManager.invokeMethod('isPowerSaveMode');
          return isPowerSaveMode ?? false;
        } catch (e) {
          return false;
        }
      }
    } else if (Platform.isIOS) {
      try {
        // iOS için özel method channel
        final powerManager = const MethodChannel('power_manager');
        final bool? isLowPowerMode =
            await powerManager.invokeMethod('isLowPowerMode');
        return isLowPowerMode ?? false;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<bool> _checkConnectivity() async {
    try {
      // Pil tasarrufu kontrolü
      if (await isBatterySaverEnabled()) {
        _showErrorDialog(
          'Pil Tasarruf Modu',
          'Pil tasarruf modu aktifken satın alma işlemi desteklenmez. Lütfen modu kapatıp tekrar deneyin.',
        );
        return false;
      }

      // DNS kontrolü (daha hızlı yanıt için)
      final dnsCheck = await InternetAddress.lookup('kelibu.net')
          .timeout(Duration(seconds: 2));
      if (dnsCheck.isEmpty || dnsCheck[0].rawAddress.isEmpty) {
        return false;
      }

      // HTTP isteği ile detaylı kontrol
      final client = http.Client();
      try {
        final response = await client.get(
          Uri.parse('https://kelibu.net'),
          headers: {'Connection': 'keep-alive'},
        ).timeout(Duration(seconds: 5));

        return response.statusCode == 200;
      } finally {
        client.close();
      }
    } on TimeoutException catch (_) {
      _showErrorDialog(
        'Bağlantı Zaman Aşımı',
        'Sunucuya bağlanırken zaman aşımı oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.',
      );
      return false;
    } on SocketException catch (_) {
      _showErrorDialog(
        'Bağlantı Hatası',
        'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
      );
      return false;
    } on HttpException catch (_) {
      _showErrorDialog(
        'Sunucu Hatası',
        'Sunucuya erişilemiyor. Lütfen daha sonra tekrar deneyin.',
      );
      return false;
    } catch (e) {
      _showErrorDialog(
        'Beklenmeyen Hata',
        'Bağlantı kontrolü sırasında beklenmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin.',
      );
      return false;
    }
  }

  void _handlePurchaseError(IAPError? error) {
    String title = 'Satın Alma Hatası';
    String message;

    switch (error?.code) {
      case 'purchase-not-allowed':
        message = 'Bu cihazda satın alma işlemleri devre dışı bırakılmış.';
        break;
      case 'payment-invalid':
        message =
            'Ödeme bilgileriniz geçersiz. Lütfen kontrol edip tekrar deneyin.';
        break;
      case 'payment-cancelled':
        message = 'Ödeme işlemi iptal edildi.';
        break;
      case 'product-not-available':
        message = 'Bu ürün şu anda satın alınamıyor.';
        break;
      case 'network-error':
        message = 'İnternet bağlantınızı kontrol edip tekrar deneyin.';
        break;
      default:
        message = error?.message ??
            'Bilinmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
    }

    _showErrorDialog(title, message);
  }

  Future<void> _showSuccessDialog(
      BuildContext context, String productId) async {
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

  void _showHealthCheckDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
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
                Icon(
                  Icons.health_and_safety,
                  color: Colors.blueAccent,
                  size: 48,
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
                SizedBox(height: 20),
                Text(
                  'Sistem sağlığı kontrol ediliyor...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
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

  Future<void> _purchasePackage(Package package) async {
    try {
      // Satın alma işlemi
      PurchaseResult result = await Purchases.purchasePackage(package);
      CustomerInfo customerInfo = result.customerInfo;

      // Başarılı satın alma kontrolü
      if (customerInfo.entitlements.active.isNotEmpty) {
        // VIP durumunu kaydet
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('VIP', true);

        // Success dialog göster
        _showSuccessDialog(context, package.identifier);
      }
    } on PurchasesErrorCode catch (e) {
      _handlePurchaseError(e as IAPError?);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_packages.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Text(
          'Şu anda satışa sunulan bir abonelik planı bulunamadı.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanım şartları vb.
          buildTermsAndConditionsText(),

          // "Kelibu Pro" başlık
          buildKelibuProHeader(),

          SizedBox(height: 8),

          // Tüm paketleri döngüyle listele
          Column(
            children: _packages.map((package) {
              // Mesela package.packageType == PackageType.annual ise "primary" kabul edebilirsiniz
              bool isPrimary = package.packageType == PackageType.annual;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SubscriptionButton(
                  package: package,
                  onPressed: () => _purchasePackage(package),
                  isPrimary: isPrimary,
                  // isPrimary true ise buton tasarımı özel olabilir
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(delay: 300.ms);
  }

  Widget buildTermsAndConditionsText() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildClickableText(
            baseText: 'By using the application, you accept the ',
            linkTexts: {
              'Terms of Service (EULA)': () => _handleEulaClick(),
              'Privacy Policy': () => _handlePrivacyClick(),
            },
            conjunction: ' and ',
          ),
          const SizedBox(height: 8),
          _buildClickableText(
            baseText: 'Uygulamayı kullanarak ',
            linkTexts: {
              'Hizmet Şartlarını (EULA)': () => _handleEulaClick(),
              'Gizlilik Politikasını': () => _handlePrivacyClick(),
            },
            conjunction: ' ve ',
            suffixText: ' kabul etmiş sayılırsınız.',
          ),
        ],
      ),
    );
  }

  Widget _buildClickableText({
    required String baseText,
    required Map<String, VoidCallback> linkTexts,
    required String conjunction,
    String suffixText = '',
  }) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.black54,
        ),
        children: [
          TextSpan(text: baseText),
          ...linkTexts.entries.map((entry) {
            bool isLast = entry.key == linkTexts.keys.last;
            return TextSpan(
              children: [
                TextSpan(
                  text: entry.key,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = entry.value,
                ),
                if (!isLast) TextSpan(text: conjunction),
              ],
            );
          }).toList(),
          if (suffixText.isNotEmpty) TextSpan(text: suffixText),
        ],
      ),
    );
  }

  void _handleEulaClick() {
    final String url = Platform.isIOS
        ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
        : Platform.isAndroid
            ? 'https://policies.google.com/terms?hl=tr'
            : '';

    if (url.isNotEmpty) {
      _launchURL(url);
    }
  }

  void _handlePrivacyClick() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
    );
  }

  void _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );
    } else {
      throw 'Could not launch $url';
    }
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

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = true;
  List<Package> _packages = [];

  @override
  void initState() {
    super.initState();
    _initializeRevenueCat();
  }

  Future<void> _initializeRevenueCat() async {
    setState(() => _loading = true);
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        setState(() {
          _packages = offerings.current!.availablePackages;
          _loading = false;
        });
      } else {
        throw Exception('No offerings available');
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorDialog('Ürünler yüklenirken bir hata oluştu', e.toString());
    }
  }

  /// -----------------------------------------------------------
  /// Aşağıda paywall ile ilgili temel UI bileşenleri
  /// -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Eğer gerçekten paywall’dan çıkılmasını istemiyorsanız, “geri” tuşunu devre dışı bırakabilirsiniz:
      //   - Bunu WillPopScope ile engelleyerek veya “AppBar”ı tamamen kaldırarak yapabilirsiniz.
      appBar: AppBar(
        title: const Text('Kelibu Pro Paywall'),
        centerTitle: true,
        automaticallyImplyLeading: true,
        // Eğer geri tuşu istemiyorsanız bunu false yapın ve ek bir kapatma ikonu vs koymayın
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildPaywallContent(context),
      ),
    );
  }

  Widget _buildPaywallContent(BuildContext context) {
    // Eğer _packages boş ise kullanıcıya uygun bir uyarı gösterebilirsiniz
    if (_packages.isEmpty) {
      return Center(
        child: Text(
          'Şu anda abonelik paketleri bulunamadı.',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      );
    }

    // Burada tipik bir paywall tasarımı yapıyoruz:
    // 1) Üst kısımda görsel, başlık, açıklama
    // 2) Ortada avantajlar/bültenler
    // 3) Altta paketler
    // 4) En altta “Kullanım Şartları” linkleri
    return SingleChildScrollView(
      child: Column(
        children: [
          // Üst görsel veya Logo
          const SizedBox(height: 20),
          _buildHeaderImage(),
          const SizedBox(height: 20),

          // Başlık
          _buildTitleSection(),

          const SizedBox(height: 16),

          // Avantajlar
          _buildBenefitsSection(),

          const SizedBox(height: 20),

          // Paketlerin listesi
          _buildPackagesSection(),

          const SizedBox(height: 24),

          // Alt kısım (Kullanım şartları, Gizlilik politikası)
          _buildTermsAndConditions(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Image.asset(
      'assets/logo.png',
      width: 100,
      height: 100,
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          'Kelibu Pro’ya Geçin!',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sizin için en uygun paketi seçerek,\nKelibu’nun tüm özelliklerine erişin!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    // Tipik olarak paywall ekranında abonelik avantajlarını maddeler halinde gösterebilirsiniz.
    final benefits = [
      'Reklamsız Deneyim',
      'Tüm Premium Özellikler',
      'Öncelikli Destek',
      'Sık Güncellemeler ve Yeni Özellikler'
    ];
    return Column(
      children: benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                benefit,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPackagesSection() {
    // RevenueCat’ten gelen paketleri listeleyip, kullanıcıyı satın almaya yönlendiriyoruz
    return Column(
      children: _packages.map((pkg) {
        // Dilerseniz priceString kullanarak “12.99 ₺/ay” gibi gösterimler yapabilirsiniz
        String packageTitle = '';
        if (pkg.packageType == PackageType.monthly) {
          packageTitle = 'Aylık';
        } else if (pkg.packageType == PackageType.annual) {
          packageTitle = 'Yıllık';
        } else {
          packageTitle = pkg.packageType.toString();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: SubscriptionButton(
            package: pkg,
            onPressed: () => _purchasePackage(pkg),
            // Paywall’da “özel stil” vermek isterseniz isPrimary gibi bir flag ekleyip
            // butonun rengini vs ayarlayabilirsiniz.
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTermsAndConditions() {
    // Kullanım şartları ve Gizlilik Politikası linkleri
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Uygulamayı kullanarak Hizmet Şartlarımızı (EULA) ve Gizlilik Politikamızı kabul etmiş sayılırsınız.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _handleEulaClick,
                child: const Text('EULA'),
              ),
              const Text('|'),
              TextButton(
                onPressed: _handlePrivacyClick,
                child: const Text('Gizlilik Politikası'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// -----------------------------------------------------------
  /// Aşağıda satın alma, hata dialogları vs. metodlar
  /// (Sizin kodunuza uyacak şekilde kısaltılmış)
  /// -----------------------------------------------------------

  Future<void> _purchasePackage(Package package) async {
    try {
      PurchaseResult result = await Purchases.purchasePackage(package);
      CustomerInfo customerInfo = result.customerInfo;

      if (customerInfo.entitlements.active.isNotEmpty) {
        // VIP durumunu kaydet
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('VIP', true);

        // Başarı diyaloğu göster veya direkt anasayfaya yönlendir
        _showSuccessDialog(context, package.identifier);
      }
    } catch (e) {
      // Hata durumunda bir dialog gösterebilirsiniz
      _showErrorDialog('Satın Alma Hatası', e.toString());
    }
  }

  void _showSuccessDialog(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Başarılı!'),
        content: const Text('Abonelik satın alındı. Teşekkürler!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Anasayfaya yönlendirme
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => MainScreen()),
              );
            },
            child: const Text('Tamam'),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _handleEulaClick() async {
    String url =
        'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
    // iOS linki, Android ise isterseniz Google Terms verebilirsiniz
    // vs...
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  void _handlePrivacyClick() async {
    String url = 'https://example.com/privacy-policy'; // Kendi linkiniz
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }
}

class SubscriptionButton extends StatelessWidget {
  final Package package;
  final VoidCallback onPressed;
  final bool isPrimary;

  const SubscriptionButton({
    Key? key,
    required this.package,
    required this.onPressed,
    this.isPrimary = false,
  }) : super(key: key);

  String _getSubscriptionPeriod() {
    final identifier = package.identifier.toLowerCase();
    return identifier.contains('year') ? 'Yıllık Üyelik' : 'Aylık Üyelik';
  }

  String _getSubscriptionSuffix() {
    final identifier = package.identifier.toLowerCase();
    return identifier.contains('year') ? '/yıl' : '/ay';
  }

  List<String> _getFeatures() {
    final identifier = package.identifier.toLowerCase();
    if (identifier.contains('year')) {
      return [
        'Tüm kelime setlerine sınırsız erişim',
        'Reklamsız deneyim',
        'Özel kelime listeleri',
        'İleri seviye istatistikler',
        'Yıllık planla daha fazla tasarruf'
      ];
    } else {
      return [
        'Tüm kelime setlerine sınırsız erişim',
        'Reklamsız deneyim',
        'Özel kelime listeleri'
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storeProduct = package.storeProduct;

    final Color primaryColor = isPrimary ? Colors.amber.shade700 : Colors.white;
    final Color textColor = isPrimary ? Colors.white : Colors.amber.shade700;
    final Color borderColor =
        isPrimary ? Colors.amber.shade700 : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isPrimary)
            BoxShadow(
              color: Colors.amber.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
        ],
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPrimary)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Chip(
                label: Text(
                  'En Popüler',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.orangeAccent,
              ),
            ),
          Text(
            storeProduct.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getSubscriptionPeriod(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                storeProduct.priceString,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _getSubscriptionSuffix(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
          if (package.storeProduct.introductoryPrice != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${package.storeProduct.introductoryPrice?.priceString} için deneme',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 16),
          ..._getFeatures().map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                foregroundColor:
                    isPrimary ? Colors.amber.shade700 : Colors.white,
                backgroundColor:
                    isPrimary ? Colors.white : Colors.amber.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'ABONE OL',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.amber.shade700 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} // Diğer gerekli paketleri eklemeyi unutmayın, örneğin animate_do veya lottie.

class SuccessDialogContent extends StatefulWidget {
  final String subscriptionType;

  const SuccessDialogContent({Key? key, required this.subscriptionType})
      : super(key: key);

  @override
  _SuccessDialogContentState createState() => _SuccessDialogContentState();
}

class _SuccessDialogContentState extends State<SuccessDialogContent>
    with SingleTickerProviderStateMixin {
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
                    borderRadius: BorderRadius.circular(
                        30), // Buton köşelerini yuvarlatma
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
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '$_secondsRemaining saniye sonra ana sayfaya yönlendirileceksiniz. Sizin için son ayarlamaları yapıyoruz!',
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

class TestimonialCard extends StatelessWidget {
  final Map<String, dynamic> testimonial;

  const TestimonialCard({Key? key, required this.testimonial})
      : super(key: key);

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
              style: GoogleFonts.poppins(
                  fontStyle: FontStyle.italic, color: Colors.grey[700]),
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

  const TestimonialHeader({Key? key, required this.name, required this.rating})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          child: Text(
            name[0],
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
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
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, color: Colors.blue[800]),
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
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideX();
  }
}
