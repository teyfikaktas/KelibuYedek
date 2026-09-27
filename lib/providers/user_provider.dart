import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

// Riverpod points provider
class PointsNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> setPoint(int newPoint) async {
    state = newPoint;
    var box = await Hive.openBox('userBox');
    await box.put('point', newPoint);
  }
  Future<void> addPoints(int delta) async {
    state = state + delta;
    var box = await Hive.openBox('userBox');
    await box.put('point', state);
  }

  Future<void> loadPoint() async {
    var box = await Hive.openBox('userBox');
    state = box.get('point') is int ? box.get('point') : 0;
  }
}

final pointsProvider = NotifierProvider<PointsNotifier, int>(
  PointsNotifier.new,
);

class UserProvider with ChangeNotifier {
  String _username = '';
  int _userId = 0;
  String _avatar = "";
  int _point = 0;
  String _email = "";
  String _phone = "";
  bool _phoneVerified = false;
  String _createdAt = "";
  String _city = "";
  int _birthYear = 0;
  String? _team;
  int _streakCount = 0;

  int _dailyRank = 0;
  int _weeklyRank = 0;
  int _monthlyRank = 0;
  int _allTimeRank = 0;

  String _hashValue(String value) {
    var bytes = utf8.encode(value);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  String get username => _username;
  int get userId => _userId;
  String get avatar => _avatar;
  int get point => _point;
  String get email => _email;
  String get phone => _phone;
  bool get phoneVerified => _phoneVerified;
  String get createdAt => _createdAt;
  String get city => _city;
  int get birthYear => _birthYear;
  String? get team => _team;
  int get streakCount => _streakCount;
  int get dailyRank => _dailyRank;
  int get weeklyRank => _weeklyRank;
  int get monthlyRank => _monthlyRank;
  int get allTimeRank => _allTimeRank;
  bool get isLoggedIn => _username.isNotEmpty;

  Future<void> setUser(
      String username,
      int userId,
      String avatar,
      int point,
      String email,
      String phone,
      bool phoneVerified,
      String createdAt,
      String city,
      int birthYear,
      String? team,
      {int streakCount = 0,
        int dailyRank = 0,
        int weeklyRank = 0,
        int monthlyRank = 0,
        int allTimeRank = 0}) async {
    _username = username;
    _userId = userId;
    _avatar = avatar;
    _point = point;
    _email = email;
    _phone = phone;
    _phoneVerified = phoneVerified;
    _createdAt = createdAt;
    _city = city;
    _birthYear = birthYear;
    _team = team;
    _streakCount = streakCount;
    _dailyRank = dailyRank;
    _weeklyRank = weeklyRank;
    _monthlyRank = monthlyRank;
    _allTimeRank = allTimeRank;

    var box = await Hive.openBox('userBox');
    String usernameHash = _hashValue(username);
    await box.put('usernameHash', usernameHash);
    await box.put('username', username);
    await box.put('userId', userId);
    await box.put('avatar', avatar);
    await box.put('point', point);
    await box.put('email', email);
    await box.put('phone', phone);
    await box.put('phoneVerified', phoneVerified);
    await box.put('createdAt', createdAt);
    await box.put('city', city);
    await box.put('birthYear', birthYear);
    if (team != null) {
      await box.put('team', team);
    }
    await box.put('streakCount', _streakCount);
    await box.put('dailyRank', dailyRank);
    await box.put('weeklyRank', weeklyRank);
    await box.put('monthlyRank', monthlyRank);
    await box.put('allTimeRank', allTimeRank);

    notifyListeners();
  }

  Future<void> addPoint(int newPoint) async {
    _point = newPoint;
    var box = await Hive.openBox('userBox');
    await box.put('point', _point);
    notifyListeners();
  }

  Future<bool> loadUser() async {
    try {
      var box = await Hive.openBox('userBox');

      var phoneVerifiedValue = box.get('phoneVerified');
      _phoneVerified = phoneVerifiedValue is bool ? phoneVerifiedValue : false;

      _username = box.get('username')?.toString() ?? '';
      _userId = box.get('userId') is int ? box.get('userId') : 0;
      _avatar = box.get('avatar')?.toString() ?? '';
      _point = box.get('point') is int ? box.get('point') : 0;
      _email = box.get('email')?.toString() ?? '';
      _phone = box.get('phone')?.toString() ?? '';
      _createdAt = box.get('createdAt')?.toString() ?? '';
      _city = box.get('city')?.toString() ?? '';
      _birthYear = box.get('birthYear') is int ? box.get('birthYear') : 0;
      _team = box.get('team')?.toString();
      _streakCount = box.get('streakCount') is int ? box.get('streakCount') : 0;
      _dailyRank = box.get('dailyRank') is int ? box.get('dailyRank') : 0;
      _weeklyRank = box.get('weeklyRank') is int ? box.get('weeklyRank') : 0;
      _monthlyRank = box.get('monthlyRank') is int ? box.get('monthlyRank') : 0;
      _allTimeRank = box.get('allTimeRank') is int ? box.get('allTimeRank') : 0;

      notifyListeners();
      return _username.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateUserAvatarUrl(String newAvatarUrl) async {
    _avatar = newAvatarUrl;
    var box = await Hive.openBox('userBox');
    await box.put('avatar', newAvatarUrl);
    notifyListeners();
  }

  Future<String> getUsernameHash() async {
    var box = await Hive.openBox('userBox');
    String hash = box.get('usernameHash', defaultValue: '');

    if (hash.isEmpty && _username.isNotEmpty) {
      hash = _hashValue(_username);
      await box.put('usernameHash', hash);
      notifyListeners();
    }

    return hash;
  }

  Future<void> logout() async {
    _username = '';
    _userId = 0;
    _avatar = '';
    _point = 0;
    _email = '';
    _phone = '';
    _phoneVerified = false;
    _createdAt = '';
    _city = '';
    _birthYear = 0;
    _team = null;
    _streakCount = 0;
    _dailyRank = 0;
    _weeklyRank = 0;
    _monthlyRank = 0;
    _allTimeRank = 0;

    var box = await Hive.openBox('userBox');
    await box.clear();
    notifyListeners();
  }

  Future<void> updateRankings({
    required int streakCount,
    required int dailyRank,
    required int weeklyRank,
    required int monthlyRank,
    required int allTimeRank,
  }) async {
    _streakCount = streakCount;
    _dailyRank = dailyRank;
    _weeklyRank = weeklyRank;
    _monthlyRank = monthlyRank;
    _allTimeRank = allTimeRank;

    var box = await Hive.openBox('userBox');
    await box.put('streakCount', streakCount);
    await box.put('dailyRank', dailyRank);
    await box.put('weeklyRank', weeklyRank);
    await box.put('monthlyRank', monthlyRank);
    await box.put('allTimeRank', allTimeRank);

    notifyListeners();
  }
}