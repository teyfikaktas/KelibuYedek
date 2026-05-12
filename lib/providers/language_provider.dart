import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool isEnglish = true;

  void toggleLanguage() {
    isEnglish = !isEnglish;
    notifyListeners();
  }
}
