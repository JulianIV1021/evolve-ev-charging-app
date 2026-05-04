import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';


class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key, required this.session});

  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final sessionId = session['id'] as String?;
    if (sessionId != null && sessionId.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .doc('sessions/$sessionId')
            .snapshots(),
        builder: (context, snap) {
          final live = snap.data?.data();
          final merged = live != null ? {'id': sessionId, ...live} : session;
          return _SessionDetailBody(session: merged);
        },
      );
    }
    return _SessionDetailBody(session: session);
  }
}

class _SessionDetailBody extends StatelessWidget {
  const _SessionDetailBody({required this.session});

  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final status         = session['status'] as String? ?? 'unknown';
    final stationId      = session['stationId'] as String? ?? 'Unknown';
    final chargerId      = session['chargerId'] as String? ?? '—';
    final energyKwh      = (session['energyKwh'] as num?)?.toDouble() ?? 0;
    final totalCost      = (session['totalCost'] as num?)?.toDouble() ?? 0;
    final idleFee        = (session['idleFee'] as num?)?.toDouble() ?? 0;
    final pricePerKwh    = (session['pricePerKwh'] as num?)?.toDouble() ?? 0;
    final elapsedSeconds = (session['elapsedSeconds'] as num?)?.toInt() ?? 0;
    final chargerPowerKw = (session['chargerPowerKw'] as num?)?.toDouble() ?? 0;
    final requestedAt    = session['requestedAt'];
    final stationName    = session['stationName'] as String? ?? stationId;

    String dateStr = '—';
    if (requestedAt is Timestamp) {
      dateStr = DateFormat('MMM d, yyyy · h:mm a').format(requestedAt.toDate());
    }

    final elapsed = Duration(seconds: elapsedSeconds);
    final durationStr = _formatDuration(elapsed);
    final energyCost = energyKwh * pricePerKwh;

    final (statusLabel, statusColor, statusIcon) = switch (status.toLowerCase()) {
      'ended' || 'complete' || 'completed' => (
        'Session Ended',
        const Color(0xFF8E8E93),
        CupertinoIcons.checkmark_circle_fill,
      ),
      'active' || 'charging' => (
        'Charging Active',
        const Color(0xFF34C759),
        CupertinoIcons.bolt_circle_fill,
      ),
      'idle_fee' => (
        'Idle Fee Active',
        const Color(0xFFFF9500),
        CupertinoIcons.clock_fill,
      ),
      _ => (
        'Session Ended',
        const Color(0xFF8E8E93),
        CupertinoIcons.checkmark_circle_fill,
      ),
    };

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFC6C6C8), width: 0.5),
        ),
        middle: const Text(
          'Session Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
          child: const Icon(
            CupertinoIcons.chevron_back,
            color: Color(0xFF007AFF),
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [

            // ── Hero status card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Total cost highlight
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total Charged',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          totalCost > 0
                              ? '₱${totalCost.toStringAsFixed(2)}'
                              : '₱0.00',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF5A623),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Quick stats row ───────────────────────────────────
            Row(
              children: [
                _StatCard(
                  icon: CupertinoIcons.bolt_fill,
                  iconColor: const Color(0xFFF5A623),
                  label: 'Energy',
                  value: '${energyKwh.toStringAsFixed(2)} kWh',
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: CupertinoIcons.clock_fill,
                  iconColor: const Color(0xFF007AFF),
                  label: 'Duration',
                  value: durationStr,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: CupertinoIcons.speedometer,
                  iconColor: const Color(0xFF34C759),
                  label: 'Power',
                  value: chargerPowerKw > 0
                      ? '${chargerPowerKw.toStringAsFixed(1)} kW'
                      : '—',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Cost breakdown ────────────────────────────────────
            _SectionCard(
              title: 'Cost Breakdown',
              children: [
                _DetailRow(
                  label: 'Price per kWh',
                  value: pricePerKwh > 0
                      ? '₱${pricePerKwh.toStringAsFixed(2)}'
                      : '—',
                ),
                _DetailRow(
                  label: 'Energy cost',
                  value: '₱${energyCost.toStringAsFixed(2)}',
                ),
                if (idleFee > 0)
                  _DetailRow(
                    label: 'Idle fee',
                    value: '₱${idleFee.toStringAsFixed(2)}',
                    valueColor: const Color(0xFFFF9500),
                  ),
                _DetailRow(
                  label: 'Total',
                  value: totalCost > 0
                      ? '₱${totalCost.toStringAsFixed(2)}'
                      : '₱0.00',
                  isTotal: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Station info ──────────────────────────────────────
            _SectionCard(
              title: 'Station Information',
              children: [
                _DetailRow(label: 'Station', value: stationName),
                _DetailRow(label: 'Charger', value: chargerId),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

// ── Stat card (3-up row) ─────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: children
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < children.length - 1)
                          Container(
                            height: 0.5,
                            color: const Color(0xFFE5E5EA),
                            margin: const EdgeInsets.only(left: 16),
                          ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ── Detail row ───────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: isTotal
                  ? const Color(0xFF1C1C1E)
                  : const Color(0xFF8E8E93),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 17 : 15,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: valueColor ??
                  (isTotal
                      ? const Color(0xFFF5A623)
                      : const Color(0xFF1C1C1E)),
            ),
          ),
        ],
      ),
    );
  }
}
