import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';
import 'home_screen.dart';

// Legacy approval gate — not used in the new GoRouter flow.
// Approval checking is now handled by MainShell in navigation/main_shell.dart.
class ApprovalGate extends StatelessWidget {
  const ApprovalGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final ref =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        final data = snap.data?.data();

        if (data == null) {
          return CupertinoPageScaffold(
            backgroundColor: AppColors.background,
            navigationBar: CupertinoNavigationBar(
              middle: Text('EvolvePRO',
                  style:
                      AppTypography.headline.copyWith(color: AppColors.label)),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Icon(CupertinoIcons.square_arrow_right,
                    color: AppColors.error),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'User profile not found. Please sign out and sign in again.',
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (data['approved'] == true) return const HomeScreen();

        return CupertinoPageScaffold(
          backgroundColor: AppColors.background,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.clock,
                        size: 64, color: AppColors.accent),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Waiting for approval',
                        textAlign: TextAlign.center,
                        style: AppTypography.title2
                            .copyWith(color: AppColors.label)),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Your account is registered, but an admin must approve '
                      'you before you can start charging.',
                      textAlign: TextAlign.center,
                      style: AppTypography.callout
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    CupertinoButton.filled(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
