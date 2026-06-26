import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feed_event.dart';
import '../models/scribble.dart';
import 'profile_repository.dart';

/// The social context: feed events, pecks, and scribbles.
class SocialRepository {
  SocialRepository(this._client, this._profiles);

  final SupabaseClient _client;
  final ProfileRepository _profiles;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<FeedEvent>> fetchFeed() async {
    // Own + friends' activity (RLS scopes it), so you can see pecks and
    // scribbles on your own catches too.
    final rows = await _client
        .from('feed_events')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    if (rows.isEmpty) return [];
    final userIds = rows.map((r) => r['user_id'] as String).toSet().toList();
    final profileMap = await _profiles.fetchProfileMap(userIds);
    final ids = rows.map((r) => r['id'] as String).toList();
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
    return rows.map((r) {
      final eventId = r['id'] as String;
      final map = Map<String, dynamic>.from(r)
        ..['profiles'] = profileMap[r['user_id'] as String]?.toJson();
      return FeedEvent.fromJson(map).copyWith(
        peckCount: countMap[eventId] ?? 0,
        hasPecked: peckedSet.contains(eventId),
      );
    }).toList();
  }

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

  Future<List<Scribble>> fetchScribbles(String feedEventId) async {
    final rows = await _client
        .from('scribbles')
        .select()
        .eq('feed_event_id', feedEventId)
        .order('created_at', ascending: true);
    if (rows.isEmpty) return [];
    final userIds = rows.map((r) => r['user_id'] as String).toSet().toList();
    final profileMap = await _profiles.fetchProfileMap(userIds);
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r)
        ..['profiles'] = profileMap[r['user_id'] as String]?.toJson();
      return Scribble.fromJson(map);
    }).toList();
  }

  Future<Scribble> addScribble(String feedEventId, String text) async {
    final row = await _client
        .from('scribbles')
        .insert({'user_id': _userId, 'feed_event_id': feedEventId, 'text': text})
        .select()
        .single();
    final profile = await _profiles.fetchProfile(_userId);
    final map = Map<String, dynamic>.from(row)..['profiles'] = profile?.toJson();
    return Scribble.fromJson(map);
  }

  Future<void> deleteScribble(String scribbleId) async {
    await _client.from('scribbles').delete().eq('id', scribbleId);
  }
}
