import 'package:flutter/material.dart';

class NoInternetPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/logo.png'), // Logo gösterimi
            SizedBox(height: 20),
            Text('Bu uygulama için internet bağlantısı gereklidir.'),
          ],
        ),
      ),
    );
  }
}
