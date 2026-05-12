import 'dart:convert';

import 'package:flutter/foundation.dart';

class UserAuthenticator extends ChangeNotifier {
  String _userName = '';
  bool _isLoggedIn = false;
  int _userId = 0;
  Map<String, dynamic> _userData =
      {}; // API'den gelen kullanıcı verilerini saklamak için
  int get userId => _userId; // userId için public getter

  String get userName => _userName;

  bool get isLoggedIn => _isLoggedIn;

  Map<String, dynamic> get userData => _userData; // userData için public getter

  void login(String response) {
    var data = json.decode(response);
    _userName = data['name'];
    _userId = data['id'];
    _userData = data; // Tüm kullanıcı verilerini sakla
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _userName = '';
    _isLoggedIn = false;
    notifyListeners();
  }
}
