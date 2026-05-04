import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import 'charging_screen.dart';

class ConfirmStartScreen extends StatefulWidget {
  final String qrPayload;
  const ConfirmStartScreen({super.key, required this.qrPayload});

  @override
  State<ConfirmStartScreen> createState() => _ConfirmStartScreenState();
}

class _ConfirmStartScreenState extends State<ConfirmStartScreen> {
  final _minutesCtrl = TextEditingController(text: '30');
  bool _loading = false;
  String? _error;

  // Expected payload example: EVOLVEPRO|EVOLVE-S1|CH-1
  ({String stationId, String chargerId}) _parse(String payload) {
    final parts = payload.split('|');
    if (parts.length != 3) throw Exception('Invalid QR format');
    if (parts[0].trim().toUpperCase() != 'EVOLVEPRO') throw Exception('Invalid QR prefix');
    return (stationId: parts[1].trim(), chargerId: parts[2].trim());
  }

  Future<void> _startSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in.');

      final parsed = _parse(widget.qrPayload);
      final stationId = parsed.stationId;
      final chargerId = parsed.chargerId;

      final minutes = int.tryParse(_minutesCtrl.text.trim()) ?? 0;
      if (minutes <= 0) throw Exception('Enter a valid duration (minutes).');

      final db = FirebaseFirestore.instance;
      final chargerRef = db.doc('stations/$stationId/chargers/$chargerId');

      final sessionRef = db.collection('sessions').doc();

      await db.runTransaction((tx) async {
        final chargerSnap = await tx.get(chargerRef);
        if (!chargerSnap.exists) throw Exception('Charger not found.');

        final ch = chargerSnap.data()!;
        final enabled = (ch['enabled'] ?? true) == true;
        final status = (ch['status'] ?? 'available') as String;

        if (!enabled || status == 'offline') {
          throw Exception('Charger is offline/disabled.');
        }
        if (status != 'available') {
          throw Exception('Charger is not available (status: $status).');
        }
        if (ch['currentSessionId'] != null && (ch['currentSessionId'] as String).isNotEmpty) {
          throw Exception('Charger is already in use.');
        }

        final powerKw = (ch['powerKw'] ?? 7).toDouble();
        final pricePerKwh = (ch['pricePerKwh'] ?? 15).toDouble();

        tx.set(sessionRef, {
          'userId': user.uid,
          'userEmail': user.email ?? '',
          'stationId': stationId,
          'chargerId': chargerId,
          'chargerKey': '$stationId|$chargerId',
          'status': 'pending_start',
          'requestedAt': FieldValue.serverTimestamp(),
          'targetMinutes': minutes,
          'elapsedSeconds': 0,
          'energyKwh': 0.0,
          'totalCost': 0.0,
          'idleFee': 0.0,
          'chargerPowerKw': powerKw,
          'pricePerKwh': pricePerKwh,
        });
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (_) => ChargingScreen(sessionId: sessionRef.id),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _minutesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Confirm & Start',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirm details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QR: ${widget.qrPayload}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF636366)),
                  ),
                  const SizedBox(height: 14),
                  CupertinoTextField(
                    controller: _minutesCtrl,
                    keyboardType: TextInputType.number,
                    placeholder: 'Charging duration (minutes)',
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFF1C1C1E)),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(
                          color: Color(0xFFFF3B30), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(14),
                      onPressed: _loading ? null : _startSession,
                      child: _loading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white)
                          : const Text(
                              'Start Charging',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
