import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../design/tokens.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';
import '../providers/station_providers.dart';

/// 5-tab Cupertino navigation shell.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        final data = snap.data?.data();
        final approved = data?['approved'] == true;

        if (!approved) return _ApprovalPendingScreen(user: user);

        return _TabShell(navigationShell: navigationShell);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab shell — only shown to approved users
// ---------------------------------------------------------------------------

class _TabShell extends ConsumerWidget {
  const _TabShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapReady = ref.watch(mapReadyProvider);

    return Stack(
      children: [
        ColoredBox(
          color: AppColors.background,
          child: Column(
            children: [
              Expanded(child: navigationShell),
              _EvroTabBar(
                currentIndex: navigationShell.currentIndex,
                onTap: _onTap,
              ),
            ],
          ),
        ),
        // Branded overlay that fades out once the map is ready
        AnimatedOpacity(
          opacity: mapReady ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          child: IgnorePointer(
            ignoring: mapReady,
            child: const _MapLoadingOverlay(),
          ),
        ),
      ],
    );
  }
}

class _MapLoadingOverlay extends StatelessWidget {
  const _MapLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: CupertinoColors.white,
      child: Center(
        child: Image(
          image: AssetImage('assets/app_logo.png'),
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}

class _EvroTabBar extends StatelessWidget {
  const _EvroTabBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        border: Border(
          top: BorderSide(color: Color(0xFFC6C6C8), width: 0.5),
        ),
      ),
      child: SizedBox(
        height: 83 + bottomPadding,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background blur effect
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9).withValues(alpha: 0.94),
                ),
              ),
            ),

            // The 4 regular tabs (skip index 2 — that's the center Scan button)
            Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Row(
                children: [
                  _TabItem(
                    icon: CupertinoIcons.map,
                    label: 'Stations',
                    index: 0,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _TabItem(
                    icon: CupertinoIcons.search,
                    label: 'Search',
                    index: 1,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  // Empty space for center button
                  const Expanded(child: SizedBox()),
                  _TabItem(
                    icon: CupertinoIcons.list_bullet,
                    label: 'Activity',
                    index: 3,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _TabItem(
                    icon: CupertinoIcons.person,
                    label: 'Profile',
                    index: 4,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                ],
              ),
            ),

            // Center Scan button — floats above the tab bar
            Positioned(
              top: -20,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF5A623).withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: const Color(0xFFF5A623).withValues(alpha: 0.20),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.qrcode_viewfinder,
                          color: CupertinoColors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: currentIndex == 2
                              ? const Color(0xFFF5A623)
                              : const Color(0xFFAEAEB2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final color = isActive
        ? const Color(0xFF007AFF)
        : const Color(0xFFAEAEB2);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Approval pending screen
// ---------------------------------------------------------------------------

class _ApprovalPendingScreen extends StatelessWidget {
  const _ApprovalPendingScreen({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  CupertinoIcons.clock,
                  size: 64,
                  color: AppColors.accent,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Waiting for approval',
                  textAlign: TextAlign.center,
                  style: AppTypography.title1
                      .copyWith(color: AppColors.label),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your account (${user.email}) is registered, but an admin must '
                  'approve it before you can start charging.',
                  textAlign: TextAlign.center,
                  style: AppTypography.callout
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                CupertinoButton(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
