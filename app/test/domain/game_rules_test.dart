import 'package:flutter_test/flutter_test.dart';
import 'package:first_light/domain/game_rules.dart';
import 'package:first_light/domain/sighting_rarity.dart';

void main() {
  group('SightingRarity.fromString', () {
    test('parses the three sighting tiers from Merlin', () {
      expect(SightingRarity.fromString('Common'), SightingRarity.common);
      expect(SightingRarity.fromString('Uncommon'), SightingRarity.uncommon);
      expect(SightingRarity.fromString('Rare'), SightingRarity.rare);
    });

    test('is case- and whitespace-insensitive', () {
      expect(SightingRarity.fromString(' UNCOMMON '), SightingRarity.uncommon);
      expect(SightingRarity.fromString('rare'), SightingRarity.rare);
    });

    test('falls back to common for unknown values', () {
      expect(SightingRarity.fromString(''), SightingRarity.common);
      expect(SightingRarity.fromString('Mythical'), SightingRarity.common);
    });
  });

  group('SightingRarity.xpPerCatch', () {
    test('awards 5 / 10 / 15 XP', () {
      expect(SightingRarity.common.xpPerCatch, 5);
      expect(SightingRarity.uncommon.xpPerCatch, 10);
      expect(SightingRarity.rare.xpPerCatch, 15);
    });
  });

  group('GameRules.levelForXp', () {
    test('maps XP to levels at the documented thresholds', () {
      expect(GameRules.levelForXp(0), 1);
      expect(GameRules.levelForXp(19), 1);
      expect(GameRules.levelForXp(20), 2);
      expect(GameRules.levelForXp(49), 2);
      expect(GameRules.levelForXp(50), 3);
      expect(GameRules.levelForXp(90), 4);
      expect(GameRules.levelForXp(140), 5);
    });

    test('caps at max level', () {
      expect(GameRules.levelForXp(10000), GameRules.maxLevel);
    });
  });

  group('GameRules.xpForNextLevel', () {
    test('returns the next threshold', () {
      expect(GameRules.xpForNextLevel(1), 20);
      expect(GameRules.xpForNextLevel(4), 140);
    });

    test('returns the final threshold at max level', () {
      expect(GameRules.xpForNextLevel(5), 140);
    });
  });

  group('GameRules.isFutureDated', () {
    final now = DateTime(2026, 6, 9, 14, 30);

    test('accepts catches from today and the past', () {
      expect(GameRules.isFutureDated(DateTime(2026, 6, 9), now), isFalse);
      expect(GameRules.isFutureDated(DateTime(2026, 6, 9, 23, 59), now), isFalse);
      expect(GameRules.isFutureDated(DateTime(2025, 1, 1), now), isFalse);
    });

    test('rejects catches dated after today', () {
      expect(GameRules.isFutureDated(DateTime(2026, 6, 10), now), isTrue);
    });
  });

  group('GameRules.isSameCalendarDay', () {
    test('compares calendar days, not 24-hour windows', () {
      expect(
        GameRules.isSameCalendarDay(
            DateTime(2026, 6, 9, 1), DateTime(2026, 6, 9, 23)),
        isTrue,
      );
      expect(
        GameRules.isSameCalendarDay(
            DateTime(2026, 6, 9, 23), DateTime(2026, 6, 10, 1)),
        isFalse,
      );
    });
  });

  group('GameRules.isLiferMilestone', () {
    test('matches only the milestone counts', () {
      expect(GameRules.isLiferMilestone(10), isTrue);
      expect(GameRules.isLiferMilestone(11), isFalse);
      expect(GameRules.isLiferMilestone(500), isTrue);
    });
  });
}
