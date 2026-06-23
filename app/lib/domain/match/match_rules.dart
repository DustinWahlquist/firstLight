/// The rules of a First Light match (the migration race). Pure Dart, no
/// Flutter — every value here mirrors the design handoff's rules reference
/// and the eventual server-side match RPC. Keep the three in sync.
abstract final class MatchRules {
  /// Distance to win the race.
  static const int winKm = 10000;

  /// Opening hand drawn on the setup night.
  static const int openingHand = 5;

  /// Night draw count and hand cap. One card drawn per night.
  static const int drawPerNight = 1;
  static const int handCap = 7;

  /// Birds deployed per Night — a single bird, including the opening night.
  static const int deployPerNight = 1;

  static int flyKm(int speed) => speed * 100;

  /// Initiative penalty for a roost of [size] birds.
  static int flockPenalty(int size) {
    if (size <= 2) return 0;
    if (size <= 4) return 1;
    if (size <= 6) return 2;
    return 3;
  }

  /// Initiative total: d20 roll + skill modifier − flock-size penalty.
  static int initiativeTotal({
    required int roll,
    required int skillMod,
    required int roostSize,
  }) =>
      roll + skillMod - flockPenalty(roostSize);

  /// Whether [youTotal] vs [oppTotal] (with roost sizes for the tiebreak)
  /// makes you the first mover. Ties go to the smaller flock, then to you.
  static bool youActFirst({
    required int youTotal,
    required int oppTotal,
    required int youRoostSize,
    required int oppRoostSize,
  }) {
    if (youTotal != oppTotal) return youTotal > oppTotal;
    return youRoostSize <= oppRoostSize;
  }
}
