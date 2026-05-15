import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_funnel.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_analytics_summary.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_content_health.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_venue.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_dashboard_screen.dart';
import 'package:wain_app/features/merchant/presentation/widgets/dashboard/merchant_dashboard_analytics_overview.dart';
import 'package:wain_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:wain_app/l10n/app_localizations.dart';

MerchantVenue _venue({
  List<String> photos = const <String>[],
  List<String> categories = const <String>['Restaurant'],
  List<String> moodLabels = const <String>['Chill'],
  Map<String, List<MerchantVenueHoursSlot>> hours =
      const <String, List<MerchantVenueHoursSlot>>{},
  bool is24Hours = false,
}) {
  return MerchantVenue(
    id: 'venue-1',
    nameAr: 'Test Venue',
    nameEn: 'Test Venue',
    city: 'Ramallah',
    phone: '0591234567',
    photos: photos,
    categories: categories,
    moodLabels: moodLabels,
    hours: hours,
    is24Hours: is24Hours,
    activeMenuVersionId: null,
    lastStoryAt: null,
    rating: 4.2,
    minPrice: 20,
    maxPrice: 80,
    lat: 31.9,
    lng: 35.2,
  );
}

Widget _buildDashboardApp() {
  final venue = _venue();

  return ProviderScope(
    overrides: [
      merchantVenueIdProvider.overrideWith((ref) async => 'venue-1'),
      merchantVenueProvider.overrideWith((ref) async => venue),
      merchantStatsProvider.overrideWith((ref) async => MerchantStats.empty()),
      merchantOffersProvider.overrideWith((ref) async => <MerchantOffer>[]),
      merchantReviewsProvider.overrideWith((ref) async => <MerchantReview>[]),
      merchantAnalyticsProvider.overrideWith(
        (ref) async => MerchantAnalytics.empty(),
      ),
      merchantDashboardAnalyticsDrilldownProvider.overrideWith(
        (ref) async => buildMerchantAnalyticsDrilldownPayload(
          analytics: MerchantAnalytics.empty(),
          currentPoints: const <MerchantDailyPoint>[],
          previousPoints: const <MerchantDailyPoint>[],
          periodDays: 7,
          offers: const <MerchantOfferAnalyticsSummary>[],
        ),
      ),
      merchantContentHealthProvider.overrideWith(
        (ref) async => const MerchantContentHealth.empty(),
      ),
      merchantAnalyticsDailyProvider(14).overrideWith((ref) async => []),
      merchantAnalyticsDailyProvider(7).overrideWith((ref) async => []),
      merchantAnalyticsDailyProvider(30).overrideWith((ref) async => []),
      merchantAnalyticsDailyProvider(60).overrideWith((ref) async => []),
      unreadNotificationsCountProvider.overrideWith((ref) => Stream.value(0)),
    ],
    child: const MaterialApp(
      locale: Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MerchantDashboardScreen(),
    ),
  );
}

MerchantReview _review({
  required String id,
  required String userName,
  DateTime? createdAt,
  String? merchantReply,
  DateTime? merchantReplyAt,
}) {
  return MerchantReview(
    id: id,
    userName: userName,
    userPhotoUrl: null,
    rating: 4,
    text: 'review',
    createdAt: createdAt,
    merchantReply: merchantReply,
    merchantReplyAt: merchantReplyAt,
    merchantReplyBy: merchantReply == null ? null : 'merchant',
  );
}

MerchantOffer _offer({
  required String id,
  required String titleAr,
  required bool isActive,
  MerchantOfferStatus? status,
  DateTime? endAt,
  int claimsCount = 0,
  int redeemedCount = 0,
}) {
  return MerchantOffer(
    id: id,
    venueId: 'venue-1',
    titleAr: titleAr,
    title: '',
    descriptionAr: '',
    description: '',
    termsAr: '',
    discountType: 'percent',
    discountValue: 0,
    singleUsePerCustomer: true,
    isActive: isActive,
    startAt: null,
    endAt: endAt,
    status: status,
    claimsCount: claimsCount,
    redeemedCount: redeemedCount,
    conversionRate: null,
    isFeatured: false,
    featuredUntil: null,
  );
}

void main() {
  group('MerchantDashboardScreen', () {
    testWidgets('renders safely when daily analytics are empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDashboardApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('يحتاج انتباهك'), findsOneWidget);
    });

    testWidgets('shows story attribution chip only when visits exist', (
      tester,
    ) async {
      final summary = buildMerchantAnalyticsSummary(
        analytics: MerchantAnalytics.empty(),
        currentPoints: const <MerchantDailyPoint>[
          MerchantDailyPoint(
            dateKey: '2026-04-01',
            views: 12,
            calls: 0,
            navs: 0,
            storyViews: 7,
            storyToVenueViews: 3,
          ),
        ],
        previousPoints: const <MerchantDailyPoint>[],
        periodDays: 7,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantAnalyticsSummaryProvider.overrideWith(
              (ref) async => summary,
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: MerchantDashboardStatsSection(showDetailCta: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('دخول من الستوري: 3'), findsOneWidget);
      expect(find.textContaining('معدل التحويل: 43%'), findsOneWidget);
    });

    testWidgets('hides action feed when nothing is actionable', (tester) async {
      final venue = _venue();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantVenueIdProvider.overrideWith((ref) async => 'venue-1'),
            merchantVenueProvider.overrideWith((ref) async => venue),
            merchantStatsProvider.overrideWith(
              (ref) async => MerchantStats.empty(),
            ),
            merchantOffersProvider.overrideWith(
              (ref) async => <MerchantOffer>[],
            ),
            merchantReviewsProvider.overrideWith(
              (ref) async => <MerchantReview>[],
            ),
            merchantAnalyticsProvider.overrideWith(
              (ref) async => MerchantAnalytics(
                viewsTotal: 0,
                viewsThisWeek: 0,
                viewsLastWeek: 0,
                callsTotal: 0,
                callsThisWeek: 0,
                callsLastWeek: 0,
                navsTotal: 0,
                navsThisWeek: 0,
                navsLastWeek: 0,
                storyViewsTotal: 0,
                storyViewsThisWeek: 0,
                updatedAt: DateTime.now(),
              ),
            ),
            merchantDashboardAnalyticsDrilldownProvider.overrideWith(
              (ref) async => buildMerchantAnalyticsDrilldownPayload(
                analytics: MerchantAnalytics.empty(),
                currentPoints: const <MerchantDailyPoint>[],
                previousPoints: const <MerchantDailyPoint>[],
                periodDays: 7,
                offers: const <MerchantOfferAnalyticsSummary>[],
              ),
            ),
            merchantContentHealthProvider.overrideWith(
              (ref) async => const MerchantContentHealth.empty(),
            ),
            merchantAnalyticsDailyProvider(14).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(7).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(30).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(60).overrideWith((ref) async => []),
            unreadNotificationsCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MerchantDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('يحتاج انتباهك'), findsNothing);
    });

    testWidgets('shows offer performance summary and per-offer metrics', (
      tester,
    ) async {
      final venue = _venue();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantVenueIdProvider.overrideWith((ref) async => 'venue-1'),
            merchantVenueProvider.overrideWith((ref) async => venue),
            merchantStatsProvider.overrideWith(
              (ref) async => MerchantStats.empty(),
            ),
            merchantOffersProvider.overrideWith(
              (ref) async => <MerchantOffer>[
                _offer(
                  id: 'offer-1',
                  titleAr: 'أفضل عرض',
                  isActive: true,
                  status: MerchantOfferStatus.active,
                  claimsCount: 10,
                  redeemedCount: 6,
                ),
                _offer(
                  id: 'offer-2',
                  titleAr: 'عرض منتهي',
                  isActive: true,
                  status: MerchantOfferStatus.active,
                  endAt: DateTime(2026, 4, 1),
                  claimsCount: 4,
                  redeemedCount: 1,
                ),
              ],
            ),
            merchantReviewsProvider.overrideWith(
              (ref) async => <MerchantReview>[],
            ),
            merchantAnalyticsProvider.overrideWith(
              (ref) async => MerchantAnalytics.empty(),
            ),
            merchantDashboardAnalyticsDrilldownProvider.overrideWith(
              (ref) async => buildMerchantAnalyticsDrilldownPayload(
                analytics: MerchantAnalytics.empty(),
                currentPoints: const <MerchantDailyPoint>[],
                previousPoints: const <MerchantDailyPoint>[],
                periodDays: 7,
                offers: const <MerchantOfferAnalyticsSummary>[],
              ),
            ),
            merchantContentHealthProvider.overrideWith(
              (ref) async => const MerchantContentHealth.empty(),
            ),
            merchantAnalyticsDailyProvider(14).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(7).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(30).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(60).overrideWith((ref) async => []),
            unreadNotificationsCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MerchantDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('14 مهتم'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('أفضل عرض'), findsWidgets);
      expect(find.text('14 مهتم'), findsOneWidget);
      expect(find.text('7 تم الاستفادة'), findsOneWidget);
      expect(find.text('50% تحويل'), findsOneWidget);
      expect(find.text('فعّال'), findsWidgets);
      expect(find.text('منتهي'), findsWidgets);
    });

    testWidgets('shows redesigned analytics summary and insights', (
      tester,
    ) async {
      final venue = _venue();
      final comparisonPoints = <MerchantDailyPoint>[
        const MerchantDailyPoint(
          dateKey: '2026-03-23',
          views: 6,
          calls: 1,
          navs: 0,
          storyViews: 1,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-03-24',
          views: 5,
          calls: 0,
          navs: 1,
          storyViews: 1,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-03-25',
          views: 6,
          calls: 1,
          navs: 0,
          storyViews: 1,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-03-26',
          views: 7,
          calls: 1,
          navs: 0,
          storyViews: 2,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-03-27',
          views: 5,
          calls: 0,
          navs: 1,
          storyViews: 1,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-03-28',
          views: 7,
          calls: 1,
          navs: 0,
          storyViews: 2,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-03-29',
          views: 6,
          calls: 1,
          navs: 0,
          storyViews: 1,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-03-30',
          views: 10,
          calls: 2,
          navs: 1,
          storyViews: 3,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-03-31',
          views: 11,
          calls: 2,
          navs: 1,
          storyViews: 4,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-04-01',
          views: 12,
          calls: 2,
          navs: 1,
          storyViews: 4,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-04-02',
          views: 14,
          calls: 3,
          navs: 1,
          storyViews: 5,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-04-03',
          views: 13,
          calls: 2,
          navs: 1,
          storyViews: 5,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-04-04',
          views: 12,
          calls: 2,
          navs: 1,
          storyViews: 4,
        ),
        const MerchantDailyPoint(
          dateKey: '2026-04-05',
          views: 12,
          calls: 2,
          navs: 1,
          storyViews: 4,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantVenueIdProvider.overrideWith((ref) async => 'venue-1'),
            merchantVenueProvider.overrideWith((ref) async => venue),
            merchantStatsProvider.overrideWith(
              (ref) async => MerchantStats.empty(),
            ),
            merchantOffersProvider.overrideWith(
              (ref) async => <MerchantOffer>[],
            ),
            merchantReviewsProvider.overrideWith(
              (ref) async => <MerchantReview>[],
            ),
            merchantAnalyticsProvider.overrideWith(
              (ref) async => MerchantAnalytics(
                viewsTotal: 300,
                viewsThisWeek: 84,
                viewsLastWeek: 42,
                callsTotal: 60,
                callsThisWeek: 15,
                callsLastWeek: 5,
                navsTotal: 44,
                navsThisWeek: 7,
                navsLastWeek: 2,
                storyViewsTotal: 70,
                storyViewsThisWeek: 29,
                updatedAt: DateTime.now(),
              ),
            ),
            merchantDashboardAnalyticsDrilldownProvider.overrideWith(
              (ref) async => buildMerchantAnalyticsDrilldownPayload(
                analytics: MerchantAnalytics(
                  viewsTotal: 300,
                  viewsThisWeek: 84,
                  viewsLastWeek: 42,
                  callsTotal: 60,
                  callsThisWeek: 15,
                  callsLastWeek: 5,
                  navsTotal: 44,
                  navsThisWeek: 7,
                  navsLastWeek: 2,
                  storyViewsTotal: 70,
                  storyViewsThisWeek: 29,
                  updatedAt: DateTime.now(),
                ),
                currentPoints: comparisonPoints.sublist(7),
                previousPoints: comparisonPoints.sublist(0, 7),
                periodDays: 7,
                offers: const <MerchantOfferAnalyticsSummary>[
                  MerchantOfferAnalyticsSummary(
                    offerId: 'offer-1',
                    offerTitleAr: 'عرض رمضان',
                    status: MerchantOfferStatus.active,
                    detailViews7d: 18,
                    claimClicks7d: 9,
                    claimsCreated7d: 5,
                    redemptions7d: 4,
                    claimToRedemptionRate7d: 0.8,
                    updatedAt: null,
                  ),
                ],
              ),
            ),
            merchantContentHealthProvider.overrideWith(
              (ref) async => const MerchantContentHealth.empty(),
            ),
            merchantAnalyticsDailyProvider(
              14,
            ).overrideWith((ref) async => comparisonPoints),
            merchantAnalyticsDailyProvider(
              7,
            ).overrideWith((ref) async => comparisonPoints.sublist(7)),
            merchantAnalyticsDailyProvider(30).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(60).overrideWith((ref) async => []),
            unreadNotificationsCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MerchantDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('المشاهدات هذه الفترة'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('تحليلات الأداء'), findsOneWidget);
      expect(find.text('المشاهدات هذه الفترة'), findsOneWidget);
      expect(find.text('نية التواصل: 22'), findsOneWidget);
      expect(find.text('معدل التواصل: 26%'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('المشاهدات ترتفع'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('أبرز الإشارات'), findsOneWidget);
      expect(find.text('الملاحظات'), findsOneWidget);
      expect(find.text('المشاهدات ترتفع'), findsOneWidget);
      expect(find.text('الزيارات ترتفع لكن التحويل لا يتحرك'), findsOneWidget);
      expect(find.text('فَنِل التحويل'), findsOneWidget);
      expect(find.text('أفضل العروض'), findsOneWidget);
      expect(find.text('عرض رمضان'), findsOneWidget);
    });

    testWidgets('shows review quality summary from merchant reviews provider', (
      tester,
    ) async {
      final now = DateTime.now();
      final venue = _venue();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantVenueIdProvider.overrideWith((ref) async => 'venue-1'),
            merchantVenueProvider.overrideWith((ref) async => venue),
            merchantStatsProvider.overrideWith(
              (ref) async => MerchantStats(
                rating: 4.3,
                reviewCount: 3,
                recentReviews: [
                  _review(
                    id: 'review-1',
                    userName: 'A',
                    createdAt: now.subtract(const Duration(hours: 4)),
                  ),
                ],
              ),
            ),
            merchantOffersProvider.overrideWith(
              (ref) async => <MerchantOffer>[],
            ),
            merchantReviewsProvider.overrideWith(
              (ref) async => <MerchantReview>[
                _review(
                  id: 'review-1',
                  userName: 'A',
                  createdAt: now.subtract(const Duration(hours: 6)),
                  merchantReply: 'thanks',
                  merchantReplyAt: now.subtract(const Duration(hours: 4)),
                ),
                _review(
                  id: 'review-2',
                  userName: 'B',
                  createdAt: now.subtract(const Duration(hours: 10)),
                  merchantReply: 'appreciated',
                  merchantReplyAt: now.subtract(const Duration(hours: 4)),
                ),
                _review(
                  id: 'review-3',
                  userName: 'C',
                  createdAt: now.subtract(const Duration(hours: 36)),
                ),
              ],
            ),
            merchantAnalyticsProvider.overrideWith(
              (ref) async => MerchantAnalytics.empty(),
            ),
            merchantDashboardAnalyticsDrilldownProvider.overrideWith(
              (ref) async => buildMerchantAnalyticsDrilldownPayload(
                analytics: MerchantAnalytics.empty(),
                currentPoints: const <MerchantDailyPoint>[],
                previousPoints: const <MerchantDailyPoint>[],
                periodDays: 7,
                offers: const <MerchantOfferAnalyticsSummary>[],
              ),
            ),
            merchantContentHealthProvider.overrideWith(
              (ref) async => const MerchantContentHealth.empty(),
            ),
            merchantAnalyticsDailyProvider(14).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(7).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(30).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(60).overrideWith((ref) async => []),
            unreadNotificationsCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MerchantDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('67% نسبة الرد'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('جودة الردود'), findsOneWidget);
      expect(find.text('67% نسبة الرد'), findsOneWidget);
      expect(find.text('4 س متوسط الرد'), findsOneWidget);
      expect(find.text('أقدم تقييم بلا رد: 1 ي'), findsOneWidget);
    });

    testWidgets('shows content health issues section from provider', (
      tester,
    ) async {
      final venue = _venue();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantVenueIdProvider.overrideWith((ref) async => 'venue-1'),
            merchantVenueProvider.overrideWith((ref) async => venue),
            merchantStatsProvider.overrideWith(
              (ref) async => MerchantStats.empty(),
            ),
            merchantOffersProvider.overrideWith(
              (ref) async => <MerchantOffer>[],
            ),
            merchantReviewsProvider.overrideWith(
              (ref) async => <MerchantReview>[],
            ),
            merchantAnalyticsProvider.overrideWith(
              (ref) async => MerchantAnalytics.empty(),
            ),
            merchantDashboardAnalyticsDrilldownProvider.overrideWith(
              (ref) async => buildMerchantAnalyticsDrilldownPayload(
                analytics: MerchantAnalytics.empty(),
                currentPoints: const <MerchantDailyPoint>[],
                previousPoints: const <MerchantDailyPoint>[],
                periodDays: 7,
                offers: const <MerchantOfferAnalyticsSummary>[],
              ),
            ),
            merchantContentHealthProvider.overrideWith(
              (ref) async => buildMerchantContentHealth(
                hasActiveMenu: false,
                menuPublishedAt: null,
                photoCount: 2,
                hasActiveStory: false,
                lastStoryAt: DateTime.now().subtract(const Duration(days: 20)),
                is24Hours: false,
                validHoursDays: 0,
                hasName: true,
                hasCity: true,
                hasPhone: true,
                hasCategory: true,
                hasPhoto: false,
              ),
            ),
            merchantAnalyticsDailyProvider(14).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(7).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(30).overrideWith((ref) async => []),
            merchantAnalyticsDailyProvider(60).overrideWith((ref) async => []),
            unreadNotificationsCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MerchantDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('صحة المحتوى'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('صحة المحتوى'), findsOneWidget);
      expect(find.text('لا توجد قائمة منشورة حالياً.'), findsOneWidget);
      expect(
        find.text('لديك فقط 2 صورة. أضف صوراً أكثر لزيادة جاذبية المحل.'),
        findsOneWidget,
      );
      expect(
        find.text('لا توجد ستوريات نشطة، وآخر نشر كان قبل 20 يوم.'),
        findsOneWidget,
      );
      expect(
        find.text('أضف ساعات العمل حتى يعرف الزبائن متى تزورك.'),
        findsOneWidget,
      );
    });
  });
}
