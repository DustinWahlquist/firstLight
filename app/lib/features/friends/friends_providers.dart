import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/friendship.dart';

final friendsProvider = FutureProvider<List<Friendship>>((ref) =>
    ref.watch(friendsRepositoryProvider).fetchFriends());

final pendingFriendsProvider = FutureProvider<List<Friendship>>((ref) =>
    ref.watch(friendsRepositoryProvider).fetchPendingIncoming());

final friendCountProvider = FutureProvider<int>((ref) =>
    ref.watch(friendsRepositoryProvider).fetchFriendCount());
