import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bird_card.dart';
import '../models/catch_log.dart';
import '../models/parse_result.dart';

class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<BirdCard>> fetchAviary() async {
    final rows = await _client
        .from('bird_cards')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(BirdCard.fromJson).toList();
  }

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

  Future<bool> hasCaughtToday(String birdCardId) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
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

  Future<BirdCard> createCard(ParseResult result, String screenshotUrl) async {
    final row = await _client
        .from('bird_cards')
        .insert({
          'user_id': _userId,
          'species_name': result.speciesName,
          'scientific_name': result.scientificName,
          'rarity': result.rarity.label,
          'level': 1,
          'xp': 0,
          'catch_count': 1,
          'first_catch_date': result.date.toIso8601String(),
          'first_catch_location': result.location,
          'first_catch_latitude': result.latitude,
          'first_catch_longitude': result.longitude,
          'description': result.description,
          'facts': result.facts,
          'migration_speed': result.migrationSpeed,
          'endurance': result.endurance,
          'screenshot_url': screenshotUrl,
          'line_art_url': result.lineArtUrl,
        })
        .select()
        .single();
    await _logCatch(
      birdCardId: row['id'] as String,
      screenshotUrl: screenshotUrl,
      sightingRarity: result.sightingRarity,
      location: result.location,
      latitude: result.latitude,
      longitude: result.longitude,
      xpAwarded: 0,
    );
    return BirdCard.fromJson(row);
  }

  Future<BirdCard> awardXp(BirdCard card, ParseResult result, String screenshotUrl) async {
    final xpToAdd = result.rarity.xpPerCatch;
    final newXp = card.xp + xpToAdd;
    final newLevel = BirdCard.levelForXp(newXp);
    final row = await _client
        .from('bird_cards')
        .update({
          'xp': newXp,
          'level': newLevel,
          'catch_count': card.catchCount + 1,
        })
        .eq('id', card.id)
        .select()
        .single();
    await _logCatch(
      birdCardId: card.id,
      screenshotUrl: screenshotUrl,
      sightingRarity: result.sightingRarity,
      location: result.location,
      latitude: result.latitude,
      longitude: result.longitude,
      xpAwarded: xpToAdd,
    );
    return BirdCard.fromJson(row);
  }

  Future<void> _logCatch({
    required String birdCardId,
    required String screenshotUrl,
    required String sightingRarity,
    required String location,
    required int xpAwarded,
    double? latitude,
    double? longitude,
  }) async {
    await _client.from('catch_logs').insert({
      'user_id': _userId,
      'bird_card_id': birdCardId,
      'caught_at': DateTime.now().toIso8601String(),
      'screenshot_url': screenshotUrl,
      'sighting_rarity': sightingRarity,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'xp_awarded': xpAwarded,
    });
  }

  Future<String> uploadScreenshot(File file) async {
    final path = '$_userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('screenshots').upload(path, file);
    return _client.storage.from('screenshots').getPublicUrl(path);
  }

  Future<List<CatchLog>> fetchCatchLogs(String birdCardId) async {
    final rows = await _client
        .from('catch_logs')
        .select()
        .eq('bird_card_id', birdCardId)
        .order('caught_at', ascending: false);
    return rows.map(CatchLog.fromJson).toList();
  }

  Future<String> uploadAvatar(File file) async {
    final path = '$_userId/avatar.jpg';
    await _client.storage.from('screenshots').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    return _client.storage.from('screenshots').getPublicUrl(path);
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['display_name'] = displayName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (data.isEmpty) return;
    await _client.auth.updateUser(UserAttributes(data: data));
  }

  Future<String?> fetchSpeciesLineArt(String speciesName) async {
    final row = await _client
        .from('bird_species')
        .select('line_art_url')
        .eq('species_name', speciesName)
        .maybeSingle();
    return row?['line_art_url'] as String?;
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> deleteAccount() async {
    await _client.rpc('delete_user');
  }
}
