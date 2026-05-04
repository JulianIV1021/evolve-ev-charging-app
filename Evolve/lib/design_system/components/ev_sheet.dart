import 'package:flutter/cupertino.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/shadows.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Apple Maps-style draggable bottom sheet using modal_bottom_sheet.
///
/// Snaps at: collapsed 30%, mid 60%, expanded 92% of screen height.
/// Includes drag handle, safe-area bottom padding, and iOS haptic dismiss.
class EvSheet extends StatelessWidget {
  const EvSheet({
    super.key,
    required this.child,
    this.title,
    this.backgroundColor = AppColors.surface,
  });

  final Widget child;
  final String? title;
  final Color backgroundColor;

  /// Show as a Cupertino modal bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
  }) {
    return showCupertinoModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      backgroundColor: AppColors.surface,
      topRadius: const Radius.circular(AppRadius.xl),
      shadow: AppShadows.sheet.first,
      builder: (context) => EvSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.topXl,
      child: Container(
      color: backgroundColor,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.separator,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title!, style: AppTypography.title2),
                ),
              )
            else
              const SizedBox(height: AppSpacing.sm),

            child,
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
      ),
    );
  }
}
