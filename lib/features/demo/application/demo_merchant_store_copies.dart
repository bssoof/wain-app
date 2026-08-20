part of 'demo_merchant_store.dart';

MerchantOffer _copyOffer(
  MerchantOffer value, {
  MerchantOfferStatus? status,
  bool? isActive,
  bool? isFeatured,
  DateTime? featuredUntil,
  int? redeemedCount,
}) => MerchantOffer(
  id: value.id,
  venueId: value.venueId,
  titleAr: value.titleAr,
  title: value.title,
  descriptionAr: value.descriptionAr,
  description: value.description,
  termsAr: value.termsAr,
  discountType: value.discountType,
  discountValue: value.discountValue,
  singleUsePerCustomer: value.singleUsePerCustomer,
  isActive: isActive ?? value.isActive,
  startAt: value.startAt,
  endAt: value.endAt,
  status: status ?? value.status,
  claimsCount: value.claimsCount,
  redeemedCount: redeemedCount ?? value.redeemedCount,
  conversionRate: value.conversionRate,
  isFeatured: isFeatured ?? value.isFeatured,
  featuredUntil: featuredUntil ?? value.featuredUntil,
);

MerchantReview _copyReview(
  MerchantReview value, {
  String? merchantReply,
  DateTime? merchantReplyAt,
  String? merchantReplyBy,
  bool clearReply = false,
}) => MerchantReview(
  id: value.id,
  userName: value.userName,
  userPhotoUrl: value.userPhotoUrl,
  rating: value.rating,
  text: value.text,
  createdAt: value.createdAt,
  merchantReply: clearReply ? null : merchantReply ?? value.merchantReply,
  merchantReplyAt: clearReply ? null : merchantReplyAt ?? value.merchantReplyAt,
  merchantReplyBy: clearReply ? null : merchantReplyBy ?? value.merchantReplyBy,
);

MerchantStory _copyStory(
  MerchantStory value, {
  DateTime? promotedUntil,
  bool? isPromotedFlag,
}) => MerchantStory(
  id: value.id,
  type: value.type,
  text: value.text,
  imageUrl: value.imageUrl,
  videoUrl: value.videoUrl,
  createdAt: value.createdAt,
  expiresAt: value.expiresAt,
  promotedUntil: promotedUntil ?? value.promotedUntil,
  isPromotedFlag: isPromotedFlag ?? value.isPromotedFlag,
);

MerchantVenue _copyVenue(
  MerchantVenue value, {
  String? nameAr,
  String? nameEn,
  String? city,
  String? phone,
  List<String>? photos,
  Map<String, List<MerchantVenueHoursSlot>>? hours,
  bool? is24Hours,
}) => MerchantVenue(
  id: value.id,
  nameAr: nameAr ?? value.nameAr,
  nameEn: nameEn ?? value.nameEn,
  city: city ?? value.city,
  phone: phone ?? value.phone,
  photos: photos ?? value.photos,
  categories: value.categories,
  moodLabels: value.moodLabels,
  hours: hours ?? value.hours,
  is24Hours: is24Hours ?? value.is24Hours,
  activeMenuVersionId: value.activeMenuVersionId,
  lastStoryAt: value.lastStoryAt,
  rating: value.rating,
  minPrice: value.minPrice,
  maxPrice: value.maxPrice,
  lat: value.lat,
  lng: value.lng,
);
