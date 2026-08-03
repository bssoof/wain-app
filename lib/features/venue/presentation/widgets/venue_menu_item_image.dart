import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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

    const assetPrefix = 'asset://';
    if (normalizedUrl.startsWith(assetPrefix)) {
      final assetPath = normalizedUrl.substring(assetPrefix.length);
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
