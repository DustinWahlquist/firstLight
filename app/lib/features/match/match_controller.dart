import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/match/match_engine.dart';
import '../../domain/match/match_seed.dart';
import '../../domain/match/match_state.dart';

/// Drives a practice match: holds the logical [MatchState] and orchestrates
/// the timed beats the pure engine doesn't — the opponent AI cadence, the
/// pause before Night, and the win delay. Display-only km animation is the
/// UI's job (it tweens from the previous km to the new one).
final matchControllerProvider =
    NotifierProvider<MatchController, MatchState>(MatchController.new);

// Beat timing, from the design handoff.
const _oppFirstDelay = Duration(milliseconds: 1100);
const _oppNextDelay = Duration(milliseconds: 1400);
const _dawnOppDelay = Duration(milliseconds: 900);
const _toNightDelay = Duration(milliseconds: 1700);
const _toEndDelay = Duration(milliseconds: 1150);

class MatchController extends Notifier<MatchState> {
  final _rng = Random();
  final _timers = <Timer>[];

  @override
  MatchState build() {
    ref.onDispose(_cancelTimers);
    return seedPracticeMatch();
  }

  int _d20() => 1 + _rng.nextInt(20);

  // ── Initiative ──

  void rollInitiative() {
    state = MatchEngine.rollInitiative(state, youRoll: _d20(), oppRoll: _d20());
  }

  void beginFirstLight() {
    state = MatchEngine.beginFirstLight(state);
    if (state.turn == MatchTurn.opp) {
      _schedule(_dawnOppDelay, _opponentFly);
    }
  }

  // ── Day ──

  void flyBird(String birdId) {
    if (state.turn != MatchTurn.you || state.screen != MatchScreen.day) return;
    state = MatchEngine.fly(state, birdId);
    _react(oppJustActed: false);
  }

  void _opponentFly() {
    if (state.screen != MatchScreen.day) return;
    state = MatchEngine.opponentFly(state);
    _react(oppJustActed: true);
  }

  /// Schedules whatever follows an activation: end on a win, Night when the
  /// day is over, or the opponent's next fly. A player turn just waits.
  void _react({required bool oppJustActed}) {
    if (state.winner != null) {
      _schedule(_toEndDelay, () => state = MatchEngine.toEnd(state));
    } else if (state.dayOver) {
      _schedule(_toNightDelay, () => state = MatchEngine.toNight(state));
    } else if (state.turn == MatchTurn.opp) {
      _schedule(oppJustActed ? _oppNextDelay : _oppFirstDelay, _opponentFly);
    }
  }

  // ── Night ──

  void nightAdvance() {
    switch (state.nightStep) {
      case 0:
        state = MatchEngine.applyShift(state);
      case 1:
        state = MatchEngine.applyDraw(state);
      case 2:
        state = MatchEngine.openDeploy(state);
      case 3:
        state = MatchEngine.confirmDeploy(state, youRoll: _d20(), oppRoll: _d20());
      case 4:
        state = MatchEngine.beginNextDay(state);
        if (state.turn == MatchTurn.opp) {
          _schedule(_dawnOppDelay, _opponentFly);
        }
    }
  }

  void toggleDeploy(String id) => state = MatchEngine.toggleDeploy(state, id);

  // ── End ──

  void restart() {
    _cancelTimers();
    state = seedPracticeMatch();
  }

  // ── Timer plumbing ──

  void _schedule(Duration d, void Function() action) {
    _timers.add(Timer(d, action));
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }
}
