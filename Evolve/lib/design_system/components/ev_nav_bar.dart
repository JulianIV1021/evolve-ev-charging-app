import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// iOS CupertinoNavigationBar wrapper with consistent EvolvePRO styling.
class EvNavBar extends StatelessWidget implements ObstructingPreferredSizeWidget {
  const EvNavBar({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.showBackButton = true,
    this.backgroundColor = AppColors.navBarBackground,
    this.border,
  });

  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final bool showBackButton;
  final Color backgroundColor;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(
      backgroundColor: backgroundColor,
      border: border,
      leading: leading ??
          (showBackButton && context.canPop()
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.pop(),
                  child: const Icon(
                    CupertinoIcons.back,
                    color: AppColors.accent,
                  ),
                )
              : null),
      middle: title != null
          ? Text(
              title!,
              style: AppTypography.headline,
            )
          : null,
      trailing: trailing,
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kMinInteractiveDimensionCupertino);

  @override
  bool shouldFullyObstruct(BuildContext context) => true;
}
