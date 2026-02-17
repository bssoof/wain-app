import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class TileCacheService {
  static final TileCacheService _instance = TileCacheService._internal();
  factory TileCacheService() => _instance;
  TileCacheService._internal();

  bool _isEnabled = true;
  String? _cachePath;

  Future<void> init() async {
    if (!_isEnabled) return;
    if (_cachePath != null) return;
    
    // Quick check for Web (no path_provider needed)
    if (kIsWeb) {
      _isEnabled = false;
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      _cachePath = '${dir.path}/tiles';
      await Directory(_cachePath!).create(recursive: true);
    } catch (e) {
      debugPrint('❌ Failed to init tile cache: $e');
      // If plugin is missing (dev/build issue), disable cache to stop spam.
      if (e.toString().contains('MissingPluginException')) {
        _isEnabled = false;
        debugPrint('⚠️ Tile Cache DISABLED due to MissingPluginException');
      }
    }
  }

  /// Get tile file. If exists locally, return it.
  /// If not, return null (provider should fetch).
  /// Or better: Provider asks for file, if not, provider downloads?
  /// Let's make this service handle "Get or Download".
  Future<File?> getTile(String url, {String? userAgent}) async {
    if (_cachePath == null) await init();
    if (_cachePath == null) return null; // Failed to init

    try {
      final filename = _urlToFilename(url);
      final file = File('$_cachePath/$filename');

      if (await file.exists()) {
        // Enforce 7-day TTL per OSM Policy
        final lastModified = await file.lastModified();
        final now = DateTime.now();
        if (now.difference(lastModified).inDays > 7) {
           // Expired -> Delete to respect freshness headers/policy
           await file.delete();
           return null;
        }
        return file;
      }
    } catch (e) {
      // Ignore disk errors
    }
    return null;
  }

  /// Save data to cache
  Future<void> cacheTile(String url, List<int> bytes) async {
    if (_cachePath == null) return;
    try {
      final filename = _urlToFilename(url);
      final file = File('$_cachePath/$filename');
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('⚠️ Valid to cache tile: $e');
    }
  }

  String _urlToFilename(String url) {
    // Basic hash or sanitization
    return url.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  }
}
