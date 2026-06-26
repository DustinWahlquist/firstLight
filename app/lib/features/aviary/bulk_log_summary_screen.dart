import 'package:flutter/material.dart';
import 'bulk_log_controller.dart';

/// Wrap-up after a bulk log: counts + the new lifers. Pops `true` if the user
/// wants to log another screenshot (the next page of a long list), else `false`.
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
              if (summary.newLifers.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEW LIFERS',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: summary.newLifers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final c = summary.newLifers[i];
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
                                  Expanded(child: Text(c.speciesName, style: theme.textTheme.titleSmall)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Spacer(),
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
    if (summary.repeats > 0) parts.add('+${summary.xpAwarded} XP');
    if (summary.leveledUp > 0) parts.add('${summary.leveledUp} leveled up');
    if (summary.duplicates > 0) {
      parts.add('${summary.duplicates} already logged');
    }
    if (parts.isEmpty) return 'These were already in your aviary for today.';
    return parts.join(' · ');
  }
}
