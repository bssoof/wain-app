import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/features/venue/domain/entities/venue_place_photo.dart';

class GooglePlacePhotoImage extends StatelessWidget {
  final VenuePlacePhoto photo;
  final BoxFit fit;
  final Widget fallback;
  final bool compactAttribution;
  final double? attributionTop;

  const GooglePlacePhotoImage({
    super.key,
    required this.photo,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.compactAttribution = false,
    this.attributionTop,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          photo.photoUri,
          fit: fit,
          filterQuality: FilterQuality.low,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : fallback,
          errorBuilder: (_, _, _) => fallback,
        ),
        PositionedDirectional(
          start: AppSpacing.sm,
          top: attributionTop,
          bottom: attributionTop == null ? AppSpacing.sm : null,
          child: _GoogleMapsAttribution(
            photo: photo,
            compact: compactAttribution,
          ),
        ),
      ],
    );
  }
}

class _GoogleMapsAttribution extends StatelessWidget {
  final VenuePlacePhoto photo;
  final bool compact;

  const _GoogleMapsAttribution({required this.photo, required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: AppSpacing.radiusSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              link: photo.googleMapsUri.isNotEmpty,
              child: GestureDetector(
                onTap: photo.googleMapsUri.isEmpty
                    ? null
                    : () => _open(photo.googleMapsUri),
                child: Text(
                  'Google Maps',
                  semanticsLabel: 'Google Maps',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (!compact && photo.authorName.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(width: 1, height: 16, color: Colors.white38),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                link: photo.authorUri.isNotEmpty,
                child: GestureDetector(
                  onTap: photo.authorUri.isEmpty
                      ? null
                      : () => _open(photo.authorUri),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (photo.authorPhotoUri.isNotEmpty) ...[
                        ClipOval(
                          child: Image.network(
                            photo.authorPhotoUri,
                            width: 18,
                            height: 18,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 128),
                        child: Text(
                          photo.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
