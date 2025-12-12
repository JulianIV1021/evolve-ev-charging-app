import 'package:flutter/material.dart';
import 'package:flutter_map_training/common/theme.dart';
import 'package:intl/intl.dart';

import 'charging_proggres_indicator.dart';

class ChargingCard extends StatelessWidget {
  final double percentage;
  final double deliveredKwh;
  final double cost;
  final DateTime? startTime;
  final double chargingSpeed;
  final double amperage;
  final double voltage;
  final String stationName;
  final String coordinates;
  final double tariffPerKwh;
  final String connectorLabel;
  final VoidCallback onStop;
  final VoidCallback? onStart;
  final String statusLabel;
  final String powerDisplay;
  final String amperageDisplay;
  final String voltageDisplay;
  final String tariffDisplay;
  final bool canStop;
  final bool canStart;
  final bool spinning;

  const ChargingCard({
    required this.percentage,
    required this.deliveredKwh,
    required this.cost,
    required this.onStop,
    this.onStart,
    this.startTime,
    this.chargingSpeed = 50,
    this.amperage = 15,
    this.voltage = 150,
    this.stationName = 'Station Name',
    this.coordinates = '',
    this.tariffPerKwh = 3.0,
    this.connectorLabel = 'Type 2 AC',
    this.statusLabel = 'Plug in, then tap Start',
    this.powerDisplay = 'N/A',
    this.amperageDisplay = 'N/A',
    this.voltageDisplay = 'N/A',
    this.tariffDisplay = 'See rates at station',
    this.canStop = false,
    this.canStart = true,
    this.spinning = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateText = startTime != null
        ? DateFormat('dd/MM/yy HH:mm').format(startTime!)
        : '-';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            spreadRadius: 3,
            blurRadius: 5,
            offset: const Offset(3, 3),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            spreadRadius: 3,
            blurRadius: 5,
            offset: const Offset(-3, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ChargingProgressIndicator(
            percentage: percentage,
            deliveredText: '${deliveredKwh.toStringAsFixed(2)} kWh',
            subtitle: statusLabel,
            spinning: spinning,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cost',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'PHP ${cost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: canStart ? onStart : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.green.withOpacity(0.35),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      )),
                  child: const Text(
                    'Start Session',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: canStop ? onStop : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      disabledBackgroundColor: Colors.red.withOpacity(0.35),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      )),
                  child: const Text(
                    'Stop Charging',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          _buildStatisticalItem('Starting Time', dateText),
          const SizedBox(height: 16),
          _buildStatisticalItem('Charging Speed', powerDisplay),
          const SizedBox(height: 16),
          _buildStatisticalItem('Amperage', amperageDisplay),
          const SizedBox(height: 16),
          _buildStatisticalItem('Voltage', voltageDisplay),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withOpacity(0.25),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Station Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stationName,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Tariff',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tariffDisplay,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Coordinates',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            coordinates.isEmpty ? '-' : coordinates,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: greyWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.ev_station,
                              color: greyBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                connectorLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticalItem(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        )
      ],
    );
  }
}
