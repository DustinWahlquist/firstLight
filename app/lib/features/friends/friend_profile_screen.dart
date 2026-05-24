import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/bird_card.dart';
import '../../models/friendship.dart';
import '../../models/user_profile.dart';

class FriendProfileScreen extends ConsumerStatefulWidget {
  const FriendProfileScreen({super.key, required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen> {
  Friendship? _friendship;
  bool _loadingFriendship = true;
  bool _requestSent = false;

  List<BirdCard>? _aviary;
  bool _loadingAviary = false;

  @override
  void initState() {
    super.initState();
    _loadFriendship();
  }

  Future<void> _loadFriendship() async {
    final f = await ref.read(supabaseServiceProvider).fetchFriendshipWith(widget.profile.id);
    if (!mounted) return;
    setState(() { _friendship = f; _loadingFriendship = false; });
    if (_canSeeContent) _loadAviary();
  }

  bool get _canSeeContent {
    if (widget.profile.isPublic) return true;
    return _friendship?.status == FriendshipStatus.accepted;
  }

  Future<void> _loadAviary() async {
    if (_loadingAviary) return;
    setState(() => _loadingAviary = true);
    final cards = await ref.read(supabaseServiceProvider).fetchAviaryFor(widget.profile.id);
    if (mounted) setState(() { _aviary = cards; _loadingAviary = false; });
  }

  Future<void> _sendRequest() async {
    await ref.read(supabaseServiceProvider).sendFriendRequest(widget.profile.id);
    if (mounted) setState(() => _requestSent = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;
    final name = profile.displayName ?? profile.username ?? 'Unknown';
    final isAccepted = _friendship?.status == FriendshipStatus.accepted;
    final isPending = _friendship?.status == FriendshipStatus.pending;

    Widget? trailingAction;
    if (!_loadingFriendship && !isAccepted) {
      if (isPending || _requestSent) {
        trailingAction = Chip(
          label: const Text('Requested'),
          labelStyle: theme.textTheme.labelSmall,
        );
      } else {
        trailingAction = FilledButton(
          onPressed: _sendRequest,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Add friend'),
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.transparent,
        actions: [if (trailingAction != null) Padding(padding: const EdgeInsets.only(right: 8), child: trailingAction)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.initials,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Watcher',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          if (_loadingFriendship)
            const Center(child: CircularProgressIndicator())
          else if (!_canSeeContent)
            _PrivateGate(name: name, onAddFriend: _requestSent || isPending ? null : _sendRequest)
          else ...[
            // Stats
            _SectionCard(
              label: 'STATS',
              child: _loadingAviary
                  ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Row(
                        children: [
                          Expanded(child: _StatCell(label: 'Lifers', value: '${_aviary?.length ?? 0}')),
                          Expanded(child: _StatCell(
                            label: 'Total catches',
                            value: '${_aviary?.fold(0, (s, c) => s + c.catchCount) ?? 0}',
                          )),
                          Expanded(child: _StatCell(
                            label: 'Friends',
                            value: '…',
                            onTap: () => context.push('/friend-list',
                                extra: (userId: profile.id, name: name)),
                          )),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            // Aviary
            _SectionCard(
              label: 'AVIARY',
              child: _loadingAviary
                  ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                  : _aviary == null || _aviary!.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Text(
                            'No birds yet.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Column(
                          children: _aviary!.map((card) => _AviaryRow(card: card)).toList(),
                        ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrivateGate extends StatelessWidget {
  const _PrivateGate({required this.name, this.onAddFriend});
  final String name;
  final VoidCallback? onAddFriend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('Private profile', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              "Only friends can see $name's Aviary and stats.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (onAddFriend != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAddFriend,
                child: const Text('Send friend request'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AviaryRow extends StatelessWidget {
  const _AviaryRow({required this.card});
  final BirdCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpToNext = BirdCard.xpForNextLevel(card.level);
    final xpProgress = card.xp / xpToNext;

    return ListTile(
      title: Text(card.speciesName, style: theme.textTheme.bodyMedium),
      subtitle: LinearProgressIndicator(
        value: xpProgress.clamp(0.0, 1.0),
        minHeight: 4,
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
      ),
      trailing: Text('Lv ${card.level}', style: theme.textTheme.labelSmall),
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

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: onTap != null ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
