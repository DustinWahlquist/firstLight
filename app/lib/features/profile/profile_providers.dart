import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../models/user_profile.dart';

final myProfileProvider = FutureProvider<UserProfile?>((ref) =>
    ref.watch(profileRepositoryProvider).fetchMyProfile());
