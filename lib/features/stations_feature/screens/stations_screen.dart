import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../network/directions_service.dart';
import '../bloc/bloc.dart';
import '../models/ocm_station.dart';
import '../screens/route_preview_screen.dart';
import '../services/active_session_store.dart';
import '../services/ocm_favorites_store.dart';
import '../services/pending_charging_intent_store.dart';
import '../services/station_focus_bus.dart';
import '../widgets/map_utility_buttons.dart';
import '../widgets/search_bar.dart';
import '../widgets/stations_map.dart';
import 'charging_screen.dart';
import 'enter_station_id_screen.dart';

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
    final bloc = context.read<StationsBloc>();
    bloc.add(StationsRequested());
    bloc.add(LoadSearchHistoryEvent());

    final pendingTarget = StationFocusBus.instance.target.value;
    if (pendingTarget != null) {
      Future.microtask(() => _handleExternalFocus(pendingTarget));
    }
  }

  @override
  void dispose() {
    StationFocusBus.instance.target.removeListener(_onExternalFocusRequested);
    _mapController = null;
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
                    final station =
                        await navigator.pushNamed('/search_screen_route');
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
    if (_mapController == null) return;
    await _mapController!.animateCamera(
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
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<Map<int, OcmStation>>(
                      valueListenable: OcmFavoritesStore.instance.favorites,
                      builder: (context, favs, _) {
                        final isFav = favs.containsKey(station.id);
                        return Row(
                          children: [
                            IconButton(
                              onPressed: () => OcmFavoritesStore.instance
                                  .toggle(station),
                              icon: Icon(
                                isFav ? Icons.star : Icons.star_border,
                                color: isFav
                                    ? const Color(0xFFF5B400)
                                    : Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              'Station ID: ${station.id}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        );
                      },
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
                              _openChargingScreen(station);
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
        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('route_preview'),
            color: Colors.blue,
            width: 5,
            points: result.polylinePoints,
          ),
        };
        _routeDistanceText = result.distanceText;
        _routeDurationText = result.durationText;
      });

      // Zoom map to fit the preview polyline.
      await _focusPolyline(result.polylinePoints);

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

  void _openChargingScreen(OcmStation station) {
    // If an active session exists, resume it instead of prompting.
    ActiveSessionStore.instance.fetchActive().then((active) {
      if (!mounted) return;
      if (active != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChargingScreen(
              stationId: active.stationId,
              stationName: active.stationName,
              coordinates:
                  '${active.latitude.toStringAsFixed(4)}, ${active.longitude.toStringAsFixed(4)}',
              connectorLabel: active.connectorType ?? 'Type 2 AC',
              tariffPerKwh: 0,
              tariffText: 'See rates at station',
              chargingSpeed: active.powerKw ?? 0,
              amperage: 15,
              voltage: 150,
              existingSessionId: active.id,
            ),
          ),
        );
        return;
      }

      // Otherwise prompt for this station's ID.
      final coords =
          '${station.latitude.toStringAsFixed(4)}, ${station.longitude.toStringAsFixed(4)}';
      final bestConnectorPower = station.connectors
          .where((c) => c.powerKw != null && c.powerKw! > 0)
          .map((c) => c.powerKw!)
          .fold<double?>(null, (prev, kw) => prev ?? kw);
      final powerKw = bestConnectorPower ?? station.powerKw ?? 0;
      final connectorLabel = station.connectorType ??
          (station.connectors.isNotEmpty
              ? station.connectors.first.connectorType
              : 'Type 2 AC');
      final tariffText = station.usageCost.isNotEmpty
          ? station.usageCost
          : 'See rates at station';
      final tariffValue = _extractTariffNumber(station.usageCost) ?? 0;
      _promptStationIdAndOpenCharging(
        expectedStationId: station.id.toString(),
        stationName: station.name,
        coordinates: coords,
        connectorLabel: connectorLabel,
        tariffPerKwh: tariffValue,
        tariffText: tariffText,
        chargingSpeed: powerKw,
        amperage: 15,
        voltage: 150,
      );
    });
  }

  double? _extractTariffNumber(String raw) {
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(raw);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
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
    _promptStationIdAndOpenCharging(
      expectedStationId: pending.stationId,
      stationName: pending.stationName,
      coordinates: pending.coordinates,
      connectorLabel: pending.connectorLabel,
      tariffPerKwh: pending.tariffPerKwh,
      chargingSpeed: pending.chargingSpeed,
      amperage: pending.amperage,
      voltage: pending.voltage,
      mockBatteryCapacityKwh: 15,
    ).then((success) {
      if (success == true) {
        PendingChargingIntentStore.instance.clear();
      }
    });
  }

  Future<void> _openMapsFromPending(PendingChargingIntent pending) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${pending.latitude},${pending.longitude}'
      '&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _focusPolyline(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty) return;
    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      minLat = (minLat == null) ? p.latitude : (p.latitude < minLat ? p.latitude : minLat);
      maxLat = (maxLat == null) ? p.latitude : (p.latitude > maxLat ? p.latitude : maxLat);
      minLng = (minLng == null) ? p.longitude : (p.longitude < minLng ? p.longitude : minLng);
      maxLng = (maxLng == null) ? p.longitude : (p.longitude > maxLng ? p.longitude : maxLng);
    }
    if (minLat == null || minLng == null || maxLat == null || maxLng == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 64),
      );
    } catch (_) {
      // Fallback to destination focus if bounds fail.
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.last, 12),
      );
    }
  }

  Future<bool> _promptStationIdAndOpenCharging({
    required String expectedStationId,
    required String stationName,
    required String coordinates,
    required String connectorLabel,
    required double tariffPerKwh,
    String? tariffText,
    required double chargingSpeed,
    required double amperage,
    required double voltage,
    double mockBatteryCapacityKwh = 15,
  }) async {
    if (!mounted) return false;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnterStationIdScreen(
          expectedStationId: expectedStationId,
          stationName: stationName,
          coordinates: coordinates,
          connectorLabel: connectorLabel,
          tariffPerKwh: tariffPerKwh,
          tariffText: tariffText,
          chargingSpeed: chargingSpeed,
          amperage: amperage,
          voltage: voltage,
          mockBatteryCapacityKwh: mockBatteryCapacityKwh,
        ),
      ),
    );
    // We can’t know user success here easily; assume success if screen returns.
    return true;
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
