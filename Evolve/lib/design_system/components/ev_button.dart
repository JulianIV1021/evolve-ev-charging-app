import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../haptics/haptics.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

enum _ButtonVariant { primary, secondary, ghost, destructive }

/// iOS-native button component with haptics and subtle press animation.
///
/// ```dart
/// EvButton.primary('Start Charging', onPressed: _start)
/// EvButton.destructive('Stop Session', onPressed: _stop)
/// ```
class EvButton extends StatefulWidget {
  const EvButton._({
    super.key,
    required this.label,
    required this.onPressed,
    required this.variant,
    this.isLoading = false,
    this.icon,
  });

  factory EvButton.primary(
    String label, {
    Key? key,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
  }) =>
      EvButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _ButtonVariant.primary,
        isLoading: isLoading,
        icon: icon,
      );

  factory EvButton.secondary(
    String label, {
    Key? key,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) =>
      EvButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _ButtonVariant.secondary,
        isLoading: isLoading,
      );

  factory EvButton.ghost(
    String label, {
    Key? key,
    required VoidCallback? onPressed,
  }) =>
      EvButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _ButtonVariant.ghost,
      );

  factory EvButton.destructive(
    String label, {
    Key? key,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) =>
      EvButton._(
        key: key,
        label: label,
        onPressed: onPressed,
        variant: _ButtonVariant.destructive,
        isLoading: isLoading,
      );

  final String label;
  final VoidCallback? onPressed;
  // ignore: library_private_types_in_public_api
  final _ButtonVariant variant;
  final bool isLoading;
  final Widget? icon;

  @override
  State<EvButton> createState() => _EvButtonState();
}

class _EvButtonState extends State<EvButton> {
  bool _pressed = false;

  Color get _bg => switch (widget.variant) {
        _ButtonVariant.primary => AppColors.accent,
        _ButtonVariant.secondary =>
          CupertinoColors.secondarySystemBackground.color,
        _ButtonVariant.ghost => const Color(0x00000000),
        _ButtonVariant.destructive => AppColors.danger,
      };

  Color get _fg => switch (widget.variant) {
        _ButtonVariant.primary || _ButtonVariant.destructive =>
          AppColors.textOnAccent,
        _ButtonVariant.secondary => AppColors.accent,
        _ButtonVariant.ghost => AppColors.accent,
      };

  bool get _hasBorder => widget.variant == _ButtonVariant.secondary;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isDisabled
          ? null
          : (_) {
              setState(() => _pressed = true);
              AppHaptics.selectionClick();
            },
      onTapUp: _isDisabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            },
      onTapCancel:
          _isDisabled ? null : () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isDisabled ? 0.45 : (_pressed ? 0.75 : 1.0),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: AppRadius.circularMd,
            border: _hasBorder
                ? Border.all(color: AppColors.accent, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: widget.isLoading
              ? const CupertinoActivityIndicator()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      widget.label,
                      style: AppTypography.headline.copyWith(color: _fg),
                    ),
                  ],
                ),
        ),
      ),
    ).animate(target: _pressed ? 1 : 0).scale(
          end: const Offset(0.97, 0.97),
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
  }
}
