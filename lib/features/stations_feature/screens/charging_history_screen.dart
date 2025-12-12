import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/sessions_bloc.dart';
import '../bloc/sessions_state.dart';
import '../bloc/sessions_event.dart';
import '../models/charging_session.dart';

class ChargingHistoryScreen extends StatelessWidget {
  const ChargingHistoryScreen({Key? key}) : super(key: key);

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('MMM d, h:mm a').format(dt);
    }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--';
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charging Sessions'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SessionsBloc>().add(LoadSessionsEvent());
            },
          )
        ],
      ),
      body: BlocBuilder<SessionsBloc, SessionsState>(
        builder: (context, state) {
          if (state.status == SessionsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == SessionsStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(state.error ?? 'Error loading sessions'),
              ),
            );
          }
          if (state.sessions.isEmpty) {
            return const Center(
              child: Text('No sessions yet.'),
            );
          }

          final active = state.sessions.where((s) => s.status == 'active').toList();
          final completed = state.sessions.where((s) => s.status != 'active').toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (active.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                ...active.map((s) => _SessionTile(
                      session: s,
                      formatTime: _formatTime,
                      formatDuration: _formatDuration,
                      showEndButton: true,
                    )),
                const Divider(height: 24),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'History',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              ...completed.map(
                (s) => _SessionTile(
                  session: s,
                  formatTime: _formatTime,
                  formatDuration: _formatDuration,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ChargingSession session;
  final String Function(DateTime?) formatTime;
  final String Function(int?) formatDuration;
  final bool showEndButton;

  const _SessionTile({
    required this.session,
    required this.formatTime,
    required this.formatDuration,
    this.showEndButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final started = formatTime(session.startedAt?.toDate());
    final ended = formatTime(session.endedAt?.toDate());
    final duration = formatDuration(session.durationSeconds);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.stationName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: session.status == 'active'
                        ? Colors.green.withOpacity(0.15)
                        : Colors.blueGrey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session.status.toUpperCase(),
                    style: TextStyle(
                      color: session.status == 'active'
                          ? Colors.green.shade700
                          : Colors.blueGrey.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('ID: ${session.stationId}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _info('Start', started),
                ),
                Expanded(
                  child: _info('End', session.status == 'active' ? '--' : ended),
                ),
                Expanded(
                  child: _info('Duration', duration),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _info('Start %',
                      session.startBatteryPercent?.toString() ?? '--'),
                ),
                Expanded(
                  child: _info('End %',
                      session.endBatteryPercent?.toString() ?? '--'),
                ),
                Expanded(
                  child: _info(
                    'Energy',
                    session.energyKWhEstimate != null
                        ? '${session.energyKWhEstimate!.toStringAsFixed(3)} kWh'
                        : '--',
                  ),
                ),
              ],
            ),
            if (showEndButton) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    context.read<SessionsBloc>().add(
                          EndSessionEvent(session.id),
                        );
                  },
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('End Session'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
