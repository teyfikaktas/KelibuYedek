import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CustomLoadingIndicatorLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animasyonu
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: Duration(seconds: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/logo.png', // Logo dosyanızın yolunu buraya girin
                width: 80,
                height: 80,
              ),
            ),
            SizedBox(height: 20),
            // Pulsating efekti
            SpinKitPulse(
              color: Colors.blue,
              size: 50.0,
            ),
            SizedBox(height: 10),
            Text(
              'Yükleniyor...',
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

