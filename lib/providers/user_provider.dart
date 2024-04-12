import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class UserProvider with ChangeNotifier {
  String _username = '';
  int _userId = 0;
  String _avatar = "";
  int _point =0;
  String _email = "";
  String _phone = "";
  String _phoneVerified = "";
  String _createdAt = "";
  String _city = ""; // Yeni alan ekleniyor
  int _birthYear = 0; // Yeni alan ekleniyor
  String? _team; // Yeni alan ekleniyor, null olabilir
  String _hashValue(String value) {
    var bytes = utf8.encode(value); // Veriyi byte dizisine dönüştür
    var digest = sha256.convert(bytes); // SHA-256 hash fonksiyonunu kullan
    return digest.toString(); // Hash değerini string olarak döndür
  }

  // Getter'lar ekleniyor
  String get username => _username;
  int get userId => _userId;
  String get avatar => _avatar;
  int get point => _point;
  String get email => _email;
  String get phone => _phone;
  String get phoneVerified => _phoneVerified;
  String get createdAt => _createdAt;
  String get city => _city; // Yeni alan için getter
  int get birthYear => _birthYear; // Yeni alan için getter
  String? get team => _team; // Yeni alan için getter, null olabilir

  bool get isLoggedIn => _username.isNotEmpty;

  // setUser fonksiyonunu güncelliyoruz, yeni alanları da içerecek şekilde
  Future<void> setUser(
      String username,
      int userId,
      String avatar,
      int point,
      String email,
      String phone,
      String phoneVerified,
      String createdAt,
      String city, // Yeni parametre
      int birthYear, // Yeni parametre
      String? team // Yeni parametre, null olabilir
      ) async {
    _username = username;
    _userId = userId;
    _avatar = avatar;
    _point = point;
    _email = email;
    _phone = phone;
    _phoneVerified = phoneVerified;
    _createdAt = createdAt;
    _city = city; // Yeni alanı ayarlıyoruz
    _birthYear = birthYear; // Yeni alanı ayarlıyoruz
    _team = team; // Yeni alanı ayarlıyoruz, null olabilir

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
    await box.put('city', city); // Yeni alanı kaydediyoruz
    await box.put('birthYear', birthYear); // Yeni alanı kaydediyoruz
    if (team != null) { // team null değilse kaydediyoruz
      await box.put('team', team);
    }


    notifyListeners();
  }
  Future<void> addPoint(int newPoint) async {

    // Puanı güncelliyoruz.
    _point = newPoint;

    // Hive veritabanında güncellenmiş puanı kaydediyoruz.
    var box = await Hive.openBox('userBox');
    await box.put('point', _point);

    notifyListeners();
  }

  // Diğer fonksiyonlarınızda bu yeni alanları kullanabilir ve gerektiğinde güncelleyebilirsiniz.

  Future<bool> loadUser() async {
    var box = await Hive.openBox('userBox');
    _username = box.get('username', defaultValue: '');
    _userId = box.get('userId', defaultValue: 0);
    _avatar = box.get('avatar', defaultValue: '');
    _point = int.parse(box.get('point', defaultValue: '0').toString());
    _email = box.get('email', defaultValue: '');
    _phone = box.get('phone', defaultValue: '');
    _phoneVerified = box.get('phoneverifed', defaultValue: '');
    _createdAt = box.get('createdAt', defaultValue: '');
    _city = box.get('city', defaultValue: ''); // Yeni alanı yüklüyoruz
    _birthYear = box.get('birthYear', defaultValue: 0); // Yeni alanı yüklüyoruz
    _team = box.get('team'); // Yeni alanı yüklüyoruz, null olabilir

    notifyListeners();
    return _username.isNotEmpty; // Kullanıcı adı doluysa true, değilse false döndür
  }
  // Yeni bir metod ekliyoruz: Kullanıcının avatar URL'sini güncellemek için
  Future<void> updateUserAvatarUrl(String newAvatarUrl) async {
    _avatar = newAvatarUrl;
    var box = await Hive.openBox('userBox');
    await box.put('avatar', newAvatarUrl);
    notifyListeners();
  }
  Future<String> getUsernameHash() async {
    var box = await Hive.openBox('userBox');
    String hash = box.get('usernameHash', defaultValue: '');

    // Eğer hash değeri boşsa ve kullanıcı adı mevcutsa, hash'i yeniden hesapla ve kaydet
    if (hash.isEmpty && _username.isNotEmpty) {
      hash = _hashValue(_username);
      await box.put('usernameHash', hash); // Yeniden hesaplanan hash değerini kaydet
      notifyListeners(); // Dinleyicileri güncelle
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
    _phoneVerified = '';
    _createdAt = '';
    _city = ''; // Yeni alanı sıfırlıyoruz
    _birthYear = 0; // Yeni alanı sıfırlıyoruz
    _team = null; // Yeni alanı sıfırlıyoruz, nullable olduğu için null olarak ayarlıyoruz

    var box = await Hive.openBox('userBox');
    await box.clear(); // Tüm verileri temizliyoruz
    notifyListeners();
  }
}
