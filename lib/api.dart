import 'dart:convert';
import 'dart:ffi';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:kelibu/Models/Classroom.dart';
import 'package:kelibu/Models/category.dart' as kelibu; // rename
import 'package:kelibu/Models/product.dart';
import 'package:kelibu/Models/studySet.dart';
import 'package:kelibu/Models/user.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:kelibu/shared_preferences/shared_preferences.dart';
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

class WordDataCache {
  static Future<void> loadAllData() async {}

  static List<List<dynamic>> parseCsvData(String csvContent) {
    return const CsvToListConverter(eol: '\n').convert(csvContent);
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
        defination: csvRow[4],
        collocations: [],
        derivations: [],
        synonyms: [],
      );
    }).toList();

    return allWords;
  }

  Future<List<WordDetail>> fetchWordsDetailFromCsvByWordIds(
      String filePath, List<int> wordIds) async {
    List<WordDetail> allWords = await fetchWordsDetailsFromCsv(filePath);
    return allWords.where((word) => wordIds.contains(word.id)).toList();
  }
}
// api.dart içine ekle

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
            const [
              Duration(seconds: 1),
              Duration(seconds: 2),
              Duration(seconds: 3)
            ];

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final RequestOptions requestOptions = err.requestOptions;
    int currentRetryCount = requestOptions.extra["retryCount"] ?? 0;

    // Bu örnekte 'connectionError', 'sendTimeout', 'receiveTimeout', 'unknown' tiplerinde retry deniyoruz
    if (_shouldRetry(err) && currentRetryCount < retries) {
      currentRetryCount++;
      final delay = retryDelays.length >= currentRetryCount
          ? retryDelays[currentRetryCount - 1]
          : retryDelays.last;

      requestOptions.extra["retryCount"] = currentRetryCount;

      await Future.delayed(delay);

      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(e as DioException);
      }
    }

    // Retry yok veya bitti ise normal hatayı dön
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // İstediğiniz hata tiplerinde retry yapabilirsiniz
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.unknown) {
      return true;
    }
    return false;
  }
}

//-----------------------------------------------------
// INTERCEPTOR: TOKEN YÖNETİMİ
//-----------------------------------------------------

// Süper basit TokenInterceptor - Sadece token ekleme
class TokenInterceptor extends Interceptor {
  String? _currentToken;

  // Token'ı set et
  void setToken(String token) {
    _currentToken = token;
  }

  // Token'ı temizle
  void clearToken() {
    _currentToken = null;
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers['Content-Type'] = 'application/json';

    // Token varsa ekle
    if (_currentToken != null) {
      options.headers['Authorization'] = 'Bearer $_currentToken';
    }

    return handler.next(options);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    // 401 gelirse token expired, kullanıcıyı login'e yönlendir
    if (err.response?.statusCode == 401) {
      clearToken();
    }
    return handler.next(err);
  }
}

//-----------------------------------------------------
// INTERCEPTOR: OFFLINE / CACHE YÖNETİMİ (ÖRNEK)
//-----------------------------------------------------
class OfflineCacheInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
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

  Dio get dio => _dio;

  ApiService() {
    // Dio ayarları
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://kelibu.net/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    if (!kReleaseMode) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
          (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }

    // Interceptor: Token
    _dio.interceptors.add(
      TokenInterceptor(),
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
      final decoded = json.decode(response.data);
      return decoded;
    } else {
      return {};
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/v2/auth/logout');
    } catch (e) {
    } finally {
      await storage.delete(key: 'access_token');

      final box = await Hive.openBox('userBox');
      await box.clear();

      // Interceptor'dan token temizle
      final tokenInterceptor = _dio.interceptors
          .firstWhere((i) => i is TokenInterceptor) as TokenInterceptor;
      tokenInterceptor.clearToken();
    }
  }

//-----------------------------------------------------
// TOKEN VALIDASYON
//-----------------------------------------------------
  Future<bool> validateToken(String token) async {
    try {
      final response = await _dio
          .get(
            '/v2/auth/user',
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            ),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      }

      // 401 Unauthorized → Token geçersiz
      if (response.statusCode == 401) {
        return false;
      }

      return false;
    } on DioException catch (e) {
      // 401 hatası
      if (e.response?.statusCode == 401) {
        return false;
      }

      // Timeout veya bağlantı hatası - token geçerli kabul et
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
  /// Word ID listesine göre sorular çek (şıklar otomatik oluşturulur)
  Future<List<Map<String, dynamic>>> getWordQuestionsByWordIds({
    required List<int> wordIds,
    int count = 10,
  }) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.post(
        '/word-questions-by-ids',
        data: {
          'word_ids': wordIds,
          'count': count,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map && response.data['data'] is List) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        }
        return [];
      } else {
        throw ApiException('Sorular alınamadı');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return [];
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    }
  }
  //-----------------------------------------------------
// WORD SET İŞLEMLERİ
//-----------------------------------------------------
  /// Kategori ID'sine göre WordSet'lerden sorular çek
  Future<List<Map<String, dynamic>>> getWordQuestionsByCategoryId({
    required int categoryId,
    int count = 10,
  }) async {
    try {
      final token = await storage.read(key: 'access_token');

      final queryParams = {
        'category_id': categoryId,
        'count': count,
      };

      final response = await _dio.post(
        '/word-questions-set', // ✅ DOĞRU ENDPOINT
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Backend'den {success: true, category_id: 1, total_words: 150, data: []} formatında geliyor
        if (response.data is Map && response.data['data'] is List) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        } else if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else {
          return [];
        }
      } else {
        throw ApiException('Kategori soruları alınamadı');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return []; // boş liste dön, exception fırlatma
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    }
  }
  /// Yeni kelime seti oluştur
  Future<Map<String, dynamic>> createWordSet({
    required String setName,
    required String founder,
    bool isPublic = false,
    bool isCorporate = false,
  }) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.post(
        '/word-sets',
        data: {
          'set_name': setName,
          'founder': founder,
          'is_public': isPublic,
          'is_corporate': isCorporate,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true, // ✅ Tüm status'leri kabul et
        ),
      );

      // ✅ Hata mesajını göreceksin

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'],
          'data': response.data['data'],
        };
      } else {
        throw ApiException('Hata: ${response.data}');
      }
    } catch (e) {
      rethrow;
    }
  }

  //-----------------------------------------------------
// KELİME ARAMA
//-----------------------------------------------------
  /// Kullanıcının kendi word setlerini getir
  Future<List<Map<String, dynamic>>> getMyWordSets() async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.get(
        '/my-word-sets',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Backend formatı: {success: true, data: [...]}
        if (responseData is Map && responseData['data'] != null) {
          final dataList = responseData['data'];

          // data bir List mi?
          if (dataList is List) {
            return dataList
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }

          // data bir Map mi? (paginated data)
          if (dataList is Map && dataList['data'] != null) {
            final items = dataList['data'];
            if (items is List) {
              return items
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
            }
          }
        }

        return [];
      } else {
        throw ApiException('Koleksiyonlar yüklenemedi: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Veri işleme hatası: $e');
    }
  }

// ✅ Buradan sonra yeni metotlar eklenecek (getMyWordSets'in DIŞINDA)

  /// Word set detayını getir
  Future<Map<String, dynamic>> getWordSetDetail(int setId) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.get(
        '/word-sets/$setId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw ApiException('Word set detayı alınamadı');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(e.response?.data['message'] ?? 'Bir hata oluştu');
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Beklenmeyen hata: $e');
    }
  }

  /// Word set güncelle
  Future<Map<String, dynamic>> updateWordSet({
    required int setId,
    String? setName,
    bool? isPublic,
  }) async {
    try {
      final token = await storage.read(key: 'access_token');

      final Map<String, dynamic> body = {};
      if (setName != null) body['set_name'] = setName;
      if (isPublic != null) body['is_public'] = isPublic;

      final response = await _dio.put(
        '/word-sets/$setId',
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ApiException('Güncelleme başarısız');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(
            e.response?.data['message'] ?? 'Güncelleme başarısız');
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Beklenmeyen hata: $e');
    }
  }

  /// Word set sil
  Future<Map<String, dynamic>> deleteWordSet(int setId) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.delete(
        '/word-sets/$setId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ApiException('Silme başarısız');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(e.response?.data['message'] ?? 'Silme başarısız');
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Beklenmeyen hata: $e');
    }
  }

  /// Sete kelime ekle
//-----------------------------------------------------
// KELİME SETE EKLE (Supabase'den bulunan kelimeyi ekle)
//-----------------------------------------------------
  Future<Map<String, dynamic>> addWordToSet({
    required int wordSetId,
    required int wordId,
  }) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio
          .post(
            '/words/add-to-set',
            data: {
              'word_set_id': wordSetId,
              'word_id': wordId,
            },
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token', // ✅ TOKEN
              },
            ),
          )
          .timeout(Duration(seconds: 10));

      // 201 Created → Kelime eklendi
      if (response.statusCode == 201) {
        if (response.data['success'] == true) {
          return response.data;
        } else {
          throw ApiException(response.data['message'] ?? 'Kelime eklenemedi');
        }
      }

      throw ApiException('Beklenmeyen bir hata oluştu');
    } on DioException catch (e) {
      // ✅ Tam data
      // 401 - Yetkisiz
      if (e.response?.statusCode == 401) {
        throw ApiException('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
      }

      // 422 - Validasyon hatası
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        if (errors != null) {
          final firstError = errors.values.first;
          throw ApiException(firstError is List ? firstError[0] : firstError);
        }
        throw ApiException('Geçersiz veri');
      }

      // 404 - Bulunamadı
      if (e.response?.statusCode == 404) {
        throw ApiException('Kelime seti bulunamadı');
      }

      // 409 - Çakışma (zaten var)
      if (e.response?.statusCode == 409) {
        throw ApiException('Bu kelime zaten sette mevcut');
      }

      // Timeout veya bağlantı hatası
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw ApiException(
            'Bağlantı hatası. İnternet bağlantınızı kontrol edin.');
      }

      // Genel hata
      throw ApiException(e.response?.data['message'] ?? 'Bir hata oluştu');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Kelime eklenirken bir hata oluştu');
    }
  }

  /// Setten kelime çıkar
  Future<Map<String, dynamic>> removeWordFromSet({
    required int setId,
    required int wordId,
  }) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.post(
        // ✅ POST
        '/words/remove-from-set',
        data: {
          'word_set_id': setId,
          'word_id': wordId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ApiException('Kelime silinemedi');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(e.response?.data['message'] ?? 'Kelime silinemedi');
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Beklenmeyen hata: $e');
    }
  }

  /// Public/Global word setleri getir
  Future<List<Map<String, dynamic>>> getPublicWordSets() async {
    try {
      final response = await _dio.get('/word-sets');

      if (response.statusCode == 200) {
        final data = _handleResponse(response);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw ApiException('Koleksiyonlar yüklenemedi: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ApiException('Bağlantı hatası: ${e.message}');
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
    required String fcmToken, // ✅ FCM token parametresi
  }) async {
    try {
      final deviceId = await deviceService.getDeviceId();

      final response = await _dio.post(
        '/v2/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'device_name': deviceId,
          'fcm_token': fcmToken, // ✅ FCM token gönder
        },
      );

      if (response.statusCode == 201) {
        final data = _handleResponse(response);

        if (!data.containsKey('token')) {
          throw ApiException('Token bulunamadı');
        }

        final token = data['token'] as String;

        // Token'ı storage'a kaydet
        await storage.write(key: 'access_token', value: token);

        // Token'ı interceptor'a ver
        final tokenInterceptor = _dio.interceptors
            .firstWhere((i) => i is TokenInterceptor) as TokenInterceptor;
        tokenInterceptor.setToken(token);

        return data;
      } else {
        throw ApiException('Kayıt başarısız: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        throw ApiException('Validation hatası', details: errors);
      }

      if (e.response?.statusCode == 409) {
        throw ApiException('Bu email zaten kayıtlı');
      }

      throw ApiException('Bağlantı hatası: ${e.message}');
    }
  }
  Future<Map<String, dynamic>> googleLogin({
    required String idToken,
  }) async {
    try {
      final deviceId = await deviceService.getDeviceId();

      final response = await _dio.post(
        '/v2/auth/google',
        data: {
          'id_token': idToken,
          'device_id': deviceId,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = _handleResponse(response);

        final token = data['access_token'] as String?;
        if (token == null) throw ApiException('Token bulunamadı');

        await storage.write(key: 'access_token', value: token);

        final refreshToken = data['refresh_token'] as String?;
        if (refreshToken != null) {
          await storage.write(key: 'refresh_token', value: refreshToken);
        }

        final tokenInterceptor = _dio.interceptors
            .firstWhere((i) => i is TokenInterceptor) as TokenInterceptor;
        tokenInterceptor.setToken(token);

        return data;
      } else {
        throw ApiException('Google giriş başarısız: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException('Geçersiz Google token');
      }
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        throw ApiException('Validation hatası', details: errors);
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    }
  }
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String fcmToken,
  }) async {
    try {
      final deviceId = await deviceService.getDeviceId();



      final response = await _dio.post(
        '/v2/auth/login',
        data: {
          'email': email.trim(),
          'password': password.trim(),
          'device_name': deviceId,
          'fcm_token': fcmToken,
        },
      );


      if (response.statusCode == 200) {
        final data = _handleResponse(response);

        if (!data.containsKey('token')) {
          throw ApiException('Token bulunamadı');
        }

        final token = data['token'] as String;

        // ✅ Token'ı kaydetmeden önce
        await storage.write(key: 'access_token', value: token);

        // ✅ Kaydedildikten sonra kontrol et
        final savedToken = await storage.read(key: 'access_token');

        final tokenInterceptor = _dio.interceptors
            .firstWhere((i) => i is TokenInterceptor) as TokenInterceptor;
        tokenInterceptor.setToken(token);

        return data;
      } else {
        throw ApiException('Login failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException('Geçersiz e-posta veya şifre');
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    }
  }
  Future<List<Map<String, dynamic>>> getPinnedSets() async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.get(
        '/pinned-sets',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map && responseData['data'] != null) {
          final dataList = responseData['data'];
          if (dataList is List) {
            return dataList
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }
        }

        return [];
      } else {
        throw ApiException('Sabitlenmiş setler yüklenemedi');
      }
    } on DioException catch (e) {
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Veri işleme hatası: $e');
    }
  }

  /// Set'i sabitle
  Future<Map<String, dynamic>> pinWordSet(int wordSetId) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.post(
        '/pinned-sets',
        data: {
          'word_set_id': wordSetId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'],
          'data': response.data['data'],
        };
      } else if (response.statusCode == 409) {
        throw ApiException('Bu set zaten sabitlenmiş');
      } else if (response.statusCode == 403) {
        throw ApiException('Bu sete erişim yetkiniz yok');
      } else {
        throw ApiException('Sabitleme başarısız: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException('Oturum süreniz dolmuş');
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Beklenmeyen hata: $e');
    }
  }

  /// Sabitlemeyi kaldır
  Future<Map<String, dynamic>> unpinWordSet(int wordSetId) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.delete(
        '/pinned-sets/$wordSetId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'],
        };
      } else {
        throw ApiException('Sabitleme kaldırılamadı');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(
            e.response?.data['message'] ?? 'Sabitleme kaldırılamadı');
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Beklenmeyen hata: $e');
    }
  }

  /// Set'in sabitlenip sabitlenmediğini kontrol et
  Future<bool> checkIfPinned(int wordSetId) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.get(
        '/pinned-sets/check/$wordSetId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data']['is_pinned'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Sabitleme sırasını güncelle
  Future<Map<String, dynamic>> updatePinnedSetOrder(
      List<Map<String, int>> orders) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.put(
        '/pinned-sets/order',
        data: {
          'orders': orders, // [{'word_set_id': 1, 'order': 0}, ...]
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'],
        };
      } else {
        throw ApiException('Sıralama güncellenemedi');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException(
            e.response?.data['message'] ?? 'Sıralama güncellenemedi');
      }
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Beklenmeyen hata: $e');
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

// ApiService içinde bu metod var mı ve doğru mu?
  Future<Map<String, dynamic>> updatePasswordOneTime({
    required String email,
    required String newPassword,
    required String accessToken,
  }) async {
    try {
      final response = await dio.post(
        '/auth/update-password-onetime', // ✅ Endpoint doğru mu?
        data: {
          'email': email,
          'new_password': newPassword,
          // 'password': newPassword, // Backend hangi field bekliyor?
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {}
      throw e;
    }
  }

  /// Sadece abonelik bitiş tarihini döndürür.
  /// Önce legacy /status endpoint'ine bakar, yoksa RevenueCat'e fallback yapar.
  Future<DateTime?> getSubscriptionEndDate() async {
    // 1. Legacy /status endpoint'ine bak
    try {
      final token = await storage.read(key: 'access_token');
      if (token != null && token.isNotEmpty) {
        final response = await _dio.get(
          '/auth/subscription/status',
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            validateStatus: (status) => true,
          ),
        );

        if (response.statusCode == 200 && response.data is Map) {
          final data = response.data as Map;
          final endDateRaw = data['end_date']?.toString();
          if (endDateRaw != null && endDateRaw.isNotEmpty) {
            return DateTime.tryParse(endDateRaw);
          }
        }
      }
    } catch (e) {
      debugPrint('Legacy end_date alınamadı: $e');
    }

    // 2. RevenueCat fallback
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.active.values.isNotEmpty
          ? customerInfo.entitlements.active.values.first
          : null;

      final expirationDate = entitlement?.expirationDate;
      if (expirationDate != null && expirationDate.isNotEmpty) {
        return DateTime.tryParse(expirationDate);
      }
    } catch (e) {
      debugPrint('RevenueCat end_date alınamadı: $e');
    }

    return null;
  }
  Future<Map<String, dynamic>> _getLegacySubscriptionStatus() async {
    try {
      // ✅ TOKEN KONTROLÜ
      final token = await storage.read(key: 'access_token');

      if (token == null || token.isEmpty) {
        throw Exception('❌ TOKEN YOK! Kullanıcı login olmamış.');
      }

      final response = await _dio.get(
        '/auth/subscription/status',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => true,
        ),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
  /// RevenueCat üzerinden abonelik statüsü
  Future<Map<String, dynamic>> _getRevenuecatSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return {
        'is_vip': customerInfo.entitlements.active.isNotEmpty,
        'status':
            customerInfo.entitlements.active.isNotEmpty ? 'active' : 'inactive'

      };
    } catch (e) {
      return {'is_vip': false, 'status': 'inactive'};
    }
  }

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
  Future<void> logSetEntry(
      String logType, String setName, String category) async {
    try {
      await sendUserLog(
        type: logType,
        log: 'Kullanıcı "$setName" "$category" giriş yaptı.',
      );
    } catch (e) {}
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
      } else {}
    } catch (e) {}
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
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Online puan güncelleme (basit örnek)
  Future<void> updateUserPoint(int userId, int newPoint) async {
    try {
      await _dio
          .put('/user/$userId/updateUserPoint', data: {'point': newPoint});
    } catch (e) {}
  }

  /// Offline/Online entegre puan güncellemesi
  ///
  /// - İnternet yoksa puan yerel cache'e kaydedilir.
  /// - İnternet gelince senkronize edilir (`syncPendingUpdates`).
  /// - timePoint parametresi de veritabanına gönderilir.
  Future<void> updateUserPointTimePeriod(
      int userId, int newPoint, int timePoint) async {
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
        }
      } on DioError catch (e) {
        if (e.type == DioErrorType.connectionError ||
            e.type == DioErrorType.unknown) {
          // İnternet yoksa cache'e kaydet
          await box.put('lastPoint_$userId', {
            'point': newPoint,
            'timePoint': timePoint,
            'timestamp': DateTime.now().toIso8601String(),
          });
          return;
        }
        rethrow;
      }
    } catch (e) {}
  }

  /// Uygulama açıldığında bekleyen güncellemeler varsa senkronize et
  Future<void> syncPendingUpdates() async {
    final box = await Hive.openBox('pointUpdateCache');
    final pendingKeys =
        box.keys.where((k) => k.toString().startsWith('lastPoint_'));

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
        } catch (e) {}
      }
    }
  }

  //-----------------------------------------------------
  // KULLANICI RANK / PUAN BİLGİSİ
  //-----------------------------------------------------
  Future<Map<String, dynamic>> fetchUserPoint(int userId) async {
    try {
      final response =
          await _dio.post('/user-ranking', data: {'user_id': userId});
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
        return _getDefaultUserData();
      }
    } catch (error) {
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
    await sp_pkg.SharedPreferences.getInstance();
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
        return categoriesJson
            .map((json) => kelibu.Package.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load categories: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to load categories. Error: $e');
    }
  }

  Future<bool> updateFcmToken(int userId, String fcmToken) async {
    try {
      final response = await _dio.post('/update-fcm-token', data: {
        'user_id': userId,
        'fcm_token': fcmToken,
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
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
        final products =
            productsJson.map((json) => Product.fromJson(json)).toList();

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
  /// Random sorular getir
  Future<List<Map<String, dynamic>>> getRandomWordQuestions({
    int count = 10,
    String? category,
  }) async {
    try {
      final token = await storage.read(key: 'access_token');

      final queryParams = {
        'count': count,
        if (category != null) 'category': category,
      };

      final response = await _dio.get(
        '/word-questions-random',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // ✅ Düzeltildi
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else {
          return [];
        }
      } else {
        throw ApiException('Random sorular alınamadı');
      }
    } on DioException catch (e) {
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Beklenmeyen hata: $e');
    }
  }

  /// Kategoriye göre sorular getir
  Future<List<Map<String, dynamic>>> getWordQuestionsByCategory(
      String category) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.post(
        '/word-questions-set',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // ✅ Düzeltildi
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else {
          return [];
        }
      } else {
        throw ApiException('Kategori soruları alınamadı');
      }
    } on DioException catch (e) {
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Beklenmeyen hata: $e');
    }
  }

  /// Belirli kelimeye ait sorular
  Future<List<Map<String, dynamic>>> getWordQuestionsByWord(int wordId) async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.get(
        '/word-questions-by-word/$wordId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // ✅ Düzeltildi
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else {
          return [];
        }
      } else {
        throw ApiException('Kelime soruları alınamadı');
      }
    } on DioException catch (e) {
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Beklenmeyen hata: $e');
    }
  }

  /// Tüm kategorileri getir
  Future<List<String>> getWordQuestionCategories() async {
    try {
      final token = await storage.read(key: 'access_token');

      final response = await _dio.get(
        '/word-questions-categories',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          // ✅ Her Map'ten sadece 'category' field'ını al
          return (response.data as List)
              .map((item) => item['category'] as String)
              .toList();
        } else {
          return [];
        }
      } else {
        throw ApiException('Kategoriler alınamadı');
      }
    } on DioException catch (e) {
      throw ApiException('Bağlantı hatası: ${e.message}');
    } catch (e) {
      throw ApiException('Beklenmeyen hata: $e');
    }
  }// Ayrı bir isolate'te çalıştırılacak parse fonksiyonu

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
    if (_memoryCache.containsKey(classroomId) &&
        _lastFetchTimes.containsKey(classroomId)) {
      final lastFetch = _lastFetchTimes[classroomId]!;
      if (DateTime.now().difference(lastFetch) < _cacheValidity) {
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
        return _memoryCache[classroomId]!;
      }

      // 4. Son çare olarak SharedPreferences'tan veri almayı dene
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString(cacheKey);

        if (cachedData != null) {
          final words = await _parseWordsJson(cachedData);

          // Bellek önbelleğine ekle
          _memoryCache[classroomId] = words;
          _lastFetchTimes[classroomId] = DateTime.now();

          return words;
        }
      } catch (parseError) {}

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
      final data = jsonDecode(jsonString);
      return (data as List).map<Word>((json) => Word.fromJson(json)).toList();
    }
  }

  Future<List<StudySet>> fetchStudySets(
      int classroomId, int wordId, String userId) async {
    final sharedPrefs = await sp_pkg.SharedPreferences.getInstance();
    final key = 'studySets_${classroomId}_${wordId}_$userId';

    try {
      final response = await _dio
          .get('/classroom/$classroomId/study-sets/$wordId/user/$userId');
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
      final response =
          await _dio.post('/example-sentences', data: {'terim': term});
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
    final response =
        await _dio.get('/classroom/$classroomId/study-sets-star/$userId');
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
        return {
          'has_institution': false,
          'message': decodedResponse['message'],
          'users': [],
        };
      }
      return decodedResponse;
    } else {
      throw Exception(
          'Failed to load users. Status code: ${response.statusCode}');
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
      throw Exception(
          'Yıldızlı kelimeler yüklenirken bir hata oluştu: ${response.data}');
    }
  }

  // Yıldızlı kelimeler - Mevcut sunucu API'sini kullan (değişiklik yok)
  Future<List<WordDetail>> fetchStarWordsAll(int userId) async {
    final response =
        await _dio.post('/get-star-words-all', data: {'user_id': userId});
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = response.data;
      List<WordDetail> wordCards =
          jsonResponse.map((data) => WordDetail.fromJson(data)).toList();
      var uniqueWordCardsMap = {for (var card in wordCards) card.id: card};
      return uniqueWordCardsMap.values.toList();
    } else {
      throw Exception(
          'Yıldızlı kelimeler yüklenirken bir hata oluştu: ${response.data}');
    }
  }

  Future<List<WordDetail>> _fetchWordsDetailFromServer(
      List<int> wordIds) async {
    try {
      final response =
          await _dio.post('/get-words-detail', data: {'word_ids': wordIds});
      if (response.statusCode == 200 && response.data != null) {
        return (response.data as List)
            .map((data) => WordDetail.fromJson(data))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> fetchStarWordsAllSystem(int userId) async {
    final response = await _dio.post('/starredwords', data: {'userid': userId});
    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      List<dynamic> starredWords = jsonResponse;
      final prefs = await sp_pkg.SharedPreferences.getInstance();

      for (var word in starredWords) {
        try {
          int wordId = word['word_id'];
          int studySetId = word['study_set_id'];
          int categoryId = word['c_id'];

          String key = _generateKey(categoryId, studySetId);
          List<String>? existingWords =
              List<String>.from(_getStringListSafe(prefs, key) ?? []);

          if (!existingWords.contains(wordId.toString())) {
            existingWords.add(wordId.toString());
            await prefs.setStringList(key, existingWords);
          }
        } catch (e) {}
      }
    } else {
      throw Exception(
          'Yıldızlı kelimeler yüklenirken bir hata oluştu: ${response.data}');
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
      return null;
    }
  }

  Future<List<WordDetail>> fetchWordsDetail(List<int> wordIds) async {
    try {
      return await WordDetail.fetchWordsDetailsFromSupabaseByIds(wordIds);
    } catch (e) {
      // Hata durumunda orijinal sunucu API'sine dön
      return _fetchWordsDetailFromServer(wordIds);
    }
  }

  Future<WordDetail?> searchWord(String term) async {
    try {
      return await WordDetail.searchWordInSupabase(term);
    } catch (e) {}
    return null;
  }

//-----------------------------------------------------
// KELİME ARAMA (Supabase)
//-----------------------------------------------------
  Future<List<Map<String, dynamic>>> searchWords(String query) async {
    try {
      // Supabase'den kelime ara
      final wordDetail = await WordDetail.searchWordInSupabase(query);

      if (wordDetail == null) {
        return [];
      }

      // API formatına çevir
      return [
        {
          'id': wordDetail.id,
          'word': wordDetail.word,
          'meaning': wordDetail.meaning,
          'example': wordDetail.defination ?? '',
          'type': wordDetail.type ?? 'noun',
          'pronunciation': '', // Supabase'de yok
          'synonyms': wordDetail.synonyms.map((s) => s.term).toList(),
        }
      ];
    } catch (e) {
      throw ApiException('Kelime aranırken bir hata oluştu');
    }
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

  Future<void> fetchAndAttachSynonymsToWordDetail(
      List<WordDetail> words) async {
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
      words
          .firstWhereOrNull((word) => word.id == wordId)
          ?.synonyms
          .add(synonym);
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
      words
          .firstWhereOrNull((word) => word.id == wordId)
          ?.collocations
          .add(collocation);
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
      words
          .firstWhereOrNull((word) => word.id == wordId)
          ?.derivations
          .add(derivation);
    }
  }

  //-----------------------------------------------------
  // KULLANICI SİLME
  //-----------------------------------------------------
  Future<bool> deleteUser(int userId) async {
    try {
      final response = await _dio.delete('/user/$userId');
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
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
            int? categoryId = int.tryParse(
                RegExp(r'\d+').firstMatch(parts[1])?.group(0) ?? '');
            int? studySetId = int.tryParse(
                RegExp(r'\d+').firstMatch(parts[2])?.group(0) ?? '');

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
        _updateSharedPreferences(response.data['starred_words']);
      } else {}
    } catch (e) {}
  }

  void _updateSharedPreferences(List<dynamic> starredWords) async {
    final prefs = await sp_pkg.SharedPreferences.getInstance();
    for (var wordData in starredWords) {
      String key = _generateKey(wordData['c_id'], wordData['study_set_id']);
      if (wordData['words'] != null && wordData['words'].isNotEmpty) {
        List<String> wordIds =
            (wordData['words'] as List).map((w) => w.toString()).toList();
        await prefs.setStringList(key, wordIds);
      }
    }
  }

  String _generateKey(int classroomId, int studySetId) {
    // Düzeltildi: Alt çizgi kullanarak
    return 'starredWords_classroomId:${classroomId}_studySetId:${studySetId}';
  }

  Future<List<WordDetail>> fetchWordsDetailStar(
      int classroomId, List<int> studySetId) async {
    final service = StarredWordsService();
    final starredWordIds =
        await service.loadClassroomStarredWordsAll(classroomId, studySetId);
    return fetchWordsDetail(starredWordIds.toList());
  }
  Future<List<int>> fetchWordsId(
      int classroomId, List<int> studySetId) async {
    final service = StarredWordsService();
    final starredWordIds =
    await service.loadClassroomStarredWordsAll(classroomId, studySetId);
    return starredWordIds.toList();
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
      throw Exception(
          'Yıldızlanma durumunu kontrol ederken bir hata oluştu: ${response.data}');
    }
  }

  Future<void> starWord(
      int wordId, int categoryID, int studySetID, int userID) async {
    final response = await _dio.post('/star-word', data: {
      'word_id': wordId,
      'userid': userID,
      'category_id': categoryID,
      'study_set_id': studySetID,
    });
    if (response.statusCode != 200) {
      throw Exception(
          'Yıldızlama işlemi sırasında bir hata oluştu: ${response.data}');
    }
  }

  Future<void> starWordDeleteAll(int wordId, int userID) async {
    final response = await _dio.post('/star-word-star-delete', data: {
      'word_id': wordId,
      'userid': userID,
    });
    if (response.statusCode != 200) {
      throw Exception(
          'Yıldızlama silme işlemi sırasında hata: ${response.data}');
    }
  }

  Future<void> starWordDelete(
      int wordId, int categoryID, int studySetID, int userID) async {
    final response = await _dio.post('/star-word-star', data: {
      'word_id': wordId,
      'userid': userID,
      'category_id': categoryID,
      'study_set_id': studySetID,
    });
    if (response.statusCode != 200) {
      throw Exception(
          'Yıldızlama işlemi sırasında bir hata oluştu: ${response.data}');
    }
  }

  Future<Map<int, bool>> checkStarredBulk(
      List<int> wordIds, int studySetId, int userId) async {
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
          await Future.delayed(retryDelay);
          continue;
        } else {
          throw Exception('Request failed: ${response.data}');
        }
      } catch (e) {
        if (retryCount >= maxRetries) {
          throw Exception('Failed after $maxRetries retries. Error: $e');
        }
        retryCount++;
        await Future.delayed(retryDelay);
      }
    }
  }

  //-----------------------------------------------------
  // ÖRNEK BİR BULK CÜMLE ÇAĞRISI
  //-----------------------------------------------------
  Future<Map<String, List<String>>> fetchExampleSentencesBulk(
      List<String> terms) async {
    final sharedPrefs = await sp_pkg.SharedPreferences.getInstance();
    final key = 'exampleSentencesBulk_${terms.join("_")}';
    final exampleSentencesCached = sharedPrefs.getString(key);

    if (exampleSentencesCached != null) {
      Map<String, dynamic> data = json.decode(exampleSentencesCached);
      return data.map<String, List<String>>((key, value) {
        var sentences =
            (value as List<dynamic>).map((item) => item.toString()).toList();
        return MapEntry(key, sentences);
      });
    } else {
      final response =
          await _dio.post('/example-sentences-word', data: {'terimler': terms});
      if (response.statusCode == 200) {
        Map<String, dynamic> data = response.data;
        Map<String, List<String>> sentencesMap =
            data.map<String, List<String>>((key, value) {
          var sentences = (value as List)
              .map<String>((item) => item['cumle'].toString())
              .toList();
          return MapEntry(key, sentences);
        });
        sharedPrefs.setString(key, json.encode(sentencesMap));
        return sentencesMap;
      } else {
        throw Exception(
            'Data could not be fetched: ${response.statusCode} - ${response.data}');
      }
    }
  }

  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await _dio.get('/announcements');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> announcementData = response.data['announcements'];

        return announcementData
            .map((json) => Announcement.fromJson(json))
            .toList();
      } else {
        throw Exception('Duyurular yüklenirken bir hata oluştu');
      }
    } on DioException {
      return [];
    } catch (e) {
      return [];
    }
  }
}

class HiveUserHelper {
  static Future<int?> getUserId() async {
    final box = await Hive.openBox('userBox');
    return box.get('userId') as int?;
  }
}
