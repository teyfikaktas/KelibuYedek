// loading_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class LoadingDialog extends StatelessWidget {
  final bool isDarkMode;

  const LoadingDialog({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: EdgeInsets.all(24.sp),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/loading.json',
              width: 70.w,
              height: 70.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 16.h),
            Text(
              'Sistem Hazırlanıyor',
              style: GoogleFonts.comfortaa(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.blue[300] : const Color(0xFF42A5F5),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Lütfen bekleyin, sistem ayarları yapılıyor...',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 16.sp,
                color: isDarkMode ? Colors.grey[400] : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
