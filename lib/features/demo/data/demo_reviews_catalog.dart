import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/reviews/domain/entities/review.dart';

const String _img = 'asset://assets/images/demo_menu';

/// Fixed base date so the "x days ago" labels never drift during a demo.
final DateTime demoReviewsBaseDate = DateTime.utc(2026, 7, 20, 12);

/// Six reviews with a deliberately uneven rating spread, two carrying a
/// merchant reply.
///
/// The names are invented placeholders — no real person is quoted, credited, or
/// implied — and only two carry an avatar so the initials fallback is on show
/// as well.
List<Review> buildDemoReviews() {
  return <Review>[
    Review(
      id: 'demo_review_1',
      userId: 'demo_user_1',
      userName: 'زائر تجريبي أ',
      userPhotoUrl: '$_img/cafe_latte.jpg',
      rating: 5,
      text: 'القهوة ممتازة والجلسة هادئة جدًا. مكان مناسب للعمل لساعات طويلة.',
      venueId: DemoMode.venueId,
      createdAt: demoReviewsBaseDate.subtract(const Duration(days: 2)),
      merchantReply: 'شكرًا لك! سعداء بأن المكان ناسب عملك.',
      merchantReplyAt: demoReviewsBaseDate.subtract(const Duration(days: 1)),
    ),
    Review(
      id: 'demo_review_2',
      userId: 'demo_user_2',
      userName: 'زائر تجريبي ب',
      userPhotoUrl: '$_img/berry_mojito.jpg',
      rating: 5,
      text:
          'الحلويات لذيذة والأسعار معقولة. الخدمة كانت بطيئة قليلًا وقت الذروة.',
      venueId: DemoMode.venueId,
      createdAt: demoReviewsBaseDate.subtract(const Duration(days: 5)),
      merchantReply: 'نعتذر عن الانتظار، عززنا الفريق في ساعات المساء.',
      merchantReplyAt: demoReviewsBaseDate.subtract(const Duration(days: 4)),
    ),
    Review(
      id: 'demo_review_3',
      userId: 'demo_user_3',
      userName: 'زائر تجريبي ج',
      rating: 5,
      text: 'أفضل تشيز كيك جربته في رام الله. أنصح به بشدة.',
      venueId: DemoMode.venueId,
      createdAt: demoReviewsBaseDate.subtract(const Duration(days: 9)),
    ),
    Review(
      id: 'demo_review_4',
      userId: 'demo_user_4',
      userName: 'زائر تجريبي د',
      rating: 4,
      text: 'المكان جميل لكن المساحة ضيقة في أوقات الذروة.',
      venueId: DemoMode.venueId,
      createdAt: demoReviewsBaseDate.subtract(const Duration(days: 14)),
    ),
    Review(
      id: 'demo_review_5',
      userId: 'demo_user_5',
      userName: 'زائر تجريبي هـ',
      rating: 5,
      text: 'فطور متكامل وطاقم لطيف. سأعود بالتأكيد.',
      venueId: DemoMode.venueId,
      createdAt: demoReviewsBaseDate.subtract(const Duration(days: 21)),
    ),
    Review(
      id: 'demo_review_6',
      userId: 'demo_user_6',
      userName: 'زائر تجريبي و',
      rating: 3,
      text: 'الموسيقى كانت عالية أكثر من اللازم في المساء.',
      venueId: DemoMode.venueId,
      createdAt: demoReviewsBaseDate.subtract(const Duration(days: 30)),
    ),
  ];
}

/// Star histogram, 1..5 stars.
Map<int, int> demoReviewsDistribution() {
  final distribution = <int, int>{
    for (var star = 1; star <= 5; star += 1) star: 0,
  };
  for (final review in buildDemoReviews()) {
    final bucket = review.rating.round().clamp(1, 5);
    distribution[bucket] = (distribution[bucket] ?? 0) + 1;
  }
  return distribution;
}

/// The review a presenter typed during this run, held in memory only.
///
/// Kept here rather than in the repository so "add a review" can be shown end
/// to end without a single write leaving the process. Cleared by
/// [clearDemoSubmittedReview], which the demo reset calls.
Review? demoSubmittedReview;

void recordDemoSubmittedReview({
  required double rating,
  required String text,
  required String userName,
  String? userPhotoUrl,
}) {
  demoSubmittedReview = Review(
    id: 'demo_review_local',
    userId: 'demo_local_user',
    userName: userName,
    userPhotoUrl: userPhotoUrl,
    rating: rating,
    text: text,
    venueId: DemoMode.venueId,
    createdAt: demoReviewsBaseDate,
  );
}

void clearDemoSubmittedReview() => demoSubmittedReview = null;

double demoReviewsAverage() {
  final reviews = buildDemoReviews();
  if (reviews.isEmpty) return 0;
  final total = reviews.fold<double>(0, (sum, r) => sum + r.rating);
  return total / reviews.length;
}
