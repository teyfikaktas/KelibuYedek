import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialPanel extends StatelessWidget {
  final bool isDarkMode;
  const SocialPanel({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SocialPanelController>(
      init: SocialPanelController(),
      builder: (controller) => Container(
        margin: EdgeInsets.all(2.w), // Küçültüldü: 4 -> 2
        padding: EdgeInsets.all(6.w), // Küçültüldü: 8 -> 6
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFFFF1E6),
          borderRadius: BorderRadius.circular(12.r), // Küçültüldü: 16 -> 12
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4, // Küçültüldü: 6 -> 4
              offset: const Offset(0, 2), // Küçültüldü: 3 -> 2
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 28.w, // Küçültüldü: 32 -> 28
                  height: 28.w, // Küçültüldü: 32 -> 28
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode
                        ? const Color(0xFF2E3A47)
                        : const Color(0xFFFFD1DC),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.smile,
                      color: Colors.white,
                      size: 12.sp, // Küçültüldü: 14 -> 12
                    ),
                  ),
                ),
                SizedBox(width: 6.w), // Küçültüldü: 8 -> 6
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bizi Takip Edin',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 6.sp, // Küçültüldü: 14 -> 12
                        color: isDarkMode ? Colors.white : Colors.black87,
                        shadows: const [
                          Shadow(
                            blurRadius: 1.5, // Küçültüldü: 2 -> 1.5
                            color: Colors.black26,
                            offset: Offset(0.5, 0.5), // Küçültüldü: 1,1 -> 0.5,0.5
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '@kelibunet',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 10.sp, // Küçültüldü: 12 -> 10
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        shadows: const [
                          Shadow(
                            blurRadius: 1.5,
                            color: Colors.black26,
                            offset: Offset(0.5, 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h), // Küçültüldü: 12 -> 8
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(
                  controller,
                  FontAwesomeIcons.instagram,
                  'instagram',
                  const [
                    Color(0xFFFFC1E3),
                    Color(0xFFFFD1DC),
                    Color(0xFFFFE4EC),
                  ],
                ),
                _buildSocialButton(
                  controller,
                  null,
                  'x',
                  isDarkMode
                      ? const [Color(0xFFB2EBF2), Color(0xFFB2DFDB)]
                      : const [Color(0xFF424242), Color(0xFF212121)],
                ),
                _buildSocialButton(
                  controller,
                  FontAwesomeIcons.youtube,
                  'youtube',
                  const [
                    Color(0xFFFFCDD2),
                    Color(0xFFFFAB91),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      SocialPanelController controller,
      IconData? icon,
      String platform,
      List<Color> gradientColors,
      ) {
    final double buttonSize = platform == 'x' ? 28.w : 32.w; // Küçültüldü: 32,38 -> 28,32
    final double iconSize = platform == 'x' ? 14.sp : 16.sp; // Küçültüldü: 16,18 -> 14,16
    return Obx(
          () => GestureDetector(
        onTap: () => controller.launchSocial(platform),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 1,
            end: controller.isPressed.value ? 0.95 : 1, // Küçültüldü: 0.9 -> 0.95
          ),
          duration: const Duration(milliseconds: 100),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 1), // Küçültüldü: 1.5 -> 1
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2, // Küçültüldü: 3 -> 2
                    offset: const Offset(0, 1), // Küçültüldü: 2 -> 1
                  ),
                ],
              ),
              child: Center(
                child: platform == 'x'
                    ? Text(
                  'X',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: iconSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 1.5,
                        color: Colors.black26,
                        offset: Offset(0.5, 0.5),
                      ),
                    ],
                  ),
                )
                    : Icon(
                  icon,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SocialPanelController extends GetxController {
  final isPressed = false.obs;

  Future<void> launchSocial(String platform) async {
    isPressed.value = true;
    await Future.delayed(const Duration(milliseconds: 100));

    final String url;
    if (platform == 'youtube') {
      url = 'https://www.youtube.com/@Kelibunet';
    } else {
      final baseUrl = platform == 'x' ? 'x' : 'www.$platform';
      url = 'https://$baseUrl.com/kelibunet';
    }

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('URL açılamadı: $e');
    }
    isPressed.value = false;
  }
}