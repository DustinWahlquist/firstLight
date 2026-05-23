import 'rarity.dart';

class BirdCard {
  const BirdCard({
    required this.id,
    required this.userId,
    required this.speciesName,
    required this.scientificName,
    required this.rarity,
    required this.level,
    required this.xp,
    required this.catchCount,
    required this.firstCatchDate,
    required this.firstCatchLocation,
    required this.description,
    required this.facts,
    required this.migrationSpeed,
    required this.endurance,
    this.firstCatchLatitude,
    this.firstCatchLongitude,
    this.screenshotUrl,
    this.lineArtUrl,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String speciesName;
  final String scientificName;
  final Rarity rarity;
  final int level;
  final int xp;
  final int catchCount;
  final DateTime firstCatchDate;
  final String firstCatchLocation;
  final String description;
  final List<String> facts;
  final int migrationSpeed;
  final int endurance;
  final double? firstCatchLatitude;
  final double? firstCatchLongitude;
  final String? screenshotUrl;
  final String? lineArtUrl;
  final DateTime createdAt;

  static const Map<int, int> _xpThresholds = {
    1: 0,
    2: 20,
    3: 50,
    4: 90,
    5: 140,
  };

  static int levelForXp(int xp) {
    var level = 1;
    for (final entry in _xpThresholds.entries) {
      if (xp >= entry.value) level = entry.key;
    }
    return level;
  }

  static int xpForNextLevel(int currentLevel) =>
      _xpThresholds[currentLevel + 1] ?? _xpThresholds.values.last;

  BirdCard copyWith({int? xp, int? level, int? catchCount, String? screenshotUrl, String? lineArtUrl}) =>
      BirdCard(
        id: id,
        userId: userId,
        speciesName: speciesName,
        scientificName: scientificName,
        rarity: rarity,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        catchCount: catchCount ?? this.catchCount,
        firstCatchDate: firstCatchDate,
        firstCatchLocation: firstCatchLocation,
        description: description,
        facts: facts,
        migrationSpeed: migrationSpeed,
        endurance: endurance,
        screenshotUrl: screenshotUrl ?? this.screenshotUrl,
        lineArtUrl: lineArtUrl ?? this.lineArtUrl,
        createdAt: createdAt,
      );

  factory BirdCard.fromJson(Map<String, dynamic> json) => BirdCard(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        speciesName: json['species_name'] as String,
        scientificName: json['scientific_name'] as String? ?? '',
        rarity: Rarity.fromString(json['rarity'] as String),
        level: json['level'] as int,
        xp: json['xp'] as int,
        catchCount: json['catch_count'] as int,
        firstCatchDate: DateTime.parse(json['first_catch_date'] as String),
        firstCatchLocation: json['first_catch_location'] as String,
        description: json['description'] as String? ?? '',
        facts: (json['facts'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        migrationSpeed: json['migration_speed'] as int? ?? 5,
        endurance: json['endurance'] as int? ?? 3,
        firstCatchLatitude: (json['first_catch_latitude'] as num?)?.toDouble(),
        firstCatchLongitude: (json['first_catch_longitude'] as num?)?.toDouble(),
        screenshotUrl: json['screenshot_url'] as String?,
        lineArtUrl: json['line_art_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'species_name': speciesName,
        'scientific_name': scientificName,
        'rarity': rarity.label,
        'level': level,
        'xp': xp,
        'catch_count': catchCount,
        'first_catch_date': firstCatchDate.toIso8601String(),
        'first_catch_location': firstCatchLocation,
        'description': description,
        'facts': facts,
        'migration_speed': migrationSpeed,
        'endurance': endurance,
        'screenshot_url': screenshotUrl,
        'created_at': createdAt.toIso8601String(),
      };
}
