import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kelibu/shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'variables.dart';
import 'package:kelibu/Models/category.dart';
import 'package:kelibu/Models/Classroom.dart';
import 'package:kelibu/Models/studySet.dart';
import 'package:kelibu/Models/user.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'auth/device_info.dart';

// api_service.dart içinde en üst kısma ekleyin
class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? details;

  ApiException(this.message, {this.details});
}

class WordDataCache {
  static List<List<dynamic>>? _wordsData;
  static List<List<dynamic>>? _synonymsData;
  static List<List<dynamic>>? _collocationsData;
  static List<List<dynamic>>? _derivationsData;

  static Future<void> loadAllData() async {
    if (_wordsData == null) {
      print('Veri yükleme başladı');

      // 1. CSV dosyalarının içeriğini ana izolede okuyun
      final wordsCsvContent = await rootBundle.loadString('assets/Model/words.csv');
      final synonymsCsvContent = await rootBundle.loadString('assets/Model/synonyms.csv');
      final collocationsCsvContent = await rootBundle.loadString('assets/Model/collacations.csv');
      final derivationsCsvContent = await rootBundle.loadString('assets/Model/derivations.csv');

      // 2. CSV içeriklerini ayrı izolelerde işleyin
      _wordsData = await compute(parseCsvData, wordsCsvContent);
      _synonymsData = await compute(parseCsvData, synonymsCsvContent);
      _collocationsData = await compute(parseCsvData, collocationsCsvContent);
      _derivationsData = await compute(parseCsvData, derivationsCsvContent);

      print('Veri yükleme tamamlandı');
    }
  }

  // CSV verisini parse eden fonksiyon
  static List<List<dynamic>> parseCsvData(String csvContent) {
    return const CsvToListConverter(eol: '\n').convert(csvContent);
  }
}

class CsvLoader {
  Future<List<List<dynamic>>> loadCsv(String path) async {
    final csvFile = await rootBundle.loadString(path);
    List<List<dynamic>> csvList = const CsvToListConverter().convert(csvFile);
    return csvList;
  }
}

class WordDetailService {
  Future<List<WordDetail>> fetchWordsDetailsFromCsv(String filePath) async {
    final csvFile = await rootBundle.loadString(filePath);
    List<List<dynamic>> csvList = CsvToListConverter().convert(csvFile);

    List<WordDetail> allWords = csvList.sublist(1).map((csvRow) {
      return WordDetail(
        id: int.parse(csvRow[0]),
        word: csvRow[1],
        meaning: csvRow[2],
        image: csvRow[3],
        type: csvRow[4],
        collocations: [],
        derivations: [],
        synonyms: [],
      );
    }).toList();

    return allWords;
  }

  Future<List<WordDetail>> fetchWordsDetailFromCsvByWordIds(String filePath, List<int> wordIds) async {
    List<WordDetail> allWords = await fetchWordsDetailsFromCsv(filePath);
    List<WordDetail> filteredWords = allWords.where((word) => wordIds.contains(word.id)).toList();
    return filteredWords;
  }
}

class ApiService {
  final String baseUrl = 'https://kelibu.net/api';
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final DeviceService deviceService = DeviceService();

  Map<String, dynamic> _handleResponse(http.Response response) {
    return json.decode(response.body);
  }


  Future<Map<String, String>> _getHeaders() async {
    String? accessToken = await storage.read(key: 'access_token');
    String? tokenType = await storage.read(key: 'token_type');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Custom-Header': privacyKey.privacyKeyVariable,
    };

    if (accessToken != null && tokenType != null) {
      headers['Authorization'] = '$tokenType $accessToken';
    }

    return headers;
  }

  Future<bool> _isAccessTokenExpired() async {
    try {
      String? expiresAtStr = await storage.read(key: 'expires_at');
      if (expiresAtStr == null) return true;

      int expiresAtMillis = int.parse(expiresAtStr);
      DateTime expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMillis);
      return DateTime.now().isAfter(expiresAt);
    } catch (e) {
      print('Hata oluştu: $e');
      return true; // Hata durumunda token'ın süresi dolmuş kabul edilir
    }
  }

  Future<bool> _refreshAccessToken() async {
    try {
      print('refreshToken');

      String? refreshToken = await storage.read(key: 'refresh_token');
      String? deviceId = await deviceService.getDeviceId();

      if (refreshToken == null || deviceId == null) {
        print('Refresh token veya device ID bulunamadı');
        return false;
      }

      final url = Uri.parse('$baseUrl/auth/refresh-token');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'refresh_token': refreshToken,
          'device_id': deviceId,
        }),
      );
      print(response);

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        await storage.write(key: 'access_token', value: data['access_token']);
        await storage.write(key: 'refresh_token', value: data['refresh_token']);
        await storage.write(
          key: 'expires_at',
          value: (DateTime.now().millisecondsSinceEpoch + data['expires_in'] * 1000).toString(),
        );
        return true;
      } else {
        print('Token yenileme başarısız: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Token yenileme sırasında hata oluştu: $e');
      return false;
    }
  }
  Future<bool> _ensureTokenValidity() async {

    return true;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final deviceId = await deviceService.getDeviceId();

    final url = Uri.parse('$baseUrl/auth/register');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_id': deviceId,
      }),
    );

    if (response.statusCode == 201) {
      final data = _handleResponse(response);
      await storage.write(key: 'access_token', value: data['access_token']);
      await storage.write(key: 'refresh_token', value: data['refresh_token']);
      await storage.write(key: 'token_type', value: data['token_type']);
      await storage.write(key: 'expires_at', value: (DateTime.now().millisecondsSinceEpoch + data['expires_in'] * 1000).toString());

      return data;
    } else if (response.statusCode == 422) {
      throw Exception(json.decode(response.body)['errors']);
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await deviceService.getDeviceId();

    final url = Uri.parse('$baseUrl/auth/login');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_id': deviceId,
      }),
    );

    print('Login API Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = _handleResponse(response);
      await storage.write(key: 'access_token', value: data['access_token']);
      await storage.write(key: 'refresh_token', value: data['refresh_token']);
      await storage.write(key: 'token_type', value: data['token_type']);
      await storage.write(
        key: 'expires_at',
        value: (DateTime.now().millisecondsSinceEpoch + (data['expires_in'] * 1000)).toString(),
      );
      await storage.write(key: 'device_id', value: deviceId); // Cihaz ID'sini sakla

      print('Login successful: $data');

      return data;
    } else if (response.statusCode == 422 || response.statusCode == 401) {
      final errorData = _handleResponse(response);
      print('Login API Error Data: $errorData');
      throw ApiException(
        errorData['message'] ?? 'Geçersiz kimlik bilgileri.',
        details: errorData['errors'], // 'errors' alanını detay olarak ekle
      );
    } else {
      throw ApiException('API error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    bool tokenValid = await _ensureTokenValidity();
    if (!tokenValid) {
      throw Exception('Token yenileme başarısız. Lütfen tekrar giriş yapın.');
    }

    String? accessToken = await storage.read(key: 'access_token');
    if (accessToken == null) {
      throw Exception('Yeni access token alınamadı.');
    }

    // Backend'den gelen yeni 'expires_in' değerini kullanın
    String? expiresAtStr = await storage.read(key: 'expires_at');
    if (expiresAtStr != null) {
      int expiresAtMillis = int.parse(expiresAtStr);
      // Bu değeri kullanarak yeni 'expires_at' hesaplaması yapabilirsiniz.
    }

    return {
      'access_token': accessToken,
      'token_type': await storage.read(key: 'token_type'),
      'expires_in': 60 * 60 * 24 * 30, // 30 gün (saniye cinsinden)
    };
  }


  Future<bool> _refreshToken() async {
    String? refreshToken = await storage.read(key: 'refresh_token');
    String? deviceId = await deviceService.getDeviceId();

    if (refreshToken == null || deviceId == null) {
      return false;
    }

    final url = Uri.parse('$baseUrl/auth/refresh-token');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'refresh_token': refreshToken,
        'device_id': deviceId,
      }),
    );

    if (response.statusCode == 200) {
      final data = _handleResponse(response);
      await storage.write(key: 'access_token', value: data['access_token']);
      await storage.write(key: 'refresh_token', value: data['refresh_token']);
      int expiresAtMillis = DateTime.now().millisecondsSinceEpoch + 2592000000;
      await storage.write(key: 'expires_at', value: expiresAtMillis.toString());
      return true;
    } else {
      return false;
    }
  }


  Future<void> logout() async {
    try {
      final url = Uri.parse('$baseUrl/auth/logout');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
      );

      // Sunucu yanıtını kontrol et, ancak her durumda yerel verileri temizle
      if (response.statusCode == 200) {
        print('Sunucu tarafında başarılı çıkış');
      } else {
        print('Sunucu yanıtı: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Çıkış isteği gönderilirken hata: $e');
    } finally {

      // Her durumda yerel token ve ilgili verileri temizle
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
      await storage.delete(key: 'token_type');
      await storage.delete(key: 'expires_at');
      print('Yerel oturum verileri temizlendi');
    }
  }

  Future<Map<String, dynamic>> subscribe({
    required String receipt,
    required String productId,
    required String platform,

  }) async {
    final url = Uri.parse('$baseUrl/auth/subscription/subscribe');
    final headers = await _getHeaders();


    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'receipt': receipt,
        'product_id': productId,
        'platform' :platform,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    final url = Uri.parse('$baseUrl/subscription/cancel');
    final headers = await _getHeaders();

    bool tokenValid = await _ensureTokenValidity();
    if (!tokenValid) {
      throw Exception('Token yenileme başarısız. Lütfen tekrar giriş yapın.');
    }

    final response = await http.post(
      url,
      headers: headers,
    );

    return _handleResponse(response);
  }
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final url = Uri.parse('$baseUrl/auth/subscription/status');
    final headers = await _getHeaders();

    bool tokenValid = await _ensureTokenValidity();
    if (!tokenValid) {
      throw Exception('Token yenileme başarısız. Lütfen tekrar giriş yapın.');
    }

    final response = await http.get(
      url,
      headers: headers,
    );
    print('response');

    print(response.body);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> joinGroup(String code, String id) async {
    final url = Uri.parse('$baseUrl/join-group');
    final headers = await _getHeaders();

    bool tokenValid = await _ensureTokenValidity();
    if (!tokenValid) {
      throw Exception('Token yenileme başarısız. Lütfen tekrar giriş yapın.');
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'code': code,
        'user_id': id,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to join group',
      };
    }
  }
  Future<Map<String, dynamic>> getUsersCount() async {
    final url = Uri.parse('$baseUrl/getUsersCount');
    final headers = await _getHeaders();

    try {
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Kullanıcı sayısı alınamadı',
          'total_users': 0
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
        'total_users': 0
      };
    }
  }
  Future<Map<String, dynamic>> leaveGroup(String id) async {
    final url = Uri.parse('$baseUrl/join-group');
    final headers = await _getHeaders();

    bool tokenValid = await _ensureTokenValidity();
    if (!tokenValid) {
      throw Exception('Token yenileme başarısız. Lütfen tekrar giriş yapın.');
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'user_id': id,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'success': false,
        'message': 'Failed to join group',
      };
    }
  }

  Future<void> logSetEntry(String logType, String setName, String Category) async {
    try {
      await sendUserLog(
        type: logType,
        log: 'Kullanıcı "$setName" "$Category" giriş yaptı.',
      );
      print('Set giriş logu başarıyla gönderildi.');
    } catch (e) {
      print('Set giriş logu gönderilirken hata oluştu: $e');
    }
  }

  Future<void> sendUserLog({required String type, required String log}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('Kullanıcı ID bulunamadı.');
      }

      final url = Uri.parse('$baseUrl/users-logs');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'type': type,
          'log': log,
        }),
      );

      if (response.statusCode == 201) {
        print('Log başarıyla gönderildi.');
      } else {
        print('Log gönderilemedi. Durum Kodu: ${response.statusCode}');
        print('Yanıt: ${response.body}');
      }
    } catch (e) {
      print('Log gönderilirken hata oluştu: $e');
    }
  }

  Future<void> updateUserPoint(int userId, int newPoint) async {
    var url = Uri.parse('$baseUrl/user/$userId/updateUserPoint');
    var headers = await _getHeaders();

    var response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({'point': newPoint}),
    );

    if (response.statusCode == 200) {
      print('Kullanıcı puanı başarıyla güncellendi.');
    } else {
      print('Puan güncelleme başarısız: ${response.body}');
    }
  }

  Future<int> getCurrentUserPoints(int userId) async {
    try {
      var url = Uri.parse('$baseUrl/$userId/point');
      var headers = await _getHeaders();

      var response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['point'] ?? 0;
      } else {
        print('Failed to get current user points. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return 0;
      }
    } catch (e) {
      print('Error getting current user points: $e');
      return 0;
    }
  }

  Future<void> updateUserPointTimePeriod(int userId, int newPoint, int timePoint) async {
    try {
      print('Updating user point - UserID: $userId, New Point: $newPoint, Time Point: $timePoint');

      int currentPoints = await getCurrentUserPoints(userId);
      print('Current points: $currentPoints');

      if (newPoint <= 1) {
        print('New point is <= 1. Keeping current points.');
        newPoint = currentPoints;
      }

      if (newPoint < currentPoints) {
        print('Warning: New point ($newPoint) is less than current points ($currentPoints).');
      }

      var url = Uri.parse('$baseUrl/user/new/updateUserPoint');
      var headers = await _getHeaders();

      var response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'userId': userId,
          'point': newPoint,
          'timePoint': timePoint
        }),
      );

      if (response.statusCode == 200) {
        print('User point successfully updated. New point: $newPoint');
      } else {
        print('Failed to update user point. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error updating user point: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUserPoint(int userId) async {
    final String apiUrl = '$baseUrl/user-ranking';

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body) as Map<String, dynamic>;
        final rankings = userData['rankings'] as Map<String, dynamic>;

        print('API Response: ${json.encode(userData)}');
        print('Current Streak from API: ${userData['current_streak']}');

        return {
          'point': _parseInt(userData['point']),
          'avatar': userData['avatar'] ?? '',
          'dailyPoint': _parseInt(userData['daily_point']),
          'weeklyPoint': _parseInt(userData['weekly_point']),
          'monthlyPoint': _parseInt(userData['monthly_point']),
          'streakCount': _parseInt(userData['current_streak']),
          'dailyRank': _parseInt(rankings['daily_point']),
          'weeklyRank': _parseInt(rankings['weekly_point']),
          'monthlyRank': _parseInt(rankings['monthly_point']),
          'allTimeRank': _parseInt(rankings['point']),
          'team': userData['team'] ?? '',
          'city': userData['city'] ?? '',
        };
      } else {
        print('API isteği başarısız: ${response.statusCode}');
        print('Response body: ${response.body}');
        return _getDefaultUserData();
      }
    } catch (error) {
      print('API isteği sırasında hata oluştu: $error');
      return _getDefaultUserData();
    }
  }

// Güvenli bir şekilde integer'a dönüştürmek için yardımcı metod
  int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    } else {
      return 0;
    }
  }

  Map<String, dynamic> _getDefaultUserData() {
    return {
      'point': 0,
      'avatar': '',
      'dailyPoint': 0,
      'weeklyPoint': 0,
      'monthlyPoint': 0,
      'streakCount': 0,
      'dailyRank': 0,
      'weeklyRank': 0,
      'monthlyRank': 0,
      'allTimeRank': 0,
      'team': '',
      'city': '',
    };
  }

  Future<String> fetchPromotionMessage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final cacheKey = 'promotion_message';
    final lastFetchKey = 'last_fetch_date';
    final today = DateTime.now().toIso8601String().split('T')[0];

    String? cachedMessage = prefs.getString(cacheKey);
    String? lastFetchDate = prefs.getString(lastFetchKey);



      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/app-info'),
        headers: headers,
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final promotionMessage = data['description'];


        return promotionMessage;
      } else {
        throw Exception('Failed to load promotion message');
      }
      }


  Future<List<Package>> fetchCategories(int userId) async {

    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/user/packages?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> categoriesJson = json.decode(response.body);
        List<Package> categories = categoriesJson.map((json) => Package.fromJson(json)).toList();

        // Cache'e sadece başarılı bir şekilde veri çekildiğinde kaydedilir
        return categories;
      } else {
        throw Exception('Failed to load categories: ${response.body}');
      }
    } catch (e) {
      // Hata durumunda cache'den veri çekmeyi engelle
      throw Exception('Failed to load categories and cache fetching is disabled.');
    }
  }

  List<Package> removeDuplicateByText(List<Package> packages) {
    final seenTexts = <String>{};
    final uniquePackages = <Package>[];

    for (var package in packages) {
      if (package.text != null && !seenTexts.contains(package.text)) {
        seenTexts.add(package.text!);
        uniquePackages.add(package);
      }
    }

    return uniquePackages;
  }


  Future<int> fetchUserPoints(int userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$userId/points'),
      headers: headers,
    );
    print(response.body);
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['points'];
    } else {
      throw Exception('Puanlar yüklenemedi');
    }
  }

  Future<List<Word>> fetchWords(int classroomId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'words_$classroomId';

    try {
      // API'den veri çekmeyi dene
      final url = Uri.parse('$baseUrl/user/category/$classroomId');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // API'den veri başarıyla alındı
        await prefs.setString(key, response.body); // Cache'e kaydet
        return compute(_parseWords, response.body);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      // API'den veri alınamadı, cache'i kontrol et
      final cachedData = prefs.getString(key);
      if (cachedData != null) {
        return compute(_parseWords, cachedData);
      }
      // Cache'de de veri yoksa hatayı fırlat
      rethrow;
    }
  }
  List<Word> _parseWords(String responseBody) {
    final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Word>((json) => Word.fromJson(json)).toList();
  }

  Future<List<StudySet>> fetchStudySets(int classroomId, int wordId, String userid) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'studySets_${classroomId}_${wordId}_$userid';

    try {
      // Her zaman önce API'den veri çekmeyi dene
      var url = Uri.parse('$baseUrl/classroom/$classroomId/study-sets/$wordId/user/$userid');
      var headers = await _getHeaders();
      var response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        // API'den veri başarıyla alındı
        prefs.setString(key, response.body); // Cache'e kaydet
        List<dynamic> studySetsJson = json.decode(response.body);
        return studySetsJson.map((json) => StudySet.fromJson(json)).toList();
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      // API'den veri alınamadı, cache'i kontrol et
      final studySetsCached = prefs.getString(key);
      if (studySetsCached != null) {
        List<dynamic> studySetsJson = json.decode(studySetsCached);
        return studySetsJson.map((json) => StudySet.fromJson(json)).toList();
      }
      // Cache'de de veri yoksa hatayı fırlat
      rethrow;
    }
  }
  Future<List<Map<String, dynamic>>> fetchExampleSentences(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'exampleSentences_$term';

    try {
      final cachedData = prefs.getString(key);
      if (cachedData != null) {
        return compute(_parseExampleSentences, cachedData);
      }

      final url = Uri.parse('$baseUrl/example-sentences');
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'terim': term}),
      );

      if (response.statusCode == 200) {
        await prefs.setString(key, response.body);
        return compute(_parseExampleSentences, response.body);
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      final cachedData = prefs.getString(key);
      if (cachedData != null) {
        return compute(_parseExampleSentences, cachedData);
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _parseExampleSentences(String responseBody) {
    final parsed = jsonDecode(responseBody) as List;
    return parsed.cast<Map<String, dynamic>>();
  }

  Future<String> fetchStudySetsStar(int classroomId, int userId) async {
    var url = Uri.parse('$baseUrl/classroom/$classroomId/study-sets-star/$userId');
    var headers = await _getHeaders();
    var response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      print(response.body);
      String idString = jsonData.map((item) => item['word_id'].toString()).join(',');
      return idString;
    } else {
      throw Exception('Veri yüklenirken bir hata oluştu: ${response.body}');
    }
  }

  Future<List<User>> fetchUsers() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users-point'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      List<dynamic> usersJson = json.decode(response.body);
      return usersJson.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<List<User>> fetchUsersNew(String code, String period) async {
    final url = Uri.parse('$baseUrl/users-point-period');
    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'code': code,
        'period': period,
      }),
    );
    if (response.statusCode == 200) {
      List<dynamic> usersJson = json.decode(response.body);
      return usersJson.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }
  Future<Map<String, dynamic>> fetchInstitutionUsersPointPeriod(String userId, String period, bool isInstitutionMode) async {
    final url = Uri.parse('$baseUrl/institution-users-point-period');
    final headers = await _getHeaders();
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'period': period,
          'is_institution_mode': isInstitutionMode,
        }),
      );
      if (response.statusCode == 200) {
        var decodedResponse = json.decode(response.body);
        if (decodedResponse['has_institution'] == false && isInstitutionMode) {
          // Kurumsal mod istendi ama kullanıcının kurumu yok
          print('User does not have an institution, but institution mode was requested');
          return {
            'has_institution': false,
            'message': decodedResponse['message'],
            'users': [],
          };
        }
        return decodedResponse;
      } else {
        print('Server responded with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load users. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred while fetching users: $e');
      throw Exception('Failed to load users. Error: $e');
    }
  }
  Future<List<int>> fetchStarWords(int userId, dynamic studySetIds) async {
    var url = Uri.parse('$baseUrl/get-star-words');
    var headers = await _getHeaders();
    var response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        'user_id': userId,
        'study_set_ids': studySetIds is List ? studySetIds : [studySetIds],
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> starWordsJson = json.decode(response.body);
      return starWordsJson.map<int>((json) => json['word_id']).toList();
    } else {
      throw Exception('Yıldızlı kelimeler yüklenirken bir hata oluştu: ${response.body}');
    }
  }

  Future<List<WordDetail>> fetchStarWordsAll(int userId) async {
    var url = Uri.parse('$baseUrl/get-star-words-all');

    var headers = await _getHeaders();
    var response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      List<WordDetail> wordCards = jsonResponse.map((data) => WordDetail.fromJson(data)).toList();

      var uniqueWordCardsMap = { for (var card in wordCards) card.id: card };
      List<WordDetail> uniqueWordCards = uniqueWordCardsMap.values.toList();

      return uniqueWordCards;
    } else {
      throw Exception('Yıldızlı kelimeler yüklenirken bir hata oluştu: ${response.body}');
    }
  }

  Future<void> fetchStarWordsAllSystem(int userId) async {
    var url = Uri.parse('$baseUrl/starredwords');

    var headers = await _getHeaders();
    var response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        'userid': userId,
      }),
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      print('Response JSON: $jsonResponse');
      List<dynamic> starredWords = jsonResponse;
      final prefs = await SharedPreferences.getInstance();
      for (var word in starredWords) {
        try {
          int wordId = word['word_id'];
          int studySetId = word['study_set_id'];
          int categoryId = word['c_id'];

          String key = _generateKey(categoryId, studySetId);
          List<String>? existingWords = List<String>.from(_getStringListSafe(prefs, key) ?? []);

          if (!existingWords.contains(wordId.toString())) {
            existingWords.add(wordId.toString());
            await prefs.setStringList(key, existingWords);
          }
        } catch (e) {
          print('Error processing word: $word, error: $e');
        }
      }
    } else {
      throw Exception('Yıldızlı kelimeler yüklenirken bir hata oluştu: ${response.body}');
    }
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
  Future<List<WordDetail>> fetchWordsDetail(List<int> wordIds) async {
    await WordDataCache.loadAllData();
    print("Fetching details for ${wordIds.length} starred words");

    final words = _parseWordsDetail(wordIds);
    _attachSynonyms(words);
    _attachCollocations(words);
    _attachDerivations(words);

    print("Fetched ${words.length} word details");
    return words;
  }
  void _attachSynonyms(List<WordDetail> words) {
    for (var csvRow in WordDataCache._synonymsData!.sublist(1)) {
      final wordId = int.parse(csvRow[3]);
      final synonym = Synonym(
        id: int.parse(csvRow[0]),
        term: csvRow[1],
        tanim: csvRow[2],
        anlam: csvRow[5],
      );

      words.firstWhereOrNull((word) => word.id == wordId)?.synonyms.add(synonym);
    }
  }

  void _attachCollocations(List<WordDetail> words) {
    for (var csvRow in WordDataCache._collocationsData!.sublist(1)) {
      final wordId = int.parse(csvRow[3]);
      final collocation = Collocation(
        id: int.parse(csvRow[0]),
        term: csvRow[1],
        definition: csvRow[2],
        anlam: csvRow[8],
      );

      words.firstWhereOrNull((word) => word.id == wordId)?.collocations.add(collocation);
    }
  }

  void _attachDerivations(List<WordDetail> words) {
    for (var csvRow in WordDataCache._derivationsData!.sublist(1)) {
      final wordId = int.parse(csvRow[3]);
      final derivation = Derivation(
        id: int.parse(csvRow[0]),
        term: csvRow[1],
        definition: csvRow[2],
        type: csvRow[8],
        anlam: csvRow[9],
      );

      words.firstWhereOrNull((word) => word.id == wordId)?.derivations.add(derivation);
    }
  }

  List<WordDetail> _parseWordsDetail(List<int> wordIds) {
    return WordDataCache._wordsData!.sublist(1)
        .where((csvRow) => wordIds.contains(int.tryParse(csvRow[0].toString()) ?? 0))
        .map((csvRow) => WordDetail(
      id: int.parse(csvRow[0].toString()),
      word: csvRow[1].toString(),
      meaning: csvRow[2].toString(),
      image: csvRow.length > 3 ? csvRow[3]?.toString() : null,
      type: csvRow.length > 4 ? csvRow[4]?.toString() : null,
      collocations: [],
      derivations: [],
      synonyms: [],
    ))
        .toList();
  }

  Future<WordDetail?> searchWord(String term) async {
    await WordDataCache.loadAllData();

    term = term.trim().toLowerCase();

    var matchedWord = WordDataCache._wordsData!.sublist(1).firstWhereOrNull(
          (row) => row[1].toString().toLowerCase() == term,
    );

    if (matchedWord != null) {
      return WordDetail(
        id: int.parse(matchedWord[0].toString()),
        word: matchedWord[1].toString(),
        meaning: matchedWord[2].toString(),
        type: matchedWord.length > 4 ? matchedWord[4]?.toString() : null,
        image: matchedWord.length > 3 ? matchedWord[3]?.toString() : null,
        collocations: [],
        derivations: [],
        synonyms: [],
      );
    }

    return null;
  }

  Future<WordDetail> loadWordDetails(WordDetail word) async {
    await Future.wait([
      fetchAndAttachSynonymsToWordDetail([word]),
      fetchAndAttachCollocations([word]),
      fetchAndAttachDerivations([word]),
    ]);
    return word;
  }

  Future<WordDetail> fetchWordDetails(WordDetail word) async {
    await Future.wait([
      fetchAndAttachSynonymsToWordDetail([word]),
      fetchAndAttachCollocations([word]),
      fetchAndAttachDerivations([word]),
    ]);
    return word;
  }

  Future<void> _attachRelatedData(WordDetail word) async {
    final wordId = word.id;

    word.derivations = WordDataCache._derivationsData!.sublist(1)
        .where((row) => int.parse(row[3].toString()) == wordId)
        .map((row) => Derivation(
      id: int.parse(row[0].toString()),
      term: row[1].toString(),
      definition: row[2].toString(),
      type: row[8].toString(),
      anlam: row[9].toString(),
    ))
        .toList();
  }

  Future<void> fetchAndAttachRelatedData(List<WordDetail> words) async {
    final synonymsFilePath = 'assets/Model/synonyms.csv';
    final collocationsFilePath = 'assets/Model/collacations.csv';
    final derivationsFilePath = 'assets/Model/derivations.csv';

    final synonymsCsv = await rootBundle.loadString(synonymsFilePath);
    final collocationsCsv = await rootBundle.loadString(collocationsFilePath);
    final derivationsCsv = await rootBundle.loadString(derivationsFilePath);

    await Future.wait([
      compute(_parseSynonyms, [synonymsCsv, words]),
      compute(_parseCollocations, [collocationsCsv, words]),
      compute(_parseDerivations, [derivationsCsv, words]),
    ]);
  }

  Future<void> fetchAndAttachSynonymsToWordDetail(List<WordDetail> words) async {
    final synonymsFilePath = 'assets/Model/synonyms.csv';
    final csvFile = await rootBundle.loadString(synonymsFilePath);

    await compute(_parseSynonyms, [csvFile, words]);
  }

  void _parseSynonyms(List<dynamic> args) {
    final csvFile = args[0] as String;
    final words = args[1] as List<WordDetail>;

    final csvList = const CsvToListConverter(eol: '\n').convert(csvFile);

    for (var csvRow in csvList.sublist(1)) {
      final wordId = int.parse(csvRow[3]);
      final synonym = Synonym(
        id: int.parse(csvRow[0]),
        term: csvRow[1],
        tanim: csvRow[2],
        anlam: csvRow[5],
      );

      words.firstWhereOrNull((word) => word.id == wordId)?.synonyms.add(synonym);
    }
  }

  Future<void> fetchAndAttachCollocations(List<WordDetail> words) async {
    final collocationsFilePath = 'assets/Model/collacations.csv';
    final csvFile = await rootBundle.loadString(collocationsFilePath);

    await compute(_parseCollocations, [csvFile, words]);
  }

  void _parseCollocations(List<dynamic> args) {
    final csvFile = args[0] as String;
    final words = args[1] as List<WordDetail>;

    final csvList = const CsvToListConverter(eol: '\n').convert(csvFile);

    for (var csvRow in csvList.sublist(1)) {
      final wordId = int.parse(csvRow[3]);
      final collocation = Collocation(
        id: int.parse(csvRow[0]),
        term: csvRow[1],
        definition: csvRow[2],
        anlam: csvRow[8],
      );

      words.firstWhereOrNull((word) => word.id == wordId)?.collocations.add(collocation);
    }
  }

  Future<void> fetchAndAttachDerivations(List<WordDetail> words) async {
    final derivationsFilePath = 'assets/Model/derivations.csv';
    final csvFile = await rootBundle.loadString(derivationsFilePath);

    await compute(_parseDerivations, [csvFile, words]);
  }

  void _parseDerivations(List<dynamic> args) {
    final csvFile = args[0] as String;
    final words = args[1] as List<WordDetail>;

    final csvList = const CsvToListConverter(eol: '\n').convert(csvFile);

    for (var csvRow in csvList.sublist(1)) {
      final wordId = int.parse(csvRow[3]);
      final derivation = Derivation(
        id: int.parse(csvRow[0]),
        term: csvRow[1],
        definition: csvRow[2],
        type: csvRow[8],
        anlam: csvRow[9],
      );

      words.firstWhereOrNull((word) => word.id == wordId)?.derivations.add(derivation);
    }
  }

  Future<bool> deleteUser(int userId) async {
    print(userId);
    var url = Uri.parse('$baseUrl/user/$userId');
    var headers = await _getHeaders();

    final response = await http.delete(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      print('User deleted successfully');
      return true;
    } else {
      print('Failed to delete user: ${response.body}');
      return false;
    }
  }

  Future<void> syncStarredWordsWithServer(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    List<Map<String, dynamic>> dataToSend = [];

    for (String key in keys) {
      if (key.startsWith('starredWords')) {
        List<String>? starredWordsList = prefs.getStringList(key);
        if (starredWordsList != null) {
          var parts = key.split('_');
          if (parts.length >= 3) {
            int? categoryId = int.tryParse(RegExp(r'\d+').firstMatch(parts[1])?.group(0) ?? '');
            int? studySetId = int.tryParse(RegExp(r'\d+').firstMatch(parts[2])?.group(0) ?? '');

            if (categoryId != null && studySetId != null) {
              dataToSend.add({
                'c_id': categoryId,
                'study_set_id': studySetId,
                'words': starredWordsList
              });
            }
          }
        }
      }
    }

    var url = Uri.parse('$baseUrl/sync_starred_words');
    var headers = await _getHeaders();

    var response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        "user_id": userId,
        "starred_words": dataToSend
      }),
    );

    if (response.statusCode == 200) {
      print("Starred words synced successfully");
      print("Raw response: ${response.body}");  // Ham yanıtı yazdır
      updateSharedPreferences(json.decode(response.body)['starred_words']);
      print(json.decode(response.body)['starred_words']);
    } else {
      print("Failed to sync starred words: ${response.body}");
    }
  }

  void updateSharedPreferences(List<dynamic> starredWords) async {
    final prefs = await SharedPreferences.getInstance();
    for (var wordData in starredWords) {
      String key = _generateKey(wordData['c_id'], wordData['study_set_id']);
      if (wordData['words'] != null && wordData['words'].isNotEmpty) {
        List<String> wordIds = (wordData['words'] as List).map((w) => w.toString()).toList();
        await prefs.setStringList(key, wordIds);
      }
    }
  }
  String _generateKey(int classroomId, int studySetId) {
    return 'starredWords_classroomId:${classroomId}_studySetId:${studySetId}';
  }

  Future<List<WordDetail>> fetchWordsDetailStar(int classroomId, List<int> studySetId) async {
    final service = StarredWordsService();
    final starredWordIds = await service.loadClassroomStarredWordsAll(classroomId, studySetId);
    return fetchWordsDetail(starredWordIds.toList());
  }

  Future<bool> checkStarred(int wordId, int studySetId, int userId) async {
    var url = Uri.parse('$baseUrl/check-starred?word_id=$wordId&study_set_id=$studySetId&user_id=$userId');
    var headers = await _getHeaders();
    var response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['isStarred'];
    } else {
      throw Exception('Yıldızlanma durumunu kontrol ederken bir hata oluştu: ${response.body}');
    }
  }

  Future<void> starWord(int wordId, int categoryID, int studySetID, int userID) async {
    var url = Uri.parse('$baseUrl/star-word');
    var headers = await _getHeaders();
    var response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        'word_id': wordId,
        'userid': userID,
        'category_id': categoryID,
        'study_set_id': studySetID,
      }),
    );
    print(response.body);
    if (response.statusCode != 200) {
      throw Exception('Yıldızlama işlemi sırasında bir hata oluştu: ${response.body}');
    }
  }

  Future<void> starWordDeleteAll(int wordId, int userID) async {
    var url = Uri.parse('$baseUrl/star-word-star-delete');
    var headers = await _getHeaders();
    var response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        'word_id': wordId,
        'userid': userID,
      }),
    );
    print(response.body);
    if (response.statusCode != 200) {
      throw Exception('Yıldızlama işlemi sırasında bir hata oluştu: ${response.body}');
    }
  }

  Future<void> starWordDelete(int wordId, int categoryID, int studySetID, int userID) async {
    var url = Uri.parse('$baseUrl/star-word-star');
    var headers = await _getHeaders();
    var response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        'word_id': wordId,
        'userid': userID,
        'category_id': categoryID,
        'study_set_id': studySetID,
      }),
    );
    print(response.body);
    if (response.statusCode != 200) {
      throw Exception('Yıldızlama işlemi sırasında bir hata oluştu: ${response.body}');
    }
  }

  Future<Map<int, bool>> checkStarredBulk(List<int> wordIds, int studySetId, int userId) async {
    var url = Uri.parse('$baseUrl/check-starred-bulk');
    var headers = await _getHeaders();
    var body = jsonEncode({
      'word_ids': wordIds,
      'study_set_id': studySetId.toString(),
      'user_id': userId.toString(),
    });

    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (true) {
      try {
        var response = await http.post(url, headers: headers, body: body);
        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          var isStarredMap = (data['isStarred'] as Map<String, dynamic>)
              .map<int, bool>((key, value) => MapEntry(int.parse(key), value));
          return isStarredMap;
        } else if (response.statusCode == 429 && retryCount < maxRetries) {
          retryCount++;
          print('Request rate limit reached, retrying... Attempt: $retryCount');
          await Future.delayed(retryDelay);
          continue;
        } else {
          print('Request failed with status: ${response.statusCode}.');
          print('Response body: ${response.body}');
          throw Exception('Request failed: ${response.body}');
        }
      } catch (e) {
        if (retryCount >= maxRetries) {
          throw Exception('Failed after $maxRetries retries.');
        }
        retryCount++;
        print('An error occurred, retrying... Attempt: $retryCount');
        await Future.delayed(retryDelay);
      }
    }
  }

  Map<String, dynamic> _parseJson(String responseBody) {
    return json.decode(responseBody) as Map<String, dynamic>;
  }

  Future<Map<String, List<String>>> fetchExampleSentencesBulk(List<String> terms) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'exampleSentencesBulk_${terms.join("_")}';
    final exampleSentencesCached = prefs.getString(key);

    if (exampleSentencesCached != null) {
      Map<String, dynamic> data = json.decode(exampleSentencesCached);
      return data.map<String, List<String>>((key, value) {
        var sentences = (value as List<dynamic>).map((item) => item.toString()).toList();
        return MapEntry(key, sentences);
      });
    } else {
      var url = Uri.parse('$baseUrl/example-sentences-word');
      var headers = await _getHeaders();
      var response = await http.post(
        url,
        headers: headers,
        body: json.encode({
          'terimler': terms,
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = await compute(_parseJson, response.body);
        Map<String, List<String>> sentencesMap = data.map<String, List<String>>((key, value) {
          var sentences = (value as List).map<String>((item) => item['cumle'].toString()).toList();
          return MapEntry(key, sentences);
        });
        prefs.setString(key, json.encode(sentencesMap));
        return sentencesMap;
      } else {
        throw Exception('Data could not be fetched: ${response.statusCode}');
      }
    }
  }
}
