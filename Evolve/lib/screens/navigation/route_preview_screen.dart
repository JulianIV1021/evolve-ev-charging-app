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

class RoutePreviewScreen extends ConsumerStatefulWidget {
  const RoutePreviewScreen({super.key});

  @override
  ConsumerState<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends ConsumerState<RoutePreviewScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Guard: if somehow we land here with no route, go back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(selectedRouteProvider) == null) {
        context.pop();
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController c) {
    _mapController = c;
    final route = ref.read(selectedRouteProvider);
    if (route == null || route.polylinePoints.length < 2) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || _mapController == null) return;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFor(route.polylinePoints), 80),
      );
    });
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

  @override
  Widget build(BuildContext context) {
    final route = ref.watch(selectedRouteProvider);
    if (route == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final (modeLabel, modeIcon, modeColor) = _modeStyle(route.mode);

    final polyline = Polyline(
      polylineId: const PolylineId('preview'),
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

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // ── Fullscreen map (overhead, no tilt) ──────────────────────────────
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
            ),
          ),

          // ── Top bar ─────────────────────────────────────────────────────────
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
                    // Back button
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
                    // Mode pill
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
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom summary panel ─────────────────────────────────────────────
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
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatChip(
                            icon: CupertinoIcons.timer,
                            label: '${route.eta.inMinutes} min',
                            color: AppColors.label,
                          ),
                          _Divider(),
                          _StatChip(
                            icon: CupertinoIcons.location_fill,
                            label: '${route.distanceKm.toStringAsFixed(1)} km',
                            color: AppColors.label,
                          ),
                          _Divider(),
                          _StatChip(
                            icon: CupertinoIcons.bolt_fill,
                            label: '${route.estimatedEnergyKwh.toStringAsFixed(1)} kWh',
                            color: AppColors.label,
                          ),
                          _Divider(),
                          _StatChip(
                            icon: CupertinoIcons.battery_25,
                            label:
                                'Arrive ${(route.estimatedArrivalSocPercent * 100).toInt()}%',
                            color: route.estimatedArrivalSocPercent < 0.15
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ],
                      ),

                      // Charging stop warning
                      if (route.chargingStops.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
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
                        onPressed: () {
                          AppHaptics.mediumImpact();
                          context.push('/navigation');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, IconData, Color) _modeStyle(RouteMode mode) => switch (mode) {
        RouteMode.fastest => (
          'Fastest Route',
          CupertinoIcons.timer,
          const Color(0xFFF5A623)
        ),
        RouteMode.cheapest => (
          'Most Efficient',
          CupertinoIcons.arrow_down_circle_fill,
          const Color(0xFF34C759)
        ),
        RouteMode.greenest => (
          'Greenest Route',
          CupertinoIcons.leaf_arrow_circlepath,
          const Color(0xFF34C759)
        ),
      };
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: AppColors.separatorOpaque,
      );
}
