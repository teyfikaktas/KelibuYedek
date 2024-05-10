
import 'package:http/http.dart' as http;
import 'package:kelibu/shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'variables.dart';
import 'screens/home_screen.dart';
import 'package:kelibu/Models/category.dart'; // Doğru yolu girin
import 'package:kelibu/Models/Classroom.dart'; // Doğru yolu girin
import 'package:kelibu/Models/studySet.dart';
import 'package:kelibu/Models/user.dart';
import 'package:kelibu/Models/wordDetaik.dart'; // Doğru yolu girin
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';


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

    // CSV dosyasından WordDetail listesini oluştur
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
    // Tüm WordDetail nesnelerini CSV'den oku
    List<WordDetail> allWords = await fetchWordsDetailsFromCsv(filePath);

    // Belirtilen wordIds listesine göre WordDetail nesnelerini filtrele
    List<WordDetail> filteredWords = allWords.where((word) => wordIds.contains(word.id)).toList();

    return filteredWords;
  }
}

class ApiService {

  Future<void> updateUserPoint(int userId, int newPoint) async {
    var url = Uri.parse('https://kelibu.net/api/user/$userId/updateUserPoint');
    var response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Custom-Header': privacyKey.privacyKeyVariable, // İsteğe eklenen özel header
      },
      body: jsonEncode({'point': newPoint}),
    );

    if (response.statusCode == 200) {
      print('Kullanıcı puanı başarıyla güncellendi.');
    } else {
      print('Puan güncelleme başarısız: ${response.body}');
    }
  }

  Future<void> updateUserPointTimePeriod(int userId, int newPoint, int timePoint) async {
    var url = Uri.parse('https://kelibu.net/api/user/new/updateUserPoint');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Custom-Header': privacyKey.privacyKeyVariable, // İsteğe eklenen özel header
      },
      body: jsonEncode({
        'userId': userId,  // UserID'yi buraya ekledik
        'point': newPoint,
        'timePoint': timePoint

      }),
    );

    if (response.statusCode == 200) {
      print('Kullanıcı puanı başarıyla güncellendi.');
    } else {
      print('Puan güncelleme başarısız: ${response.body}');
    }
  }

  Future<int> fetchUserPoint(int userId) async {
    final String apiUrl = 'http://kelibu.net/api/$userId/point';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'X-Custom-Header': privacyKey.privacyKeyVariable,
        },
      );
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        final userPoint = userData['point'];
        return userPoint ?? 0;
      } else {
        print('API isteği başarısız: ${response.statusCode}');
        return 0;
      }
    } catch (error) {
      print('API isteği sırasında hata oluştu: $error');
      return 0;
    }
  }

  Future<List<Package>> fetchCategories(int userId) async {
    final response = await http.get(
      Uri.parse('https://kelibu.net/api/user/packages?user_id=$userId'),
      headers: {
        'X-Custom-Header': privacyKey.privacyKeyVariable,
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> categoriesJson = json.decode(response.body);
      List<Package> categories = categoriesJson.map((json) => Package.fromJson(json)).toList();

      // ID'ye göre benzersiz paketleri içeren bir Set oluştur. Package sınıfı artık ID'ye göre benzersizliği handle ediyor.
      final uniqueCategoriesSet = categories.toSet();
      List<Package> uniqueCategories = uniqueCategoriesSet.toList();

      return uniqueCategories;
    } else {
      throw Exception('Failed to load categories: ${response.body}');
    }
  }
  Future<int> fetchUserPoints(int userId) async {
    final response = await http.get(
      Uri.parse('https://kelibu.net/api/$userId/points'),
      headers: {
        'X-Custom-Header': privacyKey.privacyKeyVariable,
      },
    );
    print(response.body);
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['points']; // 'points' Laravel API'nizden dönen JSON anahtarıdır
    } else {
      throw Exception('Puanlar yüklenemedi');
    }
  }
  Future<List<Word>> fetchWords(int classroomId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'words_$classroomId';
    final wordsCached = prefs.getString(key);

    if (wordsCached != null) {
      // Cache'den okuma
      List<dynamic> wordsJson = json.decode(wordsCached);
      print(wordsJson);
      return wordsJson.map((json) => Word.fromJson(json)).toList();
    } else {
      // API'den çekme ve cache'e kaydetme
      var url = Uri.parse('https://kelibu.net/api/user/category/$classroomId');
      var response = await http.get(
        url,
        headers: {
          'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header ekleme
        },
      );

      if (response.statusCode == 200) {
        prefs.setString(key, response.body); // Cevabı cache'e kaydet
        List<dynamic> wordsJson = json.decode(response.body);
        print(wordsJson);
        return wordsJson.map((json) => Word.fromJson(json)).toList();
      } else {
        throw Exception('Kelimeler yüklenirken bir hata oluştu: ${response.body}');
      }
    }
  }
  Future<List<StudySet>> fetchStudySets(int classroomId, int wordId, String userid) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'studySets_${classroomId}_${wordId}_$userid';
    final studySetsCached = prefs.getString(key);

    if (studySetsCached != null) {
      // Use cached data
      List<dynamic> studySetsJson = json.decode(studySetsCached);
      return studySetsJson.map((json) => StudySet.fromJson(json)).toList();
    } else {
      // Fetch data from API and cache it
      var url = Uri.parse('https://kelibu.net/api/classroom/$classroomId/study-sets/$wordId/user/$userid');
      var response = await http.get(
        url,
        headers: {
          'X-Custom-Header': privacyKey.privacyKeyVariable, // Adding custom header
        },
      );

      if (response.statusCode == 200) {
        // Cache the response
        prefs.setString(key, response.body);
        // Parse and return the data
        List<dynamic> studySetsJson = json.decode(response.body);
        return studySetsJson.map((json) => StudySet.fromJson(json)).toList();
      } else {
        throw Exception('Study sets couldn\'t be loaded: ${response.body}');
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchExampleSentences(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'exampleSentences_$term';
    final exampleSentencesCached = prefs.getString(key);

    if (exampleSentencesCached != null) {
      // Cache'den okuma
      List<dynamic> data = json.decode(exampleSentencesCached);
      return data.cast<Map<String, dynamic>>(); // Liste içindeki her elemanı Map<String, dynamic> olarak dönüştür
    } else {
      // API'den çekme ve cache'e kaydetme
      var url = Uri.parse('https://www.kelibu.net/api/example-sentences');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header ekleme
        },
        body: json.encode({
          'terim': term,
        }),
      );
      if (response.statusCode == 200) {
        prefs.setString(key, response.body); // Cevabı cache'e kaydet
        List data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>(); // Liste içindeki her elemanı Map<String, dynamic> olarak dönüştür
      } else {
        throw Exception('Data could not be fetched: ${response.statusCode}');
      }
    }
  }
  Future<String> fetchStudySetsStar(int classroomId, int userId) async {
    var url = Uri.parse('https://kelibu.net/api/classroom/$classroomId/study-sets-star/$userId');
    var response = await http.get(
      url,
      headers: {
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Adding custom header
      },
    );

    if (response.statusCode == 200) {
      // JSON verisini decode ediyoruz
      List<dynamic> jsonData = json.decode(response.body);
      print(response.body);

      // id değerlerini çıkarıp virgülle ayrılmış stringe dönüştürüyoruz
      String idString = jsonData.map((item) => item['word_id'].toString()).join(',');

      return idString;
    } else {
      throw Exception('Veri yüklenirken bir hata oluştu: ${response.body}');
    }
  }
  Future<List<User>> fetchUsers() async {
    final response = await http.get(
      Uri.parse('http://kelibu.net/api/users-point'),
      headers: {
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Add your custom header here
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> usersJson = json.decode(response.body);
      return usersJson.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }
  Future<List<User>> fetchUsersNew(String code, String period) async {
    final response = await http.post(
        Uri.parse('https://kelibu.net/api/users-point-period'),
        headers: {
          'X-Custom-Header': privacyKey.privacyKeyVariable, // Add your custom header here
        },
        body: {
          'code': code, // Code parameter to be sent in the request body
          'period': period, // Period parameter to be sent in the request body
        }
    );
    if (response.statusCode == 200) {
      List<dynamic> usersJson = json.decode(response.body);
      return usersJson.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }
  Future<List<int>> fetchStarWords(int userId, dynamic studySetIds) async {
    var url = Uri.parse('https://kelibu.net/api/get-star-words');
    var response = await http.post(
      url,
      headers: {
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Add the custom header here
      },
      body: json.encode({
        'user_id': userId,
        'study_set_ids': studySetIds is List ? studySetIds : [studySetIds],
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> starWordsJson = json.decode(response.body);
      // Sadece kelime ID'lerini döndür
      return starWordsJson.map<int>((json) => json['word_id']).toList();
    } else {
      throw Exception('Yıldızlı kelimeler yüklenirken bir hata oluştu: ${response.body}');
    }
  }

  Future<List<WordDetail>> fetchStarWordsAll(int userId) async {
    var url = Uri.parse('https://kelibu.net/api/get-star-words-all');

    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Adding the custom header
      },
      body: json.encode({
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      List<WordDetail> wordCards = jsonResponse.map((data) => WordDetail.fromJson(data)).toList();

      // Benzersiz id'lere göre filtreleme
      var uniqueWordCardsMap = { for (var card in wordCards) card.id: card };
      List<WordDetail> uniqueWordCards = uniqueWordCardsMap.values.toList();

      return uniqueWordCards;
    } else {
      throw Exception('Yıldızlı kelimeler yüklenirken bir hata oluştu: ${response.body}');
    }
  }

  Future<List<WordDetail>> fetchWordsDetail(List<int> wordIds) async {
    // Assuming words.csv is formatted with id,word,meaning,[image],[type],...
    String wordsFilePath = 'assets/Model/words.csv';
    final csvFile = await rootBundle.loadString(wordsFilePath);
    final converter = CsvToListConverter(eol: '\n');
    List<List<dynamic>> csvList = converter.convert(csvFile);

    List<WordDetail> filteredWords = csvList.sublist(1).where((csvRow) {
      int currentId = int.tryParse(csvRow[0].toString()) ?? 0;
      return wordIds.contains(currentId);
    }).map((csvRow) {
      return WordDetail(
        id: int.parse(csvRow[0].toString()),
        word: csvRow[1].toString(),
        meaning: csvRow[2].toString(),
        image: csvRow.length > 3 ? csvRow[3]?.toString() : null,
        type: csvRow.length > 4 ? csvRow[4]?.toString() : null,
        collocations: [],
        derivations: [],
        synonyms: [],
      );
    }).toList();

    // Fetch and attach related data to each WordDetail object
    await fetchAndAttachCollocations(filteredWords);
    await fetchAndAttachDerivations(filteredWords);
    await fetchAndAttachSynonymsToWordDetail(filteredWords);

    return filteredWords;
  }
  Future<void> fetchAndAttachSynonymsToWordDetail(List<WordDetail> words) async {

    String wordsFilePath = 'assets/Model/synonyms.csv'; // assets/models klasörü altında varsayıyoruz
    final csvFile = await rootBundle.loadString(wordsFilePath);
    final converter = CsvToListConverter(
      eol: '\n', // Satır sonu karakteri olarak '\n' kullan
      // Diğer gerekli yapılandırmalar burada belirtilebilir
    );
    List<List<dynamic>> csvList = converter.convert(csvFile);
    csvList.sublist(1).forEach((csvRow) {
      var wordId = int.parse(csvRow[3]);
      var synonym = Synonym(
        id: int.parse(csvRow[0]),
        term: csvRow[1],
        tanim: csvRow[2],
        anlam: csvRow[5], // Türkçe anlamı bulmak için bir fonksiyon
      );

      var wordDetail = words.firstWhereOrNull((word) => word.id == wordId); // firstWhereOrNull kullanımı
      if (wordDetail != null) {
        wordDetail.synonyms.add(synonym); // veya collocations, derivations için benzer
      }
      wordDetail?.synonyms.add(synonym);
    });
  }
  String findMeaning(List<WordDetail> words, String term) {
    var word = words.firstWhereOrNull((word) => word.word == term);
    return word?.meaning ?? 'Anlam bulunamadı';
  }
  Future<void> fetchAndAttachCollocations(List<WordDetail> words) async {
    String wordsFilePath = 'assets/Model/collacations.csv'; // assets/models klasörü altında varsayıyoruz

    final csvFile = await rootBundle.loadString(wordsFilePath);
    final converter = CsvToListConverter(
      eol: '\n', // Satır sonu karakteri olarak '\n' kullan
      // Diğer gerekli yapılandırmalar burada belirtilebilir
    );
    List<List<dynamic>> csvList = converter.convert(csvFile);
    csvList.sublist(1).forEach((csvRow) {
      var wordId = int.parse(csvRow[3]); // word_id kolonu
      var collocation = Collocation(
        id: int.parse(csvRow[0]),
        term: csvRow[1],
        definition: csvRow[2],
        anlam: csvRow[8],
      );

      var wordDetail = words.firstWhereOrNull((word) => word.id == wordId);
      wordDetail?.collocations.add(collocation);
    });
  }
  Future<void> fetchAndAttachDerivations(List<WordDetail> words) async {

    String wordsFilePath = 'assets/Model/derivations.csv'; // assets/models klasörü altında varsayıyoruz

    final csvFile = await rootBundle.loadString(wordsFilePath);
    final converter = CsvToListConverter(
      eol: '\n', // Satır sonu karakteri olarak '\n' kullan
      // Diğer gerekli yapılandırmalar burada belirtilebilir
    );

    List<List<dynamic>> csvList = converter.convert(csvFile);
    csvList.sublist(1).forEach((csvRow) {
      var wordId = int.parse(csvRow[3]); // word_id kolonu
      var derivation = Derivation(
        id: int.parse(csvRow[0]),
        term: csvRow[1],
        definition: csvRow[2],
        type: csvRow[8], // Derivation tipi
        anlam:csvRow[9] ,
      );

      var wordDetail = words.firstWhereOrNull((word) => word.id == wordId);
      wordDetail?.derivations.add(derivation);
    });
  }
  Future<bool> deleteUser(int userId) async {
    print(userId);
    var url = Uri.parse('https://kelibu.net/api/user/$userId');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header added
      },
    );

    if (response.statusCode == 200) {
      print('User deleted successfully');
      return true; // Başarılı olduğunda true dön
    } else {
      print('Failed to delete user: ${response.body}');
      return false; // Başarısız olduğunda false dön
    }
  }
  Future<List<WordDetail>> fetchWordsDetailStar(int classroomId, List<int> studySetId) async {
    final service = StarredWordsService();
    // Yıldızlanmış kelime ID'lerini al
    Set<int> starredWordIds = await service.loadClassroomStarredWordsAll(classroomId, studySetId);
    final result = await fetchWordsDetail(starredWordIds.toList());
    print(result);
    // Yıldızlanmış kelime ID'lerini kullanarak kelime detaylarını al
    // Bu sefer doğrudan yıldızlanmış kelime ID'leri ile kelime detaylarını alıyoruz.
    return await fetchWordsDetail(starredWordIds.toList());
  }
  Future<bool> checkStarred(int wordId, int studySetId, int userId) async {
    var url = Uri.parse('https://kelibu.net/api/check-starred?word_id=$wordId&study_set_id=$studySetId&user_id=$userId');
    var response = await http.get(
      url,
      headers: {
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header added
      },
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['isStarred'];
    } else {
      throw Exception('Yıldızlanma durumunu kontrol ederken bir hata oluştu: ${response.body}');
    }
  }
  Future<void> starWord(int wordId, int categoryID, int studySetID, int userID) async {

    var url = Uri.parse('https://kelibu.net/api/star-word'); // Backend API'nizin URL'si
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'word_id': wordId,
        'userid' : userID,
        'category_id' : categoryID,
        'study_set_id' : studySetID,
      }),
    );
    print(response.body);
    if (response.statusCode != 200) {
      throw Exception('Yıldızlama işlemi sırasında bir hata oluştu: ${response.body}');
    }

  }
  Future<void> starWordDeleteAll(int wordId, int userID) async {
    var url = Uri.parse('https://kelibu.net/api/star-word-star-delete'); // Backend API'nizin URL'si
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header added
      },
      body: json.encode({
        'word_id': wordId,
        'userid' : userID,
      }),
    );
    print(response.body);
    if (response.statusCode != 200) {
      throw Exception('Yıldızlama işlemi sırasında bir hata oluştu: ${response.body}');
    }
  }
  Future<void> starWordDelete(int wordId, int categoryID, int studySetID, int userID) async {

    var url = Uri.parse('https://kelibu.net/api/star-word-star'); // Backend API'nizin URL'si
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'word_id': wordId,
        'userid' : userID,
        'category_id' : categoryID,
        'study_set_id' : studySetID,
      }),
    );
    print(response.body);
    if (response.statusCode != 200) {
      throw Exception('Yıldızlama işlemi sırasında bir hata oluştu: ${response.body}');
    }

  }
  Future<Map<int, bool>> checkStarredBulk(List<int> wordIds, int studySetId, int userId) async {
    var url = Uri.parse('https://kelibu.net/api/check-starred-bulk');
    var headers = {
      'Content-Type': 'application/json',
      'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header added
    };
    var body = jsonEncode({
      'word_ids': wordIds,
      'study_set_id': studySetId.toString(),
      'user_id': userId.toString(),
    });

    int retryCount = 0;
    const maxRetries = 3; // Maksimum yeniden deneme sayısı
    const retryDelay = Duration(seconds: 2); // Yeniden denemeler arasındaki bekleme süresi

    while (true) {
      try {
        var response = await http.post(url, headers: headers, body: body);
        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          var isStarredMap = (data['isStarred'] as Map<String, dynamic>)
              .map<int, bool>((key, value) => MapEntry(int.parse(key), value));
          return isStarredMap;
        } else if (response.statusCode == 429 && retryCount < maxRetries) { // Çok fazla istek hatası kontrolü
          retryCount++;
          print('Request rate limit reached, retrying... Attempt: $retryCount');
          await Future.delayed(retryDelay); // Belirli bir süre bekle
          continue; // Yeniden dene
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
        await Future.delayed(retryDelay); // Hata durumunda belirli bir süre bekle ve yeniden dene
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
      // Cache'den okuma
      Map<String, dynamic> data = json.decode(exampleSentencesCached);
      return data.map<String, List<String>>((key, value) {
        var sentences = (value as List<dynamic>).map((item) => item.toString()).toList();
        return MapEntry(key, sentences);
      });
    } else {
      // API'den çekme ve cache'e kaydetme
      var url = Uri.parse('https://kelibu.net/api/example-sentences-word');
      var response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header added
          },
          body: json.encode({
            'terimler': terms,
          })
      );

      if (response.statusCode == 200) {
        // JSON çözümlemesini arka planda yap
        Map<String, dynamic> data = await compute(_parseJson, response.body);
        Map<String, List<String>> sentencesMap = data.map<String, List<String>>((key, value) {
          var sentences = (value as List).map<String>((item) => item['cumle'].toString()).toList();
          return MapEntry(key, sentences);
        });
        // Sonucu JSON string olarak cache'e kaydet
        prefs.setString(key, json.encode(sentencesMap));
        return sentencesMap;
      } else {
        throw Exception('Data could not be fetched: ${response.statusCode}');
      }
    }
  }}
