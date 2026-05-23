import 'rarity.dart';

class ParseResult {
  const ParseResult({
    required this.speciesName,
    required this.rarity,
    required this.date,
    required this.location,
  });

  final String speciesName;
  final Rarity rarity;
  final DateTime date;
  final String location;

  factory ParseResult.fromJson(Map<String, dynamic> json) => ParseResult(
        speciesName: json['species_name'] as String,
        rarity: Rarity.fromString(json['rarity'] as String),
        date: DateTime.parse(json['date'] as String),
        location: json['location'] as String,
      );
}
