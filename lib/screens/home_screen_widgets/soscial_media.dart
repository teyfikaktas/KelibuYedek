import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RefinedSocialMediaInfo extends StatelessWidget {
  const RefinedSocialMediaInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, spreadRadius: 1)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bizi takip edin!', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              Icon(Icons.share, size: 14.w),
            ],
          ),
          SizedBox(height: 12.h),
          _buildSocialButton(FontAwesomeIcons.instagram, "@kelibunet", Color(0xFFE1306C)),
          SizedBox(height: 8.h),
          _buildSocialButton(FontAwesomeIcons.graduationCap, "@phd.akademi", Color(0xFF4267B2)),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String username, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16.w),
          SizedBox(width: 8.w),
          Text(username, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Spacer(),
          Icon(Icons.chevron_right, color: color, size: 12.w),
        ],
      ),
    );
  }
}