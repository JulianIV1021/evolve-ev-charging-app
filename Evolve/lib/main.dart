import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'navigation/app_router.dart';
import 'services/notification_service.dart';

final FlutterLocalNotificationsPlugin notifs =
    FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifs() async {
  const androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();

  await notifs.initialize(const InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  ));

  // Android 13+ needs runtime permission
  final android = notifs
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();

  // Pre-create notification channels so Android registers them immediately.
  // Without this, release builds may silently drop notifications.
  await android?.createNotificationChannel(const AndroidNotificationChannel(
    'charging',
    'Charging Alerts',
    description: 'Alerts when charging completes or idle fee starts',
    importance: Importance.high,
  ));
  await android?.createNotificationChannel(const AndroidNotificationChannel(
    'charging_active',
    'Active Charging',
    description: 'Live progress while a charging session is running',
    importance: Importance.low,
  ));
  await android?.createNotificationChannel(const AndroidNotificationChannel(
    'evolvepro_main',
    'EvolvePRO Notifications',
    description: 'Charging and reservation updates',
    importance: Importance.high,
  ));
  await android?.createNotificationChannel(const AndroidNotificationChannel(
    'evolvepro_reservations',
    'Reservations',
    description: 'Hold and reservation alerts',
    importance: Importance.high,
  ));

  // iOS permission
  final ios = notifs
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
  await ios?.requestPermissions(alert: true, badge: true, sound: true);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initLocalNotifs();
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: EvolveProApp()));
}

class EvolveProApp extends StatelessWidget {
  const EvolveProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EvolvePRO',
      routerConfig: appRouter,
      localizationsDelegates: const [
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFFF5A623),
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
        textTheme: CupertinoTextThemeData(
          primaryColor: Color(0xFFF5A623),
        ),
      ),
      builder: (context, child) => DefaultTextStyle.merge(
        style: const TextStyle(decoration: TextDecoration.none),
        child: child!,
      ),
    );
  }
}
