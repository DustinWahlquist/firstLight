import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bird_card.dart';
import '../models/catch_log.dart';
import '../models/parse_result.dart';

/// Persistence for the collection context: bird cards, catch logs,
/// screenshots, and shared species art. Game state is read-only from the
/// client — catches are recorded by the server-side log_catch RPC, which
/// owns XP, levels, and feed events.
class AviaryRepository {
  AviaryRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<BirdCard>> fetchAviary() => fetchAviaryFor(_userId);

  Future<List<BirdCard>> fetchAviaryFor(String userId) async {
    final rows = await _client
        .from('bird_cards')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(BirdCard.fromJson).toList();
  }

  /// The signed-in user's deck — the cards flagged for match play.
  Future<List<BirdCard>> fetchDeck() async {
    final rows = await _client
        .from('bird_cards')
        .select()
        .eq('user_id', _userId)
        .eq('in_deck', true)
        .order('created_at', ascending: false);
    return rows.map(BirdCard.fromJson).toList();
  }

  /// Adds or removes a card from the deck. Routed through a SECURITY DEFINER
  /// RPC because bird_cards has no client UPDATE policy (game state stays
  /// server-authoritative); the function scopes the write to the caller's card.
  Future<void> setInDeck(String cardId, bool inDeck) => _client.rpc(
        'set_card_in_deck',
        params: {'p_card_id': cardId, 'p_in_deck': inDeck},
      );

  Future<BirdCard?> fetchCard(String speciesName) async {
    final rows = await _client
        .from('bird_cards')
        .select()
        .eq('user_id', _userId)
        .eq('species_name', speciesName)
        .limit(1);
    if (rows.isEmpty) return null;
    return BirdCard.fromJson(rows.first);
  }

  /// Client-side fast-fail for the once-per-day rule; the log_catch RPC
  /// re-checks authoritatively.
  Future<bool> hasCaughtOnDate(String birdCardId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final rows = await _client
        .from('catch_logs')
        .select('id')
        .eq('user_id', _userId)
        .eq('bird_card_id', birdCardId)
        .gte('caught_at', start)
        .lte('caught_at', end)
        .limit(1);
    return rows.isNotEmpty;
  }

  /// Records the catch via the server-side log_catch RPC — the single
  /// authority for XP, levels, duplicate rejection, and feed events.
  /// Returns the raw outcome: {kind, card?, previous_level?, xp_awarded?}.
  Future<Map<String, dynamic>> submitCatch({
    required ParseResult parse,
    required String screenshotUrl,
  }) async {
    final result = await _client.rpc('log_catch', params: {
      'p_species_name': parse.speciesName,
      'p_scientific_name': parse.scientificName,
      'p_sighting_rarity': parse.sightingRarity,
      'p_caught_at': parse.date.toIso8601String(),
      'p_location': parse.location,
      'p_latitude': parse.latitude,
      'p_longitude': parse.longitude,
      'p_description': parse.description,
      'p_facts': parse.facts,
      'p_migration_speed': parse.migrationSpeed,
      'p_endurance': parse.endurance,
      'p_screenshot_url': screenshotUrl,
      'p_line_art_url': parse.lineArtUrl,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<CatchLog>> fetchCatchLogs(String birdCardId) async {
    final rows = await _client
        .from('catch_logs')
        .select()
        .eq('bird_card_id', birdCardId)
        .order('caught_at', ascending: false);
    return rows.map(CatchLog.fromJson).toList();
  }

  Future<String?> fetchSpeciesLineArt(String speciesName) async {
    final row = await _client
        .from('bird_species')
        .select('line_art_url')
        .eq('species_name', speciesName)
        .maybeSingle();
    return row?['line_art_url'] as String?;
  }

  Future<String> uploadScreenshot(File file) async {
    final path = '$_userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('screenshots').upload(path, file);
    return _client.storage.from('screenshots').getPublicUrl(path);
  }

  /// Backfills flavor text + art for newly-logged species (bulk "log now,
  /// enrich later"). The edge function generates/caches content and writes it
  /// onto the caller's cards.
  Future<void> enrichSpecies(List<({String speciesName, String scientificName})> species) =>
      _client.functions.invoke('enrich-catches', body: {
        'species': [
          for (final s in species)
            {'species_name': s.speciesName, 'scientific_name': s.scientificName},
        ],
      });
}
