import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import '../../core/config.dart';
import '../../core/providers.dart';
import '../../domain/game_rules.dart';
import '../../domain/match/match_rules.dart';
import '../../domain/sighting_rarity.dart';
import '../../models/bird_card.dart';
import '../../models/catch_log.dart';
import 'aviary_providers.dart';

class BirdDetailScreen extends ConsumerStatefulWidget {
  const BirdDetailScreen({super.key, required this.card, this.ownerName});

  final BirdCard card;
  final String? ownerName;

  @override
  ConsumerState<BirdDetailScreen> createState() => _BirdDetailScreenState();
}

class _BirdDetailScreenState extends ConsumerState<BirdDetailScreen> {
  bool _showAllLogs = false;
  String? _lineArtUrl;

  @override
  void initState() {
    super.initState();
    _lineArtUrl = widget.card.lineArtUrl;
    if (_lineArtUrl == null) _loadLineArt();
  }

  Future<void> _loadLineArt() async {
    final url = await ref
        .read(aviaryRepositoryProvider)
        .fetchSpeciesLineArt(widget.card.speciesName);
    if (mounted && url != null) setState(() => _lineArtUrl = url);
  }

  Future<void> _toggleDeck({required bool currentlyIn, required int deckCount}) async {
    final repo = ref.read(aviaryRepositoryProvider);
    if (!currentlyIn && deckCount >= MatchRules.deckCapacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Deck is full — you must remove a bird before you can add this one.',
          ),
        ),
      );
      return;
    }
    await repo.setInDeck(widget.card.id, !currentlyIn);
    ref.invalidate(deckProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = widget.card;
    final catchLogs = ref.watch(catchLogsProvider(card.id));
    final isOwn = widget.ownerName == null;
    final deck = ref.watch(deckProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ownerName != null
            ? "${widget.ownerName}'s ${card.speciesName}"
            : card.speciesName),
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
          Center(child: _TradingCard(card: card, lineArtUrl: _lineArtUrl)),
          const SizedBox(height: 16),
          if (isOwn) ...[
            _DeckButton(
              cardId: card.id,
              deck: deck,
              onToggle: (currentlyIn, count) =>
                  _toggleDeck(currentlyIn: currentlyIn, deckCount: count),
            ),
            const SizedBox(height: 16),
          ],
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
          catchLogs.maybeWhen(
            data: (logs) {
              final pins = logs
                  .where((l) => l.latitude != null && l.longitude != null)
                  .toList();
              if (pins.isEmpty) return const SizedBox.shrink();
              final avgLat = pins.map((l) => l.latitude!).reduce((a, b) => a + b) / pins.length;
              final avgLng = pins.map((l) => l.longitude!).reduce((a, b) => a + b) / pins.length;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SectionCard(
                    label: 'CATCH LOCATIONS',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      child: SizedBox(
                        height: 180,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(avgLat, avgLng),
                            initialZoom: pins.length == 1 ? 8 : 4,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: osmUserAgentPackageName,
                            ),
                            MarkerLayer(
                              markers: pins.map((l) => Marker(
                                point: LatLng(l.latitude!, l.longitude!),
                                width: 28,
                                height: 28,
                                child: Icon(
                                  Icons.flutter_dash,
                                  size: 24,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
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
  const _TradingCard({required this.card, this.lineArtUrl});
  final BirdCard card;
  final String? lineArtUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpToNext = GameRules.xpForNextLevel(card.level);
    final xpProgress = (card.xp / xpToNext).clamp(0.0, 1.0);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 2.5),
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
                  if (lineArtUrl != null)
                    SvgPicture.network(
                      lineArtUrl!,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else ...[
                    CustomPaint(painter: _StripePainter()),
                    Center(
                      child: Text(
                        'illustration pending',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
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

}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
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

    // Built as rows (not side-by-side columns) so a wrapping value — like a
    // long location — can't push its neighbors out of alignment.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoCell(
                  label: 'Catches',
                  value: '${card.catchCount}',
                  theme: theme,
                  centered: true,
                ),
              ),
              Expanded(
                child: _InfoCell(
                  label: 'Level',
                  value: '${card.level}',
                  theme: theme,
                  centered: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoCell(
                  label: 'First seen',
                  value: dateStr,
                  theme: theme,
                  small: true,
                  centered: true,
                ),
              ),
              Expanded(
                child: _InfoCell(
                  label: 'Location',
                  value: card.firstCatchLocation,
                  theme: theme,
                  small: true,
                  centered: true,
                ),
              ),
            ],
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
    this.centered = false,
  });
  final String label;
  final String value;
  final ThemeData theme;
  final bool small;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    final cross = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      children: [
        Text(
          label,
          textAlign: align,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          textAlign: align,
          style: small ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall,
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
    final color = switch (SightingRarity.fromString(rarity)) {
      SightingRarity.common => theme.colorScheme.outline,
      SightingRarity.uncommon => theme.colorScheme.secondary,
      SightingRarity.rare => theme.colorScheme.primary,
    };
    return (color, label);
  }
}

class _DeckButton extends StatelessWidget {
  const _DeckButton({required this.cardId, required this.deck, required this.onToggle});
  final String cardId;
  final AsyncValue<List<BirdCard>> deck;
  final void Function(bool currentlyIn, int count) onToggle;

  @override
  Widget build(BuildContext context) {
    final cards = deck.valueOrNull;
    final count = cards?.length ?? 0;
    final inDeck = cards?.any((c) => c.id == cardId) ?? false;
    final loading = cards == null && deck.isLoading;

    if (inDeck) {
      return OutlinedButton.icon(
        onPressed: loading ? null : () => onToggle(true, count),
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('In your deck · Remove'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
      );
    }
    return FilledButton.icon(
      onPressed: loading ? null : () => onToggle(false, count),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add to deck'),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
    );
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
