import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../data/match_repository.dart';
import 'match_controller.dart';

final matchesListProvider = FutureProvider.autoDispose<List<MatchSummary>>(
  (ref) => ref.watch(matchRepositoryProvider).listMatches(),
);

/// Loads a match into the controller's cache, marks it active, and opens it.
/// Refreshes the list when the player returns.
Future<void> openMatchById(BuildContext context, WidgetRef ref, String id) async {
  await ref.read(matchRepositoryProvider).openMatch(id);
  ref.read(activeMatchIdProvider.notifier).state = id;
  if (context.mounted) await context.push('/match');
  ref.invalidate(matchesListProvider);
}

Future<void> startBotMatch(BuildContext context, WidgetRef ref) async {
  final id = await ref.read(matchRepositoryProvider).startBotMatch();
  ref.read(activeMatchIdProvider.notifier).state = id;
  if (context.mounted) await context.push('/match');
  ref.invalidate(matchesListProvider);
}

class ActiveGamesScreen extends ConsumerWidget {
  const ActiveGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final games = ref.watch(matchesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => startBotMatch(context, ref),
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Play a bot'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(matchesListProvider),
        child: games.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (list) {
            if (list.isEmpty) return _EmptyState();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _GameTile(game: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 140),
        Icon(Icons.sports_esports_outlined, size: 64, color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Text(
          'No games yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap “Play a bot” to race the migration.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _GameTile extends ConsumerWidget {
  const _GameTile({required this.game});
  final MatchSummary game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lead = game.youKm - game.oppKm;

    final (statusText, statusColor) = switch (game) {
      MatchSummary(isComplete: true, winner: 'you') => ('You won', theme.colorScheme.primary),
      MatchSummary(isComplete: true) => ('Mara won', theme.colorScheme.onSurfaceVariant),
      MatchSummary(isYourTurn: true) => ('Your move', theme.colorScheme.primary),
      _ => ('${game.opponentName} is flying…', theme.colorScheme.onSurfaceVariant),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => openMatchById(context, ref, game.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: game.isYourTurn ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: game.isYourTurn ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(
                game.mode == 'bot' ? Icons.smart_toy_outlined : Icons.person_outline,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('vs ${game.opponentName}', style: theme.textTheme.titleSmall),
                      const SizedBox(width: 8),
                      Text(
                        'Day ${game.day}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(statusText, style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(game.youKm / 1000).toStringAsFixed(1)}k',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                ),
                Text(
                  lead == 0 ? 'even' : lead > 0 ? '+${(lead / 1000).toStringAsFixed(1)}k' : '${(lead / 1000).toStringAsFixed(1)}k',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
