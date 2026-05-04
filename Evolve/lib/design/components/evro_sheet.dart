import 'package:flutter/cupertino.dart';
import '../tokens.dart';

/// DraggableScrollableSheet with Cupertino styling, drag handle, and
/// configurable initial/min/max size.
class EvroSheet extends StatelessWidget {
  const EvroSheet({
    super.key,
    required this.child,
    this.initialSize = 0.5,
    this.minSize = 0.3,
    this.maxSize = 0.95,
    this.title,
  });

  final Widget child;
  final double initialSize;
  final double minSize;
  final double maxSize;
  final String? title;

  /// Call this from a button to show the sheet as a modal.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double initialSize = 0.5,
    double minSize = 0.3,
    double maxSize = 0.95,
    String? title,
  }) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (_) => EvroSheet(
        initialSize: initialSize,
        minSize: minSize,
        maxSize: maxSize,
        title: title,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = EvroColors.surface;

    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.only(
              topLeft: EvroRadius.xl,
              topRight: EvroRadius.xl,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: EvroSpacing.sm),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EvroColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EvroSpacing.md,
                    vertical: EvroSpacing.sm,
                  ),
                  child: Text(title!, style: EvroTypography.title2),
                ),
              ] else
                const SizedBox(height: EvroSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: EvroSpacing.md,
                    vertical: EvroSpacing.sm,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
