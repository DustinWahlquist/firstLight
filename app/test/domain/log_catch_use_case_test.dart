import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:first_light/data/aviary_repository.dart';
import 'package:first_light/domain/log_catch_use_case.dart';
import 'package:first_light/models/bird_card.dart';
import 'package:first_light/models/parse_result.dart';

class _FakeAviaryRepository extends Fake implements AviaryRepository {
  BirdCard? existingCard;
  bool alreadyCaughtToday = false;
  Map<String, dynamic> serverOutcome = const {};

  int uploadCount = 0;
  Map<String, dynamic>? submitted;

  @override
  Future<BirdCard?> fetchCard(String speciesName) async => existingCard;

  @override
  Future<bool> hasCaughtOnDate(String birdCardId, DateTime date) async =>
      alreadyCaughtToday;

  @override
  Future<String> uploadScreenshot(File file) async {
    uploadCount++;
    return 'https://example.com/screenshot.jpg';
  }

  @override
  Future<Map<String, dynamic>> submitCatch({
    required ParseResult parse,
    required String screenshotUrl,
  }) async {
    submitted = {'species': parse.speciesName, 'screenshotUrl': screenshotUrl};
    return serverOutcome;
  }
}

Map<String, dynamic> _cardJson({int xp = 0, int level = 1}) => {
      'id': 'card-1',
      'user_id': 'user-1',
      'species_name': 'Northern Cardinal',
      'scientific_name': 'Cardinalis cardinalis',
      'level': level,
      'xp': xp,
      'catch_count': 2,
      'first_catch_date': '2026-06-01',
      'first_catch_location': 'Backyard',
      'description': '',
      'facts': <String>[],
      'migration_speed': 5,
      'endurance': 3,
      'created_at': '2026-06-01T12:00:00.000Z',
    };

BirdCard _card({int xp = 0, int level = 1}) =>
    BirdCard.fromJson(_cardJson(xp: xp, level: level));

ParseResult _parse({DateTime? date}) => ParseResult(
      speciesName: 'Northern Cardinal',
      scientificName: 'Cardinalis cardinalis',
      sightingRarity: 'Uncommon',
      date: date ?? DateTime(2026, 6, 8),
      location: 'Backyard',
      description: 'A red bird.',
      facts: const [],
      migrationSpeed: 3,
      endurance: 2,
    );

void main() {
  late _FakeAviaryRepository aviary;
  late LogCatchUseCase useCase;
  final screenshot = File('test/fixtures/fake.jpg');
  final now = DateTime(2026, 6, 9, 12);

  setUp(() {
    aviary = _FakeAviaryRepository();
    useCase = LogCatchUseCase(aviary: aviary, now: () => now);
  });

  test('precheck rejects duplicates without uploading', () async {
    aviary
      ..existingCard = _card()
      ..alreadyCaughtToday = true;

    final rejection = await useCase.precheck(_parse(date: DateTime(2026, 6, 5)));

    expect(rejection, isA<LogCatchDuplicate>());
    expect((rejection as LogCatchDuplicate).date, DateTime(2026, 6, 5));
    expect(aviary.uploadCount, 0);
  });

  test('precheck passes a loggable catch', () async {
    expect(await useCase.precheck(_parse()), isNull);
  });

  test('fast-fails future-dated screenshots without uploading', () async {
    final result = await useCase(
      parse: _parse(date: DateTime(2026, 6, 10)),
      screenshot: screenshot,
    );

    expect(result, isA<LogCatchFutureDated>());
    expect(aviary.uploadCount, 0);
    expect(aviary.submitted, isNull);
  });

  test('fast-fails same-day repeat catches without uploading', () async {
    aviary
      ..existingCard = _card()
      ..alreadyCaughtToday = true;

    final result = await useCase(
      parse: _parse(date: DateTime(2026, 6, 5)),
      screenshot: screenshot,
    );

    expect(result, isA<LogCatchDuplicate>());
    expect((result as LogCatchDuplicate).date, DateTime(2026, 6, 5));
    expect(aviary.uploadCount, 0);
    expect(aviary.submitted, isNull);
  });

  test('maps a new_lifer outcome to the created card', () async {
    aviary.serverOutcome = {'kind': 'new_lifer', 'card': _cardJson()};

    final result = await useCase(parse: _parse(), screenshot: screenshot);

    expect(result, isA<LogCatchNewLifer>());
    expect((result as LogCatchNewLifer).card.speciesName, 'Northern Cardinal');
    expect(aviary.submitted!['screenshotUrl'], 'https://example.com/screenshot.jpg');
  });

  test('maps an xp_awarded outcome with before/after cards', () async {
    aviary
      ..existingCard = _card(xp: 10, level: 1)
      ..serverOutcome = {'kind': 'xp_awarded', 'card': _cardJson(xp: 20, level: 2)};

    final result = await useCase(parse: _parse(), screenshot: screenshot);

    final awarded = result as LogCatchXpAwarded;
    expect(awarded.before.xp, 10);
    expect(awarded.after.xp, 20);
    expect(awarded.leveledUp, isTrue);
  });

  test('does not report a level-up when the level is unchanged', () async {
    aviary
      ..existingCard = _card(xp: 0, level: 1)
      ..serverOutcome = {'kind': 'xp_awarded', 'card': _cardJson(xp: 10, level: 1)};

    final result = await useCase(parse: _parse(), screenshot: screenshot);

    expect((result as LogCatchXpAwarded).leveledUp, isFalse);
  });

  test('respects a server-side duplicate verdict and carries the catch day', () async {
    aviary
      ..existingCard = _card()
      ..serverOutcome = {'kind': 'duplicate'};

    final result = await useCase(
      parse: _parse(date: DateTime(2026, 6, 5)),
      screenshot: screenshot,
    );

    expect(result, isA<LogCatchDuplicate>());
    expect((result as LogCatchDuplicate).date, DateTime(2026, 6, 5));
  });

  test('throws on an unknown outcome kind', () async {
    aviary.serverOutcome = {'kind': 'mystery'};

    expect(
      () => useCase(parse: _parse(), screenshot: screenshot),
      throwsStateError,
    );
  });
}
