import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_details_sheet.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_ui_constants.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueMenuPreviewSection extends ConsumerWidget {
  final Venue venue;
  final VoidCallback onOpenMenu;

  const VenueMenuPreviewSection({
    super.key,
    required this.venue,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final menuAsync = ref.watch(menuItemsProvider(venue.id));

    return menuAsync.when(
      loading: () => const _MenuActionCardLoading(),
      error: (error, stackTrace) => _MenuActionCard(
        child: _MenuActionMessage(
          icon: Icons.error_outline_rounded,
          message: l10n.menuLoadFailed,
        ),
      ),
      data: (items) {
        final availableItems = items.where((item) => item.isAvailable).toList();
        final featuredItems = selectVenueFeaturedMenuItems(
          items,
          limit: kVenueFeaturedPreviewLimit,
        );
        final sectionCount = availableItems
            .map((item) => item.category)
            .toSet()
            .length;
        final hasMenuContent =
            availableItems.isNotEmpty || venue.menuImages.isNotEmpty;

        if (!hasMenuContent) {
          return _MenuActionCard(
            child: _MenuActionMessage(
              icon: Icons.menu_book_outlined,
              message: l10n.noMenuAvailable,
            ),
          );
        }

        final isImageOnlyMenu =
            availableItems.isEmpty && venue.menuImages.isNotEmpty;
        final subtitle = availableItems.isNotEmpty
            ? l10n.menuResultsSummary(availableItems.length, sectionCount)
            : isImageOnlyMenu
            ? _previewPhotoCountLabel(l10n, venue.menuImages.length)
            : l10n.menuViewFull;

        return _MenuActionCard(
          onTap: onOpenMenu,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.menuTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              if (featuredItems.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _FeaturedPreviewItems(
                  items: featuredItems,
                  onItemTap: (item) {
                    if (!DemoMode.isDemoVenue(venue.id)) {
                      unawaited(
                        ref
                            .read(analyticsServiceProvider)
                            .logVenueMenuItemOpen(
                              venueId: venue.id,
                              itemId: item.id,
                              sectionId: item.category,
                              surface: 'preview_featured',
                              isFeatured: item.isFeatured,
                            ),
                      );
                    }
                    showVenueMenuItemDetailsSheet(context: context, item: item);
                  },
                ),
              ],
              if (isImageOnlyMenu) ...[
                const SizedBox(height: AppSpacing.lg),
                _MenuImagePreviewItems(images: venue.menuImages),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MenuImagePreviewItems extends StatelessWidget {
  final List<String> images;

  const _MenuImagePreviewItems({required this.images});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleImages = images.take(kVenueMenuPreviewImageLimit).toList();
    final remainingCount = images.length - visibleImages.length;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.menuPhotosTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: kVenueMenuPreviewImageThumbSize,
          child: Row(
            children: [
              for (final image in visibleImages) ...[
                _MenuImagePreviewThumb(url: image),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (remainingCount > 0)
                Container(
                  width: kVenueMenuPreviewImageThumbSize,
                  height: kVenueMenuPreviewImageThumbSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppSpacing.radiusSm,
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    '+$remainingCount',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuImagePreviewThumb extends StatelessWidget {
  final String url;

  const _MenuImagePreviewThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: kVenueMenuPreviewImageThumbSize,
      height: kVenueMenuPreviewImageThumbSize,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.radiusSm,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        memCacheWidth: kMenuItemThumbnailCacheSize,
        memCacheHeight: kMenuItemThumbnailCacheSize,
        maxWidthDiskCache: kMenuItemThumbnailCacheSize,
        maxHeightDiskCache: kMenuItemThumbnailCacheSize,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) =>
            ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
        errorWidget: (context, url, error) => Icon(
          Icons.photo_library_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 22,
        ),
      ),
    );
  }
}

class _FeaturedPreviewItems extends StatelessWidget {
  final List<MenuItem> items;
  final ValueChanged<MenuItem> onItemTap;

  const _FeaturedPreviewItems({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.featuredItems,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index == items.length - 1 ? 0 : AppSpacing.sm,
                ),
                child: _FeaturedPreviewItemPill(
                  item: item,
                  onTap: () => onItemTap(item),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _FeaturedPreviewItemPill extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const _FeaturedPreviewItemPill({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _previewDisplayName(item);
    final price = formatVenueMenuPriceWithCurrency(
      item.price,
      item.currency,
      languageCode: Localizations.localeOf(context).languageCode,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.radiusSm,
        child: Container(
          width: 148,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppSpacing.radiusSm,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _previewDisplayName(MenuItem item) {
  final trimmedAr = item.nameAr.trim();
  if (trimmedAr.isNotEmpty) return trimmedAr;
  final trimmedEn = item.nameEn.trim();
  if (trimmedEn.isNotEmpty) return trimmedEn;
  return '-';
}

String _previewPhotoCountLabel(AppLocalizations l10n, int count) {
  return '$count ${count == 1 ? l10n.photoSingle : l10n.photoPlural}';
}

class _MenuActionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _MenuActionCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.radiusLg,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: AppSpacing.radiusMd,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MenuActionMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MenuActionMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _MenuActionCardLoading extends StatelessWidget {
  const _MenuActionCardLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _MenuActionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 18,
            width: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.radiusFull,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 14,
            width: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.radiusFull,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.radiusMd,
            ),
          ),
        ],
      ),
    );
  }
}
