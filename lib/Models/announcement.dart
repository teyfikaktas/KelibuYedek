// Ve Announcement sınıfında da bunu güncelleyelim:
import 'dart:convert';
import 'AnnouncementCategory.dart';

class Announcement {
  final int id;
  final String title;
  final String content;
  final bool isImportant;
  final DateTime publishDate;
  final AnnouncementCategory category;
  final String? metadata;
  final List<String> links; // Yeni: 'data' alanındaki linkler için

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.isImportant,
    required this.publishDate,
    required this.category,
    this.metadata,
    this.links = const [],
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    List<String> parsedLinks = [];
    try {
      if (json['data'] != null) {
        var dataField = json['data'];
        dynamic decoded;
        
        if (dataField is String) {
          try {
            decoded = jsonDecode(dataField);
          } catch (e) {
            // Eğer JSON değilse ve düz bir linkse
            if (dataField.startsWith('http')) {
              parsedLinks = [dataField];
            }
          }
        } else {
          decoded = dataField;
        }

        if (decoded is List) {
          parsedLinks = decoded.map((e) => e.toString()).toList();
        } else if (decoded is Map) {
          // Tüm key'lerin değerlerini (link1, link2, url vb.) listeye ekle
          parsedLinks = decoded.values
              .where((v) => v != null && v.toString().startsWith('http'))
              .map((v) => v.toString())
              .toList();
        }
      }
    } catch (e) {
      // Link ayrıştırma hatası
    }

    return Announcement(
      id: json['id'] is int ? json['id'] : 0,
      title: json['title'] ?? '',
      content: json['content'] ?? json['body'] ?? '',
      isImportant: json['is_important'] == 1 || json['is_important'] == true,
      publishDate: json['publish_date'] != null 
          ? DateTime.parse(json['publish_date']) 
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      category: json['category'] != null 
          ? AnnouncementCategory.fromJson(json['category'])
          : AnnouncementCategory(id: 0, name: 'Genel', color: '#808080'),
      metadata: json['token'] ?? json['metadata'],
      links: parsedLinks,
    );
  }
}
