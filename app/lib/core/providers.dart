import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/aviary_repository.dart';
import '../data/friends_repository.dart';
import '../data/geocoding_service.dart';
import '../data/profile_repository.dart';
import '../data/social_repository.dart';
import '../data/vision_service.dart';
import '../domain/log_catch_use_case.dart';

/// Infrastructure wiring only. Feature-level state providers live in their
/// feature folders (e.g. features/aviary/aviary_providers.dart).

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authStateProvider = StreamProvider<AuthState>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange,
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

final aviaryRepositoryProvider = Provider<AviaryRepository>(
  (ref) => AviaryRepository(ref.watch(supabaseClientProvider)),
);

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(profileRepositoryProvider),
  ),
);

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FriendsRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(profileRepositoryProvider),
  ),
);

final visionServiceProvider = Provider<VisionService>(
  (ref) => VisionService(ref.watch(supabaseClientProvider)),
);

final geocodingServiceProvider = Provider<GeocodingService>(
  (ref) => GeocodingService(),
);

final logCatchUseCaseProvider = Provider<LogCatchUseCase>(
  (ref) => LogCatchUseCase(aviary: ref.watch(aviaryRepositoryProvider)),
);
