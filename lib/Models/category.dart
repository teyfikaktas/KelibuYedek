class Package {
  final int id;
  final int userId;
  final Classroom? classroom; // classroom null olabilir

  Package({required this.id, required this.userId, this.classroom});

  factory Package.fromJson(Map<String, dynamic> json) {
    Classroom? classroom;
    if (json['classroom'] != null) {
      classroom = Classroom.fromJson(json['classroom'] as Map<String, dynamic>);
    }

    return Package(
      id: json['id'] ?? 0, // null durumunda varsayılan değer
      userId: json['user_id'] ?? 0, // null durumunda varsayılan değer
      classroom: classroom, // null olabilir
    );
  }
}

class Classroom {
  final int id;
  final String title;

  Classroom({required this.id, required this.title});

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] ?? 0, // null durumunda varsayılan değer
      title: json['title'] as String? ?? '', // null durumunda varsayılan değer
    );
  }
}
