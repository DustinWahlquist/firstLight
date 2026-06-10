import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  Future<UserProfile?> fetchMyProfile() => fetchProfile(_userId);

  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row != null ? UserProfile.fromJson(row) : null;
  }

  Future<Map<String, UserProfile>> fetchProfileMap(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _client.from('profiles').select().inFilter('id', ids);
    return {for (final r in rows) r['id'] as String: UserProfile.fromJson(r)};
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

  Future<String> uploadAvatar(File file) async {
    final path = '$_userId/avatar.jpg';
    await _client.storage.from('screenshots').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    return _client.storage.from('screenshots').getPublicUrl(path);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> deleteAccount() async {
    await _client.rpc('delete_user');
  }
}
