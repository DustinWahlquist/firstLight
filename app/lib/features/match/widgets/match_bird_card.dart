import 'package:flutter/material.dart';
import '../../../models/match/match_bird.dart';

const matchCardWidth = 162.0;

/// A full in-play bird card. Used in the roost, hand, deploy grid, and
/// discard pile — the trailing affordance and overlays vary by context.
class MatchBirdCard extends StatelessWidget {
  const MatchBirdCard({
    super.key,
    required this.bird,
    this.onTap,
    this.footer,
    this.veilLabel,
    this.selected,
    this.dimmed = false,
  });

  final MatchBird bird;
  final VoidCallback? onTap;

  /// Bottom affordance line (e.g. "Fly +900 km", "enters 2d", "exhausted").
  final Widget? footer;

  /// When set, a translucent veil with this label covers the card
  /// (e.g. a flown bird's "Flew · +900 km").
  final String? veilLabel;

  /// When non-null, shows a circular check badge (filled when true) — deploy.
  final bool? selected;

  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: matchCardWidth,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Art placeholder
                  SizedBox(
                    height: 64,
                    child: CustomPaint(
                      painter: _StripePainter(
                        theme.colorScheme.surfaceContainer,
                        theme.colorScheme.surfaceContainerHigh,
                      ),
                      child: bird.starter
                          ? Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: _Tag('STARTER', theme),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bird.name,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          bird.sci,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Stat('SPD', bird.speed, theme),
                            const SizedBox(width: 14),
                            _Stat('END', bird.endurance, theme),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _EndurancePips(bird: bird),
                        if (footer != null) ...[
                          const SizedBox(height: 8),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (veilLabel != null)
                Positioned.fill(
                  child: Container(
                    color: theme.colorScheme.surface.withValues(alpha: 0.78),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        veilLabel!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              if (selected != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected!
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: selected!
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: selected!
                        ? Icon(Icons.check, size: 14, color: theme.colorScheme.onPrimary)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.theme);
  final String label;
  final int value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 3),
        Text('$value', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _EndurancePips extends StatelessWidget {
  const _EndurancePips({required this.bird});
  final MatchBird bird;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (int i = 0; i < bird.endurance; i++)
          Container(
            margin: const EdgeInsets.only(right: 4),
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < bird.daysLeft
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.surfaceContainerHigh,
            ),
          ),
        const SizedBox(width: 2),
        Text(
          '${bird.daysLeft}d',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.theme);
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 9,
          letterSpacing: 1,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 45° two-tone stripes — the brand's art placeholder.
class _StripePainter extends CustomPainter {
  _StripePainter(this.base, this.stripe);
  final Color base;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 8;
    for (double i = -size.height; i < size.width + size.height; i += 16) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.base != base || old.stripe != stripe;
}
