import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/match/match_engine.dart';
import '../../domain/match/match_seed.dart';
import '../../domain/match/match_state.dart';

/// The match the controller should load. Set by the entry flow (Play a bot /
/// resume from the Active Games list) right before navigating to the match.
final activeMatchIdProvider = StateProvider<String?>((ref) => null);

/// Drives an active match: holds the logical [MatchState], orchestrates the
/// timed beats the pure engine doesn't (opponent AI cadence, the pause before
/// Night, the win delay), and autosaves to Supabase after each change.
final matchControllerProvider =
    NotifierProvider.autoDispose<MatchController, MatchState>(MatchController.new);

// Beat timing, from the design handoff.
const _oppFirstDelay = Duration(milliseconds: 1100);
const _oppNextDelay = Duration(milliseconds: 1400);
const _dawnOppDelay = Duration(milliseconds: 900);
const _toNightDelay = Duration(milliseconds: 1700);
const _toEndDelay = Duration(milliseconds: 1150);
const _saveDebounce = Duration(milliseconds: 350);

class MatchController extends AutoDisposeNotifier<MatchState> {
  final _rng = Random();
  final _timers = <Timer>[];
  Timer? _saveTimer;
  String? _matchId; // null when running an unpersisted fallback match

  @override
  MatchState build() {
    ref.onDispose(_cancelTimers);
    final id = ref.read(activeMatchIdProvider);
    _matchId = id;
    if (id != null) {
      return ref.read(matchRepositoryProvider).cachedState(id) ?? seedPracticeMatch();
    }
    return seedPracticeMatch();
  }

  int _d20() => 1 + _rng.nextInt(20);

  /// Sets state and schedules a debounced autosave.
  void _emit(MatchState next) {
    state = next;
    if (_matchId == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () {
      ref.read(matchRepositoryProvider).saveMatch(_matchId!, state);
    });
  }

  // ── Initiative ──

  void rollInitiative() =>
      _emit(MatchEngine.rollInitiative(state, youRoll: _d20(), oppRoll: _d20()));

  void beginFirstLight() {
    _emit(MatchEngine.beginFirstLight(state));
    if (state.turn == MatchTurn.opp) _schedule(_dawnOppDelay, _opponentFly);
  }

  // ── Day ──

  void flyBird(String birdId) {
    if (state.turn != MatchTurn.you || state.screen != MatchScreen.day) return;
    _emit(MatchEngine.fly(state, birdId));
    _react(oppJustActed: false);
  }

  void _opponentFly() {
    if (state.screen != MatchScreen.day) return;
    _emit(MatchEngine.opponentFly(state));
    _react(oppJustActed: true);
  }

  void _react({required bool oppJustActed}) {
    if (state.winner != null) {
      _schedule(_toEndDelay, () => _emit(MatchEngine.toEnd(state)));
    } else if (state.dayOver) {
      _schedule(_toNightDelay, () => _emit(MatchEngine.toNight(state)));
    } else if (state.turn == MatchTurn.opp) {
      _schedule(oppJustActed ? _oppNextDelay : _oppFirstDelay, _opponentFly);
    }
  }

  // ── Night ──

  void nightAdvance() {
    switch (state.nightStep) {
      case 0:
        _emit(MatchEngine.applyShift(state));
      case 1:
        _emit(MatchEngine.applyDraw(state));
      case 2:
        _emit(MatchEngine.openDeploy(state));
      case 3:
        _emit(MatchEngine.confirmDeploy(state, youRoll: _d20(), oppRoll: _d20()));
      case 4:
        _emit(MatchEngine.beginNextDay(state));
        if (state.turn == MatchTurn.opp) _schedule(_dawnOppDelay, _opponentFly);
    }
  }

  void toggleDeploy(String id) => _emit(MatchEngine.toggleDeploy(state, id));

  // ── End ──

  /// Starts a fresh bot match in place (used by Rematch). Persists if this
  /// match is backed by a row.
  void restart() {
    _cancelTimers();
    _emit(seedPracticeMatch());
  }

  // ── Timer plumbing ──

  void _schedule(Duration d, void Function() action) => _timers.add(Timer(d, action));

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _saveTimer?.cancel();
  }
}
