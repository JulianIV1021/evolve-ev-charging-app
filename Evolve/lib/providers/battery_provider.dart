import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ev_profile_model.dart';
import 'station_providers.dart';

/// Reads the phone battery level once and returns it as a fraction (0.0–1.0).
/// Falls back to 0.8 if unavailable.
///
/// This is the ONLY place that knows about the battery data source.
/// To swap in a real EV API or OBD connection in the future,
/// replace the body of this provider — nothing else needs to change.
final phoneBatterySocProvider = FutureProvider<double>((ref) async {
  try {
    final level = await Battery().batteryLevel; // 0–100
    return (level / 100.0).clamp(0.0, 1.0);
  } catch (_) {
    return 0.8;
  }
});

/// The canonical EVProfile used throughout the app.
///
/// All vehicle fields (make, model, capacity, connectors) come from Firestore.
/// [currentSocPercent] is mocked from the phone battery until a real
/// EV API or OBD connection is wired in — at which point only
/// [phoneBatterySocProvider] above needs to change.
final effectiveEvProfileProvider = Provider<EVProfile>((ref) {
  final base = ref.watch(evProfileProvider).valueOrNull ?? const EVProfile();
  final phoneSoc = ref.watch(phoneBatterySocProvider).valueOrNull ?? 0.8;
  return base.copyWith(currentSocPercent: phoneSoc);
});
