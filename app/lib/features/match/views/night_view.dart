import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/match/match_state.dart';
import '../../../models/match/match_bird.dart';
import '../match_controller.dart';
import '../match_theme.dart';
import '../widgets/match_bird_card.dart';

/// The five-step Night sequence: nightfall → endurance shift → draw →
/// deploy → dawn re-roll. The background and sun shift by step.
class NightView extends ConsumerWidget {
  const NightView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(matchControllerProvider);
    final ctrl = ref.read(matchControllerProvider.notifier);

    // In a friend match, once you've taken your night you wait for the
    // opponent to take theirs; the next day arrives via realtime.
    if (ctrl.isFriend && (s.youNightDone || s.turn != MatchTurn.you)) {
      return const _NightWaiting();
    }

    final step = s.nightStep;
    final dawn = step == 4;
    final light = !dawn; // steps 0–3 use light text on a dark sky

    final gradient = dawn
        ? const [MatchPalette.dawnTop, Color(0xFFF5F0E8)]
        : const [MatchPalette.duskTop, MatchPalette.duskBottom];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: [
          // Sun
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1300),
            curve: Curves.easeInOut,
            top: dawn ? 60 : MediaQuery.of(context).size.height * 0.62,
            left: MediaQuery.of(context).size.width / 2 - 43,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dawn ? MatchPalette.sunDawn : MatchPalette.sunNight,
                boxShadow: [
                  BoxShadow(
                    color: (dawn ? MatchPalette.sunDawn : MatchPalette.sunNight)
                        .withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Expanded(
                    child: _StepBody(
                      s: s,
                      light: light,
                      onToggleDeploy: ctrl.toggleDeploy,
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: ctrl.nightAdvance,
                      style: FilledButton.styleFrom(shape: const StadiumBorder()),
                      child: Text(_ctaLabel(s)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ctaLabel(MatchState s) {
    if (s.setup) {
      return switch (s.nightStep) {
        0 => 'Draw opening hand',
        2 => 'Continue',
        _ => s.deploySelected.isEmpty ? 'Deploy birds' : 'Deploy ${s.deploySelected.length} · Day 1',
      };
    }
    return switch (s.nightStep) {
      0 => 'Night falls',
      1 => 'Continue',
      2 => 'Continue',
      3 => s.deploySelected.isEmpty ? 'Skip deploy' : 'Deploy ${s.deploySelected.length}',
      _ => 'Begin Day ${s.day + 1}',
    };
  }
}

class _NightWaiting extends StatelessWidget {
  const _NightWaiting();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MatchPalette.duskTop, MatchPalette.duskBottom],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.nightlight_outlined, color: MatchPalette.sunNight, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Night',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your flock is set. Waiting for your opponent to take their '
                  'night — the next day begins once they’re done.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.s, required this.light, required this.onToggleDeploy});
  final MatchState s;
  final bool light;
  final void Function(String id) onToggleDeploy;

  @override
  Widget build(BuildContext context) {
    final (kicker, headline, subtitle) = s.setup
        ? switch (s.nightStep) {
            0 => ('SETUP', 'Build your flock', 'Draw your opening hand, then send your birds to the roost.'),
            2 => ('OPENING HAND', 'Your opening hand', 'Five birds to start the migration.'),
            _ => ('TAKE FLIGHT', 'Deploy your birds', 'Place up to 3 onto the track — Day 1 begins next.'),
          }
        : switch (s.nightStep) {
            0 => ('NIGHT', 'Night falls', 'The flock settles onto the endurance track.'),
            1 => ('ENDURANCE TRACK', 'The flock shifts', 'Every bird spends a day of endurance.'),
            2 => ('REPLENISH', 'Draw', 'Two new birds join your hand.'),
            3 => ('REINFORCE', 'Deploy your birds', 'Place up to 3 onto the track — free.'),
            _ => ('A NEW DAY', 'First Light', 'Initiative is re-rolled for the coming day.'),
          };
    final textColor = light ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final mutedColor = light ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          kicker,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 2,
            color: light ? MatchPalette.sunNight : MatchPalette.kicker,
          ),
        ),
        const SizedBox(height: 10),
        Text(headline, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColor)),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mutedColor),
        ),
        const SizedBox(height: 20),
        Expanded(child: _report(context, textColor, mutedColor)),
      ],
    );
  }

  Widget _report(BuildContext context, Color textColor, Color mutedColor) {
    switch (s.nightStep) {
      case 1:
        final report = s.shiftReport;
        if (report == null) return const SizedBox.shrink();
        return _Panel(
          light: light,
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final e in report.you)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.name, style: TextStyle(color: textColor)),
                        Text(
                          e.deltaText,
                          style: TextStyle(
                            color: e.fell
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (report.oppFell > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Mara lost ${report.oppFell} bird${report.oppFell == 1 ? '' : 's'}.',
                      style: TextStyle(color: mutedColor),
                    ),
                  ),
              ],
            ),
          ),
        );
      case 2:
        final drawn = s.youHand.where((b) => s.drawnIds.contains(b.id)).toList();
        return _Panel(
          light: light,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You drew ${drawn.length}', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              for (final b in drawn)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${b.name}  ·  SPD ${b.speed} / END ${b.endurance}'),
                ),
              const SizedBox(height: 8),
              Text(
                'Hand is now ${s.youHand.length} of 7. Mara drew ${s.setup ? 5 : 2}.',
                style: TextStyle(color: mutedColor),
              ),
            ],
          ),
        );
      case 3:
        return _DeployGrid(hand: s.youHand, selected: s.deploySelected, onToggle: onToggleDeploy);
      case 4:
        final init = s.dawnInit;
        if (init == null) return const SizedBox.shrink();
        return _Panel(
          light: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Initiative · Day ${s.day + 1}', style: TextStyle(fontFamily: 'monospace', fontSize: 10, letterSpacing: 1.5, color: MatchPalette.kicker)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Total('${init.youTotal}', 'You', Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 18),
                  Text('vs', style: TextStyle(fontFamily: 'monospace', color: mutedColor)),
                  const SizedBox(width: 18),
                  _Total('${init.oppTotal}', 'Mara', Theme.of(context).colorScheme.secondary),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${init.first == MatchSide.you ? 'You' : 'Mara'} acts first'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.light});
  final Widget child;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.10)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: light ? Colors.white24 : theme.colorScheme.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _DeployGrid extends StatelessWidget {
  const _DeployGrid({required this.hand, required this.selected, required this.onToggle});
  final List<MatchBird> hand;
  final List<String> selected;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '${selected.length} of 3 selected',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: hand.length,
            itemBuilder: (context, i) {
              final bird = hand[i];
              final isSel = selected.contains(bird.id);
              return MatchBirdCard(
                bird: bird,
                selected: isSel,
                onTap: () => onToggle(bird.id),
                footer: Text(
                  'enters ${bird.endurance}d',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
