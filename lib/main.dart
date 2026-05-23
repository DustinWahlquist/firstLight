import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/aviary_card.dart';
import 'screens/aviary_screen.dart';
import 'screens/card_reveal_screen.dart';
import 'screens/import_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  runApp(const MurmurationApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const AviaryScreen()),
    GoRoute(path: '/import', builder: (_, __) => const ImportScreen()),
    GoRoute(
      path: '/reveal',
      builder: (_, state) =>
          CardRevealScreen(card: state.extra! as AviaryCard),
    ),
  ],
);

class MurmurationApp extends StatelessWidget {
  const MurmurationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'First Light',
      routerConfig: _router,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A7C59),
          brightness: Brightness.dark,
        ),
      ),
    );
  }
}
