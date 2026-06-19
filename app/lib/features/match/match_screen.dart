import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/match/match_state.dart';
import 'match_controller.dart';
import 'views/day_board_view.dart';
import 'views/end_view.dart';
import 'views/initiative_view.dart';
import 'views/night_view.dart';

/// Entry point for a practice match. Switches between the four match
/// screens; each reads the shared [matchControllerProvider].
class MatchPage extends ConsumerWidget {
  const MatchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(matchControllerProvider.select((s) => s.screen));
    return PopScope(
      canPop: screen == MatchScreen.initiative,
      child: Scaffold(
        body: switch (screen) {
          MatchScreen.initiative => const InitiativeView(),
          MatchScreen.day => const DayBoardView(),
          MatchScreen.night => const NightView(),
          MatchScreen.end => const EndView(),
        },
      ),
    );
  }
}
