class Room {
  final int id;
  final String roomCode;
  final int createdBy;
  final String status;
  final int playerCount;
  final DateTime createdAt;
  final int? currentRound;
  final DateTime? startTime;
  final String gameStatus;

  Room({
    required this.id,
    required this.roomCode,
    required this.createdBy,
    required this.status,
    required this.playerCount,
    required this.createdAt,
    this.currentRound = 0,
    this.startTime,
    this.gameStatus = 'waiting',
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    try {
      return Room(
        id: json['id'] as int,
        roomCode: json['room_code'] as String,
        createdBy: json['created_by'] as int,
        status: json['status'] as String,
        playerCount: json['player_count'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        currentRound: json['current_round'] as int?,
        startTime: json['start_time'] != null
            ? DateTime.parse(json['start_time'] as String)
            : null,
        gameStatus: json['game_status'] as String? ?? 'waiting',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Odanın oynanabilir durumda olup olmadığını kontrol eden getter
  bool get isPlayable => status != 'closed' && gameStatus == 'waiting';

  // Oyunun başlayıp başlamadığını kontrol eden getter
  bool get isGameStarted => gameStatus == 'in_progress';

  // Oyunun bitip bitmediğini kontrol eden getter
  bool get isGameFinished => gameStatus == 'finished';
}
