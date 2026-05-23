import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/bird_card.dart';
import '../../models/catch_log.dart';
import '../../models/rarity.dart';

final _catchLogsProvider =
    FutureProvider.family<List<CatchLog>, String>((ref, cardId) {
  return ref.watch(supabaseServiceProvider).fetchCatchLogs(cardId);
});

class BirdDetailScreen extends ConsumerStatefulWidget {
  const BirdDetailScreen({super.key, required this.card});

  final BirdCard card;

  @override
  ConsumerState<BirdDetailScreen> createState() => _BirdDetailScreenState();
}

class _BirdDetailScreenState extends ConsumerState<BirdDetailScreen> {
  bool _showAllLogs = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = widget.card;
    final catchLogs = ref.watch(_catchLogsProvider(card.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: Text(card.speciesName),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Center(child: _TradingCard(card: card)),
          const SizedBox(height: 16),
          _SectionCard(
            label: 'CATCH INFO',
            child: _CatchInfoGrid(card: card),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            label: 'BIRD STATS',
            child: _BirdStatsSection(card: card),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            label: 'ABOUT',
            child: _AboutSection(card: card),
          ),
          const SizedBox(height: 12),
          catchLogs.when(
            loading: () => const _SectionCard(
              label: 'CATCH LOG',
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => _SectionCard(
              label: 'CATCH LOG',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading logs: $e'),
              ),
            ),
            data: (logs) => _SectionCard(
              label: 'CATCH LOG',
              child: _CatchLogSection(
                logs: logs,
                showAll: _showAllLogs,
                onToggle: () => setState(() => _showAllLogs = !_showAllLogs),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradingCard extends StatelessWidget {
  const _TradingCard({required this.card});
  final BirdCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (borderColor, glowColor) = _rarityColors(theme, card.rarity);
    final xpToNext = BirdCard.xpForNextLevel(card.level);
    final xpProgress = (card.xp / xpToNext).clamp(0.0, 1.0);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 148,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _StripePainter()),
                  Center(
                    child: Text(
                      'bird illustration',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.speciesName, style: theme.textTheme.titleMedium),
                Text(
                  card.scientificName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Lv ${card.level}', style: theme.textTheme.labelMedium),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: xpProgress,
                          minHeight: 4,
                          backgroundColor: theme.colorScheme.surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color?) _rarityColors(ThemeData theme, Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return (theme.colorScheme.outlineVariant, null);
      case Rarity.somewhatRare:
        return (theme.colorScheme.secondary, theme.colorScheme.secondaryContainer);
      case Rarity.ultraRare:
        return (theme.colorScheme.primary, theme.colorScheme.primaryContainer);
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _CatchInfoGrid extends StatelessWidget {
  const _CatchInfoGrid({required this.card});
  final BirdCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final date = card.firstCatchDate;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoCell(
                  label: 'Catches',
                  value: '${card.catchCount}',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _InfoCell(
                  label: 'First seen',
                  value: dateStr,
                  theme: theme,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoCell(
                  label: 'Level',
                  value: '${card.level}',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _InfoCell(
                  label: 'Location',
                  value: card.firstCatchLocation,
                  theme: theme,
                  small: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.label,
    required this.value,
    required this.theme,
    this.small = false,
  });
  final String label;
  final String value;
  final ThemeData theme;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: small ? theme.textTheme.bodySmall : theme.textTheme.headlineSmall,
        ),
      ],
    );
  }
}

class _BirdStatsSection extends StatelessWidget {
  const _BirdStatsSection({required this.card});
  final BirdCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          _StatBar(
            label: 'Migration Speed',
            value: '${card.migrationSpeed * 100} km',
            progress: card.migrationSpeed / 10,
            color: theme.colorScheme.primary,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _StatBar(
            label: 'Endurance',
            value: '${card.endurance}',
            progress: card.endurance / 5,
            color: theme.colorScheme.secondary,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.theme,
  });
  final String label;
  final String value;
  final double progress;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(value, style: theme.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.card});
  final BirdCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.description.isEmpty
                ? 'No description available.'
                : card.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          if (card.facts.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'FIELD NOTES',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            for (final fact in card.facts)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(fact, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CatchLogSection extends StatelessWidget {
  const _CatchLogSection({
    required this.logs,
    required this.showAll,
    required this.onToggle,
  });
  final List<CatchLog> logs;
  final bool showAll;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (logs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Text(
          'No catches recorded.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    const maxVisible = 5;
    final visible = showAll ? logs : logs.take(maxVisible).toList();
    final overflow = logs.length - maxVisible;

    return Column(
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: theme.colorScheme.outlineVariant,
            ),
          _CatchLogEntry(log: visible[i]),
        ],
        if (logs.length > maxVisible)
          TextButton(
            onPressed: onToggle,
            child: Text(
              showAll
                  ? 'Show less'
                  : 'Show $overflow more',
            ),
          ),
      ],
    );
  }
}

class _CatchLogEntry extends StatelessWidget {
  const _CatchLogEntry({required this.log});
  final CatchLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = log.caughtAt;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final (rarityColor, xpLabel) = _rarityInfo(theme, log.sightingRarity, log.xpAwarded);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.location.isEmpty ? 'Unknown location' : log.location,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '·',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      log.sightingRarity,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: rarityColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              xpLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _rarityInfo(ThemeData theme, String rarity, int xpAwarded) {
    final label = xpAwarded == 0 ? 'First catch' : '+$xpAwarded XP';
    final lower = rarity.toLowerCase();
    if (lower.contains('uncommon') || lower.contains('somewhat')) {
      return (theme.colorScheme.secondary, label);
    } else if (lower.contains('rare') || lower.contains('ultra')) {
      return (theme.colorScheme.primary, label);
    }
    return (theme.colorScheme.outline, label);
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDAD4C9)
      ..strokeWidth = 1.0;

    const spacing = 14.0;
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    for (double i = -diagonal; i < diagonal * 2; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}
