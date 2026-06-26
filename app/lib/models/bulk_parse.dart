/// One row of a parsed Merlin "Identify" list. [verified] mirrors the blue
/// checkmark badge — only verified birds may be logged.
class BulkBird {
  const BulkBird({
    required this.speciesName,
    required this.scientificName,
    required this.verified,
  });

  final String speciesName;
  final String scientificName;
  final bool verified;

  factory BulkBird.fromJson(Map<String, dynamic> json) => BulkBird(
        speciesName: json['species_name'] as String,
        scientificName: json['scientific_name'] as String? ?? '',
        verified: json['verified'] as bool? ?? false,
      );
}

/// A parsed Merlin list screenshot: one shared date + location, many birds.
class BulkParse {
  const BulkParse({
    required this.date,
    required this.location,
    required this.birds,
  });

  final DateTime date;
  final String location;
  final List<BulkBird> birds;

  factory BulkParse.fromJson(Map<String, dynamic> json) => BulkParse(
        date: DateTime.parse(json['date'] as String),
        location: json['location'] as String,
        birds: ((json['birds'] as List?) ?? const [])
            .map((e) => BulkBird.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
