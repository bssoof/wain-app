import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

/// Reusable Venue Card Widget
class VenueCard extends StatelessWidget {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String distance;
  final bool isBestMatch;
  final bool isFavorite;
  final bool? isOpen; // null = unknown, true = open, false = closed
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final String? imageUrl;
  final Timestamp? lastStoryAt;

  const VenueCard({
    super.key,
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.distance,
    this.isBestMatch = false,
    this.isFavorite = false,
    this.isOpen,
    this.onTap,
    this.onFavoriteToggle,
    this.imageUrl,
    this.lastStoryAt,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveStory =
        lastStoryAt != null &&
        lastStoryAt!.toDate().isAfter(
          DateTime.now().subtract(const Duration(hours: 24)),
        );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isBestMatch
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  // Image Content
                  Container(
                    margin: hasActiveStory
                        ? const EdgeInsets.all(3)
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      borderRadius: hasActiveStory
                          ? BorderRadius.circular(13)
                          : const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                      border: hasActiveStory
                          ? Border.all(color: AppTheme.primaryColor, width: 3)
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: hasActiveStory
                          ? BorderRadius.circular(10)
                          : const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                      child: Stack(
                        children: [
                          if (imageUrl != null)
                            CachedNetworkImage(
                              imageUrl: imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              memCacheHeight: 400, // Limit memory usage
                              memCacheWidth: 600,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: WainLoadingIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                    child: Icon(
                                      Icons.restaurant,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                          else
                            Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Best Match Badge
                  if (isBestMatch)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.venueCardBestMatch,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Favorite Button
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: onFavoriteToggle,
                      ),
                    ),
                  ),
                  // Open/Closed Badge
                  if (isOpen != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen! ? Colors.green : Colors.red.shade400,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOpen! ? Icons.check_circle : Icons.cancel,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOpen! ? AppLocalizations.of(context)!.venueCardOpen : AppLocalizations.of(context)!.venueCardClosed,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        distance,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
