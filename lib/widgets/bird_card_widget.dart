import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/aviary_card.dart';
import 'xp_bar_widget.dart';

class BirdCardWidget extends StatelessWidget {
  const BirdCardWidget({super.key, required this.card});

  final AviaryCard card;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardArt(screenshotUrl: card.screenshotUrl),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.speciesName,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _RarityChip(rarity: card.rarity),
                    const Spacer(),
                    Text(
                      'Lv ${card.level}',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: cs.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                XpBarWidget(card: card),
                if (card.firstCatchLocation != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${card.firstCatchLocation}  ·  ${DateFormat.yMMMd().format(card.firstCatchDate)}',
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardArt extends StatelessWidget {
  const _CardArt({this.screenshotUrl});

  final String? screenshotUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: screenshotUrl != null
          ? Image.network(screenshotUrl!, fit: BoxFit.cover)
          : Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.flutter_dash, size: 48),
            ),
    );
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({required this.rarity});

  final Rarity rarity;

  static const _labels = {
    Rarity.common: 'Common',
    Rarity.somewhatRare: 'Rare',
    Rarity.ultraRare: 'Ultra Rare',
  };

  static const _colors = {
    Rarity.common: Color(0xFF78909C),
    Rarity.somewhatRare: Color(0xFF1976D2),
    Rarity.ultraRare: Color(0xFF7B1FA2),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _colors[rarity],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _labels[rarity]!,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  }
}
