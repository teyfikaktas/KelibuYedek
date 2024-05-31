import 'package:shared_preferences/shared_preferences.dart';
import 'package:kelibu/event_bus.dart';
import '../api.dart';
import '../event.dart';
import '../main.dart';

class StarredWordsService {
  Future<void> toggleWordStarStatus(int wordId, bool isStarred, int classroomId, int studySetId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _generateKey(classroomId, studySetId);
    final starredWordsSet = await loadStarredWords(classroomId, studySetId);
    final userID = userProviderGlobal!.userId;
    await ApiService().starWord(wordId, classroomId, studySetId, userID);
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
    final userID = userProviderGlobal!.userId;

    await ApiService().starWordDeleteAll(wordId,userID);
    for (String key in keys) {
      if (key.startsWith('starredWords')) {
        final List<String>? starredWordsList = _getStringListSafe(prefs, key);

        if (starredWordsList != null && starredWordsList.contains(wordId.toString())) {
          List<String> mutableStarredWordsList = List<String>.from(starredWordsList);
          mutableStarredWordsList.remove(wordId.toString());
          await prefs.setStringList(key, mutableStarredWordsList);
        }
      }
    }
  }

  Future<void> removeWordFromAllById(int wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final userID = userProviderGlobal!.userId;

    await ApiService().starWordDeleteAll(wordId,userID);

    for (String key in keys) {
      if (key.startsWith('starredWords')) {
        final List<String>? starredWordsStringList = _getStringListSafe(prefs, key);

        if (starredWordsStringList != null && starredWordsStringList.contains(wordId.toString())) {
          starredWordsStringList.remove(wordId.toString());
          await prefs.setStringList(key, starredWordsStringList);
        }
      }
    }
  }

  Future<Set<int>> loadStarredWords(int classroomId, int studySetId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _generateKey(classroomId, studySetId);
    final List<String>? starredWordsStringList = _getStringListSafe(prefs, key);
    print(starredWordsStringList);
    if (starredWordsStringList != null) {
      final Set<int> starredWordsSet = starredWordsStringList.map((id) => int.parse(id)).toSet();
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

    if (classroomId == -1) {
      final keys = prefs.getKeys();  // Tüm anahtarları getir
      for (var key in keys) {
        if (key.startsWith('starredWords')) {  // Anahtar 'starredWords' ile başlıyorsa
          final List<String>? starredWordsStringList = _getStringListSafe(prefs, key);

          if (starredWordsStringList != null) {
            final starredWordsSet = starredWordsStringList
                .map((id) => int.tryParse(id))
                .where((id) => id != null)
                .cast<int>()
                .toSet();
            allStarredWords.addAll(starredWordsSet);
          }
        }
      }
    } else {
      // Belirli bir classroom ve study set ids için yıldızlı kelimeleri getir
      try {
        for (int studySetId in studySetIds) {
          final key = _generateKey(classroomId, studySetId);
          final List<String>? starredWordsStringList = _getStringListSafe(prefs, key);

          if (starredWordsStringList != null) {
            final starredWordsSet = starredWordsStringList
                .map((id) => int.tryParse(id))
                .where((id) => id != null)
                .cast<int>()
                .toSet();
            allStarredWords.addAll(starredWordsSet);
          }
        }
        print('Yüklenen tüm yıldızlı kelimeler: $allStarredWords');
      } catch (e) {
        print('SharedPreferences işlemleri sırasında bir hata oluştu: $e');
      }
    }

    return allStarredWords;
  }

  Set<int> _parseStarredWordsString(String starredWordsString) {
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
        final List<String>? starredWordsStringList = _getStringListSafe(prefs, key);
        if (starredWordsStringList != null) {
          allStarredWords.addAll(starredWordsStringList.map((id) => int.parse(id)));
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

  List<String>? _getStringListSafe(SharedPreferences prefs, String key) {
    try {
      final dynamic value = prefs.get(key);
      if (value is List) {
        return value.cast<String>();
      }
      return null;
    } catch (e) {
      print('Error getting string list for key $key: $e');
      return null;
    }
  }
}
