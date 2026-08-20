import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/core/routing/app_router.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_stories_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_story.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_wallet.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_wallet_providers.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_stories_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

MerchantStory _story({
  String id = 'story-1',
  DateTime? createdAt,
  DateTime? expiresAt,
  DateTime? promotedUntil,
  bool isPromotedFlag = false,
  int viewCount = 0,
}) {
  return MerchantStory(
    id: id,
    type: 'text',
    text: 'قصتي الحالية',
    imageUrl: null,
    videoUrl: null,
    createdAt: createdAt ?? DateTime(2026, 4, 8, 12),
    expiresAt: expiresAt ?? DateTime(2026, 4, 9, 12),
    promotedUntil: promotedUntil,
    isPromotedFlag: isPromotedFlag,
    viewCount: viewCount,
  );
}

Widget _buildStoriesApp(_FakeMerchantStoriesRepository repository) {
  final router = GoRouter(
    initialLocation: AppRoutes.merchantStories,
    routes: [
      GoRoute(
        path: AppRoutes.merchantStories,
        builder: (context, state) => const MerchantStoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.merchantWallet,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('wallet destination'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWith((ref) => true),
      merchantVenueIdProvider.overrideWith((ref) async => 'venue-1'),
      merchantStoriesRepositoryProvider.overrideWithValue(repository),
      merchantWalletStreamProvider.overrideWith(
        (ref) => Stream.value(
          MerchantWallet(
            venueId: 'venue-1',
            currency: 'ILS',
            status: MerchantWalletStatus.active,
            availableBalance: 30,
            lowBalanceThreshold: 10,
            createdAt: DateTime(2026, 4, 8),
            updatedAt: DateTime(2026, 4, 8),
          ),
        ),
      ),
    ],
    child: MaterialApp.router(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

Future<void> _tapPromoteButton(WidgetTester tester) async {
  final promoteButton = find.widgetWithText(ElevatedButton, 'ترويج 🚀');
  await tester.scrollUntilVisible(
    promoteButton,
    240,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(promoteButton);
  await tester.pumpAndSettle();
}

void main() {
  group('MerchantStoriesScreen', () {
    testWidgets('shows dynamic promotion pricing options from wallet pricing', (
      tester,
    ) async {
      final repository = _FakeMerchantStoriesRepository(
        stories: <MerchantStory>[_story()],
      );

      await tester.pumpWidget(_buildStoriesApp(repository));
      await tester.pumpAndSettle();

      await _tapPromoteButton(tester);

      expect(find.text('اختر المدة:'), findsOneWidget);
      expect(find.text('يوم واحد (3 ILS)'), findsOneWidget);
      expect(find.text('3 أيام (7 ILS)'), findsOneWidget);
      expect(find.text('أسبوع (14 ILS)'), findsOneWidget);
    });

    testWidgets('shows insufficient balance CTA and navigates to wallet', (
      tester,
    ) async {
      final repository = _FakeMerchantStoriesRepository(
        stories: <MerchantStory>[_story()],
        promoteError: const StoryPromotionFailure(
          code: 'failed-precondition',
          message: 'insufficient_wallet_balance',
        ),
      );

      await tester.pumpWidget(_buildStoriesApp(repository));
      await tester.pumpAndSettle();

      await _tapPromoteButton(tester);
      await tester.tap(find.text('يوم واحد (3 ILS)'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text(
          'الرصيد غير كافٍ لترويج هذه الستوري. اشحن رصيد وين ثم حاول مرة أخرى.',
        ),
        findsOneWidget,
      );
      expect(find.text('فتح رصيد وين'), findsOneWidget);

      await tester.tap(find.text('فتح رصيد وين'));
      await tester.pumpAndSettle();

      expect(find.text('wallet destination'), findsOneWidget);
    });

    testWidgets('shows renew CTA and expiring state for promoted story', (
      tester,
    ) async {
      final repository = _FakeMerchantStoriesRepository(
        stories: <MerchantStory>[
          _story(
            id: 'story-expiring',
            promotedUntil: DateTime.now().add(const Duration(hours: 6)),
            isPromotedFlag: true,
          ),
        ],
      );

      await tester.pumpWidget(_buildStoriesApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('تجديد الترويج'), findsOneWidget);
      expect(find.textContaining('الترويج سينتهي قريبًا'), findsOneWidget);
    });

    testWidgets('shows story view count badge when views are available', (
      tester,
    ) async {
      final repository = _FakeMerchantStoriesRepository(
        stories: <MerchantStory>[_story(viewCount: 23)],
      );

      await tester.pumpWidget(_buildStoriesApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('23 مشاهدة'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('hides story view count badge when views are zero', (
      tester,
    ) async {
      final repository = _FakeMerchantStoriesRepository(
        stories: <MerchantStory>[_story()],
      );

      await tester.pumpWidget(_buildStoriesApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('0 مشاهدة'), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('dismisses promotion loading when story stream updates', (
      tester,
    ) async {
      final repository = _FakeMerchantStoriesRepository(
        stories: <MerchantStory>[_story()],
        emitEmptyStoriesDuringPromotion: true,
      );

      await tester.pumpWidget(_buildStoriesApp(repository));
      await tester.pumpAndSettle();

      await _tapPromoteButton(tester);
      await tester.tap(find.text('يوم واحد (3 ILS)'));
      await tester.pump();

      expect(find.byType(WainLoadingIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(WainLoadingIndicator), findsNothing);
      expect(find.text('✅ تم ترويج الستوري بنجاح!'), findsOneWidget);
    });
  });
}

class _FakeMerchantStoriesRepository implements MerchantStoriesRepository {
  List<MerchantStory> stories;
  final StoryPromotionPricing pricing;
  final Object? promoteError;
  final bool emitEmptyStoriesDuringPromotion;
  final StreamController<List<MerchantStory>> _storyUpdates =
      StreamController<List<MerchantStory>>.broadcast();

  _FakeMerchantStoriesRepository({
    required this.stories,
    StoryPromotionPricing? pricing,
    this.promoteError,
    this.emitEmptyStoriesDuringPromotion = false,
  }) : pricing =
           pricing ??
           const StoryPromotionPricing(
             currency: 'ILS',
             oneDayPrice: 3,
             threeDayPrice: 7,
             sevenDayPrice: 14,
           );

  @override
  Future<void> createStory({
    required String venueId,
    required String text,
    required int expiryHours,
    required String? createdBy,
    XFile? image,
    XFile? video,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteStory({
    required String storyId,
    String? imageUrl,
    String? videoUrl,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<StoryPromotionPricing> getStoryPromotionPricing() async => pricing;

  @override
  Future<bool> hasActiveStory({required String venueId, DateTime? now}) async {
    return stories.isNotEmpty;
  }

  @override
  Future<void> promoteStory({
    required String storyId,
    required int durationDays,
    required String requestId,
  }) async {
    if (promoteError != null) {
      throw promoteError!;
    }
    if (emitEmptyStoriesDuringPromotion) {
      stories = const <MerchantStory>[];
      _storyUpdates.add(stories);
    }
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Stream<List<MerchantStory>> watchStories({
    required String venueId,
    int limit = 20,
  }) {
    return _watchStories();
  }

  Stream<List<MerchantStory>> _watchStories() async* {
    yield stories;
    yield* _storyUpdates.stream;
  }
}
