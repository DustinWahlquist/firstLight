import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feed_event.dart';
import '../models/friendship.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import '../services/vision_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authStateProvider = StreamProvider<AuthState>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange,
);

final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(ref.watch(supabaseClientProvider)),
);

final visionServiceProvider = Provider<VisionService>(
  (ref) => VisionService(ref.watch(supabaseClientProvider)),
);

final myProfileProvider = FutureProvider<UserProfile?>((ref) =>
    ref.watch(supabaseServiceProvider).fetchMyProfile());

final feedProvider = FutureProvider<List<FeedEvent>>((ref) =>
    ref.watch(supabaseServiceProvider).fetchFeed());

final friendsProvider = FutureProvider<List<Friendship>>((ref) =>
    ref.watch(supabaseServiceProvider).fetchFriends());

final pendingFriendsProvider = FutureProvider<List<Friendship>>((ref) =>
    ref.watch(supabaseServiceProvider).fetchPendingIncoming());

final friendCountProvider = FutureProvider<int>((ref) =>
    ref.watch(supabaseServiceProvider).fetchFriendCount());
