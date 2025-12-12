import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../../firebase_options.dart';

class ChargingTaskHandler extends TaskHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Battery _battery = Battery();

  String? _sessionId;
  String? _uid;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // already initialized
    }

    _sessionId =
        await FlutterForegroundTask.getData<String>(key: 'sessionId');
    _uid = await FlutterForegroundTask.getData<String>(key: 'uid');
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (_sessionId == null || _uid == null) return;
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final doc = _firestore
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .doc(_sessionId);

      await doc.update({
        'batteryLevel': level,
        'batteryState': state.toString(),
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      FlutterForegroundTask.updateService(
        notificationTitle: 'Charging Session Active',
        notificationText: 'Battery: $level%',
      );
    } catch (_) {
      // keep service alive
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Intentionally do not auto-complete the session here; we only end when the user stops.
  }
}
