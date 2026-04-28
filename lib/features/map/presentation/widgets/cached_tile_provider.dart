import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:wain_app/core/services/tile_cache_service.dart';
import 'dart:ui' as ui;

class CachedTileProvider extends TileProvider {
  final String userAgent;

  CachedTileProvider({required this.userAgent});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return CachedTileImageProvider(url: url, userAgent: userAgent);
  }
}

class CachedTileImageProvider extends ImageProvider<CachedTileImageProvider> {
  final String url;
  final String userAgent;

  CachedTileImageProvider({required this.url, required this.userAgent});

  @override
  Future<CachedTileImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadImage(
    CachedTileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<String>('Url', url),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    CachedTileImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final cacheService = TileCacheService();

      // 1. Check disk
      final file = await cacheService.getTile(url);
      if (file != null && await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
        }
      }

      // 2. Download
      final uri = Uri.parse(url);
      final response = await http.get(uri, headers: {'User-Agent': userAgent});

      if (response.statusCode == 200) {
        // 3. Save to disk (async)
        cacheService.cacheTile(url, response.bodyBytes);

        return await decode(
          await ui.ImmutableBuffer.fromUint8List(response.bodyBytes),
        );
      } else {
        throw Exception('Failed to load tile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Tile Error: $url -> $e');
      throw Exception('Failed to load tile');
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is CachedTileImageProvider && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
