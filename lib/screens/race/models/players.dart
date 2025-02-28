class Player {
  final int id;          // room_players.id -> rp_id
  final int roomId;      // room_players.room_id
  final int userId;      // room_players.user_id (int olarak tanımlı)
  final DateTime joinedAt;
  final int score;
  final bool isReady;
  final bool isHost;
  final bool isConnected; // is_connected durumu ekledik

  // Aşağıdakiler, users tablosundan gelen ek alanlar:
  final String? username;
  final String? avatar;

  Player({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.joinedAt,
    this.score = 0,
    this.isReady = false,
    this.isHost = false,
    this.isConnected = true, // Varsayılan olarak true
    this.username,
    this.avatar,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    try {
      return Player(
        id: json['rp_id'] is int
            ? json['rp_id'] as int
            : throw Exception('rp_id must be int, got ${json['rp_id'].runtimeType}'),
        roomId: json['room_id'] is int
            ? json['room_id'] as int
            : throw Exception('room_id must be int, got ${json['room_id'].runtimeType}'),
        userId: json['user_id'] is int
            ? json['user_id'] as int
            : throw Exception('user_id must be int, got ${json['user_id'].runtimeType}'), // Sadece int kabul et
        joinedAt: json['joined_at'] is String
            ? DateTime.parse(json['joined_at'] as String)
            : throw Exception('joined_at must be String, got ${json['joined_at'].runtimeType}'),
        score: json['score'] is int
            ? json['score'] as int
            : (json['score'] as num?)?.toInt() ?? 0,
        isReady: json['is_ready'] is bool
            ? json['is_ready'] as bool
            : (json['is_ready'] as int?) == 1,
        isHost: json['is_host'] is bool
            ? json['is_host'] as bool
            : (json['is_host'] as int?) == 1,
        isConnected: json['is_connected'] is bool
            ? json['is_connected'] as bool
            : json['is_connected'] == 1, // true/false veya 1/0 değerini kabul et
        username: json['name'] is String
            ? json['name'] as String
            : json['name']?.toString(),
        avatar: json['avatar'] is String
            ? json['avatar'] as String
            : json['avatar']?.toString(),
      );
    } catch (e) {
      print('Player parse error detail: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'rp_id': id,
      'room_id': roomId,
      'user_id': userId,  // int olarak tut
      'joined_at': joinedAt.toIso8601String(),
      'score': score,
      'is_ready': isReady,
      'is_host': isHost,
      'is_connected': isConnected, // is_connected durumunu ekle
      'name': username,
      'avatar': avatar,
    };
  }

  Player copyWith({
    int? id,
    int? roomId,
    int? userId,  // int olarak güncelle
    DateTime? joinedAt,
    int? score,
    bool? isReady,
    bool? isHost,
    bool? isConnected, // is_connected durumu ekle
    String? username,
    String? avatar,
  }) {
    return Player(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,  // int olarak tut
      joinedAt: joinedAt ?? this.joinedAt,
      score: score ?? this.score,
      isReady: isReady ?? this.isReady,
      isHost: isHost ?? this.isHost,
      isConnected: isConnected ?? this.isConnected, // is_connected için değer ata
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
    );
  }

  // Eşitlik kontrolü (id, roomId, userId bazında)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Player &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              roomId == other.roomId &&
              userId == other.userId;

  @override
  int get hashCode => id.hashCode ^ roomId.hashCode ^ userId.hashCode;

  // Ekranda gösterilecek isim
  String get displayName => username ?? 'Anonim Oyuncu';

  // Örneğin avatar URL yoksa ilk harf vs. kullanabilirsiniz:
  String get avatarLetter => displayName.isNotEmpty
      ? displayName[0].toUpperCase()
      : '?';
}