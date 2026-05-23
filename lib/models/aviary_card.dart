class AviaryCard {
  const AviaryCard({
    required this.id,
    required this.userId,
    required this.speciesName,
    required this.rarity,
    required this.level,
    required this.xp,
    required this.firstCatchDate,
    this.firstCatchLocation,
    this.screenshotUrl,
  });

  factory AviaryCard.fromJson(Map<String, dynamic> json) => AviaryCard(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        speciesName: json['species_name'] as String,
        rarity: Rarity.fromString(json['rarity'] as String),
        level: json['level'] as int,
        xp: json['xp'] as int,
        firstCatchDate: DateTime.parse(json['first_catch_date'] as String),
        firstCatchLocation: json['first_catch_location'] as String?,
        screenshotUrl: json['screenshot_url'] as String?,
      );

  final String id;
  final String userId;
  final String speciesName;
  final Rarity rarity;
  final int level;
  final int xp;
  final DateTime firstCatchDate;
  final String? firstCatchLocation;
  final String? screenshotUrl;

  // XP threshold to reach the next level: each level costs level * 20 XP.
  int get xpForNextLevel => level * 20;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'species_name': speciesName,
        'rarity': rarity.value,
        'level': level,
        'xp': xp,
        'first_catch_date': firstCatchDate.toIso8601String(),
        'first_catch_location': firstCatchLocation,
        'screenshot_url': screenshotUrl,
      };

  AviaryCard copyWith({
    int? level,
    int? xp,
  }) =>
      AviaryCard(
        id: id,
        userId: userId,
        speciesName: speciesName,
        rarity: rarity,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        firstCatchDate: firstCatchDate,
        firstCatchLocation: firstCatchLocation,
        screenshotUrl: screenshotUrl,
      );
}

enum Rarity {
  common('common', xpPerCatch: 5),
  somewhatRare('somewhat_rare', xpPerCatch: 10),
  ultraRare('ultra_rare', xpPerCatch: 15);

  const Rarity(this.value, {required this.xpPerCatch});

  factory Rarity.fromString(String s) =>
      values.firstWhere((r) => r.value == s, orElse: () => Rarity.common);

  final String value;
  final int xpPerCatch;
}
