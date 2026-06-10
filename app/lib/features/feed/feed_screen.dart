import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/feed_event.dart';
import '../../models/scribble.dart';
import '../../models/user_profile.dart';
import 'feed_providers.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final feed = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ),
      ),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          if (events.isEmpty) return _EmptyState();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(feedProvider),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: events.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 16,
                color: theme.colorScheme.outlineVariant,
              ),
              itemBuilder: (_, i) => _FeedItem(event: events[i]),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'Add friends to see their activity',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.push('/friends'),
              child: const Text('Find friends'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feed Item ─────────────────────────────────────────────────────

class _FeedItem extends ConsumerStatefulWidget {
  const _FeedItem({required this.event});
  final FeedEvent event;

  @override
  ConsumerState<_FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends ConsumerState<_FeedItem> {
  late int _peckCount;
  late bool _hasPecked;
  bool _showScribbles = false;
  List<Scribble>? _scribbles;
  bool _loadingScribbles = false;
  final _scribbleController = TextEditingController();
  bool _postingScribble = false;

  @override
  void initState() {
    super.initState();
    _peckCount = widget.event.peckCount;
    _hasPecked = widget.event.hasPecked;
  }

  @override
  void dispose() {
    _scribbleController.dispose();
    super.dispose();
  }

  Future<void> _togglePeck() async {
    final service = ref.read(socialRepositoryProvider);
    setState(() {
      _hasPecked = !_hasPecked;
      _peckCount += _hasPecked ? 1 : -1;
    });
    try {
      if (_hasPecked) {
        await service.addPeck(widget.event.id);
      } else {
        await service.removePeck(widget.event.id);
      }
    } catch (_) {
      setState(() {
        _hasPecked = !_hasPecked;
        _peckCount += _hasPecked ? 1 : -1;
      });
    }
  }

  Future<void> _toggleScribbles() async {
    if (!_showScribbles && _scribbles == null && !_loadingScribbles) {
      setState(() => _loadingScribbles = true);
      final loaded = await ref.read(socialRepositoryProvider).fetchScribbles(widget.event.id);
      if (mounted) setState(() { _scribbles = loaded; _loadingScribbles = false; });
    }
    if (mounted) setState(() => _showScribbles = !_showScribbles);
  }

  Future<void> _postScribble() async {
    final text = _scribbleController.text.trim();
    if (text.isEmpty || _postingScribble) return;
    setState(() => _postingScribble = true);
    try {
      final s = await ref.read(socialRepositoryProvider).addScribble(widget.event.id, text);
      if (!mounted) return;
      _scribbleController.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _scribbles = [...?_scribbles, s];
        _postingScribble = false;
      });
    } catch (_) {
      setState(() => _postingScribble = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = widget.event;
    final profile = event.profile;
    final scribbleCount = _scribbles?.length ?? 0;

    return InkWell(
      onTap: profile != null ? () => context.push('/friend-profile', extra: profile) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(profile: profile, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ActivityText(event: event, theme: theme),
                      const SizedBox(height: 2),
                      Text(
                        _relativeTime(event.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bird art panel
          if (event.speciesName != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: profile != null
                    ? () => context.push('/friend-profile', extra: profile)
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: event.lineArtUrl != null
                        ? SvgPicture.network(
                            event.lineArtUrl!,
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) => _ArtPlaceholder(theme: theme),
                          )
                        : _ArtPlaceholder(theme: theme),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Action bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 4),
            child: Row(
              children: [
                // Peck button
                TextButton.icon(
                  onPressed: _togglePeck,
                  style: TextButton.styleFrom(
                    foregroundColor: _hasPecked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    _hasPecked ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                  ),
                  label: Text(
                    _peckCount == 0
                        ? 'Peck'
                        : _peckCount == 1
                            ? '1 peck'
                            : '$_peckCount pecks',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 4),
                // Comment button
                TextButton.icon(
                  onPressed: _toggleScribbles,
                  style: TextButton.styleFrom(
                    foregroundColor: _showScribbles
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    _showScribbles
                        ? Icons.chat_bubble
                        : Icons.chat_bubble_outline,
                    size: 18,
                  ),
                  label: Text(
                    scribbleCount > 0 ? '$scribbleCount' : '',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),

          // Inline scribbles
          if (_showScribbles) ...[
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            if (_loadingScribbles)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              if (_scribbles != null)
                for (final s in _scribbles!)
                  _ScribbleRow(scribble: s, theme: theme),
              // Input row
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16, 8, 16,
                  MediaQuery.of(context).viewInsets.bottom + 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _scribbleController,
                        decoration: InputDecoration(
                          hintText: 'Add a scribble…',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _postScribble(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _postingScribble ? null : _postScribble,
                      child: const Text('Post'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ActivityText extends StatelessWidget {
  const _ActivityText({required this.event, required this.theme});
  final FeedEvent event;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final name = event.profile?.displayName ?? 'Someone';
    final species = event.speciesName;

    switch (event.type) {
      case FeedEventType.newLifer:
        return RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(text: '$name caught a new lifer\n'),
              if (species != null)
                TextSpan(
                  text: species,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        );

      case FeedEventType.catch_:
        return RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(text: '$name spotted '),
              if (species != null)
                TextSpan(
                  text: species,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (event.xpAwarded != null && event.xpAwarded! > 0)
                TextSpan(
                  text: '  +${event.xpAwarded} XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        );

      case FeedEventType.levelUp:
        return RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(text: "$name's "),
              if (species != null)
                TextSpan(
                  text: species,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const TextSpan(text: ' leveled up'),
              if (event.level != null)
                TextSpan(
                  text: ' → Lv ${event.level}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        );

      case FeedEventType.milestone:
        return RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(text: '$name reached a milestone\n'),
              if (event.milestoneValue != null)
                TextSpan(
                  text: '${event.milestoneValue} lifers!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        );
    }
  }
}

class _ScribbleRow extends StatelessWidget {
  const _ScribbleRow({required this.scribble, required this.theme});
  final Scribble scribble;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final profile = scribble.profile;
    final name = profile?.displayName ?? 'User';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: profile != null
                ? () => context.push('/friend-profile', extra: profile)
                : null,
            child: _Avatar(profile: profile, radius: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '$name ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: scribble.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, required this.radius});
  final UserProfile? profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = profile?.avatarUrl;
    final initial = profile?.initials ?? '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: avatarUrl != null
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}

class _ArtPlaceholder extends StatelessWidget {
  const _ArtPlaceholder({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StripePainter(theme.colorScheme.surfaceContainerHigh),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 12;
    for (double i = -size.height; i < size.width + size.height; i += 24) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.color != color;
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
}
