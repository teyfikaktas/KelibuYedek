class WordDetail {
  final int id;
  final String word;
  final String meaning;
  final String? type;
  final String? image; // Eğer bir 'image' alanınız varsa bu şekilde ekleyin
  final List<Collocation> collocations;
  final List<Derivation> derivations;
  final List<Synonym> synonyms; // Synonyms listesi eklendi

  WordDetail({
    required this.id,
    required this.word,
    required this.meaning,
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
      collocations: collocationsList.map((c) => Collocation.fromJson(c)).toList(),
      derivations: derivationsList.map((d) => Derivation.fromJson(d)).toList(),
      synonyms: synonymsList.map((s) => Synonym.fromJson(s)).toList(), // Synonyms listesi eklendi
    );
  }
}

class Collocation {
  final int id;
  final String term;
  final String definition;

  Collocation({
    required this.id,
    required this.term,
    required this.definition,
  });

  factory Collocation.fromJson(Map<String, dynamic> json) {
    return Collocation(
      id: json['id'],
      term: json['terim'],
      definition: json['tanim'],
    );
  }
}

class Derivation {
  final int id;
  final String term;
  final String definition;
  final String type;

  Derivation({
    required this.id,
    required this.term,
    required this.definition,
    required this.type,
  });

  factory Derivation.fromJson(Map<String, dynamic> json) {
    return Derivation(
      id: json['id'],
      term: json['terim'],
      definition: json['tanim'],
      type: json['type'],
    );
  }
}

class Synonym { // Synonym sınıfı eklendi
  final int id;
  final String term;
  final String tanim;

  Synonym({
    required this.id,
    required this.term,
    required this.tanim,
  });

  factory Synonym.fromJson(Map<String, dynamic> json) {
    return Synonym(
      id: json['id'],
      term: json['terim'],
      tanim:json['tanim'],
    );
  }
}
