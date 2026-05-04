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

enum _NavFlowMode { preview, active }

class NavigationFlowScreen extends ConsumerStatefulWidget {
  const NavigationFlowScreen({super.key});

  @override
  ConsumerState<NavigationFlowScreen> createState() =>
      _NavigationFlowScreenState();
}

class _NavigationFlowScreenState extends ConsumerState<NavigationFlowScreen> {
  GoogleMapController? _mapController;
  _NavFlowMode _mode = _NavFlowMode.preview;
  StreamSubscription<NavigationState>? _navSub;
  NavigationState _navState = const NavigationState(phase: NavigationPhase.active);
  bool _arrived = false;

  @override
  void dispose() {
    _navSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController c) {
    _mapController = c;
    final route = ref.read(selectedRouteProvider);
    if (route == null || route.polylinePoints.length < 2) return;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || _mapController == null) return;
      _fitRouteBounds(route.polylinePoints);
    });
  }

  /// Fits the route polyline into the visible map area, accounting for the
  /// top navigation bar and the bottom stats panel so neither overlay hides
  /// the route endpoints.
  void _fitRouteBounds(List<LatLng> points) {
    final base = _boundsFor(points);
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    // topInset: status bar (varies per device) + nav pill height
    final topInset = padding.top + 90.0;
    // bottomInset: bottom safe area (gesture bar / home indicator) + panel content
    final bottomInset = padding.bottom + 250.0;
    const sidePad = 50.0;
    const breathing = 24.0;

    final h = screen.height;
    // Target screen-y positions for the route's north and south extents
    final yn = topInset + breathing;           // route NORTH should appear here
    final ys = h - bottomInset - breathing;    // route SOUTH should appear here
    final mapH = h - 2 * sidePad;

    final latSpan = base.northeast.latitude - base.southwest.latitude;
    // Scale extended lat span so the route fills exactly (yn→ys) of screen
    final extLatSpan = latSpan * mapH / (ys - yn).clamp(1.0, double.infinity);
    // Shift extended NE northward so the route's NE aligns with yn
    final extNELat = base.northeast.latitude +
        extLatSpan * (yn - sidePad) / mapH;

    final adjusted = LatLngBounds(
      southwest: LatLng(extNELat - extLatSpan, base.southwest.longitude),
      northeast: LatLng(extNELat, base.northeast.longitude),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(adjusted, sidePad),
    );
  }

  void _startNavigation() {
    AppHaptics.mediumImpact();
    setState(() => _mode = _NavFlowMode.active);
    // Immediately tilt the camera — don't wait for the first GPS stream event,
    // which can take several seconds and leave the screen in flat preview mode.
    _snapCameraToNavMode();
    _beginNavTracking();
  }

  void _snapCameraToNavMode() {
    if (_mapController == null) return;
    final route = ref.read(selectedRouteProvider);
    final origin = route?.polylinePoints.firstOrNull;
    if (origin == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: origin,
          zoom: 17,
          tilt: 45,
          bearing: 0,
        ),
      ),
    );
  }

  void _beginNavTracking() {
    final route = ref.read(selectedRouteProvider);
    if (route == null) return;
    final svc = ref.read(navigationServiceProvider);
    _navSub = svc.startNavigation(route).listen((state) {
      if (!mounted) return;
      setState(() => _navState = state);
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

  LatLngBounds _boundsFor(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  (String, IconData, Color) _modeStyle(RouteMode mode) => switch (mode) {
        RouteMode.fastest => (
          'Fastest Route',
          CupertinoIcons.timer,
          const Color(0xFFF5A623),
        ),
        RouteMode.cheapest => (
          'Most Efficient',
          CupertinoIcons.arrow_down_circle_fill,
          const Color(0xFF34C759),
        ),
        RouteMode.greenest => (
          'Greenest Route',
          CupertinoIcons.leaf_arrow_circlepath,
          const Color(0xFF34C759),
        ),
      };

  @override
  Widget build(BuildContext context) {
    final route = ref.watch(selectedRouteProvider);

    if (route == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: route.polylinePoints,
      color: AppColors.accent,
      width: 5,
    );

    final markers = <Marker>{};
    if (route.polylinePoints.isNotEmpty) {
      markers.add(Marker(
        markerId: const MarkerId('origin'),
        position: route.polylinePoints.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
      markers.add(Marker(
        markerId: const MarkerId('dest'),
        position: route.polylinePoints.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    final initial = route.polylinePoints.isNotEmpty
        ? route.polylinePoints.first
        : const LatLng(14.5995, 120.9842);

    final (modeLabel, modeIcon, modeColor) = _modeStyle(route.mode);

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // ── Single GoogleMap — lives for the entire flow ─────────────────
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: initial,
                zoom: 12,
              ),
              polylines: {polyline},
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              buildingsEnabled: false,
            ),
          ),

          // ── Overlays swap on mode change ─────────────────────────────────
          if (_mode == _NavFlowMode.preview) ...[
            // Preview: top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          AppHaptics.selectionClick();
                          context.pop();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(99.0),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.label.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.chevron_back,
                            color: AppColors.label,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(99.0),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.label.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(modeIcon, size: 16, color: modeColor),
                            const SizedBox(width: 6),
                            Text(
                              modeLabel,
                              style: AppTypography.subhead.copyWith(
                                color: AppColors.label,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Recenter button — re-fits the full route into view
                      GestureDetector(
                        onTap: () {
                          AppHaptics.lightImpact();
                          _fitRouteBounds(route.polylinePoints);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(99.0),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.label.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.viewfinder,
                            color: AppColors.label,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Preview: bottom summary panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.label.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatChip(
                              icon: CupertinoIcons.timer,
                              label: '${route.eta.inMinutes} min',
                              color: AppColors.label,
                            ),
                            _FlowDivider(),
                            _StatChip(
                              icon: CupertinoIcons.location_fill,
                              label:
                                  '${route.distanceKm.toStringAsFixed(1)} km',
                              color: AppColors.label,
                            ),
                            _FlowDivider(),
                            _StatChip(
                              icon: CupertinoIcons.bolt_fill,
                              label:
                                  '${route.estimatedEnergyKwh.toStringAsFixed(1)} kWh',
                              color: AppColors.label,
                            ),
                            _FlowDivider(),
                            _StatChip(
                              icon: CupertinoIcons.battery_25,
                              label:
                                  'Arrive ${(route.estimatedArrivalSocPercent * 100).toInt()}%',
                              color:
                                  route.estimatedArrivalSocPercent < 0.15
                                      ? AppColors.error
                                      : AppColors.success,
                            ),
                          ],
                        ),
                        if (route.chargingStops.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color:
                                    AppColors.warning.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons
                                      .exclamationmark_triangle_fill,
                                  size: 14,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Charging stop needed along this route',
                                  style: AppTypography.caption1.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        EvButton.primary(
                          'Start Navigation',
                          onPressed: _startNavigation,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Active nav: top instruction card
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

            // Active nav: bottom panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _arrived
                    ? _ArrivedPanel(onDone: () => context.pop())
                    : _NavBottomPanel(route: route, onStop: _stopNavigation),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption1.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

class _FlowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: AppColors.separatorOpaque,
      );
}

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
                    style:
                        AppTypography.headline.copyWith(color: AppColors.label),
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
    if (etaRemaining != null) parts.add('${etaRemaining!.inMinutes} min');
    if (distanceRemaining != null) {
      parts.add('${distanceRemaining!.toStringAsFixed(1)} km');
    }
    return parts.join(' · ');
  }
}

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavStat(label: 'Mode', value: _modeLabel(route.mode)),
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
              style:
                  AppTypography.headline.copyWith(color: AppColors.label)),
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
            Text(
              'Scan the QR code on the charger to begin charging.',
              style: AppTypography.subhead
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            EvButton.primary('Done', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
