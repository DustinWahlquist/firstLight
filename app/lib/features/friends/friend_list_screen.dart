import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/friendship.dart';
import '../../models/user_profile.dart';

class FriendListScreen extends ConsumerStatefulWidget {
  const FriendListScreen({super.key, required this.userId, required this.name});
  final String userId;
  final String name;

  @override
  ConsumerState<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends ConsumerState<FriendListScreen> {
  List<Friendship>? _friends;
  Set<String> _myFriendIds = {};
  bool _loading = true;
  final Set<String> _requestedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(supabaseServiceProvider);
    final theirFriends = await service.fetchFriendListFor(widget.userId);
    final myFriends = await service.fetchFriends();
    if (!mounted) return;
    setState(() {
      _friends = theirFriends;
      _myFriendIds = myFriends.map((f) => f.profile?.id ?? '').toSet();
      _loading = false;
    });
  }

  Future<void> _sendRequest(String userId) async {
    await ref.read(supabaseServiceProvider).sendFriendRequest(userId);
    if (mounted) setState(() => _requestedIds.add(userId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mutual = _friends?.where((f) => _myFriendIds.contains(f.profile?.id)).toList() ?? [];
    final others = _friends?.where((f) => !_myFriendIds.contains(f.profile?.id)).toList() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: Text("${widget.name}'s Friends"),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _friends!.isEmpty
              ? Center(
                  child: Text(
                    'No friends yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    if (mutual.isNotEmpty) ...[
                      _SectionHeader(
                        label: 'MUTUAL FRIENDS · ${mutual.length}',
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: theme.colorScheme.surface,
                        child: Column(
                          children: mutual.map((f) => _FriendListRow(
                            profile: f.profile,
                            isMutual: true,
                            requested: _requestedIds.contains(f.profile?.id),
                            onTap: f.profile != null
                                ? () => context.push('/friend-profile', extra: f.profile!)
                                : null,
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (others.isNotEmpty) ...[
                      _SectionHeader(label: 'OTHERS · ${others.length}'),
                      const SizedBox(height: 8),
                      Card(
                        color: theme.colorScheme.surface,
                        child: Column(
                          children: others.map((f) => _FriendListRow(
                            profile: f.profile,
                            isMutual: false,
                            requested: _requestedIds.contains(f.profile?.id),
                            onAdd: f.profile != null
                                ? () => _sendRequest(f.profile!.id)
                                : null,
                            onTap: f.profile != null
                                ? () => context.push('/friend-profile', extra: f.profile!)
                                : null,
                          )).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: color ?? theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FriendListRow extends StatelessWidget {
  const _FriendListRow({
    required this.profile,
    required this.isMutual,
    required this.requested,
    this.onTap,
    this.onAdd,
  });
  final UserProfile? profile;
  final bool isMutual;
  final bool requested;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profile?.displayName ?? profile?.username ?? 'Unknown';
    final avatarUrl = profile?.avatarUrl;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isMutual
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHigh,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? Text(
                profile?.initials ?? '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isMutual
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
      ),
      title: Text(name),
      subtitle: isMutual
          ? Text(
              'Mutual friend',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            )
          : null,
      trailing: !isMutual
          ? requested
              ? Chip(
                  label: const Text('Requested'),
                  labelStyle: theme.textTheme.labelSmall,
                  padding: EdgeInsets.zero,
                )
              : FilledButton(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Add'),
                )
          : null,
    );
  }
}
