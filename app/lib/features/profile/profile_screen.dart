import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';
import '../aviary/aviary_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notifications = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aviary = ref.watch(aviaryProvider);
    final user = Supabase.instance.client.auth.currentUser;

    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final createdAt = user?.createdAt != null
        ? DateTime.tryParse(user!.createdAt)
        : null;
    final watcherSince = createdAt != null
        ? '${_monthName(createdAt.month)} ${createdAt.year}'
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(email, style: theme.textTheme.titleLarge),
                if (watcherSince.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Watcher since $watcherSince',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          aviary.when(
            loading: () => const _SectionCard(
              label: 'STATS',
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (cards) {
              final lifers = cards.length;
              final totalCatches =
                  cards.fold(0, (sum, c) => sum + c.catchCount);
              final totalXp = cards.fold(0, (sum, c) => sum + c.xp);
              final avgLevel = cards.isEmpty
                  ? 0.0
                  : cards.fold(0, (sum, c) => sum + c.level) / cards.length;

              return _SectionCard(
                label: 'STATS',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatCell(
                              label: 'Lifers',
                              value: '$lifers',
                            ),
                            const SizedBox(height: 16),
                            _StatCell(
                              label: 'Total XP',
                              value: '$totalXp',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatCell(
                              label: 'Total catches',
                              value: '$totalCatches',
                            ),
                            const SizedBox(height: 16),
                            _StatCell(
                              label: 'Avg level',
                              value: avgLevel.toStringAsFixed(1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _SectionCard(
            label: 'MAP',
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(painter: _StripePainter()),
                        const Center(
                          child: Text(
                            'first-catch location map',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFF4D4742),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                aviary.maybeWhen(
                  data: (cards) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${cards.length} states',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  },
                  orElse: () => const SizedBox(height: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: 0.5,
            child: _SectionCard(
              label: 'MATCH RECORD',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Coming soon',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCell(label: 'W', value: '—'),
                    ),
                    Expanded(
                      child: _StatCell(label: 'L', value: '—'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            label: 'ACCOUNT',
            child: Column(
              children: [
                Opacity(
                  opacity: 0.5,
                  child: ListTile(
                    title: const Text('Merlin account'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Coming soon',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                SwitchListTile(
                  title: const Text('Notifications'),
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                ListTile(
                  title: const Text('Sign out'),
                  onTap: () async {
                    await ref.read(supabaseServiceProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                ListTile(
                  title: Text(
                    'Delete account',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => _showDeleteSheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _DeleteConfirmSheet(
        onConfirm: () async {
          Navigator.of(context).pop();
          await ref.read(supabaseServiceProvider).deleteAccount();
          if (context.mounted) context.go('/login');
        },
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }
}

class _DeleteConfirmSheet extends StatefulWidget {
  const _DeleteConfirmSheet({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  State<_DeleteConfirmSheet> createState() => _DeleteConfirmSheetState();
}

class _DeleteConfirmSheetState extends State<_DeleteConfirmSheet> {
  final _controller = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final can = _controller.text == 'Delete';
      if (can != _canDelete) setState(() => _canDelete = can);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delete account?',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This will permanently delete your account, all bird cards, and catch history. This cannot be undone.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'TYPE DELETE TO CONFIRM',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Delete',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _canDelete ? widget.onConfirm : null,
                style: _canDelete
                    ? FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      )
                    : null,
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child, this.trailing});
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.headlineSmall),
      ],
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDAD4C9)
      ..strokeWidth = 1.0;

    const spacing = 14.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}
