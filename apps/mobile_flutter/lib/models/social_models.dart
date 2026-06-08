/// A friend or pending friend-request, from the current user's perspective.
class Friend {
  final int friendshipId;
  final int userId;
  final String name;
  final String email;
  final String? profilePhotoBase64;

  /// PENDING / ACCEPTED / DECLINED
  final String status;

  /// FRIEND (accepted), INCOMING (they asked you), OUTGOING (you asked them)
  final String direction;

  const Friend({
    required this.friendshipId,
    required this.userId,
    required this.name,
    required this.email,
    required this.status,
    required this.direction,
    this.profilePhotoBase64,
  });

  bool get isIncoming => direction == 'INCOMING';
  bool get isOutgoing => direction == 'OUTGOING';

  factory Friend.fromJson(dynamic json) {
    final m = (json as Map).cast<String, dynamic>();
    return Friend(
      friendshipId: (m['friendshipId'] as num?)?.toInt() ?? 0,
      userId: (m['userId'] as num?)?.toInt() ?? 0,
      name: m['name'] as String? ?? '',
      email: m['email'] as String? ?? '',
      profilePhotoBase64: m['profilePhotoBase64'] as String?,
      status: m['status'] as String? ?? 'PENDING',
      direction: m['direction'] as String? ?? 'FRIEND',
    );
  }
}

/// One row of the gamification leaderboard (Health Shield points + streak only).
class LeaderboardEntry {
  final int userId;
  final String name;
  final String? profilePhotoBase64;
  final int level;
  final String levelName;
  final int points;
  final int streak;
  final bool isMe;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.level,
    required this.levelName,
    required this.points,
    required this.streak,
    required this.isMe,
    required this.rank,
    this.profilePhotoBase64,
  });

  factory LeaderboardEntry.fromJson(dynamic json) {
    final m = (json as Map).cast<String, dynamic>();
    return LeaderboardEntry(
      userId: (m['userId'] as num?)?.toInt() ?? 0,
      name: m['name'] as String? ?? '',
      profilePhotoBase64: m['profilePhotoBase64'] as String?,
      level: (m['level'] as num?)?.toInt() ?? 1,
      levelName: m['levelName'] as String? ?? '',
      points: (m['points'] as num?)?.toInt() ?? 0,
      streak: (m['streak'] as num?)?.toInt() ?? 0,
      isMe: m['isMe'] as bool? ?? false,
      rank: (m['rank'] as num?)?.toInt() ?? 0,
    );
  }
}
