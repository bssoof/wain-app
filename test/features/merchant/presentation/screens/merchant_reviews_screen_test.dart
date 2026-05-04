import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/merchant/data/repositories/merchant_reviews_repository.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_review.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';
import 'package:wain_app/features/merchant/presentation/screens/merchant_reviews_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

Widget _buildReviewsApp({
  required List<MerchantReview> reviews,
  int? initialFilter,
}) {
  return ProviderScope(
    overrides: [
      merchantVenueIdProvider.overrideWith((ref) async => 'venue-1'),
      merchantReviewsProvider.overrideWith((ref) async => reviews),
      merchantReviewsRepositoryProvider.overrideWithValue(
        _UnusedMerchantReviewsRepository(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MerchantReviewsScreen(initialFilter: initialFilter),
    ),
  );
}

MerchantReview _review({
  required String id,
  required String userName,
  required double rating,
  required String text,
  required DateTime createdAt,
  String? merchantReply,
}) {
  return MerchantReview(
    id: id,
    userName: userName,
    userPhotoUrl: null,
    rating: rating,
    text: text,
    createdAt: createdAt,
    merchantReply: merchantReply,
    merchantReplyAt: null,
    merchantReplyBy: null,
  );
}

void main() {
  group('MerchantReviewsScreen', () {
    testWidgets('applies no-reply filter from initial route state', (
      tester,
    ) async {
      final reviews = <MerchantReview>[
        _review(
          id: 'review-1',
          userName: 'Ali',
          rating: 4,
          text: 'بدون رد',
          createdAt: DateTime(2026, 4, 1),
        ),
        _review(
          id: 'review-2',
          userName: 'Sara',
          rating: 5,
          text: 'عليه رد',
          createdAt: DateTime(2026, 4, 1),
          merchantReply: 'شكراً',
        ),
      ];

      await tester.pumpWidget(
        _buildReviewsApp(reviews: reviews, initialFilter: 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('Sara'), findsNothing);
      expect(find.text('بدون رد'), findsWidgets);
    });
  });
}

class _UnusedMerchantReviewsRepository implements MerchantReviewsRepository {
  @override
  Future<void> deleteReply({
    required String venueId,
    required String reviewId,
  }) async {}

  @override
  Future<void> submitReply({
    required String venueId,
    required String reviewId,
    required String replyText,
    required String authorIdentifier,
  }) async {}
}
