import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/match/match_rules.dart';
import '../../../domain/match/match_state.dart';
import '../../../models/match/match_bird.dart';
import '../match_controller.dart';
import '../sheets/match_sheets.dart';
import '../widgets/match_bird_card.dart';
import '../widgets/treehouse_icon.dart';
import '../widgets/watcher_token.dart';

/// The day board: a fixed header + turn banner over a vertical 3-station
/// pager — Mara (pull down), the default migration view, and your hand
/// (pull up).
class DayBoardView extends ConsumerStatefulWidget {
  const DayBoardView({super.key});

  @override
  ConsumerState<DayBoardView> createState() => _DayBoardViewState();
}

class _DayBoardViewState extends ConsumerState<DayBoardView> {
  final _pager = PageController(initialPage: 1);

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _tapRoostBird(MatchBird bird) async {
    final s = ref.read(matchControllerProvider);
    if (s.turn != MatchTurn.you || bird.tapped) return;
    final fly = await showActivationSheet(context, bird);
    if (fly == true) {
      ref.read(matchControllerProvider.notifier).flyBird(bird.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(matchControllerProvider);
    final isFriend = ref.read(matchControllerProvider.notifier).isFriend;

    return SafeArea(
      child: Column(
        children: [
          _MatchHeader(day: s.day),
          _TurnBanner(turn: s.turn, screen: s.screen, isFriend: isFriend),
          Expanded(
            child: PageView(
              scrollDirection: Axis.vertical,
              controller: _pager,
              children: [
                _MaraPage(s: s),
                _DefaultPage(s: s, onTapBird: _tapRoostBird),
                _HandPage(s: s),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({required this.day});
  final int day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFE8A23D),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('Day $day · First Light', style: theme.textTheme.titleSmall),
          const Spacer(),
          Text(
            'VS MARA',
            style: theme.textTheme.labelMedium?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.turn, required this.screen, this.isFriend = false});
  final MatchTurn turn;
  final MatchScreen screen;
  final bool isFriend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yourTurn = turn == MatchTurn.you;
    final waitingText = isFriend ? 'Waiting for your opponent…' : 'Mara is flying…';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      color: yourTurn ? const Color(0xFFEBF6FA) : theme.colorScheme.surfaceContainer,
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: yourTurn ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            yourTurn ? 'Your move — tap a bird to fly' : waitingText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: yourTurn ? const Color(0xFF1A7FA8) : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Default station: compact Mara + migration break + your roost ──

class _DefaultPage extends StatelessWidget {
  const _DefaultPage({required this.s, required this.onTapBird});
  final MatchState s;
  final void Function(MatchBird) onTapBird;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _CompactMaraStrip(s: s),
        _MigrationBreak(s: s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'YOUR ROOST · TAP A BIRD TO FLY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: _RoostScroller(roost: s.youRoost, onTapBird: onTapBird)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactMaraStrip extends StatelessWidget {
  const _CompactMaraStrip({required this.s});
  final MatchState s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Text('M', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSecondaryContainer)),
          ),
          const SizedBox(width: 8),
          Text('Mara', style: theme.textTheme.titleSmall),
          const SizedBox(width: 6),
          Text(
            '${s.oppRoost.length} in roost · ${s.oppHand.length} in hand',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            'PULL TO EXPAND ▲',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 1,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The flyway: the race strip with both tokens advancing toward 10,000 km.
class _MigrationBreak extends StatelessWidget {
  const _MigrationBreak({required this.s});
  final MatchState s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lead = s.youKm - s.oppKm;
    final leadText = lead == 0
        ? 'Neck and neck'
        : lead > 0
            ? 'You lead by ${lead.abs()} km'
            : 'Mara leads by ${lead.abs()} km';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'THE MIGRATION',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(leadText, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          _Flyway(youKm: s.youKm, oppKm: s.oppKm, flash: s.flash),
        ],
      ),
    );
  }
}

class _Flyway extends StatelessWidget {
  const _Flyway({required this.youKm, required this.oppKm, required this.flash});
  final int youKm;
  final int oppKm;
  final FlyFlash? flash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 106,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth - 36; // leave room for the destination marker
          double x(int km) => (km / MatchRules.winKm).clamp(0.0, 1.0) * w;
          return Stack(
            children: [
              // dashed route
              Positioned(
                left: 0,
                right: 0,
                top: 52,
                child: CustomPaint(painter: _DashPainter(theme.colorScheme.outlineVariant), size: const Size(double.infinity, 1)),
              ),
              // destination roost marker (the migration's end — a tree house)
              Positioned(
                right: 0,
                top: 38,
                child: TreehouseIcon(color: theme.colorScheme.primary, size: 30),
              ),
              // Mara token (above the line)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutCubic,
                left: x(oppKm),
                top: 18,
                child: _Token(km: oppKm, color: theme.colorScheme.secondary),
              ),
              // Your token (below the line)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutCubic,
                left: x(youKm),
                top: 60,
                child: _Token(km: youKm, color: theme.colorScheme.primary),
              ),
              // axis labels
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _axis('0', theme),
                    _axis('5,000', theme),
                    _axis('10,000 km', theme),
                  ],
                ),
              ),
              if (flash != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${flash!.side == MatchSide.you ? 'You' : 'Mara'} ${flash!.birdName} +${flash!.km} km',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _axis(String label, ThemeData theme) => Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
}

class _Token extends StatelessWidget {
  const _Token({required this.km, required this.color});
  final int km;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WatcherToken(color: color, size: 26),
        const SizedBox(height: 2),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: km, end: km),
          duration: const Duration(milliseconds: 750),
          builder: (_, v, _) => Text(
            '${(v / 1000).toStringAsFixed(1)}k',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dash = 6.0, gap = 5.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

// ── Roost / hand horizontal scrollers ──

class _RoostScroller extends StatelessWidget {
  const _RoostScroller({required this.roost, required this.onTapBird});
  final List<MatchBird> roost;
  final void Function(MatchBird) onTapBird;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (roost.isEmpty) {
      return Center(
        child: Text('No birds in the roost.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }
    return GridView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 rows
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: matchCardWidth,
        childAspectRatio: 0.62,
      ),
      itemCount: roost.length,
      itemBuilder: (context, i) {
        final bird = roost[i];
        return MatchBirdCard(
          bird: bird,
          onTap: () => onTapBird(bird),
          veilLabel: bird.tapped ? 'Flew · +${bird.flyKm} km' : null,
          footer: bird.tapped
              ? null
              : Text(
                  'Fly +${bird.flyKm} km',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        );
      },
    );
  }
}

// ── Mara expanded station ──

class _MaraPage extends StatelessWidget {
  const _MaraPage({required this.s});
  final MatchState s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text('M', style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
              ),
              const SizedBox(width: 10),
              Text('Mara', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text('${s.oppHand.length} in hand', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "MARA'S ROOST",
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: matchCardWidth,
              childAspectRatio: 0.62,
            ),
            itemCount: s.oppRoost.length,
            itemBuilder: (context, i) => MatchBirdCard(bird: s.oppRoost[i]),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('▼ back to the migration', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ),
      ],
    );
  }
}

// ── Your hand station ──

class _HandPage extends ConsumerWidget {
  const _HandPage({required this.s});
  final MatchState s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your hand', style: theme.textTheme.titleMedium),
                  Text('${s.youHand.length} cards · deploy at Night',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              _MiniTile(label: 'Deck', value: '${s.youDeck}'),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => showDiscardSheet(context, s.youDiscard),
                child: _MiniTile(label: 'Discard ›', value: '${s.youDiscard.length}'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: matchCardWidth,
              childAspectRatio: 0.62,
            ),
            itemCount: s.youHand.length,
            itemBuilder: (context, i) => MatchBirdCard(bird: s.youHand[i]),
          ),
        ),
      ],
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleMedium),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
