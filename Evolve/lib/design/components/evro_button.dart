import 'package:flutter/cupertino.dart';
import '../tokens.dart';

/// Primary action button — Cupertino styled, 52 px tall, EVRO amber fill.
///
/// Set [isDestructive] for red destructive actions.
/// Set [isLoading] to replace label with a spinner.
/// Set [secondary] for an outlined/secondary style.
class EvroButton extends StatelessWidget {
  const EvroButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.isDestructive = false,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDestructive;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final bg = isDestructive
        ? EvroColors.error
        : secondary
            ? CupertinoColors.secondarySystemBackground.resolveFrom(context)
            : EvroColors.primary;

    final fg = secondary && !isDestructive
        ? EvroColors.primary
        : CupertinoColors.white;

    return GestureDetector(
      onTap: (isLoading || onTap == null) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(EvroRadius.mdValue),
          border: secondary && !isDestructive
              ? Border.all(color: EvroColors.primary, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: isLoading
            ? CupertinoActivityIndicator(color: fg)
            : Text(
                label,
                style: EvroTypography.headline.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
