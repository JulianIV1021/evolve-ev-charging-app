import 'package:flutter/material.dart';
import '../models/ocm_station.dart';
import 'charging_screen.dart';

class EnterStationIdScreen extends StatefulWidget {
  /// When provided, we validate against this exact ID (used from station sheets).
  final String? expectedStationId;
  /// When null, we search the provided stations list by the entered ID.
  final List<OcmStation>? stations;
  final String stationName;
  final String coordinates;
  final String connectorLabel;
  final double tariffPerKwh;
  final String? tariffText;
  final double chargingSpeed;
  final double amperage;
  final double voltage;
  final double mockBatteryCapacityKwh;
  final bool fullHeight;

  const EnterStationIdScreen({
    Key? key,
    this.expectedStationId,
    this.stations,
    required this.stationName,
    required this.coordinates,
    required this.connectorLabel,
    required this.tariffPerKwh,
    this.tariffText,
    required this.chargingSpeed,
    required this.amperage,
    required this.voltage,
    this.mockBatteryCapacityKwh = 15,
    this.fullHeight = false,
  }) : super(key: key);

  @override
  State<EnterStationIdScreen> createState() => _EnterStationIdScreenState();
}

class _EnterStationIdScreenState extends State<EnterStationIdScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndContinue() {
    final entered = _controller.text.trim();
    if (entered.isEmpty) {
      setState(() {
        _error = 'Please enter the Station ID printed on the charger.';
      });
      return;
    }

    // Case 1: Validate against expected ID
    if (widget.expectedStationId != null) {
      if (entered != widget.expectedStationId) {
        setState(() {
          _error = 'Station ID does not match this charger.';
        });
        return;
      }
      _goToCharging(
        stationId: entered,
        stationName: widget.stationName,
        coordinates: widget.coordinates,
        connectorLabel: widget.connectorLabel,
        tariffPerKwh: widget.tariffPerKwh,
        tariffText: widget.tariffText,
        chargingSpeed: widget.chargingSpeed,
        amperage: widget.amperage,
        voltage: widget.voltage,
        mockBatteryCapacityKwh: widget.mockBatteryCapacityKwh,
      );
      return;
    }

    // Case 2: Lookup in stations list
    final list = widget.stations ?? const <OcmStation>[];
    final match = list.firstWhere(
      (s) => s.id.toString() == entered,
      orElse: () => OcmStation(
        id: -1,
        name: '',
        latitude: 0,
        longitude: 0,
        address: '',
        status: '',
        operatorName: '',
        usageCost: '',
        numberOfPoints: 0,
        connectors: [],
        powerKw: 0,
        connectorType: '',
      ),
    );
    if (match.id == -1) {
      setState(() {
        _error = 'Station ID not found.';
      });
      return;
    }
    final coords =
        '${match.latitude.toStringAsFixed(4)}, ${match.longitude.toStringAsFixed(4)}';
    final bestConnectorPower = match.connectors
        .where((c) => c.powerKw != null && c.powerKw! > 0)
        .map((c) => c.powerKw!)
        .fold<double?>(null, (prev, kw) => prev ?? kw);
    final powerKw = bestConnectorPower ?? match.powerKw ?? 0;
    final connectorLabel =
        match.connectorType ?? (match.connectors.isNotEmpty ? match.connectors.first.connectorType : 'Type 2 AC');
    final tariffText =
        (match.usageCost.isNotEmpty ? match.usageCost : 'See rates at station');
    final tariffValue = _extractTariffNumber(match.usageCost) ?? 0;
    _goToCharging(
      stationId: entered,
      stationName: match.name,
      coordinates: coords,
      connectorLabel: connectorLabel,
      tariffPerKwh: tariffValue,
      tariffText: tariffText,
      chargingSpeed: powerKw,
      amperage: 15,
      voltage: 150,
      mockBatteryCapacityKwh: widget.mockBatteryCapacityKwh,
    );
  }

  void _goToCharging({
    required String stationId,
    required String stationName,
    required String coordinates,
    required String connectorLabel,
    required double tariffPerKwh,
    String? tariffText,
    required double chargingSpeed,
    required double amperage,
    required double voltage,
    required double mockBatteryCapacityKwh,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChargingScreen(
          stationId: stationId,
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
  }

  double? _extractTariffNumber(String raw) {
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(raw);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Station ID'),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          widget.fullHeight ? 24 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.stationName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Station ID required before starting your session.',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Station ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _validateAndContinue,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
            if (widget.fullHeight) const Spacer(),
          ],
        ),
      ),
    );
  }
}
