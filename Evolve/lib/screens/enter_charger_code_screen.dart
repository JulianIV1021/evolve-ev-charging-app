import 'package:flutter/cupertino.dart';

import '../design_system/components/ev_button.dart';
import '../design_system/components/ev_text_field.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';
import 'plug_in_screen.dart';

class EnterChargerCodeScreen extends StatefulWidget {
  const EnterChargerCodeScreen({super.key});

  @override
  State<EnterChargerCodeScreen> createState() => _EnterChargerCodeScreenState();
}

class _EnterChargerCodeScreenState extends State<EnterChargerCodeScreen> {
  final _ctrl = TextEditingController(text: 'EVOLVEPRO|EVOLVE-S1|CH-1');
  String? _error;

  bool _isValidPayload(String v) {
    final parts = v.split('|');
    if (parts.length != 3) return false;
    if (parts[0] != 'EVOLVEPRO') return false;
    if (parts[1].trim().isEmpty) return false;
    if (parts[2].trim().isEmpty) return false;
    return true;
  }

  void _continue() {
    final value = _ctrl.text.trim();
    if (!_isValidPayload(value)) {
      setState(() =>
          _error = 'Invalid code. Format: EVOLVEPRO|EVOLVE-S1|CH-1');
      return;
    }
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(
        builder: (_) => PlugInScreen(qrPayload: value),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
        middle: Text('Enter Charger Code', style: AppTypography.headline),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // ── Section title ──────────────────────────────────────────────
              Text('Manual Entry', style: AppTypography.title2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Type the charger code exactly as shown:',
                style: AppTypography.subhead,
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Format example pill ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  borderRadius: AppRadius.circularMd,
                ),
                child: Text(
                  'EVOLVEPRO|EVOLVE-S1|CH-1',
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Text field ─────────────────────────────────────────────────
              EvTextField(
                controller: _ctrl,
                placeholder: 'EVOLVEPRO|STATION|CHARGER',
                autocorrect: false,
                errorText: _error,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _continue(),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── CTA ────────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: EvButton.primary(
                  'Continue',
                  onPressed: _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
