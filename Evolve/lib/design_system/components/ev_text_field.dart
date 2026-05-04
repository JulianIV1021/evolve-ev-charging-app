import 'package:flutter/cupertino.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// iOS-native text field with optional prefix/suffix icons and error text.
class EvTextField extends StatelessWidget {
  const EvTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
    this.autocorrect = true,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String placeholder;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autocorrect;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        errorText != null ? AppColors.danger : AppColors.separatorOpaque;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autocorrect: autocorrect,
          autofocus: autofocus,
          enabled: enabled,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          placeholderStyle:
              AppTypography.body.copyWith(color: AppColors.textTertiary),
          prefix: prefixIcon != null
              ? Padding(
                  padding:
                      const EdgeInsets.only(left: AppSpacing.lg),
                  child: prefixIcon,
                )
              : null,
          suffix: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: suffixIcon,
                )
              : null,
          padding: EdgeInsets.symmetric(
            horizontal: prefixIcon != null ? AppSpacing.sm : AppSpacing.lg,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.circularMd,
            border: Border.all(color: borderColor, width: 1),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Text(
              errorText!,
              style: AppTypography.footnote.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ],
    );
  }
}
