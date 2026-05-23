import 'package:flutter/material.dart';
import '../../../models/bird_card.dart';

class BirdCardTile extends StatelessWidget {
  const BirdCardTile({super.key, required this.card});

  final BirdCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpToNext = BirdCard.xpForNextLevel(card.level);
    final xpProgress = card.xp / xpToNext;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.speciesName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    card.rarity.label,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Lv ${card.level}', style: theme.textTheme.labelMedium),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: xpProgress.clamp(0.0, 1.0),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${card.xp} / $xpToNext XP', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${card.firstCatchLocation} · ${_formatDate(card.firstCatchDate)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
