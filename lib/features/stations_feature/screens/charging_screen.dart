import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_training/features/stations_feature/widgets/charging_card.dart';

enum ChargingStatus { idle, charging, finished }

class ChargingScreen extends StatefulWidget {
  final double mockBatteryCapacityKwh;
  final double tariffPerKwh;
  final double chargingSpeed;
  final double amperage;
  final double voltage;
  final String stationName;
  final String coordinates;
  final String connectorLabel;

  const ChargingScreen({
    Key? key,
    this.mockBatteryCapacityKwh = 15.0,
    this.tariffPerKwh = 3.0,
    this.chargingSpeed = 50,
    this.amperage = 15,
    this.voltage = 150,
    this.stationName = 'Demo Station',
    this.coordinates = '54.4567, 54.4567',
    this.connectorLabel = 'Type 2 AC',
  }) : super(key: key);

  @override
  State<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends State<ChargingScreen> {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _levelTimer;

  ChargingStatus _status = ChargingStatus.idle;
  int _currentLevel = 0;
  int? _startLevel;
  DateTime? _startTime;
  double _deliveredKwh = 0;
  double _cost = 0;

  @override
  void initState() {
    super.initState();
    _initBatteryMonitoring();
  }

  Future<void> _initBatteryMonitoring() async {
    final level = await _battery.batteryLevel;
    _currentLevel = level;
    final initialState = await _battery.batteryState;
    if (initialState == BatteryState.charging) {
      _startSession();
    }
    _recompute();
    _batteryStateSubscription =
        _battery.onBatteryStateChanged.listen((batteryState) async {
      final latestLevel = await _battery.batteryLevel;
      _currentLevel = latestLevel;
      if (batteryState == BatteryState.charging) {
        _startSession();
      } else if (batteryState == BatteryState.discharging ||
          batteryState == BatteryState.full) {
        _finishSession();
      }
      _recompute();
    });

    _levelTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final latestLevel = await _battery.batteryLevel;
      if (latestLevel != _currentLevel) {
        _currentLevel = latestLevel;
        _recompute();
      } else {
        _safeSetState();
      }
    });
    _safeSetState();
  }

  void _safeSetState() {
    if (!mounted) return;
    setState(() {});
  }

  void _startSession() {
    if (_status == ChargingStatus.charging) {
      return;
    }
    _status = ChargingStatus.charging;
    _startTime ??= DateTime.now();
    _startLevel ??= _currentLevel;
    _safeSetState();
  }

  void _finishSession() {
    if (_status == ChargingStatus.finished) {
      return;
    }
    _status = ChargingStatus.finished;
    _safeSetState();
  }

  void _stopManually() {
    _finishSession();
  }

  void _recompute() {
    if (_startLevel != null) {
      final deltaPercent = (_currentLevel - _startLevel!).clamp(0, 100);
      _deliveredKwh = (deltaPercent / 100) * widget.mockBatteryCapacityKwh;
      _cost = _deliveredKwh * widget.tariffPerKwh;
    }
    _safeSetState();
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    _levelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_currentLevel / 100).clamp(0.0, 1.0);
    final statusLabel = switch (_status) {
      ChargingStatus.charging => 'Charging',
      ChargingStatus.finished => 'Finished',
      _ => 'Plug in to start',
    };

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white24,
        title: const Text(
          'Charging Session',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ChargingCard(
            percentage: percentage,
            deliveredKwh: _deliveredKwh,
            cost: _cost,
            startTime: _startTime,
            chargingSpeed: widget.chargingSpeed,
            amperage: widget.amperage,
            voltage: widget.voltage,
            stationName: widget.stationName,
            coordinates: widget.coordinates,
            tariffPerKwh: widget.tariffPerKwh,
            connectorLabel: widget.connectorLabel,
            statusLabel: statusLabel,
            canStop: _status == ChargingStatus.charging,
            spinning: _status == ChargingStatus.charging,
            onStop: _stopManually,
          ),
        ),
      ),
    );
  }
}
