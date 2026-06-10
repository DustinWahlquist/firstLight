import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/bird_card.dart';
import '../../models/catch_log.dart';

/// The signed-in user's collection, with line art backfilled from the shared
/// species cache for cards created before art generation existed.
final aviaryProvider = FutureProvider<List<BirdCard>>((ref) async {
  final repo = ref.watch(aviaryRepositoryProvider);
  final cards = await repo.fetchAviary();
  return Future.wait(
    cards.map((c) async {
      if (c.lineArtUrl != null) return c;
      final url = await repo.fetchSpeciesLineArt(c.speciesName);
      return url != null ? c.copyWith(lineArtUrl: url) : c;
    }),
  );
});

final catchLogsProvider =
    FutureProvider.family<List<CatchLog>, String>((ref, cardId) {
  return ref.watch(aviaryRepositoryProvider).fetchCatchLogs(cardId);
});
