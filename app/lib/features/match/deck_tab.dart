import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../domain/match/match_rules.dart';
import '../../models/bird_card.dart';
import '../aviary/aviary_providers.dart';

/// The "Your deck" tab of the Games screen: the cards the player has flagged
/// for match play. Birds are added/removed from a bird's detail page; here the
/// deck is reviewed and trimmed.
class DeckTab extends ConsumerWidget {
  const DeckTab({super.key});

  Future<void> _remove(WidgetRef ref, BirdCard card) async {
    await ref.read(aviaryRepositoryProvider).setInDeck(card.id, false);
    ref.invalidate(deckProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(deckProvider),
      child: deck.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [Padding(padding: const EdgeInsets.all(24), child: Text('Error: $e'))],
        ),
        data: (cards) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _DeckHeader(count: cards.length),
            const SizedBox(height: 12),
            if (cards.isEmpty)
              const _DeckEmpty()
            else
              for (final c in cards) ...[
                _DeckRow(card: c, onRemove: () => _remove(ref, c)),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _DeckHeader extends StatelessWidget {
  const _DeckHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final full = count >= MatchRules.deckCapacity;
    return Row(
      children: [
        Text('Your deck', style: theme.textTheme.titleMedium),
        const Spacer(),
        Text(
          '$count / ${MatchRules.deckCapacity}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: full ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.card, required this.onRemove});
  final BirdCard card;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push('/bird-detail', extra: (card: card, ownerName: null)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.speciesName, style: theme.textTheme.titleSmall),
                    Text(
                      card.scientificName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SPD ${card.migrationSpeed} · END ${card.endurance} · Lv ${card.level}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline),
                color: theme.colorScheme.error,
                tooltip: 'Remove from deck',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckEmpty extends StatelessWidget {
  const _DeckEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.style_outlined, size: 56, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 14),
          Text(
            'Your deck is empty',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            'Open a bird in your Aviary and tap “Add to deck.”',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Go to Aviary'),
          ),
        ],
      ),
    );
  }
}
