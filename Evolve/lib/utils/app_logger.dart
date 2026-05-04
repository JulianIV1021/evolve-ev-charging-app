import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error }

/// Structured application logger.
///
/// - Debug builds: prints to console with timestamp.
/// - Release builds: sends errors to FirebaseCrashlytics.
///
/// Rules:
/// - NEVER log email addresses, passwords, tokens, or full addresses.
/// - Always include a correlation_id for user-initiated actions.
/// - Never call inside build() methods — only in event handlers / services.
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  void log({
    required LogLevel level,
    required String event,
    Map<String, dynamic> data = const {},
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = {'event': event, 'level': level.name, 'ts': timestamp, ...data};

    if (kDebugMode) {
      final prefix = switch (level) {
        LogLevel.info => '[INFO]',
        LogLevel.warning => '[WARN]',
        LogLevel.error => '[ERROR]',
      };
      debugPrint('$prefix $entry');
    }

    if (level == LogLevel.error && !kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        entry,
        null,
        reason: event,
        printDetails: false,
      );
    }
  }

  void info(String event, [Map<String, dynamic> data = const {}]) =>
      log(level: LogLevel.info, event: event, data: data);

  void warning(String event, [Map<String, dynamic> data = const {}]) =>
      log(level: LogLevel.warning, event: event, data: data);

  void error(String event, [Map<String, dynamic> data = const {}]) =>
      log(level: LogLevel.error, event: event, data: data);
}
