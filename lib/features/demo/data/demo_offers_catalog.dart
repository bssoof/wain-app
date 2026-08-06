import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';

const String _img = 'asset://assets/images/demo_menu';

/// Fixed clock for the demo.
///
/// Validity windows are anchored to constants rather than `DateTime.now()` so a
/// demo shows the same three states every time it is run, and the tests that
/// assert those states cannot rot overnight.
final DateTime demoOffersEpoch = DateTime.utc(2026, 7, 1);
final DateTime demoOffersValidUntil = DateTime.utc(2027, 12, 31);
final DateTime demoOffersExpiredAt = DateTime.utc(2026, 7, 20);

/// Offers whose id appears here are presented as already used, so the demo can
/// show the "used" state without ever creating a claim.
const Set<String> demoUsedOfferIds = <String>{'demo_offer_used_dessert'};

List<Offer> buildDemoOffers() {
  return <Offer>[
    Offer(
      id: 'demo_offer_percent_coffee',
      venueId: DemoMode.venueId,
      titleAr: 'خصم 25% على القهوة المختصة',
      titleEn: '25% off specialty coffee',
      descriptionAr:
          'استمتع بخصم 25% على جميع أصناف القهوة المختصة طوال أيام الأسبوع.',
      descriptionEn: 'Enjoy 25% off every specialty coffee, all week long.',
      discountType: DiscountType.percent,
      discountValue: 25,
      currency: 'ILS',
      startAt: demoOffersEpoch,
      endAt: demoOffersValidUntil,
      termsAr: 'يسري على مشروب واحد لكل زيارة. لا يجمع مع عروض أخرى.',
      imageUrl: '$_img/cafe_latte.jpg',
      isPartner: true,
    ),
    Offer(
      id: 'demo_offer_amount_breakfast',
      venueId: DemoMode.venueId,
      titleAr: 'حسم 10 شيكل على الفطور',
      titleEn: '10 ILS off breakfast',
      descriptionAr: 'حسم ثابت 10 شيكل على أي طبق فطور قبل الساعة 11 صباحًا.',
      descriptionEn: 'A flat 10 ILS off any breakfast plate before 11am.',
      discountType: DiscountType.amount,
      discountValue: 10,
      currency: 'ILS',
      startAt: demoOffersEpoch,
      endAt: demoOffersValidUntil,
      termsAr: 'صالح من الأحد إلى الخميس، قبل الساعة 11 صباحًا.',
      imageUrl: '$_img/club_sandwich.jpg',
      isPartner: true,
    ),
    Offer(
      id: 'demo_offer_free_juice',
      venueId: DemoMode.venueId,
      titleAr: 'عصير مجاني مع كل وجبة',
      titleEn: 'Free juice with every meal',
      descriptionAr: 'احصل على عصير برتقال طازج مجانًا عند طلب أي وجبة رئيسية.',
      descriptionEn: 'A fresh orange juice on the house with any main dish.',
      discountType: DiscountType.freeItem,
      discountValue: 1,
      currency: 'ILS',
      startAt: demoOffersEpoch,
      endAt: demoOffersValidUntil,
      termsAr: 'عصير واحد لكل وجبة. غير قابل للاستبدال بقيمة نقدية.',
      imageUrl: '$_img/orange_juice.jpg',
      isPartner: true,
    ),
    Offer(
      id: 'demo_offer_used_dessert',
      venueId: DemoMode.venueId,
      titleAr: 'قطعة حلى مجانية',
      titleEn: 'Free dessert',
      descriptionAr:
          'قطعة تشيز كيك مجانية مع أي مشروب ساخن — استُخدم هذا العرض مسبقًا.',
      descriptionEn: 'A free slice of cheesecake with any hot drink.',
      discountType: DiscountType.freeItem,
      discountValue: 1,
      currency: 'ILS',
      startAt: demoOffersEpoch,
      endAt: demoOffersExpiredAt,
      termsAr: 'عرض لمرة واحدة لكل زبون.',
      imageUrl: '$_img/san_sebastian.jpg',
      isPartner: true,
      claimsCount: 1,
      redeemedCount: 1,
    ),
  ];
}

/// Whether [offerId] belongs to the demo catalog.
///
/// Keyed on the offer rather than the venue because the redemption-status
/// provider is family-keyed by offer id and never sees a venue id.
bool isDemoOffer(String offerId) =>
    DemoMode.isEnabled && buildDemoOffers().any((offer) => offer.id == offerId);

/// The redemption state the demo reports for [offerId], with no claim lookup.
bool isDemoOfferRedeemed(String offerId) => demoUsedOfferIds.contains(offerId);

/// The payload shown on the demo QR.
///
/// Deliberately not a claim token and not parseable as one: it carries no
/// claim id, no signature, and says in both languages that it cannot be
/// redeemed. Nothing in the redemption path will accept it.
String demoQrPayload(String offerId) =>
    'WAIN-DEMO://offer/$offerId?valid=false&note=NOT_REDEEMABLE';

const String demoQrNoticeAr = 'DEMO — غير صالح للاستخدام';
const String demoQrNoticeEn = 'DEMO — not valid for redemption';
