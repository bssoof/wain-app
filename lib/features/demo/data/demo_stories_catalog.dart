import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/stories/domain/entities/story.dart';

const String _img = 'asset://assets/images/demo_menu';

/// Fixed window, far enough out that `Story.isExpired` stays false without the
/// demo depending on the wall clock. A story whose expiry is computed as
/// "now + n hours" makes every test that touches it time-sensitive.
final DateTime demoStoriesCreatedAt = DateTime.utc(2026, 7, 1, 8);
final DateTime demoStoriesExpiresAt = DateTime.utc(2099, 1, 1);
final DateTime demoStoriesPromotedUntil = DateTime.utc(2099, 1, 1);

/// Three stories covering the three types the viewer can render: a plain image,
/// one bound to an offer, and a text card. Video is deliberately absent — the
/// project has no bundled video asset and no player dependency, and adding
/// either just to fill a demo slot would be the wrong trade.
List<Story> buildDemoStories() {
  return <Story>[
    Story(
      id: 'demo_story_morning',
      venueId: DemoMode.venueId,
      venueName: DemoMode.venueNameAr,
      venuePhotoUrl: '$_img/cafe_latte.jpg',
      type: 'image',
      imageUrl: '$_img/cappuccino.jpg',
      text: 'صباح القهوة المختصة ☕',
      createdAt: demoStoriesCreatedAt,
      expiresAt: demoStoriesExpiresAt,
      viewCount: 128,
      durationSeconds: 5,
    ),
    Story(
      id: 'demo_story_offer',
      venueId: DemoMode.venueId,
      venueName: DemoMode.venueNameAr,
      venuePhotoUrl: '$_img/cafe_latte.jpg',
      type: 'offer',
      imageUrl: '$_img/orange_juice.jpg',
      text: 'عصير مجاني مع كل وجبة — لفترة محدودة',
      offerRef: 'demo_offer_free_juice',
      createdAt: demoStoriesCreatedAt,
      expiresAt: demoStoriesExpiresAt,
      promotedUntil: demoStoriesPromotedUntil,
      viewCount: 341,
      durationSeconds: 6,
    ),
    Story(
      id: 'demo_story_text',
      venueId: DemoMode.venueId,
      venueName: DemoMode.venueNameAr,
      venuePhotoUrl: '$_img/cafe_latte.jpg',
      type: 'text',
      imageUrl: '$_img/belgian_waffle.jpg',
      text: 'حلوياتنا تُحضّر يوميًا في المقهى 🍰',
      createdAt: demoStoriesCreatedAt,
      expiresAt: demoStoriesExpiresAt,
      viewCount: 87,
      durationSeconds: 5,
    ),
  ];
}
