import 'scribble.dart';
import 'user_profile.dart';

enum FeedEventType { newLifer, catch_, levelUp, milestone }

class FeedEvent {
  const FeedEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.createdAt,
    this.birdCardId,
    this.speciesName,
    this.lineArtUrl,
    this.xpAwarded,
    this.sightingRarity,
    this.level,
    this.milestoneValue,
    this.milestoneType,
    this.profile,
    this.peckCount = 0,
    this.hasPecked = false,
    this.scribbles = const [],
  });

  final String id;
  final String userId;
  final FeedEventType type;
  final DateTime createdAt;
  final String? birdCardId;
  final String? speciesName;
  final String? lineArtUrl;
  final int? xpAwarded;
  final String? sightingRarity;
  final int? level;
  final int? milestoneValue;
  final String? milestoneType;
  final UserProfile? profile;
  final int peckCount;
  final bool hasPecked;
  final List<Scribble> scribbles;

  FeedEvent copyWith({int? peckCount, bool? hasPecked, List<Scribble>? scribbles}) => FeedEvent(
        id: id,
        userId: userId,
        type: type,
        createdAt: createdAt,
        birdCardId: birdCardId,
        speciesName: speciesName,
        lineArtUrl: lineArtUrl,
        xpAwarded: xpAwarded,
        sightingRarity: sightingRarity,
        level: level,
        milestoneValue: milestoneValue,
        milestoneType: milestoneType,
        profile: profile,
        peckCount: peckCount ?? this.peckCount,
        hasPecked: hasPecked ?? this.hasPecked,
        scribbles: scribbles ?? this.scribbles,
      );

  static FeedEventType _typeFromString(String s) => switch (s) {
        'new_lifer' => FeedEventType.newLifer,
        'catch' => FeedEventType.catch_,
        'level_up' => FeedEventType.levelUp,
        _ => FeedEventType.milestone,
      };

  factory FeedEvent.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profiles'] as Map<String, dynamic>?;
    return FeedEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: _typeFromString(json['type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      birdCardId: json['bird_card_id'] as String?,
      speciesName: json['species_name'] as String?,
      lineArtUrl: json['line_art_url'] as String?,
      xpAwarded: json['xp_awarded'] as int?,
      sightingRarity: json['sighting_rarity'] as String?,
      level: json['level'] as int?,
      milestoneValue: json['milestone_value'] as int?,
      milestoneType: json['milestone_type'] as String?,
      profile: profileJson != null ? UserProfile.fromJson(profileJson) : null,
    );
  }
}
