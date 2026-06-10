import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/vision_service.dart';
import '../../domain/game_rules.dart';
import '../../domain/log_catch_use_case.dart';
import '../../models/bird_card.dart';
import '../../models/parse_result.dart';
import 'aviary_providers.dart';
import 'log_catch_controller.dart';
import 'widgets/bird_card_tile.dart';

enum _SortOrder { dateAdded, lastCatch, level, alphabetical }

final _sortOrderProvider = StateProvider<_SortOrder>((_) => _SortOrder.dateAdded);
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
      return 'Already logged this bird today. Come back tomorrow!';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Already logged this bird on ${months[date.month - 1]} ${date.day}. '
        'One catch per bird per day.';
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
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePreviewSheet(file: File(picked.path)),
    );

    if (confirmed != true || !context.mounted) return;

    await _submitCatch(context, ref, File(picked.path));
  }

  Future<void> _submitCatch(BuildContext context, WidgetRef ref, File file) async {
    final controller = ref.read(logCatchControllerProvider.notifier);

    try {
      ParseResult parseResult;
      try {
        parseResult = await controller.parseScreenshot(file);
      } on UnverifiableScreenshotException {
        return; // The rejection banner explains it.
      }

      if (parseResult.latitude == null && context.mounted) {
        final manualLocation = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _LocationDialog(initialLocation: parseResult.location),
        );
        if (manualLocation != null && manualLocation.isNotEmpty) {
          parseResult = parseResult.copyWith(location: manualLocation);
        }
      }

      if (!context.mounted) return;
      final result = await controller.submit(parseResult, file);

      if (!context.mounted) return;
      switch (result) {
        case LogCatchNewLifer(:final card):
          context.push('/card-reveal', extra: card);
        case LogCatchXpAwarded(leveledUp: true, :final before, :final after):
          context.push('/level-up', extra: (oldCard: before, newCard: after));
        case LogCatchXpAwarded():
        case LogCatchDuplicate():
        case LogCatchFutureDated():
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse screenshot: $e')),
        );
      }
    }
  }
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({required this.initialLocation});
  final String initialLocation;

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLocation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Where was this?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "We couldn't pinpoint this location on the map. Enter a place name to save with this catch.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'e.g. Central Park, New York',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(widget.initialLocation),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
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
