import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class PickedScreenshot {
  const PickedScreenshot({required this.file, this.assetId});

  final File file;

  /// Photo-library asset id when picked from the in-app gallery; null when
  /// picked through the system picker, where deletion isn't possible.
  final String? assetId;
}

/// Picks a screenshot, preferring the in-app gallery — which keeps the
/// photo-library asset reference so the screenshot can be offered for
/// deletion after a successful catch. Falls back to the system picker
/// (no deletion) when library access is denied.
Future<PickedScreenshot?> pickScreenshot(BuildContext context) async {
  final permission = await PhotoManager.requestPermissionExtend();
  if (!permission.hasAccess) {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return PickedScreenshot(file: File(picked.path));
  }

  if (!context.mounted) return null;
  final asset = await Navigator.of(context).push<AssetEntity>(
    MaterialPageRoute(builder: (_) => const _ScreenshotPickerScreen()),
  );
  if (asset == null) return null;
  final file = await asset.file;
  if (file == null) return null;
  return PickedScreenshot(file: file, assetId: asset.id);
}

/// Moves the photo to Recently Deleted. The OS shows its own confirmation
/// dialog; a refusal there just leaves the photo in place.
Future<void> deleteScreenshotAsset(String assetId) async {
  try {
    await PhotoManager.editor.deleteWithIds([assetId]);
  } catch (_) {
    // Deletion is a courtesy — never let it disrupt the catch flow.
  }
}

class _ScreenshotPickerScreen extends StatefulWidget {
  const _ScreenshotPickerScreen();

  @override
  State<_ScreenshotPickerScreen> createState() => _ScreenshotPickerScreenState();
}

class _ScreenshotPickerScreenState extends State<_ScreenshotPickerScreen> {
  List<AssetEntity> _assets = [];
  bool _loading = true;
  bool _limitedAccess = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final permission = await PhotoManager.requestPermissionExtend();
    _limitedAccess = permission == PermissionState.limited;

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    if (paths.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final recents = paths.first;
    final count = await recents.assetCountAsync;
    final assets = await recents.getAssetListRange(start: 0, end: count.clamp(0, 500));
    if (mounted) {
      setState(() {
        _assets = assets;
        _loading = false;
      });
    }
  }

  Future<void> _selectMorePhotos() async {
    await PhotoManager.presentLimited();
    if (mounted) {
      setState(() => _loading = true);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a screenshot'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ),
      ),
      body: Column(
        children: [
          if (_limitedAccess)
            Material(
              color: theme.colorScheme.primaryContainer,
              child: ListTile(
                dense: true,
                title: Text(
                  'First Light can only see some of your photos',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: TextButton(
                  onPressed: _selectMorePhotos,
                  child: const Text('Select more'),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _assets.isEmpty
                    ? Center(
                        child: Text(
                          'No photos found.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(2),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: _assets.length,
                        itemBuilder: (context, i) {
                          final asset = _assets[i];
                          return GestureDetector(
                            onTap: () => Navigator.of(context).pop(asset),
                            child: AssetEntityImage(
                              asset,
                              isOriginal: false,
                              thumbnailSize: const ThumbnailSize.square(300),
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
