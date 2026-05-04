import 'package:flutter/cupertino.dart';

/// Semantic color tokens — use these in all UI code, never raw hex values.
///
/// Light values are the defaults; dark overrides are provided for system-dark-mode
/// support in future. For Phase 0 the app is locked to light mode.
abstract class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const accent = Color(0xFFF5A623); // EvolvePRO amber
  static const accentDark = Color(0xFFE6930A); // pressed / darker amber

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const background = Color(0xFFF2F2F7); // iOS system grouped bg
  static const surface = Color(0xFFFFFFFF); // card / sheet surface
  static const surfaceElevated = Color(0xFFFFFFFF); // elevated card

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF636366);
  static const textTertiary = Color(0xFFAEAEB2);
  static const textOnAccent = Color(0xFFFFFFFF);

  // ── Separators ────────────────────────────────────────────────────────────
  static const separator = Color(0xFFC6C6C8);
  static const separatorOpaque = Color(0xFFE5E5EA);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const success = Color(0xFF34C759); // iOS green
  static const warning = Color(0xFFFF9500); // iOS orange
  static const danger = Color(0xFFFF3B30); // iOS red

  // ── Aliases (Apple naming conventions used across screens) ────────────────
  static const label = textPrimary; // primary label alias
  static const error = danger;      // error alias

  // ── Map ───────────────────────────────────────────────────────────────────
  static const markerAvailable = Color(0xFF34C759);
  static const markerBusy = Color(0xFFFF9500);
  static const markerOffline = Color(0xFF8E8E93);
  static const mapOverlayScrim = Color(0x66000000);

  // ── Navigation bar ────────────────────────────────────────────────────────
  static const navBarBackground = Color(0xFFF9F9F9);

  // ── Dark-mode equivalents (used when dark theme is active) ────────────────
  static const backgroundDark = Color(0xFF1C1C1E);
  static const surfaceDark = Color(0xFF2C2C2E);
  static const surfaceElevatedDark = Color(0xFF3A3A3C);
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFAEAEB2);
}
