import 'package:flutter/cupertino.dart';

/// iOS-calibrated animation durations and curves.
abstract class AppMotion {
  /// 120 ms — button press, badge update.
  static const fast = Duration(milliseconds: 120);

  /// 180 ms — sheet snap, tab switch.
  static const normal = Duration(milliseconds: 180);

  /// 240 ms — screen transition, card expand.
  static const slow = Duration(milliseconds: 240);

  /// iOS-style ease-out curve (feels natural on spring-loaded elements).
  static const easeOut = Curves.easeOutCubic;

  /// iOS-style ease-in-out (page transitions, sheet drags).
  static const easeInOut = Curves.easeInOutCubic;

  /// Bouncy spring for map marker taps.
  static const spring = Curves.elasticOut;
}
