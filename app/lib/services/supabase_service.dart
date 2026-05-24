import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bird_card.dart';
import '../models/catch_log.dart';
import '../models/feed_event.dart';
import '../models/friendship.dart';
import '../models/parse_result.dart';
import '../models/scribble.dart';
import '../models/user_profile.dart';

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

  Future<List<BirdCard>> fetchAviaryFor(String userId) async {
    final rows = await _client
        .from('bird_cards')
        .select()
        .eq('user_id', userId)
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
          'last_caught_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    final card = BirdCard.fromJson(row);
    await Future.wait([
      _logCatch(
        birdCardId: card.id,
        screenshotUrl: screenshotUrl,
        sightingRarity: result.sightingRarity,
        location: result.location,
        latitude: result.latitude,
        longitude: result.longitude,
        xpAwarded: 0,
      ),
      _emitFeedEvent({
        'user_id': _userId,
        'type': 'new_lifer',
        'bird_card_id': card.id,
        'species_name': result.speciesName,
        'line_art_url': result.lineArtUrl,
        'sighting_rarity': result.sightingRarity,
      }),
    ]);
    await _checkMilestone();
    return card;
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
          'last_caught_at': DateTime.now().toIso8601String(),
        })
        .eq('id', card.id)
        .select()
        .single();
    final updated = BirdCard.fromJson(row);
    final events = <Map<String, dynamic>>[
      {
        'user_id': _userId,
        'type': 'catch',
        'bird_card_id': card.id,
        'species_name': card.speciesName,
        'line_art_url': card.lineArtUrl,
        'xp_awarded': xpToAdd,
        'sighting_rarity': result.sightingRarity,
      },
    ];
    if (updated.level > card.level) {
      events.add({
        'user_id': _userId,
        'type': 'level_up',
        'bird_card_id': card.id,
        'species_name': card.speciesName,
        'line_art_url': card.lineArtUrl,
        'level': updated.level,
      });
    }
    await Future.wait([
      _logCatch(
        birdCardId: card.id,
        screenshotUrl: screenshotUrl,
        sightingRarity: result.sightingRarity,
        location: result.location,
        latitude: result.latitude,
        longitude: result.longitude,
        xpAwarded: xpToAdd,
      ),
      ...events.map(_emitFeedEvent),
    ]);
    return updated;
  }

  Future<void> _emitFeedEvent(Map<String, dynamic> data) async {
    try {
      await _client.from('feed_events').insert(data);
    } catch (_) {
      // Feed events are best-effort; don't fail the main operation
    }
  }

  static const _milestoneCounts = [10, 25, 50, 100, 250, 500];

  Future<void> _checkMilestone() async {
    final rows = await _client
        .from('bird_cards')
        .select('id')
        .eq('user_id', _userId);
    final count = rows.length;
    if (!_milestoneCounts.contains(count)) return;
    await _emitFeedEvent({
      'user_id': _userId,
      'type': 'milestone',
      'milestone_value': count,
      'milestone_type': 'lifers',
    });
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

  Future<void> updateProfile({String? displayName, String? avatarUrl}) =>
      upsertProfile(displayName: displayName, avatarUrl: avatarUrl);

  Future<String?> fetchSpeciesLineArt(String speciesName) async {
    final row = await _client
        .from('bird_species')
        .select('line_art_url')
        .eq('species_name', speciesName)
        .maybeSingle();
    return row?['line_art_url'] as String?;
  }

  // ── Profiles ──────────────────────────────────────────────────────

  Future<UserProfile?> fetchMyProfile() async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', _userId)
        .maybeSingle();
    return row != null ? UserProfile.fromJson(row) : null;
  }

  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row != null ? UserProfile.fromJson(row) : null;
  }

  Future<void> upsertProfile({String? displayName, String? avatarUrl, bool? isPublic}) async {
    final data = <String, dynamic>{'id': _userId};
    if (displayName != null) data['display_name'] = displayName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (isPublic != null) data['is_public'] = isPublic;
    await _client.from('profiles').upsert(data);
    // Keep auth metadata in sync
    final authData = <String, dynamic>{};
    if (displayName != null) authData['display_name'] = displayName;
    if (avatarUrl != null) authData['avatar_url'] = avatarUrl;
    if (authData.isNotEmpty) await _client.auth.updateUser(UserAttributes(data: authData));
  }

  Future<List<UserProfile>> searchProfiles(String query) async {
    final rows = await _client
        .from('profiles')
        .select()
        .or('display_name.ilike.%$query%,username.ilike.%$query%')
        .neq('id', _userId)
        .limit(20);
    return rows.map(UserProfile.fromJson).toList();
  }

  // ── Friends ───────────────────────────────────────────────────────

  Future<Friendship> sendFriendRequest(String addresseeId) async {
    final row = await _client
        .from('friendships')
        .insert({
          'requester_id': _userId,
          'addressee_id': addresseeId,
          'status': 'pending',
        })
        .select()
        .single();
    return Friendship.fromJson(row);
  }

  Future<Friendship> acceptFriendRequest(String friendshipId) async {
    final row = await _client
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', friendshipId)
        .select()
        .single();
    return Friendship.fromJson(row);
  }

  Future<void> declineFriendRequest(String friendshipId) async {
    await _client
        .from('friendships')
        .update({'status': 'declined'})
        .eq('id', friendshipId);
  }

  Future<void> removeFriend(String friendshipId) async {
    await _client.from('friendships').delete().eq('id', friendshipId);
  }

  Future<List<Friendship>> fetchFriends() async {
    final rows = await _client
        .from('friendships')
        .select('*, profiles!friendships_requester_id_fkey(*), profiles!friendships_addressee_id_fkey(*)')
        .or('requester_id.eq.$_userId,addressee_id.eq.$_userId')
        .eq('status', 'accepted');
    return rows.map((row) => _friendshipWithOtherProfile(row)).toList();
  }

  Future<List<Friendship>> fetchPendingIncoming() async {
    final rows = await _client
        .from('friendships')
        .select('*, profiles!friendships_requester_id_fkey(*)')
        .eq('addressee_id', _userId)
        .eq('status', 'pending');
    return rows.map((row) {
      final profileJson = row['profiles!friendships_requester_id_fkey'] as Map<String, dynamic>?;
      final map = Map<String, dynamic>.from(row)
        ..['profiles'] = profileJson;
      return Friendship.fromJson(map);
    }).toList();
  }

  Future<Friendship?> fetchFriendshipWith(String userId) async {
    final rows = await _client
        .from('friendships')
        .select()
        .or('and(requester_id.eq.$_userId,addressee_id.eq.$userId),and(requester_id.eq.$userId,addressee_id.eq.$_userId)')
        .limit(1);
    if (rows.isEmpty) return null;
    return Friendship.fromJson(rows.first);
  }

  Future<int> fetchFriendCount() async {
    final rows = await _client
        .from('friendships')
        .select('id')
        .or('requester_id.eq.$_userId,addressee_id.eq.$_userId')
        .eq('status', 'accepted');
    return rows.length;
  }

  Future<List<Friendship>> fetchFriendListFor(String userId) async {
    final rows = await _client
        .from('friendships')
        .select('*, profiles!friendships_requester_id_fkey(*), profiles!friendships_addressee_id_fkey(*)')
        .or('requester_id.eq.$userId,addressee_id.eq.$userId')
        .eq('status', 'accepted');
    return rows.map((row) => _friendshipWithOtherProfileFor(row, userId)).toList();
  }

  Friendship _friendshipWithOtherProfile(Map<String, dynamic> row) {
    final isRequester = row['requester_id'] as String == _userId;
    final key = isRequester
        ? 'profiles!friendships_addressee_id_fkey'
        : 'profiles!friendships_requester_id_fkey';
    final profileJson = row[key] as Map<String, dynamic>?;
    final map = Map<String, dynamic>.from(row)..['profiles'] = profileJson;
    return Friendship.fromJson(map);
  }

  Friendship _friendshipWithOtherProfileFor(Map<String, dynamic> row, String ownerId) {
    final isRequester = row['requester_id'] as String == ownerId;
    final key = isRequester
        ? 'profiles!friendships_addressee_id_fkey'
        : 'profiles!friendships_requester_id_fkey';
    final profileJson = row[key] as Map<String, dynamic>?;
    final map = Map<String, dynamic>.from(row)..['profiles'] = profileJson;
    return Friendship.fromJson(map);
  }

  // ── Feed ──────────────────────────────────────────────────────────

  Future<List<FeedEvent>> fetchFeed() async {
    final rows = await _client
        .from('feed_events')
        .select('*, profiles(*)')
        .neq('user_id', _userId)
        .order('created_at', ascending: false)
        .limit(50);
    final events = rows.map(FeedEvent.fromJson).toList();
    if (events.isEmpty) return events;
    // Batch-fetch peck counts and whether current user has pecked
    final ids = events.map((e) => e.id).toList();
    final peckRows = await _client
        .from('pecks')
        .select('feed_event_id, user_id')
        .inFilter('feed_event_id', ids);
    final countMap = <String, int>{};
    final peckedSet = <String>{};
    for (final p in peckRows) {
      final fid = p['feed_event_id'] as String;
      countMap[fid] = (countMap[fid] ?? 0) + 1;
      if (p['user_id'] as String == _userId) peckedSet.add(fid);
    }
    return events.map((e) => e.copyWith(
      peckCount: countMap[e.id] ?? 0,
      hasPecked: peckedSet.contains(e.id),
    )).toList();
  }

  // ── Pecks ─────────────────────────────────────────────────────────

  Future<void> addPeck(String feedEventId) async {
    await _client.from('pecks').insert({
      'user_id': _userId,
      'feed_event_id': feedEventId,
    });
  }

  Future<void> removePeck(String feedEventId) async {
    await _client
        .from('pecks')
        .delete()
        .eq('user_id', _userId)
        .eq('feed_event_id', feedEventId);
  }

  // ── Scribbles ─────────────────────────────────────────────────────

  Future<List<Scribble>> fetchScribbles(String feedEventId) async {
    final rows = await _client
        .from('scribbles')
        .select('*, profiles(*)')
        .eq('feed_event_id', feedEventId)
        .order('created_at', ascending: true);
    return rows.map(Scribble.fromJson).toList();
  }

  Future<Scribble> addScribble(String feedEventId, String text) async {
    final row = await _client
        .from('scribbles')
        .insert({
          'user_id': _userId,
          'feed_event_id': feedEventId,
          'text': text,
        })
        .select('*, profiles(*)')
        .single();
    return Scribble.fromJson(row);
  }

  Future<void> deleteScribble(String scribbleId) async {
    await _client.from('scribbles').delete().eq('id', scribbleId);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> deleteAccount() async {
    await _client.rpc('delete_user');
  }
}
