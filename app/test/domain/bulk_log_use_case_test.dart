import 'package:flutter_test/flutter_test.dart';
import 'package:first_light/domain/bulk_log_use_case.dart';
import 'package:first_light/models/bulk_parse.dart';

BulkBird _bird(String name, {required bool verified}) =>
    BulkBird(speciesName: name, scientificName: '$name sci', verified: verified);

void main() {
  group('partitionBirds', () {
    test('splits verified/new vs not-verified vs already-logged', () {
      final plan = partitionBirds(
        [
          _bird('Northern Flicker', verified: true), // eligible
          _bird('House Sparrow', verified: false), // heard only
          _bird('Song Sparrow', verified: true), // already logged today
        ],
        futureDated: false,
        alreadyLogged: {'Song Sparrow'},
      );

      expect(plan.eligible.map((i) => i.bird.speciesName), ['Northern Flicker']);
      final reasons = {for (final i in plan.skipped) i.bird.speciesName: i.reason};
      expect(reasons['House Sparrow'], BulkSkipReason.notVerified);
      expect(reasons['Song Sparrow'], BulkSkipReason.alreadyLoggedToday);
    });

    test('a future-dated screenshot skips every verified bird', () {
      final plan = partitionBirds(
        [
          _bird('Osprey', verified: true),
          _bird('Mallard', verified: false),
        ],
        futureDated: true,
        alreadyLogged: const {},
      );

      expect(plan.eligible, isEmpty);
      final reasons = {for (final i in plan.items) i.bird.speciesName: i.reason};
      expect(reasons['Osprey'], BulkSkipReason.futureDated);
      // Not-verified takes precedence and is reported as such.
      expect(reasons['Mallard'], BulkSkipReason.notVerified);
    });

    test('all eligible when verified, not logged, and present-dated', () {
      final plan = partitionBirds(
        [_bird('Arctic Tern', verified: true), _bird('Snow Goose', verified: true)],
        futureDated: false,
        alreadyLogged: const {},
      );
      expect(plan.eligible.length, 2);
      expect(plan.skipped, isEmpty);
    });
  });
}
