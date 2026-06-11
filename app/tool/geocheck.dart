import 'package:first_light/data/geocoding_service.dart';

Future<void> main() async {
  final service = GeocodingService();
  for (final q in ['Theo Wirth', 'Central Park', 'Afton']) {
    final results = await service.search(q);
    print('"$q" -> ${results.length} results; first: ${results.isEmpty ? '-' : results.first.name}');
  }
}
