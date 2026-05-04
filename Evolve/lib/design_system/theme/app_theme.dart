import 'package:flutter/cupertino.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// App-wide Cupertino theme configuration.
abstract class AppTheme {
  // ── Cupertino light (default for all screens) ─────────────────────────────
  static const cupertinoLight = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.accent,
    scaffoldBackgroundColor: AppColors.background,
    barBackgroundColor: AppColors.navBarBackground,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.accent,
      textStyle: AppTypography.body,
      navTitleTextStyle: AppTypography.headline,
      navLargeTitleTextStyle: AppTypography.largeTitle,
    ),
  );

  // ── Cupertino dark ────────────────────────────────────────────────────────
  static const cupertinoDark = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.accent,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    barBackgroundColor: AppColors.surfaceDark,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.accent,
      textStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryDark,
      ),
    ),
  );
}
