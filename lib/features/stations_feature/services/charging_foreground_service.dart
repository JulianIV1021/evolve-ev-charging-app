import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'charging_task_handler.dart';

@pragma('vm:entry-point')
void chargingServiceStartCallback() {
  FlutterForegroundTask.setTaskHandler(ChargingTaskHandler());
}

class ChargingForegroundService {
  static Future<void> start({required String sessionId, required String uid}) async {
    await FlutterForegroundTask.saveData(key: 'sessionId', value: sessionId);
    await FlutterForegroundTask.saveData(key: 'uid', value: uid);

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'charging_session',
        channelName: 'Charging Session',
        channelDescription: 'Monitors charging progress in the background',
        onlyAlertOnce: true,
        channelImportance: NotificationChannelImportance.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    await FlutterForegroundTask.startService(
      notificationTitle: 'Charging Session',
      notificationText: 'Monitoring battery...',
      callback: chargingServiceStartCallback,
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}
