import 'dart:convert';
import 'dart:io';
import '../core/config.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

/// Place search backed by Photon (photon.komoot.io), the OSM geocoder
/// designed for search-as-you-type. No API key; fair-use rate limits.
class GeocodingService {
  Future<List<PlaceSuggestion>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];

    final uri = Uri.https('photon.komoot.io', '/api/', {'q': q, 'limit': '6'});
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      // Photon's CDN rejects Dart's default user agent with a 403.
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'FirstLight/1.0 ($osmUserAgentPackageName)',
      );
      final response = await request.close();
      if (response.statusCode != 200) return [];
      final body = await response.transform(utf8.decoder).join();
      final features =
          (jsonDecode(body)['features'] as List<dynamic>?) ?? const [];
      return features
          .map(_suggestionFromFeature)
          .whereType<PlaceSuggestion>()
          .toList();
    } catch (_) {
      // Suggestions are a convenience — typing a name still works without them.
      return [];
    } finally {
      client.close(force: true);
    }
  }

  PlaceSuggestion? _suggestionFromFeature(dynamic feature) {
    final props = feature['properties'] as Map<String, dynamic>? ?? const {};
    final coords = feature['geometry']?['coordinates'] as List<dynamic>?;
    if (coords == null || coords.length < 2) return null;

    final seen = <String>{};
    final parts = [props['name'], props['city'], props['state'], props['country']]
        .whereType<String>()
        .where((p) => p.isNotEmpty && seen.add(p))
        .toList();
    if (parts.isEmpty) return null;

    return PlaceSuggestion(
      name: parts.join(', '),
      latitude: (coords[1] as num).toDouble(),
      longitude: (coords[0] as num).toDouble(),
    );
  }
}
