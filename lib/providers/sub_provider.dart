import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kelibu/api.dart';

class SubscriptionProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _isVip = false;
  String _type = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _status = '';

  bool get isVip => _isVip;

  String get type => _type;

  DateTime? get startDate => _startDate;

  DateTime? get endDate => _endDate;

  String get status => _status;

  SubscriptionProvider() {
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    await fetchSubscriptionStatus(); // ✅ Direkt API'den çek
  }

  Future<void> fetchSubscriptionStatus() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> statusData = await apiService.getCombinedSubscriptionStatus();
      _updateSubscriptionData(statusData);
      await _storage.write(key: 'subscription_status', value: const JsonEncoder().convert(statusData));
      notifyListeners();
    } catch (e)
    {
    }
  }

  void _updateSubscriptionData(Map<String, dynamic> statusData) {
    _isVip = statusData['is_vip'] ?? false;
    _type = statusData['type'] ?? '';
    _startDate = statusData['start_date'] != null
        ? DateTime.parse(statusData['start_date'])
        : null;
    _endDate = statusData['end_date'] != null
        ? DateTime.parse(statusData['end_date'])
        : null;
    _status = statusData['status'] ?? '';
  }

  Future<Map<String, dynamic>> subscribe(
      String platform, String receipt, String productId) async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> response = await apiService.subscribe(
          receipt: receipt, productId: productId, platform: platform);

      if (response['membership']['status'] == 'active') {
        await fetchSubscriptionStatus(); // Fetch updated status after successful subscription
        return {'success': true, 'message': 'Subscription successful'};
      } else {
        return {
          'success': false,
          'message': 'Subscription failed: ${response['status']}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error occurred during subscription'
      };
    }
  }

  Future<void> cancelSubscription() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> response = await apiService.cancelSubscription();
      if (response['success']) {
        await fetchSubscriptionStatus(); // Fetch updated status after successful cancellation
      }
    } catch (e) {
    }
  }
}
