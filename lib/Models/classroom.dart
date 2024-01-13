class Word {
  final int id;
  final String name; // Diğer gerekli alanlarınızı ekleyin.

  Word({required this.id, required this.name});

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      name: json['title'],
    );
  }
}
