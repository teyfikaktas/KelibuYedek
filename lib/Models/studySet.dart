class StudySet {
  final int id;
  final String name;
  final String words;
  final int word_count;
  StudySet({required this.id, required this.name, required this.words, required this.word_count});

  factory StudySet.fromJson(Map<String, dynamic> json) {
    return StudySet(
      id: json['id'],
      name: json['title'],
      words:json['words'],
        word_count:json['count']
    );
  }
}
