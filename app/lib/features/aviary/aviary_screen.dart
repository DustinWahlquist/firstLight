import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../data/geocoding_service.dart';
import '../../data/vision_service.dart';
import '../../domain/game_rules.dart';
import '../../domain/log_catch_use_case.dart';
import '../../models/bird_card.dart';
import '../../models/parse_result.dart';
import 'aviary_providers.dart';
import 'log_catch_controller.dart';
import 'screenshot_picker.dart';
import 'widgets/bird_card_tile.dart';

// Declaration order is the sort menu's display order.
enum _SortOrder { alphabetical, level, lastCatch, dateAdded }

final _sortOrderProvider = StateProvider<_SortOrder>((_) => _SortOrder.alphabetical);
final _sortAscendingProvider = StateProvider<bool>((_) => true);

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
    final file = picked.file;

    try {
      ParseResult parseResult;
      try {
        parseResult = await controller.parseScreenshot(file);
      } on UnverifiableScreenshotException {
        return; // The rejection banner explains it.
      }

      // Reject duplicates and future dates before asking for a location.
      final rejection = await controller.precheck(parseResult);
      if (rejection != null) {
        if (rejection is LogCatchDuplicate &&
            picked.assetId != null &&
            context.mounted) {
          await _offerScreenshotDeletion(
            context,
            picked.assetId!,
            alreadyLogged: true,
          );
        }
        return;
      }

      if (parseResult.latitude == null && context.mounted) {
        final manual = await showDialog<ManualLocation>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _LocationDialog(
            initialLocation: parseResult.location,
            geocoder: ref.read(geocodingServiceProvider),
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

typedef ManualLocation = ({String name, double? latitude, double? longitude});

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({required this.initialLocation, required this.geocoder});
  final String initialLocation;
  final GeocodingService geocoder;

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLocation);
    if (widget.initialLocation.trim().isNotEmpty) {
      _search(widget.initialLocation);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(text));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 3) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    final results = await widget.geocoder.search(query);
    if (!mounted) return;
    // Ignore stale results that arrive after the text has changed again.
    if (_controller.text != query) return;
    setState(() {
      _suggestions = results;
      _searching = false;
    });
  }

  void _pickSuggestion(PlaceSuggestion s) => Navigator.of(context)
      .pop((name: s.name, latitude: s.latitude, longitude: s.longitude));

  void _saveTyped() => Navigator.of(context)
      .pop((name: _controller.text.trim(), latitude: null, longitude: null));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Where was this?'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "We couldn't pinpoint this location on the map. Search for the place so this catch shows up on your map.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'e.g. Central Park, New York',
                border: const OutlineInputBorder(),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _onChanged,
              onSubmitted: (_) => _saveTyped(),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, i) {
                    final s = _suggestions[i];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(s.name, style: theme.textTheme.bodyMedium),
                      onTap: () => _pickSuggestion(s),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            (name: widget.initialLocation, latitude: null, longitude: null),
          ),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: _saveTyped,
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
