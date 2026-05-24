import 'user_profile.dart';

class Scribble {
  const Scribble({
    required this.id,
    required this.userId,
    required this.feedEventId,
    required this.text,
    required this.createdAt,
    this.profile,
  });

  final String id;
  final String userId;
  final String feedEventId;
  final String text;
  final DateTime createdAt;
  final UserProfile? profile;

  factory Scribble.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profiles'] as Map<String, dynamic>?;
    return Scribble(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      feedEventId: json['feed_event_id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      profile: profileJson != null ? UserProfile.fromJson(profileJson) : null,
    );
  }
}
