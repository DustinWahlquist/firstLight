import 'rarity.dart';

class ParseResult {
  const ParseResult({
    required this.speciesName,
    required this.scientificName,
    required this.rarity,
    required this.sightingRarity,
    required this.date,
    required this.location,
    required this.description,
    required this.facts,
    required this.migrationSpeed,
    required this.endurance,
    this.latitude,
    this.longitude,
    this.lineArtUrl,
  });

  final String speciesName;
  final String scientificName;
  final Rarity rarity;
  final String sightingRarity;
  final DateTime date;
  final String location;
  final String description;
  final List<String> facts;
  final int migrationSpeed;
  final int endurance;
  final double? latitude;
  final double? longitude;
  final String? lineArtUrl;

  factory ParseResult.fromJson(Map<String, dynamic> json) => ParseResult(
        speciesName: json['species_name'] as String,
        scientificName: json['scientific_name'] as String? ?? '',
        rarity: Rarity.fromString(json['rarity'] as String),
        sightingRarity: json['sighting_rarity'] as String? ?? 'Common',
        date: DateTime.parse(json['date'] as String),
        location: json['location'] as String,
        description: json['description'] as String? ?? '',
        facts: (json['facts'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        migrationSpeed: json['migration_speed'] as int? ?? 5,
        endurance: json['endurance'] as int? ?? 3,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        lineArtUrl: json['line_art_url'] as String?,
      );
}
