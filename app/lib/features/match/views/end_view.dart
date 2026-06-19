import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/match/match_rules.dart';
import '../../../domain/match/match_state.dart';
import '../match_controller.dart';

class EndView extends ConsumerWidget {
  const EndView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = ref.watch(matchControllerProvider);
    final won = s.winner == MatchSide.you;

    return Container(
      decoration: BoxDecoration(
        gradient: won
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3F4F0), Color(0xFFF5F0E8)],
              )
            : null,
        color: won ? null : theme.colorScheme.surfaceContainerLow,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                won ? 'MIGRATION COMPLETE' : 'RACE OVER',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: won ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 3,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                won ? 'You banked 10,000 km' : 'Mara reached 10,000 km first',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                won
                    ? 'Your flock crossed the line first. New lifers, new range.'
                    : 'So close. Catch more birds and build a faster flock.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              _SummaryCard(s: s),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => ref.read(matchControllerProvider.notifier).restart(),
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                  child: const Text('Rematch'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back to app'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.s});
  final MatchState s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winnerKm = s.winner == MatchSide.you ? s.youKm : s.oppKm;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _Bar(label: 'You', km: s.youKm, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          _Bar(label: 'Mara', km: s.oppKm, color: theme.colorScheme.secondary),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat('${s.daysPlayed}', 'days'),
                _Stat('${s.flewCount}', 'flights'),
                _Stat('${(winnerKm / 1000).toStringAsFixed(1)}k', 'km banked'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.km, required this.color});
  final String label;
  final int km;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (km / MatchRules.winKm).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 46, child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: color))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '${(km / 1000).toStringAsFixed(1)}k',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
