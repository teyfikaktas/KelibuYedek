import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

class WordDetail {
  final int id;
  final String word;
  final String meaning;
  final String? defination;
  final String? type;
  final String? image; // Eğer bir 'image' alanınız varsa bu şekilde ekleyin
  late final List<Collocation> collocations;
  late final List<Derivation> derivations;
  late final List<Synonym> synonyms; // Synonyms listesi eklendi

  WordDetail({
    required this.id,
    required this.word,
    required this.meaning,
    required this.defination,
    required this.type,
    this.image, // Opsiyonel olarak bu alan eklenebilir
    required this.collocations,
    required this.derivations,
    required this.synonyms, // Synonyms parametresi eklendi
  });

  factory WordDetail.fromJson(Map<String, dynamic> json) {
    var collocationsList = json['collocations'] as List;
    var derivationsList = json['derivations'] as List;
    var synonymsList = json['synonyms'] as List; // JSON'dan synonyms listesi çekildi
    return WordDetail(
      id: json['id'],
      word: json['terim'], // 'terim' yerine 'word' kullanıldı
      meaning: json['tanim'],
      type: json['type'] as String?,
      image: json['image'] as String?, // null kontrolü
      defination: json['defination'] as String?,
      collocations: collocationsList.map((c) => Collocation.fromJson(c)).toList(),
      derivations: derivationsList.map((d) => Derivation.fromJson(d)).toList(),
      synonyms: synonymsList.map((s) => Synonym.fromJson(s)).toList(), // Synonyms listesi eklendi
    );
  }
  String toString() {
    return 'WordDetail(word: $word, meaning: $meaning)';
  }
  Future<List<WordDetail>> fetchWordsDetailsFromCsv(String filePath) async {
    final csvFile = await rootBundle.loadString(filePath);
    List<List<dynamic>> csvList = CsvToListConverter().convert(csvFile);

    // WordDetail nesnelerinin ilk oluşturulması.
    List<WordDetail> words = csvList.sublist(1).map((csvRow) {
      return WordDetail(
        id: int.parse(csvRow[0]),
        word: csvRow[1],
        meaning: csvRow[2],
        image: csvRow[3],
        type: csvRow[4],
        defination: csvRow[5],
        collocations: [],
        derivations: [],
        synonyms: [],
      );
    }).toList();
    print(words);
    // İlişkili verilerin eklenmesi için fonksiyonlar.
    try {
      await fetchAndAttachSynonymsToWordDetail('assets/Model/collacations.csv', words);
      // Diğer fonksiyonlar
    } catch (e) {
      print('Bir hata oluştu: $e');
    }
    await fetchAndAttachCollocations('asset/Model/collocations.csv', words);
    await fetchAndAttachDerivations('asset/Model/derivations.csv', words);

    return words;
  }
  Future<void> fetchAndAttachSynonymsToWordDetail(String filePath, List<WordDetail> words) async {
    String wordsFilePath = 'assets/Model/words.csv'; // assets/models klasörü altında varsayıyoruz
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
        anlam: findMeaning(words, csvRow[1]), // Türkçe anlamı bulmak için bir fonksiyon
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
  Future<void> fetchAndAttachCollocations(String filePath, List<WordDetail> words) async {
    final csvFile = await rootBundle.loadString(filePath);
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
        anlam: findMeaning(words, csvRow[1]),
      );

      var wordDetail = words.firstWhereOrNull((word) => word.id == wordId);
      wordDetail?.collocations.add(collocation);
    });
  }

  Future<void> fetchAndAttachDerivations(String filePath, List<WordDetail> words) async {
    final csvFile = await rootBundle.loadString(filePath);
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
        type: csvRow[4], // Derivation tipi
        anlam: findMeaning(words, csvRow[1]),
      );

      var wordDetail = words.firstWhereOrNull((word) => word.id == wordId);
      wordDetail?.derivations.add(derivation);
    });
  }

}

class Collocation {
  final int id;
  final String term;
  final String definition;
  final String? anlam;

  Collocation({
    required this.id,
    required this.term,
    required this.definition,
    required this.anlam,
  });

  factory Collocation.fromJson(Map<String, dynamic> json) {
    return Collocation(
      id: json['id'],
      term: json['terim'],
      definition: json['tanim'],
      anlam: json['anlam'],
    );
  }
}

class Derivation {
  final int id;
  final String term;
  final String definition;
  final String type;
  final String? anlam;

  Derivation({
    required this.id,
    required this.term,
    required this.definition,
    required this.type,
    required this.anlam,
  });

  factory Derivation.fromJson(Map<String, dynamic> json) {
    return Derivation(
      id: json['id'],
      term: json['terim'],
      definition: json['tanim'],
      type: json['type'],
      anlam:json['anlam'],
    );
  }
}

class Synonym { // Synonym sınıfı eklendi
  final int id;
  final String term;
  final String tanim;
  final String? anlam;
  Synonym({
    required this.id,
    required this.term,
    required this.tanim,
    required this.anlam,
  });

  factory Synonym.fromJson(Map<String, dynamic> json) {
    return Synonym(
      id: json['id'],
      term: json['terim'],
      tanim:json['tanim'],
      anlam:json['anlam'],
    );
  }
}