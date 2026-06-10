import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/friendship.dart';
import '../../models/user_profile.dart';
import 'friends_providers.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  List<UserProfile>? _searchResults;
  bool _searching = false;
  final Set<String> _requestedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) { setState(() => _searchResults = null); return; }
    setState(() => _searching = true);
    final results = await ref.read(profileRepositoryProvider).searchProfiles(q);
    if (mounted) setState(() { _searchResults = results; _searching = false; });
  }

  Future<void> _sendRequest(String userId) async {
    await ref.read(friendsRepositoryProvider).sendFriendRequest(userId);
    if (mounted) setState(() => _requestedIds.add(userId));
  }

  Future<void> _accept(String friendshipId) async {
    await ref.read(friendsRepositoryProvider).acceptFriendRequest(friendshipId);
    ref.invalidate(pendingFriendsProvider);
    ref.invalidate(friendsProvider);
  }

  Future<void> _decline(String friendshipId) async {
    await ref.read(friendsRepositoryProvider).declineFriendRequest(friendshipId);
    ref.invalidate(pendingFriendsProvider);
  }

  Future<void> _remove(String friendshipId) async {
    await ref.read(friendsRepositoryProvider).removeFriend(friendshipId);
    ref.invalidate(friendsProvider);
    ref.invalidate(friendCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friends = ref.watch(friendsProvider);
    final pending = ref.watch(pendingFriendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Search
          _SectionCard(
            label: 'ADD FRIENDS',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Username or display name',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _searching ? null : _search,
                        child: _searching
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Search'),
                      ),
                    ],
                  ),
                  if (_searchResults != null) ...[
                    const SizedBox(height: 12),
                    if (_searchResults!.isEmpty)
                      Text(
                        'No users found.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      for (final profile in _searchResults!)
                        _SearchResultRow(
                          profile: profile,
                          requested: _requestedIds.contains(profile.id),
                          onAdd: () => _sendRequest(profile.id),
                          onTap: () => context.push('/friend-profile', extra: profile),
                        ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'https://firstlight.app/invite'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite link copied!')),
                      );
                    },
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Share invite link'),
                  ),
                ],
              ),
            ),
          ),

          // Pending
          pending.maybeWhen(
            data: (list) {
              if (list.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 12),
                  _SectionCard(
                    label: 'PENDING',
                    child: Column(
                      children: list.map((f) => _PendingRow(
                        friendship: f,
                        onAccept: () => _accept(f.id),
                        onDecline: () => _decline(f.id),
                        onTap: f.profile != null
                            ? () => context.push('/friend-profile', extra: f.profile!)
                            : null,
                      )).toList(),
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // Friends list
          const SizedBox(height: 12),
          friends.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
            data: (list) => _SectionCard(
              label: '${list.length} FRIENDS',
              child: list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Text(
                        'No friends yet. Search above to connect.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Column(
                      children: list.map((f) {
                        final profile = f.profile;
                        return _FriendRow(
                          friendship: f,
                          onTap: profile != null
                              ? () => context.push('/friend-profile', extra: profile)
                              : null,
                          onRemove: () => _remove(f.id),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.profile,
    required this.requested,
    required this.onAdd,
    required this.onTap,
  });
  final UserProfile profile;
  final bool requested;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: _ProfileAvatar(profile: profile, radius: 18),
      title: Text(profile.displayName ?? profile.username ?? 'Unknown'),
      onTap: onTap,
      trailing: requested
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
            ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.friendship,
    required this.onAccept,
    required this.onDecline,
    this.onTap,
  });
  final Friendship friendship;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final profile = friendship.profile;
    return ListTile(
      leading: _ProfileAvatar(profile: profile, radius: 18),
      title: Text(profile?.displayName ?? 'Unknown'),
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(onPressed: onDecline, child: const Text('Decline')),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: onAccept,
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friendship, this.onTap, required this.onRemove});
  final Friendship friendship;
  final VoidCallback? onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = friendship.profile;
    return ListTile(
      leading: _ProfileAvatar(profile: profile, radius: 18),
      title: Text(profile?.displayName ?? 'Unknown'),
      onTap: onTap,
      trailing: TextButton(
        onPressed: onRemove,
        style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
        child: const Text('Remove'),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.radius});
  final UserProfile? profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = profile?.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Text(
              profile?.initials ?? '?',
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});
  final String label;
  final Widget child;

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
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
