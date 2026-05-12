import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final String? imagePath;
  final VoidCallback? onPressed;

  const CustomDialog({
    Key? key,
    required this.title,
    required this.content,
    this.buttonText = 'Tamam',
    this.imagePath,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: Get.width * 0.95,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FF),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Image.asset(
                imagePath ?? 'assets/logo.png',
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: Get.height * 0.25),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.quicksand(
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF212121),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onPressed ?? () => Get.back(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  buttonText,
                  style: GoogleFonts.quicksand(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showCustomDialog(
    BuildContext context, String title, String message) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return CustomDialog(
        title: title,
        content: message,
      );
    },
  );
}