import 'package:shared_preferences/shared_preferences.dart';
import 'package:kelibu/event_bus.dart';
import '../api.dart';
import '../event.dart';
import '../main.dart';

class StarredWordsService {
  static final StarredWordsService _instance = StarredWordsService._internal();
  static const String _keyPrefix = 'starredWords';
  SharedPreferences? _prefs;
  final Map<String, Set<int>> _cache = {};

  factory StarredWordsService() {
    return _instance;
  }

  StarredWordsService._internal();

  Future<void> ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> toggleWordStarStatus(int wordId, bool isStarred, int classroomId, int studySetId) async {
    await ensureInitialized();
    final key = _generateKey(classroomId, studySetId);
    final starredWordsSet = await _getStarredWords(key);
    final userID = userProviderGlobal!.userId;

    await Future.wait([
      ApiService().starWord(wordId, classroomId, studySetId, userID),
      _updateStarredWords(key, starredWordsSet, wordId, isStarred),
    ]);

    appEventBus.fire(StarredWordsChangedEvent(starredWordsSet.length));
  }

  Future<void> removeWordFromAll(int wordId) async {
    await ensureInitialized();
    final userID = userProviderGlobal!.userId;
    await ApiService().starWordDeleteAll(wordId, userID);

    final futures = _prefs!.getKeys()
        .where((key) => key.startsWith(_keyPrefix))
        .map((key) => _removeWordFromSet(key, wordId));

    await Future.wait(futures);
  }

  Future<void> removeWordFromAllById(int wordId) async {
    await removeWordFromAll(wordId);
  }

  Future<Set<int>> loadStarredWords(int classroomId, int studySetId) async {
    await ensureInitialized();
    final key = _generateKey(classroomId, studySetId);
    return _getStarredWords(key);
  }

  Future<Set<int>> loadClassroomStarredWordsAll(int classroomId, List<int> studySetIds) async {
    await ensureInitialized();

    if (classroomId == -1) {
      return loadAllStarredWordsAll();
    }

    final allStarredWords = <int>{};
    for (final studySetId in studySetIds) {
      final key = _generateKey(classroomId, studySetId);
      final starredWords = await _getStarredWords(key);
      allStarredWords.addAll(starredWords);
    }

    return allStarredWords;
  }

  Future<Set<int>> loadAllStarredWordsAll() async {
    await ensureInitialized();
    final allStarredWords = Set<int>();

    for (String key in _prefs!.getKeys()) {
      if (key.startsWith(_keyPrefix)) {
        final starredWords = await _getStarredWords(key);
        allStarredWords.addAll(starredWords);
      }
    }

    return allStarredWords;
  }

  Future<void> printAllSharedPreferences() async {
    await ensureInitialized();
    final allKeys = _prefs!.getKeys();

    for (String key in allKeys) {
      var value = _prefs!.get(key);
      print('$key: $value');
    }
  }

  Future<Set<int>> _getStarredWords(String key) async {
    if (!_cache.containsKey(key)) {
      final List<String>? starredWordsStringList = _prefs!.getStringList(key);
      _cache[key] = starredWordsStringList?.map(int.parse).toSet() ?? {};
    }
    return _cache[key]!;
  }

  Future<void> _updateStarredWords(String key, Set<int> starredWords, int wordId, bool isStarred) async {
    if (isStarred) {
      starredWords.add(wordId);
    } else {
      starredWords.remove(wordId);
    }
    _cache[key] = starredWords;
    await _prefs!.setStringList(key, starredWords.map((id) => id.toString()).toList());
  }

  Future<void> _removeWordFromSet(String key, int wordId) async {
    final starredWords = await _getStarredWords(key);
    if (starredWords.remove(wordId)) {
      _cache[key] = starredWords;
      await _prefs!.setStringList(key, starredWords.map((id) => id.toString()).toList());
    }
  }

  String _generateKey(int classroomId, int studySetId) {
    return '${_keyPrefix}_classroomId:${classroomId}_studySetId:${studySetId}';
  }

  List<String>? _getStringListSafe(String key) {
    try {
      final dynamic value = _prefs!.get(key);
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