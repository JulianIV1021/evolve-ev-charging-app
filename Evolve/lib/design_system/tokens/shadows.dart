import 'package:flutter/cupertino.dart';

/// Subtle iOS-like shadow definitions.
abstract class AppShadows {
  /// Elevation-1 shadow for cards.
  static const card = [
    BoxShadow(
      color: Color(0x14000000), // 8% black
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  /// Elevation-2 shadow for sheets and floating elements.
  static const sheet = [
    BoxShadow(
      color: Color(0x1F000000), // 12% black
      blurRadius: 20,
      offset: Offset(0, -2),
    ),
  ];

  /// Very subtle top-level overlay shadow.
  static const overlay = [
    BoxShadow(
      color: Color(0x29000000), // 16% black
      blurRadius: 30,
      offset: Offset(0, 4),
    ),
  ];
}
