class CatchLog {
  const CatchLog({
    required this.id,
    required this.userId,
    required this.birdCardId,
    required this.caughtAt,
    this.screenshotUrl,
  });

  final String id;
  final String userId;
  final String birdCardId;
  final DateTime caughtAt;
  final String? screenshotUrl;

  factory CatchLog.fromJson(Map<String, dynamic> json) => CatchLog(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        birdCardId: json['bird_card_id'] as String,
        caughtAt: DateTime.parse(json['caught_at'] as String),
        screenshotUrl: json['screenshot_url'] as String?,
      );
}
