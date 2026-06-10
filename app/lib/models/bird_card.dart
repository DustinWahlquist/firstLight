class BirdCard {
  const BirdCard({
    required this.id,
    required this.userId,
    required this.speciesName,
    required this.scientificName,
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
    this.lastCaughtAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String speciesName;
  final String scientificName;
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
  final DateTime? lastCaughtAt;
  final DateTime createdAt;

  BirdCard copyWith({int? xp, int? level, int? catchCount, String? screenshotUrl, String? lineArtUrl}) =>
      BirdCard(
        id: id,
        userId: userId,
        speciesName: speciesName,
        scientificName: scientificName,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        catchCount: catchCount ?? this.catchCount,
        firstCatchDate: firstCatchDate,
        firstCatchLocation: firstCatchLocation,
        description: description,
        facts: facts,
        migrationSpeed: migrationSpeed,
        endurance: endurance,
        firstCatchLatitude: firstCatchLatitude,
        firstCatchLongitude: firstCatchLongitude,
        screenshotUrl: screenshotUrl ?? this.screenshotUrl,
        lineArtUrl: lineArtUrl ?? this.lineArtUrl,
        lastCaughtAt: lastCaughtAt,
        createdAt: createdAt,
      );

  factory BirdCard.fromJson(Map<String, dynamic> json) => BirdCard(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        speciesName: json['species_name'] as String,
        scientificName: json['scientific_name'] as String? ?? '',
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
        lastCaughtAt: json['last_caught_at'] != null
            ? DateTime.parse(json['last_caught_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'species_name': speciesName,
        'scientific_name': scientificName,
        'level': level,
        'xp': xp,
        'catch_count': catchCount,
        'first_catch_date': firstCatchDate.toIso8601String(),
        'first_catch_location': firstCatchLocation,
        'description': description,
        'facts': facts,
        'migration_speed': migrationSpeed,
        'endurance': endurance,
        'first_catch_latitude': firstCatchLatitude,
        'first_catch_longitude': firstCatchLongitude,
        'screenshot_url': screenshotUrl,
        'line_art_url': lineArtUrl,
        'last_caught_at': lastCaughtAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
