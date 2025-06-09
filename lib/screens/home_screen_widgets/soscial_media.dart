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
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF222831) : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black26 : Colors.black12,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactHeader(),
            _buildCompactSocialButtons(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14.r),
          topRight: Radius.circular(14.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                '#',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFA726),
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              '@kelibunet',
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 4.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              'Takip Et',
              style: GoogleFonts.poppins(
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFFA726),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSocialButtons(SocialPanelController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSocialIcon(
            controller,
            'instagram',
            FontAwesomeIcons.instagram,
            const LinearGradient(
              colors: [Color(0xFFE1306C), Color(0xFFF56040)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          _buildSocialIcon(
            controller,
            'x',
            FontAwesomeIcons.xTwitter,
            LinearGradient(
              colors: [Colors.black, Colors.black],
              begin: Alignment.center,
              end: Alignment.center,
            ),
          ),
          _buildSocialIcon(
            controller,
            'youtube',
            FontAwesomeIcons.youtube,
            const LinearGradient(
              colors: [Color(0xFFFF0000), Color(0xFFFF0000)],
              begin: Alignment.center,
              end: Alignment.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(
      SocialPanelController controller,
      String platform,
      IconData icon,
      Gradient gradient,
      ) {
    return Obx(
          () => GestureDetector(
        onTap: () => controller.launchSocial(platform),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 1,
            end: controller.isPressed.value ? 0.95 : 1,
          ),
          duration: const Duration(milliseconds: 100),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  color: Colors.white,
                  size: 16.sp,
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