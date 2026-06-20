import '../../models/match/match_bird.dart';

enum MatchScreen { initiative, day, night, end }

/// Whose activation it is. [lock] = no input (animations, AI, transitions).
enum MatchTurn { you, opp, lock }

/// A definite side, for first-mover and winner.
enum MatchSide { you, opp }

/// One bird's line in the Night endurance-shift report.
class ShiftEntry {
  const ShiftEntry({required this.name, required this.deltaText, required this.fell});
  final String name;
  final String deltaText; // e.g. "3d → 2d" or "1d → off"
  final bool fell;
}

class ShiftReport {
  const ShiftReport({required this.you, required this.oppFell});
  final List<ShiftEntry> you;
  final int oppFell;
}

/// Result of the dawn re-roll that opens the next day.
class DawnInit {
  const DawnInit({required this.youTotal, required this.oppTotal, required this.first});
  final int youTotal;
  final int oppTotal;
  final MatchSide first;
}

/// Transient description of the bird that just flew, for the move toast.
class FlyFlash {
  const FlyFlash({required this.side, required this.birdName, required this.km});
  final MatchSide side;
  final String birdName;
  final int km;
}

/// The complete logical state of a match. Display-only animated values
/// (e.g. the counting-up km number) live in the UI layer, not here.
class MatchState {
  const MatchState({
    required this.screen,
    required this.turn,
    required this.day,
    required this.youKm,
    required this.oppKm,
    required this.youRoost,
    required this.oppRoost,
    required this.youHand,
    required this.youDeck,
    required this.youDiscard,
    required this.youQueue,
    required this.oppHand,
    required this.oppDeck,
    required this.oppDiscard,
    required this.oppQueue,
    required this.youMod,
    required this.oppMod,
    required this.youRoll,
    required this.oppRoll,
    required this.initRolled,
    required this.firstMover,
    required this.nightStep,
    required this.shiftReport,
    required this.drawnIds,
    required this.deploySelected,
    required this.dawnInit,
    required this.winner,
    required this.daysPlayed,
    required this.flewCount,
    required this.flash,
    required this.dayOver,
    this.youNightDone = false,
    this.oppNightDone = false,
  });

  final MatchScreen screen;
  final MatchTurn turn;
  final int day;

  final int youKm;
  final int oppKm;

  final List<MatchBird> youRoost;
  final List<MatchBird> oppRoost;

  final List<MatchBird> youHand;
  final int youDeck;
  final List<MatchBird> youDiscard;
  final List<MatchBird> youQueue; // draw source (front = top of deck)

  // Fully materialized so the state is symmetric for two-human play. The
  // opponent's hand is private — render only its length to the viewer.
  final List<MatchBird> oppHand;
  final int oppDeck;
  final List<MatchBird> oppDiscard;
  final List<MatchBird> oppQueue;

  final int youMod;
  final int oppMod;

  // Initiative
  final int youRoll;
  final int oppRoll;
  final bool initRolled;
  final MatchSide firstMover;

  // Night
  final int nightStep; // 0–4
  final ShiftReport? shiftReport;
  final List<String> drawnIds;
  final List<String> deploySelected; // ≤ 3
  final DawnInit? dawnInit;

  // End
  final MatchSide? winner;
  final int daysPlayed;
  final int flewCount;

  // Transient
  final FlyFlash? flash;
  final bool dayOver; // both roosts fully tapped; controller moves to Night

  // Async night: each player completes their own night independently.
  final bool youNightDone;
  final bool oppNightDone;

  bool get youHasUntapped => youRoost.any((b) => !b.tapped);
  bool get oppHasUntapped => oppRoost.any((b) => !b.tapped);

  /// The same match from the opponent's point of view — every you/opp pair
  /// swapped, so each player always sees themselves as "you". Night UI fields
  /// (nightStep/drawnIds/deploySelected) belong to whoever is acting and are
  /// carried as-is. Used to store canonically (player1's view) yet let player2
  /// play as "you".
  MatchState flip() {
    MatchTurn flipTurn(MatchTurn t) => switch (t) {
          MatchTurn.you => MatchTurn.opp,
          MatchTurn.opp => MatchTurn.you,
          MatchTurn.lock => MatchTurn.lock,
        };
    MatchSide flipSide(MatchSide s) =>
        s == MatchSide.you ? MatchSide.opp : MatchSide.you;
    return MatchState(
      screen: screen,
      turn: flipTurn(turn),
      day: day,
      youKm: oppKm,
      oppKm: youKm,
      youRoost: oppRoost,
      oppRoost: youRoost,
      youHand: oppHand,
      youDeck: oppDeck,
      youDiscard: oppDiscard,
      youQueue: oppQueue,
      oppHand: youHand,
      oppDeck: youDeck,
      oppDiscard: youDiscard,
      oppQueue: youQueue,
      youMod: oppMod,
      oppMod: youMod,
      youRoll: oppRoll,
      oppRoll: youRoll,
      initRolled: initRolled,
      firstMover: flipSide(firstMover),
      nightStep: nightStep,
      shiftReport: shiftReport,
      drawnIds: drawnIds,
      deploySelected: deploySelected,
      dawnInit: dawnInit,
      winner: winner == null ? null : flipSide(winner!),
      daysPlayed: daysPlayed,
      flewCount: flewCount,
      flash: flash,
      dayOver: dayOver,
      youNightDone: oppNightDone,
      oppNightDone: youNightDone,
    );
  }

  static List<MatchBird> _birds(dynamic list) =>
      ((list as List?) ?? const [])
          .map((e) => MatchBird.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

  Map<String, dynamic> toJson() => {
        'screen': screen.name,
        'turn': turn.name,
        'day': day,
        'youKm': youKm,
        'oppKm': oppKm,
        'youRoost': youRoost.map((b) => b.toJson()).toList(),
        'oppRoost': oppRoost.map((b) => b.toJson()).toList(),
        'youHand': youHand.map((b) => b.toJson()).toList(),
        'youDeck': youDeck,
        'youDiscard': youDiscard.map((b) => b.toJson()).toList(),
        'youQueue': youQueue.map((b) => b.toJson()).toList(),
        'oppHand': oppHand.map((b) => b.toJson()).toList(),
        'oppDeck': oppDeck,
        'oppDiscard': oppDiscard.map((b) => b.toJson()).toList(),
        'oppQueue': oppQueue.map((b) => b.toJson()).toList(),
        'youMod': youMod,
        'oppMod': oppMod,
        'youRoll': youRoll,
        'oppRoll': oppRoll,
        'initRolled': initRolled,
        'firstMover': firstMover.name,
        'nightStep': nightStep,
        'drawnIds': drawnIds,
        'deploySelected': deploySelected,
        'winner': winner?.name,
        'daysPlayed': daysPlayed,
        'flewCount': flewCount,
        'dayOver': dayOver,
        'youNightDone': youNightDone,
        'oppNightDone': oppNightDone,
        // shiftReport / dawnInit / flash are transient — not persisted.
      };

  factory MatchState.fromJson(Map<String, dynamic> json) => MatchState(
        screen: MatchScreen.values.byName(json['screen'] as String),
        turn: MatchTurn.values.byName(json['turn'] as String),
        day: json['day'] as int,
        youKm: json['youKm'] as int,
        oppKm: json['oppKm'] as int,
        youRoost: _birds(json['youRoost']),
        oppRoost: _birds(json['oppRoost']),
        youHand: _birds(json['youHand']),
        youDeck: json['youDeck'] as int,
        youDiscard: _birds(json['youDiscard']),
        youQueue: _birds(json['youQueue']),
        oppHand: _birds(json['oppHand']),
        oppDeck: json['oppDeck'] as int,
        oppDiscard: _birds(json['oppDiscard']),
        oppQueue: _birds(json['oppQueue']),
        youMod: json['youMod'] as int,
        oppMod: json['oppMod'] as int,
        youRoll: json['youRoll'] as int,
        oppRoll: json['oppRoll'] as int,
        initRolled: json['initRolled'] as bool,
        firstMover: MatchSide.values.byName(json['firstMover'] as String),
        nightStep: json['nightStep'] as int,
        shiftReport: null,
        drawnIds: ((json['drawnIds'] as List?) ?? const []).cast<String>(),
        deploySelected: ((json['deploySelected'] as List?) ?? const []).cast<String>(),
        dawnInit: null,
        winner: json['winner'] == null
            ? null
            : MatchSide.values.byName(json['winner'] as String),
        daysPlayed: json['daysPlayed'] as int,
        flewCount: json['flewCount'] as int,
        flash: null,
        dayOver: json['dayOver'] as bool? ?? false,
        youNightDone: json['youNightDone'] as bool? ?? false,
        oppNightDone: json['oppNightDone'] as bool? ?? false,
      );

  MatchState copyWith({
    MatchScreen? screen,
    MatchTurn? turn,
    int? day,
    int? youKm,
    int? oppKm,
    List<MatchBird>? youRoost,
    List<MatchBird>? oppRoost,
    List<MatchBird>? youHand,
    int? youDeck,
    List<MatchBird>? youDiscard,
    List<MatchBird>? youQueue,
    List<MatchBird>? oppHand,
    int? oppDeck,
    List<MatchBird>? oppDiscard,
    List<MatchBird>? oppQueue,
    int? youRoll,
    int? oppRoll,
    bool? initRolled,
    MatchSide? firstMover,
    int? nightStep,
    ShiftReport? shiftReport,
    List<String>? drawnIds,
    List<String>? deploySelected,
    DawnInit? dawnInit,
    MatchSide? winner,
    int? daysPlayed,
    int? flewCount,
    FlyFlash? flash,
    bool? dayOver,
    bool? youNightDone,
    bool? oppNightDone,
    bool clearFlash = false,
    bool clearShiftReport = false,
    bool clearDawnInit = false,
  }) =>
      MatchState(
        screen: screen ?? this.screen,
        turn: turn ?? this.turn,
        day: day ?? this.day,
        youKm: youKm ?? this.youKm,
        oppKm: oppKm ?? this.oppKm,
        youRoost: youRoost ?? this.youRoost,
        oppRoost: oppRoost ?? this.oppRoost,
        youHand: youHand ?? this.youHand,
        youDeck: youDeck ?? this.youDeck,
        youDiscard: youDiscard ?? this.youDiscard,
        youQueue: youQueue ?? this.youQueue,
        oppHand: oppHand ?? this.oppHand,
        oppDeck: oppDeck ?? this.oppDeck,
        oppDiscard: oppDiscard ?? this.oppDiscard,
        oppQueue: oppQueue ?? this.oppQueue,
        youMod: youMod,
        oppMod: oppMod,
        youRoll: youRoll ?? this.youRoll,
        oppRoll: oppRoll ?? this.oppRoll,
        initRolled: initRolled ?? this.initRolled,
        firstMover: firstMover ?? this.firstMover,
        nightStep: nightStep ?? this.nightStep,
        shiftReport: clearShiftReport ? null : (shiftReport ?? this.shiftReport),
        drawnIds: drawnIds ?? this.drawnIds,
        deploySelected: deploySelected ?? this.deploySelected,
        dawnInit: clearDawnInit ? null : (dawnInit ?? this.dawnInit),
        winner: winner ?? this.winner,
        daysPlayed: daysPlayed ?? this.daysPlayed,
        flewCount: flewCount ?? this.flewCount,
        flash: clearFlash ? null : (flash ?? this.flash),
        dayOver: dayOver ?? this.dayOver,
        youNightDone: youNightDone ?? this.youNightDone,
        oppNightDone: oppNightDone ?? this.oppNightDone,
      );
}
