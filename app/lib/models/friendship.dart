import 'user_profile.dart';

enum FriendshipStatus { pending, accepted, declined }

class Friendship {
  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    this.profile,
  });

  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final UserProfile? profile;

  factory Friendship.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final status = switch (json['status'] as String) {
      'accepted' => FriendshipStatus.accepted,
      'declined' => FriendshipStatus.declined,
      _ => FriendshipStatus.pending,
    };
    final profileJson = json['profiles'] as Map<String, dynamic>?;
    return Friendship(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: status,
      createdAt: DateTime.parse(json['created_at'] as String),
      profile: profileJson != null ? UserProfile.fromJson(profileJson) : null,
    );
  }
}
