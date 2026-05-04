import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/haptics/haptics.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/tokens/shadows.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';
import '../providers/battery_provider.dart';
import '../providers/station_providers.dart';
import 'charging_screen.dart';
import 'enter_charger_code_screen.dart';
import 'scan_qr_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Prevents scheduling multiple push callbacks in the same frame.
  bool _recoveryScheduled = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = user?.displayName?.split(' ').first ??
        user?.email?.split('@').first ??
        'there';
    final evProfile = ref.watch(evProfileProvider).valueOrNull;
    final phoneSoc = ref.watch(phoneBatterySocProvider).valueOrNull;

    // ── Active session recovery ────────────────────────────────────────────
    // If an active session exists and HomeScreen is the top route (nothing
    // pushed above it), push ChargingScreen. canPop() is the sole guard:
    //   - Scan → confirm → charging flow on stack → canPop true → skip
    //   - ChargingScreen already pushed by recovery → canPop true → skip
    //   - User navigated back from ChargingScreen → canPop false → re-push
    //   - Session ended, user tapped Done → activeSessionId is null → skip
    final activeSessionId =
        ref.watch(activeSessionProvider).valueOrNull;
    if (activeSessionId != null && !_recoveryScheduled) {
      _recoveryScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recoveryScheduled = false;
        if (!mounted) return;
        if (Navigator.of(context).canPop()) return;
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => ChargingScreen(sessionId: activeSessionId),
          ),
        );
      });
    }

    final vehicleName = evProfile != null && evProfile.vehicleMake.isNotEmpty
        ? '${evProfile.vehicleMake} ${evProfile.vehicleModel}'.trim()
        : 'Not set up';

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // ── Greeting ───────────────────────────────────────────────────
              Text(
                'Hello, $firstName',
                style: AppTypography.largeTitle.copyWith(color: AppColors.label),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Ready to charge?', style: AppTypography.subhead),

              const SizedBox(height: AppSpacing.xl),

              // ── Stats row ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: _batteryIcon(phoneSoc ?? 0.8),
                      iconColor: _batteryColor(phoneSoc ?? 0.8),
                      label: 'Battery',
                      value: phoneSoc != null
                          ? '${(phoneSoc * 100).round()}%'
                          : '--',
                      subtitle: phoneSoc != null
                          ? _batterySubtitle(
                              phoneSoc,
                              evProfile?.batteryCapacityKwh,
                            )
                          : null,
                      subtitleColor: phoneSoc != null
                          ? _batteryColor(phoneSoc)
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      icon: CupertinoIcons.car_fill,
                      iconColor: AppColors.accent,
                      label: 'Vehicle',
                      value: vehicleName,
                      subtitle: evProfile != null
                          ? '${evProfile.maxChargingPowerKw.toStringAsFixed(0)} kW max'
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Primary scan card ──────────────────────────────────────────
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => AppHaptics.mediumImpact(),
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (_) => const ScanQrScreen()),
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: AppRadius.circularXl,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.qrcode_viewfinder,
                          size: 72,
                          color: CupertinoColors.white,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Scan QR Code',
                          style: AppTypography.title3.copyWith(
                            color: AppColors.textOnAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Point at any EvolvePRO charger',
                          style: AppTypography.footnote.copyWith(
                            color: AppColors.textOnAccent.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Secondary: Enter ID manually ───────────────────────────────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => AppHaptics.lightImpact(),
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (_) => const EnterChargerCodeScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.circularLg,
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.keyboard,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Enter Charger ID manually',
                          style: AppTypography.callout
                              .copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _batteryColor(double soc) {
    if (soc >= 0.5) return AppColors.success;
    if (soc >= 0.2) return AppColors.warning;
    return AppColors.danger;
  }

  static IconData _batteryIcon(double soc) {
    if (soc >= 0.75) return CupertinoIcons.battery_100;
    if (soc >= 0.25) return CupertinoIcons.battery_25;
    return CupertinoIcons.battery_0;
  }

  static String _batteryStatus(double soc) {
    if (soc < 0.20) return 'Low battery';
    if (soc < 0.50) return 'Charge soon';
    if (soc <= 0.80) return 'Good range';
    return 'Ready for long trip';
  }

  static String _batterySubtitle(double soc, double? capacityKwh) {
    final status = _batteryStatus(soc);
    if (capacityKwh == null || capacityKwh <= 0) return status;
    final rangeKm = (capacityKwh * soc * 6.5).round();
    return '~$rangeKm km\n$status';
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    this.subtitleColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.circularLg,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.circularSm,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption1),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.callout.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.caption1.copyWith(
                      color: subtitleColor ?? AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
