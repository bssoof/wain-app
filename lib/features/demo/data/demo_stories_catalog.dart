import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/stories/domain/entities/story.dart';

const String _img = 'asset://assets/images/demo_menu';

/// Fixed window, far enough out that `Story.isExpired` stays false without the
/// demo depending on the wall clock. A story whose expiry is computed as
/// "now + n hours" makes every test that touches it time-sensitive.
final DateTime demoStoriesCreatedAt = DateTime.utc(2026, 7, 1, 8);
final DateTime demoStoriesExpiresAt = DateTime.utc(2099, 1, 1);
final DateTime demoStoriesPromotedUntil = DateTime.utc(2099, 1, 1);

/// The same stories in the raw-map shape the venue-side `venueStoriesProvider`
/// serves.
///
/// `VenueStoriesSection` reads maps and builds [Story] itself, so the demo has
/// to supply both shapes. Derived from [buildDemoStories] rather than written
/// twice, so the two can never drift apart.
List<Map<String, dynamic>> demoStoryMaps() {
  return <Map<String, dynamic>>[
    for (final story in buildDemoStories())
      <String, dynamic>{
        'id': story.id,
        'venue_id': story.venueId,
        'venue_name': story.venueName,
        'venue_photo_url': story.venuePhotoUrl,
        'type': story.type,
        'image_url': story.imageUrl,
        'video_url': story.videoUrl,
        'text': story.text,
        'offer_ref': story.offerRef,
        'view_count': story.viewCount,
        'duration_seconds': story.durationSeconds,
      },
  ];
}

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
