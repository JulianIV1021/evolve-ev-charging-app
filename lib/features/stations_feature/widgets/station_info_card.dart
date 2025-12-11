import 'package:flutter/material.dart';

import '../models/ocm_station.dart';

class StationInfoCard extends StatelessWidget {
  final OcmStation station;
  final VoidCallback onClose;
  final VoidCallback onGetDirections;
  final VoidCallback onChargeNow;
  final String? distanceText;
  final String? durationText;

  const StationInfoCard({
    super.key,
    required this.station,
    required this.onClose,
    required this.onGetDirections,
    required this.onChargeNow,
    this.distanceText,
    this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = Colors.grey.shade700;
    final surface = Colors.white;

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        color: surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              station.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtle,
              ),
            ),
            if (distanceText != null && durationText != null) ...[
              const SizedBox(height: 4),
              Text(
                '$distanceText • $durationText',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _banner(),
            const SizedBox(height: 16),
            _infoRow(
              icon: Icons.bolt,
              title: 'Power Output',
              subtitle: station.powerSummary,
            ),
            const SizedBox(height: 12),
            _infoRow(
              icon: Icons.ev_station,
              title: 'Charge Points',
              subtitle: '${station.numberOfPoints} available',
              accent: station.isAvailable ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            _infoRow(
              icon: Icons.access_time,
              title: 'Overstaying Fee',
              subtitle:
                  'Please check on-site signage or ask staff for latest rates.',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onGetDirections,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    child: const Text('Get Directions'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onChargeNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5B400),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
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
  }

  Widget _banner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0C9BE6), Color(0xFF0B4F9E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Save more with membership offers',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
}
