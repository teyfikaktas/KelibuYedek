

// Ve Announcement sınıfında da bunu güncelleyelim:
import 'AnnouncementCategory.dart';

class Announcement {
  final int id;
  final String title;
  final String content;
  final bool isImportant;
  final DateTime publishDate;
  final AnnouncementCategory category;  // Burada değişti

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.isImportant,
    required this.publishDate,
    required this.category,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      isImportant: json['is_important'] ?? false,
      publishDate: DateTime.parse(json['publish_date']),
      category: AnnouncementCategory.fromJson(json['category']),
    );
  }
}