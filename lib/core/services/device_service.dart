import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_service.g.dart';

/// Service for device identification and info
class DeviceService {
  final SharedPreferences _prefs;

  static const String _deviceIdKey = 'device_unique_id';

  DeviceService(this._prefs);

  /// Get unique device ID (generates if not exists)
  Future<String> getDeviceId() async {
    String? deviceId = _prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await _prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Generate a unique device ID
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'dev_${timestamp}_$random';
  }

  /// Get device info for analytics
  Map<String, String> getDeviceInfo() {
    return {'platform': _getPlatform(), 'is_web': kIsWeb.toString()};
  }

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}

// ============ PROVIDER ============

@Riverpod(keepAlive: true)
DeviceService deviceService(Ref ref) {
  throw UnimplementedError(
    'deviceServiceProvider must be overridden with SharedPreferences',
  );
}
