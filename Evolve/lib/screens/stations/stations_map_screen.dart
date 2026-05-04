import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../design/components/map_marker_painter.dart';
import '../../design_system/components/ev_sheet.dart';
import '../../design_system/haptics/haptics.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radius.dart';
import '../../design_system/tokens/shadows.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../models/station_model.dart';
import '../../providers/station_providers.dart';
import '../../utils/app_logger.dart';
import 'filter_sheet.dart';
import 'station_detail_sheet.dart';

// ── Main screen ───────────────────────────────────────────────────────────────
//
// Watches only stationFilterProvider (overlay data).
// Station data is watched exclusively inside _StationsGoogleMap, so
// Firestore station ticks do not trigger a parent rebuild.

class StationsMapScreen extends ConsumerStatefulWidget {
  const StationsMapScreen({super.key});

  @override
  ConsumerState<StationsMapScreen> createState() => _StationsMapScreenState();
}

class _StationsMapScreenState extends ConsumerState<StationsMapScreen>
    with AutomaticKeepAliveClientMixin {
  // Controller passed up from _StationsGoogleMap via onControllerReady
  GoogleMapController? _mapController;
  bool _overlayVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // One-shot overlay entry animation — single setState, no station data involved
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _overlayVisible = true);
    });
    // Search-tab → map: pan camera to station then show detail sheet
    ref.listenManual<String?>(selectedStationIdProvider, (_, stationId) {
      if (stationId == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(selectedStationIdProvider.notifier).state = null;
        final all = ref.read(allStationsProvider).valueOrNull ?? [];
        final station = all.where((s) => s.id == stationId).firstOrNull;
        if (station != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(station.latLng, 15),
          );
        }
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _showStationDetail(stationId);
        });
      });
    });
  }

  // Receives the GoogleMapController from the child widget
  void _onControllerReady(GoogleMapController c) {
    _mapController = c;
    ref.read(mapReadyProvider.notifier).state = true;
  }

  void _showStationDetail(String stationId) {
    EvSheet.show(
      context: context,
      child: StationDetailSheetContent(stationId: stationId),
    );
  }

  Future<void> _locateMe() async {
    AppHaptics.lightImpact();

    // 1. Instant pan using the value already fetched at app start
    final cached = ref.read(userLocationProvider).valueOrNull;
    if (cached != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(cached, 15.5),
      );
      return;
    }

    // 2. No cached value yet — request a fresh fix (low accuracy = fast)
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15.5),
      );
    } catch (_) {
      // Location unavailable or timed out — nothing to do
    }
  }

  void _openFilters() {
    AppHaptics.lightImpact();
    EvSheet.show(
      context: context,
      title: 'Filter Stations',
      child: const FilterSheetContent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    // Narrowed dependency: only filter state for overlay badges.
    // Station data changes do not trigger this build.
    final filter = ref.watch(stationFilterProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          // ── Map subtree ─────────────────────────────────────────────────
          // Isolated ConsumerStatefulWidget: only rebuilds on station data
          // or GPS changes, not on overlay-only setState calls.
          _StationsGoogleMap(
            onControllerReady: _onControllerReady,
            onStationTap: _showStationDetail,
          ),

          // ── Top overlay: search pill + filter badge ─────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Column(
              children: [
                // Search pill — one-shot entry animation
                AnimatedSlide(
                  offset:
                      _overlayVisible ? Offset.zero : const Offset(0, -0.3),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _overlayVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: () => context.go('/shell/search'),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.circularLg,
                          boxShadow: AppShadows.overlay,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.search,
                              color: AppColors.textTertiary,
                              size: 17,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Search stations…',
                              style: AppTypography.callout
                                  .copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Filter badge — IgnorePointer prevents hidden badge from
                // intercepting taps on the map underneath
                IgnorePointer(
                  ignoring: filter.isDefault,
                  child: AnimatedOpacity(
                    opacity: filter.isDefault ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _openFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: AppRadius.circularLg,
                          ),
                          child: Text(
                            'Filters active',
                            style: AppTypography.footnote
                                .copyWith(color: AppColors.textOnAccent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom-right FABs ────────────────────────────────────────────
          Positioned(
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            right: AppSpacing.lg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapFab(
                  icon: CupertinoIcons.slider_horizontal_3,
                  onTap: _openFilters,
                  badge: !filter.isDefault,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MapFab(
                  icon: CupertinoIcons.location_fill,
                  onTap: _locateMe,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Isolated Google Map widget ─────────────────────────────────────────────────
//
// Watches filteredStationsProvider and userLocationProvider only.
// Parent overlay state changes (filter badge, _overlayVisible) do NOT cause
// this widget to watch new data — it only rebuilds when station data changes.
// Marker memoization ensures the same Set<Marker> instance is returned when
// the station list is unchanged, preventing native bridge marker updates.

class _StationsGoogleMap extends ConsumerStatefulWidget {
  const _StationsGoogleMap({
    required this.onControllerReady,
    required this.onStationTap,
  });

  final ValueChanged<GoogleMapController> onControllerReady;
  final ValueChanged<String> onStationTap;

  @override
  ConsumerState<_StationsGoogleMap> createState() => _StationsGoogleMapState();
}

class _StationsGoogleMapState extends ConsumerState<_StationsGoogleMap> {
  // ── Marker descriptor cache — static so preloadAll() runs once per session
  static Map<String, BitmapDescriptor>? _cachedDescriptors;
  Map<String, BitmapDescriptor>? _descriptors;

  GoogleMapController? _mapController;
  bool _hasAnimatedToUser = false;
  late final AppLifecycleListener _lifecycleListener;

  // ── Marker memoization ─────────────────────────────────────────────────────
  // _sig encodes id + status + location for each station.
  // When the sig matches the previous call, the same Set<Marker> instance is
  // returned — GoogleMap.didUpdateWidget sees markers == oldMarkers and skips
  // the native update.
  String _lastMarkerSig = '';
  Set<Marker> _cachedMarkers = {};

  @override
  void initState() {
    super.initState();
    _loadDescriptors();
    // Re-check location when app returns from background (e.g. user went to
    // Settings to grant permission after initially denying it).
    _lifecycleListener = AppLifecycleListener(
      onResume: () => ref.invalidate(userLocationProvider),
    );
  }

  Future<void> _loadDescriptors() async {
    if (_cachedDescriptors != null) {
      if (mounted) setState(() => _descriptors = _cachedDescriptors);
      return;
    }
    final m = await MapMarkerPainter.preloadAll();
    _cachedDescriptors = m;
    if (mounted) setState(() => _descriptors = m);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  BitmapDescriptor _iconFor(StationStatus status) {
    if (_descriptors == null || _descriptors!.isEmpty) {
      return BitmapDescriptor.defaultMarkerWithHue(
        switch (status) {
          StationStatus.available => BitmapDescriptor.hueGreen,
          StationStatus.busy => BitmapDescriptor.hueOrange,
          StationStatus.offline => BitmapDescriptor.hueRed,
        },
      );
    }
    return switch (status) {
      StationStatus.available => _descriptors!['available']!,
      StationStatus.busy => _descriptors!['busy']!,
      StationStatus.offline => _descriptors!['offline']!,
    };
  }

  /// Lightweight string covering every field that affects marker rendering:
  /// descriptor load state, station id, status, and position.
  String _sig(List<StationModel> stations) {
    final buf = StringBuffer(_descriptors != null ? '1:' : '0:');
    for (final s in stations) {
      buf.write(
        '${s.id}:${s.status.index}:${s.location.latitude},${s.location.longitude};',
      );
    }
    return buf.toString();
  }

  /// Returns cached markers when the signature is unchanged.
  /// Rebuilds the full marker set only when station data or descriptors change.
  Set<Marker> _markersFor(List<StationModel> stations) {
    final sig = _sig(stations);
    if (sig == _lastMarkerSig) return _cachedMarkers;
    _lastMarkerSig = sig;
    _cachedMarkers = stations.map((s) {
      return Marker(
        markerId: MarkerId(s.id),
        position: s.latLng,
        icon: _iconFor(s.status),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow.noText,
        onTap: () {
          AppHaptics.lightImpact();
          AppLogger.instance
              .info('station_detail_opened', {'station_id': s.id});
          widget.onStationTap(s.id);
        },
      );
    }).toSet();
    return _cachedMarkers;
  }

  @override
  Widget build(BuildContext context) {
    final stations = ref.watch(filteredStationsProvider);
    final userLoc = ref.watch(userLocationProvider).valueOrNull;

    // One-shot camera animation: fires once after both GPS and map are ready
    if (userLoc != null && !_hasAnimatedToUser && _mapController != null) {
      _hasAnimatedToUser = true;
      Future.microtask(() {
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLoc, 15.5));
      });
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: userLoc ?? const LatLng(14.5995, 120.9842),
        zoom: userLoc != null ? 15.5 : 13,
      ),
      myLocationEnabled: userLoc != null,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      mapType: MapType.normal,
      markers: _markersFor(stations),
      onMapCreated: (c) {
        _mapController = c;
        widget.onControllerReady(c);
        AppLogger.instance.info('station_markers_rendered', {
          'count': stations.length,
        });
      },
    );
  }
}

// ── Map floating action button ─────────────────────────────────────────────────

class _MapFab extends StatelessWidget {
  const _MapFab({required this.icon, required this.onTap, this.badge = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppShadows.overlay,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            if (badge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
