import '../data/aviary_repository.dart';
import '../models/bulk_parse.dart';
import 'game_rules.dart';

/// Why a parsed bird won't be logged.
enum BulkSkipReason {
  /// No blue checkmark — heard, not a verified catch.
  notVerified,

  /// Already logged this species on the screenshot's day.
  alreadyLoggedToday,

  /// The whole screenshot is dated in the future.
  futureDated,
}

class BulkPlanItem {
  const BulkPlanItem({required this.bird, required this.reason});

  final BulkBird bird;

  /// null = eligible to upload; otherwise why it's skipped.
  final BulkSkipReason? reason;

  bool get eligible => reason == null;
}

class BulkPlan {
  const BulkPlan(this.items);
  final List<BulkPlanItem> items;

  List<BulkPlanItem> get eligible => items.where((i) => i.eligible).toList();
  List<BulkPlanItem> get skipped => items.where((i) => !i.eligible).toList();
}

/// Pure partition: classify each bird given whether the screenshot is
/// future-dated and which species are already logged that day. Kept separate
/// from I/O so it's unit-testable.
BulkPlan partitionBirds(
  List<BulkBird> birds, {
  required bool futureDated,
  required Set<String> alreadyLogged,
}) {
  return BulkPlan([
    for (final b in birds)
      BulkPlanItem(
        bird: b,
        reason: !b.verified
            ? BulkSkipReason.notVerified
            : futureDated
                ? BulkSkipReason.futureDated
                : alreadyLogged.contains(b.speciesName)
                    ? BulkSkipReason.alreadyLoggedToday
                    : null,
      ),
  ]);
}

/// Builds a [BulkPlan] from a parsed list, probing the collection for
/// species already logged on the screenshot's date.
class BulkLogUseCase {
  BulkLogUseCase({required this._aviary, this._now = DateTime.now});

  final AviaryRepository _aviary;
  final DateTime Function() _now;

  Future<BulkPlan> plan(BulkParse parse) async {
    final futureDated = GameRules.isFutureDated(parse.date, _now());

    final alreadyLogged = <String>{};
    if (!futureDated) {
      // Only verified birds are candidates worth probing.
      final verified = parse.birds.where((b) => b.verified);
      for (final b in verified) {
        final card = await _aviary.fetchCard(b.speciesName);
        if (card != null && await _aviary.hasCaughtOnDate(card.id, parse.date)) {
          alreadyLogged.add(b.speciesName);
        }
      }
    }

    return partitionBirds(
      parse.birds,
      futureDated: futureDated,
      alreadyLogged: alreadyLogged,
    );
  }
}
