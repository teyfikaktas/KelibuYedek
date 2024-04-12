import 'package:shared_preferences/shared_preferences.dart';
import 'package:kelibu/event_bus.dart';

import '../event.dart';
class StarredWordsService {
  Future<void> toggleWordStarStatus(int wordId, bool isStarred, int classroomId, int studySetId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _generateKey(classroomId, studySetId);
    final starredWordsSet = await loadStarredWords(classroomId, studySetId);
    if (isStarred) {
      starredWordsSet.add(wordId);
      print('$wordId yıldızlandı.');
    } else {
      starredWordsSet.remove(wordId);
      print('$wordId yıldızı kaldırıldı.');
    }
    await prefs.setStringList(key, starredWordsSet.map((id) => id.toString()).toList());
    appEventBus.fire(StarredWordsChangedEvent(starredWordsSet.length));

  }
  Future<void> removeWordFromAll(int wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (String key in keys) {
      var value = prefs.get(key); // Anahtarın değerini al

      // Değer List<String> türünde değilse, döngünün bu adımını atla
      if (value is! List<String>) continue;

      // Değer List<String> türündeyse, işlemlere devam et
      List<String>? starredWordsList = prefs.getStringList(key);

      if (starredWordsList != null) {
        final updatedStarredWordsList = starredWordsList.where((id) => int.parse(id) != wordId).toList();

        // Güncellenmiş listeyi kaydet
        await prefs.setStringList(key, updatedStarredWordsList);
      }
    }
  }

  Future<Set<int>> loadStarredAllWords(int classroomId, int studySetId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _generateKey(classroomId, studySetId);
    final String? starredWordsString = prefs.getString(key);

    if (starredWordsString != null) {
      return _parseStarredWordsString(starredWordsString);
    } else {
      return {};
    }
  }
  Future<void> removeWordFromAllById(int wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (String key in keys) {
      if (key.startsWith('starredWords')) {
        // Bu anahtara ait yıldızlanmış kelimelerin listesini al
        List<String>? starredWordsList = prefs.getStringList(key);

        // Eğer listede kelime varsa, kelime ID'sini listeden çıkar
        if (starredWordsList != null && starredWordsList.contains(wordId.toString())) {
          starredWordsList.remove(wordId.toString());
          // Güncellenmiş listeyi tekrar kaydet
          await prefs.setStringList(key, starredWordsList);
        }
      }
    }
  }
  Future<Set<int>> loadStarredWords(int classroomId, int studySetId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _generateKey(classroomId, studySetId);
    final starredWordsStringList = prefs.getStringList(key);

    if (starredWordsStringList != null) {
      final starredWordsSet = starredWordsStringList.map((id) => int.parse(id)).toSet();
      print('Yüklenen yıldızlı kelimeler: $starredWordsSet');
      return starredWordsSet;
    } else {
      print('Yıldızlı kelime bulunamadı.');
      return {};
    }
  }
  Future<Set<int>> loadClassroomStarredWordsAll(int classroomId, List<int> studySetIds) async {
    final prefs = await SharedPreferences.getInstance();
    Set<int> allStarredWords = {};

    try {
      for (int studySetId in studySetIds) {
        final key = _generateKey(classroomId, studySetId);
        final starredWordsStringList = prefs.getStringList(key); // getStringList kullanılıyor

        if (starredWordsStringList != null) {
          final starredWordsSet = starredWordsStringList
              .map((id) => int.tryParse(id))
              .where((id) => id != null)
              .cast<int>()
              .toSet(); // String listesini int set'e çevir
          allStarredWords.addAll(starredWordsSet);
        }
      }
      print('Yüklenen tüm yıldızlı kelimeler: $allStarredWords');
    } catch (e) {
      print('SharedPreferences işlemleri sırasında bir hata oluştu: $e');
    }

    return allStarredWords;
  }

  Set<int> _parseStarredWordsString(String starredWordsString) {
    print(starredWordsString);
    final String cleanedString = starredWordsString.replaceAll(RegExp(r'[\[\]]'), '');
    return Set.from(cleanedString.split(',')
        .map((id) => int.tryParse(id.trim()))
        .where((id) => id != null)
        .cast<int>());
  }

  Future<void> printAllSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    for (String key in allKeys) {
      var value = prefs.get(key); // Değer dynamic türünde olacağı için doğrudan yazdırıyoruz.
      print('$key: $value');
    }
  }

  Future<Set<int>> loadAllStarredWordsAll() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final Set<int> allStarredWords = Set<int>();

    for (String key in allKeys) {
      if (key.startsWith('starredWords')) {
        // getStringList ile doğrudan List<String> bekliyoruz.
        List<String>? starredWordsList = prefs.getStringList(key);
        if (starredWordsList != null) {
          // List<String> içindeki her elemanı int'e çevirip Set<int>'e ekliyoruz.
          allStarredWords.addAll(starredWordsList.map((id) => int.parse(id)));
        }
      }
    }

    print('Tüm yıldızlanmış kelimeler: $allStarredWords');
    return allStarredWords;
  }
  String _generateKey(int classroomId, int studySetId) {
    // Kelimenin benzersizliğini sağlayacak bir key üretiyoruz
    return 'starredWords_classroomId:${classroomId}_studySetId:${studySetId}';
  }

}
