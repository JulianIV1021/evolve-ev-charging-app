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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return 'Full name is required.';
    if (_emailCtrl.text.trim().isEmpty) return 'Email is required.';
    if (!_emailCtrl.text.contains('@')) return 'Enter a valid email address.';
    if (_passCtrl.text.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (_passCtrl.text != _confirmCtrl.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    AppHaptics.mediumImpact();
    try {
      await AuthService.instance.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );
      // Sign out immediately — user must be approved before accessing the app.
      await AuthService.instance.signOut();
      if (mounted) setState(() => _success = true);
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
        'email-already-in-use' => 'An account already exists for this email.',
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' => 'Password must be at least 8 characters.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        _ => 'Account creation failed. Please try again.',
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
      ),
      child: SafeArea(
        child: _success
            ? _SuccessView(onBack: () => context.pop())
            : SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),

                    // ── Logo ───────────────────────────────────────────────
                    Center(
                      child: Image.asset(
                        'assets/login_logo.png',
                        width: 180,
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // ── Heading ────────────────────────────────────────────
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: AppTypography.title2.copyWith(
                        color: AppColors.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Fill in your details to get started.',
                      textAlign: TextAlign.center,
                      style: AppTypography.subhead
                          .copyWith(color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Form group ─────────────────────────────────────────
                    _FormGroup(children: [
                      _Field(
                        controller: _nameCtrl,
                        placeholder: 'Full Name',
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        prefixIcon: CupertinoIcons.person,
                      ),
                      _Divider(),
                      _Field(
                        controller: _emailCtrl,
                        placeholder: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        prefixIcon: CupertinoIcons.mail,
                      ),
                      _Divider(),
                      _Field(
                        controller: _passCtrl,
                        placeholder: 'Password (min 8 characters)',
                        obscureText: _obscurePass,
                        textInputAction: TextInputAction.next,
                        prefixIcon: CupertinoIcons.lock,
                        suffixWidget: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                          child: Icon(
                            _obscurePass
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      _Divider(),
                      _Field(
                        controller: _confirmCtrl,
                        placeholder: 'Confirm Password',
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _createAccount(),
                        prefixIcon: CupertinoIcons.lock_shield,
                        suffixWidget: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                          child: Icon(
                            _obscureConfirm
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                        ),
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
                      'Create Account',
                      isLoading: _loading,
                      onPressed: _loading ? null : _createAccount,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Admin approval notice ──────────────────────────────
                    Text(
                      'Your account will need admin approval before you can sign in.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption1
                          .copyWith(color: AppColors.textTertiary),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // ── Sign in link ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: AppTypography.subhead
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.only(left: 4),
                          onPressed: () => context.pop(),
                          child: Text(
                            'Sign In',
                            style: AppTypography.subhead.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
// Success view
// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              CupertinoIcons.checkmark_seal_fill,
              size: 72,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Account Created!',
              textAlign: TextAlign.center,
              style: AppTypography.title1.copyWith(
                color: AppColors.label,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your account is pending admin approval. '
              'You will be able to sign in once approved.',
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 52),
        child: Container(height: 0.5, color: AppColors.separatorOpaque),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.placeholder,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.autocorrect = true,
    this.onSubmitted,
    this.suffixWidget,
  });

  final TextEditingController controller;
  final String placeholder;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool autocorrect;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixWidget;

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
            obscureText: obscureText,
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
        if (suffixWidget != null) suffixWidget!,
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
