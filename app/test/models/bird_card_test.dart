import 'package:flutter_test/flutter_test.dart';
import 'package:first_light/models/bird_card.dart';

void main() {
  final json = {
    'id': 'card-1',
    'user_id': 'user-1',
    'species_name': 'Northern Cardinal',
    'scientific_name': 'Cardinalis cardinalis',
    'level': 2,
    'xp': 25,
    'catch_count': 3,
    'first_catch_date': '2026-06-01T00:00:00.000',
    'first_catch_location': 'Backyard',
    'description': 'A red bird.',
    'facts': ['Sings year-round'],
    'migration_speed': 3,
    'endurance': 2,
    'first_catch_latitude': 40.7,
    'first_catch_longitude': -74.0,
    'screenshot_url': 'https://example.com/s.jpg',
    'line_art_url': 'https://example.com/art.svg',
    'last_caught_at': '2026-06-08T00:00:00.000',
    'created_at': '2026-06-01T12:00:00.000',
  };

  test('fromJson/toJson round-trips every field', () {
    final card = BirdCard.fromJson(json);
    expect(card.toJson(), json);
  });

  test('copyWith preserves fields it does not change', () {
    final card = BirdCard.fromJson(json);
    final copied = card.copyWith(lineArtUrl: 'https://example.com/new.svg');

    expect(copied.firstCatchLatitude, card.firstCatchLatitude);
    expect(copied.firstCatchLongitude, card.firstCatchLongitude);
    expect(copied.lastCaughtAt, card.lastCaughtAt);
    expect(copied.screenshotUrl, card.screenshotUrl);
    expect(copied.lineArtUrl, 'https://example.com/new.svg');
  });
}
