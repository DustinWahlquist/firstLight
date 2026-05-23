import 'aviary_card.dart';

/// The outcome returned after processing a screenshot import.
sealed class CatchResult {
  const CatchResult();
}

/// A brand-new lifer — card was created at Level 1.
class NewLifer extends CatchResult {
  const NewLifer(this.card);
  final AviaryCard card;
}

/// An existing species — XP was awarded; leveled up if threshold crossed.
class XpAwarded extends CatchResult {
  const XpAwarded({
    required this.card,
    required this.xpGained,
    required this.didLevelUp,
  });
  final AviaryCard card;
  final int xpGained;
  final bool didLevelUp;
}

/// Catch already logged today for this species.
class DailyLimitReached extends CatchResult {
  const DailyLimitReached(this.speciesName);
  final String speciesName;
}

/// Claude could not confidently parse the screenshot.
class ParseFailure extends CatchResult {
  const ParseFailure(this.reason);
  final String reason;
}
