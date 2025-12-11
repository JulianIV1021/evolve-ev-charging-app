import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map_training/common/routes.dart';
import 'package:flutter_map_training/features/stations_feature/widgets/map_utility_buttons.dart';
import 'package:flutter_map_training/features/stations_feature/widgets/search_bar.dart';
import 'package:flutter_map_training/features/stations_feature/widgets/stations_map.dart';
import 'dart:ui' as ui;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/bloc.dart';
import '../models/ocm_station.dart';
import '../screens/route_preview_screen.dart';
import '../../../network/directions_service.dart';
import '../services/pending_charging_intent_store.dart';
import '../services/ocm_favorites_store.dart';
import '../services/station_focus_bus.dart';
import 'charging_screen.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({Key? key}) : super(key: key);

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  bool _myLocationEnabled = false;
  LatLng? _userLocation;
  Set<Polyline> _routePolylines = {};
  String? _routeDistanceText;
  String? _routeDurationText;
  GoogleMapController? _mapController;
  bool _stationSheetOpen = false;
  OcmStation? _pendingFocusStation;

  @override
  void initState() {
    super.initState();
    StationFocusBus.instance.target.addListener(_onExternalFocusRequested);
    _ensureLocationPermission();
    context.read<StationsBloc>().add(StationsRequested());

    final pendingTarget = StationFocusBus.instance.target.value;
    if (pendingTarget != null) {
      Future.microtask(() => _handleExternalFocus(pendingTarget));
    }
  }

  @override
  void dispose() {
    StationFocusBus.instance.target.removeListener(_onExternalFocusRequested);
    super.dispose();
  }

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    if (!mounted) return;

    setState(() {
      _myLocationEnabled = true;
      _userLocation = LatLng(position.latitude, position.longitude);
    });

    context.read<StationsBloc>().add(
          CenterOnUserRequested(
            LatLng(position.latitude, position.longitude),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    const double navBarHeight = 72;

    return Scaffold(
      body: Stack(
        children: [
          StationsMap(
            myLocationEnabled: _myLocationEnabled,
            userLocation: _userLocation,
            onStationSelected: (station) {
              _showStationSheet(station);
            },
            polylines: _routePolylines,
            onMapCreated: (c) {
              _mapController = c;
              context.read<StationsBloc>().initMapController(c);
              _maybeFocusPendingStation();
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final stationBloc = context.read<StationsBloc>();
                    final station = await navigator.pushNamed(searchScreenRoute);
                    stationBloc.add(ClearSearchQueryEvent());
                    if (station != null) {
                      final stationModel = station as OcmStation;
                      stationBloc.add(
                        StationSelectedViaSearchEvent(stationModel),
                      );
                    }
                  },
                  child: const AbsorbPointer(
                    child: Hero(
                      tag: 'SearchBar',
                      child: Material(
                        color: Colors.transparent,
                        child: SearchBarWidget(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          MapUtilityButtons(
            bottomPadding: navBarHeight + 40,
          ),
          ValueListenableBuilder<PendingChargingIntent?>(
            valueListenable: PendingChargingIntentStore.instance.notifier,
            builder: (context, pending, _) {
              if (pending == null) return const SizedBox.shrink();
              final bottomPadding = MediaQuery.of(context).padding.bottom;
              return Stack(
                children: [
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomPadding + 16,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PendingIntentBanner(
                        pending: pending,
                        onStart: () => _startChargingFromPending(pending),
                        onDismiss: PendingChargingIntentStore.instance.clear,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _onExternalFocusRequested() {
    final station = StationFocusBus.instance.target.value;
    if (station == null) return;
    _handleExternalFocus(station);
  }

  void _handleExternalFocus(OcmStation station) {
    // Clear immediately so rebuilds while the sheet is open don't re-trigger focus.
    StationFocusBus.instance.clear();
    _pendingFocusStation = station;
    _maybeFocusPendingStation();
  }

  Future<void> _maybeFocusPendingStation() async {
    final station = _pendingFocusStation;
    if (station == null) return;
    if (_mapController == null) return;

    _pendingFocusStation = null;
    await _focusOnStation(station);
  }

  Future<void> _focusOnStation(OcmStation station) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(station.latitude, station.longitude),
        15,
      ),
    );
    if (mounted) {
      await _showStationSheet(station);
    }
  }

  Future<void> _showStationSheet(OcmStation station) async {
    // Ensure only one station sheet is visible at a time.
    if (_stationSheetOpen && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _stationSheetOpen = true;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          minChildSize: 0.25,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            station.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        ValueListenableBuilder<Map<int, OcmStation>>(
                          valueListenable:
                              OcmFavoritesStore.instance.favorites,
                          builder: (context, favs, _) {
                            final isFav = favs.containsKey(station.id);
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      OcmFavoritesStore.instance.toggle(
                                    station,
                                  ),
                                  icon: Icon(
                                    isFav ? Icons.star : Icons.star_border,
                                    color: isFav
                                        ? const Color(0xFFF5B400)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.address,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    if (_routeDistanceText != null &&
                        _routeDurationText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_routeDistanceText!} - ${_routeDurationText!}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _infoRow(
                      icon: Icons.bolt,
                      title: 'Power Output',
                      subtitle: station.powerSummary,
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      icon: Icons.ev_station,
                      title: 'Charge Points',
                      subtitle: '${station.numberOfPoints} available',
                      accent: station.isAvailable ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      icon: Icons.access_time,
                      title: 'Overstaying Fee',
                      subtitle:
                          'Please check on-site signage or ask staff for latest rates.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _startInAppNavigation(station);
                            },
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Get Directions'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _startInAppNavigation(station);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5B400),
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Charge Now'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    _stationSheetOpen = false;
  }

  Future<void> _startInAppNavigation(OcmStation station) async {
    if (_userLocation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for your location...')),
      );
      return;
    }

    try {
      final origin = _userLocation!;
      final destination = LatLng(station.latitude, station.longitude);

      final result = await DirectionsService.getRoute(
        origin: origin,
        destination: destination,
      );

      setState(() {
        _routePolylines = {}; // preview-only used in the next screen
        _routeDistanceText = result.distanceText;
        _routeDurationText = result.durationText;
      });

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoutePreviewScreen(
            polylinePoints: result.polylinePoints,
            distanceText: result.distanceText,
            durationText: result.durationText,
            origin: origin,
            destination: destination,
            station: station,
          ),
        ),
      );

      if (!mounted) return;
      setState(() {
        _routePolylines.clear();
        _routeDistanceText = null;
        _routeDurationText = null;
      });
    } catch (e) {
      debugPrint('Error getting directions: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load route.')),
      );
    }
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? accent,
  }) {
    final color = accent ?? Colors.grey.shade800;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startChargingFromPending(PendingChargingIntent pending) {
    PendingChargingIntentStore.instance.clear();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChargingScreen(
          stationName: pending.stationName,
          coordinates: pending.coordinates,
          connectorLabel: pending.connectorLabel,
          tariffPerKwh: pending.tariffPerKwh,
          chargingSpeed: pending.chargingSpeed,
          amperage: pending.amperage,
          voltage: pending.voltage,
          mockBatteryCapacityKwh: 15,
        ),
      ),
    );
  }

  Future<void> _openMapsFromPending(PendingChargingIntent pending) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${pending.latitude},${pending.longitude}'
      '&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _PendingIntentBanner extends StatelessWidget {
  final PendingChargingIntent pending;
  final VoidCallback onStart;
  final VoidCallback onDismiss;

  const _PendingIntentBanner({
    required this.pending,
    required this.onStart,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Left: text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You are navigating to',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pending.stationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pending.address ?? pending.coordinates,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Primary action
            TextButton(
              onPressed: onStart,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF00A3FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Charge now',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Dismiss text button
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Dismiss',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black87, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 220,
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
