import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';
import '../../data/match_repository.dart';
import 'match_controller.dart';

final matchesListProvider = FutureProvider.autoDispose<List<MatchSummary>>(
  (ref) => ref.watch(matchRepositoryProvider).listMatches(),
);

/// Loads a match (bot or friend) into the controller's cache and opens the
/// board. The controller reads the cached perspective + mode.
Future<void> openMatchById(BuildContext context, WidgetRef ref, String id) async {
  try {
    await ref.read(matchRepositoryProvider).openMatch(id);
    ref.read(activeMatchIdProvider.notifier).state = id;
    if (context.mounted) await context.push('/match');
    ref.invalidate(matchesListProvider);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open match: $e')),
      );
    }
  }
}

Future<void> startBotMatch(BuildContext context, WidgetRef ref) async {
  try {
    final id = await ref.read(matchRepositoryProvider).startBotMatch();
    ref.read(activeMatchIdProvider.notifier).state = id;
    if (context.mounted) await context.push('/match');
    ref.invalidate(matchesListProvider);
  } catch (e, st) {
    debugPrint('startBotMatch failed: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start match: $e')),
      );
    }
  }
}

class ActiveGamesScreen extends ConsumerStatefulWidget {
  const ActiveGamesScreen({super.key});

  @override
  ConsumerState<ActiveGamesScreen> createState() => _ActiveGamesScreenState();
}

class _ActiveGamesScreenState extends ConsumerState<ActiveGamesScreen> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    // Live-refresh the list when any of my matches change (new challenge,
    // an accept, or an opponent's move once live play ships).
    _channel = Supabase.instance.client
        .channel('matches-list')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matches',
          callback: (_) {
            if (mounted) ref.invalidate(matchesListProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) Supabase.instance.client.removeChannel(_channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Play a bot, or challenge a friend from their profile.',
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

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    await ref.read(matchRepositoryProvider).acceptChallenge(game.id);
    ref.invalidate(matchesListProvider);
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    await ref.read(matchRepositoryProvider).declineChallenge(game.id);
    ref.invalidate(matchesListProvider);
  }

  void _open(BuildContext context, WidgetRef ref) {
    if (game.isOutgoingInvite) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Waiting for ${game.otherName} to accept')),
      );
      return;
    }
    openMatchById(context, ref, game.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final (statusText, statusColor) = switch (game) {
      MatchSummary(isIncomingInvite: true) => ('Challenged you to a race', theme.colorScheme.primary),
      MatchSummary(isOutgoingInvite: true) => ('Waiting for ${game.otherName}…', theme.colorScheme.onSurfaceVariant),
      MatchSummary(isComplete: true) => ('Finished', theme.colorScheme.onSurfaceVariant),
      MatchSummary(isBot: true) => ('Day ${game.day} · tap to play', theme.colorScheme.primary),
      _ => ('Day ${game.day} · in progress', theme.colorScheme.onSurfaceVariant),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: game.isIncomingInvite ? null : () => _open(context, ref),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: game.isIncomingInvite ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: game.isIncomingInvite ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.secondaryContainer,
              backgroundImage: game.otherAvatarUrl != null ? NetworkImage(game.otherAvatarUrl!) : null,
              child: game.otherAvatarUrl != null
                  ? null
                  : Icon(
                      game.isBot ? Icons.smart_toy_outlined : Icons.person_outline,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('vs ${game.otherName}', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(statusText, style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (game.isIncomingInvite) ...[
              TextButton(onPressed: () => _decline(context, ref), child: const Text('Decline')),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: () => _accept(context, ref),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('Accept'),
              ),
            ] else
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
