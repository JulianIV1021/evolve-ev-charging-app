import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/cupertino.dart';

import '../design_system/haptics/haptics.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';
import 'confirm_start_screen.dart';

class PlugInScreen extends StatefulWidget {
  final String qrPayload;
  const PlugInScreen({super.key, required this.qrPayload});

  @override
  State<PlugInScreen> createState() => _PlugInScreenState();
}

class _PlugInScreenState extends State<PlugInScreen>
    with SingleTickerProviderStateMixin {
  final _battery = Battery();
  StreamSubscription<BatteryState>? _batterySub;
  bool _plugged = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Check current state immediately (phone may already be plugged in)
    _battery.batteryState.then(_onBatteryState);
    // Then listen for changes
    _batterySub = _battery.onBatteryStateChanged.listen(_onBatteryState);
  }

  void _onBatteryState(BatteryState state) {
    if (_plugged) return;
    if (state == BatteryState.charging || state == BatteryState.full) {
      if (!mounted) return;
      setState(() => _plugged = true);
      _pulseCtrl.stop();
      AppHaptics.notificationSuccess();
      // Brief pause to show the success state before navigating
      Future.delayed(const Duration(milliseconds: 1200), _proceed);
    }
  }

  void _proceed() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(
        builder: (_) => ConfirmStartScreen(qrPayload: widget.qrPayload),
      ),
    );
  }

  @override
  void dispose() {
    _batterySub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

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
        middle: Text(
          _plugged ? 'Ready to Charge' : 'Plug In Charger',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Animated icon ──────────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _plugged
                    ? _StatusCircle(
                        key: const ValueKey('plugged'),
                        color: AppColors.success,
                        icon: CupertinoIcons.checkmark_circle_fill,
                      )
                    : AnimatedBuilder(
                        key: const ValueKey('waiting'),
                        animation: _pulseAnim,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: _StatusCircle(
                            color: AppColors.accent,
                            icon: CupertinoIcons.bolt_fill,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Heading ────────────────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _plugged ? 'Charger Connected!' : 'Plug In Your Charger',
                  key: ValueKey(_plugged),
                  textAlign: TextAlign.center,
                  style: AppTypography.title2.copyWith(
                    color: AppColors.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _plugged
                      ? 'Connected. Taking you to the next step…'
                      : 'Connect the charging cable to your vehicle\nbefore starting the session.',
                  key: ValueKey(_plugged),
                  textAlign: TextAlign.center,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared icon circle ──────────────────────────────────────────────────────

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({super.key, required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 60, color: color),
      );
}
