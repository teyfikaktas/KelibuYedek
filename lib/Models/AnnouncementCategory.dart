class AnnouncementCategory {
  final int id;
  final String name;
  final String color;

  AnnouncementCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  factory AnnouncementCategory.fromJson(Map<String, dynamic> json) {
    return AnnouncementCategory(
      id: json['id'],
      name: json['name'],
      color: json['color'] ?? '#000000',
    );
  }
}
