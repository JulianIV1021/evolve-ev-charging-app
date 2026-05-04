import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart' show notifs;
import '../utils/app_logger.dart';

/// Top-level FCM background handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM background] ${message.notification?.title}');
}

/// Manages both Firebase Cloud Messaging (push) and local notifications.
/// Also owns a persistent Firestore stream for the active charging session
/// so notifications fire even when the app is backgrounded / screen locked.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;

  // ── Active session tracking ────────────────────────────────────────────────

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sessionSub;
  String? _trackedSessionId;
  String? _lastTrackedStatus;

  static const _kChargingActiveId = 20001;

  /// Call this when a charging session starts. NotificationService will keep
  /// a Firestore listener alive even when the screen is locked / app is
  /// backgrounded, showing an ongoing foreground-service notification on
  /// Android and updating it on every kiosk tick.
  void startTrackingSession(String sessionId) {
    if (_trackedSessionId == sessionId) return; // already tracking
    _sessionSub?.cancel();
    _trackedSessionId = sessionId;
    _lastTrackedStatus = null;
    _sessionSub = FirebaseFirestore.instance
        .doc('sessions/$sessionId')
        .snapshots()
        .listen(_onSessionDoc, onError: (_) {});
  }

  /// Stop tracking (and cancel the foreground notification). Called when the
  /// session reaches 'ended', or when the user navigates to a new session.
  void stopTrackingSession() {
    _sessionSub?.cancel();
    _sessionSub = null;
    _trackedSessionId = null;
    _lastTrackedStatus = null;
    _cancelChargingNotification();
  }

  void _onSessionDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) return;

    final status = (data['status'] ?? '') as String;
    final elapsedSec = (data['elapsedSeconds'] ?? 0) as int;
    final targetMin = (data['targetMinutes'] ?? 0) as int;
    final targetSec = targetMin * 60;
    final remainingSec = (targetSec - elapsedSec).clamp(0, targetSec);
    final remainingMin = targetSec > 0 ? (remainingSec / 60).ceil() : 0;
    final energyKwh = (data['energyKwh'] ?? 0.0).toDouble();
    final cost =
        ((data['totalCost'] ?? 0) + (data['idleFee'] ?? 0)).toDouble();

    // One-time status-change alerts (fire even in background via this stream)
    if (_lastTrackedStatus != status) {
      _lastTrackedStatus = status;
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
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
            ),
          ),
        );
      } else if (status == 'idle_fee') {
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
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
            ),
          ),
        );
      } else if (status == 'ended') {
        stopTrackingSession();
        return;
      }
    }

    // Update the ongoing foreground notification on every tick
    final bool showNotification = status == 'pending_start' ||
        status == 'active' ||
        status == 'charging' ||
        status == 'complete' ||
        status == 'idle_fee';

    if (showNotification) {
      _showOrUpdateChargingNotification(
        status: status,
        remainingMin: remainingMin,
        energyKwh: energyKwh,
        cost: cost,
      );
    }
  }

  Future<void> _showOrUpdateChargingNotification({
    required String status,
    required int remainingMin,
    required double energyKwh,
    required double cost,
  }) async {
    final String title;
    final String body;

    switch (status) {
      case 'idle_fee':
        title = 'Idle Fee Active';
        body = 'Unplug your vehicle — fee: ₱${cost.toStringAsFixed(2)}';
      case 'complete':
        title = 'Charging Complete';
        body =
            'Please unplug soon · ${energyKwh.toStringAsFixed(2)} kWh · ₱${cost.toStringAsFixed(2)}';
      case 'pending_start':
        title = 'Starting Session…';
        body = 'Connecting to charger';
      default:
        title = 'Charging in Progress';
        body = remainingMin > 0
            ? '$remainingMin min remaining · ${energyKwh.toStringAsFixed(2)} kWh'
            : 'Finishing… · ${energyKwh.toStringAsFixed(2)} kWh';
    }

    const androidDetails = AndroidNotificationDetails(
      'charging_active',
      'Active Charging',
      channelDescription: 'Live progress while a charging session is running',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
    );

    // Android: use a foreground service so the process stays alive
    final androidPlugin = notifs.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.startForegroundService(
        _kChargingActiveId,
        title,
        body,
        notificationDetails: androidDetails,
      );
    } else {
      // iOS: silent background update (no sound/alert — just updates the
      // notification centre entry so users can glance at progress)
      await notifs.show(
        _kChargingActiveId,
        title,
        body,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: false,
            presentSound: false,
            presentBadge: false,
          ),
        ),
      );
    }
  }

  Future<void> _cancelChargingNotification() async {
    final androidPlugin = notifs.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.stopForegroundService();
    await notifs.cancel(_kChargingActiveId);
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    final token = await _fcm.getToken();
    if (token != null) _saveFcmToken(token);
    _fcm.onTokenRefresh.listen(_saveFcmToken);

    AppLogger.instance.info('notification_service_initialized');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'evolvepro_main',
      'EvolvePRO Notifications',
      channelDescription: 'Charging and reservation updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    notifs.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> _saveFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    } catch (_) {}
    AppLogger.instance.info('fcm_token_refreshed');
  }

  /// Show a local "reservation expiring" notification.
  Future<void> showReservationExpiring(String stationName, int minutesLeft) {
    return notifs.show(
      10001,
      'Hold expiring soon',
      'Your hold at $stationName expires in $minutesLeft min.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'evolvepro_reservations',
          'Reservations',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Show a local "charger available" notification.
  Future<void> showChargerAvailable(String stationName) {
    return notifs.show(
      10002,
      'Charger available',
      'A charger at $stationName is now free.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'evolvepro_main',
          'EvolvePRO Notifications',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
