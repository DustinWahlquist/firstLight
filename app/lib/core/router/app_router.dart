import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/aviary/aviary_screen.dart';
import '../../features/aviary/bird_detail_screen.dart';
import '../../features/card_reveal/card_reveal_screen.dart';
import '../../features/level_up/level_up_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../models/bird_card.dart';
import '../shell/app_shell.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<AuthState> stream) {
    _subscription = stream.listen((authState) {
      _lastEvent = authState.event;
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;
  AuthChangeEvent? _lastEvent;

  bool get isPasswordRecovery => _lastEvent == AuthChangeEvent.passwordRecovery;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRefreshNotifier(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      final loc = state.matchedLocation;
      final isOnLogin = loc == '/login';
      final isOnReset = loc == '/reset-password';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && notifier.isPasswordRecovery && !isOnReset) return '/reset-password';
      if (isLoggedIn && isOnLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const AviaryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/bird-detail',
        builder: (context, state) => BirdDetailScreen(card: state.extra as BirdCard),
      ),
      GoRoute(
        path: '/card-reveal',
        builder: (context, state) => CardRevealScreen(card: state.extra as BirdCard),
      ),
      GoRoute(
        path: '/level-up',
        builder: (context, state) {
          final args = state.extra as ({BirdCard oldCard, BirdCard newCard});
          return LevelUpScreen(oldCard: args.oldCard, newCard: args.newCard);
        },
      ),
    ],
  );
});
