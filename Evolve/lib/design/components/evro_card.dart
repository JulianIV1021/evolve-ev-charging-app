import 'package:flutter/cupertino.dart';
import '../tokens.dart';

/// Cupertino card with white/dark background, rounded corners, and a
/// subtle shadow. Optionally tappable.
class EvroCard extends StatelessWidget {
  const EvroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(EvroSpacing.md),
    this.onTap,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    const bg = EvroColors.surface;

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(EvroRadius.lgValue),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
