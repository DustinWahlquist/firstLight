import 'package:flutter/material.dart';

import '../models/aviary_card.dart';

class XpBarWidget extends StatelessWidget {
  const XpBarWidget({super.key, required this.card});

  final AviaryCard card;

  @override
  Widget build(BuildContext context) {
    final progress = (card.xp / card.xpForNextLevel).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              '${card.xp} / ${card.xpForNextLevel}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
