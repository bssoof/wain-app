import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/services/deep_link_service.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/core/utils/geo_utils.dart';
import 'package:wain_app/features/demo/application/demo_session_store.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_image.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/try_list/presentation/providers/try_list_provider.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/domain/entities/venue_place_photo.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/venue/presentation/widgets/google_place_photo_image.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_photo_page_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueHeroHeader extends ConsumerStatefulWidget {
  final Venue venue;
  final bool isFavorite;
  final List<String> displayTags;

  const VenueHeroHeader({
    super.key,
    required this.venue,
    required this.isFavorite,
    required this.displayTags,
  });

  @override
  ConsumerState<VenueHeroHeader> createState() => _VenueHeroHeaderState();
}

class _VenueHeroHeaderState extends ConsumerState<VenueHeroHeader> {
  static const double _imageHeight = 250;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final venue = widget.venue;
    final placePhotos = venue.photos.isEmpty && venue.googlePlaceId.isNotEmpty
        ? ref
              .watch(venuePlacePhotosProvider(venue.id))
              .when(
                data: (photos) => photos,
                loading: () => const <VenuePlacePhoto>[],
                error: (_, _) => const <VenuePlacePhoto>[],
              )
        : const <VenuePlacePhoto>[];
    final isDemo = DemoMode.isDemoVenue(venue.id);
    // Location is a real device permission and a real GPS read; the demo must
    // not request either. A fixed sample distance keeps the row populated.
    final distanceText = isDemo
        ? '1.2 ${l10n.kilometerUnit}'
        : ref
              .watch(userLocationProvider)
              .when(
                data: (position) {
                  final distanceKm = calculateDistanceKm(
                    position.latitude,
                    position.longitude,
                    venue.lat,
                    venue.lng,
                  );
                  if (distanceKm < 1) {
                    return '${(distanceKm * 1000).toInt()} ${l10n.meterUnit}';
                  }
                  return '${distanceKm.toStringAsFixed(1)} ${l10n.kilometerUnit}';
                },
                loading: () => '...',
                error: (_, _) => l10n.venueSummaryNotAvailable,
              );

    // The image and the info panel used to share one fixed 420px SliverAppBar,
    // which left the panel a fixed 141px remainder — too little for a two-line
    // Arabic title, the English name, the metadata row, and the chips. They are
    // now separate slivers: the app bar owns only the image (and therefore only
    // needs to be as tall as the image), and the panel sits in a
    // SliverToBoxAdapter where it takes its own intrinsic height. Grouped so the
    // caller still receives exactly one sliver, and no nested scrolling is
    // introduced.
    return SliverMainAxisGroup(
      slivers: [
        _buildImageAppBar(
          context,
          venue,
          theme: theme,
          l10n: l10n,
          placePhotos: placePhotos,
        ),
        SliverToBoxAdapter(
          child: _buildInfoPanel(context, venue, distanceText: distanceText),
        ),
      ],
    );
  }

  Widget _buildImageAppBar(
    BuildContext context,
    Venue venue, {
    required ThemeData theme,
    required AppLocalizations l10n,
    required List<VenuePlacePhoto> placePhotos,
  }) {
    return SliverAppBar(
      expandedHeight: _imageHeight,
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: IconButton(
        icon: _circleIcon(
          context,
          Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
        ),
        onPressed: () {
          context.popOrGo('/results');
        },
      ),
      actions: [
        IconButton(
          icon: _circleIcon(
            context,
            Icon(
              widget.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: AppTheme.errorColor,
            ),
          ),
          onPressed: () {
            if (DemoMode.isDemoVenue(venue.id)) {
              ref.read(demoSessionStoreProvider.notifier).toggleFavourite(
                venue.id,
              );
              return;
            }
            ref.read(favoritesListProvider.notifier).toggle(venue.id);
          },
        ),
        IconButton(
          icon: _circleIcon(
            context,
            DemoMode.isDemoVenue(venue.id)
                ? Icon(
                    ref.watch(
                          demoSessionStoreProvider.select(
                            (s) => s.tryListVenueIds.contains(venue.id),
                          ),
                        )
                        ? Icons.flag_rounded
                        : Icons.flag_outlined,
                    color: ref.watch(
                          demoSessionStoreProvider.select(
                            (s) => s.tryListVenueIds.contains(venue.id),
                          ),
                        )
                        ? AppTheme.primaryColor
                        : theme.colorScheme.onSurfaceVariant,
                  )
                : ref
                      .watch(isInTryListProvider(venue.id))
                      .when(
                        data: (inList) => Icon(
                          inList ? Icons.flag_rounded : Icons.flag_outlined,
                          color: inList
                              ? AppTheme.primaryColor
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        loading: () => Icon(
                          Icons.flag_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        error: (_, _) => Icon(
                          Icons.flag_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
          ),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            if (DemoMode.isDemoVenue(venue.id)) {
              final store = ref.read(demoSessionStoreProvider.notifier);
              store.toggleTryList(venue.id);
              final added = store.isOnTryList(venue.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    added
                        ? l10n.tryListAdded
                        : l10n.tryListRemoved(venue.nameAr),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            final added = await ref
                .read(tryListNotifierProvider.notifier)
                .toggle(venue.id);
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  added ? l10n.tryListAdded : l10n.tryListRemoved(venue.nameAr),
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: _circleIcon(
            context,
            Icon(
              Icons.share_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onPressed: () async {
            // Share opens the OS share sheet through a platform channel and
            // logs a real analytics event; neither may happen for the demo.
            if (DemoMode.isDemoVenue(venue.id)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('غير متاح في وضع العرض'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            ref
                .read(analyticsServiceProvider)
                .logShareClick(
                  venueId: venue.id,
                  venueName: venue.nameAr,
                  city: venue.city,
                  source: 'venue_details',
                );
            await DeepLinkService.shareVenue(
              venueId: venue.id,
              venueName: venue.nameAr,
              city: venue.city,
              shareMessage: l10n.shareVenueText,
              rating: venue.rating,
              category: venue.categories.isNotEmpty
                  ? venue.categories.first
                  : null,
            );
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: SizedBox(
          height: _imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              venue.photos.isNotEmpty || placePhotos.isNotEmpty
                  ? _buildPhotoGallery(context, venue, placePhotos)
                  : _buildHeroFallback(context),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.darkSurface.withAlpha(65),
                        Colors.transparent,
                        AppTheme.darkSurface.withAlpha(35),
                      ],
                      stops: const [0, 0.42, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Intrinsically sized: whatever the title, metadata, and chips need, they
  /// get. Nothing here is clipped, scrolled, or shrunk to fit.
  Widget _buildInfoPanel(
    BuildContext context,
    Venue venue, {
    required String distanceText,
  }) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width > 720 ? 640 : width),
          child: Container(
            key: const ValueKey('venue-hero-info-panel'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(90),
                ),
              ),
            ),
            child: _VenueHeroInfoOverlay(
              venue: venue,
              displayTags: widget.displayTags,
              distanceText: distanceText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            AppTheme.primarySurfaceColor,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 68,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.venue.nameAr,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(226),
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outline.withAlpha(110)),
        boxShadow: const [],
      ),
      child: child,
    );
  }

  Widget _buildPhotoGallery(
    BuildContext context,
    Venue venue,
    List<VenuePlacePhoto> placePhotos,
  ) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio.clamp(1.0, 2.0);
    final cacheWidth = (mediaQuery.size.width * devicePixelRatio).round();

    final photoCount = venue.photos.isNotEmpty
        ? venue.photos.length
        : placePhotos.length;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: photoCount,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, index) {
            if (venue.photos.isNotEmpty) {
              // Routed through VenueMenuItemImage because a venue photo may be
              // a bundled `asset://` path, which CachedNetworkImage cannot
              // resolve — it failed silently to the fallback icon, so the demo
              // gallery rendered six broken images.
              return VenueMenuItemImage(
                imageUrl: venue.photos[index],
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                placeholder: _buildHeroFallback(context),
              );
            }
            return GooglePlacePhotoImage(
              photo: placePhotos[index],
              fallback: _buildHeroFallback(context),
              attributionTop: 120,
            );
          },
        ),
        if (photoCount > 1)
          Positioned(
            top: 92,
            left: 0,
            right: 0,
            child: Center(
              child: VenuePhotoPageIndicator(
                photoCount: photoCount,
                currentIndex: _currentPage,
              ),
            ),
          ),
        if (photoCount > 1)
          Positioned(
            top: 88,
            right: AppSpacing.lg,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs + 1,
              ),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withAlpha(170),
                borderRadius: AppSpacing.radiusMd,
              ),
              child: Text(
                '${_currentPage + 1}/$photoCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.surface,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VenueHeroInfoOverlay extends StatelessWidget {
  final Venue venue;
  final List<String> displayTags;
  final String distanceText;

  const _VenueHeroInfoOverlay({
    required this.venue,
    required this.displayTags,
    required this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final chips = <String>[
      if (venue.categories.isNotEmpty) venue.categories.first,
      ...displayTags.take(2),
      if (displayTags.length > 2) '+${displayTags.length - 2}',
    ];
    final isOpenNow = venue.isOpenNow();
    final statusText = isOpenNow == null
        ? l10n.venueSummaryNotAvailable
        : (isOpenNow ? l10n.openNow : l10n.closed);
    final priceRange = _resolvePriceRange() ?? l10n.venueSummaryNotAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          venue.nameAr,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (venue.nameEn.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            venue.nameEn,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs + 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _InlineMetaItem(
              text: venue.rating.toStringAsFixed(1),
              icon: Icons.star_rounded,
              iconColor: AppTheme.warningColor,
            ),
            _metaSeparator(theme),
            Text(
              statusText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isOpenNow == true
                    ? AppTheme.successColor.withAlpha(235)
                    : isOpenNow == false
                    ? AppTheme.errorColor
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            _metaSeparator(theme),
            _InlineMetaItem(
              text: distanceText,
              icon: Icons.near_me_outlined,
              textColor: theme.colorScheme.onSurfaceVariant,
              iconColor: theme.colorScheme.onSurfaceVariant,
            ),
            _metaSeparator(theme),
            Text(
              priceRange,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: chips
                .map((chip) => _buildChip(context, chip))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  Widget _metaSeparator(ThemeData theme) {
    return Text(
      '•',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.outline,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCategory =
        venue.categories.isNotEmpty && label == venue.categories.first;
    final isOverflow = label.startsWith('+');
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isCategory
            ? AppTheme.primarySurfaceColor
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.radiusFull,
        border: Border.all(
          color: isCategory
              ? AppTheme.primaryColor.withAlpha(65)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: isCategory
              ? AppTheme.primaryColor
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: isCategory ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );

    if (!isOverflow) return chip;

    return Semantics(
      button: true,
      label: l10n.venueShowAllFeatures,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('venue-more-features'),
          borderRadius: AppSpacing.radiusFull,
          onTap: () => _showAllFeatures(context),
          child: chip,
        ),
      ),
    );
  }

  Future<void> _showAllFeatures(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tags = displayTags.toSet().toList(growable: false);

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.venueAllFeaturesTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.45,
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              backgroundColor: AppTheme.primarySurfaceColor,
                              side: BorderSide.none,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _resolvePriceRange() {
    final min = venue.minPrice;
    final max = venue.maxPrice;
    if (min <= 0 || max <= 0 || max < min) {
      return null;
    }
    return '$min-$max ${venue.currency}';
  }
}

class _InlineMetaItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? textColor;
  final Color? iconColor;

  const _InlineMetaItem({
    required this.text,
    required this.icon,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Icon(icon, size: 14, color: iconColor ?? theme.colorScheme.onSurface),
      ],
    );
  }
}
