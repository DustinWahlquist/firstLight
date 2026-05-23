import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../models/aviary_card.dart';
import '../widgets/bird_card_widget.dart';
import '../widgets/xp_bar_widget.dart';

class CardRevealScreen extends StatelessWidget {
  const CardRevealScreen({super.key, required this.card});

  final AviaryCard card;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'New Lifer!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
            const SizedBox(height: 32),
            SizedBox(
              width: 260,
              child: BirdCardWidget(card: card),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .scale(begin: const Offset(0.7, 0.7), delay: 300.ms),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: XpBarWidget(card: card),
            ).animate().fadeIn(delay: 900.ms),
            const SizedBox(height: 48),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Add to Aviary'),
            ).animate().fadeIn(delay: 1200.ms),
          ],
        ),
      ),
    );
  }
}
