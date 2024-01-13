class User {
  final String name;
  final String avatar;
  final int point;

  User({required this.name, required this.avatar, required this.point});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      point: json['point'] as int,
    );
  }
}