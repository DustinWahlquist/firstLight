import 'package:supabase_flutter/supabase_flutter.dart';

/// Fire-and-forget usage analytics. Events must never disrupt the app —
/// failures are swallowed.
class UsageEventsRepository {
  UsageEventsRepository(this._client);

  final SupabaseClient _client;

  Future<void> log(String event, [String? value]) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('usage_events').insert({
        'user_id': userId,
        'event': event,
        'value': value,
      });
    } catch (_) {
      // ignore
    }
  }
}
