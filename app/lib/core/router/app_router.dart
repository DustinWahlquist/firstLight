import 'package:go_router/go_router.dart';
import '../../features/aviary/aviary_screen.dart';
import '../../features/screenshot/screenshot_screen.dart';
import '../../features/card_reveal/card_reveal_screen.dart';
import '../../features/level_up/level_up_screen.dart';
import '../../models/bird_card.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AviaryScreen(),
    ),
    GoRoute(
      path: '/screenshot',
      builder: (context, state) => const ScreenshotScreen(),
    ),
    GoRoute(
      path: '/card-reveal',
      builder: (context, state) => CardRevealScreen(
        card: state.extra as BirdCard,
      ),
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
