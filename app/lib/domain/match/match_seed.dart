import '../../models/match/match_bird.dart';
import 'match_state.dart';

/// A fresh match against the AI opponent "Mara": both Watchers start at 0 km
/// with a deployed opening flock, an opening hand, and an empty discard pile.
MatchState seedPracticeMatch() {
  MatchBird b(String id, String name, String sci, int level, int speed,
          int endurance, [int? daysLeft, bool starter = false]) =>
      MatchBird(
        id: id,
        name: name,
        sci: sci,
        level: level,
        speed: speed,
        endurance: endurance,
        daysLeft: daysLeft ?? endurance,
        starter: starter,
      );

  return MatchState(
    screen: MatchScreen.initiative,
    turn: MatchTurn.lock,
    day: 1,
    youKm: 0,
    oppKm: 0,
    youRoost: [
      b('y1', 'Peregrine Falcon', 'Falco peregrinus', 4, 9, 1, 1),
      b('y2', 'Arctic Tern', 'Sterna paradisaea', 3, 8, 2, 2),
      b('y3', 'Barn Swallow', 'Hirundo rustica', 2, 6, 3, 3),
      b('y4', 'Cedar Waxwing', 'Bombycilla cedrorum', 3, 4, 4, 4),
    ],
    oppRoost: [
      b('o1', 'Bar-tailed Godwit', 'Limosa lapponica', 4, 9, 1, 1),
      b('o2', 'Red Knot', 'Calidris canutus', 3, 7, 2, 2),
      b('o3', 'Canada Goose', 'Branta canadensis', 2, 6, 3, 2),
    ],
    youHand: [
      b('h1', 'Sandhill Crane', 'Antigone canadensis', 5, 7, 2),
      b('h2', 'American Robin', 'Turdus migratorius', 2, 5, 3),
      b('h3', 'Snow Goose', 'Anser caerulescens', 3, 6, 3),
      b('h4', 'Ruby-throated Hummingbird', 'Archilochus colubris', 2, 7, 1),
      b('h5', 'Backyard Sparrow', 'Passer domesticus', 1, 2, 2, null, true),
    ],
    youDeck: 41,
    youDiscard: const [],
    youQueue: [
      b('q1', 'Osprey', 'Pandion haliaetus', 4, 7, 2),
      b('q2', 'Whimbrel', 'Numenius phaeopus', 3, 8, 2),
      b('q3', 'Tree Swallow', 'Tachycineta bicolor', 2, 6, 2),
      b('q4', 'Blackpoll Warbler', 'Setophaga striata', 3, 8, 1),
      b('q5', 'Northern Pintail', 'Anas acuta', 2, 5, 3),
    ],
    oppHand: [
      b('oh1', 'Semipalmated Plover', 'Charadrius semipalmatus', 2, 6, 2),
      b('oh2', 'Ruddy Turnstone', 'Arenaria interpres', 3, 6, 2),
      b('oh3', 'Least Sandpiper', 'Calidris minutilla', 2, 5, 2),
      b('oh4', 'Black-bellied Plover', 'Pluvialis squatarola', 3, 7, 2),
    ],
    oppDeck: 39,
    oppDiscard: const [],
    oppQueue: [
      b('p1', 'Hudsonian Godwit', 'Limosa haemastica', 3, 8, 2),
      b('p2', 'Sanderling', 'Calidris alba', 2, 6, 2),
      b('p3', 'Tundra Swan', 'Cygnus columbianus', 4, 6, 3),
      b('p4', 'Dunlin', 'Calidris alpina', 2, 5, 2),
    ],
    youMod: 3,
    oppMod: 2,
    youRoll: 0,
    oppRoll: 0,
    initRolled: false,
    firstMover: MatchSide.you,
    nightStep: 0,
    shiftReport: null,
    drawnIds: const [],
    deploySelected: const [],
    dawnInit: null,
    winner: null,
    daysPlayed: 0,
    flewCount: 0,
    flash: null,
    dayOver: false,
  );
}

/// A brand-new bot match: opens on the setup night with empty roosts and
/// empty hands. The player draws an opening hand, deploys, then Day 1 begins.
MatchState seedOpeningMatch() {
  MatchBird b(String id, String name, String sci, int level, int speed,
          int endurance, [bool starter = false]) =>
      MatchBird(
        id: id, name: name, sci: sci, level: level, speed: speed,
        endurance: endurance, daysLeft: endurance, starter: starter,
      );

  // Your draw pile (deck). Opening draws 5; the rest feed later nights.
  final youDeck = [
    b('y1', 'Peregrine Falcon', 'Falco peregrinus', 4, 9, 1),
    b('y2', 'Arctic Tern', 'Sterna paradisaea', 3, 8, 2),
    b('y3', 'Sandhill Crane', 'Antigone canadensis', 5, 7, 2),
    b('y4', 'Barn Swallow', 'Hirundo rustica', 2, 6, 3),
    b('y5', 'Snow Goose', 'Anser caerulescens', 3, 6, 3),
    b('y6', 'Cedar Waxwing', 'Bombycilla cedrorum', 3, 4, 4),
    b('y7', 'American Robin', 'Turdus migratorius', 2, 5, 3),
    b('y8', 'Osprey', 'Pandion haliaetus', 4, 7, 2),
    b('y9', 'Whimbrel', 'Numenius phaeopus', 3, 8, 2),
    b('y10', 'Tree Swallow', 'Tachycineta bicolor', 2, 6, 2),
    b('y11', 'Northern Pintail', 'Anas acuta', 2, 5, 3),
    b('y12', 'Backyard Sparrow', 'Passer domesticus', 1, 2, 2, true),
  ];
  final oppDeck = [
    b('o1', 'Bar-tailed Godwit', 'Limosa lapponica', 4, 9, 1),
    b('o2', 'Red Knot', 'Calidris canutus', 3, 7, 2),
    b('o3', 'Hudsonian Godwit', 'Limosa haemastica', 3, 8, 2),
    b('o4', 'Canada Goose', 'Branta canadensis', 2, 6, 3),
    b('o5', 'Sanderling', 'Calidris alba', 2, 6, 2),
    b('o6', 'Tundra Swan', 'Cygnus columbianus', 4, 6, 3),
    b('o7', 'Black-bellied Plover', 'Pluvialis squatarola', 3, 7, 2),
    b('o8', 'Dunlin', 'Calidris alpina', 2, 5, 2),
    b('o9', 'Ruddy Turnstone', 'Arenaria interpres', 3, 6, 2),
    b('o10', 'Least Sandpiper', 'Calidris minutilla', 2, 5, 2),
    b('o11', 'Semipalmated Plover', 'Charadrius semipalmatus', 2, 6, 2),
    b('o12', 'Willet', 'Tringa semipalmata', 3, 6, 2),
  ];

  return MatchState(
    screen: MatchScreen.night,
    turn: MatchTurn.lock,
    day: 1,
    youKm: 0,
    oppKm: 0,
    youRoost: const [],
    oppRoost: const [],
    youHand: const [],
    youDeck: 50,
    youDiscard: const [],
    youQueue: youDeck,
    oppHand: const [],
    oppDeck: 50,
    oppDiscard: const [],
    oppQueue: oppDeck,
    youMod: 3,
    oppMod: 2,
    youRoll: 0,
    oppRoll: 0,
    initRolled: false,
    firstMover: MatchSide.you,
    nightStep: 0,
    shiftReport: null,
    drawnIds: const [],
    deploySelected: const [],
    dawnInit: null,
    winner: null,
    daysPlayed: 0,
    flewCount: 0,
    flash: null,
    dayOver: false,
    setup: true,
  );
}
