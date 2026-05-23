class CatchLog {
  const CatchLog({
    required this.id,
    required this.userId,
    required this.birdCardId,
    required this.caughtAt,
    required this.sightingRarity,
    required this.location,
    required this.xpAwarded,
    this.screenshotUrl,
  });

  final String id;
  final String userId;
  final String birdCardId;
  final DateTime caughtAt;
  final String sightingRarity;
  final String location;
  final int xpAwarded;
  final String? screenshotUrl;

  factory CatchLog.fromJson(Map<String, dynamic> json) => CatchLog(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        birdCardId: json['bird_card_id'] as String,
        caughtAt: DateTime.parse(json['caught_at'] as String),
        sightingRarity: json['sighting_rarity'] as String? ?? 'Common',
        location: json['location'] as String? ?? '',
        xpAwarded: json['xp_awarded'] as int? ?? 0,
        screenshotUrl: json['screenshot_url'] as String?,
      );
}
