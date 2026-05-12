class Word {
  final int id;
  final String name;

  Word({required this.id, required this.name});

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      // 'title' anahtarına karşılık gelen değer 'null' ise varsayılan olarak boş bir string ('') atanıyor.
      name: json['title'] as String? ??
          '', // Burada null kontrolü yapılarak, 'title' null ise boş string atanıyor.
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
