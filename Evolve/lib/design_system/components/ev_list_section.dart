import 'package:flutter/cupertino.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// Cupertino-style grouped list section with header and footer labels.
class EvListSection extends StatelessWidget {
  const EvListSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin,
  });

  final List<Widget> children;
  final String? header;
  final String? footer;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: header != null
          ? Text(header!, style: AppTypography.footnote)
          : null,
      footer: footer != null
          ? Text(footer!, style: AppTypography.caption1)
          : null,
      margin: margin,
      children: children,
    );
  }
}

/// A single row inside [EvListSection].
class EvListRow extends StatelessWidget {
  const EvListRow({
    super.key,
    required this.label,
    this.value,
    this.leading,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final String? value;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile.notched(
      title: Text(
        label,
        style: AppTypography.body.copyWith(
          color: isDestructive ? AppColors.danger : AppColors.textPrimary,
        ),
      ),
      subtitle: value != null
          ? Text(value!, style: AppTypography.subhead)
          : null,
      leading: leading,
      trailing: trailing ??
          (onTap != null
              ? const Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.textTertiary,
                )
              : null),
      onTap: onTap,
    );
  }
}
