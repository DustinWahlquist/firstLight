import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/match/match_seed.dart';
import '../domain/match/match_state.dart';

/// A row in the Active Games list — enough to render without loading the
/// full match state.
class MatchSummary {
  const MatchSummary({
    required this.id,
    required this.mode,
    required this.otherName,
    required this.otherAvatarUrl,
    required this.status,
    required this.turn,
    required this.winner,
    required this.day,
    required this.creatorKm,
    required this.updatedAt,
    required this.isIncomingInvite,
    required this.isOutgoingInvite,
  });

  final String id;
  final String mode; // 'bot' | 'friend'
  final String otherName; // the other participant, from the viewer's side
  final String? otherAvatarUrl;
  final String status; // 'pending' | 'active' | 'complete'
  final String turn; // 'you' | 'opp' | 'lock' (creator perspective)
  final String? winner;
  final int day;
  final int creatorKm; // youKm from the stored (creator) perspective
  final DateTime updatedAt;

  /// A friend challenge sent to me, awaiting my accept.
  final bool isIncomingInvite;

  /// A friend challenge I sent, awaiting their accept.
  final bool isOutgoingInvite;

  bool get isPending => status == 'pending';
  bool get isComplete => status == 'complete';
  bool get isBot => mode == 'bot';

  factory MatchSummary.fromRow(Map<String, dynamic> r, String me) {
    final state = Map<String, dynamic>.from(r['state'] as Map);
    final playerId = r['player_id'] as String;
    final opponentId = r['opponent_id'] as String?;
    final iAmCreator = playerId == me;
    final status = r['status'] as String? ?? 'active';

    final otherName = iAmCreator
        ? (r['opponent_name'] as String? ?? 'Mara')
        : (r['challenger_name'] as String? ?? 'Watcher');

    return MatchSummary(
      id: r['id'] as String,
      mode: r['mode'] as String? ?? 'bot',
      otherName: otherName,
      otherAvatarUrl: r['opponent_avatar_url'] as String?,
      status: status,
      turn: r['turn'] as String? ?? 'you',
      winner: r['winner'] as String?,
      day: state['day'] as int? ?? 1,
      creatorKm: state['youKm'] as int? ?? 0,
      updatedAt: DateTime.parse(r['updated_at'] as String),
      isIncomingInvite: status == 'pending' && opponentId == me,
      isOutgoingInvite: status == 'pending' && iAmCreator,
    );
  }
}

/// Persistence for matches. Loaded states are cached so the match
/// controller can seed itself synchronously after an async open.
class MatchRepository {
  MatchRepository(this._client);

  final SupabaseClient _client;
  final _cache = <String, MatchState>{}; // canonical (player1/creator) state
  final _meta = <String, ({String mode, bool amOpponent})>{};

  String get _userId => _client.auth.currentUser!.id;

  MatchState? cachedState(String id) => _cache[id];
  ({String mode, bool amOpponent})? metaOf(String id) => _meta[id];

  /// Creates a fresh bot match, caches its state, and returns its id.
  Future<String> startBotMatch() async {
    final state = seedPracticeMatch();
    final row = await _client
        .from('matches')
        .insert({
          'player_id': _userId,
          'mode': 'bot',
          'opponent_name': 'Mara',
          'status': 'active',
          'turn': state.turn.name,
          'state': state.toJson(),
        })
        .select('id')
        .single();
    final id = row['id'] as String;
    _cache[id] = state;
    _meta[id] = (mode: 'bot', amOpponent: false);
    return id;
  }

  /// Challenges a friend: creates a pending friend match. [challengerName] is
  /// the current user's display name (shown to the opponent).
  Future<void> challengeFriend({
    required String opponentId,
    required String opponentName,
    String? opponentAvatarUrl,
    required String challengerName,
  }) async {
    // Friend matches skip the local initiative screen (it can't be driven by
    // both players) and open on the day, challenger to move first.
    final state = seedPracticeMatch().copyWith(
      screen: MatchScreen.day,
      turn: MatchTurn.you,
      initRolled: true,
      firstMover: MatchSide.you,
    );
    await _client.from('matches').insert({
      'player_id': _userId,
      'opponent_id': opponentId,
      'mode': 'friend',
      'opponent_name': opponentName,
      'opponent_avatar_url': opponentAvatarUrl,
      'challenger_name': challengerName,
      'status': 'pending',
      'turn': state.turn.name,
      'state': state.toJson(),
    });
  }

  Future<void> acceptChallenge(String id) =>
      _client.from('matches').update({'status': 'active'}).eq('id', id);

  Future<void> declineChallenge(String id) =>
      _client.from('matches').delete().eq('id', id);

  /// Loads a match into the cache (canonical state + my perspective);
  /// returns its id (for navigation).
  Future<String> openMatch(String id) async {
    final row = await _client
        .from('matches')
        .select('state, mode, player_id, opponent_id')
        .eq('id', id)
        .single();
    _cache[id] = MatchState.fromJson(Map<String, dynamic>.from(row['state'] as Map));
    _meta[id] = (
      mode: row['mode'] as String? ?? 'bot',
      amOpponent: (row['opponent_id'] as String?) == _userId,
    );
    return id;
  }

  /// The latest canonical state straight from the row (for realtime apply).
  MatchState parseState(Map<String, dynamic> row) =>
      MatchState.fromJson(Map<String, dynamic>.from(row['state'] as Map));

  /// Persists the latest state and the denormalized list columns.
  Future<void> saveMatch(String id, MatchState state) async {
    _cache[id] = state;
    try {
      await _client.from('matches').update({
        'state': state.toJson(),
        'turn': state.turn.name,
        'status': state.screen == MatchScreen.end ? 'complete' : 'active',
        'winner': state.winner?.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (_) {
      // Best-effort autosave; the local state stays authoritative in-session.
    }
  }

  Future<List<MatchSummary>> listMatches() async {
    final rows = await _client
        .from('matches')
        .select('id, player_id, opponent_id, mode, opponent_name, '
            'opponent_avatar_url, challenger_name, status, turn, winner, state, updated_at')
        .or('player_id.eq.$_userId,opponent_id.eq.$_userId')
        .order('updated_at', ascending: false);
    final me = _userId;
    final all = rows.map((r) => MatchSummary.fromRow(r, me)).toList();
    // Incoming invites first, then active, then complete.
    int rank(MatchSummary m) => m.isIncomingInvite ? 0 : m.isComplete ? 2 : 1;
    all.sort((a, b) => rank(a).compareTo(rank(b)));
    return all;
  }

  Future<void> deleteMatch(String id) async {
    _cache.remove(id);
    await _client.from('matches').delete().eq('id', id);
  }
}
