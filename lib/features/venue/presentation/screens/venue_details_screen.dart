import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/app_error_widget.dart';
import 'package:wain_app/core/widgets/app_skeleton.dart';
import 'package:wain_app/core/widgets/offline_widgets.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import '../../../offers/presentation/screens/offer_qr_code_screen.dart';
import '../../domain/entities/venue.dart';
import '../providers/venue_providers.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../reviews/presentation/widgets/reviews_section.dart';
import '../../../offers/presentation/providers/offers_providers.dart';
import '../../../transport/presentation/widgets/venue_transport_card.dart';
import '../widgets/venue_hero_header.dart';
import '../widgets/venue_busy_times_section.dart';
import '../widgets/venue_hours_section.dart';
import '../widgets/venue_menu_preview_section.dart';
import '../widgets/venue_offers_section.dart';
import '../widgets/venue_social_links_section.dart';
import '../widgets/venue_stories_section.dart';

@visibleForTesting
class VenueViewRouteAttribution {
  final String source;
  final String? storyId;

  const VenueViewRouteAttribution({required this.source, this.storyId});
}

@visibleForTesting
VenueViewRouteAttribution resolveVenueViewRouteAttribution(Object? extra) {
  if (extra is Map<String, dynamic>) {
    final source = extra['source'];
    final storyId = extra['storyId'];
    return VenueViewRouteAttribution(
      source: source is String && source.trim().isNotEmpty
          ? source.trim()
          : 'venue_details',
      storyId: storyId is String && storyId.trim().isNotEmpty
          ? storyId.trim()
          : null,
    );
  }

  return const VenueViewRouteAttribution(source: 'venue_details');
}

/// Venue Details Screen
class VenueDetailsScreen extends ConsumerStatefulWidget {
  final String venueId;

  const VenueDetailsScreen({super.key, required this.venueId});

  @override
  ConsumerState<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends ConsumerState<VenueDetailsScreen>
    with TickerProviderStateMixin {
  bool _hasLoggedView = false;
  late final TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!mounted) return;
    if (_selectedTabIndex != _tabController.index) {
      _selectedTabIndex = _tabController.index;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // Launch Maps with deep link
  Future<void> _openMaps(double lat, double lng, String navApp) async {
    Uri uri;
    if (navApp == 'waze') {
      uri = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
      );
    }

    // Try to launch in external app first, fallback to browser
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback: open in browser
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // Last resort: try browser
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  // Show BottomSheet and log navigation click
  void _showMapsBottomSheet(
    BuildContext context,
    String venueId,
    double lat,
    double lng,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.selectMapApp, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withAlpha(24),
                  borderRadius: AppSpacing.radiusMd,
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: AppTheme.infoColor,
                  size: 28,
                ),
              ),
              title: Text(
                l10n.brandGoogleMaps,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(l10n.openInGoogleMaps),
              onTap: () async {
                Navigator.pop(ctx);
                final analytics = ref.read(analyticsServiceProvider);
                analytics.trackNavClick(
                  venueId: venueId,
                  navApp: 'google_maps',
                  source: 'venue_details',
                );
                // Try to log navigation click (don't block if fails)
                try {
                  await ref.read(
                    logNavigationClickProvider(
                      venueId: venueId,
                      navApp: 'google_maps',
                    ).future,
                  );
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('Failed to log navigation click: $e');
                  }
                }
                // Open maps (always)
                await _openMaps(lat, lng, 'google_maps');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurfaceColor,
                  borderRadius: AppSpacing.radiusMd,
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              title: Text(l10n.brandWaze, style: theme.textTheme.titleMedium),
              subtitle: Text(l10n.openInWaze),
              onTap: () async {
                Navigator.pop(ctx);
                final analytics = ref.read(analyticsServiceProvider);
                analytics.trackNavClick(
                  venueId: venueId,
                  navApp: 'waze',
                  source: 'venue_details',
                );
                // Try to log navigation click (don't block if fails)
                try {
                  await ref.read(
                    logNavigationClickProvider(
                      venueId: venueId,
                      navApp: 'waze',
                    ).future,
                  );
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('Failed to log navigation click: $e');
                  }
                }
                // Open maps (always)
                await _openMaps(lat, lng, 'waze');
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  AppException _asAppException(Object error) {
    if (error is AppException) return error;
    return ServerException(message: error.toString());
  }

  Object? _routeExtra() {
    try {
      return GoRouterState.of(context).extra;
    } catch (_) {
      return null;
    }
  }

  void _logVenueViewIfNeeded(Venue venue) {
    if (_hasLoggedView) return;
    _hasLoggedView = true;

    final attribution = resolveVenueViewRouteAttribution(_routeExtra());
    final analytics = ref.read(analyticsServiceProvider);
    analytics.logVenueViewFull(
      venueId: venue.id,
      venueName: venue.nameAr,
      city: venue.city,
      source: attribution.source,
    );
    analytics.trackVenueEvent(
      venueId: venue.id,
      eventType: 'view',
      source: attribution.source,
      storyId: attribution.storyId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final venueSnapshotAsync = ref.watch(
      venueByIdSnapshotProvider(widget.venueId),
    );
    final venueAsync = ref.watch(venueByIdProvider(widget.venueId));
    final isFavorite = ref.watch(
      favoritesListProvider.select(
        (favoritesAsync) => favoritesAsync.maybeWhen(
          data: (favorites) => favorites.contains(widget.venueId),
          orElse: () => false,
        ),
      ),
    );

    return Scaffold(
      body: venueAsync.when(
        loading: () => const VenueDetailsSkeleton(),
        error: (err, stack) => AppErrorWidget(
          exception: _asAppException(err),
          onRetry: () {
            ref.invalidate(venueByIdSnapshotProvider(widget.venueId));
            ref.invalidate(venueByIdProvider(widget.venueId));
          },
        ),
        data: (venue) {
          final venueSnapshot = venueSnapshotAsync.asData?.value;
          final showOfflineEmpty =
              venue == null &&
              venueSnapshot != null &&
              !venueSnapshot.hasData &&
              venueSnapshot.isFromCache &&
              venueSnapshot.fetchedAt == null &&
              !ref.read(isOnlineProvider);
          if (showOfflineEmpty) {
            return const OfflineEmptyState(
              title: 'لا توجد نسخة محفوظة لهذا المكان',
              subtitle: 'افتح المكان مرة واحدة أثناء الاتصال لحفظ نسخة محلية.',
            );
          }

          if (venue == null) {
            return AppEmptyState(
              icon: Icons.storefront_outlined,
              message: l10n.venueNotFound,
            );
          }

          _logVenueViewIfNeeded(venue);

          // Combined tags for display (Mood + Occasion)
          final displayTags = <String>[
            ...venue.tags.mood,
            ...venue.tags.occasion,
          ];

          return NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: OfflineBanner(
                    isVisible: venueSnapshot?.isFromCache ?? false,
                    fetchedAt: venueSnapshot?.fetchedAt,
                  ),
                ),
                VenueHeroHeader(
                  venue: venue,
                  isFavorite: isFavorite,
                  displayTags: displayTags,
                ),
                if (venue.transportEnabled)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: VenueTransportCard(
                        venue: venue,
                        onOpenNavigation: () {
                          _showMapsBottomSheet(
                            context,
                            venue.id,
                            venue.lat,
                            venue.lng,
                          );
                        },
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xs),
                ),
                SliverPersistentHeader(
                  pinned: false,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabAlignment: TabAlignment.fill,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppTheme.primarySurfaceColor,
                        borderRadius: AppSpacing.radiusFull,
                        border: Border.all(
                          color: AppTheme.primaryColor.withAlpha(36),
                        ),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      splashBorderRadius: AppSpacing.radiusFull,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(child: _TabLabel(text: l10n.tabOffersMenu)),
                        Tab(child: _TabLabel(text: l10n.tabAbout)),
                        Tab(child: _TabLabel(text: l10n.tabReviews)),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: _buildActiveTabBody(venue),
          );
        },
      ),
      bottomNavigationBar: venueAsync.asData?.value != null
          ? Consumer(
              builder: (context, ref, _) {
                final venue = venueAsync.asData!.value!;
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: AppShadows.overlay,
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Call Button (working)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: venue.phone.isNotEmpty
                                ? () async {
                                    final analytics = ref.read(
                                      analyticsServiceProvider,
                                    );
                                    analytics.logCallClick(
                                      venueId: venue.id,
                                      venueName: venue.nameAr,
                                      city: venue.city,
                                      source: 'venue_details',
                                    );
                                    analytics.trackVenueEvent(
                                      venueId: venue.id,
                                      eventType: 'call',
                                      source: 'venue_details',
                                    );
                                    final uri = Uri.parse(
                                      'tel:${venue.normalizedPhone}',
                                    );
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.phone),
                            label: Text(l10n.call),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.radiusMd,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // WhatsApp Button (working)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: venue.phone.isNotEmpty
                                ? () async {
                                    final analytics = ref.read(
                                      analyticsServiceProvider,
                                    );
                                    analytics.logEvent(
                                      name: 'whatsapp_click',
                                      parameters: {
                                        'venue_id': venue.id,
                                        'venue_name': venue.nameAr,
                                        'city': venue.city,
                                        'source': 'venue_details',
                                      },
                                    );
                                    analytics.trackVenueEvent(
                                      venueId: venue.id,
                                      eventType: 'call',
                                      source: 'venue_details',
                                    );
                                    final uri = Uri.parse(
                                      'https://wa.me/${venue.normalizedPhone}',
                                    );
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.chat),
                            label: Text(l10n.whatsapp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.radiusMd,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Navigate Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showMapsBottomSheet(
                                context,
                                venue.id,
                                venue.lat,
                                venue.lng,
                              );
                            },
                            icon: const Icon(Icons.navigation),
                            label: Text(l10n.navigate),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.radiusMd,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  void _showClaimConfirmation(Offer offer, String city, String venueName) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importantNotice, textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.offerValidTenMinutes,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.offerActivationWarning,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleOfferClaim(offer, city, venueName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text(l10n.activateOfferNow),
          ),
        ],
      ),
    );
  }

  void _openFullMenu(String venueId) {
    context.pushNamed('venue-menu', pathParameters: {'id': venueId});
  }

  String _claimErrorMessage(BuildContext context, String? error) {
    final l10n = AppLocalizations.of(context)!;
    switch (error) {
      case 'offer_already_used':
        return l10n.offerErrorAlreadyUsed;
      case 'offer_expired':
        return l10n.offerErrorExpired;
      case 'offer_inactive':
      case 'offer_not_started':
        return l10n.offerErrorUnavailable;
      case 'app_check_failed':
        return l10n.inviteAppCheckFailed;
      case 'claim_save_failed':
      case null:
      case '':
        return l10n.claimRequestFailed;
      default:
        return error;
    }
  }

  void _handleOfferClaim(Offer offer, String city, String venueName) async {
    final success = await ref
        .read(claimOfferProvider.notifier)
        .claim(offer: offer, source: 'venue_details', city: city);

    if (!mounted) return;

    if (success != null) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OfferQRCodeScreen(
            claimResult: success,
            offer: offer,
            venueName: venueName,
          ),
        ),
      );
    } else {
      final error = ref.read(claimOfferProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.errorPrefix}: '
            '${_claimErrorMessage(context, error)}',
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildActiveTabBody(Venue venue) {
    switch (_selectedTabIndex) {
      case 0:
        final offersMenuChildren = <Widget>[
          VenueOffersSection(
            venue: venue,
            onClaimOffer: (offer) {
              final isOnline = ref.read(isOnlineProvider);
              if (!isOnline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'تحتاج إلى اتصال بالإنترنت لتفعيل العرض',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              _showClaimConfirmation(offer, venue.city, venue.nameAr);
            },
          ),
          const SizedBox(height: 16),
          VenueMenuPreviewSection(
            venue: venue,
            onOpenMenu: () => _openFullMenu(venue.id),
          ),
        ];
        return CustomScrollView(
          key: const PageStorageKey<String>('offers_menu_tab'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => offersMenuChildren[index],
                  childCount: offersMenuChildren.length,
                ),
              ),
            ),
          ],
        );
      case 1:
        final aboutChildren = <Widget>[
          VenueStoriesSection(venueId: venue.id),
          const SizedBox(height: 16),
          VenueWorkingHoursSection(venue: venue),
          const SizedBox(height: 16),
          VenueBusyTimesSection(venue: venue),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          if (venue.hasSocialLinks) ...[VenueSocialLinksSection(venue: venue)],
        ];
        return CustomScrollView(
          key: const PageStorageKey<String>('about_tab'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => aboutChildren[index],
                  childCount: aboutChildren.length,
                ),
              ),
            ),
          ],
        );
      default:
        return CustomScrollView(
          key: const PageStorageKey<String>('reviews_tab'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return switch (index) {
                    0 => ReviewsSection(
                      venueId: venue.id,
                      venueName: venue.nameAr,
                    ),
                    _ => null,
                  };
                }, childCount: 1),
              ),
            ),
          ],
        );
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppSpacing.radiusFull,
          border: Border.all(color: theme.colorScheme.outline),
          boxShadow: overlapsContent ? AppShadows.elevated : const [],
        ),
        child: Padding(padding: const EdgeInsets.all(4), child: tabBar),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _TabLabel extends StatelessWidget {
  final String text;

  const _TabLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }
}
