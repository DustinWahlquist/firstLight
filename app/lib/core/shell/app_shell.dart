import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers.dart';
import 'birdcage_icon.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final displayName = user?.userMetadata?['display_name'] as String? ?? '';
    final email = user?.email ?? '';
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : email.isNotEmpty
            ? email[0].toUpperCase()
            : '?';

    final theme = Theme.of(context);

    Widget profileIcon({bool selected = false}) {
      if (avatarUrl != null) {
        return CircleAvatar(
          radius: 13,
          backgroundImage: CachedNetworkImageProvider(avatarUrl),
        );
      }
      return CircleAvatar(
        radius: 13,
        backgroundColor: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHigh,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 56,
        selectedIndex: navigationShell.currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: BirdcageIcon(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: BirdcageIcon(
              color: theme.colorScheme.onSecondaryContainer,
            ),
            label: 'Aviary',
          ),
          NavigationDestination(
            icon: profileIcon(),
            selectedIcon: profileIcon(selected: true),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
