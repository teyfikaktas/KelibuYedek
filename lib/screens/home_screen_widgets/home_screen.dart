import 'dart:io';
import 'dart:ui';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:kelibu/screens/home_screen_widgets/score_display.dart';
import 'package:hive/hive.dart';
import 'package:kelibu/screens/home_screen_widgets/phdakademiinfo.dart';
import 'package:kelibu/screens/market_store.dart';
import 'package:kelibu/screens/point/point.dart';
import 'package:kelibu/screens/settings_screen.dart';
import 'package:kelibu/screens/streak_widget.dart';
import 'package:kelibu/screens/study_screen.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/variables.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Models/announcement.dart';
import '../../Models/category.dart';
import '../../Models/wordDetaik.dart';
import '../../globalDart/urls.dart';
import '../../global_user_id_provider.dart';
import '../../providers/sub_provider.dart';
import '../../providers/user_provider.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/WordListScreen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../shared_preferences/shared_preferences.dart';
import '../../widgets/searchPanel/searchPanel.dart';
import '../WordsSetList.dart';
import '../leader_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';
import '../../providers/darkmodeprovider.dart';
import '../RaceScreen.dart';
import '../connectivywrapper.dart';
import '../privary_policy.dart';
import 'SimpleAnnouncementButton.dart';
import 'soscial_media.dart';
import '../library_star.dart';
import '../loadingIndicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RaceModeButton extends StatelessWidget {
  final bool isVip;
  final VoidCallback onPressed;

  const RaceModeButton({
    Key? key,
    required this.isVip,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isVip ? Colors.blue : Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVip)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'VIP',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          if (isVip) SizedBox(width: 10),
          Text(
            'Yarış Modu',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 10),
          FaIcon(
            isVip ? FontAwesomeIcons.flagCheckered : FontAwesomeIcons.lock,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class RaceScreen extends StatefulWidget {
  final bool isVip;

  const RaceScreen({Key? key, required this.isVip}) : super(key: key);

  @override
  _RaceScreenState createState() => _RaceScreenState();
}

class VIPAdvantagesPanelProvider extends ChangeNotifier {
  bool _shouldShowPanel = false;

  bool get shouldShowPanel => _shouldShowPanel;

  Future<void> checkAndShowPanel(BuildContext context) async {
    final subscriptionProvider =
    Provider.of<SubscriptionProvider>(context, listen: false);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasShownVIPAdvantagesPanel = prefs.getBool('VIP') ?? false;
    final container = riverpod.ProviderScope.containerOf(context);
    var userProvider = Provider.of<UserProvider>(context, listen: false);
    container.read(globalUserIdProvider.notifier).state = userProvider.userId.toInt();
    container.read(globalUsernameProvider.notifier).state = userProvider.username;

    if (subscriptionProvider.isVip && hasShownVIPAdvantagesPanel) {
      await prefs.setBool('VIP', false);

      _shouldShowPanel = true;
      notifyListeners();
    } else {
    }
  }

  void panelShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasShownVIPAdvantagesPanel', true);
    _shouldShowPanel = false;
    notifyListeners();
  }
}

class _RaceScreenState extends State<RaceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showVipDialog() {
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
              colors: [Colors.purple.shade300, Colors.purple.shade900],
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
                'Kelibu Canlı Yarış',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              Text(
                'Beta aşamasında olduğu için şu an sadece pro üyelere açıktır.',
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  padding:
                  EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
                ),
                child: Text(
                  'Anladım',
                  style: GoogleFonts.poppins(
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

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            height: 200
                .h, // Sabit bir yükseklik verin veya ekran yüksekliğine göre ayarlayın
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.pink.shade300, Colors.purple.shade900],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20.sp),
                      child: ScaleTransition(
                        scale: _animation,
                        child: Icon(
                          Icons.videogame_asset,
                          size: 60.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: AutoSizeText(
                        'Canlı Yarış',
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        maxLines: 1,
                        minFontSize: 16,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(8.sp),
                      height: 60.h,
                      width: 60.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.sp),
                        child: Image.asset('assets/logo.png'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Stack(
                  children: [
                    Container(
                      width: 200.w,
                      height: 60.h,
                    ),
                    if (widget.isVip)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            'VIP',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class KelibuProPanel extends StatefulWidget {
  @override
  _KelibuProPanelState createState() => _KelibuProPanelState();
}

class _KelibuProPanelState extends State<KelibuProPanel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        height: 550,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: ProFeaturesList.proFeatures.length +
                    1, // +1 for welcome page
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildWelcomePage();
                  }
                  final proFeature = ProFeaturesList.proFeatures[index - 1];
                  return ProFeatureSlide(
                    icon: proFeature['icon'] as IconData,
                    title: proFeature['title'] as String,
                    description: proFeature['description'] as String,
                    color: proFeature['color'] as Color,
                    details: proFeature['details'] as String,
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < ProFeaturesList.proFeatures.length + 1; i++)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == i
                          ? Colors.orange
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_currentPage < ProFeaturesList.proFeatures.length) {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                elevation: 0,
              ),
              child: Text(
                _currentPage < ProFeaturesList.proFeatures.length
                    ? 'Devam Et'
                    : 'Harika!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fadeIn(delay: GetNumUtils(300).milliseconds).scale(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Kelibu",
            style: GoogleFonts.poppins(
              fontSize: 24.sp, // .sp kullanarak font boyutunu ayarlayın
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "PRO",
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                " Dünyasına",
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h), // .h kullanarak yüksekliği ayarlayın
          Text(
            "Hoş Geldiniz!",
            style: GoogleFonts.poppins(
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 40.w), // .w kullanarak genişliği ayarlayın
            child: Text(
              "Dil öğrenme yolculuğunuzda size özel ayrıcalıklar ve fırsatlar sizi bekliyor.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.2, end: 0),
    );
  }
}

class ProFeatureSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String details;
  final Color color;

  const ProFeatureSlide({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.details,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color),
          SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text(
            details,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}

class KelibuProDialog extends StatelessWidget {
  static const String _shownKey = 'kelibu_pro_shown';

  const KelibuProDialog({Key? key}) : super(key: key);

  static Future<void> showIfNotShown(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_shownKey) ?? false;
    if (!shown) {
      await showDialog(
        context: context,
        builder: (context) => const KelibuProDialog(),
      );
      await prefs.setBool(_shownKey, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KelibuProPanel();
  }
}

class ProFeaturesList {
  static const List<Map<String, dynamic>> proFeatures = [
    {
      'icon': Icons.book,
      'title': 'Sınırsız Setler',
      'description': "Kelibu'nun tüm setlerine sınırsız erişim",
      'color': Colors.blue,
      'details':
      'A1, A2 (temel), B1, B2 (orta) ve C1, C2 (ileri) seviye İngilizce setleri dahil, tüm dil seviyelerine uygun onlarca sete erişim. YÖKDİL, YDT gibi ÖSYM sınavları ile TOEFL, IELTS gibi uluslararası sınavlara özel hazırlık setleri de mevcut!',
    },
    {
      'icon': Icons.rocket_launch,
      'title': 'Erken Erişim',
      'description': 'Tüm yeni özelliklere öncelikli erişim',
      'color': Colors.orange,
      'details':
      'Yeni çıkacak özellikleri, setleri ve güncellemeleri herkesten önce deneyimleyin. Kelibu\'nun geleceğini şekillendirmede söz sahibi olun!',
    },
    {
      'icon': Icons.menu_book,
      'title': 'Ücretsiz E-Kitaplar',
      'description': 'PhD Akademi Level 1-2-3 kitaplarına ücretsiz erişim',
      'color': Colors.purple,
      'details':
      'PhD Akademi\'nin popüler Level 1, 2 ve 3 e-kitaplarına tamamen ücretsiz erişim sağlayın. Bu kitaplar, dil öğrenme yolculuğunuzda size rehberlik edecek.',
    },
    {
      'icon': Icons.phone_android,
      'title': 'SelfEnglish Beta',
      'description': 'SelfEnglish uygulamasına özel beta erişimi',
      'color': Colors.teal,
      'details':
      'Yakında çıkacak SelfEnglish uygulamamızın beta sürümüne erken erişim kazanın. Yapay zeka destekli bu yeni uygulamamızı ilk siz deneyin ve geri bildirimlerinizle şekillenmesine katkıda bulunun.',
    },
    {
      'icon': Icons.analytics,
      'title': 'Gelişmiş Takip',
      'description': 'Özelleştirilmiş ilerleme takibi ve analizler',
      'color': Colors.red,
      'details':
      'Detaylı ilerleme grafikleri, kişiselleştirilmiş öğrenme önerileri ve haftalık performans raporları ile dil öğrenme yolculuğunuzu optimize edin. Güçlü ve zayıf yönlerinizi keşfedin.',
    },
    {
      'icon': Icons.edit_document,
      'title': 'Kelibu Doodle',
      'description': 'PDF düzenleme ve not alma özelliği',
      'color': Colors.indigo,
      'details':
      'Kelibu Doodle ile PDF belgeleriniz üzerinde not alın, işaretlemeler yapın ve düzenlemeler gerçekleştirin. Level 1, 2 ve 3 kitapları üzerinde çalışırken interaktif bir deneyim yaşayın.',
    },
  ];
}

class KelibuProAdvantagesPanel extends StatefulWidget {
  @override
  _KelibuProAdvantagesPanelState createState() =>
      _KelibuProAdvantagesPanelState();
}

class _KelibuProAdvantagesPanelState extends State<KelibuProAdvantagesPanel> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMacOS ? 800 : 400, // Sabit genişlik
        height: isMacOS ? 600 : 500, // Sabit yükseklik
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Önemli
          children: [
            // Başlık ve Kapat butonu satırı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kelibu Pro Avantajları',
                  style: TextStyle(
                    fontSize: isMacOS ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero, // Padding'i sıfırla
                ),
              ],
            ),
            Divider(),
            // İçerik
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: AdvantagesList.advantages.length,
                itemBuilder: (context, index) {
                  final advantage = AdvantagesList.advantages[index];
                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: AdvantageSlide(
                        icon: advantage['icon'] as IconData,
                        title: advantage['title'] as String,
                        description: advantage['description'] as String,
                        color: advantage['color'] as Color,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                AdvantagesList.advantages.length,
                    (index) => Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withOpacity(
                        _pageController.hasClients &&
                            _pageController.page?.round() == index
                            ? 1
                            : 0.3),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isMacOS) ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('İptal'),
                  ),
                  SizedBox(width: 8),
                ],
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Kapat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdvantageSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const AdvantageSlide({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isMacOS ? 60 : 40,
            color: color,
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: isMacOS ? 22 : 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: isMacOS ? 16 : 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class KelibuProAdvantagesDialog extends StatelessWidget {
  static const String _shownKey = 'kelibu_pro_advantages_shown';

  const KelibuProAdvantagesDialog({Key? key}) : super(key: key);

  static Future<void> showIfNotShown(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_shownKey) ?? false;
    if (!shown) {
      await showDialog(
        context: context,
        builder: (context) => const KelibuProAdvantagesDialog(),
      );
      await prefs.setBool(_shownKey, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSubscriptionBadge(context),
              SizedBox(height: 10.h),
              const AdvantagesList(),
              SizedBox(height: 10.h),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  padding:
                  EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
                  elevation: 0,
                ),
                child: Text(
                  'Harika!',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(delay: 1200.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBadge(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Kelibu",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(width: 2.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
        SizedBox(width: 4.w),
        Text(
          "Avantajlarınız!",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }
}

class AdvantagesList extends StatelessWidget {
  static const List<Map<String, dynamic>> advantages = [
    const {
      'icon': FontAwesomeIcons.book,
      'title': 'Setler',
      'description': "Kelibu'nun tüm setlerine erişim",
      'color': Colors.yellow,
    },
    const {
      'icon': FontAwesomeIcons.rocket,
      'title': 'Erken Erişim',
      'description': 'Tüm yeni özelliklere öncelikli erişim',
      'color': Colors.orange,
    },
    const {
      'icon': FontAwesomeIcons.book,
      'title': 'Ücretsiz E-Kitaplar',
      'description': 'PhD Akademi Level 1-2-3 kitaplarına ücretsiz erişim',
      'color': Colors.purple,
    },
    const {
      'icon': FontAwesomeIcons.mobileScreen,
      'title': 'SelfEnglish Beta',
      'description': 'SelfEnglish uygulamasına özel beta erişimi',
      'color': Colors.blue,
    },
    const {
      'icon': FontAwesomeIcons.chartLine,
      'title': 'Gelişmiş Takip',
      'description': 'Özelleştirilmiş ilerleme takibi ve analizler',
      'color': Colors.red,
    },
  ];

  const AdvantagesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: advantages.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final advantage = advantages[index];
        return AdvantageItem(
          icon: advantage['icon'] as IconData,
          title: advantage['title'] as String,
          description: advantage['description'] as String,
          color: advantage['color'] as Color,
          delay: (index * 200).ms,
        );
      },
    );
  }
}

class AdvantageItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Duration delay;

  const AdvantageItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.delay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                      fontSize: 14.sp, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: 0.2, end: 0);
  }
}

class WordOfTheDayService {
  static const String _lastFetchDateKey = 'last_fetch_date';
  static const String _lastWordKey = 'last_word';

  Future<WordOfTheDay> getWordOfTheDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchDate = prefs.getString(_lastFetchDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastFetchDate != today) {
      // Bugün henüz API çağrısı yapılmamış
      final newWord = await fetchWordOfTheDay();
      await _saveWordOfTheDay(newWord, today);
      return newWord;
    } else {
      // Bugün zaten API çağrısı yapılmış, kaydedilmiş kelimeyi kullan
      return _getSavedWordOfTheDay(prefs);
    }
  }

  Future<void> _saveWordOfTheDay(WordOfTheDay word, String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFetchDateKey, date);
    await prefs.setString(
        _lastWordKey,
        json.encode({
          'term': word.term,
          'definition': word.definition,
          'type': word.type,
        }));
  }

  WordOfTheDay _getSavedWordOfTheDay(SharedPreferences prefs) {
    final savedWordJson = prefs.getString(_lastWordKey);
    if (savedWordJson != null) {
      final decodedJson = json.decode(savedWordJson);
      return WordOfTheDay.fromJson(decodedJson);
    }
    throw Exception('No saved word of the day found');
  }
}

class WordOfTheDay {
  final String term;
  final String definition;
  final String? type;

  WordOfTheDay({required this.term, required this.definition, this.type});

  factory WordOfTheDay.fromJson(Map<String, dynamic> json) {
    return WordOfTheDay(
      term: json['terim'],
      definition: json['tanim'],
      type: json['type'],
    );
  }
}

Future<WordOfTheDay> fetchWordOfTheDay() async {
  final uri = Uri.parse('https://kelibu.net/api/daily-word');
  final response = await http.get(uri, headers: {
    "X-Custom-Header": privacyKey.privacyKeyVariable,
  });

  if (response.statusCode == 200) {
    return WordOfTheDay.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load word of the day');
  }
}

class HomeScreen extends StatefulWidget {
  final String? message;

  const HomeScreen({Key? key, this.message}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ValueNotifier<int> pointValueNotifier = ValueNotifier(0);
  String promotionMessage = 'Yükleniyor...';
  WordOfTheDay? _wordOfTheDay;
  List<Package>? _packages;
  bool isExpanded = false;
  final FlutterTts flutterTts = FlutterTts();
  bool _isDarkMode = false;
  OverlayEntry? _overlayEntry;
  int activeUserCount = 0;
  bool _isLoading = true;
  String? fcmErrorMessage;
  bool showFcmError = false;
  ValueNotifier<bool> fcmTokenUpdatedNotifier = ValueNotifier(false);
  bool _hasShownLeaderboardRules = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
  @override
  void initState() {
    super.initState();
    // Dark mode değerini hemen yükle
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _isDarkMode = prefs.getBool("darkMode") ?? false;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      _checkAndShowVipPanel();
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    var userProvider = Provider.of<UserProvider>(context, listen: false);
    pointValueNotifier.value = userProvider.point;

    // ✅ Riverpod pointsProvider'ı da güncelle
    final container = riverpod.ProviderScope.containerOf(context);
    await container.read(pointsProvider.notifier).setPoint(userProvider.point);

    try {
      await _fetchData().catchError((e) {});
      await checkSubscriptionStatus().catchError((e) {});
      if (!mounted) return;
      setState(() => _isLoading = false);
      Future.delayed(Duration(milliseconds: 500), () {
        if (!mounted) return;
        updateFcmToken(context);
        _loadWordOfTheDay();
        _loadDarkModePreference();
        _loadPromotionMessage();
        _fetchActiveUsers();
        _checkWelcomePopup(); // Backend kontrollü popup (Sıralama Kuralları)
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
    if (mounted) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) _showVipBenefitsPanel();
      });
    }
  }  // 3. Opsiyonel olarak, bir FCM token bağlantı durumu gösterici widget ekleyebilirsiniz:
  Widget _buildFcmStatusIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: fcmTokenUpdatedNotifier, // Bu notifier'ı eklemeniz gerekecek
      builder: (context, isUpdated, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isUpdated ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUpdated ? Icons.check_circle : Icons.sync,
                size: 12.sp,
                color: isUpdated ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 4.w),
              Text(
                isUpdated ? 'Bildirimler Aktif' : 'Bildirim Senkronizasyonu',
                style: TextStyle(
                  color: isUpdated ? Colors.green : Colors.orange,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _fetchActiveUsers() async {
    final container = riverpod.ProviderScope.containerOf(context);
    var userProvider = Provider.of<UserProvider>(context, listen: false);
    container.read(globalUserIdProvider.notifier).state = userProvider.userId.toInt();
    container.read(globalUsernameProvider.notifier).state = userProvider.username;
    try {
      final response = await ApiService().getUsersCount();
      setState(() {
        activeUserCount = response['total_users'] ?? 0;
      });
    } catch (e) {
      setState(() {
        activeUserCount = 0;
      });
    }
  }

  Widget _buildActiveUsersIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.grey[850]!.withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.greenAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          TweenAnimationBuilder<int>(
            duration: Duration(seconds: 2),
            tween: IntTween(
              begin: 0,
              end: activeUserCount,
            ),
            builder: (context, value, child) {
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    TextSpan(
                      text: ' Online',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color:
                        _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _checkWelcomePopup() async {
    try {
      bool shouldShow = await ApiService().checkWelcomePopupStatus();
      if (shouldShow && mounted) {
        _showLeaderboardRules(context);
      }
    } catch (e) {
      debugPrint("Popup kontrol hatası: $e");
    }
  }

  void _showLeaderboardRules(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events,
                            color: Colors.amber, size: 32.sp),
                        SizedBox(width: 12.w),
                        Text(
                          'Sıralama Kuralları',
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    // Sezon Promo Banner (Custom & Professional) - ÜSTE TAŞINDI
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Color(0xFF1A1C2E) : Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: _isDarkMode ? Color(0xFF3D446E) : Color(0xFFDDE3FF),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zirve Yarışı Başladı!',
                            style: GoogleFonts.poppins(
                              color: _isDarkMode ? Colors.white : Color(0xFF1E265C),
                              fontWeight: FontWeight.w900,
                              fontSize: 20.sp,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Color(0xFF4F5EDF),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              '2. SEZON',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.sp,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: 18.h),
                          Text(
                            'Yeni sezonda puanlar sıfırlandı! Her sezonun sonunda ilk 3\'e giren kullanıcılarımıza sürpriz hediyeler verilecektir. Çalışmaya başla, ödülleri kap.',
                            style: GoogleFonts.poppins(
                              color: _isDarkMode ? Colors.white70 : Color(0xFF4A5187),
                              fontSize: 13.5.sp,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 16.sp, color: Color(0xFF4F5EDF)),
                              SizedBox(width: 8.w),
                              Text(
                                'Sezon Bitiş Tarihi: 30 Eylül',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF4F5EDF),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _buildRuleItem(
                      icon: Icons.bolt,
                      title: 'Puan Kazanma',
                      description:
                          'Çözdüğünüz her test ve öğrendiğiniz her kelime size puan kazandırır.',
                      color: Colors.blue,
                    ),
                    _buildRuleItem(
                      icon: Icons.local_fire_department,
                      title: 'Seri (Streak)',
                      description:
                          'Her gün düzenli çalışarak serinizi koruyun. Yüksek seriler profilinizde parlar!',
                      color: Colors.orange,
                    ),
                    _buildRuleItem(
                      icon: Icons.timer,
                      title: 'Zaman Aralıkları',
                      description:
                          'Günlük, haftalık ve aylık tablolarda en iyiler arasına girerek ödüller kazanın.',
                      color: Colors.green,
                    ),
                    SizedBox(height: 32.h),
                    ElevatedButton(
                      onPressed: () async {
                        await ApiService().markWelcomePopupSeen();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Anladım, Başlayalım!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: _isDarkMode ? Colors.white60 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showVipBenefitsPanel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isVip =
        Provider.of<SubscriptionProvider>(context, listen: false).isVip;
    bool hasShownVipPanel = prefs.getBool('hasShownVipPanel') ?? false;

    if ((!isVip) && (!hasShownVipPanel)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          child: EnhancedProBenefitsCard(
            onSubscribe: () {
              prefs.setBool('hasShownVipPanel', true);
            },
          ),
        ),
      );
    }
  }

  Widget _buildVipButton({required bool isDarkMode}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          splashColor: Colors.orange.withOpacity(0.1),
          highlightColor: Colors.orange.withOpacity(0.05),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MarketPage()),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                  Colors.grey[900]!,
                  Colors.grey[850]!,
                ]
                    : [
                  Colors.white,
                  Color(0xFFFFFBF0),
                ],
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Kelibu",
                        style: GoogleFonts.poppins(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          "PRO",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.crown,
                        color: Colors.orange[400],
                        size: 14.sp,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        "Avantajlarım",
                        style: GoogleFonts.poppins(
                          color:
                          isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      FaIcon(
                        FontAwesomeIcons.chevronRight,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        size: 12.sp,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> checkSubscriptionStatus() async {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    await provider.fetchSubscriptionStatus();
  }

  Future<void> _loadPromotionMessage() async {
    try {
      String message = await ApiService().fetchPromotionMessage();
      setState(() => promotionMessage = message);
    } catch (e) {
      setState(() => promotionMessage = 'Mesaj yüklenemedi');
    }
  }

  Future<void> _loadWordOfTheDay() async {
    WordOfTheDay? cachedWord = await WordOfTheDayCache.getCachedWordOfTheDay();
    if (cachedWord != null) {
      setState(() {
        _wordOfTheDay = cachedWord;
      });
    } else {
      try {
        _wordOfTheDay = await fetchWordOfTheDay();
        await WordOfTheDayCache.cacheWordOfTheDay(_wordOfTheDay!);
        setState(() {});
      } catch (error) {
        _wordOfTheDay = await _loadWordFromPrefs();
        setState(() {});
      }
    }
  }

  Future<WordOfTheDay?> _loadWordFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final term = prefs.getString('word_term');
    final definition = prefs.getString('word_definition');
    final type = prefs.getString('word_type');
    if (term != null && definition != null) {
      return WordOfTheDay(term: term, definition: definition, type: type);
    }
    return null;
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Future<void> _fetchData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;

    // Fetch starred words
    ApiService().fetchStarWordsAllSystem(currentUserId);

    try {
      Map<String, dynamic> userData =
      await ApiService().fetchUserPoint();
      userProvider.addPoint(userData['point']);
      userProvider.updateUserAvatarUrl(userData['avatar']);
      userProvider.updateRankings(
        streakCount:
        userData['streakCount'] is int ? userData['streakCount'] as int : 0,
        dailyRank:
        userData['dailyRank'] is int ? userData['dailyRank'] as int : 0,
        weeklyRank: userData['weeklyRank'],
        monthlyRank: userData['monthlyRank'],
        allTimeRank: userData['allTimeRank'],
      );
      pointValueNotifier.value = userProvider.point;
    } catch (error) {
    }

    await fetchPackages(currentUserId);
  }
  Future<void> updateFcmToken(BuildContext context) async {
    try {
      // Hata panelini temizle
      setState(() {
        fcmErrorMessage = null;
        showFcmError = false;
      });

      // iOS için APNS token kontrolü ve gecikme
      if (Platform.isIOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          // APNS token yoksa biraz bekle
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        }
      }

      // FCM token'ı alma
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        // Token alınamadı, hata panelini göster
        setState(() {
          showFcmError = true;
          fcmTokenUpdatedNotifier.value = false;
        });

        // Yine de SnackBar gösterelim
        Future.microtask(() {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('FCM token alınamadı: Token null'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        });
        return;
      }



      // Kullanıcı ID'sini alma
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      int userId = userProvider.userId;

      // ApiService ile token'ı gönderme
      await ApiService().updateFcmToken(userId, token);

      // Token başarıyla güncellendi
      setState(() {
        fcmTokenUpdatedNotifier.value = true;
        showFcmError = false;
      });

      // Başarılı durumunu göster
    } catch (e) {
      // Hata durumunda hata panelini göster
      setState(() {
        showFcmError = true;
        fcmTokenUpdatedNotifier.value = false;
      });

    }
  }
  Future<void> fetchPackages(int userId) async {
    try {
      List<Package> packages = await ApiService().fetchCategories(userId);
      setState(() {
        _packages = packages;
      });
    } catch (error) {
    }
  }
  Widget _buildFcmErrorPanel(String errorMessage) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            showFcmError = false; // Hata panelini kapat
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 28.sp,
                      ),
                      SizedBox(width: 12.w),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      errorMessage,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: _isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // Hata mesajını kopyala
                          Clipboard.setData(ClipboardData(text: errorMessage));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata kopyalandı'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(Icons.copy, size: 18.sp),
                        label: Text(
                          "Kopyala",
                          style: GoogleFonts.poppins(fontSize: 14.sp),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Hatayı paylaş
                          Share.share(
                            'FCM Token Hatası: $errorMessage',
                            subject: 'Kelibu FCM Token Hatası',
                          );
                        },
                        icon: Icon(Icons.share, size: 18.sp),
                        label: Text(
                          "Paylaş",
                          style: GoogleFonts.poppins(fontSize: 14.sp),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            showFcmError = false; // Hata panelini kapat
                          });
                        },
                        icon: Icon(Icons.close, size: 18.sp),
                        label: Text(
                          "Kapat",
                          style: GoogleFonts.poppins(fontSize: 14.sp),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> savePackagesToPrefs(List<Package> packages) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData =
    json.encode(packages.map((package) => package.toJson()).toList());
    await prefs.setString('packages', encodedData);
  }

  Future<bool> checkIfBuyed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isbuyed') ?? false;
  }

  void speak(String text) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _getBackgroundColor(),
          body: Stack(
            children: [
              _buildMainContent(userProvider),
              if (widget.message != null) KelibuProPanel()
            ],
          ),
        );
      },
    );
  }

  void _navigateToWordSetsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WordSetsPage(),
      ),
    );
  }

// Mesaj panelini oluşturan yeni bir metod
  Widget _buildMessagePanel() {
    return Positioned(
      top: 20, // Üstten 20 piksel aşağıda
      left: 20, // Soldan 20 piksel içeride
      right: 20, // Sağdan 20 piksel içeride
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'message',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _checkAndShowVipPanel() async {
    final vipProvider =
    Provider.of<VIPAdvantagesPanelProvider>(context, listen: false);
    await vipProvider.checkAndShowPanel(context);
    if (vipProvider.shouldShowPanel) {
      // VIP panelini göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => KelibuProPanel(),
      ).then((_) {
        // Panel gösterildikten sonra durumu güncelle
        vipProvider.panelShown();
      });
    }
  }

  Widget _buildMainContent(UserProvider userProvider) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        bool isVip = subscriptionProvider.isVip;

        return ListView(
          shrinkWrap: true,
          children: [
            _buildUserInfoSection(userProvider),

            // VIP değilse VIP butonunu göster, VIP ise boş container
            !isVip
                ? _buildKelibuProButton(isDarkMode: _isDarkMode)
                : _buildVipButton(isDarkMode: _isDarkMode),

            _buildLearningPanel(),
            _buildStreakWidget(userProvider),
            _buildSocialMediaInfo(),
            PhdAkademiInfo(isDarkMode: _isDarkMode),
          ],
        );
      },
    );
  }

  Widget _buildKelibuProButton({required bool isDarkMode}) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: 10.w, vertical: 4.h), // Kenarları küçülttüm
      decoration: BoxDecoration(
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10.r), // Border radius'u küçülttüm
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.r),
          splashColor: Colors.amber.withOpacity(0.1),
          highlightColor: Colors.amber.withOpacity(0.05),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MarketPage()),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.amber.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 3, // Gölgeyi azalttım
                  offset: Offset(0, 1), // Gölge offset'ini küçülttüm
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                  Colors.grey[900]!,
                  Colors.grey[850]!,
                ]
                    : [
                  Colors.white,
                  Color(0xFFFFFBF0), // Sarımsı arka plan
                ],
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 14.w, vertical: 10.h), // Padding'i küçülttüm
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Kelibu",
                            style: GoogleFonts.poppins(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp, // Font boyutunu küçülttüm
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5.w,
                                vertical:
                                1.h), // PRO badge padding'ini küçülttüm
                            decoration: BoxDecoration(
                              color: Colors.amber[600],
                              borderRadius: BorderRadius.circular(5.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  spreadRadius: 0,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              "PRO",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.sp, // Font boyutunu küçülttüm
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      FaIcon(
                        FontAwesomeIcons.crown,
                        color: Colors.amber[400],
                        size: 14.sp, // İkon boyutunu küçülttüm
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h), // Boşluğu küçülttüm
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Hemen Kelibu PRO'lu ol",
                        style: GoogleFonts.poppins(
                          color:
                          isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          fontSize: 12.sp, // Font boyutunu küçülttüm
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      FaIcon(
                        FontAwesomeIcons.chevronRight,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        size: 11.sp, // İkon boyutunu küçülttüm
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(UserProvider userProvider) {
    return Container(
      margin: EdgeInsets.all(8.sp),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getShadowColor(),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAvatarWithName(userProvider),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ScoreDisplay(),
                  SizedBox(height: 4.h),
                ],
              ),
            ],
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAvatarWithName(UserProvider userProvider) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        bool isSubscribed = subscriptionProvider.isVip;
        return Row(
          children: [
            GestureDetector(
              onTap: () => _showEnlargedAvatar(userProvider.avatar),
              child: Hero(
                tag: 'avatar',
                child: TweenAnimationBuilder(
                  duration: Duration(seconds: 1),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          width: 54.w,
                          height: 54.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSubscribed
                                  ? (_isDarkMode
                                  ? Colors.amberAccent
                                  : Colors.amber)
                                  : (_isDarkMode
                                  ? Colors.greenAccent
                                  : Colors.green),
                              width: isSubscribed ? 3.0 : 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isDarkMode
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: 'https://kelibu.net/storage/${userProvider.avatar}',
                              fit: BoxFit.cover,
                              maxHeightDiskCache: 200,
                              memCacheWidth: 200,
                              filterQuality: FilterQuality.low,
                              placeholderFadeInDuration: Duration(milliseconds: 200),
                              fadeInDuration: Duration(milliseconds: 300),
                              placeholder: (context, url) => ShimmerLoading(),
                              errorWidget: (context, url, error) => FaIcon(
                                FontAwesomeIcons.userCircle,
                                size: 27.sp,
                                color: _isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),
                Text(
                  userProvider.username,
                  style: GoogleFonts.raleway(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 5.h),
                if (isSubscribed)
                  _buildSubscriptionBadge()
                else
                  _buildVIPanel(),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionBadge() {
    return Row(
      children: [
        Text(
          "Kelibu",
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(width: 2.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
        SizedBox(width: 4.w),
        GestureDetector(
          onTap: () => _showProAdvantagesDialog(),
          child: Icon(
            FontAwesomeIcons.crown,
            color: Colors.orange,
            size: 16.sp,
          ),
        ),
      ],
    );
  }

  void _showProAdvantagesDialog() {
    showDialog(
      context: context,
      builder: (context) => KelibuProAdvantagesDialog(),
    );
  }

  Widget _buildVIPanel() {
    return Container();
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            icon: Icons.notifications_outlined,
            label: 'Bildirimler',
            color: Colors.red[600]!,
            onPressed: _showAnnouncements,
          ),
          _buildActionButton(
            icon: Icons.search_outlined,
            label: 'Ara',
            color: Colors.teal[600]!,
            onPressed: _openSearchDialog,
          ),
          _buildActionButton(
            icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            label: _isDarkMode ? 'Aydınlık' : 'Karanlık',
            color: _isDarkMode ? Colors.orange[600]! : Colors.indigo[600]!,
            onPressed: _toggleDarkMode,
          ),
          _buildActionButton(
            icon: Icons.play_circle_outline,
            label: 'Video',
            color: Colors.green[600]!,
            onPressed: _openVideoPlayer,
          ),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Paylaş',
            color: Colors.purple[600]!,
            onPressed: _shareApp,
          ),
          _buildActionButton(
            icon: Icons.settings_outlined,
            label: 'Ayarlar',
            color: Colors.blue[600]!,
            onPressed: _openSettings,
          ),
        ],
      ),
    );
  }

  List<Announcement> announcements = [];

  // Tarih formatlama metodu
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

// HomeScreen içinde _buildActionButton metodunu güncelle:
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool hasNotification = false,
  }) {
    // Bildirim veya Duyuru butonu ise özel okundu/okunmadı mantığı olan widget'ı kullan
    if (icon == Icons.notifications_outlined || icon == Icons.campaign_outlined) {
      return Flexible(
        child: SimpleAnnouncementButton(
          onTap: onPressed,
          isDarkMode: _isDarkMode,
          icon: icon,
          color: color,
        ),
      );
    }

    // Diğer butonlar için mevcut implementasyon
    return Flexible(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(2.w),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }


// HTML temizleme yardımcı fonksiyonu


  void _showAnnouncements() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Sürükle çubuğu
              Container(
                margin: EdgeInsets.symmetric(vertical: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Başlık
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.red[700]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 24.sp,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Bildirimler',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20.sp,
                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: _isDarkMode ? Colors.grey[800] : Colors.grey[200]),
              // Duyuru Listesi
              Expanded(
                child: FutureBuilder<List<Announcement>>(
                  future: ApiService().getNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Bildirimler yüklenirken bir hata oluştu',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }

                    final announcements = snapshot.data ?? [];

                    if (announcements.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: Colors.red[700]!.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 40.sp,
                              color: Colors.red[700],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Henüz bildirim bulunmuyor',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: _isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Yeni bildirimler geldiğinde burada görünecek',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final announcement = announcements[index];
                        return GestureDetector(
                          onTap: () => _showAnnouncementDetail(announcement),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              color: _isDarkMode ? Colors.grey[850] : Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Color(
                                  int.parse(
                                    announcement.category.color.replaceAll('#', '0xFF'),
                                  ),
                                ).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 6.w,
                                          runSpacing: 4.h,
                                          children: [
                                            // Metadata Tagleri (Yeni)
                                            if (announcement.metadata != null && announcement.metadata!.isNotEmpty)
                                              ..._buildMetadataTags(announcement.metadata!),
                                            
                                            // Varsayılan Kategori (Eğer metadata yoksa veya ek bilgi olarak)
                                            if (announcement.metadata == null || !announcement.metadata!.contains('category:'))
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color: Color(
                                                    int.parse(
                                                      announcement.category.color.replaceAll('#', '0xFF'),
                                                    ),
                                                  ).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6.r),
                                                ),
                                                child: Text(
                                                  announcement.category.name,
                                                  style: GoogleFonts.poppins(
                                                    color: Color(
                                                      int.parse(
                                                        announcement.category.color.replaceAll('#', '0xFF'),
                                                      ),
                                                    ),
                                                    fontSize: 10.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            
                                            if (announcement.isImportant)
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[50],
                                                  borderRadius: BorderRadius.circular(6.r),
                                                ),
                                                child: Text(
                                                  'Önemli',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.red,
                                                    fontSize: 10.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),

                                            if (announcement.links.isNotEmpty)
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius: BorderRadius.circular(6.r),
                                                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.link, size: 12.sp, color: Colors.blue[700]),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      'LİNK VAR',
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.blue[700],
                                                        fontSize: 9.sp,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        formatDate(announcement.publishDate),
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              announcement.title,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                                color: _isDarkMode ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            Container(
                                              constraints: BoxConstraints(maxHeight: 80.h),
                                              child: Html(
                                                data: announcement.content,
                                                style: {
                                                  "body": Style(
                                                    fontSize: FontSize(14.sp),
                                                    color: Colors.grey,
                                                    fontFamily: GoogleFonts.poppins().fontFamily,
                                                  ),
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16.sp,
                                        color: _isDarkMode ? Colors.white54 : Colors.black45,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showAnnouncementDetail(Announcement announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(announcement.category.color.replaceAll('#', '0xFF')),
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        announcement.category.name,
                        style: GoogleFonts.poppins(
                          color: Color(
                            int.parse(announcement.category.color.replaceAll('#', '0xFF')),
                          ),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (announcement.isImportant)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          margin: EdgeInsets.only(bottom: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'Önemli',
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Text(
                        announcement.title,
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: _isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        formatDate(announcement.publishDate),
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // HTML içeriğini render eden widget:
                      Html(
                        data: announcement.content,
                        style: {
                          "body": Style(
                            fontSize: FontSize(14.sp),
                            color: _isDarkMode ? Colors.white70 : Colors.black87,
                            fontFamily: GoogleFonts.poppins().fontFamily,
                          ),
                        },
                      ),
                      if (announcement.links.isNotEmpty) ...[
                        SizedBox(height: 24.h),
                        Divider(color: _isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Icon(Icons.link, size: 20.sp, color: Colors.blue),
                            SizedBox(width: 8.w),
                            Text(
                              'İlgili Bağlantılar',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        ...announcement.links.map((link) {
                          final uri = Uri.parse(link);
                          final displayUrl = uri.host.isNotEmpty ? uri.host : link;
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode ? Colors.blue.withOpacity(0.05) : Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.language,
                                          color: Colors.blue,
                                          size: 18.sp,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayUrl,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[800],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Linke git',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.blue.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.blue.withOpacity(0.5),
                                        size: 14.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String formatDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();
    return '$day.$month.$year';
  }

  List<Widget> _buildMetadataTags(String metadata) {
    List<Widget> tags = [];
    final parts = metadata.split(';');

    for (var part in parts) {
      if (part.startsWith('category:')) {
        final categories = part.replaceFirst('category:', '').split('|');
        for (var cat in categories) {
          Color color = Colors.green; // Varsayılan yeşil
          String label = cat;

          if (cat == 'events') {
            color = Colors.blueAccent;
            label = 'Etkinlik';
          } else if (cat == 'general') {
            label = 'Genel';
          } else if (cat == 'announcements') {
            label = 'Duyuru';
          }

          tags.add(_buildTag(label, color));
        }
      } else if (part.startsWith('importance:')) {
        final imp = part.replaceFirst('importance:', '').toLowerCase();
        Color color = Colors.orange;
        String label = 'Normal';

        if (imp == 'high') {
          color = Colors.red;
          label = 'Yüksek Öncelik';
        } else if (imp == 'low') {
          color = Colors.grey;
          label = 'Düşük Öncelik';
        }

        tags.add(_buildTag(label, color));
      }
    }
    return tags;
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => SettingsPage()));
  }

  void _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await prefs.setBool('darkMode', _isDarkMode);
  }

  void _openVideoPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              VideoPlayerScreen(videoUrl: AppUrls.homescreen)),
    );
  }

  void _shareApp() {
    final String message = """
🚀 Kelibu ile kelime haznenizi genişletin! 🧠💪

Her gün yeni kelimeler öğrenin, eğlenceli quizler çözün ve dil becerilerinizi geliştirin. 📚✨

📱 Kelibu'yu hemen indirin ve kelime dünyasına dalın! 🌊

🍎 iOS kullanıcıları için: 
   Elmanızı bilgiyle parlatın! 🍏✨
   https://apps.apple.com/tr/app/kelibu/id6484268631

🤖 Android severler için:
   Robotunuzu kelimelerle programlayın! 🦾📚
   https://play.google.com/store/apps/details?id=com.phdakademi.kelibu

💻 Web'de takılanlar için:
   Tarayıcınızı bir kelime makinesine dönüştürün! 🕸️📖
   Kelibu.net

Hadi, birlikte öğrenelim ve büyüyelim! 🌟🎉
Kelime öğrenmenin tadını Kelibu ile çıkarın! 🍭📗
    """;

    Share.share(message,
        subject: 'Kelibu - Eğlenceli Kelime Öğrenme Macerası!');
  }

  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SearchDialog(isDarkMode: _isDarkMode);
      },
    );
  }

  Widget _buildStreakWidget(UserProvider userProvider) {
    return StreakWidget(
      isDarkMode: _isDarkMode,
      streakCount: userProvider.streakCount,
      dailyRank: userProvider.dailyRank,
      monthlyRank: userProvider.monthlyRank,
      weeklyRank: userProvider.weeklyRank,
      allTimeRank: userProvider.allTimeRank,
    );
  }

  Widget _buildLearningPanel() {
    return LearningPanel(
      isDarkMode: _isDarkMode,
      onWordSetsTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => WordSetsPage()),
        );
      },
      onWordOfDayTap: _showWordOfDayDialog,
      onDictionaryTap: _openSearchDialog,
    );
  }

  Widget _buildSocialMediaInfo() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: _getSocialMediaInfoColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getShadowColor(),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SocialPanel(isDarkMode: _isDarkMode),
    );
  }

  Widget _buildExpandedWordSets() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDraggableHeader(),
          _buildWordSetsHeader(),
          Expanded(
            child: _buildWordSetsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableHeader() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 10) {
          setState(() {
            isExpanded = false;
          });
        }
      },
      child: Container(
        height: 40,
        child: Center(
          child: Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordSetsHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF1F1F1F) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWordSetsTitle(),
              _buildCloseButton(),
            ],
          ),
          SizedBox(height: 10),
          _buildWordSetsSubtitle(),
        ],
      ),
    );
  }

  Widget _buildWordSetsTitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Color(0xFF58CC02),
            size: 28,
          ),
          SizedBox(width: 10),
          Text(
            "Kelime Setleriniz",
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Color(0xFF3C3C3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordSetsSubtitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(
        "Öğrenmeye hazır mısınız? Hadi başlayalım!",
        style: GoogleFonts.nunito(
          fontSize: 16,
          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300),
      builder: (context, double value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: child,
          ),
        );
      },
      child: IconButton(
        icon: Icon(
          Icons.close_rounded,
          color: _isDarkMode ? Colors.white70 : Color(0xFF58CC02),
          size: 28,
        ),
        onPressed: () {
          setState(() {
            isExpanded = false;
          });
        },
      ),
    );
  }

  Widget _buildWordSetsList() {
    if (_packages == null) {
      return Center(child: LogoLoadingIndicator());
    } else if (_packages!.isEmpty) {
      return _buildEmptyState();
    } else {
      return ListView.builder(
        itemCount: _packages!.length,
        itemBuilder: (context, index) {
          return _buildWordSetItem(_packages![index], index);
        },
      );
    }
  }

  Widget _buildWordSetItem(Package package, int index) {
    final List<Color> colors = [
      Color(0xFF58CC02),
      Color(0xFF1CB0F6),
      Color(0xFFFFC800),
      Color(0xFFFF9600),
      Color(0xFFFF4B4B),
    ];
    final color = colors[index % colors.length];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _onListItemTap(package.classroom?.id ?? 0,
            package.classroom?.title ?? 'Varsayılan Başlık'),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.school,
                  size: 100,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.classroom?.title ?? 'Varsayılan Başlık',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: 0.7, // Update with actual progress
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: 80,
            color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            "Henüz kelime setiniz yok",
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Yeni setler ekleyerek öğrenmeye başlayın!",
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: _isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _onListItemTap(int categoryId, String categoryName) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => WordListScreen(
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    ));
  }

  void _showEnlargedAvatar(String avatarUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Hero(
              tag: 'avatar',
              child: Image.network(
                'https://kelibu.net/storage/$avatarUrl',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  void _expandWordSets() {
    setState(() {
      isExpanded = true;
    });
  }

  void _showWordOfDayDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WordOfTheDayDialog(
          isDarkMode: _isDarkMode,
          onSpeak: speak,
        );
      },
    );
  }

  Color _getBackgroundColor() {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    return colors["background"] ?? Colors.white;
  }

  Color _getSocialMediaInfoColor() {
    return _isDarkMode ? Colors.grey[850]! : Colors.white;
  }

  Color _getShadowColor() {
    return _isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.3);
  }
}

class PackageListWidget extends StatelessWidget {
  final Future<List<Package>> packagesFuture;

  const PackageListWidget({Key? key, required this.packagesFuture})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Package>>(
      future: packagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: LogoLoadingIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}"));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildPackageItem(context, snapshot.data![index]);
            },
          );
        } else {
          return Center(child: Text("Kategori verisi yok"));
        }
      },
    );
  }

  Widget _buildPackageItem(BuildContext context, Package package) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        leading: Icon(Icons.book, color: Colors.white, size: 30.sp),
        title: Text(
          package.classroom?.title ?? 'Varsayılan Başlık',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: () => _onListItemTap(context, package.classroom?.id ?? 0,
            package.classroom?.title ?? 'Varsayılan Başlık'),
      ),
    );
  }

  void _onListItemTap(
      BuildContext context, int categoryId, String categoryName) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => WordListScreen(
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    ));
  }
}

class WordCard {
  final int id;
  final String? type;
  final String terim;
  final String tanim;

  WordCard({
    required this.id,
    this.type,
    required this.terim,
    required this.tanim,
  });

  factory WordCard.fromJson(Map<String, dynamic> json) {
    return WordCard(
      id: json['id'],
      type: json['type'],
      terim: json['terim'],
      tanim: json['tanim'],
    );
  }
}

class SearchPanel extends StatelessWidget {
  final bool isDarkMode;

  const SearchPanel({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SearchDialog(isDarkMode: isDarkMode);
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF3A3A3C) : Color(0xFF58CC02),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search,
                color: isDarkMode ? Colors.grey[300] : Colors.white,
                size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              "Sözlük",
              style: GoogleFonts.nunito(
                color: isDarkMode ? Colors.grey[300] : Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class WordOfTheDayCache {
  static const String _keyWord = 'word_of_the_day';
  static const String _keyDefinition = 'definition_of_the_day';
  static const String _keyType = 'type_of_the_day';
  static const String _keyImage = 'image_of_the_day';
  static const String _keyLastFetchDate = 'last_fetch_date';

  static Future<void> cacheWordOfTheDay(WordOfTheDay word) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWord, word.term);
    await prefs.setString(_keyDefinition, word.definition);
    if (word.type != null) {
      await prefs.setString(_keyType, word.type!);
    }
    await prefs.setString(_keyLastFetchDate, DateTime.now().toIso8601String());
  }

  static Future<WordOfTheDay?> getCachedWordOfTheDay() async {
    final prefs = await SharedPreferences.getInstance();
    final term = prefs.getString(_keyWord);
    final definition = prefs.getString(_keyDefinition);
    final type = prefs.getString(_keyType);
    final lastFetchDate = prefs.getString(_keyLastFetchDate);

    if (term != null && definition != null && lastFetchDate != null) {
      final fetchDate = DateTime.parse(lastFetchDate);
      if (DateTime.now().difference(fetchDate).inDays < 1) {
        return WordOfTheDay(term: term, definition: definition, type: type);
      }
    }
    return null;
  }

  static Future<void> cacheImage(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyImage, imageUrl);
  }

  static Future<String?> getCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyImage);
  }
}

class WordOfTheDayDialog extends StatelessWidget {
  final bool isDarkMode;
  final Function(String) onSpeak;

  const WordOfTheDayDialog({
    Key? key,
    required this.isDarkMode,
    required this.onSpeak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      child: ContentBox(isDarkMode: isDarkMode, onSpeak: onSpeak),
    );
  }
}

class ContentBox extends StatelessWidget {
  final bool isDarkMode;
  final Function(String) onSpeak;

  const ContentBox({
    Key? key,
    required this.isDarkMode,
    required this.onSpeak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
              left: 20.w, top: 65.h + 20.h, right: 20.w, bottom: 20.h),
          margin: EdgeInsets.only(top: 45.h),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: FutureBuilder<WordOfTheDay>(
            future: fetchWordOfTheDay(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: LogoLoadingIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Hata oluştu'));
              } else if (snapshot.hasData) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      snapshot.data!.term,
                      style: GoogleFonts.nunito(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Text(
                      snapshot.data!.definition,
                      style: GoogleFonts.nunito(
                        fontSize: 16.sp,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => onSpeak(snapshot.data!.term),
                          child: Icon(Icons.volume_up, color: Colors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(15),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _navigateToWordDetail(context, snapshot.data!),
                          child: Text(
                            "Detaylı Keşfet!",
                            style: GoogleFonts.nunito(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 10.h),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Center(child: Text('Veri bulunamadı'));
              }
            },
          ),
        ),
        Positioned(
          left: 20.w,
          right: 20.w,
          child: CircleAvatar(
            backgroundColor: Colors.green,
            radius: 45.h,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(45.h)),
              child: Icon(Icons.lightbulb, color: Colors.white, size: 50.sp),
            ),
          ),
        ),
        Positioned(
          right: -10.w,
          top: -10.h,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(4.sp),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: isDarkMode ? Colors.white : Colors.black,
                size: 20.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToWordDetail(BuildContext context, WordOfTheDay word) {
    WordDetail wordDetail = WordDetail(
      id: 0, // Günün kelimesi için özel bir ID oluşturabilirsiniz
      word: word.term,
      meaning: word.definition,
      type: word.type,
      defination: word.definition,
      image: null, // Eğer varsa, günün kelimesinin resmini ekleyebilirsiniz
      collocations: [],
      derivations: [],
      synonyms: [],
    );

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => StudyScreen(
        words: [wordDetail],
        classroomId: 0,
        studySetId: 0,
        isStarred: true,
      ),
    ));
  }
}

class LearningPanel extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onWordOfDayTap;
  final VoidCallback onWordSetsTap;
  final VoidCallback onDictionaryTap;

  const LearningPanel({
    Key? key,
    required this.isDarkMode,
    required this.onWordOfDayTap,
    required this.onWordSetsTap,
    required this.onDictionaryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          WordSetsButton(onTap: onWordSetsTap, isDarkMode: isDarkMode),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.3),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28.sp),
                SizedBox(height: 8.h),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class WordSetsButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDarkMode;

  const WordSetsButton({
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  State<WordSetsButton> createState() => _WordSetsButtonState();
}

class _WordSetsButtonState extends State<WordSetsButton> {
  final GetXTransitionController _controller = Get.put(GetXTransitionController());

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _controller.opacity.value,
      child: Transform.translate(
        offset: Offset(0, _controller.slideOffset.value),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) => _controller.onTapDown(),
            onTapUp: (_) => _controller.onTapUp(),
            onTapCancel: () => _controller.onTapCancel(),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: _controller.scale.value,
              child: Container(
                height: 65.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isDarkMode
                        ? [Color(0xFF1CB0F6), Color(0xFF1BA0E1)]
                        : [Color(0xFF58CC02), Color(0xFF4FB802)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isDarkMode
                          ? Colors.black.withOpacity(0.25)
                          : Color(0xFF45A800).withOpacity(0.3),
                      blurRadius: _controller.shadowBlur.value,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Subtle pattern overlay
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: CustomPaint(
                          painter: DottedPatternPainter(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Kelime Setleri",
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  "Keşfet ve Öğren!",
                                  style: GoogleFonts.nunito(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

// Dotted pattern painter for subtle background texture
class DottedPatternPainter extends CustomPainter {
  final Color color;

  DottedPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 15.0;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
class GetXTransitionController extends GetxController {
  final opacity = 0.0.obs;
  final slideOffset = 0.1.obs;
  final scale = 1.0.obs;
  final shadowBlur = 8.0.obs;

  @override
  void onInit() {
    super.onInit();
    entrance();
  }

  void entrance() async {
    await 0.1.delay();
    opacity.value = 1.0;
    slideOffset.value = 0.0;
  }

  void onTapDown() {
    scale.value = 0.95;
    shadowBlur.value = 2.0;
  }

  void onTapUp() {
    scale.value = 1.0;
    shadowBlur.value = 8.0;
  }

  void onTapCancel() => onTapUp();
}

class ActionButton {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  ActionButton(
      {required this.icon, required this.color, required this.onPressed});
}

class ActionButtons extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleDarkMode;
  final VoidCallback shareApp;

  const ActionButtons({
    Key? key,
    required this.isDarkMode,
    required this.toggleDarkMode,
    required this.shareApp,
  }) : super(key: key);

  List<ActionButton> _getButtons(BuildContext context) => [
    ActionButton(
      icon: FontAwesomeIcons.bell,
      color: Colors.red,
      onPressed: () {},
    ),
    ActionButton(
      icon: FontAwesomeIcons.gear,
      color: Colors.blue,
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => SettingsPage())),
    ),
    ActionButton(
      icon: isDarkMode ? FontAwesomeIcons.moon : FontAwesomeIcons.sun,
      color: isDarkMode ? Colors.indigo : Colors.orange,
      onPressed: toggleDarkMode,
    ),
    ActionButton(
      icon: FontAwesomeIcons.playCircle,
      color: Colors.green,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                VideoPlayerScreen(videoUrl: AppUrls.homescreen)),
      ),
    ),
    ActionButton(
      icon: FontAwesomeIcons.shareNodes,
      color: Colors.purple,
      onPressed: shareApp,
    ),
    ActionButton(
      icon: FontAwesomeIcons.magnifyingGlass,
      color: Colors.teal,
      onPressed: () => showDialog(
        context: context,
        builder: (BuildContext context) =>
            SearchDialog(isDarkMode: isDarkMode),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final buttons = _getButtons(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double maxIconSize = 45.w;
        final double minSpacing = 4.w;

        double iconSize =
            (totalWidth - (buttons.length - 1) * minSpacing) / buttons.length;
        iconSize = iconSize.clamp(0, maxIconSize);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: buttons
              .map((button) => Flexible(child: _buildAnimatedButton(button, iconSize)))
              .toList(),
        );
      },
    );
  }

  Widget _buildAnimatedButton(ActionButton button, double size) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: button.color.withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: button.color.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: CircleBorder(),
          onTap: button.onPressed,
          child: Center(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: FaIcon(
                button.icon,
                key: ValueKey<IconData>(button.icon),
                size: size * 0.5,
                color: button.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EnhancedLoadingIndicator extends StatelessWidget {
  final String message;

  const EnhancedLoadingIndicator({
    Key? key,
    this.message =
    "Sistemde gerekli ayarlar yapılıyor... Uygulamızı sizin için en iyi hale getiriyoruz. Merak etmeyin, uzun sürmeyecek.",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitFoldingCube(
              color: Theme.of(context).primaryColor,
              size: 50.0,
            ),
            SizedBox(height: 24.0),
            Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.0),
            LinearProgressIndicator(
              valueColor:
              AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              backgroundColor: Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }
}

void showLoadingIndicator(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: EnhancedLoadingIndicator(),
      );
    },
  );
}

class MarqueeWidget extends StatefulWidget {
  final Widget child;
  final Axis direction;
  final Duration animationDuration, backDuration, pauseDuration;

  MarqueeWidget({
    required this.child,
    this.direction = Axis.horizontal,
    this.animationDuration = const Duration(milliseconds: 3000),
    this.backDuration = const Duration(milliseconds: 800),
    this.pauseDuration = const Duration(milliseconds: 800),
  });

  @override
  _MarqueeWidgetState createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  ScrollController? scrollController;

  @override
  void initState() {
    scrollController = ScrollController(initialScrollOffset: 50.0);
    WidgetsBinding.instance.addPostFrameCallback(scroll);
    super.initState();
  }

  @override
  void dispose() {
    scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: widget.child,
      scrollDirection: widget.direction,
      controller: scrollController,
    );
  }

  void scroll(_) async {
    while (scrollController!.hasClients) {
      await Future.delayed(widget.pauseDuration);
      if (scrollController!.hasClients) {
        await scrollController!.animateTo(
          scrollController!.position.maxScrollExtent,
          duration: widget.animationDuration,
          curve: Curves.ease,
        );
      }
      await Future.delayed(widget.pauseDuration);
      if (scrollController!.hasClients) {
        await scrollController!.animateTo(
          0.0,
          duration: widget.backDuration,
          curve: Curves.easeOut,
        );
      }
    }
  }
}

Widget buildCompactIconButton({
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
  required double size,
  String? text,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: CircleBorder(),
            onTap: onPressed,
            child: Center(
              child: FaIcon(
                icon,
                size: size * 0.6,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      if (text != null)
        Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.25,
            ),
          ),
        ),
    ],
  );
}

class ShimmerLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }
}