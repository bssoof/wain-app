import 'dart:math' show asin, cos, pi, sin, sqrt;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wain_app/core/services/deep_link_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/features/offers/presentation/providers/offers_providers.dart';
import '../../../offers/presentation/screens/offer_qr_code_screen.dart';
import 'package:wain_app/features/offers/presentation/widgets/offer_card.dart';
import '../../../stories/domain/entities/story.dart';
import '../../../stories/presentation/screens/story_viewer_screen.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../domain/entities/venue.dart';
import '../providers/venue_providers.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../try_list/presentation/providers/try_list_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../reviews/presentation/widgets/reviews_section.dart';
import '../../../menu/presentation/providers/menu_providers.dart';
import '../../../menu/domain/entities/menu_item.dart';

/// Venue Details Screen
class VenueDetailsScreen extends ConsumerStatefulWidget {
  final String venueId;

  const VenueDetailsScreen({super.key, required this.venueId});

  @override
  ConsumerState<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends ConsumerState<VenueDetailsScreen> {
  bool _hasLoggedView = false;
  final PageController _photoPageController = PageController();
  int _currentPhotoPage = 0;

  @override
  void dispose() {
    _photoPageController.dispose();
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'اختر تطبيق الخرائط',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map, color: Colors.blue, size: 28),
              ),
              title: const Text(
                'Google Maps',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('فتح في خرائط جوجل'),
              onTap: () async {
                Navigator.pop(ctx);
                // Try to log navigation click (don't block if fails)
                try {
                  await ref.read(
                    logNavigationClickProvider(
                      venueId: venueId,
                      navApp: 'google_maps',
                    ).future,
                  );
                } catch (e) {
                  debugPrint('Failed to log navigation click: $e');
                }
                // Open maps (always)
                await _openMaps(lat, lng, 'google_maps');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.lightBlue,
                  size: 28,
                ),
              ),
              title: const Text(
                'Waze',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('فتح في ويز'),
              onTap: () async {
                Navigator.pop(ctx);
                // Try to log navigation click (don't block if fails)
                try {
                  await ref.read(
                    logNavigationClickProvider(
                      venueId: venueId,
                      navApp: 'waze',
                    ).future,
                  );
                } catch (e) {
                  debugPrint('Failed to log navigation click: $e');
                }
                // Open maps (always)
                await _openMaps(lat, lng, 'waze');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch to keep alive/observe
    ref.watch(claimOfferProvider);
    final venueAsync = ref.watch(venueByIdProvider(widget.venueId));

    // Favorites
    final favoritesAsync = ref.watch(favoritesListProvider);
    final favorites = favoritesAsync.when(
      data: (list) => list,
      loading: () => <String>[],
      error: (_, _) => <String>[],
    );
    final isFavorite = favorites.contains(widget.venueId);

    return Scaffold(
      body: venueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (venue) {
          if (venue == null) {
            return const Center(child: Text('المكان غير موجود'));
          }

          // Log venue view (only once per session)
          if (!_hasLoggedView) {
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
          final displayTags = [
            ...venue.tags.mood,
            ...venue.tags.occasion,
          ].take(5).toList();

          return CustomScrollView(
            slivers: [
              // Header Image
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
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
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/results');
                    }
                  },
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
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
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(favoritesListProvider.notifier)
                          .toggle(widget.venueId);
                    },
                  ),
                  // Try List button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
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
                      child: ref
                          .watch(isInTryListProvider(widget.venueId))
                          .when(
                            data: (isInList) => Icon(
                              isInList ? Icons.flag : Icons.flag_outlined,
                              color: isInList
                                  ? AppTheme.primaryColor
                                  : Colors.grey,
                            ),
                            loading: () => const Icon(
                              Icons.flag_outlined,
                              color: Colors.grey,
                            ),
                            error: (_, _) => const Icon(
                              Icons.flag_outlined,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final added = await ref
                          .read(tryListNotifierProvider.notifier)
                          .toggle(widget.venueId);
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            added
                                ? '🎯 تمت الإضافة لقائمة "بدي أجرّب"'
                                : 'تم الحذف من القائمة',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  // Share button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
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
                      child: const Icon(Icons.share, color: Colors.grey),
                    ),
                    onPressed: () async {
                      // Log share click
                      final v = venueAsync.asData?.value;
                      if (v != null) {
                        ref
                            .read(analyticsServiceProvider)
                            .logShareClick(
                              venueId: v.id,
                              venueName: v.nameAr,
                              city: v.city,
                              source: 'venue_details',
                            );
                        // Share venue via native share sheet with deep link
                        await DeepLinkService.shareVenue(
                          venueId: v.id,
                          venueName: v.nameAr,
                          city: v.city,
                          rating: v.rating,
                          category: v.categories.isNotEmpty
                              ? v.categories.first
                              : null,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: venue.photos.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            // Photo Gallery Slider
                            PageView.builder(
                              controller: _photoPageController,
                              itemCount: venue.photos.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentPhotoPage = i),
                              itemBuilder: (context, index) {
                                return CachedNetworkImage(
                                  imageUrl: venue.photos[index],
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) =>
                                      Container(color: Colors.grey.shade300),
                                  errorWidget: (_, _, _) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Dot indicators (only if more than 1 photo)
                            if (venue.photos.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(venue.photos.length, (
                                    i,
                                  ) {
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      width: _currentPhotoPage == i ? 20 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _currentPhotoPage == i
                                            ? Colors.white
                                            : Colors.white54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            // Photo counter badge
                            if (venue.photos.length > 1)
                              Positioned(
                                top: 100,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_currentPhotoPage + 1}/${venue.photos.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Name & Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                venue.nameAr,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Category
                                  Text(
                                    venue.categories.isNotEmpty
                                        ? venue.categories.first
                                        : 'عام',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Open/Closed Badge
                                  Builder(
                                    builder: (_) {
                                      final isOpen = venue.isOpenNow();
                                      if (isOpen == null)
                                        return const SizedBox.shrink();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOpen
                                              ? Colors.green.shade50
                                              : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isOpen
                                                ? Colors.green.shade300
                                                : Colors.red.shade300,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: isOpen
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isOpen ? 'مفتوح' : 'مغلق',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isOpen
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${venue.rating}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: displayTags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag, // Needs localization? Using keys for now as per updated Schema
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // === MENU SECTION ===
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildMenuSection(venue),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // === OFFERS SECTION ===
                    _buildOffersSection(venue),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // === STORIES SECTION ===
                    _buildStoriesSection(venue.id),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // === REVIEWS SECTION ===
                    ReviewsSection(venueId: venue.id, venueName: venue.nameAr),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // === WORKING HOURS ===
                    _buildWorkingHoursSection(venue),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // === SOCIAL LINKS ===
                    if (venue.hasSocialLinks) ...[
                      _buildSocialLinksSection(venue),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],

                    // Info Items
                    _buildInfoRow(Icons.location_on_outlined, venue.city),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.attach_money,
                      '${venue.minPrice} - ${venue.maxPrice} ${venue.currency}',
                    ),
                    const SizedBox(height: 12),
                    // Real distance from user location
                    _buildDistanceRow(venue),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: venueAsync.asData?.value != null
          ? Consumer(
              builder: (context, ref, _) {
                final venue = venueAsync.asData!.value!;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
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
                            label: const Text('اتصال'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                            label: const Text('واتساب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                            label: const Text('توجيه'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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

  // === MENU SECTION (Structured + Image Fallback) ===
  Widget _buildMenuSection(Venue venue) {
    final venueCategory = venue.categories.isNotEmpty
        ? venue.categories.first
        : 'restaurant';
    final menuAsync = ref.watch(menuItemsProvider(venue.id));
    final sections = ref.watch(menuSectionsProvider(venueCategory));

    return menuAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuHeader(),
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
      error: (_, __) => _buildMenuImagesOnly(venue),
      data: (items) {
        if (items.isEmpty) {
          return venue.menuImages.isNotEmpty
              ? _buildMenuImagesOnly(venue)
              : const SizedBox.shrink();
        }

        final grouped = <String, List<MenuItem>>{};
        for (final item in items.where((i) => i.isAvailable)) {
          grouped.putIfAbsent(item.category, () => []).add(item);
        }

        final activeSections = sections
            .where(
              (s) => grouped.containsKey(s.id) && grouped[s.id]!.isNotEmpty,
            )
            .toList();

        if (activeSections.isEmpty) {
          return venue.menuImages.isNotEmpty
              ? _buildMenuImagesOnly(venue)
              : const SizedBox.shrink();
        }

        final featured = items
            .where((i) => i.isFeatured && i.isAvailable)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuHeader(itemCount: items.length),
            const SizedBox(height: 16),

            // Featured items
            if (featured.isNotEmpty) ...[
              const Text(
                '⭐ الأصناف المميزة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: featured.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _buildFeaturedCard(featured[i]),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Sections with items
            ...activeSections.map((section) {
              final sectionItems = grouped[section.id]!
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${section.icon} ${section.nameAr}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...sectionItems.map((item) => _buildMenuItemTile(item)),
                  const Divider(height: 24),
                ],
              );
            }),

            // Also show image gallery if available
            if (venue.menuImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildMenuImagesOnly(venue),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMenuHeader({int? itemCount}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.restaurant_menu,
            color: Colors.orange.shade800,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'المنيو',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (itemCount != null)
          Text(
            '$itemCount صنف',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
      ],
    );
  }

  Widget _buildFeaturedCard(MenuItem item) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: item.photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.photoUrl,
                    height: 100,
                    width: 150,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(height: 100, color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => Container(
                      height: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  )
                : Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price} ${item.currency}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemTile(MenuItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (item.photoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item.photoUrl,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 55,
                  height: 55,
                  color: Colors.grey.shade200,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 55,
                  height: 55,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.fastfood,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          if (item.photoUrl.isNotEmpty) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nameAr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (item.descriptionAr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.descriptionAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${item.price} ${item.currency}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuImagesOnly(Venue venue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: Colors.orange.shade800,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'المنيو',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${venue.menuImages.length} صور',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: venue.menuImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final url = venue.menuImages[index];
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: InteractiveViewer(
                        child: CachedNetworkImage(imageUrl: url),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: 150,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 150,
                      height: 200,
                      color: Colors.grey.shade200,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 150,
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // === OFFERS SECTION ===
  Widget _buildOffersSection(Venue venue) {
    final venueId = venue.id;
    final city = venue.city;
    final offersAsync = ref.watch(offersByVenueProvider(venueId: venueId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_offer, color: Colors.amber.shade700),
            ),
            const SizedBox(width: 12),
            const Text(
              'العروض المتاحة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Offers list
        offersAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400),
                const SizedBox(width: 12),
                const Text('فشل تحميل العروض'),
              ],
            ),
          ),
          data: (offers) {
            if (offers.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.card_giftcard_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد عروض حالياً',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تابعنا للحصول على عروض جديدة',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: offers.map((offer) {
                return OfferCard(
                  offer: offer,
                  onClaim: () =>
                      _showClaimConfirmation(offer, city, venue.nameAr),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showClaimConfirmation(Offer offer, String city, String venueName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ تنبيه هام', textAlign: TextAlign.right),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هذا العرض صالح لمدة 10 دقائق فقط!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 8),
            Text(
              'يرجى عدم تفعيل العرض إلا عند تواجدك داخل المطعم وأمام الكاشير.\n\nبمجرد التفعيل، سيبدأ العداد ولن تتمكن من إيقافه.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleOfferClaim(offer, city, venueName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('تفعيل العرض الآن'),
          ),
        ],
      ),
    );
  }

  /// Handle offer claim
  void _handleOfferClaim(Offer offer, String city, String venueName) async {
    final success = await ref
        .read(claimOfferProvider.notifier)
        .claim(offer: offer, source: 'venue_details', city: city);

    if (!mounted) return;

    if (success != null) {
      if (!mounted) return;
      // Navigate to QR Screen
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
          content: Text('❌ ${error ?? 'فشل في تسجيل الطلب'}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // === Stories Helper Methods ===
  Widget _buildStoriesSection(String venueId) {
    final storiesAsync = ref.watch(venueStoriesProvider(venueId));

    return storiesAsync.when(
      data: (rawStories) {
        if (rawStories.isEmpty) return const SizedBox.shrink();

        // Convert raw maps to Story objects for the viewer
        final storyObjects = rawStories.map((map) {
          // Create a fake DocumentSnapshot-like conversion
          final createdAt =
              (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
          final expiresAt =
              (map['expires_at'] as Timestamp?)?.toDate() ??
              DateTime.now().add(const Duration(hours: 24));
          return Story(
            id: map['id'] ?? '',
            venueId: map['venue_id'] ?? venueId,
            venueName: map['venue_name'] ?? '',
            venuePhotoUrl: map['venue_photo_url'],
            type: map['type'] ?? 'text',
            imageUrl: map['image_url'],
            videoUrl: map['video_url'],
            text: map['text'] ?? '',
            offerRef: map['offer_ref'],
            createdAt: createdAt,
            expiresAt: expiresAt,
            viewCount: (map['view_count'] as num?)?.toInt() ?? 0,
            durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 5,
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'قصص المحل 📖',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: storyObjects.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final story = storyObjects[index];
                  final imageUrl = story.imageUrl;
                  final isVideo = story.isVideo;

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoryViewerScreen.single(
                            stories: storyObjects,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                            image: imageUrl != null
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.grey.shade200,
                          ),
                          child: imageUrl == null
                              ? Icon(
                                  isVideo ? Icons.videocam : Icons.text_fields,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 70,
                          child: Text(
                            story.text.isNotEmpty
                                ? story.text
                                : (isVideo ? '🎬' : 'قصة'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  // === WORKING HOURS ===
  Widget _buildWorkingHoursSection(Venue venue) {
    final todayText = venue.todayHoursText;
    if (todayText == null && venue.hours.isEmpty)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.access_time,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'ساعات العمل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (todayText != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  todayText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (venue.hours.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...venue.hours.entries.map((entry) {
            final dayName = _arabicDayName(entry.key);
            final slots = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      slots.isEmpty
                          ? 'مغلق'
                          : slots
                                .map((s) => '${s.open} - ${s.close}')
                                .join(' ، '),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  String _arabicDayName(String key) {
    const names = {
      'monday': 'الإثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
      'sunday': 'الأحد',
    };
    return names[key.toLowerCase()] ?? key;
  }

  // === SOCIAL LINKS ===
  Widget _buildSocialLinksSection(Venue venue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.link, color: Colors.purple.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'روابط التواصل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (venue.instagram.isNotEmpty)
              _socialChip(
                Icons.camera_alt,
                'Instagram',
                'https://instagram.com/${venue.instagram}',
              ),
            if (venue.facebook.isNotEmpty)
              _socialChip(Icons.facebook, 'Facebook', venue.facebook),
            if (venue.website.isNotEmpty)
              _socialChip(Icons.language, 'Website', venue.website),
            if (venue.whatsapp.isNotEmpty)
              _socialChip(
                Icons.chat,
                'WhatsApp',
                'https://wa.me/${venue.whatsappNumber}',
              ),
          ],
        ),
      ],
    );
  }

  Widget _socialChip(IconData icon, String label, String url) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  // === INFO ROW ===
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  // === DISTANCE ROW ===
  Widget _buildDistanceRow(Venue venue) {
    final locationAsync = ref.watch(userLocationProvider);
    return locationAsync.when(
      data: (pos) {
        if (pos == null) {
          return _buildInfoRow(Icons.near_me, 'الموقع غير متاح');
        }
        final dist = _calculateDistance(
          pos.latitude,
          pos.longitude,
          venue.lat,
          venue.lng,
        );
        final distText = dist < 1
            ? '${(dist * 1000).toInt()} م'
            : '${dist.toStringAsFixed(1)} كم';
        return _buildInfoRow(Icons.near_me, '$distText بعيد');
      },
      loading: () => _buildInfoRow(Icons.near_me, 'جاري تحديد الموقع...'),
      error: (_, __) => _buildInfoRow(Icons.near_me, 'تعذر تحديد الموقع'),
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0; // km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * r * asin(sqrt(a));
  }
}
