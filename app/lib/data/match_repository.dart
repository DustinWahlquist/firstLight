import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/match/match_seed.dart';
import '../domain/match/match_state.dart';

/// A row in the Active Games list — enough to render without loading the
/// full match state.
class MatchSummary {
  const MatchSummary({
    required this.id,
    required this.mode,
    required this.opponentName,
    required this.status,
    required this.turn,
    required this.winner,
    required this.day,
    required this.youKm,
    required this.oppKm,
    required this.updatedAt,
  });

  final String id;
  final String mode; // 'bot' | 'friend'
  final String opponentName;
  final String status; // 'active' | 'complete'
  final String turn; // 'you' | 'opp' | 'lock'
  final String? winner; // 'you' | 'opp' | null
  final int day;
  final int youKm;
  final int oppKm;
  final DateTime updatedAt;

  bool get isYourTurn => status == 'active' && turn == 'you';
  bool get isComplete => status == 'complete';

  factory MatchSummary.fromRow(Map<String, dynamic> r) {
    final state = Map<String, dynamic>.from(r['state'] as Map);
    return MatchSummary(
      id: r['id'] as String,
      mode: r['mode'] as String? ?? 'bot',
      opponentName: r['opponent_name'] as String? ?? 'Mara',
      status: r['status'] as String? ?? 'active',
      turn: r['turn'] as String? ?? 'you',
      winner: r['winner'] as String?,
      day: state['day'] as int? ?? 1,
      youKm: state['youKm'] as int? ?? 0,
      oppKm: state['oppKm'] as int? ?? 0,
      updatedAt: DateTime.parse(r['updated_at'] as String),
    );
  }
}

/// Persistence for matches. Loaded states are cached so the match
/// controller can seed itself synchronously after an async open.
class MatchRepository {
  MatchRepository(this._client);

  final SupabaseClient _client;
  final _cache = <String, MatchState>{};

  String get _userId => _client.auth.currentUser!.id;

  MatchState? cachedState(String id) => _cache[id];

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
    return id;
  }

  /// Loads a match into the cache; returns its id (for navigation).
  Future<String> openMatch(String id) async {
    final row = await _client.from('matches').select('state').eq('id', id).single();
    _cache[id] = MatchState.fromJson(Map<String, dynamic>.from(row['state'] as Map));
    return id;
  }

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
        .select('id, mode, opponent_name, status, turn, winner, state, updated_at')
        .eq('player_id', _userId)
        .order('status', ascending: true) // active before complete
        .order('updated_at', ascending: false);
    return rows.map(MatchSummary.fromRow).toList();
  }

  Future<void> deleteMatch(String id) async {
    _cache.remove(id);
    await _client.from('matches').delete().eq('id', id);
  }
}
