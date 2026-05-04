import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/ev_button.dart';
import '../../design_system/haptics/haptics.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radius.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    AppHaptics.mediumImpact();
    try {
      await AuthService.instance.sendPasswordReset(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyError(e.code));
        AppHaptics.notificationError();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) => switch (code) {
        'user-not-found' => 'No account found for this email.',
        'invalid-email' => 'Enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        _ => 'Could not send reset email. Please try again.',
      };

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.accent,
          ),
        ),
        middle: Text(
          'Reset Password',
          style: AppTypography.headline.copyWith(color: AppColors.label),
        ),
      ),
      child: SafeArea(
        child: _sent
            ? _SentView(onBack: () => context.pop())
            : SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // ── Icon header ────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          CupertinoIcons.mail_solid,
                          size: 36,
                          color: AppColors.accent,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'Forgot your password?',
                      textAlign: TextAlign.center,
                      style: AppTypography.title2.copyWith(
                        color: AppColors.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "Enter your account email and we'll send you a reset link.",
                      textAlign: TextAlign.center,
                      style: AppTypography.subhead
                          .copyWith(color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Email field ────────────────────────────────────────
                    _FormGroup(children: [
                      _Field(
                        controller: _emailCtrl,
                        placeholder: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        onSubmitted: (_) => _send(),
                        prefixIcon: CupertinoIcons.mail,
                      ),
                    ]),

                    // ── Error ──────────────────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _ErrorBanner(message: _error!),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // ── Submit button ──────────────────────────────────────
                    EvButton.primary(
                      'Send Reset Link',
                      isLoading: _loading,
                      onPressed: _loading ? null : _send,
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sent success view
// ---------------------------------------------------------------------------

class _SentView extends StatelessWidget {
  const _SentView({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 72,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Check your inbox',
              textAlign: TextAlign.center,
              style: AppTypography.title2.copyWith(
                color: AppColors.label,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'A password reset link has been sent to your email address. '
              'Follow the instructions to set a new password.',
              textAlign: TextAlign.center,
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            EvButton.primary('Back to Login', onPressed: onBack),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _FormGroup extends StatelessWidget {
  const _FormGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.label.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.placeholder,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autocorrect = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String placeholder;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool autocorrect;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: AppSpacing.md),
        Icon(prefixIcon, size: 20, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autocorrect: autocorrect,
            onSubmitted: onSubmitted,
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
            decoration: null,
            style: AppTypography.body.copyWith(color: AppColors.label),
            placeholderStyle:
                AppTypography.body.copyWith(color: AppColors.textTertiary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_circle,
                size: 16, color: AppColors.error),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style:
                    AppTypography.subhead.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
}
