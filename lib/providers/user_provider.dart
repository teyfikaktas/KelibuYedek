import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class UserProvider with ChangeNotifier {
  String _username = '';
  int _userId = 0;
  String avatar = "";
  String get username => _username;
  int get userId => _userId;
  String point = "";
  bool get isLoggedIn => _username.isNotEmpty;

  Future<void> setUser(String username, int userId, String avatar, String point) async {
    _username = username;
    _userId = userId;
    this.avatar = avatar;
    this.point = "";// _avatar yerine this.avatar kullanın
    var box = await Hive.openBox('userBox');
    await box.put('username', username);
    await box.put('userId', userId);
    await box.put('avatar', avatar);
    notifyListeners();
  }

  Future<void> loadUser() async {
    var box = await Hive.openBox('userBox');
    _username = box.get('username', defaultValue: '');
    _userId = box.get('userId', defaultValue: 0);
    avatar = box.get('avatar', defaultValue: "0");
    notifyListeners();
  }

  logout() async {
    _username = '';
    _userId = 0;
    var box = await Hive.openBox('userBox');
    await box.clear();
    notifyListeners();
  }

}
