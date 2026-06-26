import 'package:flutter/material.dart';
import '../../domain/game_rules.dart';
import 'bulk_log_controller.dart';

/// Wrap-up after a bulk log: new lifers up top, then an animated XP bar per
/// repeat catch (like the single-catch flow). Pops `true` if the user wants to
/// log another screenshot (the next page of a long list), else `false`.
class BulkLogSummaryScreen extends StatelessWidget {
  const BulkLogSummaryScreen({super.key, required this.summary});

  final BulkSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Icon(Icons.check_circle, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                summary.logged == 0
                    ? 'Nothing new to log'
                    : 'Logged ${summary.logged} bird${summary.logged == 1 ? '' : 's'}',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                _subtitle(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    if (summary.newLifers.isNotEmpty) ...[
                      _SectionLabel('NEW LIFERS'),
                      const SizedBox(height: 8),
                      for (final c in summary.newLifers) ...[
                        _LiferRow(name: c.speciesName),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 12),
                    ],
                    if (summary.repeats.isNotEmpty) ...[
                      _SectionLabel('XP GAINED'),
                      const SizedBox(height: 8),
                      for (final r in summary.repeats) ...[
                        _XpRow(repeat: r),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Log another screenshot'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final parts = <String>[];
    if (summary.newLifers.isNotEmpty) {
      parts.add('${summary.newLifers.length} new lifer${summary.newLifers.length == 1 ? '' : 's'}');
    }
    if (summary.repeats.isNotEmpty) parts.add('+${summary.xpAwarded} XP');
    if (summary.leveledUp > 0) parts.add('${summary.leveledUp} leveled up');
    if (summary.duplicates > 0) parts.add('${summary.duplicates} already logged');
    if (parts.isEmpty) return 'These were already in your aviary for today.';
    return parts.join(' · ');
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _LiferRow extends StatelessWidget {
  const _LiferRow({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.star, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
        ],
      ),
    );
  }
}

/// A repeat catch: the bird's XP bar animates from where it was to where it is
/// now, mirroring the single-catch XP dialog.
class _XpRow extends StatelessWidget {
  const _XpRow({required this.repeat});
  final BulkRepeat repeat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final after = repeat.after;
    final threshold = GameRules.xpForNextLevel(after.level);
    final begin =
        repeat.leveledUp ? 0.0 : (repeat.before.xp / threshold).clamp(0.0, 1.0);
    final end = (after.xp / threshold).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(after.speciesName, style: theme.textTheme.titleSmall)),
              if (repeat.leveledUp)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'Lv ${after.level}!',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Text(
                '+${repeat.gained} XP',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: begin, end: end),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lv ${after.level} · ${after.xp} / $threshold XP',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
