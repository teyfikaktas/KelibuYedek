class Product {
  final int id;
  // artık userId ile ilgilenmiyoruz
  final Classroom? classroom;
  final String? text;

  Product({required this.id, this.classroom, this.text});

  factory Product.fromJson(Map<String, dynamic> json) {
    Classroom? classroom;
    if (json['classroom'] != null) {
      classroom = Classroom.fromJson(json['classroom']);
    }

    return Product(
      id: json['id'] ?? 0,
      classroom: classroom,
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classroom': classroom?.toJson(),
      'text': text,
    };
  }

  @override
  String toString() {
    return 'Product{id: $id, classroom: ${classroom?.toString() ?? "null"}, text: $text}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Product && runtimeType == other.runtimeType && id == other.id;

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
