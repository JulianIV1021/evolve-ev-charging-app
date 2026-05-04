import 'package:flutter/cupertino.dart';

/// All visual constants for EvolvePRO. Never hardcode colors, sizes, or font
/// sizes in widget files — always reference a token here.
class EvroColors {
  EvroColors._();

  static const primary = Color(0xFFF5A623); // EVRO amber/gold
  static const primaryDark = Color(0xFF1A1A2E); // dark navy
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF0F0F1A);
  static const success = Color(0xFF34C759); // iOS green
  static const warning = Color(0xFFFF9500); // iOS orange
  static const error = Color(0xFFFF3B30); // iOS red
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF636366);
  static const separator = Color(0xFFC6C6C8);
  static const background = Color(0xFFF2F2F7); // iOS grouped background
  static const markerAvailable = Color(0xFF34C759);
  static const markerBusy = Color(0xFFFF9500);
  static const markerOffline = Color(0xFF8E8E93);

  // Dark-mode equivalents
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFAEAEB2);
  static const surfaceElevatedDark = Color(0xFF1C1C1E);
  static const backgroundDark = Color(0xFF050A12);
}

class EvroTypography {
  EvroTypography._();

  static const largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
  );
  static const title1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
  static const title2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
  static const headline = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 17, fontWeight: FontWeight.w400);
  static const callout = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static const subheadline =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w400);
  static const footnote = TextStyle(fontSize: 13, fontWeight: FontWeight.w400);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
}

class EvroSpacing {
  EvroSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class EvroRadius {
  EvroRadius._();

  static const sm = Radius.circular(8);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(16);
  static const xl = Radius.circular(24);
  static const smValue = 8.0;
  static const mdValue = 12.0;
  static const lgValue = 16.0;
  static const xlValue = 24.0;
}
