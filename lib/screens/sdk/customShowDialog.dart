import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showCustomDialog(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset('assets/logo.png', width: 100),
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              SizedBox(height: 8),
              Text(
                content,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Tamam', style: GoogleFonts.roboto()),
                style: ElevatedButton.styleFrom(
                  primary: Colors.pink,
                  onPrimary: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
