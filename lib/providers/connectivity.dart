import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void startMonitoring() {
    print(ConnectivityResult);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      print("Connectivity Changed: $results");  // Debugging statement
      if (results.contains(ConnectivityResult.none)) {
        print("No internet connection");  // Debugging statement
        navigatorKey.currentState?.pushNamed('/noInternet');
      } else {
        print("Internet connection available");  // Debugging statement
        if (navigatorKey.currentState?.canPop() ?? false) {
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
        }
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
