import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

const String _assetPrefix = 'asset://';

/// The [ImageProvider] form of the same rule [VenueMenuItemImage] applies.
///
/// Needed wherever an image is supplied as a provider rather than a widget —
/// `DecorationImage`, `CircleAvatar.backgroundImage` — which cannot be handed a
/// widget. Without it those call sites pass a bundled `asset://` path to
/// `NetworkImage`, which fails the request and renders nothing.
ImageProvider venueImageProvider(String imageUrl) {
  final normalizedUrl = imageUrl.trim();
  if (normalizedUrl.startsWith(_assetPrefix)) {
    return AssetImage(normalizedUrl.substring(_assetPrefix.length));
  }
  return CachedNetworkImageProvider(normalizedUrl);
}

class VenueMenuItemImage extends StatelessWidget {
  const VenueMenuItemImage({
    super.key,
    required this.imageUrl,
    required this.placeholder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final String imageUrl;
  final Widget placeholder;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl.trim();
    if (normalizedUrl.isEmpty) return placeholder;

    if (normalizedUrl.startsWith(_assetPrefix)) {
      final assetPath = normalizedUrl.substring(_assetPrefix.length);
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return CachedNetworkImage(
      imageUrl: normalizedUrl,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.low,
      memCacheWidth: cacheWidth,
      maxWidthDiskCache: cacheWidth,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, _) => placeholder,
      errorWidget: (context, url, error) => placeholder,
    );
  }
}
