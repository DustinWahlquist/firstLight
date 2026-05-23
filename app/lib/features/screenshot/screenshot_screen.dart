import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers.dart';

enum ScreenshotState { idle, loading, duplicateCatch }

final screenshotStateProvider = StateProvider<ScreenshotState>(
  (_) => ScreenshotState.idle,
);

class ScreenshotScreen extends ConsumerWidget {
  const ScreenshotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(screenshotStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Catch')),
      body: Center(
        child: state == ScreenshotState.loading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Parsing screenshot...'),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state == ScreenshotState.duplicateCatch)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Already logged this bird today. Come back tomorrow!',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () => _pick(context, ref, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose from Camera Roll'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _pick(context, ref, ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take Photo'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    ref.read(screenshotStateProvider.notifier).state = ScreenshotState.loading;

    try {
      final file = File(picked.path);
      final supabase = ref.read(supabaseServiceProvider);
      final vision = ref.read(visionServiceProvider);

      final parseResult = await vision.parseScreenshot(file);
      final screenshotUrl = await supabase.uploadScreenshot(file);

      final existing = await supabase.fetchCard(parseResult.speciesName);

      if (existing != null) {
        final alreadyCaughtToday = await supabase.hasCaughtToday(existing.id);
        if (alreadyCaughtToday) {
          ref.read(screenshotStateProvider.notifier).state = ScreenshotState.duplicateCatch;
          return;
        }
        final oldCard = existing;
        final updatedCard = await supabase.awardXp(existing, parseResult.rarity.xpPerCatch, screenshotUrl);
        ref.read(screenshotStateProvider.notifier).state = ScreenshotState.idle;
        if (context.mounted) {
          if (updatedCard.level > oldCard.level) {
            context.go('/level-up', extra: (oldCard: oldCard, newCard: updatedCard));
          } else {
            context.go('/');
          }
        }
      } else {
        final newCard = await supabase.createCard(parseResult, screenshotUrl);
        ref.read(screenshotStateProvider.notifier).state = ScreenshotState.idle;
        if (context.mounted) context.go('/card-reveal', extra: newCard);
      }
    } catch (e) {
      ref.read(screenshotStateProvider.notifier).state = ScreenshotState.idle;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse screenshot: $e')),
        );
      }
    }
  }
}
