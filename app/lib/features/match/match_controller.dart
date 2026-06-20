import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';
import '../../domain/match/match_engine.dart';
import '../../domain/match/match_seed.dart';
import '../../domain/match/match_state.dart';

/// The match the controller should load. Set by the entry flow (Play a bot /
/// resume / accept) right before navigating to the match.
final activeMatchIdProvider = StateProvider<String?>((ref) => null);

/// Drives an active match. For bot matches it runs the opponent AI on timers;
/// for friend matches it submits only the local player's moves and applies the
/// opponent's from a realtime subscription — strictly turn-based and
/// server-persisted (async), feeling live only when both happen to be online.
final matchControllerProvider =
    NotifierProvider.autoDispose<MatchController, MatchState>(MatchController.new);

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
  String? _matchId;
  String _mode = 'bot';
  bool _amOpponent = false; // friend match where I'm the challenged player
  RealtimeChannel? _channel;
  String? _lastSavedJson; // ignore my own realtime echo

  bool get isFriend => _mode == 'friend';
  bool get isMyTurn => state.turn == MatchTurn.you;

  @override
  MatchState build() {
    ref.onDispose(_teardown);
    final id = ref.read(activeMatchIdProvider);
    _matchId = id;
    if (id == null) return seedPracticeMatch();

    final meta = ref.read(matchRepositoryProvider).metaOf(id);
    _mode = meta?.mode ?? 'bot';
    _amOpponent = meta?.amOpponent ?? false;
    final canonical = ref.read(matchRepositoryProvider).cachedState(id) ?? seedPracticeMatch();
    if (isFriend) _subscribe(id);
    return _toLocal(canonical);
  }

  int _d20() => 1 + _rng.nextInt(20);

  // ── Perspective ──
  MatchState _toLocal(MatchState canonical) => _amOpponent ? canonical.flip() : canonical;
  MatchState _toCanonical(MatchState local) => _amOpponent ? local.flip() : local;

  // ── Persistence ──
  void _emit(MatchState local) {
    state = local;
    if (_matchId == null) return;
    final canonical = _toCanonical(local);
    final json = jsonEncode(canonical.toJson());
    _lastSavedJson = json;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () {
      ref.read(matchRepositoryProvider).saveMatch(_matchId!, canonical);
    });
  }

  // ── Realtime (friend matches) ──
  void _subscribe(String id) {
    _channel = Supabase.instance.client
        .channel('match-$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: id,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            final canonical = ref.read(matchRepositoryProvider).parseState(row);
            // Ignore the echo of my own write.
            if (jsonEncode(canonical.toJson()) == _lastSavedJson) return;
            state = _toLocal(canonical);
          },
        )
        .subscribe();
  }

  // ── Initiative ──
  void rollInitiative() =>
      _emit(MatchEngine.rollInitiative(state, youRoll: _d20(), oppRoll: _d20()));

  void beginFirstLight() {
    _emit(MatchEngine.beginFirstLight(state));
    if (!isFriend && state.turn == MatchTurn.opp) _schedule(_dawnOppDelay, _opponentFly);
  }

  // ── Day ──
  void flyBird(String birdId) {
    if (state.turn != MatchTurn.you || state.screen != MatchScreen.day) return;
    final next = MatchEngine.fly(state, birdId);
    if (isFriend) {
      if (next.winner != null) {
        _emit(MatchEngine.toEnd(next));
      } else if (next.dayOver) {
        _emit(MatchEngine.enterNightFriend(next));
      } else {
        _emit(next); // turn passed to opponent — wait
      }
    } else {
      _emit(next);
      _react(oppJustActed: false);
    }
  }

  void _opponentFly() {
    if (state.screen != MatchScreen.day) return;
    _emit(MatchEngine.opponentFly(state));
    _react(oppJustActed: true);
  }

  /// Bot-only: schedule the next beat after an activation.
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
    if (isFriend) {
      switch (state.nightStep) {
        case 0:
          _emit(state.copyWith(nightStep: 1)); // shift already applied on entry
        case 1:
          _emit(MatchEngine.friendDraw(state));
        case 2:
          _emit(MatchEngine.openDeploy(state));
        case 3:
          _emit(MatchEngine.friendConfirmDeploy(state, youRoll: _d20(), oppRoll: _d20()));
      }
      return;
    }
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
  void restart() {
    if (isFriend) return; // rematch is a fresh challenge, handled elsewhere
    _cancelTimers();
    _emit(seedPracticeMatch());
  }

  // ── Plumbing ──
  void _schedule(Duration d, void Function() action) => _timers.add(Timer(d, action));

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _saveTimer?.cancel();
  }

  void _teardown() {
    _cancelTimers();
    if (_channel != null) Supabase.instance.client.removeChannel(_channel!);
  }
}
