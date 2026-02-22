import 'package:flutter/foundation.dart';

class PlatformLogger {
  static void info(String component, String message, {String? platform}) {
    debugPrint(_format('INFO', component, message, platform: platform));
  }

  static void warn(String component, String message, {String? platform}) {
    debugPrint(_format('WARN', component, message, platform: platform));
  }

  static void error(
    String component,
    String message, {
    String? platform,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final suffix = error == null ? '' : ' | error: $error';
    debugPrint(
      _format('ERROR', component, '$message$suffix', platform: platform),
    );
    if (stackTrace != null && kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static String _format(
    String level,
    String component,
    String message, {
    String? platform,
  }) {
    final platformPart = platform == null ? '' : '[$platform]';
    return '[$level][$component]$platformPart $message';
  }
}
