import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../data/vision_service.dart';
import '../../domain/game_rules.dart';
import '../../domain/log_catch_use_case.dart';
import '../../models/bird_card.dart';
import '../../models/bulk_parse.dart';
import '../../models/parse_result.dart';
import 'aviary_providers.dart';
import 'bulk_log_controller.dart';
import 'bulk_log_review_screen.dart';
import 'bulk_log_summary_screen.dart';
import 'log_catch_controller.dart';
import 'screenshot_picker.dart';
import 'widgets/bird_card_tile.dart';
import 'widgets/location_dialog.dart';

// Declaration order is the sort menu's display order.
enum _SortOrder { alphabetical, level, lastCatch, dateAdded }

// Default: highest-level birds first.
final _sortOrderProvider = StateProvider<_SortOrder>((_) => _SortOrder.level);
final _sortAscendingProvider = StateProvider<bool>((_) => false);

class AviaryScreen extends ConsumerWidget {
  const AviaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aviary = ref.watch(aviaryProvider);
    final flowState = ref.watch(logCatchControllerProvider);
    final catchState = flowState.status;
    final sortOrder = ref.watch(_sortOrderProvider);
    final ascending = ref.watch(_sortAscendingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aviary'),
        backgroundColor: Colors.transparent,
        actions: [
          Builder(
            builder: (btnCtx) => IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showSortMenu(btnCtx, ref),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: catchState == CatchFlowStatus.loading
            ? null
            : () => _pickImage(context, ref),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Log Catch'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: Stack(
        children: [
          aviary.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (cards) {
              int cmp(BirdCard a, BirdCard b) => switch (sortOrder) {
                _SortOrder.dateAdded    => a.createdAt.compareTo(b.createdAt),
                _SortOrder.lastCatch    => (a.lastCaughtAt ?? a.createdAt)
                                              .compareTo(b.lastCaughtAt ?? b.createdAt),
                // Level ties break on XP progress within the level.
                _SortOrder.level        => a.level != b.level
                                              ? a.level.compareTo(b.level)
                                              : a.xp.compareTo(b.xp),
                _SortOrder.alphabetical => a.speciesName.compareTo(b.speciesName),
              };
              final sorted = [...cards]..sort((a, b) => ascending ? cmp(a, b) : cmp(b, a));
              return Column(
              children: [
                if (catchState == CatchFlowStatus.duplicate ||
                    catchState == CatchFlowStatus.futureDate ||
                    catchState == CatchFlowStatus.unverifiable)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                switch (catchState) {
                                  CatchFlowStatus.futureDate =>
                                    'This screenshot is dated in the future. Please check the date on your device.',
                                  CatchFlowStatus.unverifiable =>
                                    flowState.unverifiableReason ??
                                        "Couldn't verify this catch from the screenshot.",
                                  _ => _duplicateMessage(flowState.duplicateDate),
                                },
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            onPressed: () => ref
                                .read(logCatchControllerProvider.notifier)
                                .dismissBanner(),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: sorted.isEmpty
                      ? Center(
                          child: Text(
                            'No birds yet.\nLog your first catch to get started.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isTablet = constraints.maxWidth > 600;
                            if (isTablet) {
                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.82,
                                ),
                                itemCount: sorted.length,
                                itemBuilder: (context, i) => BirdCardTile(
                                  card: sorted[i],
                                  isGrid: true,
                                  onTap: () => context.push('/bird-detail', extra: (card: sorted[i], ownerName: null)),
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                              itemCount: sorted.length,
                              itemBuilder: (context, i) => BirdCardTile(
                                card: sorted[i],
                                onTap: () => context.push('/bird-detail', extra: (card: sorted[i], ownerName: null)),
                              ),
                            );
                          },
                        ),
                ),
              ],
              );
            },
          ),
          if (catchState == CatchFlowStatus.loading)
            Container(
              color: const Color(0xD9F5F0E8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Parsing photo...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _duplicateMessage(DateTime? date) {
    if (date == null || GameRules.isSameCalendarDay(date, DateTime.now())) {
      return 'Already logged this bird today.';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Already logged this bird on ${months[date.month - 1]} ${date.day}.';
  }

  void _showSortMenu(BuildContext context, WidgetRef ref) {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);
    final right = overlay.size.width - pos.dx - box.size.width;
    final top = pos.dy + box.size.height - 8;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => Stack(
        children: [
          Positioned(
            top: top,
            right: right,
            child: Consumer(
            builder: (ctx, ref, _) {
              final sortOrder = ref.watch(_sortOrderProvider);
              final ascending = ref.watch(_sortAscendingProvider);
              final theme = Theme.of(context);
              return Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surface,
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _SortOrder.values.map((v) {
                      final isSelected = v == sortOrder;
                      final label = switch (v) {
                        _SortOrder.dateAdded    => 'Date added',
                        _SortOrder.lastCatch    => 'Last catch',
                        _SortOrder.level        => 'Level',
                        _SortOrder.alphabetical => 'Alphabetical',
                      };
                      return ListTile(
                        dense: true,
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Icon(
                          isSelected
                              ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
                              : Icons.unfold_more,
                          size: 18,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        onTap: () {
                          if (isSelected) {
                            ref.read(_sortAscendingProvider.notifier).state = !ascending;
                          } else {
                            ref.read(_sortOrderProvider.notifier).state = v;
                            ref.read(_sortAscendingProvider.notifier).state =
                                v == _SortOrder.alphabetical;
                            // Deliberate choice only — the default is never logged.
                            ref.read(usageEventsProvider).log('aviary_sort', v.name);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final picked = await pickScreenshot(context);
    if (picked == null || !context.mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePreviewSheet(file: picked.file),
    );

    if (confirmed != true || !context.mounted) return;

    await _submitCatch(context, ref, picked);
  }

  Future<void> _submitCatch(
    BuildContext context,
    WidgetRef ref,
    PickedScreenshot picked,
  ) async {
    final controller = ref.read(logCatchControllerProvider.notifier);
    try {
      final ParseOutcome outcome;
      try {
        outcome = await controller.parseScreenshot(picked.file);
      } on UnverifiableScreenshotException {
        return; // The rejection banner explains it.
      }
      if (!context.mounted) return;
      switch (outcome) {
        case ParsedSingle(:final result):
          await _submitSingle(context, ref, picked, result);
        case ParsedList(:final bulk):
          await _submitBulk(context, ref, picked, bulk);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse screenshot: $e')),
        );
      }
    }
  }

  Future<void> _submitSingle(
    BuildContext context,
    WidgetRef ref,
    PickedScreenshot picked,
    ParseResult parseResult,
  ) async {
    final controller = ref.read(logCatchControllerProvider.notifier);
    final file = picked.file;

    // Reject duplicates and future dates before asking for a location.
    final rejection = await controller.precheck(parseResult);
    if (rejection != null) {
      if (rejection is LogCatchDuplicate &&
          picked.assetId != null &&
          context.mounted) {
        await _offerScreenshotDeletion(context, picked.assetId!, alreadyLogged: true);
      }
      return;
    }

    if (parseResult.latitude == null && context.mounted) {
      final manual = await showDialog<ManualLocation>(
        context: context,
        barrierDismissible: false,
        builder: (_) => LocationDialog(
          initialLocation: parseResult.location,
          geocoder: ref.read(geocodingServiceProvider),
          note: "We couldn't pinpoint this location on the map. Search for the "
              'place so this catch shows up on your map.',
        ),
      );
      if (manual != null && manual.name.isNotEmpty) {
        parseResult = parseResult.copyWith(
          location: manual.name,
          latitude: manual.latitude,
          longitude: manual.longitude,
        );
      }
    }

    if (!context.mounted) return;
    final result = await controller.submit(parseResult, file);

    // Offer cleanup whenever the screenshot's catch is in the aviary —
    // including duplicates, where it was logged previously.
    final inAviary = result is LogCatchNewLifer ||
        result is LogCatchXpAwarded ||
        result is LogCatchDuplicate;
    if (inAviary && picked.assetId != null && context.mounted) {
      await _offerScreenshotDeletion(
        context,
        picked.assetId!,
        alreadyLogged: result is LogCatchDuplicate,
      );
    }

    if (!context.mounted) return;
    switch (result) {
      case LogCatchNewLifer(:final card):
        context.push('/card-reveal', extra: card);
      case LogCatchXpAwarded(leveledUp: true, :final before, :final after):
        context.push('/level-up', extra: (oldCard: before, newCard: after));
      case LogCatchXpAwarded(:final before, :final after):
        await showDialog<void>(
          context: context,
          builder: (_) => _XpGainedDialog(before: before, after: after),
        );
      case LogCatchDuplicate():
      case LogCatchFutureDated():
        break;
    }
  }

  /// Bulk flow for a Merlin "Identify" list: one location for all birds,
  /// a review of what will/won't be logged, then a summary.
  Future<void> _submitBulk(
    BuildContext context,
    WidgetRef ref,
    PickedScreenshot picked,
    BulkParse bulk,
  ) async {
    // The bulk flow has its own progress UI; clear the single-flow parsing
    // overlay so it doesn't linger behind the review screen.
    ref.read(logCatchControllerProvider.notifier).dismissBanner();

    final manual = await showDialog<ManualLocation>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LocationDialog(
        initialLocation: bulk.location,
        geocoder: ref.read(geocodingServiceProvider),
        title: 'Where were these?',
        note: 'This location will be used for all the birds in this screenshot.',
      ),
    );
    if (manual == null || !context.mounted) return;
    final location = manual.name.isNotEmpty ? manual.name : bulk.location;

    final plan = await ref.read(bulkLogUseCaseProvider).plan(bulk);
    if (!context.mounted) return;

    final summary = await Navigator.of(context).push<BulkSummary>(
      MaterialPageRoute(
        builder: (_) => BulkLogReviewScreen(
          plan: plan,
          date: bulk.date,
          location: location,
          latitude: manual.latitude,
          longitude: manual.longitude,
          screenshot: picked.file,
        ),
      ),
    );
    if (summary == null || !context.mounted) return;

    if (picked.assetId != null && summary.logged > 0) {
      await _offerScreenshotDeletion(context, picked.assetId!);
    }
    if (!context.mounted) return;

    final again = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BulkLogSummaryScreen(summary: summary)),
    );
    if (again == true && context.mounted) {
      await _pickImage(context, ref);
    }
  }

  Future<void> _offerScreenshotDeletion(
    BuildContext context,
    String assetId, {
    bool alreadyLogged = false,
  }) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(alreadyLogged ? 'Already logged' : 'Catch logged!'),
        content: Text(
          alreadyLogged
              ? 'This catch is already in your aviary. Delete the screenshot from your photo library?'
              : 'Delete the screenshot from your photo library?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (delete == true) {
      await deleteScreenshotAsset(assetId);
    }
  }
}

/// Celebrates a repeat catch: the bird's XP bar animates from where it
/// was to where it is now.
class _XpGainedDialog extends StatelessWidget {
  const _XpGainedDialog({required this.before, required this.after});

  final BirdCard before;
  final BirdCard after;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final threshold = GameRules.xpForNextLevel(after.level);
    final gained = after.xp - before.xp;

    return AlertDialog(
      title: Text(after.speciesName, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 96,
            child: after.lineArtUrl != null
                ? SvgPicture.network(after.lineArtUrl!, fit: BoxFit.contain)
                : Icon(
                    Icons.flutter_dash,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            '+$gained XP',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: (before.xp / threshold).clamp(0.0, 1.0),
              end: (after.xp / threshold).clamp(0.0, 1.0),
            ),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lv ${after.level} · ${after.xp} / $threshold XP',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Nice!'),
        ),
      ],
    );
  }
}

class _ImagePreviewSheet extends StatelessWidget {
  const _ImagePreviewSheet({required this.file});
  final File file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                file,
                height: 360,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Log this bird'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
