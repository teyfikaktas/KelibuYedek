import 'package:flutter/material.dart';

class LogoLoadingIndicator extends StatelessWidget {
  const LogoLoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.0,
      height: 100.0,
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 5,
          )
        ],
      ),
      child: CircularProgressIndicator(
        strokeWidth: 8.0,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        // Background Image
        backgroundColor: Colors.grey[200],
      ),
      alignment: Alignment.center,
      // Logo Image as Background
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage('assets/logo.png'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
