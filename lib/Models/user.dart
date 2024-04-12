class User {
  final String name;
  final String avatar;
  final int point;
  final int id;
  final String? city; // Make city nullable
  final String? team; // Team is already nullable

  User({
    required this.name,
    required this.avatar,
    required this.point,
    required this.id,
    this.city, // Adjusted for nullable city
    this.team,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      point: json['point'] as int,
      id: json['id'] as int,
      city: json['city'] as String?, // Adjust for nullable city
      team: json['team'] as String?, // Adjust for nullable team
    );
  }
}
