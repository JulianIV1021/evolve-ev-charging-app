import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart' show notifs;
import '../services/notification_service.dart';

class ChargingScreen extends StatefulWidget {
  final String sessionId;
  const ChargingScreen({super.key, required this.sessionId});

  @override
  State<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends State<ChargingScreen> {
  bool _stopping = false;
  String? _stopError;
  String? _lastStatus;

  Timer? _uiTimer;
  int _nowMs = DateTime.now().millisecondsSinceEpoch;

  // Local interpolation fields — smooth ring between Firestore ticks
  int _firestoreElapsedSec = 0;
  int _firestoreTargetSec = 0;
  int _firestoreReceivedMs = 0;
  int _prevFirestoreElapsed = -1;

  // Cached stream — prevents StreamBuilder from re-subscribing every second
  // when _uiTimer triggers a rebuild.
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _sessionStream;

  bool _canUserEnd(String status) {
    return status == 'pending_start' ||
        status == 'active' ||
        status == 'charging' ||
        status == 'complete' ||
        status == 'idle_fee';
  }

  @override
  void initState() {
    super.initState();
    _sessionStream = FirebaseFirestore.instance
        .doc('sessions/${widget.sessionId}')
        .snapshots();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _nowMs = DateTime.now().millisecondsSinceEpoch);
    });

    // Start background Firestore watcher + foreground service notification.
    // This keeps the session alive and notifications firing even when the
    // screen is locked or the user navigates away.
    NotificationService.instance.startTrackingSession(widget.sessionId);
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  Future<void> _endSession() async {
    if (_stopping) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _stopping = true;
      _stopError = null;
    });

    try {
      final db = FirebaseFirestore.instance;
      final sessionRef = db.doc('sessions/${widget.sessionId}');

      await db.runTransaction((tx) async {
        final sSnap = await tx.get(sessionRef);
        if (!sSnap.exists) throw Exception('Session not found.');

        final s = sSnap.data() as Map<String, dynamic>;
        final status = (s['status'] ?? '') as String;

        if (!_canUserEnd(status)) {
          throw Exception('Cannot end session. Status is: $status');
        }

        tx.update(sessionRef, {
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _stopError = e.toString());
    } finally {
      setState(() => _stopping = false);
    }
  }

  void _maybeNotifyStatus(String status) {
    if (_lastStatus == status) return;
    _lastStatus = status;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (status == 'complete') {
        notifs.show(
          1,
          'Charging complete',
          'Grace period started. Please unplug your vehicle.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'charging',
              'Charging Alerts',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }

      if (status == 'idle_fee') {
        notifs.show(
          2,
          'Idle fee active',
          'Grace period ended. Idle fee is now counting.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'charging',
              'Charging Alerts',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }

      if (status == 'ended') {
        NotificationService.instance.stopTrackingSession();
      }
    });
  }

  String _fmtMMSS(int sec) {
    sec = sec < 0 ? 0 : sec;
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _sessionStream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const CupertinoPageScaffold(
            backgroundColor: Color(0xFFF2F2F7),
            child: Center(
                child: CupertinoActivityIndicator(
                    color: Color(0xFFF5A623))),
          );
        }

        final data = snap.data!.data();
        if (data == null) {
          return const CupertinoPageScaffold(
            backgroundColor: Color(0xFFF2F2F7),
            child: Center(
              child: Text('Session not found',
                  style: TextStyle(color: Color(0xFF8E8E93))),
            ),
          );
        }

        final status = (data['status'] ?? '') as String;
        _maybeNotifyStatus(status);

        final stationId  = (data['stationId'] ?? '') as String;
        final chargerId  = (data['chargerId'] ?? '') as String;
        final elapsedSec = (data['elapsedSeconds'] ?? 0) as int;
        final targetMin  = (data['targetMinutes'] ?? 0) as int;
        final targetSec  = targetMin * 60;
        final energy     = (data['energyKwh'] ?? 0).toDouble();
        final total      = (data['totalCost'] ?? 0).toDouble();
        final idleFee    = (data['idleFee'] ?? 0).toDouble();

        // Interpolate elapsed locally between Firestore ticks for smooth animation
        if (elapsedSec != _prevFirestoreElapsed) {
          _firestoreElapsedSec = elapsedSec;
          _firestoreTargetSec = targetSec;
          _firestoreReceivedMs = DateTime.now().millisecondsSinceEpoch;
          _prevFirestoreElapsed = elapsedSec;
        }
        final driftSec = _firestoreReceivedMs == 0
            ? 0
            : (DateTime.now().millisecondsSinceEpoch - _firestoreReceivedMs) ~/
                1000;
        final smoothElapsedSec = targetSec > 0
            ? (_firestoreElapsedSec + driftSec).clamp(0, targetSec)
            : _firestoreElapsedSec + driftSec;

        final remainingSec = targetSec - smoothElapsedSec;
        final remainingMinDisplay =
            remainingSec <= 0 ? 0 : (remainingSec / 60).ceil();
        final ringProgress = targetSec <= 0
            ? 0.0
            : (smoothElapsedSec / targetSec).clamp(0.0, 1.0);

        int? graceRemainingSec;
        final graceTs = data['gracePeriodEndsAt'];
        if (graceTs is Timestamp) {
          final graceEndsMs = graceTs.toDate().millisecondsSinceEpoch;
          graceRemainingSec = ((graceEndsMs - _nowMs) / 1000).floor();
          if (graceRemainingSec < 0) graceRemainingSec = 0;
        }

        final canEnd = _canUserEnd(status);

        return CupertinoPageScaffold(
          backgroundColor: const Color(0xFFF2F2F7),
          navigationBar: CupertinoNavigationBar(
            backgroundColor: const Color(0xFFFFFFFF),
            border: const Border(
              bottom: BorderSide(color: Color(0x1A000000), width: 0.5),
            ),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Icon(
                CupertinoIcons.chevron_back,
                color: Color(0xFFF5A623),
              ),
            ),
            middle: Text(
              _titleFor(status),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [

                // ── Status pills row ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      _DarkPill(stationId.isEmpty ? 'Station' : stationId),
                      const SizedBox(width: 8),
                      _DarkPill(chargerId.isEmpty ? 'Charger' : chargerId),
                      const Spacer(),
                      _StatusPill(status),
                    ],
                  ),
                ),

                // ── Ring + state visual ───────────────────────────
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF000000).withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _buildRingSection(
                        status: status,
                        remainingMinDisplay: remainingMinDisplay,
                        remainingSec: remainingSec,
                        elapsedSec: elapsedSec,
                        ringProgress: ringProgress,
                        graceRemainingSec: graceRemainingSec,
                      ),
                    ),
                  ),
                ),

                // ── White details card ────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 24,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Station name row
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5A623).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              CupertinoIcons.bolt_fill,
                              size: 16,
                              color: Color(0xFFF5A623),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            stationId.isEmpty ? 'Charging Session' : stationId,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Stats row
                      Row(
                        children: [
                          _LightStatCard(
                            icon: CupertinoIcons.bolt_fill,
                            iconColor: const Color(0xFFF5A623),
                            label: 'Energy',
                            value: '${energy.toStringAsFixed(2)} kWh',
                          ),
                          const SizedBox(width: 10),
                          _LightStatCard(
                            icon: CupertinoIcons.money_dollar_circle_fill,
                            iconColor: const Color(0xFF34C759),
                            label: 'Cost',
                            value: '₱${total.toStringAsFixed(2)}',
                          ),
                          const SizedBox(width: 10),
                          _LightStatCard(
                            icon: CupertinoIcons.exclamationmark_circle_fill,
                            iconColor: const Color(0xFFFF9500),
                            label: 'Idle Fee',
                            value: '₱${idleFee.toStringAsFixed(2)}',
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Elapsed / remaining row
                      if (status == 'active' || status == 'charging') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _TimeLabel(
                                label: 'Elapsed',
                                value: _fmtMMSS(smoothElapsedSec),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: const Color(0xFFE5E5EA),
                              ),
                              _TimeLabel(
                                label: 'Remaining',
                                value: _fmtMMSS(remainingSec),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (status == 'idle_fee') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3DC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                color: Color(0xFFFF9500),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Idle fee active — please unplug your vehicle',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8E5E00),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (status == 'complete') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: Color(0xFF34C759),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  graceRemainingSec == null
                                      ? 'Charging complete — please unplug your vehicle'
                                      : 'Grace period: ${_fmtMMSS(graceRemainingSec)} remaining',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1A5C2A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Error
                      if (_stopError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5E5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _stopError!,
                            style: const TextStyle(
                              color: Color(0xFFFF3B30),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Action button — "Done" when ended, "Stop Charging" otherwise
                      if (status == 'ended')
                        CupertinoButton(
                          color: const Color(0xFF34C759),
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: CupertinoColors.white,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Done',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: (_stopping || !canEnd)
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(0xFFFF3B30).withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: CupertinoButton(
                            color: (_stopping || !canEnd)
                                ? const Color(0xFFE5E5EA)
                                : const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(16),
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            onPressed: (_stopping || !canEnd) ? null : _endSession,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_stopping)
                                  const CupertinoActivityIndicator(
                                    color: CupertinoColors.white,
                                    radius: 10,
                                  )
                                else
                                  Icon(
                                    CupertinoIcons.stop_circle_fill,
                                    color: (_stopping || !canEnd)
                                        ? const Color(0xFF8E8E93)
                                        : CupertinoColors.white,
                                    size: 22,
                                  ),
                                const SizedBox(width: 10),
                                Text(
                                  _stopping ? 'Ending...' : 'Stop Charging',
                                  style: TextStyle(
                                    color: (_stopping || !canEnd)
                                        ? const Color(0xFF8E8E93)
                                        : CupertinoColors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _titleFor(String status) => switch (status) {
        'active' || 'charging' => 'Charging In Progress',
        'complete' => 'Charging Complete',
        'idle_fee' => 'Idle Fee Active',
        'ended' => 'Session Ended',
        _ => 'Charging Session',
      };

  Widget _buildRingSection({
    required String status,
    required int remainingMinDisplay,
    required int remainingSec,
    required int elapsedSec,
    required double ringProgress,
    required int? graceRemainingSec,
  }) {
    if (status == 'active' || status == 'charging') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 210,
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: ringProgress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  builder: (_, value, __) => CustomPaint(
                    size: const Size(210, 210),
                    painter: _RingPainter(progress: value),
                  ),
                ),
                // Outer glow
                Container(
                  width: 172,
                  height: 172,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF5A623).withValues(alpha: 0.18),
                        const Color(0x00F5A623),
                      ],
                    ),
                  ),
                ),
                // Inner circle (light)
                Container(
                  width: 144,
                  height: 144,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.bolt_fill,
                      size: 26,
                      color: Color(0xFFF5A623),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0)
                            .animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Text(
                        '$remainingMinDisplay',
                        key: ValueKey(remainingMinDisplay),
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C1C1E),
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remainingMinDisplay == 1 ? 'min left' : 'mins left',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (status == 'complete') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 52,
              color: Color(0xFF34C759),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Charging Complete',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
        ],
      );
    }

    if (status == 'idle_fee') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 52,
              color: Color(0xFFFF9500),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Idle Fee Active',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
        ],
      );
    }

    if (status == 'ended') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF8E8E93).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 52,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Session Ended',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
        ],
      );
    }

    // pending_start or unknown
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoActivityIndicator(
          color: Color(0xFFF5A623),
          radius: 20,
        ),
        SizedBox(height: 16),
        Text(
          'Starting session...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }
}

// ── Station/charger ID pill ───────────────────────────────────────
class _DarkPill extends StatelessWidget {
  const _DarkPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1A000000)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1C1E),
        ),
      ),
    );
  }
}

// ── Status pill (top right) ──────────────────────────────────────
class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      'active' ||
      'charging'      => ('Charging', const Color(0xFF34C759), const Color(0x2534C759)),
      'complete'      => ('Complete', const Color(0xFF34C759), const Color(0x2534C759)),
      'idle_fee'      => ('Idle Fee', const Color(0xFFFF9500), const Color(0x25FF9500)),
      'pending_start' => ('Starting', const Color(0xFFF5A623), const Color(0x25F5A623)),
      _               => ('Ended',    const Color(0xFF8E8E93), const Color(0x258E8E93)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Light stat card (inside white panel) ─────────────────────────
class _LightStatCard extends StatelessWidget {
  const _LightStatCard({
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
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
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Time label ───────────────────────────────────────────────────
class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ring painter ─────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;
    const strokeWidth = 14.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE5E5EA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = const Color(0xFFF5A623)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
