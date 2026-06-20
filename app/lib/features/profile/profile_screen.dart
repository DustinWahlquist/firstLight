import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config.dart';
import '../../core/providers.dart';
import '../../models/bird_card.dart';
import '../aviary/aviary_providers.dart';
import '../friends/friends_providers.dart';
import '../match/active_games_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool? _notifications;
  bool? _isPublic;

  @override
  void initState() {
    super.initState();
    ref.read(myProfileProvider.future).then((p) {
      if (mounted) {
        setState(() {
          _isPublic = p?.isPublic ?? true;
          _notifications = p?.notificationsEnabled ?? true;
        });
      }
    });
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (updated == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aviary = ref.watch(aviaryProvider);
    final user = Supabase.instance.client.auth.currentUser;

    final email = user?.email ?? '';
    final displayName = user?.userMetadata?['display_name'] as String? ?? '';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : email.isNotEmpty
            ? email[0].toUpperCase()
            : '?';
    final createdAt = user?.createdAt != null
        ? DateTime.tryParse(user!.createdAt)
        : null;
    final watcherSince = createdAt != null
        ? '${_monthName(createdAt.month)} ${createdAt.year}'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEditProfile(context),
          ),
        ],
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
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          initial,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  displayName.isNotEmpty ? displayName : email,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                if (displayName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
              final totalCatches = cards.fold(0, (sum, c) => sum + c.catchCount);
              final totalXp = cards.fold(0, (sum, c) => sum + c.xp);
              final friendCount = ref.watch(friendCountProvider);

              return _SectionCard(
                label: 'STATS',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _StatCell(label: 'Lifers', value: '$lifers')),
                        Expanded(child: _StatCell(label: 'Catches', value: '$totalCatches')),
                        Expanded(child: _StatCell(label: 'XP', value: '$totalXp')),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/friends'),
                            child: _StatCell(
                              label: 'Friends',
                              value: friendCount.maybeWhen(data: (n) => '$n', orElse: () => '…'),
                              primary: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          aviary.maybeWhen(
            data: (cards) {
              final pins = cards
                  .where((c) => c.firstCatchLatitude != null && c.firstCatchLongitude != null)
                  .toList();
              return _SectionCard(
                label: 'MAP',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      child: SizedBox(
                        height: 200,
                        child: pins.isEmpty
                            ? const Center(
                                child: Text(
                                  'Log catches to see your map',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: Color(0xFF4D4742),
                                  ),
                                ),
                              )
                            : FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    pins.map((c) => c.firstCatchLatitude!).reduce((a, b) => a + b) / pins.length,
                                    pins.map((c) => c.firstCatchLongitude!).reduce((a, b) => a + b) / pins.length,
                                  ),
                                  initialZoom: 5,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: osmUserAgentPackageName,
                                  ),
                                  MarkerLayer(
                                    markers: pins.map((c) => Marker(
                                      point: LatLng(c.firstCatchLatitude!, c.firstCatchLongitude!),
                                      width: 32,
                                      height: 32,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _showBirdPin(context, c),
                                        child: Icon(
                                          Icons.flutter_dash,
                                          size: 24,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(
                        '${pins.length} location${pins.length == 1 ? '' : 's'} mapped',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            },
            orElse: () => _SectionCard(
              label: 'MAP',
              child: const SizedBox(height: 200),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            label: 'MATCH RECORD',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Preview',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      Expanded(child: _StatCell(label: 'W', value: '—')),
                      Expanded(child: _StatCell(label: 'L', value: '—')),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.sports_esports_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  title: const Text('Play a practice match'),
                  subtitle: Text(
                    'Race the migration vs. Mara',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => startBotMatch(context, ref),
                ),
              ],
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
                  value: _notifications ?? true,
                  onChanged: (v) async {
                    setState(() => _notifications = v);
                    await ref
                        .read(profileRepositoryProvider)
                        .upsertProfile(notificationsEnabled: v);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                SwitchListTile(
                  title: const Text('Public profile'),
                  subtitle: Text(
                    (_isPublic ?? true)
                        ? 'Anyone can see your Aviary'
                        : 'Only friends can see your Aviary',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: _isPublic ?? true,
                  onChanged: (v) async {
                    setState(() => _isPublic = v);
                    await ref.read(profileRepositoryProvider).upsertProfile(isPublic: v);
                  },
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
                    await ref.read(profileRepositoryProvider).signOut();
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

  void _showBirdPin(BuildContext context, BirdCard card) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: InkWell(
          onTap: () {
            Navigator.of(sheetContext).pop();
            context.push('/bird-detail', extra: (card: card, ownerName: null));
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: card.lineArtUrl != null
                      ? SvgPicture.network(card.lineArtUrl!, fit: BoxFit.contain)
                      : Icon(
                          Icons.flutter_dash,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.speciesName, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              card.firstCatchLocation.isEmpty
                                  ? 'Unknown location'
                                  : card.firstCatchLocation,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
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
          await ref.read(profileRepositoryProvider).deleteAccount();
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
      color: theme.colorScheme.surface,
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
  const _StatCell({required this.label, required this.value, this.primary = false});
  final String label;
  final String value;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Label pinned to the top, number to the bottom — so a wrapping label
    // doesn't push its number out of line with the other cells.
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: primary ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

