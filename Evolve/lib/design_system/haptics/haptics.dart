import 'package:flutter/services.dart';

/// Haptic feedback utilities matching iOS HIG patterns.
/// Call from event handlers — never from build methods.
abstract class AppHaptics {
  /// Light — tap, selection change, icon press.
  static Future<void> lightImpact() =>
      HapticFeedback.lightImpact();

  /// Selection — segmented control, radio button.
  static Future<void> selectionClick() =>
      HapticFeedback.selectionClick();

  /// Medium — drag confirm, bottom sheet snap.
  static Future<void> mediumImpact() =>
      HapticFeedback.mediumImpact();

  /// Success — QR scan detected, payment OK, session started.
  static Future<void> notificationSuccess() =>
      HapticFeedback.heavyImpact();

  /// Error — failed action, validation error.
  static Future<void> notificationError() =>
      HapticFeedback.heavyImpact();

  /// Warning — low SoC, station offline alert.
  static Future<void> notificationWarning() =>
      HapticFeedback.mediumImpact();
}
