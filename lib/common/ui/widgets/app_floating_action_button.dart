import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/stations_feature/bloc/stations_bloc.dart';
import '../../../features/stations_feature/models/charging_session.dart';
import '../../../features/stations_feature/screens/charging_screen.dart';
import '../../../features/stations_feature/screens/enter_station_id_screen.dart';
import '../../../features/stations_feature/services/active_session_store.dart';

class AppFloatingActionButton extends StatelessWidget {
  const AppFloatingActionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _promptStationId(context),
        child: const Center(
          child: Icon(
            Icons.flash_on,
            color: Colors.grey,
            size: 26,
          ),
        ),
      ),
    );
  }

  Future<void> _promptStationId(BuildContext context) async {
    // If there is an active session, jump back into it.
    final ChargingSession? active =
        await ActiveSessionStore.instance.fetchActive();
    if (active != null) {
      if (!context.mounted) return;
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

    final stations = context.read<StationsBloc>().state.stations;
    if (stations.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stations not loaded yet.')),
      );
      return;
    }

    // Use the same full-screen prompt as Charge Now, but allow lookup.
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnterStationIdScreen(
          expectedStationId: null,
          stations: stations,
          stationName: 'Enter Station ID',
          coordinates: '',
          connectorLabel: 'Type 2 AC',
          tariffPerKwh: 0,
          tariffText: 'See rates at station',
          chargingSpeed: 50,
          amperage: 15,
          voltage: 150,
          mockBatteryCapacityKwh: 15,
        ),
      ),
    );
  }
}
