import 'package:flutter/material.dart';
import '../../../models/bird_card.dart';

class BirdCardTile extends StatelessWidget {
  const BirdCardTile({super.key, required this.card, this.onTap});

  final BirdCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpToNext = BirdCard.xpForNextLevel(card.level);
    final xpProgress = card.xp / xpToNext;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.speciesName, style: theme.textTheme.titleMedium),
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
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${card.xp} / $xpToNext XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${card.firstCatchLocation} · ${_formatDate(card.firstCatchDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
