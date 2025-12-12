import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map_training/features/stations_feature/widgets/charging_card.dart';
import '../models/ocm_station.dart';
import '../repository/session_repository.dart';
import '../services/charging_foreground_service.dart';

enum ChargingStatus { idle, charging, finished }

class ChargingScreen extends StatefulWidget {
  final String stationId;
  final double mockBatteryCapacityKwh;
  final double tariffPerKwh;
  final double chargingSpeed;
  final double amperage;
  final double voltage;
  final String stationName;
  final String coordinates;
  final String connectorLabel;
  final String? tariffText;
  final String? existingSessionId;

  const ChargingScreen({
    Key? key,
    required this.stationId,
    this.mockBatteryCapacityKwh = 15.0,
    this.tariffPerKwh = 3.0,
    this.chargingSpeed = 50,
    this.amperage = 15,
    this.voltage = 150,
    this.stationName = 'Demo Station',
    this.coordinates = '54.4567, 54.4567',
    this.connectorLabel = 'Type 2 AC',
    this.tariffText,
    this.existingSessionId,
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
  String? _activeSessionId;
  bool _isPlugged = false;
  Timestamp? _persistedStart;

  @override
  void initState() {
    super.initState();
    _initBatteryMonitoring();
    _resumeExistingIfAny();
  }

  Future<void> _initBatteryMonitoring() async {
    final level = await _battery.batteryLevel;
    final initialState = await _battery.batteryState;
    _currentLevel = level;
    _isPlugged =
        initialState == BatteryState.charging || initialState == BatteryState.full;
    _recompute();
    _batteryStateSubscription =
        _battery.onBatteryStateChanged.listen((batteryState) async {
      _isPlugged = batteryState == BatteryState.charging ||
          batteryState == BatteryState.full;
      final latestLevel = await _battery.batteryLevel;
      _currentLevel = latestLevel;
      _recompute();
    });

    _levelTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final latestState = await _battery.batteryState;
      _isPlugged =
          latestState == BatteryState.charging || latestState == BatteryState.full;
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

  Future<void> _resumeExistingIfAny() async {
    if (widget.existingSessionId == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(widget.existingSessionId!)
          .get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      _activeSessionId = widget.existingSessionId;
      _status = ChargingStatus.charging;
      _persistedStart = data['startedAt'] as Timestamp?;
      _startTime = _persistedStart?.toDate();
      final startPct = data['startBatteryPercent'] as int?;
      if (startPct != null) {
        _startLevel = startPct;
      }
      _safeSetState();
    } catch (_) {}
  }

  void _finishSession() {
    if (_status == ChargingStatus.finished) {
      return;
    }
    _status = ChargingStatus.finished;
    _safeSetState();
  }

  Future<void> _startSession() async {
    if (_status == ChargingStatus.charging) {
      return;
    }
    if (!_isPlugged) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plug in the charger before starting the session.'),
        ),
      );
      return;
    }
    try {
      final station = _stationFromProps();
      final repo = context.read<SessionRepositoryImpl>();
      final sessionId =
          _activeSessionId ?? await repo.startSession(station);
      _activeSessionId = sessionId;
      _status = ChargingStatus.charging;
      _startTime ??= DateTime.now();
      _startLevel ??= _currentLevel;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await ChargingForegroundService.start(
          sessionId: sessionId,
          uid: uid,
        );
      }
      _recompute();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start session: $e')),
      );
    }
  }

  Future<void> _stopManually() async {
    _finishSession();
    // End active session in repo and stop foreground service.
    final repo = context.read<SessionRepositoryImpl>();
    final sessionId = _activeSessionId;
    _activeSessionId = null;
    if (sessionId != null) {
      try {
        await repo.endSession(sessionId);
      } catch (_) {}
    }
    await ChargingForegroundService.stop();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If we were launched to resume an existing session, keep that ID.
    if (_activeSessionId == null && widget.existingSessionId != null) {
      _activeSessionId = widget.existingSessionId;
      _status = ChargingStatus.charging;
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_currentLevel / 100).clamp(0.0, 1.0);
    final statusLabel = switch (_status) {
      ChargingStatus.charging => 'Charging',
      ChargingStatus.finished => 'Finished',
      _ => 'Plug in, then tap Start',
    };

    final powerDisplay =
        widget.chargingSpeed > 0 ? '${widget.chargingSpeed.toStringAsFixed(0)} kW (rated)' : 'N/A';
    final ampDisplay =
        widget.amperage > 0 ? '${widget.amperage.toStringAsFixed(0)} A' : 'N/A';
    final voltDisplay =
        widget.voltage > 0 ? '${widget.voltage.toStringAsFixed(0)} V' : 'N/A';
    final tariffDisplay = (widget.tariffText ?? '').isNotEmpty
        ? widget.tariffText!
        : (widget.tariffPerKwh > 0
            ? 'PHP ${widget.tariffPerKwh.toStringAsFixed(2)} per kWh'
            : 'See rates at station');

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
            powerDisplay: powerDisplay,
            amperageDisplay: ampDisplay,
            voltageDisplay: voltDisplay,
            tariffDisplay: tariffDisplay,
            statusLabel: statusLabel,
            onStart: _startSession,
            canStart: _status != ChargingStatus.charging,
            canStop: _status == ChargingStatus.charging,
            spinning: _status == ChargingStatus.charging,
          onStop: _stopManually,
        ),
      ),
      ),
    );
  }

  OcmStation _stationFromProps() {
    final parts = widget.coordinates.split(',');
    final lat = parts.isNotEmpty ? double.tryParse(parts[0].trim()) ?? 0.0 : 0.0;
    final lng =
        parts.length > 1 ? double.tryParse(parts[1].trim()) ?? 0.0 : 0.0;
    return OcmStation(
      id: int.tryParse(widget.stationId) ?? 0,
      name: widget.stationName,
      latitude: lat,
      longitude: lng,
      address: widget.coordinates,
      status: 'active',
      operatorName: 'EVOLVE',
      usageCost: widget.tariffPerKwh.toString(),
      numberOfPoints: 1,
      connectors: const [],
      powerKw: widget.chargingSpeed,
      connectorType: widget.connectorLabel,
    );
  }
}
