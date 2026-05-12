import 'dart:io';

import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier with WidgetsBindingObserver {
  bool isConnected = true;

  ConnectivityService() {
    // Mevcut bağlantı dinleyicinizi burada başlatıyorsunuz
    WidgetsBinding.instance.addObserver(this);
    _initConnectivity();
  }

  void _initConnectivity() {
    // Uygulama ilk açıldığında internet bağlantısını kontrol edin
    _checkConnectivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulama ön plana geldiğinde internet bağlantısını kontrol edin
      _checkConnectivity();
    }
  }

  void _checkConnectivity() async {
    // Burada internet bağlantısını kontrol edin ve isConnected değişkenini güncelleyin
    // Örnek:
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isConnected = true;
      } else {
        isConnected = false;
      }
    } on SocketException catch (_) {
      isConnected = false;
    }
    notifyListeners();
  }
}
