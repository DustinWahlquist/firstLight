import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
