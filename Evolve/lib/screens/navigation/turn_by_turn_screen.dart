import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../design_system/components/ev_button.dart';
import '../../design_system/haptics/haptics.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radius.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../models/route_option_model.dart';
import '../../providers/navigation_providers.dart';
import '../../utils/app_logger.dart';

class TurnByTurnScreen extends ConsumerStatefulWidget {
  const TurnByTurnScreen({super.key});

  @override
  ConsumerState<TurnByTurnScreen> createState() => _TurnByTurnScreenState();
}

class _TurnByTurnScreenState extends ConsumerState<TurnByTurnScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<NavigationState>? _navSub;
  NavigationState _navState = const NavigationState(phase: NavigationPhase.active);
  bool _arrived = false;

  @override
  void initState() {
    super.initState();
    _startNavigation();
  }

  @override
  void dispose() {
    _navSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startNavigation() {
    final route = ref.read(selectedRouteProvider);
    if (route == null) return;

    final svc = ref.read(navigationServiceProvider);
    _navSub = svc.startNavigation(route).listen((state) {
      if (!mounted) return;
      setState(() => _navState = state);

      // First real GPS fix → zoom in and follow user
      if (state.currentPosition != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: state.currentPosition!,
              zoom: 17,
              tilt: 45,
            ),
          ),
        );
      }

      if (state.phase == NavigationPhase.arrived) {
        AppHaptics.notificationSuccess();
        setState(() => _arrived = true);
        AppLogger.instance.info('navigation_arrived');
      }
    });

    AppLogger.instance.info('navigation_started', {
      'mode': route.mode.name,
      'distance_km': route.distanceKm,
    });
  }

  void _stopNavigation() {
    AppHaptics.selectionClick();
    final svc = ref.read(navigationServiceProvider);
    svc.stopNavigation();
    _navSub?.cancel();
    AppLogger.instance.info('navigation_cancelled_by_user');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final route = ref.watch(selectedRouteProvider);

    if (route == null) {
      return const CupertinoPageScaffold(
        child: Center(child: Text('No active route')),
      );
    }

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Fullscreen map
          Positioned.fill(
            child: _NavMap(
              route: route,
              currentPosition: _navState.currentPosition,
              onMapCreated: (c) => _mapController = c,
            ),
          ),

          // Top instruction card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _InstructionCard(
                phase: _navState.phase,
                instruction: _navState.currentInstruction,
                etaRemaining: _navState.etaRemaining,
                distanceRemaining: _navState.distanceRemainingKm,
              ),
            ),
          ),

          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _arrived
                  ? _ArrivedPanel(onDone: () => Navigator.of(context).pop())
                  : _NavBottomPanel(
                      route: route,
                      onStop: _stopNavigation,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map
// ---------------------------------------------------------------------------

class _NavMap extends StatelessWidget {
  const _NavMap({
    required this.route,
    required this.currentPosition,
    required this.onMapCreated,
  });

  final RouteOption route;
  final LatLng? currentPosition;
  final void Function(GoogleMapController) onMapCreated;

  @override
  Widget build(BuildContext context) {
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: route.polylinePoints,
      color: AppColors.accent,
      width: 5,
    );

    final initial = route.polylinePoints.isNotEmpty
        ? route.polylinePoints.first
        : const LatLng(14.5995, 120.9842); // Manila fallback

    final markers = <Marker>{};
    if (currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('user'),
        position: currentPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }
    if (route.polylinePoints.isNotEmpty) {
      markers.add(Marker(
        markerId: const MarkerId('dest'),
        position: route.polylinePoints.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(
        target: currentPosition ?? initial,
        zoom: 15,
        tilt: 45,
      ),
      polylines: {polyline},
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      buildingsEnabled: false,
    );
  }
}

// ---------------------------------------------------------------------------
// Instruction card (top)
// ---------------------------------------------------------------------------

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.phase,
    required this.instruction,
    required this.etaRemaining,
    required this.distanceRemaining,
  });

  final NavigationPhase phase;
  final String? instruction;
  final Duration? etaRemaining;
  final double? distanceRemaining;

  @override
  Widget build(BuildContext context) {
    final icon = switch (phase) {
      NavigationPhase.rerouting => CupertinoIcons.arrow_2_circlepath,
      NavigationPhase.arrived => CupertinoIcons.checkmark_circle_fill,
      _ => CupertinoIcons.arrow_up,
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.label.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.surface, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    instruction ?? _phaseLabel(phase),
                    style: AppTypography.headline.copyWith(color: AppColors.label),
                  ),
                  if (etaRemaining != null || distanceRemaining != null)
                    Text(
                      _buildSubtitle(),
                      style: AppTypography.subhead
                          .copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(NavigationPhase p) => switch (p) {
        NavigationPhase.rerouting => 'Recalculating…',
        NavigationPhase.arrived => 'You have arrived',
        NavigationPhase.cancelled => 'Navigation stopped',
        _ => 'Navigating',
      };

  String _buildSubtitle() {
    final parts = <String>[];
    if (etaRemaining != null) {
      parts.add('${etaRemaining!.inMinutes} min');
    }
    if (distanceRemaining != null) {
      parts.add('${distanceRemaining!.toStringAsFixed(1)} km');
    }
    return parts.join(' · ');
  }
}

// ---------------------------------------------------------------------------
// Bottom panels
// ---------------------------------------------------------------------------

class _NavBottomPanel extends StatelessWidget {
  const _NavBottomPanel({required this.route, required this.onStop});
  final RouteOption route;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.label.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Route summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavStat(
                  label: 'Mode',
                  value: _modeLabel(route.mode),
                ),
                _NavStat(
                  label: 'Distance',
                  value: '${route.distanceKm.toStringAsFixed(1)} km',
                ),
                _NavStat(
                  label: 'Energy',
                  value: '${route.estimatedEnergyKwh.toStringAsFixed(1)} kWh',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            EvButton.destructive('Stop Navigation', onPressed: onStop),
          ],
        ),
      ),
    );
  }

  String _modeLabel(RouteMode m) => switch (m) {
        RouteMode.fastest => 'Fastest',
        RouteMode.cheapest => 'Efficient',
        RouteMode.greenest => 'Greenest',
      };
}

class _NavStat extends StatelessWidget {
  const _NavStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: AppTypography.headline.copyWith(color: AppColors.label)),
          Text(label,
              style: AppTypography.caption1
                  .copyWith(color: AppColors.textSecondary)),
        ],
      );
}

class _ArrivedPanel extends StatelessWidget {
  const _ArrivedPanel({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.checkmark_circle_fill,
                size: 48, color: AppColors.success),
            const SizedBox(height: AppSpacing.sm),
            Text('You have arrived!',
                style: AppTypography.title3.copyWith(color: AppColors.label)),
            const SizedBox(height: AppSpacing.xs),
            Text('Scan the QR code on the charger to begin charging.',
                style: AppTypography.subhead
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            EvButton.primary('Done', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
