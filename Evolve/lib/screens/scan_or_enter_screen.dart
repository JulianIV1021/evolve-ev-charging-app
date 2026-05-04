import 'package:flutter/cupertino.dart';

import '../design_system/haptics/haptics.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/tokens/shadows.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';
import 'enter_charger_code_screen.dart';
import 'scan_qr_screen.dart';

class ScanOrEnterScreen extends StatelessWidget {
  const ScanOrEnterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: AppColors.accent),
        ),
        middle: Text('Start Charging', style: AppTypography.headline),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxxl),

              // ── Icon + header ──────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.bolt_fill,
                        size: 34,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Choose a method', style: AppTypography.title2),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'How would you like to connect\nto your charger?',
                      style: AppTypography.subhead,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // ── Primary: Scan QR ───────────────────────────────────────────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => AppHaptics.mediumImpact(),
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const ScanQrScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppRadius.circularXl,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.qrcode_viewfinder,
                        size: 22,
                        color: CupertinoColors.white,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Scan QR Code',
                        style: AppTypography.headline
                            .copyWith(color: AppColors.textOnAccent),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Secondary: Enter code manually ─────────────────────────────
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
                    vertical: AppSpacing.lg + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.circularXl,
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.keyboard,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Enter Charger Code',
                        style: AppTypography.headline
                            .copyWith(color: AppColors.textPrimary),
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
}
