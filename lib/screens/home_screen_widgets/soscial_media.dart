import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CompactDuolingoStyleSocialPanel extends StatelessWidget {
  final bool isDarkMode;

  const CompactDuolingoStyleSocialPanel({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode ? Color(0xFF1CB0F6) : Color(0xFFFFF4E5);
    final textColor = isDarkMode ? Colors.white : Color(0xFF4B4B4B);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bizi Takip Et!',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSocialButton(FontAwesomeIcons.instagram, 'Instagram', Color(0xFFFF4F5E)),
              _buildSocialButton(FontAwesomeIcons.twitter, 'Twitter', Color(0xFF1CB0F6)),
              _buildSocialButton(FontAwesomeIcons.youtube, 'YouTube', Color(0xFFFF9600)),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            '@kelibunet',
            style: TextStyle(
              fontSize: 14.sp,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String platform, Color color) {
    return InkWell(
      onTap: () => _launchURL('https://www.$platform.com/kelibunet'.toLowerCase()),
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            )
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 12.w),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }
}