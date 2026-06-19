/// A bird as it exists inside a match — distinct from the collection's
/// BirdCard. Carries only what the migration race needs, plus live match
/// state (days of endurance left, tapped, and a discard reason).
class MatchBird {
  const MatchBird({
    required this.id,
    required this.name,
    required this.sci,
    required this.level,
    required this.speed,
    required this.endurance,
    required this.daysLeft,
    this.tapped = false,
    this.starter = false,
    this.reason,
  });

  final String id;
  final String name;
  final String sci;
  final int level;
  final int speed; // 1–10; flies speed × 100 km
  final int endurance; // 1–5; days of life when deployed
  final int daysLeft; // current position on the endurance track
  final bool tapped; // already activated this day
  final bool starter; // generic filler card, can't be leveled
  final String? reason; // why it's in the discard pile (e.g. 'exhausted')

  /// Distance this bird banks if it flies today.
  int get flyKm => speed * 100;

  MatchBird copyWith({
    int? daysLeft,
    bool? tapped,
    String? reason,
  }) =>
      MatchBird(
        id: id,
        name: name,
        sci: sci,
        level: level,
        speed: speed,
        endurance: endurance,
        daysLeft: daysLeft ?? this.daysLeft,
        tapped: tapped ?? this.tapped,
        starter: starter,
        reason: reason ?? this.reason,
      );

  /// A fresh copy as it enters the roost: full endurance, untapped.
  MatchBird deployed() =>
      copyWith(daysLeft: endurance, tapped: false);
}
