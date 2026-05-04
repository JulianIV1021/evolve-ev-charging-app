import 'package:flutter/cupertino.dart';
import '../tokens.dart';

/// iOS-style text field using CupertinoTextField, 52 px tall.
class EvroTextField extends StatelessWidget {
  const EvroTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
    this.autocorrect = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String placeholder;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autocorrect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        errorText != null ? EvroColors.error : EvroColors.separator;

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
          style: EvroTypography.body.copyWith(
            color: EvroColors.textPrimary,
          ),
          placeholderStyle: EvroTypography.body.copyWith(
            color: EvroColors.textSecondary,
          ),
          prefix: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: EvroSpacing.md),
                  child: prefixIcon,
                )
              : null,
          padding: EdgeInsets.symmetric(
            horizontal: prefixIcon != null ? EvroSpacing.sm : EvroSpacing.md,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(EvroRadius.mdValue),
            border: Border.all(color: borderColor, width: 1),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: EvroSpacing.xs),
          Text(
            errorText!,
            style: EvroTypography.footnote.copyWith(color: EvroColors.error),
          ),
        ],
      ],
    );
  }
}
