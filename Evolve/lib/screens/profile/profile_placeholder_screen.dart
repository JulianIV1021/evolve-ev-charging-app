import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../design/tokens.dart';
import '../../services/auth_service.dart';

/// Phase 5 will replace this with the full profile management screen.
/// Provides sign-out as the only functional action for Phase 0.
class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Profile')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EvroSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: EvroSpacing.lg),

              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: EvroColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (user?.email?.isNotEmpty == true)
                        ? user!.email![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: EvroSpacing.md),
              Text(
                user?.email ?? 'Unknown',
                style: EvroTypography.callout,
              ),
              const SizedBox(height: EvroSpacing.xxl),

              // Coming soon notice
              const Icon(
                CupertinoIcons.person_crop_circle,
                size: 52,
                color: EvroColors.textSecondary,
              ),
              const SizedBox(height: EvroSpacing.md),
              const Text(
                'Full profile management coming in Phase 5',
                textAlign: TextAlign.center,
                style: TextStyle(color: EvroColors.textSecondary),
              ),

              const Spacer(),

              // Sign out
              CupertinoButton(
                color: EvroColors.error,
                borderRadius: BorderRadius.circular(EvroRadius.mdValue),
                onPressed: () => AuthService.instance.signOut(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.square_arrow_left,
                        color: CupertinoColors.white),
                    SizedBox(width: EvroSpacing.sm),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EvroSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
