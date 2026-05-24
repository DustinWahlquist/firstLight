import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/bird_card.dart';

class BirdCardTile extends StatelessWidget {
  const BirdCardTile({super.key, required this.card, this.onTap, this.isGrid = false});

  final BirdCard card;
  final VoidCallback? onTap;
  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    return isGrid ? _GridCard(card: card, onTap: onTap) : _ListCard(card: card, onTap: onTap);
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.card, this.onTap});
  final BirdCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpToNext = BirdCard.xpForNextLevel(card.level);
    final xpProgress = card.xp / xpToNext;

    return Card(
      color: theme.colorScheme.surface,
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

class _GridCard extends StatelessWidget {
  const _GridCard({required this.card, this.onTap});
  final BirdCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpToNext = BirdCard.xpForNextLevel(card.level);
    final xpProgress = card.xp / xpToNext;

    return Card(
      color: theme.colorScheme.surface,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Art area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: card.lineArtUrl != null
                    ? SvgPicture.network(
                        card.lineArtUrl!,
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => _StripedBackground(theme: theme),
                      )
                    : _StripedBackground(theme: theme),
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.speciesName,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Lv ${card.level}', style: theme.textTheme.labelSmall),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: xpProgress.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: theme.colorScheme.surfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.firstCatchLocation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripedBackground extends StatelessWidget {
  const _StripedBackground({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StripePainter(theme.colorScheme.surfaceContainerHigh),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 12;
    for (double i = -size.height; i < size.width + size.height; i += 24) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.color != color;
}
