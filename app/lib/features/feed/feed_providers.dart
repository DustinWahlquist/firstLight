import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/feed_event.dart';

final feedProvider = FutureProvider<List<FeedEvent>>((ref) =>
    ref.watch(socialRepositoryProvider).fetchFeed());
