import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VolumeProvider with ChangeNotifier {
  bool _isVolumeOn = true;

  bool get isVolumeOn => _isVolumeOn;

  void toggleVolume() {
    _isVolumeOn = !_isVolumeOn;
    notifyListeners();
  }
}
