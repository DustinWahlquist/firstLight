import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers.dart';
import '../../models/bird_card.dart';
import 'widgets/bird_card_tile.dart';

final aviaryProvider = FutureProvider<List<BirdCard>>((ref) {
  return ref.watch(supabaseServiceProvider).fetchAviary();
});

enum _CatchState { idle, loading, duplicate }

final _catchStateProvider = StateProvider<_CatchState>((_) => _CatchState.idle);

class AviaryScreen extends ConsumerWidget {
  const AviaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aviary = ref.watch(aviaryProvider);
    final catchState = ref.watch(_catchStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: const Text('Aviary'),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: catchState == _CatchState.loading
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
            data: (cards) => Column(
              children: [
                if (catchState == _CatchState.duplicate)
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
                                'Already logged this bird today. Come back tomorrow!',
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
                                .read(_catchStateProvider.notifier)
                                .state = _CatchState.idle,
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: cards.isEmpty
                      ? Center(
                          child: Text(
                            'No birds yet.\nLog your first catch to get started.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: cards.length,
                          itemBuilder: (context, i) => BirdCardTile(
                            card: cards[i],
                            onTap: () => context.push('/bird-detail', extra: cards[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (catchState == _CatchState.loading)
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
    ref.read(_catchStateProvider.notifier).state = _CatchState.loading;

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final vision = ref.read(visionServiceProvider);

      final parseResult = await vision.parseScreenshot(file);
      final screenshotUrl = await supabase.uploadScreenshot(file);
      final existing = await supabase.fetchCard(parseResult.speciesName);

      if (existing != null) {
        final alreadyCaughtToday = await supabase.hasCaughtToday(existing.id);
        if (alreadyCaughtToday) {
          ref.read(_catchStateProvider.notifier).state = _CatchState.duplicate;
          return;
        }
        final oldCard = existing;
        final updatedCard = await supabase.awardXp(existing, parseResult, screenshotUrl);
        ref.invalidate(aviaryProvider);
        ref.read(_catchStateProvider.notifier).state = _CatchState.idle;
        if (context.mounted) {
          if (updatedCard.level > oldCard.level) {
            context.push('/level-up', extra: (oldCard: oldCard, newCard: updatedCard));
          }
        }
      } else {
        final newCard = await supabase.createCard(parseResult, screenshotUrl);
        ref.invalidate(aviaryProvider);
        ref.read(_catchStateProvider.notifier).state = _CatchState.idle;
        if (context.mounted) context.push('/card-reveal', extra: newCard);
      }
    } catch (e) {
      ref.read(_catchStateProvider.notifier).state = _CatchState.idle;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse screenshot: $e')),
        );
      }
    }
  }
}

class _ImagePreviewSheet extends StatelessWidget {
  const _ImagePreviewSheet({required this.file});
  final File file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F0E8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
