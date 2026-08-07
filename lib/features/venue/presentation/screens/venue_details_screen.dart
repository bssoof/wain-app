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
import 'package:wain_app/features/demo/application/demo_session_store.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/demo/presentation/demo_badge.dart';
import 'package:wain_app/features/demo/presentation/demo_data_notice.dart';
import 'package:wain_app/features/demo/presentation/demo_offer_qr_sheet.dart';
import 'package:wain_app/features/demo/presentation/demo_transport_card.dart';
import 'package:wain_app/features/demo/presentation/demo_unavailable_section.dart';
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

  /// True when the external action was swallowed because this is the demo.
  ///
  /// Every outward-facing action on this screen funnels through here, so the
  /// demo can never dial a number, open WhatsApp, or hand off to a maps app.
  bool _blockExternalActionInDemo() {
    if (!DemoMode.isDemoVenue(widget.venueId)) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('غير متاح في وضع العرض'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return true;
  }

  // Launch Maps with deep link
  Future<void> _openMaps(double lat, double lng, String navApp) async {
    if (_blockExternalActionInDemo()) return;
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
                if (_blockExternalActionInDemo()) return;
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
                if (_blockExternalActionInDemo()) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final venueSnapshotAsync = ref.watch(
      venueByIdSnapshotProvider(widget.venueId),
    );
    final venueAsync = ref.watch(venueByIdProvider(widget.venueId));
    // Favourites for the demo venue live in DemoSessionStore, so the
    // production favourites repository is never read or written.
    final isDemo = DemoMode.isDemoVenue(widget.venueId);
    final isFavorite = isDemo
        ? ref.watch(
            demoSessionStoreProvider.select(
              (state) => state.favouriteVenueIds.contains(widget.venueId),
            ),
          )
        : ref.watch(
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

          final isDemoVenue = DemoMode.isDemoVenue(venue.id);

          // Log venue view (only once per session).
          // The demo venue is not a real subscriber, so the screen must not
          // reach AnalyticsService at all — not even to have the service drop
          // the event internally, because logVenueViewFull writes straight to
          // FirebaseAnalytics before any venue-scoped guard could run.
          if (!_hasLoggedView && !isDemoVenue) {
            _hasLoggedView = true;
            final analytics = ref.read(analyticsServiceProvider);
            analytics.logVenueViewFull(
              venueId: venue.id,
              venueName: venue.nameAr,
              city: venue.city,
              source: 'venue_details',
            );
            analytics.trackVenueEvent(
              venueId: venue.id,
              eventType: 'view',
              source: 'venue_details',
            );
          }

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
                // Sits between the hero panel and the transport card: after the
                // information it qualifies, before the first actionable
                // surface, and outside the tab bodies so it survives every tab.
                if (isDemoVenue)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: DemoModeBadge(),
                    ),
                  ),
                if (isDemoVenue)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: DemoTransportCard(),
                    ),
                  )
                else if (venue.transportEnabled)
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
                    topInset: MediaQuery.paddingOf(context).top,
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
                                    if (_blockExternalActionInDemo()) return;
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
                                    if (_blockExternalActionInDemo()) return;
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
              // Activation in the demo stops at a locally drawn, inert QR: no
              // callable, no claim document, no redeemable token.
              if (DemoMode.isDemoVenue(venue.id)) {
                DemoOfferQrSheet.show(context, offer);
                return;
              }
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
        final isDemoAbout = DemoMode.isDemoVenue(venue.id);
        final aboutChildren = <Widget>[
          // Stories now come from the local demo catalog, so the real section
          // renders for the demo too.
          VenueStoriesSection(venueId: venue.id),
          const SizedBox(height: 16),
          // Hours and busy times are already served from the local demo
          // catalogs, so they render for real.
          VenueWorkingHoursSection(venue: venue),
          const SizedBox(height: 16),
          VenueBusyTimesSection(venue: venue),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // No "unavailable" card in the walkthrough: the section simply is not
          // there, which reads as a venue without social links rather than as a
          // feature that has been switched off.
          if (isDemoAbout && !DemoMode.showDemoLabels)
            const SizedBox.shrink()
          else if (isDemoAbout)
            const DemoUnavailableSection(
              icon: Icons.link_off,
              title: 'الروابط الخارجية',
            )
          else if (venue.hasSocialLinks)
            VenueSocialLinksSection(venue: venue),
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
                  if (index != 0) return null;
                  final isDemo = DemoMode.isDemoVenue(venue.id);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Named for what they are, so nobody reads the rating as
                      // a real one.
                      if (isDemo) ...[
                        const DemoDataNotice(label: 'مراجعات تجريبية'),
                        const SizedBox(height: 16),
                      ],
                      ReviewsSection(
                        venueId: venue.id,
                        venueName: venue.nameAr,
                      ),
                    ],
                  );
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

  /// Height of the system status bar.
  ///
  /// The hero app bar floats away on scroll, leaving this header pinned at the
  /// very top of the screen — where it collided with the clock and the wifi
  /// icons. The inset has to live in the extents as well as the padding, or the
  /// sliver reports a height it does not occupy.
  final double topInset;

  _SliverAppBarDelegate(this.tabBar, {this.topInset = 0});

  @override
  double get minExtent => tabBar.preferredSize.height + topInset;

  @override
  double get maxExtent => tabBar.preferredSize.height + topInset;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(20, 8 + topInset, 20, 6),
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
    return oldDelegate.topInset != topInset;
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
