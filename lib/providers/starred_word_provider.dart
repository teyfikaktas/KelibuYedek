import 'package:flutter/material.dart';

class StarredWordsProvider extends ChangeNotifier {
  Map<int, bool> _starredWords = {};

  Map<int, bool> get starredWords => _starredWords;

  void toggleStar(int wordId, bool isStarred) {
    _starredWords[wordId] = !isStarred;
    notifyListeners();
  }

  void setStarredWords(Map<int, bool> newStarredWords) {
    _starredWords = newStarredWords;
    notifyListeners();
  }
}
