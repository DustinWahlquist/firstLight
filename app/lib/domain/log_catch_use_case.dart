import 'dart:io';
import '../data/aviary_repository.dart';
import '../models/bird_card.dart';
import '../models/parse_result.dart';
import 'game_rules.dart';

sealed class LogCatchResult {
  const LogCatchResult();
}

/// First catch of a species — a new card was created.
class LogCatchNewLifer extends LogCatchResult {
  const LogCatchNewLifer(this.card);
  final BirdCard card;
}

/// Repeat catch — XP was added to the existing card.
class LogCatchXpAwarded extends LogCatchResult {
  const LogCatchXpAwarded({required this.before, required this.after});
  final BirdCard before;
  final BirdCard after;

  bool get leveledUp => after.level > before.level;
}

/// This bird was already caught on the screenshot's calendar day.
class LogCatchDuplicate extends LogCatchResult {
  const LogCatchDuplicate(this.date);

  /// The day in question — the screenshot's date, not necessarily today.
  final DateTime date;
}

/// The screenshot is dated after today.
class LogCatchFutureDated extends LogCatchResult {
  const LogCatchFutureDated();
}

/// Logs a catch from a parsed Merlin screenshot. The server-side log_catch
/// RPC is the authority on every rule — XP by sighting rarity, level-ups,
/// once-per-day, future dates, feed events, milestones. The checks here are
/// UX fast-fails only, so obvious rejections cost no upload.
class LogCatchUseCase {
  LogCatchUseCase({
    required this._aviary,
    this._now = DateTime.now,
  });

  final AviaryRepository _aviary;
  final DateTime Function() _now;

  /// Pre-submission rejection check — run this before asking the user for
  /// anything (like a manual location), so wasted effort fails fast.
  /// Returns null when the catch looks loggable.
  Future<LogCatchResult?> precheck(ParseResult parse) async {
    if (GameRules.isFutureDated(parse.date, _now())) {
      return const LogCatchFutureDated();
    }
    final existing = await _aviary.fetchCard(parse.speciesName);
    if (existing != null &&
        await _aviary.hasCaughtOnDate(existing.id, parse.date)) {
      return LogCatchDuplicate(parse.date);
    }
    return null;
  }

  Future<LogCatchResult> call({
    required ParseResult parse,
    required File screenshot,
  }) async {
    final rejection = await precheck(parse);
    if (rejection != null) return rejection;

    final existing = await _aviary.fetchCard(parse.speciesName);
    final screenshotUrl = await _aviary.uploadScreenshot(screenshot);
    final outcome = await _aviary.submitCatch(
      parse: parse,
      screenshotUrl: screenshotUrl,
    );

    switch (outcome['kind'] as String?) {
      case 'new_lifer':
        return LogCatchNewLifer(_cardFrom(outcome));
      case 'xp_awarded':
        // `existing` is always set here: the server only awards XP to a
        // card it found, which the fetch above already loaded.
        return LogCatchXpAwarded(before: existing!, after: _cardFrom(outcome));
      case 'duplicate':
        return LogCatchDuplicate(parse.date);
      case 'future_dated':
        return const LogCatchFutureDated();
      case final kind:
        throw StateError('log_catch returned unknown kind: $kind');
    }
  }

  BirdCard _cardFrom(Map<String, dynamic> outcome) =>
      BirdCard.fromJson(Map<String, dynamic>.from(outcome['card'] as Map));
}
