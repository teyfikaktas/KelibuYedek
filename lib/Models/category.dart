class Package {
  final int id;
  final int userId;
  final Classroom? classroom;
  final String? text;

  Package({required this.id, required this.userId, this.classroom, this.text});

  factory Package.fromJson(Map<String, dynamic> json) {
    Classroom? classroom;
    if (json['classroom'] != null) {
      classroom = Classroom.fromJson(json['classroom']);
    }

    return Package(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      classroom: classroom,
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'classroom': classroom?.toJson(),
      'text': text,
    };
  }
  @override
  String toString() {
    // Burada 'classroom' ve 'text' gibi nullable olan özellikler için null kontrolü yapabilirsiniz.
    return 'Package{id: $id, userId: $userId, classroom: ${classroom?.toString() ?? "null"}, text: $text}';
  }
  // ID'ye göre benzersizliği sağlamak için eşitlik ve hashCode metotlarını override ediyoruz.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Package && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Classroom {
  final int id;
  final String title;
  final String? text;

  Classroom({required this.id, required this.title, this.text});

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      text: json['text'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'text': text,
    };
  }
  @override
  String toString() {
    return 'Classroom(id: $id, title: $title, text: $text)';
  }
}

