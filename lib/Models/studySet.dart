class StudySet {
  final int id;
  final String name;
  final String words;
  StudySet({required this.id, required this.name, required this.words});

  factory StudySet.fromJson(Map<String, dynamic> json) {
    return StudySet(
      id: json['id'],
      name: json['title'],
      words:json['words']
    );
  }
}
