import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'NetWorkService.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> checkConnectivity() async {
    await _updateConnectionStatus(await Connectivity().checkConnectivity());
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      _isOnline = false;
    } else {
      _isOnline = await NetworkService.isConnected();
    }
    notifyListeners();
  }
}