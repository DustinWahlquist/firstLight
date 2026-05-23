import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/aviary_card.dart';
import '../services/supabase_service.dart';
import '../widgets/bird_card_widget.dart';

class AviaryScreen extends StatefulWidget {
  const AviaryScreen({super.key});

  @override
  State<AviaryScreen> createState() => _AviaryScreenState();
}

class _AviaryScreenState extends State<AviaryScreen> {
  late Future<List<AviaryCard>> _aviary;

  @override
  void initState() {
    super.initState();
    _aviary = SupabaseService.instance.fetchAviary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Aviary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Import catch',
            onPressed: () => context.push('/import'),
          ),
        ],
      ),
      body: FutureBuilder<List<AviaryCard>>(
        future: _aviary,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final cards = snapshot.data!;
          if (cards.isEmpty) {
            return const _EmptyAviary();
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisExtent: 280,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: cards.length,
            itemBuilder: (_, i) => BirdCardWidget(card: cards[i]),
          );
        },
      ),
    );
  }
}

class _EmptyAviary extends StatelessWidget {
  const _EmptyAviary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.egg_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            'Your Aviary is empty.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Import a Merlin screenshot to catch your first bird.'),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Import catch'),
            onPressed: () => context.push('/import'),
          ),
        ],
      ),
    );
  }
}
