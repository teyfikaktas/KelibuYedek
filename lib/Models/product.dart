// Model sınıfları
class Product {
  final int id;
  final Classroom? classroom;
  final String? text;
  final String? title;
  final String? image;
  final int? price;
  final int status;
  final int userId;
  final int classroomId;
  final int order;
  final String? createdAt;
  final String? updatedAt;

  Product({
    required this.id,
    this.classroom,
    this.text,
    this.title,
    this.image,
    this.price,
    required this.status,
    required this.userId,
    required this.classroomId,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    Classroom? classroom;
    if (json['classroom'] != null) {
      classroom = Classroom.fromJson(json['classroom']);
    }

    return Product(
      id: json['id'] ?? 0,
      classroom: classroom,
      text: json['text'],
      title: json['title'],
      image: json['image'],
      price: json['price'],
      status: json['status'] ?? 1,
      userId: json['user_id'] ?? 0,
      classroomId: json['classroom_id'] ?? 0,
      order: json['order'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classroom': classroom?.toJson(),
      'text': text,
      'title': title,
      'image': image,
      'price': price,
      'status': status,
      'user_id': userId,
      'classroom_id': classroomId,
      'order': order,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'Product{id: $id, title: $title, classroom: ${classroom?.toString() ?? "null"}}';
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
  final String? code;
  final int status;
  final int public;
  final int userId;
  final int sort;
  final String? image;
  final String? createdAt;
  final String? updatedAt;

  Classroom({
    required this.id,
    required this.title,
    this.text,
    this.code,
    required this.status,
    required this.public,
    required this.userId,
    required this.sort,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      text: json['text'],
      code: json['code'],
      status: json['status'] ?? 1,
      public: json['public'] ?? 0,
      userId: json['user_id'] ?? 0,
      sort: json['sort'] ?? 0,
      image: json['image'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'code': code,
      'status': status,
      'public': public,
      'user_id': userId,
      'sort': sort,
      'image': image,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'Classroom(id: $id, title: $title, sort: $sort)';
  }
}
