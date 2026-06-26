import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/geocoding_service.dart';

typedef ManualLocation = ({String name, double? latitude, double? longitude});

/// Confirms a catch location, geocoding free text via [geocoder]. Pops a
/// [ManualLocation]. [note] is the explanatory line under the title — the bulk
/// flow uses it to say the location applies to every bird in the screenshot.
class LocationDialog extends StatefulWidget {
  const LocationDialog({
    super.key,
    required this.initialLocation,
    required this.geocoder,
    this.title = 'Where was this?',
    this.note,
  });

  final String initialLocation;
  final GeocodingService geocoder;
  final String title;
  final String? note;

  @override
  State<LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<LocationDialog> {
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
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.note != null)
              Text(
                widget.note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (widget.note != null) const SizedBox(height: 16),
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
