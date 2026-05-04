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
import '../../services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    AppHaptics.mediumImpact();
    try {
      await GoogleAuthService.signIn();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyError(e.code));
        AppHaptics.notificationError();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Google sign in failed. Please try again.');
        AppHaptics.notificationError();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    AppHaptics.mediumImpact();
    try {
      await AuthService.instance.signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
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
        'wrong-password' || 'invalid-credential' => 'Incorrect password. Please try again.',
        'invalid-email' => 'Enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        _ => 'Sign in failed. Please check your details.',
      };

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),

              // ── Logo ────────────────────────────────────────────────────
              _Logo(),

              const SizedBox(height: 48),

              // ── Form group ──────────────────────────────────────────────
              _FormGroup(children: [
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
                  placeholder: 'Password',
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  prefixIcon: CupertinoIcons.lock,
                  suffixWidget: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    child: Icon(
                      _obscurePass ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ]),

              // ── Error ────────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _ErrorBanner(message: _error!),
              ],

              // ── Forgot password ──────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  padding: const EdgeInsets.only(
                      top: AppSpacing.sm, bottom: 0),
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(
                    'Forgot Password?',
                    style: AppTypography.subhead.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Sign in button ───────────────────────────────────────────
              EvButton.primary(
                'Sign In',
                isLoading: _loading,
                onPressed: _loading ? null : _login,
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Divider ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Container(height: 0.5, color: AppColors.separator)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      'or',
                      style: AppTypography.subhead.copyWith(
                          color: AppColors.textTertiary),
                    ),
                  ),
                  Expanded(child: Container(height: 0.5, color: AppColors.separator)),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Google Sign In ───────────────────────────────────────────
              Container(
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.separator),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.label.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onPressed: _loading ? null : _googleSignIn,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Continue with Google',
                        style: AppTypography.body.copyWith(
                          color: AppColors.label,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // ── Sign up link ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: AppTypography.subhead.copyWith(
                        color: AppColors.textSecondary),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.only(left: 4),
                    onPressed: () => context.push('/signup'),
                    child: Text(
                      'Sign Up',
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
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Image.asset(
            'assets/login_logo.png',
            width: 240,
            height: 190,
            fit: BoxFit.contain,
          ),
        ],
      );
}

/// iOS-style inset grouped form card
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
            padding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 0),
            decoration: null, // no inner border
            style: AppTypography.body.copyWith(color: AppColors.label),
            placeholderStyle: AppTypography.body
                .copyWith(color: AppColors.textTertiary),
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
                style: AppTypography.subhead.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
}
