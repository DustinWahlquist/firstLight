import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/catch_result.dart';
import '../services/screenshot_service.dart';
import '../services/supabase_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  Uint8List? _preview;
  bool _processing = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final bytes = source == ImageSource.gallery
        ? await ScreenshotService.instance.pickFromGallery()
        : await ScreenshotService.instance.pickFromCamera();

    if (bytes == null || !mounted) return;
    setState(() {
      _preview = bytes;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_preview == null) return;
    setState(() {
      _processing = true;
      _error = null;
    });

    final result =
        await SupabaseService.instance.processScreenshot(_preview!);

    if (!mounted) return;
    setState(() => _processing = false);

    switch (result) {
      case NewLifer(:final card):
        context.go('/reveal', extra: card);
      case XpAwarded(:final card, :final xpGained, :final didLevelUp):
        _showXpSnack(card.speciesName, xpGained, didLevelUp);
        context.pop();
      case DailyLimitReached(:final speciesName):
        setState(() =>
            _error = "You've already logged $speciesName today. Come back tomorrow!");
      case ParseFailure(:final reason):
        setState(() => _error = reason);
    }
  }

  void _showXpSnack(String species, int xp, bool leveledUp) {
    final message = leveledUp
        ? '$species leveled up! (+$xp XP)'
        : '+$xp XP for $species';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Catch')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScreenshotPreview(
              bytes: _preview,
              onPickGallery: () => _pick(ImageSource.gallery),
              onPickCamera: () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed:
                  (_preview == null || _processing) ? null : _submit,
              child: _processing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

enum ImageSource { gallery, camera }

class _ScreenshotPreview extends StatelessWidget {
  const _ScreenshotPreview({
    required this.bytes,
    required this.onPickGallery,
    required this.onPickCamera,
  });

  final Uint8List? bytes;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: bytes != null
            ? Image.memory(bytes!, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_outlined, size: 48),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                        onPressed: onPickGallery,
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                        onPressed: onPickCamera,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
