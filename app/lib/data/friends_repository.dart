import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friendship.dart';
import 'profile_repository.dart';

class FriendsRepository {
  FriendsRepository(this._client, this._profiles);

  final SupabaseClient _client;
  final ProfileRepository _profiles;

  String get _userId => _client.auth.currentUser!.id;

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

  Future<List<Friendship>> fetchFriends() => fetchFriendListFor(_userId);

  Future<List<Friendship>> fetchFriendListFor(String userId) async {
    final rows = await _client
        .from('friendships')
        .select()
        .or('requester_id.eq.$userId,addressee_id.eq.$userId')
        .eq('status', 'accepted');
    return _attachProfiles(rows, userId);
  }

  Future<List<Friendship>> fetchPendingIncoming() async {
    final rows = await _client
        .from('friendships')
        .select()
        .eq('addressee_id', _userId)
        .eq('status', 'pending');
    return _attachProfiles(rows, _userId);
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

  /// Resolves the "other side" of each friendship row to a profile.
  Future<List<Friendship>> _attachProfiles(
    List<Map<String, dynamic>> rows,
    String ownerId,
  ) async {
    if (rows.isEmpty) return [];
    String otherId(Map<String, dynamic> r) {
      final rid = r['requester_id'] as String;
      return rid == ownerId ? r['addressee_id'] as String : rid;
    }

    final profileMap =
        await _profiles.fetchProfileMap(rows.map(otherId).toSet().toList());
    return rows.map((r) {
      final map = Map<String, dynamic>.from(r)
        ..['profiles'] = profileMap[otherId(r)]?.toJson();
      return Friendship.fromJson(map);
    }).toList();
  }
}
