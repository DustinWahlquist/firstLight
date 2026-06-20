import '../../models/match/match_bird.dart';
import 'match_rules.dart';
import 'match_state.dart';

/// Pure state transitions for a match. Every method takes a [MatchState] and
/// returns the next one — no timers, no I/O, no randomness of its own (rolls
/// are passed in). The controller layer orchestrates delays, the AI cadence,
/// and km animations on top of these.
abstract final class MatchEngine {
  /// Records an initiative roll and resolves who acts first.
  static MatchState rollInitiative(
    MatchState s, {
    required int youRoll,
    required int oppRoll,
  }) {
    final youTotal = MatchRules.initiativeTotal(
        roll: youRoll, skillMod: s.youMod, roostSize: s.youRoost.length);
    final oppTotal = MatchRules.initiativeTotal(
        roll: oppRoll, skillMod: s.oppMod, roostSize: s.oppRoost.length);
    final youFirst = MatchRules.youActFirst(
      youTotal: youTotal,
      oppTotal: oppTotal,
      youRoostSize: s.youRoost.length,
      oppRoostSize: s.oppRoost.length,
    );
    return s.copyWith(
      youRoll: youRoll,
      oppRoll: oppRoll,
      initRolled: true,
      firstMover: youFirst ? MatchSide.you : MatchSide.opp,
    );
  }

  /// Moves from the initiative screen into the day, first mover to act.
  static MatchState beginFirstLight(MatchState s) => s.copyWith(
        screen: MatchScreen.day,
        turn: s.firstMover == MatchSide.you ? MatchTurn.you : MatchTurn.opp,
      );

  /// You fly [birdId]: tap it, bank its distance, advance the turn.
  static MatchState fly(MatchState s, String birdId) {
    final bird = s.youRoost.firstWhere((b) => b.id == birdId);
    final roost = _tap(s.youRoost, birdId);
    final km = s.youKm + bird.flyKm;
    final base = s.copyWith(
      youRoost: roost,
      youKm: km,
      flewCount: s.flewCount + 1,
      flash: FlyFlash(side: MatchSide.you, birdName: bird.name, km: bird.flyKm),
    );
    return _advanceAfterActivation(base, youRoost: roost, winningSide: km >= MatchRules.winKm ? MatchSide.you : null);
  }

  /// The opponent AI flies its highest-speed untapped bird.
  static MatchState opponentFly(MatchState s) {
    final untapped = s.oppRoost.where((b) => !b.tapped).toList();
    if (untapped.isEmpty) {
      return _advanceAfterActivation(s, youRoost: s.youRoost, winningSide: null);
    }
    untapped.sort((a, b) => b.speed.compareTo(a.speed));
    final pick = untapped.first;
    final roost = _tap(s.oppRoost, pick.id);
    final km = s.oppKm + pick.flyKm;
    final base = s.copyWith(
      oppRoost: roost,
      oppKm: km,
      flash: FlyFlash(side: MatchSide.opp, birdName: pick.name, km: pick.flyKm),
    );
    return _advanceAfterActivation(base, oppRoost: roost, winningSide: km >= MatchRules.winKm ? MatchSide.opp : null);
  }

  /// Shared turn-advance: win → lock+winner; else hand off to whoever still
  /// has untapped birds; else flag the day over.
  static MatchState _advanceAfterActivation(
    MatchState s, {
    List<MatchBird>? youRoost,
    List<MatchBird>? oppRoost,
    MatchSide? winningSide,
  }) {
    final you = youRoost ?? s.youRoost;
    final opp = oppRoost ?? s.oppRoost;
    if (winningSide != null) {
      return s.copyWith(turn: MatchTurn.lock, winner: winningSide);
    }
    final youUn = you.any((b) => !b.tapped);
    final oppUn = opp.any((b) => !b.tapped);
    // The side that just acted is whoever's turn it currently was.
    final actor = s.turn;
    if (actor == MatchTurn.you) {
      if (oppUn) return s.copyWith(turn: MatchTurn.opp);
      if (youUn) return s.copyWith(turn: MatchTurn.you);
    } else {
      if (youUn) return s.copyWith(turn: MatchTurn.you);
      if (oppUn) return s.copyWith(turn: MatchTurn.opp);
    }
    return s.copyWith(turn: MatchTurn.lock, dayOver: true);
  }

  /// Enters the Night sequence at step 0.
  static MatchState toNight(MatchState s) => s.copyWith(
        screen: MatchScreen.night,
        turn: MatchTurn.lock,
        nightStep: 0,
        dayOver: false,
        clearFlash: true,
      );

  /// Night step 0→1: every roosting bird loses a day; 0 → exhausted (discard).
  static MatchState applyShift(MatchState s) {
    final you = _shift(s.youRoost);
    final opp = _shift(s.oppRoost);
    return s.copyWith(
      youRoost: you.survivors,
      oppRoost: opp.survivors,
      youDiscard: [...s.youDiscard, ...you.fell],
      oppDiscard: [...s.oppDiscard, ...opp.fell],
      shiftReport: ShiftReport(you: you.report, oppFell: opp.fell.length),
      nightStep: 1,
    );
  }

  /// Night step 1→2: draw 2, capped at a hand of 7 (overflow forfeited).
  static MatchState applyDraw(MatchState s) {
    final take = (MatchRules.handCap - s.youHand.length)
        .clamp(0, MatchRules.drawPerNight)
        .clamp(0, s.youQueue.length);
    final drawn = s.youQueue.take(take).toList();
    final oppTake = (MatchRules.handCap - s.oppHand.length)
        .clamp(0, MatchRules.drawPerNight)
        .clamp(0, s.oppQueue.length);
    final oppDrawn = s.oppQueue.take(oppTake).toList();
    return s.copyWith(
      youHand: [...s.youHand, ...drawn],
      youQueue: s.youQueue.skip(take).toList(),
      youDeck: (s.youDeck - take).clamp(0, s.youDeck),
      drawnIds: drawn.map((b) => b.id).toList(),
      oppHand: [...s.oppHand, ...oppDrawn],
      oppQueue: s.oppQueue.skip(oppTake).toList(),
      oppDeck: (s.oppDeck - oppTake).clamp(0, s.oppDeck),
      nightStep: 2,
    );
  }

  /// Night step 2→3: open the deploy selector.
  static MatchState openDeploy(MatchState s) =>
      s.copyWith(nightStep: 3, deploySelected: const []);

  /// Toggles a hand card in the deploy selection (max 3).
  static MatchState toggleDeploy(MatchState s, String id) {
    final sel = s.deploySelected;
    if (sel.contains(id)) {
      return s.copyWith(deploySelected: sel.where((x) => x != id).toList());
    }
    if (sel.length >= MatchRules.deployPerNight) return s;
    return s.copyWith(deploySelected: [...sel, id]);
  }

  /// Night step 3→4: deploy the selected birds, deploy the AI's, and re-roll
  /// initiative for the coming dawn.
  static MatchState confirmDeploy(
    MatchState s, {
    required int youRoll,
    required int oppRoll,
  }) {
    final deploying = s.youHand
        .where((b) => s.deploySelected.contains(b.id))
        .map((b) => b.deployed())
        .toList();
    final hand = s.youHand.where((b) => !s.deploySelected.contains(b.id)).toList();
    final roost = [...s.youRoost, ...deploying];

    // Bot AI deploys up to 3 of its longest-lived birds from hand.
    final oppDeploy = (s.oppHand.toList()
          ..sort((a, b) => b.endurance.compareTo(a.endurance)))
        .take(MatchRules.deployPerNight)
        .toList();
    final oppDeployIds = oppDeploy.map((b) => b.id).toSet();
    final oppNew = oppDeploy.map((b) => b.deployed()).toList();
    final oppRoost = [...s.oppRoost, ...oppNew];
    final oppHandLeft = s.oppHand.where((b) => !oppDeployIds.contains(b.id)).toList();

    final youTotal = MatchRules.initiativeTotal(
        roll: youRoll, skillMod: s.youMod, roostSize: roost.length);
    final oppTotal = MatchRules.initiativeTotal(
        roll: oppRoll, skillMod: s.oppMod, roostSize: oppRoost.length);
    final youFirst = MatchRules.youActFirst(
      youTotal: youTotal,
      oppTotal: oppTotal,
      youRoostSize: roost.length,
      oppRoostSize: oppRoost.length,
    );
    final first = youFirst ? MatchSide.you : MatchSide.opp;

    return s.copyWith(
      youRoost: roost,
      youHand: hand,
      oppRoost: oppRoost,
      oppHand: oppHandLeft,
      nightStep: 4,
      dawnInit: DawnInit(youTotal: youTotal, oppTotal: oppTotal, first: first),
      firstMover: first,
    );
  }

  /// Night step 4 → next day's First Light.
  static MatchState beginNextDay(MatchState s) => s.copyWith(
        screen: MatchScreen.day,
        day: s.day + 1,
        turn: s.firstMover == MatchSide.you ? MatchTurn.you : MatchTurn.opp,
        nightStep: 0,
        drawnIds: const [],
        deploySelected: const [],
        clearShiftReport: true,
        clearDawnInit: true,
        clearFlash: true,
      );

  /// Moves to the end screen.
  static MatchState toEnd(MatchState s) => s.copyWith(
        screen: MatchScreen.end,
        turn: MatchTurn.lock,
        daysPlayed: s.day,
      );

  // ── helpers ──

  static List<MatchBird> _tap(List<MatchBird> roost, String id) =>
      roost.map((b) => b.id == id ? b.copyWith(tapped: true) : b).toList();

  static ({List<MatchBird> survivors, List<MatchBird> fell, List<ShiftEntry> report})
      _shift(List<MatchBird> roost) {
    final survivors = <MatchBird>[];
    final fell = <MatchBird>[];
    final report = <ShiftEntry>[];
    for (final b in roost) {
      final nd = b.daysLeft - 1;
      if (nd <= 0) {
        fell.add(b.copyWith(reason: 'exhausted'));
        report.add(ShiftEntry(name: b.name, deltaText: '${b.daysLeft}d → off', fell: true));
      } else {
        survivors.add(b.copyWith(daysLeft: nd, tapped: false));
        report.add(ShiftEntry(name: b.name, deltaText: '${b.daysLeft}d → ${nd}d', fell: false));
      }
    }
    return (survivors: survivors, fell: fell, report: report);
  }
}
