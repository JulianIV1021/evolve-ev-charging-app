import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/ev_button.dart';
import '../../design_system/haptics/haptics.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radius.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../models/ev_profile_model.dart';
import '../../services/auth_service.dart';

// ---------------------------------------------------------------------------
// Provider — user profile doc
// ---------------------------------------------------------------------------

final _userDocProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => s.data());
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_userDocProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppColors.background,
        border: null,
        middle: Text('Profile'),
      ),
      child: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(
            child: Text('Error: $e',
                style: AppTypography.subhead
                    .copyWith(color: AppColors.textSecondary)),
          ),
          data: (doc) => _ProfileBody(doc: doc),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.doc});
  final Map<String, dynamic>? doc;

  @override
  Widget build(BuildContext context) {
    final name = doc?['name'] as String? ?? 'EV Driver';
    final email = doc?['email'] as String? ??
        FirebaseAuth.instance.currentUser?.email ??
        '—';
    final role = doc?['role'] as String? ?? 'user';
    final evProfileData = doc?['evProfile'] as Map<String, dynamic>?;
    final evProfile =
        evProfileData != null ? EVProfile.fromMap(evProfileData) : null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Avatar + name
        _AvatarHeader(name: name, email: email, role: role),

        const SizedBox(height: AppSpacing.xl),

        // EV Profile section
        _SectionLabel('My Vehicle'),
        _VehicleCard(evProfile: evProfile),

        const SizedBox(height: AppSpacing.xl),

        // Account section
        _SectionLabel('Account'),
        _SettingsGroup(items: [
          _SettingsItem(
            icon: CupertinoIcons.person_crop_circle,
            label: 'Display Name',
            trailing: name,
          ),
          _SettingsItem(
            icon: CupertinoIcons.mail,
            label: 'Email',
            trailing: email,
          ),
        ]),

        const SizedBox(height: AppSpacing.xl),

        // App section
        _SectionLabel('App'),
        _SettingsGroup(items: [
          _SettingsItem(
            icon: CupertinoIcons.info_circle,
            label: 'Version',
            trailing: '1.0.0',
          ),
        ]),

        const SizedBox(height: AppSpacing.xl),

        EvButton.destructive(
          'Sign Out',
          onPressed: () async {
            AppHaptics.mediumImpact();
            await AuthService.instance.signOut();
          },
        ),

        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({
    required this.name,
    required this.email,
    required this.role,
  });
  final String name;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Text(
              initials.toUpperCase(),
              style: AppTypography.largeTitle.copyWith(color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(name,
            style: AppTypography.title3.copyWith(color: AppColors.label)),
        const SizedBox(height: 2),
        Text(email,
            style:
                AppTypography.subhead.copyWith(color: AppColors.textSecondary)),
        if (role == 'admin') ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text('Admin',
                style: AppTypography.caption1.copyWith(
                    color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.evProfile});
  final EVProfile? evProfile;

  @override
  Widget build(BuildContext context) {
    if (evProfile == null) {
      return GestureDetector(
        onTap: () =>
            context.push('/profile/vehicle'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.5),
                style: BorderStyle.solid),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.add_circled_solid,
                  color: AppColors.accent, size: 24),
              const SizedBox(width: AppSpacing.md),
              Text('Add Your EV',
                  style: AppTypography.callout.copyWith(color: AppColors.accent,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/profile/vehicle'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.separator),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(CupertinoIcons.car_detailed,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${evProfile!.vehicleMake} ${evProfile!.vehicleModel}'.trim(),
                    style: AppTypography.callout
                        .copyWith(color: AppColors.label, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${evProfile!.batteryCapacityKwh.toStringAsFixed(0)} kWh · ${evProfile!.maxChargingPowerKw.toStringAsFixed(0)} kW max',
                    style: AppTypography.subhead
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            left: AppSpacing.xs, bottom: AppSpacing.sm),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.caption1.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
      );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.separator),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Container(height: 0.5, color: AppColors.separator),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label,
                  style:
                      AppTypography.callout.copyWith(color: AppColors.label)),
            ),
            if (trailing != null)
              Text(trailing!,
                  style: AppTypography.callout
                      .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
