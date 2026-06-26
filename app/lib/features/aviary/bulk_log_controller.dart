import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/bird_card.dart';
import '../../models/bulk_parse.dart';
import '../../models/parse_result.dart';
import 'aviary_providers.dart';

/// A repeat catch that gained XP — carries before/after so the summary can
/// animate the XP bar like the single-catch flow.
class BulkRepeat {
  const BulkRepeat({required this.before, required this.after});
  final BirdCard before;
  final BirdCard after;
  int get gained => after.xp - before.xp;
  bool get leveledUp => after.level > before.level;
}

/// Outcome of a bulk commit, for the summary screen.
class BulkSummary {
  const BulkSummary({
    required this.newLifers,
    required this.repeats,
    required this.duplicates,
  });

  final List<BirdCard> newLifers;
  final List<BulkRepeat> repeats;
  final int duplicates; // server rejected as already-logged today

  int get logged => newLifers.length + repeats.length;
  int get xpAwarded => repeats.fold(0, (s, r) => s + r.gained);
  int get leveledUp => repeats.where((r) => r.leveledUp).length;
}

/// Progress while committing (done/total), or null when idle.
typedef BulkCommitProgress = ({int done, int total});

final bulkLogControllerProvider =
    NotifierProvider<BulkLogController, BulkCommitProgress?>(BulkLogController.new);

/// Commits a bulk log: uploads the screenshot once, then logs each chosen bird
/// through the authoritative log_catch RPC (which dedups/awards XP), and fires
/// off enrichment for new species.
class BulkLogController extends Notifier<BulkCommitProgress?> {
  @override
  BulkCommitProgress? build() => null;

  Future<BulkSummary> commit({
    required List<BulkBird> birds,
    required DateTime date,
    required String location,
    double? latitude,
    double? longitude,
    required File screenshot,
  }) async {
    final aviary = ref.read(aviaryRepositoryProvider);
    final url = await aviary.uploadScreenshot(screenshot);

    final newLifers = <BirdCard>[];
    final repeats = <BulkRepeat>[];
    var duplicates = 0;

    state = (done: 0, total: birds.length);
    for (var i = 0; i < birds.length; i++) {
      final b = birds[i];
      final parse = ParseResult(
        speciesName: b.speciesName,
        scientificName: b.scientificName,
        sightingRarity: 'Common',
        date: date,
        location: location,
        description: '',
        facts: const [],
        migrationSpeed: 5,
        endurance: 3,
        latitude: latitude,
        longitude: longitude,
      );
      try {
        final outcome = await aviary.submitCatch(parse: parse, screenshotUrl: url);
        switch (outcome['kind'] as String?) {
          case 'new_lifer':
            newLifers.add(BirdCard.fromJson(Map<String, dynamic>.from(outcome['card'] as Map)));
          case 'xp_awarded':
            final after = BirdCard.fromJson(Map<String, dynamic>.from(outcome['card'] as Map));
            final delta = (outcome['xp_awarded'] as int?) ?? 0;
            final prevLevel = (outcome['previous_level'] as int?) ?? after.level;
            repeats.add(BulkRepeat(
              before: after.copyWith(xp: after.xp - delta, level: prevLevel),
              after: after,
            ));
          case 'duplicate':
            duplicates++;
        }
      } catch (_) {
        // One bird failing shouldn't sink the batch.
      }
      state = (done: i + 1, total: birds.length);
    }
    state = null;

    // Backfill flavor/art for new species, then refresh once it lands.
    if (newLifers.isNotEmpty) {
      final species = [
        for (final c in newLifers) (speciesName: c.speciesName, scientificName: c.scientificName),
      ];
      unawaited(
        aviary.enrichSpecies(species).then((_) => ref.invalidate(aviaryProvider)).catchError((_) {}),
      );
    }
    ref.invalidate(aviaryProvider);

    return BulkSummary(
      newLifers: newLifers,
      repeats: repeats,
      duplicates: duplicates,
    );
  }
}
