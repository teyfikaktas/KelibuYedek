import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';

// Supabase istemcisi için global değişken
final supabase = Supabase.instance.client;

class WordDetail {
  final int id;
  final String word;
  final String meaning;
  final String? defination;
  final String? type;
  final String? image;
  late final List<Collocation> collocations;
  late final List<Derivation> derivations;
  late final List<Synonym> synonyms;

  WordDetail({
    required this.id,
    required this.word,
    required this.meaning,
    required this.defination,
    required this.type,
    this.image,
    required this.collocations,
    required this.derivations,
    required this.synonyms,
  });

  // Mevcut fromJson metodu
  factory WordDetail.fromJson(Map<String, dynamic> json) {
    var collocationsList = json['collocations'] as List? ?? [];
    var derivationsList = json['derivations'] as List? ?? [];
    var synonymsList = json['synonyms'] as List? ?? [];

    return WordDetail(
      id: json['id'],
      word: json['terim'] ?? json['word'] ?? '',
      meaning: json['tanim'] ?? json['meaning'] ?? '',
      type: json['type'],
      image: json['image'],
      defination: json['defination'] ?? json['definition'],
      collocations: collocationsList.map((c) => Collocation.fromJson(c)).toList(),
      derivations: derivationsList.map((d) => Derivation.fromJson(d)).toList(),
      synonyms: synonymsList.map((s) => Synonym.fromJson(s)).toList(),
    );
  }

  // Supabase'den veri çekerken kullanılacak metod
  factory WordDetail.fromSupabase(Map<String, dynamic> json) {
    return WordDetail(
      id: json['id'],
      word: json['terim'] ?? '',
      meaning: json['tanim'] ?? '',
      type: json['type'],
      image: json['image'],
      defination: json['definition'],
      collocations: [],
      derivations: [],
      synonyms: [],
    );
  }

  String toString() {
    return 'WordDetail(word: $word, meaning: $meaning)';
  }

  // CSV yerine Supabase'den kelime detaylarını alıyor
  static Future<List<WordDetail>> fetchWordsDetailsFromSupabase() async {
    try {
      // Tüm kelimeleri çek
      final response = await supabase
          .from('words')
          .select();

      // WordDetail nesnelerini oluştur
      List<WordDetail> words = (response as List)
          .map((json) => WordDetail.fromSupabase(json))
          .toList();

      // İlişkili verileri ekle
      await fetchAndAttachSynonymsFromSupabase(words);
      await fetchAndAttachCollocationsFromSupabase(words);
      await fetchAndAttachDerivationsFromSupabase(words);

      return words;
    } catch (e) {
      print('Supabase\'den kelimeler alınırken hata: $e');
      return [];
    }
  }

  // ID'lere göre detayları getir
  static Future<List<WordDetail>> fetchWordsDetailsFromSupabaseByIds(List<int> wordIds) async {
    try {
      // Belirli kelimeleri ID'lerine göre çek
      final response = await supabase
          .from('words')
          .select()
          .filter('id', 'in', wordIds);

      // WordDetail nesnelerini oluştur
      List<WordDetail> words = (response as List)
          .map((json) => WordDetail.fromSupabase(json))
          .toList();

      // İlişkili verileri ekle
      await fetchAndAttachSynonymsFromSupabase(words);
      await fetchAndAttachCollocationsFromSupabase(words);
      await fetchAndAttachDerivationsFromSupabase(words);

      return words;
    } catch (e) {
      print('Supabase\'den kelimeler alınırken hata: $e');
      return [];
    }
  }

  // Kelime arama
  static Future<WordDetail?> searchWordInSupabase(String term) async {
    try {
      final response = await supabase
          .from('words')
          .select()
          .ilike('terim', term.trim())
          .limit(1);

      if ((response as List).isEmpty) {
        return null;
      }

      // WordDetail nesnesini oluştur
      WordDetail word = WordDetail.fromSupabase(response[0]);

      // İlişkili verileri ekle
      await fetchAndAttachSynonymsFromSupabase([word]);
      await fetchAndAttachCollocationsFromSupabase([word]);
      await fetchAndAttachDerivationsFromSupabase([word]);

      return word;
    } catch (e) {
      print('Supabase\'de kelime aranırken hata: $e');
      return null;
    }
  }

  // Tam metin araması
  static Future<List<WordDetail>> searchWordsFullText(String searchTerm) async {
    try {
      final response = await supabase
          .from('words')
          .select()
          .textSearch('fts', searchTerm);

      // WordDetail nesnelerini oluştur
      List<WordDetail> words = (response as List)
          .map((json) => WordDetail.fromSupabase(json))
          .toList();

      // İlişkili verileri ekle
      await fetchAndAttachSynonymsFromSupabase(words);
      await fetchAndAttachCollocationsFromSupabase(words);
      await fetchAndAttachDerivationsFromSupabase(words);

      return words;
    } catch (e) {
      print('Tam metin araması yapılırken hata: $e');
      return [];
    }
  }

  // CSV yerine Supabase'den eşanlamlıları al
  static Future<void> fetchAndAttachSynonymsFromSupabase(List<WordDetail> words) async {
    if (words.isEmpty) return;

    try {
      // Tüm kelimelerin ID'lerini al
      List<int> wordIds = words.map((w) => w.id).toList();

      // Eşanlamlıları çek
      final response = await supabase
          .from('synonyms')
          .select()
          .filter('word_id', 'in', wordIds);

      // Her eşanlamlıyı ilgili kelimeye ekle
      for (var syn in response as List) {
        var wordId = syn['word_id'];
        var synonym = Synonym(
          id: syn['id'],
          term: syn['terim'],
          tanim: syn['tanim'],
          anlam: syn['type'],
        );

        var wordDetail = words.firstWhereOrNull((word) => word.id == wordId);
        if (wordDetail != null) {
          wordDetail.synonyms.add(synonym);
        }
      }
    } catch (e) {
      print('Eşanlamlılar alınırken hata: $e');
    }
  }

  // CSV yerine Supabase'den kolokasyonları al
  static Future<void> fetchAndAttachCollocationsFromSupabase(List<WordDetail> words) async {
    if (words.isEmpty) return;

    try {
      // Tüm kelimelerin ID'lerini al
      List<int> wordIds = words.map((w) => w.id).toList();

      // Kolokasyonları çek
      final response = await supabase
          .from('collocations')
          .select()
          .filter('word_id', 'in', wordIds);

      // Her kolokasyonu ilgili kelimeye ekle
      for (var coll in response as List) {
        var wordId = coll['word_id'];
        var collocation = Collocation(
          id: coll['id'],
          term: coll['terim'],
          definition: coll['anlam'],
          anlam: coll['turkce'],
        );

        var wordDetail = words.firstWhereOrNull((word) => word.id == wordId);
        if (wordDetail != null) {
          wordDetail.collocations.add(collocation);
        }
      }
    } catch (e) {
      print('Kolokasyonlar alınırken hata: $e');
    }
  }

  // CSV yerine Supabase'den türetilmiş kelimeleri al
  static Future<void> fetchAndAttachDerivationsFromSupabase(List<WordDetail> words) async {
    if (words.isEmpty) return;

    try {
      // Tüm kelimelerin ID'lerini al
      List<int> wordIds = words.map((w) => w.id).toList();

      // Türetilmiş kelimeleri çek
      final response = await supabase
          .from('derivations')
          .select()
          .filter('word_id', 'in', wordIds);

      // Her türetilmiş kelimeyi ilgili kelimeye ekle
      for (var der in response as List) {
        var wordId = der['word_id'];
        var derivation = Derivation(
          id: der['id'],
          term: der['terim'],
          definition: der['anlam'],
          type: der['type'],
          anlam: der['turkce'],
        );

        var wordDetail = words.firstWhereOrNull((word) => word.id == wordId);
        if (wordDetail != null) {
          wordDetail.derivations.add(derivation);
        }
      }
    } catch (e) {
      print('Türetilmiş kelimeler alınırken hata: $e');
    }
  }
}

// Diğer model sınıfları değişmedi
class Collocation {
  final int id;
  final String term;
  final String definition;
  final String? anlam;

  Collocation({
    required this.id,
    required this.term,
    required this.definition,
    this.anlam,
  });

  factory Collocation.fromJson(Map<String, dynamic> json) {
    return Collocation(
      id: json['id'],
      term: json['terim'],
      definition: json['anlam'],
      anlam:  json['turkce'],
    );
  }
}
class Derivation {
  final int id;
  final String term;
  final String definition;
  final String? type; // Nullable olarak değiştirildi
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
      definition: json['tanim'] ?? json['Anlam'] ?? '',
      type: json['type'],
      anlam: json['anlam'] ?? json['Turkce'],
    );
  }
}

class Synonym {
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
      tanim: json['tanim'],
      anlam: json['anlam'],
    );
  }
}