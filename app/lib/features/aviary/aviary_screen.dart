import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/bird_card.dart';
import 'widgets/bird_card_tile.dart';

final aviaryProvider = FutureProvider<List<BirdCard>>((ref) {
  return ref.watch(supabaseServiceProvider).fetchAviary();
});

class AviaryScreen extends ConsumerWidget {
  const AviaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aviary = ref.watch(aviaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Aviary')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/screenshot'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Log Catch'),
      ),
      body: aviary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cards) => cards.isEmpty
            ? const Center(
                child: Text(
                  'No birds yet.\nLog your first catch to get started.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cards.length,
                itemBuilder: (context, i) => BirdCardTile(card: cards[i]),
              ),
      ),
    );
  }
}
