import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/match/match_rules.dart';
import '../../../domain/match/match_state.dart';
import '../match_controller.dart';
import '../match_theme.dart';

/// "First Light breaks" — both Watchers roll for initiative; higher total
/// acts first.
class InitiativeView extends ConsumerStatefulWidget {
  const InitiativeView({super.key});

  @override
  ConsumerState<InitiativeView> createState() => _InitiativeViewState();
}

class _InitiativeViewState extends ConsumerState<InitiativeView> {
  bool _spinning = false;
  Timer? _spinTimer;
  final _rng = Random();
  int _spinFace = 14;

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }

  void _roll() {
    setState(() => _spinning = true);
    var frames = 0;
    _spinTimer = Timer.periodic(const Duration(milliseconds: 55), (t) {
      frames++;
      setState(() => _spinFace = 1 + _rng.nextInt(20));
      if (frames >= 13) {
        t.cancel();
        ref.read(matchControllerProvider.notifier).rollInitiative();
        setState(() => _spinning = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = ref.watch(matchControllerProvider);
    final rolled = s.initRolled;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MatchPalette.initiativeTop, Color(0xFFF5F0E8)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'DAY ${s.day} · FIRST LIGHT BREAKS',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: MatchPalette.kicker,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Roll for initiative',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Higher total acts first at First Light.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              _WatcherRow(
                name: 'You',
                flockLabel: 'Your',
                roostSize: s.youRoost.length,
                skillMod: s.youMod,
                tileColor: theme.colorScheme.primaryContainer,
                ringColor: theme.colorScheme.primary,
                face: rolled ? s.youRoll : _spinFace,
                showFace: rolled || _spinning,
                total: rolled
                    ? MatchRules.initiativeTotal(
                        roll: s.youRoll, skillMod: s.youMod, roostSize: s.youRoost.length)
                    : null,
                isWinner: rolled && s.firstMover == MatchSide.you,
              ),
              const SizedBox(height: 12),
              _WatcherRow(
                name: 'Mara',
                flockLabel: 'Shorebird',
                roostSize: s.oppRoost.length,
                skillMod: s.oppMod,
                tileColor: theme.colorScheme.secondaryContainer,
                ringColor: theme.colorScheme.secondary,
                face: rolled ? s.oppRoll : _spinFace,
                showFace: rolled || _spinning,
                total: rolled
                    ? MatchRules.initiativeTotal(
                        roll: s.oppRoll, skillMod: s.oppMod, roostSize: s.oppRoost.length)
                    : null,
                isWinner: rolled && s.firstMover == MatchSide.opp,
              ),
              if (rolled) ...[
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${s.firstMover == MatchSide.you ? 'You' : 'Mara'} act first',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _spinning
                      ? null
                      : rolled
                          ? ref.read(matchControllerProvider.notifier).beginFirstLight
                          : _roll,
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    _spinning
                        ? 'Rolling…'
                        : rolled
                            ? 'Begin First Light'
                            : 'Roll the die',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatcherRow extends StatelessWidget {
  const _WatcherRow({
    required this.name,
    required this.flockLabel,
    required this.roostSize,
    required this.skillMod,
    required this.tileColor,
    required this.ringColor,
    required this.face,
    required this.showFace,
    required this.total,
    required this.isWinner,
  });

  final String name;
  final String flockLabel;
  final int roostSize;
  final int skillMod;
  final Color tileColor;
  final Color ringColor;
  final int face;
  final bool showFace;
  final int? total;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final penalty = MatchRules.flockPenalty(roostSize);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? ringColor : theme.colorScheme.outlineVariant,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              showFace ? '$face' : '—',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                Text(
                  '$flockLabel flock · $roostSize birds',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Chip(
                      'skill +$skillMod',
                      bg: theme.colorScheme.secondaryContainer,
                      fg: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 6),
                    _Chip(
                      'flock −$penalty',
                      bg: theme.colorScheme.errorContainer,
                      fg: theme.colorScheme.onErrorContainer,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (total != null) ...[
            const SizedBox(width: 8),
            Text('$total', style: theme.textTheme.headlineSmall),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
