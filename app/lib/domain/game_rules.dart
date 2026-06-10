/// The rules of First Light: leveling curve, milestones, and catch validity.
/// Pure Dart — no Flutter or Supabase imports — so every rule is unit-testable.
///
/// The server enforces these authoritatively in the log_catch RPC
/// (supabase/migrations/014_server_side_catch.sql) — keep the two in sync.
/// Client-side they drive display (XP bars) and pre-submit fast-fails.
abstract final class GameRules {
  /// XP required to reach each level. Cards start at level 1 with 0 XP.
  static const Map<int, int> levelXpThresholds = {
    1: 0,
    2: 20,
    3: 50,
    4: 90,
    5: 140,
  };

  static int get maxLevel => levelXpThresholds.keys.last;

  static int levelForXp(int xp) {
    var level = 1;
    for (final entry in levelXpThresholds.entries) {
      if (xp >= entry.value) level = entry.key;
    }
    return level;
  }

  static int xpForNextLevel(int currentLevel) =>
      levelXpThresholds[currentLevel + 1] ?? levelXpThresholds.values.last;

  /// Lifer counts that trigger a milestone feed event.
  static const List<int> liferMilestones = [10, 25, 50, 100, 250, 500];

  static bool isLiferMilestone(int liferCount) =>
      liferMilestones.contains(liferCount);

  /// A catch dated after the end of [now]'s calendar day is invalid —
  /// the screenshot claims to be from the future.
  static bool isFutureDated(DateTime catchDate, DateTime now) =>
      catchDate.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));

  static bool isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
