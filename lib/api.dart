import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kelibu/Models/Classroom.dart';
import 'package:kelibu/Models/category.dart' as kelibu; // rename
import 'package:kelibu/Models/product.dart';
import 'package:kelibu/Models/studySet.dart';
import 'package:kelibu/Models/user.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:kelibu/shared_preferences/shared_preferences.dart';
import 'package:kelibu/variables.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart' as sp_pkg;
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/device_info.dart';
import 'Models/announcement.dart';

//-----------------------------------------------------
// ÖRNEK API EXCEPTION
//-----------------------------------------------------
class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? details;

  ApiException(this.message, {this.details});
}

//-----------------------------------------------------
// CSV İLE İLGİLİ CACHE / YÜKLEME YAPISI
//-----------------------------------------------------
class WordDataCache {
  static List<List<dynamic>>? _wordsData;
  static List<List<dynamic>>? _synonymsData;
  static List<List<dynamic>>? _collocationsData;
  static List<List<dynamic>>? _derivationsData;

  static Future<void> loadAllData() async {
    if (_wordsData == null) {
      print('Veri yükleme başladı');

      final wordsCsvContent = await rootBundle.loadString('assets/Model/words.csv');
      final synonymsCsvContent = await rootBundle.loadString('assets/Model/synonyms.csv');
      final collocationsCsvContent = await rootBundle.loadString('assets/Model/collacations.csv');
      final derivationsCsvContent = await rootBundle.loadString('assets/Model/derivations.csv');

      _wordsData = await compute(parseCsvData, wordsCsvContent);
      _synonymsData = await compute(parseCsvData, synonymsCsvContent);
      _collocationsData = await compute(parseCsvData, collocationsCsvContent);
      _derivationsData = await compute(parseCsvData, derivationsCsvContent);

      print('Veri yükleme tamamlandı');
    }
  }

  static List<List<dynamic>> parseCsvData(String csvContent) {
    return const CsvToListConverter(eol: '\n').convert(csvContent);
  }
}

class CsvLoader {
  Future<List<List<dynamic>>> loadCsv(String path) async {
    final csvFile = await rootBundle.loadString(path);
    return const CsvToListConverter().convert(csvFile);
  }
}

class WordDetailService {
  Future<List<WordDetail>> fetchWordsDetailsFromCsv(String filePath) async {
    final csvFile = await rootBundle.loadString(filePath);
    List<List<dynamic>> csvList = const CsvToListConverter().convert(csvFile);

    List<WordDetail> allWords = csvList.sublist(1).map((csvRow) {
      return WordDetail(
        id: int.parse(csvRow[0]),
        word: csvRow[1],
        meaning: csvRow[2],
        image: csvRow[3],
        type: csvRow[4],
        defination:csvRow[4] ,
        collocations: [],
        derivations: [],
        synonyms: [],
      );
    }).toList();

    return allWords;
  }

  Future<List<WordDetail>> fetchWordsDetailFromCsvByWordIds(String filePath, List<int> wordIds) async {
    List<WordDetail> allWords = await fetchWordsDetailsFromCsv(filePath);
    return allWords.where((word) => wordIds.contains(word.id)).toList();
  }
}

//-----------------------------------------------------
// CUSTOM DIO RETRY INTERCEPTOR (HARİCİ PAKET YOK)
//-----------------------------------------------------
class DioRetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;

  DioRetryInterceptor({
    required this.dio,
    this.retries = 3,
    List<Duration>? retryDelays,
  }) : retryDelays = retryDelays ??
      const [Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 3)];

  @override
  Future<void> onError(DioError err, ErrorInterceptorHandler handler) async {
    final RequestOptions requestOptions = err.requestOptions;
    int currentRetryCount = requestOptions.extra["retryCount"] ?? 0;

    // Bu örnekte 'connectionError', 'sendTimeout', 'receiveTimeout', 'unknown' tiplerinde retry deniyoruz
    if (_shouldRetry(err) && currentRetryCount < retries) {
      currentRetryCount++;
      final delay = retryDelays.length >= currentRetryCount
          ? retryDelays[currentRetryCount - 1]
          : retryDelays.last;

      requestOptions.extra["retryCount"] = currentRetryCount;

      print("[DioRetryInterceptor] Retry attempt: $currentRetryCount");

      await Future.delayed(delay);

      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(e as DioError);
      }
    }

    // Retry yok veya bitti ise normal hatayı dön
    return handler.next(err);
  }

  bool _shouldRetry(DioError err) {
    // İstediğiniz hata tiplerinde retry yapabilirsiniz
    if (err.type == DioErrorType.connectionError ||
        err.type == DioErrorType.sendTimeout ||
        err.type == DioErrorType.receiveTimeout ||
        err.type == DioErrorType.unknown) {
      return true;
    }
    return false;
  }
}

//-----------------------------------------------------
// INTERCEPTOR: TOKEN YÖNETİMİ
//-----------------------------------------------------
class TokenInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio dioInstance;

  TokenInterceptor({
    required this.storage,
    required this.dioInstance,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Her istekte Header'a token ekliyoruz
    final token = await storage.read(key: 'access_token');
    final tokenType = await storage.read(key: 'token_type') ?? 'Bearer';

    options.headers['Content-Type'] = 'application/json';
    // Eğer özel bir header gerekiyorsa ekleyin
    options.headers['X-Custom-Header'] = privacyKey.privacyKeyVariable;

    if (token != null) {
      options.headers['Authorization'] = '$tokenType $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    // 401 ise token yenileme deneyelim
    if (err.response?.statusCode == 401) {
      print('401 hatası alındı, token yenilenmeye çalışılıyor.');
      final refreshSuccess = await _refreshToken();
      if (refreshSuccess) {
        // Token yenilendikten sonra isteği tekrar dene
        try {
          final newResponse = await dioInstance.fetch(err.requestOptions);
          return handler.resolve(newResponse);
        } catch (e) {
          return handler.next(err);
        }
      }
    }
    return handler.next(err);
  }

  Future<bool> _refreshToken() async {
    print('TokenInterceptor -> _refreshToken çağrıldı');
    String? refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      print('refresh_token yok, yenileme yapılamadı');
      return false;
    }

    try {
      final deviceService = DeviceService();
      final deviceId = await deviceService.getDeviceId();
      if (deviceId == null) {
        print('Cihaz ID bulunamadı, token yenileme iptal');
        return false;
      }

      final response = await dioInstance.post(
        '/auth/refresh-token',
        data: {
          'refresh_token': refreshToken,
          'device_id': deviceId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        await storage.write(key: 'access_token', value: data['access_token']);
        await storage.write(key: 'refresh_token', value: data['refresh_token']);
        await storage.write(key: 'token_type', value: data['token_type'] ?? 'Bearer');

        final expiresIn = data['expires_in'] ?? 0;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await storage.write(key: 'expires_at', value: (nowMs + expiresIn * 1000).toString());

        print('Token yenileme başarılı');
        return true;
      } else {
        print('Token yenileme başarısız -> ${response.data}');
        return false;
      }
    } catch (e) {
      print('Token yenileme isteğinde hata: $e');
      return false;
    }
  }
}

//-----------------------------------------------------
// INTERCEPTOR: OFFLINE / CACHE YÖNETİMİ (ÖRNEK)
//-----------------------------------------------------
class OfflineCacheInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Burada ister internet bağlantısını kontrol edin, ister Hive'dan cache'e bakın.
    // Projenize göre özelleştirin
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Örnek: başarılı yanıtı Hive'a veya SharedPreferences'a kaydedebiliriz
    return handler.next(response);
  }
}

//-----------------------------------------------------
// API SERVICE (DIO İLE)
//-----------------------------------------------------
class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final DeviceService deviceService = DeviceService();
  static const String LAST_SYNC_KEY = 'last_subscription_sync';

  ApiService() {
    // Dio ayarları
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://kelibu.net/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // (Opsiyonel) Debug moddaysanız kendinden imzalı sertifikayı bypass etmek için:
    if (!kReleaseMode) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }

    // Interceptor: Token
    _dio.interceptors.add(
      TokenInterceptor(
        storage: storage,
        dioInstance: _dio,
      ),
    );

    // Interceptor: Kendi yazdığımız Retry Interceptor (DioRetryInterceptor)
    _dio.interceptors.add(
      DioRetryInterceptor(
        dio: _dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );

    // Interceptor: Offline cache (örnek)
    _dio.interceptors.add(OfflineCacheInterceptor());
  }

  //-----------------------------------------------------
  // ÖRNEK HELPER METOTLAR
  //-----------------------------------------------------
  Map<String, dynamic> _handleResponse(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data;
    } else if (response.data is String) {
      return json.decode(response.data);
    } else {
      return {};
    }
  }


  Future<void> logout() async {
    try {
      final response = await _dio.post('/auth/logout');
      if (response.statusCode == 200) {
        print('Sunucu tarafında başarılı çıkış');
      } else {
        print('Sunucu yanıtı: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Çıkış isteği gönderilirken hata: $e');
    } finally {
      // Mevcut token verilerini temizle
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
      await storage.delete(key: 'token_type');
      await storage.delete(key: 'expires_at');

      // Tüm SharedPreferences verilerini temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('Tüm oturum verileri ve SharedPreferences temizlendi');
    }
  }

  //-----------------------------------------------------
  // KULLANICI KAYIT / LOGIN
  //-----------------------------------------------------
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final deviceId = await deviceService.getDeviceId();
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_id': deviceId,
      },
    );

    if (response.statusCode == 201) {
      final data = _handleResponse(response);
      await storage.write(key: 'access_token', value: data['access_token']);
      await storage.write(key: 'refresh_token', value: data['refresh_token']);
      await storage.write(key: 'token_type', value: data['token_type']);
      await storage.write(
        key: 'expires_at',
        value: (DateTime.now().millisecondsSinceEpoch + data['expires_in'] * 1000).toString(),
      );
      return data;
    } else if (response.statusCode == 422) {
      throw Exception(response.data['errors']);
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.data}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String fcmToken, // fcm_token parametresini ekledik
  }) async {
    try {
      final deviceId = await deviceService.getDeviceId();
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'device_id': deviceId,
          'fcm_token': fcmToken, // fcm_token sunucuya gönderiliyor
        },
      );

      // Hata durumlarını kontrol ediyoruz
      if (response.statusCode == 401) {
        throw ApiException('Geçersiz e-posta veya şifre.');
      }

      if (response.statusCode == 422) {
        final errorData = response.data;
        throw ApiException(
          errorData['message'] ?? 'Giriş bilgilerini kontrol ediniz.',
          details: errorData['errors'],
        );
      }

      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw ApiException('Beklenmeyen bir hata oluştu: ${response.statusCode}');
      }

      // Başarılı yanıtı işleyelim
      final data = _handleResponse(response);
      if (data['error'] == 'invalid_credentials') {
        throw ApiException('Geçersiz e-posta veya şifre.');
      }

      await _saveTokens(data, deviceId);
      await _handleRevenueCatLogin(data);
      return data;

    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException('Geçersiz e-posta veya şifre.');
      }
      if (e.response?.statusCode == 422) {
        final errorData = e.response?.data;
        throw ApiException(
          errorData?['message'] ?? 'Giriş bilgilerini kontrol ediniz.',
          details: errorData?['errors'],
        );
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    }
  }


  Future<void> _saveTokens(Map<String, dynamic> data, String deviceId) async {
    await storage.write(key: 'access_token', value: data['access_token']);
    await storage.write(key: 'refresh_token', value: data['refresh_token']);
    await storage.write(key: 'token_type', value: data['token_type']);
    await storage.write(
      key: 'expires_at',
      value: (DateTime.now().millisecondsSinceEpoch + (data['expires_in'] * 1000)).toString(),
    );
    await storage.write(key: 'device_id', value: deviceId);
  }

  Future<void> _handleRevenueCatLogin(Map<String, dynamic> data) async {
    if (data['user'] != null && data['user']['id'] != null) {
      try {
        final userId = data['user']['id'].toString();
        await Purchases.logIn(userId);
        await Purchases.setAttributes({
          'email': data['user']['email'],
          'name': data['user']['name'],
          'phone': data['user']['phone'],
          'created_at': data['user']['created_at'],
          'user_type': 'premium',
          'platform': Platform.isIOS ? 'ios' : 'android',
        });
        print('RevenueCat login ve attribute ataması yapıldı: $userId');
      } catch (e) {
        print('RevenueCat login hatası: $e');
      }
    }
  }

  //-----------------------------------------------------
  // ABONELİK / REVENUECAT / LEGACY
  //-----------------------------------------------------
  Future<Map<String, dynamic>> subscribe({
    required String receipt,
    required String productId,
    required String platform,
  }) async {
    final response = await _dio.post(
      '/auth/subscription/subscribe',
      data: {
        'receipt': receipt,
        'product_id': productId,
        'platform': platform,
      },
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    final response = await _dio.post('/subscription/cancel');
    return _handleResponse(response);
  }

  /// Eski sistem üzerinden abonelik statüsü
  Future<Map<String, dynamic>> _getLegacySubscriptionStatus() async {
    final response = await _dio.get('/auth/subscription/status');
    print('Legacy sistem response: ${response.data}');
    return _handleResponse(response);
  }

  /// RevenueCat üzerinden abonelik statüsü
  Future<Map<String, dynamic>> _getRevenuecatSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return {
        'is_vip': customerInfo.entitlements.active.isNotEmpty,
        'status': customerInfo.entitlements.active.isNotEmpty ? 'active' : 'inactive'
      };
    } catch (e) {
      print('RevenueCat check error: $e');
      return {'is_vip': false, 'status': 'inactive'};
    }
  }

  Future<bool> _isRevenuecatAvailable() async {
    try {
      await Purchases.getCustomerInfo();
      return true;
    } catch (e) {
      print('RevenueCat kullanılabilir değil: $e');
      return false;
    }
  }

  /// Tek noktadan abonelik durumu
  Future<Map<String, dynamic>> getCombinedSubscriptionStatus() async {
    bool revIsVip = false;
    bool legacyIsVip = false;
    bool isManual = false;

    // RevenueCat
    try {
      final revStatus = await _getRevenuecatSubscriptionStatus();
      revIsVip = revStatus['is_vip'] ?? false;
    } catch (_) {
      revIsVip = false;
    }

    // Legacy
    try {
      final legacyStatus = await _getLegacySubscriptionStatus();
      legacyIsVip = legacyStatus['is_vip'] ?? false;
      String? productId = legacyStatus['product_id']?.toString().toLowerCase();
      isManual = productId?.contains('manual') ?? false;
    } catch (_) {
      legacyIsVip = false;
      isManual = false;
    }

    bool isVip = revIsVip || legacyIsVip;
    return {
      'is_vip': isVip,
      'status': isVip ? 'active' : 'inactive',
      'is_manual': isManual,
    };
  }

  //-----------------------------------------------------
  // GRUP İŞLEMLERİ
  //-----------------------------------------------------
  Future<Map<String, dynamic>> joinGroup(String code, String id) async {
    final response = await _dio.post(
      '/join-group',
      data: {'code': code, 'user_id': id},
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      return {'success': false, 'message': 'Failed to join group'};
    }
  }

  Future<Map<String, dynamic>> leaveGroup(String id) async {
    final response = await _dio.post(
      '/join-group',
      data: {'user_id': id},
    );
    if (response.statusCode == 200) {
      return response.data;
    } else {
      return {'success': false, 'message': 'Failed to leave group'};
    }
  }

  Future<Map<String, dynamic>> getUsersCount() async {
    try {
      final response = await _dio.get('/getUsersCount');
      if (response.statusCode == 200) {
        return response.data;
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

  //-----------------------------------------------------
  // LOG İŞLEMLERİ
  //-----------------------------------------------------
  Future<void> logSetEntry(String logType, String setName, String category) async {
    try {
      await sendUserLog(
        type: logType,
        log: 'Kullanıcı "$setName" "$category" giriş yaptı.',
      );
      print('Set giriş logu başarıyla gönderildi.');
    } catch (e) {
      print('Set giriş logu gönderilirken hata: $e');
    }
  }

  Future<void> sendUserLog({required String type, required String log}) async {
    try {
      final prefs = await sp_pkg.SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) throw Exception('Kullanıcı ID bulunamadı.');

      final response = await _dio.post(
        '/users-logs',
        data: {
          'user_id': userId,
          'type': type,
          'log': log,
        },
      );

      if (response.statusCode == 201) {
        print('Log başarıyla gönderildi.');
      } else {
        print('Log gönderilemedi. Durum Kodu: ${response.statusCode}');
        print('Yanıt: ${response.data}');
      }
    } catch (e) {
      print('Log gönderilirken hata oluştu: $e');
    }
  }

  //-----------------------------------------------------
  // KULLANICI PUAN İŞLEMLERİ (OFFLINE DESTEĞİYLE)
  //-----------------------------------------------------

  /// Mevcut puanı öğrenmek için
  Future<int> getCurrentUserPoints(int userId) async {
    try {
      final response = await _dio.get('/$userId/point');
      if (response.statusCode == 200) {
        return response.data['point'] ?? 0;
      } else {
        print('Failed to get current user points. Status code: ${response.statusCode}');
        print('Response body: ${response.data}');
        return 0;
      }
    } catch (e) {
      print('Error getting current user points: $e');
      return 0;
    }
  }

  /// Online puan güncelleme (basit örnek)
  Future<void> updateUserPoint(int userId, int newPoint) async {
    try {
      await _dio.put('/user/$userId/updateUserPoint', data: {'point': newPoint});
      print('Kullanıcı puanı başarıyla güncellendi.');
    } catch (e) {
      print('Puan güncelleme başarısız: $e');
    }
  }

  /// Offline/Online entegre puan güncellemesi
  ///
  /// - İnternet yoksa puan yerel cache'e kaydedilir.
  /// - İnternet gelince senkronize edilir (`syncPendingUpdates`).
  /// - timePoint parametresi de veritabanına gönderilir.
  Future<void> updateUserPointTimePeriod(int userId, int newPoint, int timePoint) async {
    try {
      final box = await Hive.openBox('pointUpdateCache');
      try {
        final response = await _dio.post('/user/new/updateUserPoint', data: {
          'userId': userId,
          'point': newPoint,
          'timePoint': timePoint,
        });
        if (response.statusCode == 200) {
          await box.delete('lastPoint_$userId');
          print('Point updated successfully');
        }
      } on DioError catch (e) {
        if (e.type == DioErrorType.connectionError || e.type == DioErrorType.unknown) {
          // İnternet yoksa cache'e kaydet
          await box.put('lastPoint_$userId', {
            'point': newPoint,
            'timePoint': timePoint,
            'timestamp': DateTime.now().toIso8601String(),
          });
          print('İnternet yok, puan offline kaydedildi');
          return;
        }
        rethrow;
      }
    } catch (e) {
      print('Error updating user point: $e');
    }
  }

  /// Uygulama açıldığında bekleyen güncellemeler varsa senkronize et
  Future<void> syncPendingUpdates() async {
    final box = await Hive.openBox('pointUpdateCache');
    final pendingKeys = box.keys.where((k) => k.toString().startsWith('lastPoint_'));

    for (final key in pendingKeys) {
      final update = box.get(key);
      if (update != null) {
        try {
          final userId = int.parse(key.toString().split('_')[1]);
          final newPoint = update['point'];
          final timePoint = update['timePoint'];

          await _dio.post('/user/new/updateUserPoint', data: {
            'userId': userId,
            'point': newPoint,
            'timePoint': timePoint,
          });
          await box.delete(key);
          print('Pending update senkronize edildi: $userId');
        } catch (e) {
          print('Sync failed for $key: $e');
        }
      }
    }
  }

  //-----------------------------------------------------
  // KULLANICI RANK / PUAN BİLGİSİ
  //-----------------------------------------------------
  Future<Map<String, dynamic>> fetchUserPoint(int userId) async {
    try {
      final response = await _dio.post('/user-ranking', data: {'user_id': userId});
      if (response.statusCode == 200) {
        final userData = response.data;
        final rankings = userData['rankings'] as Map<String, dynamic>;

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
        return _getDefaultUserData();
      }
    } catch (error) {
      print('API isteği sırasında hata oluştu: $error');
      return _getDefaultUserData();
    }
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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

  //-----------------------------------------------------
  // TANITIM MESAJI
  //-----------------------------------------------------
  Future<String> fetchPromotionMessage() async {
    final sharedPrefs = await sp_pkg.SharedPreferences.getInstance();
    final response = await _dio.get('/app-info');
    if (response.statusCode == 200) {
      final data = response.data;
      return data['description'] ?? '';
    } else {
      throw Exception('Failed to load promotion message');
    }
  }

  //-----------------------------------------------------
  // KATEGORİ / PRODUCT LİSTELERİ
  //-----------------------------------------------------
  Future<List<kelibu.Package>> fetchCategories(int userId) async {
    try {
      final response = await _dio.get('/user/packages?user_id=$userId');
      if (response.statusCode == 200) {
        List<dynamic> categoriesJson = response.data;
        return categoriesJson.map((json) => kelibu.Package.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to load categories. Error: $e');
    }
  }
  List<Product>? _cachedProducts;
  DateTime? _lastFetchTime;
  final Duration _cacheValidity = Duration(minutes: 60);

  Future<List<Product>> fetchActiveProducts() async {
    // Önbellekteki veri hala geçerliyse, hemen döndür
    if (_cachedProducts != null && _lastFetchTime != null) {
      final difference = DateTime.now().difference(_lastFetchTime!);
      if (difference < _cacheValidity) {
        return _cachedProducts!;
      }
    }

    try {
      // Paralel işlemleri optimize etmek için compute kullanabiliriz
      final response = await _dio.post('/user/products-active');
      if (response.statusCode == 200) {
        // JSON işlemini ana thread'de yapalım - compute kullanmıyoruz
        final List<dynamic> productsJson = response.data;
        final products = productsJson.map((json) => Product.fromJson(json)).toList();

        // Önbelleğe alalım
        _cachedProducts = products;
        _lastFetchTime = DateTime.now();

        return products;
      } else {
        // Önbellekte veri varsa ve API yanıt vermezse, eski veriyi kullanabiliriz
        if (_cachedProducts != null) {
          return _cachedProducts!;
        }
        throw Exception('Failed to load products: ${response.data}');
      }
    } catch (e) {
      // Hata durumunda da önbellekteki veriyi kullanabiliriz
      if (_cachedProducts != null) {
        return _cachedProducts!;
      }
      throw Exception(e.toString());
    }
  }


// Ayrı bir isolate'te çalıştırılacak parse fonksiyonu
List<Product> _parseProducts(List<dynamic> productsJson) {
  return productsJson.map((json) => Product.fromJson(json)).toList();
}

  List<kelibu.Package> removeDuplicateByText(List<kelibu.Package> packages) {
    final seenTexts = <String>{};
    final uniquePackages = <kelibu.Package>[];

    for (var package in packages) {
      if (package.text != null && !seenTexts.contains(package.text)) {
        seenTexts.add(package.text!);
        uniquePackages.add(package);
      }
    }
    return uniquePackages;
  }

  //-----------------------------------------------------
  // WORD / STUDYSET İŞLEMLERİ
  //-----------------------------------------------------
  final Map<int, List<Word>> _memoryCache = {};
  final Map<int, DateTime> _lastFetchTimes = {};
  Future<List<Word>> fetchWords(int classroomId) async {
    // 1. Önce bellek içi önbelleği kontrol et (en hızlı erişim)
    if (_memoryCache.containsKey(classroomId) && _lastFetchTimes.containsKey(classroomId)) {
      final lastFetch = _lastFetchTimes[classroomId]!;
      if (DateTime.now().difference(lastFetch) < _cacheValidity) {
        print('Bellek önbelleğinden kelimeler alınıyor: $classroomId');
        return _memoryCache[classroomId]!;
      }
    }

    // Önbellek anahtarı
    final cacheKey = 'words_$classroomId';

    try {
      // 2. API'den veri al
      final response = await _dio.get('/user/category/$classroomId');
      if (response.statusCode == 200) {
        // API'den gelen veriyi işle
        final jsonString = jsonEncode(response.data);

        // Veriyi SharedPreferences'a kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonString);

        // Isolate kullanarak JSON'ı parse et (UI thread'i bloklamadan)
        final words = await _parseWordsJson(jsonString);

        // Bellek önbelleğine ekle
        _memoryCache[classroomId] = words;
        _lastFetchTimes[classroomId] = DateTime.now();

        return words;
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      // 3. Hata durumunda önce bellek önbelleğini kontrol et
      if (_memoryCache.containsKey(classroomId)) {
        print('Ağ hatası, bellek önbelleğinden veri döndürülüyor: $e');
        return _memoryCache[classroomId]!;
      }

      // 4. Son çare olarak SharedPreferences'tan veri almayı dene
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString(cacheKey);

        if (cachedData != null) {
          print('Ağ hatası, yerel önbellekten veri döndürülüyor: $e');
          final words = await _parseWordsJson(cachedData);

          // Bellek önbelleğine ekle
          _memoryCache[classroomId] = words;
          _lastFetchTimes[classroomId] = DateTime.now();

          return words;
        }
      } catch (parseError) {
        print('Önbellek çözme hatası: $parseError');
      }

      // Her şey başarısız olursa, hatayı yeniden fırlat
      rethrow;
    }
  }
  Future<List<Word>> _parseWordsJson(String jsonString) async {
    try {
      return compute((String jsonStr) {
        final data = jsonDecode(jsonStr);
        return (data as List).map<Word>((json) => Word.fromJson(json)).toList();
      }, jsonString);
    } catch (e) {
      // Isolate hatası durumunda ana thread'de parse etmeyi dene
      print('Isolate hatası, ana thread\'de parse ediliyor: $e');
      final data = jsonDecode(jsonString);
      return (data as List).map<Word>((json) => Word.fromJson(json)).toList();
    }
  }
  List<Word> _parseWords(String responseBody) {
    final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Word>((json) => Word.fromJson(json)).toList();
  }

  Future<List<StudySet>> fetchStudySets(int classroomId, int wordId, String userId) async {
    final sharedPrefs = await sp_pkg.SharedPreferences.getInstance();
    final key = 'studySets_${classroomId}_${wordId}_$userId';

    try {
      final response = await _dio.get('/classroom/$classroomId/study-sets/$wordId/user/$userId');
      if (response.statusCode == 200) {
        await sharedPrefs.setString(key, jsonEncode(response.data));
        List<dynamic> studySetsJson = response.data;
        return studySetsJson.map((json) => StudySet.fromJson(json)).toList();
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      final studySetsCached = sharedPrefs.getString(key);
      if (studySetsCached != null) {
        List<dynamic> studySetsJson = jsonDecode(studySetsCached);
        return studySetsJson.map((json) => StudySet.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchExampleSentences(String term) async {
    final sharedPrefs = await sp_pkg.SharedPreferences.getInstance();
    final key = 'exampleSentences_$term';

    try {
      final cachedData = sharedPrefs.getString(key);
      if (cachedData != null) {
        return compute(_parseExampleSentences, cachedData);
      }
      final response = await _dio.post('/example-sentences', data: {'terim': term});
      if (response.statusCode == 200) {
        await sharedPrefs.setString(key, jsonEncode(response.data));
        return compute(_parseExampleSentences, jsonEncode(response.data));
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      final cachedData = sharedPrefs.getString(key);
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
    final response = await _dio.get('/classroom/$classroomId/study-sets-star/$userId');
    if (response.statusCode == 200) {
      List<dynamic> jsonData = response.data;
      return jsonData.map((item) => item['word_id'].toString()).join(',');
    } else {
      throw Exception('Veri yüklenirken bir hata oluştu: ${response.data}');
    }
  }

  //-----------------------------------------------------
  // KULLANICI LİSTELEME
  //-----------------------------------------------------
  Future<List<User>> fetchUsers() async {
    final response = await _dio.get('/users-point');
    if (response.statusCode == 200) {
      List<dynamic> usersJson = response.data;
      return usersJson.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<bool> checkFreeMode() async {
    final response = await _dio.post(
      '/check-mode',
    );
    if (response.statusCode == 200) {
      return response.data['mode'];
    } else {
      throw Exception('Failed to check free mode');
    }
  }
  Future<Map<String, dynamic>> fetchInstitutionUsersPointPeriod(
      String userId,
      String period,
      bool isInstitutionMode,
      ) async {
    final response = await _dio.post(
      '/institution-users-point-period',
      data: {
        'user_id': userId,
        'period': period,
        'is_institution_mode': isInstitutionMode,
      },
    );
    if (response.statusCode == 200) {
      var decodedResponse = response.data;
      if (decodedResponse['has_institution'] == false && isInstitutionMode) {
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
      print('Response body: ${response.data}');
      throw Exception('Failed to load users. Status code: ${response.statusCode}');
    }
  }

  //-----------------------------------------------------
  // YILDIZLI KELİMELER
  //-----------------------------------------------------
  Future<List<int>> fetchStarWords(int userId, dynamic studySetIds) async {
    final response = await _dio.post(
      '/get-star-words',
      data: {
        'user_id': userId,
        'study_set_ids': studySetIds is List ? studySetIds : [studySetIds],
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> starWordsJson = response.data;
      return starWordsJson.map<int>((json) => json['word_id']).toList();
    } else {
      throw Exception('Yıldızlı kelimeler yüklenirken bir hata oluştu: ${response.data}');
    }
  }

  Future<List<WordDetail>> fetchStarWordsAll(int userId) async {
    final response = await _dio.post('/get-star-words-all', data: {'user_id': userId});
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = response.data;
      List<WordDetail> wordCards = jsonResponse.map((data) => WordDetail.fromJson(data)).toList();
      var uniqueWordCardsMap = {for (var card in wordCards) card.id: card};
      return uniqueWordCardsMap.values.toList();
    } else {
      throw Exception('Yıldızlı kelimeler yüklenirken bir hata oluştu: ${response.data}');
    }
  }

  Future<void> fetchStarWordsAllSystem(int userId) async {
    final response = await _dio.post('/starredwords', data: {'userid': userId});
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      print('Response JSON: $jsonResponse');
      List<dynamic> starredWords = jsonResponse;
      final prefs = await sp_pkg.SharedPreferences.getInstance();

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
      throw Exception('Yıldızlı kelimeler yüklenirken bir hata oluştu: ${response.data}');
    }
  }

  List<String>? _getStringListSafe(sp_pkg.SharedPreferences prefs, String key) {
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

  //-----------------------------------------------------
  // CSV'DEN KELİME DETAYLARI ÇEKME
  //-----------------------------------------------------
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
    return WordDataCache._wordsData!
        .sublist(1)
        .where((csvRow) => wordIds.contains(int.tryParse(csvRow[0].toString()) ?? 0))
        .map((csvRow) => WordDetail(
      id: int.parse(csvRow[0].toString()),
      word: csvRow[1].toString(),
      meaning: csvRow[2].toString(),
      image: csvRow.length > 3 ? csvRow[3]?.toString() : null,
      type: csvRow.length > 4 ? csvRow[4]?.toString() : null,
      defination:csvRow[9] ,
      collocations: [],
      derivations: [],
      synonyms: [],
    ))
        .toList();
  }

  Future<WordDetail?> searchWord(String term) async {
    await WordDataCache.loadAllData();
    term = term.trim().toLowerCase();

    var matchedWord = WordDataCache._wordsData!
        .sublist(1)
        .firstWhereOrNull((row) => row[1].toString().toLowerCase() == term);

    if (matchedWord != null) {
      return WordDetail(
        id: int.parse(matchedWord[0].toString()),
        word: matchedWord[1].toString(),
        meaning: matchedWord[2].toString(),
        type: matchedWord.length > 4 ? matchedWord[4]?.toString() : null,
        image: matchedWord.length > 3 ? matchedWord[3]?.toString() : null,
        defination:matchedWord[5] ,
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

  Future<void> fetchAndAttachSynonymsToWordDetail(List<WordDetail> words) async {
    final synonymsFilePath = 'assets/Model/synonyms.csv';
    final csvFile = await rootBundle.loadString(synonymsFilePath);

    await compute(_parseSynonyms, [csvFile, words]);
  }

  static void _parseSynonyms(List<dynamic> args) {
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

  static void _parseCollocations(List<dynamic> args) {
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

  static void _parseDerivations(List<dynamic> args) {
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

  //-----------------------------------------------------
  // KULLANICI SİLME
  //-----------------------------------------------------
  Future<bool> deleteUser(int userId) async {
    try {
      final response = await _dio.delete('/user/$userId');
      if (response.statusCode == 200) {
        print('User deleted successfully');
        return true;
      } else {
        print('Failed to delete user: ${response.data}');
        return false;
      }
    } catch (e) {
      print('Delete user exception: $e');
      return false;
    }
  }

  //-----------------------------------------------------
  // LOKAL - SUNUCU ARASI YILDIZLI KELİMELER SENKRON
  //-----------------------------------------------------
  Future<void> syncStarredWordsWithServer(int userId) async {
    final prefs = await sp_pkg.SharedPreferences.getInstance();
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

    try {
      final response = await _dio.post('/sync_starred_words', data: {
        "user_id": userId,
        "starred_words": dataToSend,
      });
      if (response.statusCode == 200) {
        print("Starred words synced successfully");
        print("Raw response: ${response.data}");
        _updateSharedPreferences(response.data['starred_words']);
        print(response.data['starred_words']);
      } else {
        print("Failed to sync starred words: ${response.data}");
      }
    } catch (e) {
      print("syncStarredWordsWithServer exception: $e");
    }
  }

  void _updateSharedPreferences(List<dynamic> starredWords) async {
    final prefs = await sp_pkg.SharedPreferences.getInstance();
    for (var wordData in starredWords) {
      String key = _generateKey(wordData['c_id'], wordData['study_set_id']);
      if (wordData['words'] != null && wordData['words'].isNotEmpty) {
        List<String> wordIds = (wordData['words'] as List).map((w) => w.toString()).toList();
        await prefs.setStringList(key, wordIds);
      }
    }
  }

  String _generateKey(int classroomId, int studySetId) {
    // Düzeltildi: Alt çizgi kullanarak
    return 'starredWords_classroomId:${classroomId}_studySetId:${studySetId}';
  }

  Future<List<WordDetail>> fetchWordsDetailStar(int classroomId, List<int> studySetId) async {
    final service = StarredWordsService();
    final starredWordIds = await service.loadClassroomStarredWordsAll(classroomId, studySetId);
    return fetchWordsDetail(starredWordIds.toList());
  }

  Future<bool> checkStarred(int wordId, int studySetId, int userId) async {
    final response = await _dio.get(
      '/check-starred',
      queryParameters: {
        'word_id': wordId,
        'study_set_id': studySetId,
        'user_id': userId,
      },
    );
    if (response.statusCode == 200) {
      return response.data['isStarred'];
    } else {
      throw Exception('Yıldızlanma durumunu kontrol ederken bir hata oluştu: ${response.data}');
    }
  }

  Future<void> starWord(int wordId, int categoryID, int studySetID, int userID) async {
    final response = await _dio.post('/star-word', data: {
      'word_id': wordId,
      'userid': userID,
      'category_id': categoryID,
      'study_set_id': studySetID,
    });
    if (response.statusCode != 200) {
      throw Exception('Yıldızlama işlemi sırasında bir hata oluştu: ${response.data}');
    }
  }

  Future<void> starWordDeleteAll(int wordId, int userID) async {
    final response = await _dio.post('/star-word-star-delete', data: {
      'word_id': wordId,
      'userid': userID,
    });
    if (response.statusCode != 200) {
      throw Exception('Yıldızlama silme işlemi sırasında hata: ${response.data}');
    }
  }

  Future<void> starWordDelete(int wordId, int categoryID, int studySetID, int userID) async {
    final response = await _dio.post('/star-word-star', data: {
      'word_id': wordId,
      'userid': userID,
      'category_id': categoryID,
      'study_set_id': studySetID,
    });
    if (response.statusCode != 200) {
      throw Exception('Yıldızlama işlemi sırasında bir hata oluştu: ${response.data}');
    }
  }

  Future<Map<int, bool>> checkStarredBulk(List<int> wordIds, int studySetId, int userId) async {
    var body = {
      'word_ids': wordIds,
      'study_set_id': studySetId.toString(),
      'user_id': userId.toString(),
    };

    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (true) {
      try {
        final response = await _dio.post('/check-starred-bulk', data: body);
        if (response.statusCode == 200) {
          var data = response.data;
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
          print('Response data: ${response.data}');
          throw Exception('Request failed: ${response.data}');
        }
      } catch (e) {
        if (retryCount >= maxRetries) {
          throw Exception('Failed after $maxRetries retries. Error: $e');
        }
        retryCount++;
        print('An error occurred, retrying... Attempt: $retryCount');
        await Future.delayed(retryDelay);
      }
    }
  }

  //-----------------------------------------------------
  // ÖRNEK BİR BULK CÜMLE ÇAĞRISI
  //-----------------------------------------------------
  Future<Map<String, List<String>>> fetchExampleSentencesBulk(List<String> terms) async {
    final sharedPrefs = await sp_pkg.SharedPreferences.getInstance();
    final key = 'exampleSentencesBulk_${terms.join("_")}';
    final exampleSentencesCached = sharedPrefs.getString(key);

    if (exampleSentencesCached != null) {
      Map<String, dynamic> data = json.decode(exampleSentencesCached);
      return data.map<String, List<String>>((key, value) {
        var sentences = (value as List<dynamic>).map((item) => item.toString()).toList();
        return MapEntry(key, sentences);
      });
    } else {
      final response = await _dio.post('/example-sentences-word', data: {'terimler': terms});
      if (response.statusCode == 200) {
        Map<String, dynamic> data = response.data;
        Map<String, List<String>> sentencesMap = data.map<String, List<String>>((key, value) {
          var sentences = (value as List).map<String>((item) => item['cumle'].toString()).toList();
          return MapEntry(key, sentences);
        });
        sharedPrefs.setString(key, json.encode(sentencesMap));
        return sentencesMap;
      } else {
        throw Exception('Data could not be fetched: ${response.statusCode} - ${response.data}');
      }
    }
  }
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await _dio.get('/announcements');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> announcementData = response.data['announcements'];

        return announcementData.map((json) => Announcement.fromJson(json)).toList();
      } else {
        throw Exception('Duyurular yüklenirken bir hata oluştu');
      }
    } on DioError catch (e) {
      print('Duyurular yüklenirken DioError: ${e.message}');
      return [];
    } catch (e) {
      print('Duyurular yüklenirken hata: $e');
      return [];
    }
  }
}
