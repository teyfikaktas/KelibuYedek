
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kelibu/Models/category.dart'; // Doğru yolu girin
import 'package:kelibu/Models/Classroom.dart'; // Doğru yolu girin
import 'package:kelibu/Models/studySet.dart';
import 'package:kelibu/Models/user.dart';
import 'package:kelibu/Models/wordDetaik.dart'; // Doğru yolu girin

class ApiService {

  Future<void> updateUserPoint(int userId, int newPoint) async {
    var url = Uri.parse('http://kelibu.net/api/user/$userId/updateUserPoint');
    var response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'point': newPoint}),
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
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        final userPoint = userData['point'];
        return userPoint ?? 0; // API'den dönen değeri doğrudan int olarak kullan
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
    );
    if (response.statusCode == 200) {
      // Başarılı yanıtı işle
      List<dynamic> categoriesJson = json.decode(response.body);
      List<Package> categories = categoriesJson.map((json) => Package.fromJson(json)).toList();

      return categories;
    } else {
      // Hata durumunda konsola hata bilgisini yazdır
      throw Exception('Kategoriler yüklenirken bir hata oluştu: ${response.body}');
    }
  }
  Future<int> fetchUserPoints(int userId) async {
    final response = await http.get(
      Uri.parse('https://kelibu.net/api/$userId/points'),
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
    var url = Uri.parse('https://kelibu.net/api/user/category/$classroomId');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> wordsJson = json.decode(response.body);
      return wordsJson.map((json) => Word.fromJson(json)).toList();
    } else {
      throw Exception('Kelimeler yüklenirken bir hata oluştu: ${response.body}');
    }
  }
  Future<List<StudySet>> fetchStudySets(int classroomId) async {
    var url = Uri.parse('https://kelibu.net/api/classroom/$classroomId/study-sets');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> studySetsJson = json.decode(response.body);
      return studySetsJson.map((json) => StudySet.fromJson(json)).toList();
    } else {
      throw Exception('Study setleri yüklenirken bir hata oluştu: ${response.body}');
    }
  }

    Future<List<User>> fetchUsers() async {
      final response = await http.get(Uri.parse('http://kelibu.net/api/users-point'));
      print(response.body);
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
        'Content-Type': 'application/json',
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
  Future<List<WordDetail>> fetchWordsDetail(List<int> wordIds) async {
    var url = Uri.parse('https://kelibu.net/api/get-words-detail');
    print(wordIds);// API'nin URL'si
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'word_ids': wordIds,
      }),
    );
    if (response.statusCode == 200) {
      List<dynamic> wordsJson = json.decode(response.body);
      print(wordsJson);
      List<WordDetail> words = wordsJson.map((json) => WordDetail.fromJson(json)).toList();
      return words;
    } else {
      throw Exception('Kelime detayları yüklenirken bir hata oluştu: ${response.body}');
    }
  }
  Future<bool> checkStarred(int wordId, int studySetId, int userId) async {
    var url = Uri.parse('https://kelibu.net/api/check-starred?word_id=$wordId&study_set_id=$studySetId&user_id=$userId');
    var response = await http.get(url);

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

    if (response.statusCode != 200) {
      throw Exception('Yıldızlama işlemi sırasında bir hata oluştu: ${response.body}');
    }

  }
  Future<Map<int, bool>> checkStarredBulk(List<int> wordIds, int studySetId, int userId) async {
    var url = Uri.parse('https://kelibu.net/api/check-starred-bulk');
    var headers = {'Content-Type': 'application/json'};
    var body = jsonEncode({
      'word_ids': wordIds,
      'study_set_id': studySetId.toString(),
      'user_id': userId.toString(),
    });

    var response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      var isStarredMap = (data['isStarred'] as Map<String, dynamic>)
          .map<int, bool>((key, value) => MapEntry(int.parse(key), value));
      return isStarredMap;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      print('Response body: ${response.body}');
      throw Exception('Bulk check starred failed: ${response.body}');
    }
  }
  Future<List<Map<String, dynamic>>> fetchExampleSentences(String term) async {
    var url = Uri.parse('http://kelibu.net/api/example-sentences');

    var response = await http.post(url,
        headers:{
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'terim': term,
        }),
    );
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>(); // Liste içindeki her elemanı Map<String, dynamic> olarak dönüştür
    } else {
      throw Exception('Veri alınamadı: ${response.statusCode}');
    }
  }
  Future<List<Map<String, dynamic>>> fetchExampleSentencesBulk(List<String> terms) async {
    try {
      var url = Uri.parse('http://kelibu.net/api/example-sentences');
      var response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'words': terms,
        }),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Veri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      print('Hata: $e');
      return []; // Hata durumunda boş liste döndür
    }
  }
}
