import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/bulk_log_use_case.dart';
import 'bulk_log_controller.dart';

/// Reviews a parsed Merlin list before logging: eligible birds are checked by
/// default and can be unchecked; not-verified birds can be checked to override
/// a missed checkmark; already-logged / future-dated birds are shown but can't
/// be logged. Pops the [BulkSummary] once committed.
class BulkLogReviewScreen extends ConsumerStatefulWidget {
  const BulkLogReviewScreen({
    super.key,
    required this.plan,
    required this.date,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.screenshot,
  });

  final BulkPlan plan;
  final DateTime date;
  final String location;
  final double? latitude;
  final double? longitude;
  final File screenshot;

  @override
  ConsumerState<BulkLogReviewScreen> createState() => _BulkLogReviewScreenState();
}

class _BulkLogReviewScreenState extends ConsumerState<BulkLogReviewScreen> {
  // Indices into plan.items that will be logged.
  late final Set<int> _included = {
    for (var i = 0; i < widget.plan.items.length; i++)
      if (widget.plan.items[i].eligible) i,
  };
  bool _committing = false;

  bool _canToggle(BulkPlanItem item) =>
      item.eligible || item.reason == BulkSkipReason.notVerified;

  Future<void> _commit() async {
    setState(() => _committing = true);
    final birds = [for (final i in _included) widget.plan.items[i].bird];
    final summary = await ref.read(bulkLogControllerProvider.notifier).commit(
          birds: birds,
          date: widget.date,
          location: widget.location,
          latitude: widget.latitude,
          longitude: widget.longitude,
          screenshot: widget.screenshot,
        );
    if (mounted) Navigator.of(context).pop(summary);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.plan.items;
    final progress = ref.watch(bulkLogControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review catches'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${widget.location} · ${_dateLabel(widget.date)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final item = items[i - 1];
          final idx = i - 1;
          final checked = _included.contains(idx);
          final toggleable = _canToggle(item) && !_committing;
          return _BirdRow(
            item: item,
            checked: checked,
            enabled: toggleable,
            onChanged: toggleable
                ? (v) => setState(() => v ? _included.add(idx) : _included.remove(idx))
                : null,
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: _committing || _included.isEmpty ? null : _commit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: Text(
            _committing
                ? 'Logging ${progress?.done ?? 0}/${progress?.total ?? _included.length}…'
                : _included.isEmpty
                    ? 'Nothing to log'
                    : 'Log ${_included.length} bird${_included.length == 1 ? '' : 's'}',
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _BirdRow extends StatelessWidget {
  const _BirdRow({
    required this.item,
    required this.checked,
    required this.enabled,
    required this.onChanged,
  });

  final BulkPlanItem item;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bird = item.bird;
    final reasonText = switch (item.reason) {
      BulkSkipReason.notVerified => 'Not verified — no checkmark',
      BulkSkipReason.alreadyLoggedToday => 'Already logged today',
      BulkSkipReason.futureDated => 'Dated in the future',
      null => null,
    };
    return Opacity(
      opacity: enabled || checked ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bird.speciesName, style: theme.textTheme.titleSmall),
                  if (bird.scientificName.isNotEmpty)
                    Text(
                      bird.scientificName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (reasonText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        reasonText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: item.reason == BulkSkipReason.notVerified
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (item.eligible)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.verified, size: 18, color: theme.colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}
