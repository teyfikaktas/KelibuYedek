// login_controller.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../api.dart';
import '../../../../main.dart';
import '../../../../providers/user_provider.dart';

class LoginController extends GetxController {
  final ApiService _apiService;
  final storage;

  var isLoading = false.obs;

  LoginController(this._apiService, this.storage);

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;

      // 1. FCM Token alma işlemi
      final String? fcmToken = await FirebaseMessaging.instance.getToken();

      // 2. API Login işlemi
      final responseData = await _apiService.login(
        email: email.trim(),
        password: password.trim(),
        fcmToken: fcmToken ?? '',
      );

      // 3. RevenueCat işlemleri
      await _handleRevenueCat(responseData);

      // 4. Token işlemleri
      await _handleTokenStorage(responseData);

      // 5. User Provider güncelleme
      await _updateUserProvider(responseData);

      // 6. SharedPreferences güncelleme
      await _updateSharedPreferences(responseData);

      // 7. Başarı mesajı gösterme
      _showSuccessMessage(responseData['message'] ?? 'Giriş başarılı!');

      // 8. Yönlendirme
      Get.off(
        () => MainScreen(),
        transition: Transition.fade,
        duration: Duration(milliseconds: 500),
      );
    } on ApiException catch (e) {
      _handleApiError(e);
    } catch (e) {
      _handleGeneralError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleRevenueCat(Map<String, dynamic> userData) async {
    try {
      final String userIdR = userData['user']['id']?.toString() ?? '0';
      await Purchases.logIn(userIdR);
      await Purchases.syncPurchases();
      final customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      // RevenueCat hatası login işlemini engellemeyecek
    }
  }

  Future<void> _handleTokenStorage(Map<String, dynamic> responseData) async {
    if (responseData['access_token'] == null ||
        responseData['expires_in'] == null) {
      throw Exception('Token bilgisi eksik.');
    }

    final String accessToken = responseData['access_token'];
    final int expiresIn = responseData['expires_in'];
    final int expiresAtMillis =
        DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;

    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'expires_at', value: expiresAtMillis.toString());
  }

  Future<void> _updateUserProvider(Map<String, dynamic> responseData) async {
    final user = responseData['user'];
    if (user == null) throw Exception('Kullanıcı verisi bulunamadı.');

    final userProvider = Get.find<UserProvider>();
    await userProvider.setUser(
      user['name'] ?? '',
      user['id'] != null ? int.tryParse(user['id'].toString()) ?? 0 : 0,
      user['avatar'] ?? '',
      user['point'] ?? 0,
      user['email'] ?? '',
      user['phone'] ?? '',
      user['phone_verified'] ?? false,
      user['created_at'] ?? '',
      user['city'] ?? '',
      user['birth_year'] != null
          ? int.tryParse(user['birth_year'].toString()) ?? 0
          : 0,
      user['team'] ?? '',
      streakCount: user['streak_count'] ?? 0,
      dailyRank: user['daily_rank'] ?? 0,
      weeklyRank: user['weekly_rank'] ?? 0,
      monthlyRank: user['monthly_rank'] ?? 0,
      allTimeRank: user['all_time_rank'] ?? 0,
    );
  }

  Future<void> _updateSharedPreferences(
      Map<String, dynamic> responseData) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = responseData['user']['id']?.toString() ?? '0';
    await prefs.setString('userId', userId);
  }

  void _showSuccessMessage(String message) {
    Get.snackbar(
      'Başarılı',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _handleApiError(ApiException e) {
    if (e.details != null) {
      final List<String> errorMessages = [];
      e.details!.forEach((field, messages) {
        errorMessages.addAll(List<String>.from(messages));
      });
      final String combinedMessage = errorMessages.join('\n');
      Get.dialog(
        AlertDialog(
          title: Text('Hatalar'),
          content: Text(combinedMessage),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Tamam'),
            ),
          ],
        ),
      );
    } else if (e.message.contains('Too Many Requests')) {
      Get.dialog(
        AlertDialog(
          title: Text('Çok Fazla Deneme'),
          content: Text(
              'Çok fazla giriş denemesi yaptınız. Lütfen bekleyip tekrar deneyin.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Tamam'),
            ),
          ],
        ),
      );
    } else {
      Get.dialog(
        AlertDialog(
          title: Text('Hata'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  void _handleGeneralError(dynamic e) {
    String message = 'Bir sorun oluştu. Lütfen tekrar deneyin.';
    if (e is ApiException && e.message.contains('Too Many Requests')) {
      message =
          'Çok fazla giriş denemesi yaptınız. Lütfen biraz bekleyip tekrar deneyin.';
    }

    Get.dialog(
      AlertDialog(
        title: Text('Beklenmeyen Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
