import 'package:flutter_test/flutter_test.dart';
import 'package:first_light/domain/match/match_engine.dart';
import 'package:first_light/domain/match/match_rules.dart';
import 'package:first_light/domain/match/match_seed.dart';
import 'package:first_light/domain/match/match_state.dart';

void main() {
  group('MatchRules', () {
    test('fly distance is speed × 100', () {
      expect(MatchRules.flyKm(9), 900);
      expect(MatchRules.flyKm(2), 200);
    });

    test('flock penalty bands', () {
      expect(MatchRules.flockPenalty(2), 0);
      expect(MatchRules.flockPenalty(4), 1);
      expect(MatchRules.flockPenalty(6), 2);
      expect(MatchRules.flockPenalty(7), 3);
    });

    test('initiative total subtracts the flock penalty', () {
      expect(
        MatchRules.initiativeTotal(roll: 15, skillMod: 3, roostSize: 5),
        15 + 3 - 2,
      );
    });

    test('first mover: higher total wins, ties go to the smaller flock', () {
      expect(
        MatchRules.youActFirst(youTotal: 18, oppTotal: 17, youRoostSize: 5, oppRoostSize: 3),
        isTrue,
      );
      expect(
        MatchRules.youActFirst(youTotal: 17, oppTotal: 17, youRoostSize: 3, oppRoostSize: 5),
        isTrue, // tie, you have the smaller flock
      );
      expect(
        MatchRules.youActFirst(youTotal: 17, oppTotal: 17, youRoostSize: 5, oppRoostSize: 3),
        isFalse, // tie, opponent smaller
      );
    });
  });

  group('friend (async) night', () {
    test('each player takes their own night; second finisher starts the day', () {
      // Enter night with you as first mover.
      var s = seedPracticeMatch().copyWith(
        screen: MatchScreen.day,
        dayOver: true,
        firstMover: MatchSide.you,
      );
      s = MatchEngine.enterNightFriend(s);
      expect(s.screen, MatchScreen.night);
      expect(s.turn, MatchTurn.you); // first mover's night
      expect(s.youNightDone, isFalse);

      // You draw + deploy → night hands off to the opponent, not dawn.
      s = MatchEngine.friendDraw(s);
      s = MatchEngine.toggleDeploy(s.copyWith(nightStep: 3), 'h2');
      s = MatchEngine.friendConfirmDeploy(s, youRoll: 10, oppRoll: 10);
      expect(s.youNightDone, isTrue);
      expect(s.turn, MatchTurn.opp); // opponent's night now
      expect(s.screen, MatchScreen.night); // not the next day yet

      // Opponent (after flip, they are "you") takes their night and finishes.
      var o = s.flip();
      expect(o.oppNightDone, isTrue); // the first player, from opp view
      o = MatchEngine.friendDraw(o);
      o = MatchEngine.friendConfirmDeploy(o.copyWith(nightStep: 3), youRoll: 12, oppRoll: 8);
      // Both done → next day begins.
      expect(o.screen, MatchScreen.day);
      expect(o.day, seedPracticeMatch().day + 1);
    });
  });

  group('perspective flip', () {
    test('swaps you/opp so each player sees themselves as "you"', () {
      final s = seedPracticeMatch().copyWith(turn: MatchTurn.you);
      final f = s.flip();
      expect(f.youKm, s.oppKm);
      expect(f.oppKm, s.youKm);
      expect(f.youRoost.first.id, s.oppRoost.first.id);
      expect(f.youHand.length, s.oppHand.length);
      expect(f.turn, MatchTurn.opp); // your turn becomes the opponent's
    });

    test('flipping twice is the identity', () {
      final s = seedPracticeMatch().copyWith(turn: MatchTurn.opp, youKm: 4200, oppKm: 5100);
      final back = s.flip().flip();
      expect(back.youKm, s.youKm);
      expect(back.oppKm, s.oppKm);
      expect(back.turn, s.turn);
      expect(back.youRoost.length, s.youRoost.length);
      expect(back.firstMover, s.firstMover);
    });
  });

  group('serialization', () {
    test('a mid-match state round-trips through JSON', () {
      // Advance a bit so roosts, hands, discard, and km all differ.
      var s = MatchEngine.beginFirstLight(
        seedPracticeMatch().copyWith(turn: MatchTurn.you),
      );
      s = MatchEngine.fly(s, 'y1');
      s = MatchEngine.applyShift(s.copyWith(screen: MatchScreen.night));

      final restored = MatchState.fromJson(s.toJson());
      expect(restored.screen, s.screen);
      expect(restored.turn, s.turn);
      expect(restored.youKm, s.youKm);
      expect(restored.youRoost.length, s.youRoost.length);
      expect(restored.youDiscard.length, s.youDiscard.length);
      expect(restored.youRoost.first.id, s.youRoost.first.id);
      expect(restored.flewCount, s.flewCount);
      expect(restored.firstMover, s.firstMover);
    });
  });

  group('initiative', () {
    test('roll resolves the first mover from totals', () {
      final s = seedPracticeMatch();
      // you: 18+3-pen(4)=20 ; opp: 5+2-pen(3)=6 → you first
      final rolled = MatchEngine.rollInitiative(s, youRoll: 18, oppRoll: 5);
      expect(rolled.initRolled, isTrue);
      expect(rolled.firstMover, MatchSide.you);

      final begun = MatchEngine.beginFirstLight(rolled);
      expect(begun.screen, MatchScreen.day);
      expect(begun.turn, MatchTurn.you);
    });
  });

  group('fly', () {
    test('banks distance, taps the bird, and hands off to the opponent', () {
      final s = MatchEngine.beginFirstLight(
        seedPracticeMatch().copyWith(firstMover: MatchSide.you, turn: MatchTurn.you),
      );
      final after = MatchEngine.fly(s, 'y1'); // Peregrine, speed 9

      expect(after.youKm, 6200 + 900);
      expect(after.youRoost.firstWhere((b) => b.id == 'y1').tapped, isTrue);
      expect(after.flewCount, 1);
      expect(after.flash!.km, 900);
      expect(after.turn, MatchTurn.opp); // opponent still has untapped birds
    });

    test('reaching 10,000 km wins immediately', () {
      var s = seedPracticeMatch().copyWith(
        screen: MatchScreen.day,
        turn: MatchTurn.you,
        youKm: 9200, // +900 → 10,100
      );
      final after = MatchEngine.fly(s, 'y1');
      expect(after.winner, MatchSide.you);
      expect(after.turn, MatchTurn.lock);
    });

    test('day ends when both roosts are fully tapped', () {
      // One bird each, both about to be spent.
      var s = seedPracticeMatch().copyWith(
        screen: MatchScreen.day,
        turn: MatchTurn.you,
        youRoost: [seedPracticeMatch().youRoost.first], // y1 untapped
        oppRoost: [seedPracticeMatch().oppRoost.first.copyWith(tapped: true)],
      );
      final after = MatchEngine.fly(s, 'y1');
      expect(after.dayOver, isTrue);
      expect(after.turn, MatchTurn.lock);
    });
  });

  group('opponentFly', () {
    test('flies the highest-speed untapped bird', () {
      final s = seedPracticeMatch().copyWith(screen: MatchScreen.day, turn: MatchTurn.opp);
      final after = MatchEngine.opponentFly(s);
      // o1 Bar-tailed Godwit speed 9 is highest.
      expect(after.oppKm, 6800 + 900);
      expect(after.oppRoost.firstWhere((b) => b.id == 'o1').tapped, isTrue);
    });
  });

  group('night', () {
    test('shift ages every bird and exhausts those that hit zero', () {
      final s = MatchEngine.applyShift(seedPracticeMatch());
      // y1 Peregrine had 1 day left → exhausted.
      expect(s.youRoost.any((b) => b.id == 'y1'), isFalse);
      expect(s.youDiscard.any((b) => b.id == 'y1' && b.reason == 'exhausted'), isTrue);
      // y2 Arctic Tern 2 → 1, untapped.
      final tern = s.youRoost.firstWhere((b) => b.id == 'y2');
      expect(tern.daysLeft, 1);
      expect(tern.tapped, isFalse);
      expect(s.nightStep, 1);
    });

    test('draw respects the hand cap of 7', () {
      // Hand of 6 → can only draw 1.
      var s = seedPracticeMatch();
      s = s.copyWith(youHand: [...s.youHand, s.youQueue.first]); // 6 in hand
      final drawn = MatchEngine.applyDraw(s.copyWith(youQueue: s.youQueue.skip(1).toList()));
      expect(drawn.youHand.length, 7);
      expect(drawn.drawnIds.length, 1);
    });

    test('deploy moves up to 3 selected birds into the roost at full endurance', () {
      var s = seedPracticeMatch();
      s = MatchEngine.openDeploy(s.copyWith(nightStep: 2));
      s = MatchEngine.toggleDeploy(s, 'h1');
      s = MatchEngine.toggleDeploy(s, 'h2');
      final before = s.youRoost.length;
      final after = MatchEngine.confirmDeploy(s, youRoll: 10, oppRoll: 10);

      expect(after.youRoost.length, before + 2);
      expect(after.youHand.any((b) => b.id == 'h1'), isFalse);
      final crane = after.youRoost.firstWhere((b) => b.id == 'h1');
      expect(crane.daysLeft, crane.endurance);
      expect(crane.tapped, isFalse);
      expect(after.nightStep, 4);
      expect(after.dawnInit, isNotNull);
    });

    test('deploy selection caps at 3', () {
      var s = MatchEngine.openDeploy(seedPracticeMatch().copyWith(nightStep: 2));
      for (final id in ['h1', 'h2', 'h3', 'h4']) {
        s = MatchEngine.toggleDeploy(s, id);
      }
      expect(s.deploySelected.length, 3);
    });

    test('beginNextDay advances the day and hands initiative to the first mover', () {
      var s = seedPracticeMatch().copyWith(
        screen: MatchScreen.night,
        nightStep: 4,
        firstMover: MatchSide.opp,
        day: 1,
      );
      final next = MatchEngine.beginNextDay(s);
      expect(next.screen, MatchScreen.day);
      expect(next.day, 2);
      expect(next.turn, MatchTurn.opp);
      expect(next.shiftReport, isNull);
    });
  });
}
