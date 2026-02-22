// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get venueNotFound => 'المكان غير موجود';

  @override
  String get selectMapApp => 'اختر تطبيق الخرائط';

  @override
  String get openInGoogleMaps => 'فتح في خرائط Google';

  @override
  String get openInWaze => 'فتح في Waze';

  @override
  String get call => 'اتصال';

  @override
  String get whatsapp => 'واتساب';

  @override
  String get navigate => 'توجيه';

  @override
  String get menuNoMatchingResults => 'لا توجد نتائج مطابقة في المنيو';

  @override
  String get photoSingle => 'صورة';

  @override
  String get photoPlural => 'صور';

  @override
  String get noMenuAvailable => 'لا يوجد منيو متاح حالياً';

  @override
  String get menuLoadFailed => 'تعذر تحميل المنيو حالياً';

  @override
  String get importantNotice => 'تنبيه هام';

  @override
  String get offerValidTenMinutes => 'هذا العرض صالح لمدة 10 دقائق فقط!';

  @override
  String get offerActivationWarning => 'يرجى عدم تفعيل العرض إلا عند تواجدك داخل المطعم وأمام الكاشير.\\n\\nبمجرد التفعيل، سيبدأ العداد ولن تتمكن من إيقافه.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get activateOfferNow => 'تفعيل العرض الآن';

  @override
  String get errorPrefix => 'خطأ';

  @override
  String get claimRequestFailed => 'فشل في تسجيل الطلب';

  @override
  String get locationUnavailable => 'الموقع غير متاح';

  @override
  String get meterUnit => 'م';

  @override
  String get kilometerUnit => 'كم';

  @override
  String distanceAway(String distance) {
    return '$distance بعيد';
  }

  @override
  String get detectingLocation => 'جاري تحديد الموقع...';

  @override
  String get failedToDetectLocation => 'تعذر تحديد الموقع';

  @override
  String get menuItemCounter => 'صنف';

  @override
  String get menuTitle => 'المنيو';

  @override
  String get searchInMenuHint => 'ابحث داخل المنيو...';

  @override
  String get featuredItems => 'الأصناف المميزة';

  @override
  String get all => 'الكل';

  @override
  String get offersAvailable => 'العروض المتاحة';

  @override
  String get offersLoadFailed => 'فشل تحميل العروض';

  @override
  String get noOffersNow => 'لا توجد عروض حالياً';

  @override
  String get followForNewOffers => 'تابعنا للحصول على عروض جديدة';

  @override
  String get hoursTitle => 'ساعات العمل';

  @override
  String get closed => 'مغلق';

  @override
  String get openNow => 'مفتوح';

  @override
  String get open24Hours => 'مفتوح 24 ساعة';

  @override
  String get dayMonday => 'الاثنين';

  @override
  String get dayTuesday => 'الثلاثاء';

  @override
  String get dayWednesday => 'الأربعاء';

  @override
  String get dayThursday => 'الخميس';

  @override
  String get dayFriday => 'الجمعة';

  @override
  String get daySaturday => 'السبت';

  @override
  String get daySunday => 'الأحد';

  @override
  String get generalCategory => 'عام';

  @override
  String get socialLinks => 'روابط التواصل';

  @override
  String get tryListAdded => 'تمت الإضافة لقائمة بدي أجرب';

  @override
  String get venueStories => 'قصص المحل';

  @override
  String get video => 'فيديو';

  @override
  String get story => 'قصة';

  @override
  String get partnerBadge => 'شريك';

  @override
  String get offerDetails => 'تفاصيل العرض';

  @override
  String get getOffer => 'احصل على العرض';

  @override
  String get needConnection => 'تحتاج اتصال';

  @override
  String get tabMenu => 'المنيو';

  @override
  String get tabReviews => 'الآراء';

  @override
  String get tabAbout => 'التفاصيل';

  @override
  String get reviewFormSelectRating => 'الرجاء اختيار تقييم';

  @override
  String get reviewFormLoginRequired => 'يجب تسجيل الدخول لإضافة تقييم';

  @override
  String get reviewFormSuccess => 'تمت إضافة تقييمك بنجاح!';

  @override
  String reviewFormError(String error) {
    return 'فشل إضافة التقييم: $error';
  }

  @override
  String reviewFormTitlePrefix(String venue) {
    return 'تقييم $venue';
  }

  @override
  String get reviewFormSubtitle => 'شاركنا تجربتك مع هذا المكان';

  @override
  String get reviewFormHint => 'اكتب تعليقك هنا (اختياري)...';

  @override
  String get reviewFormSubmitBtn => 'إرسال التقييم';

  @override
  String get reviewRatingTerrible => 'سيء جدًا';

  @override
  String get reviewRatingPoor => 'مقبول';

  @override
  String get reviewRatingGood => 'جيد';

  @override
  String get reviewRatingVeryGood => 'ممتاز';

  @override
  String get reviewRatingExcellent => 'رائع!';

  @override
  String get reviewRatingPrompt => 'اختر تقييمك';

  @override
  String get reviewsSectionTitle => 'التقييمات والمراجعات';

  @override
  String get reviewsSectionAddBtn => 'أضف تقييم';

  @override
  String get reviewsSectionLoadFail => 'فشل تحميل التقييمات';

  @override
  String get reviewsSectionEmptyTitle => 'لا توجد تقييمات بعد';

  @override
  String get reviewsSectionEmptySubtitle => 'كن أول من يقيّم هذا المكان!';

  @override
  String reviewsSectionCountLabel(num count) {
    return '$count تقييم';
  }

  @override
  String reviewsSectionViewAllCount(num count) {
    return 'عرض كل التقييمات ($count)';
  }

  @override
  String get reviewsSectionMerchantReply => 'رد صاحب المحل';

  @override
  String get reviewsSectionDeleteTitle => 'حذف التقييم';

  @override
  String get reviewsSectionDeleteConfirm => 'هل أنت متأكد من حذف تقييمك؟';

  @override
  String get reviewsSectionCancel => 'إلغاء';

  @override
  String get reviewsSectionDeleteBtn => 'حذف';

  @override
  String reviewsSectionAllTitle(num count) {
    return 'كل التقييمات ($count)';
  }

  @override
  String get reviewsTimeNow => 'الآن';

  @override
  String reviewsTimeMins(num mins) {
    return 'منذ $mins دقيقة';
  }

  @override
  String reviewsTimeHours(num hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String reviewsTimeDays(num days) {
    return 'منذ $days يوم';
  }

  @override
  String reviewsTimeWeeks(num weeks) {
    return 'منذ $weeks أسبوع';
  }

  @override
  String get priceLabel => 'السعر';

  @override
  String menuShowAll(int count) {
    return 'عرض الكل (+$count)';
  }

  @override
  String get menuShowLess => 'عرض أقل';

  @override
  String menuResultsSummary(int itemsCount, int sectionsCount) {
    return '$itemsCount صنف في $sectionsCount أقسام';
  }

  @override
  String get venueSummaryStatus => 'الحالة';

  @override
  String get venueSummaryDistance => 'المسافة';

  @override
  String get venueSummaryClosesAt => 'يغلق عند';

  @override
  String get venueSummaryPriceRange => 'نطاق السعر';

  @override
  String get venueSummaryNotAvailable => 'غير متاح';

  @override
  String get venueSummaryClosedToday => 'مغلق اليوم';

  @override
  String get merchantDashboardTitle => 'لوحة التاجر';

  @override
  String get merchantManageVenue => 'إدارة المحل';

  @override
  String get merchantNoVenueLinked => 'ما في محل مربوط بحسابك';

  @override
  String get merchantEnterInvitePrompt => 'أدخل رمز الدعوة عشان تربط محلك';

  @override
  String get merchantEnterInviteBtn => 'أدخل رمز الدعوة';

  @override
  String get merchantStats => 'الإحصائيات';

  @override
  String get merchantRating => 'التقييم';

  @override
  String get merchantReviewCount => 'التقييمات';

  @override
  String get merchantVisitorEngagement => 'تفاعل الزوار';

  @override
  String get merchantThisWeek => 'هذا الأسبوع';

  @override
  String get merchantViews => 'مشاهدات';

  @override
  String get merchantCalls => 'اتصالات';

  @override
  String get merchantNavs => 'تنقل';

  @override
  String get merchantStoryViews => 'ستوريات';

  @override
  String merchantTotalLabel(int total) {
    return 'الإجمالي: $total';
  }

  @override
  String get merchantTrends => 'اتجاهات الأداء';

  @override
  String get merchantNoTrendData => 'لا توجد بيانات كافية لعرض الاتجاهات بعد';

  @override
  String get merchantTrendLoadFailed => 'تعذر تحميل بيانات الاتجاهات الآن';

  @override
  String get merchantNoChartActivity => 'لا يوجد نشاط كافٍ لعرض الرسم';

  @override
  String merchantBestDay(String dateKey, int views) {
    return 'أفضل يوم: $dateKey • $views مشاهدة';
  }

  @override
  String merchantViewsLast(String range) {
    return 'مشاهدات آخر $range';
  }

  @override
  String merchantCallsLast(String range) {
    return 'اتصالات آخر $range';
  }

  @override
  String merchantNavsLast(String range) {
    return 'تنقل آخر $range';
  }

  @override
  String get merchantViewsWow => 'مشاهدات WoW';

  @override
  String get merchantCallsWow => 'اتصالات WoW';

  @override
  String get merchantNavsWow => 'تنقل WoW';

  @override
  String get merchantRecentReviews => 'آخر التقييمات';

  @override
  String get merchantNoReviewsYet => 'ما في تقييمات بعد';

  @override
  String get merchantDefaultUser => 'مستخدم';

  @override
  String get merchantOffers => 'العروض';

  @override
  String get merchantNoOffersNow => 'ما في عروض حالياً';

  @override
  String get merchantDefaultOfferTitle => 'عرض';

  @override
  String get merchantVenueInfo => 'معلومات المحل';

  @override
  String get merchantInfoName => 'الاسم';

  @override
  String get merchantInfoCity => 'المدينة';

  @override
  String get merchantInfoPhone => 'الهاتف';

  @override
  String get merchantInfoCategory => 'التصنيف';

  @override
  String get merchantOpenNow => 'مفتوح الآن';

  @override
  String get merchantClosed => 'مغلق';

  @override
  String get merchantDefaultVenueName => 'اسم المحل';

  @override
  String get merchantDefaultType => 'مطعم';

  @override
  String merchantErrorGeneric(String error) {
    return 'خطأ: $error';
  }

  @override
  String merchantRefreshSuccess(int views, int calls, int navs) {
    return 'تم تحديث بيانات الأداء • مشاهدات: $views • اتصالات: $calls • تنقل: $navs';
  }

  @override
  String merchantRefreshFailed(String error) {
    return 'فشل تحديث بيانات الأداء: $error';
  }

  @override
  String get merchantBackfillPermissionDenied => 'الحساب غير مربوط كتاجر بشكل صحيح. افتح كود الدعوة وأعد الربط.';

  @override
  String get merchantBackfillMissingIndex => 'ينقص Index للتحليلات في Firestore. نفّذ deploy لـ firestore:indexes.';

  @override
  String get merchantBackfillNoVenue => 'لا يوجد محل مربوط بهذا الحساب. اربط المحل أولاً ثم أعد المحاولة.';

  @override
  String get merchantBackfillUnauthenticated => 'يلزم تسجيل الدخول مرة أخرى قبل التحديث.';

  @override
  String merchantBackfillDefaultError(String message) {
    return 'فشل تحديث بيانات الأداء: $message';
  }

  @override
  String get merchantQuickActionScan => 'ماسح الكود';

  @override
  String get merchantQuickActionEdit => 'تعديل المعلومات';

  @override
  String get merchantQuickActionOffers => 'إدارة العروض';

  @override
  String get merchantQuickActionPhotos => 'صور المحل';

  @override
  String get merchantQuickActionReviews => 'التقييمات';

  @override
  String get merchantQuickActionMenu => 'المنيو';

  @override
  String get merchantQuickActionHours => 'ساعات العمل';

  @override
  String get merchantQuickActionStories => 'الستوريات';

  @override
  String get merchantDays7 => '7 أيام';

  @override
  String get merchantDays30 => '30 يوم';

  @override
  String get merchantPhotosTitle => 'صور المحل 📸';

  @override
  String get merchantPhotosEmpty => 'ما في صور بعد';

  @override
  String get merchantPhotosAddPrompt => 'أضف صور لمحلك عشان يشوفها الزبائن!';

  @override
  String get merchantPhotosAddBtn => 'إضافة صور';

  @override
  String get merchantPhotosUploading => 'جاري الرفع...';

  @override
  String merchantPhotosUploadSuccess(int count) {
    return '✅ تم رفع $count صورة';
  }

  @override
  String merchantPhotosUploadFailed(String error) {
    return '❌ فشل الرفع: $error';
  }

  @override
  String get merchantPhotosDeleteTitle => 'حذف الصورة';

  @override
  String get merchantPhotosDeleteConfirm => 'هل أنت متأكد من حذف هذه الصورة؟';

  @override
  String get merchantPhotosNo => 'لا';

  @override
  String get merchantPhotosYes => 'نعم';

  @override
  String get merchantPhotosSetCover => 'تعيين كغلاف';

  @override
  String get merchantPhotosDelete => 'حذف';

  @override
  String get merchantPhotosCoverLabel => 'الغلاف';

  @override
  String get merchantPhotosCoverSet => '✅ تم تعيين الصورة كغلاف';

  @override
  String get merchantPhotosNoVenue => 'ما في محل مربوط';

  @override
  String merchantPhotosErrorGeneric(String error) {
    return '❌ خطأ: $error';
  }

  @override
  String get merchantReviewsTitle => 'التقييمات 💬';

  @override
  String get merchantReviewsEmpty => 'ما في تقييمات بعد';

  @override
  String get merchantReviewsFilterAll => 'الكل';

  @override
  String get merchantReviewsFilterNoReply => 'بدون رد';

  @override
  String merchantReviewsCount(int count) {
    return '$count تقييم';
  }

  @override
  String get merchantReviewsNoResults => 'لا توجد تقييمات بهذا الفلتر';

  @override
  String get merchantReviewsReplySent => '✅ تم إرسال الرد';

  @override
  String get merchantReviewsReplyDeleted => '🗑️ تم حذف الرد';

  @override
  String get merchantReviewsDeleteReplyTitle => 'حذف الرد';

  @override
  String get merchantReviewsDeleteReplyConfirm => 'هل أنت متأكد من حذف ردك؟';

  @override
  String get merchantReviewsCancel => 'إلغاء';

  @override
  String get merchantReviewsDelete => 'حذف';

  @override
  String get merchantReviewsOwnerReply => 'رد صاحب المحل';

  @override
  String get merchantReviewsReplyHint => 'اكتب ردك...';

  @override
  String get merchantReviewsEdit => 'تعديل';

  @override
  String get merchantReviewsDeleteTooltip => 'حذف الرد';

  @override
  String get merchantReviewsAddReply => 'أضف رد';

  @override
  String get merchantReviewsDefaultUser => 'مستخدم';

  @override
  String get merchantReviewsDefaultInitial => '؟';

  @override
  String merchantReviewsErrorGeneric(String error) {
    return '❌ خطأ: $error';
  }

  @override
  String get merchantStoriesTitle => 'الستوريات 📖';

  @override
  String get merchantStoriesNewStory => 'ستوري جديد';

  @override
  String get merchantStoriesError => 'خطأ';

  @override
  String get merchantStoriesNoVenue => 'ما في محل مربوط';

  @override
  String get merchantStoriesEmpty => 'ما في ستوريات بعد';

  @override
  String get merchantStoriesEmptyPrompt => 'أنشر ستوري عشان يشوفها زبائنك!';

  @override
  String get merchantStoriesVideo => '🎬 فيديو';

  @override
  String get merchantStoriesPromoted => 'مروج';

  @override
  String get merchantStoriesExpired => 'منتهي';

  @override
  String get merchantStoriesActive => 'فعّال';

  @override
  String get merchantStoriesExtendPromo => 'تمديد الترويج';

  @override
  String get merchantStoriesPromote => 'ترويج 🚀';

  @override
  String get merchantStoriesDeleteTooltip => 'حذف';

  @override
  String get merchantStoriesPromoteTitle => 'ترويج الستوري 🚀';

  @override
  String get merchantStoriesPromoteDesc => 'سيظهر الستوري في الصفحة الرئيسية لكل المستخدمين!';

  @override
  String get merchantStoriesChooseDuration => 'اختر المدة:';

  @override
  String get merchantStoriesCancel => 'إلغاء';

  @override
  String get merchantStoriesPromoteSuccess => '✅ تم ترويج الستوري بنجاح!';

  @override
  String merchantStoriesPromoteError(String error) {
    return '❌ خطأ: $error';
  }

  @override
  String get merchantStoriesUnexpectedError => '❌ حدث خطأ غير متوقع';

  @override
  String get merchantStoriesDeleteTitle => 'حذف الستوري';

  @override
  String get merchantStoriesDeleteConfirm => 'هل أنت متأكد؟';

  @override
  String get merchantStoriesNo => 'لا';

  @override
  String get merchantStoriesYes => 'نعم';

  @override
  String get merchantStoriesDeleted => 'تم حذف الستوري';

  @override
  String merchantStoriesDeleteFailed(String error) {
    return 'فشل حذف الستوري: $error';
  }

  @override
  String get merchantStoriesPromote1 => 'يوم واحد (1\$)';

  @override
  String get merchantStoriesPromote3 => '3 أيام (2.5\$)';

  @override
  String get merchantStoriesPromote7 => 'أسبوع (5\$)';

  @override
  String get storiesBarTitle => '📢 قصص الأماكن';

  @override
  String get storiesBarDefaultVenue => 'مكان';

  @override
  String get storiesFeaturedBadge => 'مميز';

  @override
  String storiesFeaturedError(String error) {
    return '⚠️ خطأ في تحميل المميز: $error';
  }

  @override
  String storyViewerVisitVenue(String venue) {
    return 'زيارة $venue';
  }

  @override
  String get storyViewerLoadingVideo => 'جاري تحميل الفيديو...';

  @override
  String get storyViewerSpecialOffer => 'عرض خاص!';

  @override
  String get storyViewerOpenAppToActivate => 'افتح التطبيق للتفعيل';

  @override
  String storyViewerMinsAgo(num mins) {
    return 'منذ $mins د';
  }

  @override
  String storyViewerHoursAgo(num hours) {
    return 'منذ $hours س';
  }

  @override
  String get storyViewerYesterday => 'أمس';

  @override
  String get merchantStoriesAddContent => 'أضف نص أو صورة أو فيديو على الأقل';

  @override
  String get merchantStoriesPublished => '✅ تم نشر الستوري';

  @override
  String merchantStoriesPublishError(String error) {
    return '❌ خطأ: $error';
  }

  @override
  String get merchantStoriesNewStoryTitle => 'ستوري جديد 📖';

  @override
  String get merchantStoriesPhoto => '📷 صورة';

  @override
  String get merchantStoriesVideoSelected => '✅ تم اختيار الفيديو';

  @override
  String get merchantStoriesVideoLimit => '(حد أقصى 30 ثانية)';

  @override
  String get merchantStoriesTextHint => 'اكتب نص الستوري...';

  @override
  String get merchantStoriesDuration => 'مدة الستوري:';

  @override
  String get merchantStories24h => '24 ساعة';

  @override
  String get merchantStories48h => '48 ساعة';

  @override
  String get merchantStoriesPublishBtn => 'نشر الستوري';

  @override
  String get savedOffersTitle => 'العروض المحفوظة';

  @override
  String get offerEndingSoon => 'ينتهي قريباً';

  @override
  String get offerQrDiscountCode => 'رمز الخصم';

  @override
  String get offerQrCodeExpired => 'انتهت صلاحية الرمز';

  @override
  String get offerQrValidFor => 'صالح لمدة';

  @override
  String get offerQrRedeemed => 'تمت الاستفادة من العرض';

  @override
  String get offerQrPeriodExpired => 'انتهت فترة الصلاحية';

  @override
  String get offerQrShowToCashier => 'أظهر هذا الرمز للكاشير';

  @override
  String get offerDetailsRequestFail => 'فشل في تسجيل الطلب';

  @override
  String get offerDetailsRequestFailFallback => 'فشل في تسجيل الطلب';

  @override
  String get offerDetailsUnexpectedError => 'حدث خطأ غير متوقع';

  @override
  String get offerDetailsAlreadyUsed => 'هذا العرض تم استخدامه مسبقاً أو غير متاح حالياً';

  @override
  String get offerDetailsLimitExceeded => 'تم تجاوز الحد المسموح، حاول لاحقاً';

  @override
  String get offerDetailsNoInternet => 'تأكد من اتصال الإنترنت';

  @override
  String get offerDetailsLoadFail => 'فشل تحميل العرض';

  @override
  String get offerDetailsNotFound => 'العرض غير موجود';

  @override
  String get offerDetailsVenueLoadFail => 'خطأ في تحميل بيانات المكان';

  @override
  String get offerDetailsVenueNotFound => 'المكان غير موجود';

  @override
  String get offerDetailsSaveRemoved => 'تم إزالة الحفظ';

  @override
  String get offerDetailsSaved => 'تم الحفظ';

  @override
  String get offerDetailsExclusive => 'عرض حصري للشركاء';

  @override
  String get offerDetailsValidity => 'صلاحية العرض';

  @override
  String get offerDetailsTerms => 'الشروط والأحكام';

  @override
  String get myClaimsTitle => 'عروضي';

  @override
  String get myClaimsEmptyTitle => 'لا يوجد عروض محفوظة حتى الآن';

  @override
  String get myClaimsEmptyDesc => 'استكشف الأماكن واحصل على خصومات حصرية!';

  @override
  String get myClaimsExploreBtn => 'استكشف الخريطة';

  @override
  String get myClaimsStatusUsed => 'تم الاستخدام';

  @override
  String get myClaimsStatusCancelled => 'ملغي';

  @override
  String get myClaimsStatusActive => 'نشط';

  @override
  String offerDiscountPercent(String value) {
    return 'خصم $value%';
  }

  @override
  String offerDiscountCurrency(String value, String currency) {
    return 'خصم $value $currency';
  }

  @override
  String get offerDiscountFree => 'عرض مجاني';

  @override
  String get offerValidityAlways => 'متاح دائماً';

  @override
  String get offerValidityExpired => 'منتهي';

  @override
  String offerValidityDays(int days) {
    return 'متبقي $days يوم';
  }

  @override
  String offerValidityHours(int hours) {
    return 'متبقي $hours ساعة';
  }

  @override
  String get offerValiditySoon => 'ينتهي قريباً';

  @override
  String get offerErrorSaveFailed => 'فشل في حفظ الطلب';

  @override
  String get offerErrorAlreadyUsed => 'لقد تمت الاستفاده من العرض من قبلكم';

  @override
  String get merchantOffersTitle => 'إدارة العروض 🎁';

  @override
  String get merchantOffersNewOffer => 'عرض جديد';

  @override
  String merchantOffersErrorLoad(String error) {
    return 'خطأ: $error';
  }

  @override
  String get merchantOffersEmpty => 'ما في عروض بعد';

  @override
  String get merchantOffersEmptyPrompt => 'أنشئ أول عرض لمحلك!';

  @override
  String get merchantOffersDefaultTitle => 'عرض';

  @override
  String get merchantOffersEndingSoon => 'ينتهي قريبًا';

  @override
  String get merchantOffersEdit => 'تعديل';

  @override
  String get merchantOffersDeleteMenu => 'حذف';

  @override
  String get merchantOffersActive => 'فعّال';

  @override
  String get merchantOffersPaused => 'متوقف';

  @override
  String get merchantOffersExpired => 'منتهي';

  @override
  String get merchantOffersNoDate => 'بدون تاريخ محدد';

  @override
  String merchantOffersClaims(int count) {
    return '$count مهتم';
  }

  @override
  String merchantOffersRedeemed(int count) {
    return '$count تم الاستفادة';
  }

  @override
  String merchantOffersConversion(String rate) {
    return '$rate% تحويل';
  }

  @override
  String get merchantOffersDeleteTitle => 'حذف العرض';

  @override
  String get merchantOffersDeleteConfirm => 'هل أنت متأكد من حذف هذا العرض؟';

  @override
  String get merchantOffersNo => 'لا';

  @override
  String get merchantOffersYesDelete => 'نعم، احذف';

  @override
  String merchantOffersDiscountAmount(String value) {
    return 'خصم $value ₪';
  }

  @override
  String get merchantOffersDiscountFree => 'عرض مجاني';

  @override
  String merchantOffersDiscountPercent(String value) {
    return 'خصم $value%';
  }

  @override
  String get merchantOffersPreviewTitle => 'معاينة العرض';

  @override
  String get merchantOffersPreviewClose => 'إغلاق';

  @override
  String get merchantOffersPreviewPublish => 'نشر العرض ✅';

  @override
  String get merchantOffersEditUpdated => '✅ تم تعديل العرض';

  @override
  String get merchantOffersCreated => '✅ تم إنشاء العرض';

  @override
  String merchantOffersSubmitError(String error) {
    return '❌ خطأ: $error';
  }

  @override
  String get merchantOffersFormEditTitle => 'تعديل العرض';

  @override
  String get merchantOffersFormNewTitle => 'عرض جديد 🎁';

  @override
  String get merchantOffersFieldRequired => 'مطلوب';

  @override
  String get merchantOffersFieldOfferTitle => 'عنوان العرض';

  @override
  String get merchantOffersFieldOfferTitleHint => 'مثال: خصم 20% على كل الطلبات';

  @override
  String get merchantOffersFieldDescription => 'وصف العرض';

  @override
  String get merchantOffersFieldDescHint => 'تفاصيل العرض...';

  @override
  String get merchantOffersFieldDiscountType => 'نوع الخصم';

  @override
  String get merchantOffersTypePercent => 'نسبة %';

  @override
  String get merchantOffersTypeAmount => 'مبلغ ₪';

  @override
  String get merchantOffersTypeFree => 'مجاني';

  @override
  String get merchantOffersFieldValue => 'القيمة';

  @override
  String get merchantOffersDurationLabel => '📅 مدة العرض';

  @override
  String get merchantOffersStartDate => 'بداية';

  @override
  String get merchantOffersEndDate => 'نهاية';

  @override
  String get merchantOffersFieldTerms => 'الشروط (اختياري)';

  @override
  String get merchantOffersFieldTermsHint => 'مثال: العرض لا يشمل التوصيل';

  @override
  String get merchantOffersPreviewBtn => 'معاينة';

  @override
  String get merchantOffersSaveChanges => 'حفظ التعديلات';

  @override
  String get merchantOffersPublish => 'نشر العرض';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'سجّل دخولك للاستمتاع بجميع ميزات وين';

  @override
  String get loginGoogle => 'تسجيل الدخول بحساب Google';

  @override
  String get loginOr => 'أو';

  @override
  String get loginPhoneLabel => 'رقم الهاتف';

  @override
  String get loginSendOtp => 'إرسال رمز التحقق';

  @override
  String get loginEmailHint => 'البريد الإلكتروني';

  @override
  String get loginPasswordHint => 'كلمة المرور';

  @override
  String get loginEmailBtn => 'تسجيل الدخول';

  @override
  String get loginNoAccount => 'ليس لديك حساب؟  ';

  @override
  String get loginCreateAccount => 'إنشاء حساب';

  @override
  String get loginUsePhone => 'استخدم رقم الهاتف';

  @override
  String get loginUseEmail => 'استخدم البريد الإلكتروني';

  @override
  String get loginContinueGuest => 'المتابعة كضيف';

  @override
  String get loginWelcome => 'مرحباً!';

  @override
  String loginWelcomeUser(String name) {
    return 'مرحباً $name!';
  }

  @override
  String get loginGoogleFailed => 'فشل تسجيل الدخول بحساب Google، حاول مرة أخرى';

  @override
  String loginErrorGeneric(String error) {
    return 'خطأ في تسجيل الدخول: $error';
  }

  @override
  String get loginErrorPhone => 'الرجاء إدخال رقم الهاتف';

  @override
  String get loginErrorEmailPassword => 'الرجاء إدخال البريد وكلمة المرور';

  @override
  String get loginErrorUserNotFound => 'لا يوجد حساب بهذا البريد';

  @override
  String get loginErrorWrongPassword => 'كلمة المرور غير صحيحة';

  @override
  String get loginErrorInvalidCredential => 'البريد أو كلمة المرور غير صحيحة';

  @override
  String get loginErrorDefault => 'حدث خطأ، حاول مرة أخرى';

  @override
  String get signupTitle => 'إنشاء حساب جديد';

  @override
  String get signupSubtitle => 'أنشئ حسابك واستمتع بميزات تطبيق وين';

  @override
  String get signupNameLabel => 'الاسم الكامل';

  @override
  String get signupNameHint => 'أدخل اسمك الكامل';

  @override
  String get signupNameRequired => 'الرجاء إدخال الاسم';

  @override
  String get signupEmailLabel => 'البريد الإلكتروني';

  @override
  String get signupEmailRequired => 'الرجاء إدخال البريد الإلكتروني';

  @override
  String get signupEmailInvalid => 'البريد الإلكتروني غير صالح';

  @override
  String get signupPasswordLabel => 'كلمة المرور';

  @override
  String get signupPasswordRequired => 'الرجاء إدخال كلمة المرور';

  @override
  String get signupPasswordWeak => 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  @override
  String get signupConfirmLabel => 'تأكيد كلمة المرور';

  @override
  String get signupConfirmRequired => 'الرجاء تأكيد كلمة المرور';

  @override
  String get signupConfirmMismatch => 'كلمة المرور غير متطابقة';

  @override
  String get signupBtn => 'إنشاء حساب';

  @override
  String get signupHaveAccount => 'لديك حساب؟  ';

  @override
  String get signupLogin => 'سجّل دخول';

  @override
  String get signupSuccess => 'تم إنشاء الحساب بنجاح! 🎉';

  @override
  String get signupErrorEmailInUse => 'البريد الإلكتروني مستخدم مسبقاً';

  @override
  String get signupErrorWeakPassword => 'كلمة المرور ضعيفة جداً';

  @override
  String get signupErrorInvalidEmail => 'البريد الإلكتروني غير صالح';

  @override
  String get otpTitle => 'رمز التحقق';

  @override
  String get otpSentTo => 'تم إرسال رمز التحقق إلى\n';

  @override
  String get otpVerifyBtn => 'تأكيد';

  @override
  String get otpNotReceived => 'لم يصلك الرمز؟  ';

  @override
  String otpResendCountdown(int seconds) {
    return 'إعادة الإرسال ($seconds)';
  }

  @override
  String get otpResend => 'إعادة الإرسال';

  @override
  String get otpChangePhone => 'تغيير رقم الهاتف';

  @override
  String get otpInvalid => 'الرجاء إدخال رمز التحقق المكون من 6 أرقام';

  @override
  String get otpSuccess => 'تم تسجيل الدخول بنجاح!';

  @override
  String get otpResent => 'تم إعادة إرسال رمز التحقق';

  @override
  String get inviteTitle => 'التحق كتاجر';

  @override
  String get inviteEnterCode => 'أدخل رمز الدعوة';

  @override
  String get inviteSubtitle => 'إذا أنت صاحب محل، أدخل الرمز اللي وصلك\nعشان تقدر تدير محلك من التطبيق';

  @override
  String get inviteCodeEmpty => 'أدخل رمز الدعوة';

  @override
  String get inviteVerifyBtn => 'تحقق من الرمز';

  @override
  String get inviteHelpText => 'ما عندك رمز؟ تواصل مع فريق وين عشان نسجلك كتاجر.';

  @override
  String get editVenueTitle => 'تعديل معلومات المحل';

  @override
  String editVenueError(String error) {
    return 'خطأ: $error';
  }

  @override
  String get editVenueNoVenue => 'ما في محل مربوط';

  @override
  String get editVenueNameAr => 'اسم المحل (عربي)';

  @override
  String get editVenueNameEn => 'اسم المحل (إنجليزي)';

  @override
  String get editVenuePhone => 'رقم الهاتف';

  @override
  String get editVenueCity => 'المدينة';

  @override
  String get editVenueRequired => 'مطلوب';

  @override
  String get editVenueEditHours => 'تعديل ساعات العمل';

  @override
  String get editVenueSaveBtn => 'حفظ التعديلات';

  @override
  String get editVenueSaved => '✅ تم حفظ التعديلات';

  @override
  String editVenueSaveError(String error) {
    return '❌ فشل الحفظ: $error';
  }

  @override
  String get hours24hToggle => 'مفتوح 24 ساعة';

  @override
  String get hours24hSubtitle => 'سيظهر المحل دائماً \"مفتوح\"';

  @override
  String get hoursScheduleHint => 'حدد أوقات الدوام لكل يوم:';

  @override
  String get hoursSaveBtn => 'حفظ التغييرات';

  @override
  String get hoursSaved => '✅ تم حفظ ساعات العمل';

  @override
  String hoursSaveError(String error) {
    return '❌ فشل الحفظ: $error';
  }

  @override
  String get hoursCopyAll => 'نسخ لكل الأيام';

  @override
  String get hoursAddShift => 'إضافة فترة';

  @override
  String get hoursClosed => 'مغلق';

  @override
  String get hoursCopiedAll => 'تم نسخ التوقيت لكل الأيام';

  @override
  String get hoursMonday => 'الإثنين';

  @override
  String get hoursTuesday => 'الثلاثاء';

  @override
  String get hoursWednesday => 'الأربعاء';

  @override
  String get hoursThursday => 'الخميس';

  @override
  String get hoursFriday => 'الجمعة';

  @override
  String get hoursSaturday => 'السبت';

  @override
  String get hoursSunday => 'الأحد';

  @override
  String get scanTitle => 'المسح الضوئي (تجار)';

  @override
  String get scanRedeemSuccess => '✅ تم صرف العرض بنجاح!';

  @override
  String get scanRedeemError => '❌ حدث خطأ أثناء الصرف';

  @override
  String get scanValidOffer => 'عرض صحيح';

  @override
  String get scanInvalidOffer => 'عرض غير صالح';

  @override
  String get scanUnnamedOffer => 'عرض غير مسمى';

  @override
  String get scanUnknownVenue => 'مكان غير معروف';

  @override
  String scanReasonPrefix(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get scanRedeemBtn => 'صرف العرض (Redeem)';

  @override
  String get scanMerchantRequired => 'يجب عليك تسجيل الدخول كتاجر لصرف العرض';

  @override
  String get scanCancelRescan => 'الغاء / مسح جديد';

  @override
  String get menuSectionOther => 'أخرى';

  @override
  String get menuErrorNotMerchant => 'يجب تسجيل الدخول كتاجر.';

  @override
  String get menuDraftPublished => 'تم نشر المسودة بنجاح';

  @override
  String menuDraftPublishFailed(String error) {
    return 'فشل نشر المسودة: $error';
  }

  @override
  String get menuNoArchivedVersions => 'لا توجد نسخ سابقة متاحة';

  @override
  String get menuSelectArchivedVersion => 'اختر النسخة السابقة';

  @override
  String get menuRollbackSuccess => 'تم استرجاع النسخة بنجاح';

  @override
  String menuRollbackFailed(String error) {
    return 'فشل استرجاع النسخة: $error';
  }

  @override
  String get menuNoEditableSections => 'لا توجد أقسام قابلة للتعديل في هذه المسودة بعد.';

  @override
  String get menuManageSections => 'إدارة الأقسام';

  @override
  String get menuAdd => 'إضافة';

  @override
  String menuReorderFailed(String error) {
    return 'فشل إعادة الترتيب: $error';
  }

  @override
  String get menuRename => 'إعادة تسمية';

  @override
  String get menuDelete => 'حذف';

  @override
  String get menuSectionNameHint => 'اسم القسم';

  @override
  String get menuCancel => 'إلغاء';

  @override
  String get menuSave => 'حفظ';

  @override
  String get menuAddSectionTitle => 'إضافة قسم';

  @override
  String get menuSectionAdded => 'تمت إضافة القسم';

  @override
  String menuSectionAddFailed(String error) {
    return 'فشل إضافة القسم: $error';
  }

  @override
  String get menuRenameSectionTitle => 'إعادة تسمية القسم';

  @override
  String get menuSectionUpdated => 'تم تحديث القسم';

  @override
  String menuSectionUpdateFailed(String error) {
    return 'فشل تعديل القسم: $error';
  }

  @override
  String get menuKeepOneSection => 'يجب الإبقاء على قسم واحد على الأقل.';

  @override
  String get menuDeleteSectionTitle => 'حذف القسم';

  @override
  String menuDeleteSectionConfirm(String sectionName) {
    return 'سيتم حذف القسم \"$sectionName\".';
  }

  @override
  String get menuMoveItemsTo => 'نقل العناصر إلى:';

  @override
  String get menuSectionDeleted => 'تم حذف القسم';

  @override
  String menuSectionDeleteFailed(String error) {
    return 'فشل حذف القسم: $error';
  }

  @override
  String get menuManageMenuTitle => 'إدارة المنيو';

  @override
  String get menuManageCategoriesTooltip => 'إدارة الأقسام';

  @override
  String get menuPublishDraftTooltip => 'نشر المسودة';

  @override
  String get menuRollbackTooltip => 'استرجاع لإصدار مؤرشف';

  @override
  String menuError(String error) {
    return 'خطأ: $error';
  }

  @override
  String get menuNoVenueLinked => 'لا يوجد متجر مرتبط بهذا الحساب';

  @override
  String menuDraftPrepareFailed(String error) {
    return 'فشل تجهيز مسودة: $error';
  }

  @override
  String get menuDraftPublishedCreateNew => 'تم نشر آخر مسودة. أنشئ مسودة جديدة لمواصلة التعديل.';

  @override
  String get menuCreateNewDraftBtn => 'أنشئ مسودة جديدة';

  @override
  String menuSectionsError(String error) {
    return 'خطأ في أقسام المنيو: $error';
  }

  @override
  String get menuNoSectionsAvailable => 'لا توفر أقسام منيو';

  @override
  String get menuEditingUnpublishedDraft => 'تعديل مسودة جديدة غير منشورة';

  @override
  String menuEditingDraftOverActive(String versionId) {
    return 'تعديل مسودة فوق الإصدار النشط: $versionId';
  }

  @override
  String get menuManageSectionsBtn => 'إدارة الأقسام';

  @override
  String get menuAddSectionBtn => 'إضافة قسم';

  @override
  String get menuEmptyAddFirstItem => 'المنيو فارغ حالياً. أضف أول صنف عبر زر +';

  @override
  String menuNoItemsInSection(String sectionName) {
    return 'لا توجد عناصر في قسم $sectionName';
  }

  @override
  String menuReorderItemsFailed(String error) {
    return 'فشل إعادة ترتيب العناصر: $error';
  }

  @override
  String menuSaveItemFailed(String error) {
    return 'فشل حفظ العنصر: $error';
  }

  @override
  String get menuAddItemTitle => 'إضافة عنصر';

  @override
  String get menuEditItemTitle => 'تعديل عنصر';

  @override
  String get menuItemNameLabel => 'اسم العنصر';

  @override
  String get menuItemDescLabel => 'الوصف';

  @override
  String get menuItemPriceLabel => 'السعر';

  @override
  String get menuItemAvailableToggle => 'متاح';

  @override
  String get menuItemFeaturedToggle => 'مميز';

  @override
  String get menuItemChooseImage => 'اختر صورة';

  @override
  String get menuItemImageSelected => 'تم اختيار الصورة';

  @override
  String get brandGoogleMaps => 'Google Maps';

  @override
  String get brandWaze => 'Waze';

  @override
  String get brandAiBadge => 'AI';

  @override
  String hoursLoadError(String error) {
    return 'خطأ في تحميل ساعات العمل: $error';
  }

  @override
  String get scanUnknownReason => 'غير معروف';

  @override
  String get inviteCodeHint => 'WAIN-XXXXXX';

  @override
  String get loginPhoneHint => '+970599123456';

  @override
  String get signupEmailHint => 'example@email.com';

  @override
  String get signupPasswordPlaceholder => '????????';

  @override
  String get retryButton => 'حاول مرة ثانية';

  @override
  String get emptyNoResults => 'لا توجد نتائج مطابقة، جرّب تعديل الفلاتر';

  @override
  String get emptyNoResultsAction => 'تعديل الفلاتر';

  @override
  String get emptyNoFavorites => 'لا يوجد أماكن مفضلة بعد';

  @override
  String get emptyNoFavoritesAction => 'استكشف أماكن';

  @override
  String get emptyNoReviews => 'لا توجد تقييمات بعد';

  @override
  String get emptyNoReviewsAction => 'أضف تقييم';

  @override
  String get emptyNoSavedOffers => 'لا يوجد عروض محفوظة بعد';

  @override
  String get emptyNoSavedOffersAction => 'تصفح العروض';

  @override
  String get emptyOffline => 'تعذر تحميل بيانات جديدة، تعرض نسخة محفوظة';

  @override
  String get emptyOfflineAction => 'تحديث';

  @override
  String get hoursOpen24 => 'مفتوح 24 ساعة';

  @override
  String get hoursUnavailable => 'ساعات العمل غير متوفرة';

  @override
  String get hoursUnknown => 'غير معروف';

  @override
  String get hoursClosedToday => 'مغلق اليوم';

  @override
  String get hoursBadgeOpen => 'مفتوح';

  @override
  String get hoursBadgeClosed => 'مغلق';

  @override
  String hoursOpenUntil(String time) {
    return 'مفتوح حتى $time';
  }

  @override
  String get hoursOpenNow => 'مفتوح الآن';

  @override
  String hoursOpensAt(String time) {
    return 'يفتح الساعة $time';
  }

  @override
  String get hoursPeriodAm => 'ص';

  @override
  String get hoursPeriodPm => 'م';

  @override
  String get navDialogTitle => 'ابدأ الملاحة إلى';

  @override
  String get navCancel => 'إلغاء';

  @override
  String get cacheUnknown => 'غير معروف';

  @override
  String get cacheJustNow => 'الآن';

  @override
  String cacheMinsAgo(int mins) {
    return 'منذ $mins دقيقة';
  }

  @override
  String cacheHoursAgo(int hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String cacheDaysAgo(int days) {
    return 'منذ $days يوم';
  }

  @override
  String distanceMeters(String meters) {
    return '$meters م';
  }

  @override
  String distanceKm(String km) {
    return '$km كم';
  }

  @override
  String durationMins(String mins) {
    return '$mins د';
  }

  @override
  String durationHoursMins(String hours, String mins) {
    return '$hours س $mins د';
  }

  @override
  String geofenceNearby(String venue) {
    return '📍 أنت قريب من $venue!';
  }

  @override
  String get geofenceOffers => '🎁 في عروض حصرية بانتظارك!';

  @override
  String get geofenceDiscover => '⭐ اكتشف هذا المكان المميز';

  @override
  String get shareVenueText => 'شوف هالمكان على وين! 🌟';

  @override
  String get errorPageNotFound => 'الصفحة غير موجودة';

  @override
  String get errorGoHome => 'العودة للرئيسية';

  @override
  String get mapNoVenuesInArea => 'لا توجد أماكن في هذه المنطقة حالياً';

  @override
  String mapFoundVenuesWithOffers(String count, String offers) {
    return 'تم العثور على $count مكان ($offers عروض متاحة 🔥)';
  }

  @override
  String mapFoundVenues(String count) {
    return 'تم العثور على $count مكان';
  }

  @override
  String get mapSearchError => 'حدث خطأ في البحث';

  @override
  String get mapBoundsTooLarge => 'المنطقة كبيرة جداً، يرجى التقريب أكثر';

  @override
  String get mapRateLimited => 'تم تجاوز حد البحث المسموح';

  @override
  String get mapNavModeActive => 'وضع الملاحة مفعل';

  @override
  String get mapSearchHint => 'ابحث عن مكان...';

  @override
  String get mapFilterTopRated => 'الأعلى تقييماً';

  @override
  String get mapFilterExplore => 'استكشاف';

  @override
  String get mapFilterOpenNow => 'مفتوح الآن';

  @override
  String get mapFilterPartners => 'شركاء';

  @override
  String get mapFilterOffers => 'عروض';

  @override
  String get mapFilterRestaurants => 'مطاعم';

  @override
  String get mapFilterCafes => 'كافيهات';

  @override
  String get mapFilterRomantic => 'رومانسي';

  @override
  String get mapFilterFamily => 'عائلي';

  @override
  String get mapOfflineBanner => 'أنت غير متصل - تصفح النسخة المحفوظة';

  @override
  String get mapOfferAvailable => 'يوجد عرض متاح';

  @override
  String get mapCategoryGeneral => 'عام';

  @override
  String get mapGetOfferNow => 'احصل على العرض الآن';

  @override
  String get mapDetails => 'التفاصيل';

  @override
  String get mapDirections => 'اتجاهات';

  @override
  String mapVenueCount(String count) {
    return '$count مكان';
  }

  @override
  String mapDistanceAway(String distance) {
    return 'يبعد $distance كم';
  }

  @override
  String get mapNeedsConnection => 'يحتاج اتصال';

  @override
  String get mapStartNavigation => 'ابدأ الملاحة';

  @override
  String get mapRouteFetchFailed => 'فشل جلب الطريق';

  @override
  String get profileTitle => 'الإعدادات';

  @override
  String get profileSectionActivity => 'نشاطي';

  @override
  String get profileMyOffers => 'عروضي';

  @override
  String get profileMyOffersSubtitle => 'العروض المستخدمة';

  @override
  String get profileSavedOffers => 'العروض المحفوظة';

  @override
  String get profileSavedOffersSubtitle => 'العروض التي حفظتها';

  @override
  String get profileMyStats => 'إحصائياتي';

  @override
  String get profileMyStatsSubtitle => 'ملخص نشاطك على وين';

  @override
  String get profileTryList => 'بدي أجرّب 🎯';

  @override
  String get profileTryListSubtitle => 'أماكن حابب تزورها';

  @override
  String get profileMerchantDashboard => 'لوحة التاجر 📊';

  @override
  String get profileMerchantDashboardSubtitle => 'إدارة محلك وإحصائياته';

  @override
  String get profileJoinMerchant => 'التحق كتاجر';

  @override
  String get profileJoinMerchantSubtitle => 'عندك محل؟ أدخل رمز الدعوة';

  @override
  String get profileSectionSettings => 'الإعدادات';

  @override
  String get profileCity => 'المدينة';

  @override
  String get profileLanguage => 'اللغة';

  @override
  String get profileLanguageAr => 'العربية';

  @override
  String get profileTheme => 'المظهر';

  @override
  String get profileThemeDark => 'داكن';

  @override
  String get profileThemeLight => 'فاتح';

  @override
  String get profileGeofenceNotifs => 'إشعارات القرب';

  @override
  String get profileGeofenceNotifsSubtitle => 'تنبيه عند الاقتراب من أماكن مميزة';

  @override
  String get profileSectionAbout => 'عن التطبيق';

  @override
  String get profileAboutWain => 'عن وين';

  @override
  String get profilePrivacy => 'سياسة الخصوصية';

  @override
  String get profileHelp => 'المساعدة';

  @override
  String profileVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get profileMerchantScan => 'دخول التاجر (Scan)';

  @override
  String get profileChooseCity => 'اختر المدينة';

  @override
  String get profileUser => 'مستخدم';

  @override
  String get profileSignOut => 'تسجيل الخروج';

  @override
  String get profileGuestUser => 'مستخدم ضيف';

  @override
  String get profileGuestSubtitle => 'سجل دخولك لحفظ المفضلة';

  @override
  String get profileSignIn => 'تسجيل الدخول';

  @override
  String get venueCardBestMatch => 'الأفضل';

  @override
  String get venueCardOpen => 'مفتوح';

  @override
  String get venueCardClosed => 'مغلق';

  @override
  String get nearbyVenuesTitle => 'أماكن قريبة منك';

  @override
  String get nearbyApproxLocation => 'موقع تقريبي';

  @override
  String get categoryGeneral => 'عام';

  @override
  String get statsTitle => 'إحصائياتي';

  @override
  String get statsLoginPrompt => 'سجّل دخولك لعرض إحصائياتك';

  @override
  String statsWelcome(String name) {
    return 'مرحباً $name!';
  }

  @override
  String get statsActivitySummary => 'ملخص نشاطك على وين';

  @override
  String get statsUsedOffers => 'عروض مستخدمة';

  @override
  String get statsReviews => 'تقييمات';

  @override
  String get statsFavorites => 'مفضلات';

  @override
  String get statsRecentActivity => 'نشاطك الأخير';

  @override
  String get statsReviewsReady => 'ميزة التقييمات جاهزة!';

  @override
  String get statsReviewsReadySub => 'قيّم الأماكن اللي زرتها';

  @override
  String get statsTimeNow => 'الآن';

  @override
  String get statsExploreOffers => 'استكشف العروض الحصرية';

  @override
  String get statsExploreOffersSub => 'عروض جديدة كل يوم';

  @override
  String get statsTimeToday => 'اليوم';

  @override
  String get statsDiscoverPlaces => 'اكتشف أماكن جديدة';

  @override
  String get statsDiscoverPlacesSub => 'جرّب سؤال \"وين أروح؟\"';

  @override
  String get statsTimeNew => 'جديد';

  @override
  String get statsAchievements => 'إنجازاتك';

  @override
  String get statsNewExplorer => 'مستكشف جديد';

  @override
  String get statsReviewer => 'مقيّم';

  @override
  String get statsOfferHunter => 'صائد عروض';

  @override
  String get statsPlaceLover => 'محب الأماكن';

  @override
  String get statsWainExpert => 'خبير وين';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingExploreTitle => 'استكشف واكتشف';

  @override
  String get onboardingExploreDesc => 'اكتشف أفضل الكافيهات والمطاعم والأماكن الترفيهية حولك بسهولة.';

  @override
  String get onboardingOffersTitle => 'عروض حصرية';

  @override
  String get onboardingOffersDesc => 'استفد من خصومات وعروض خاصة للمستخدمين عند زيارة شركائنا.';

  @override
  String get onboardingNavigateTitle => 'حدد وجهتك';

  @override
  String get onboardingNavigateDesc => 'احصل على اتجاهات دقيقة وتعرف على الأماكن المفتوحة الآن.';

  @override
  String get favoritesTitle => 'المفضلة';

  @override
  String get tryListTitle => 'بدي أجرّب 🎯';

  @override
  String tryListMovedToFav(String name) {
    return '✅ $name انتقل للمفضلة!';
  }

  @override
  String get tryListUndo => 'تراجع';

  @override
  String tryListRemoved(String name) {
    return '🗑️ $name شيلناه من القائمة';
  }

  @override
  String tryListTriedIt(String name) {
    return '🎉 $name جرّبتها! انتقل للمفضلة';
  }

  @override
  String get tryListTriedItBtn => 'جرّبتها';

  @override
  String get tryListEmptyTitle => 'لسا ما ضفت أماكن';

  @override
  String get tryListEmptySubtitle => 'اضغط على 🎯 في أي مكان عشان تضيفه لقائمة \"بدي أجرّب\"';

  @override
  String get tryListExploreBtn => 'اكتشف أماكن';

  @override
  String get tryListInfoTitle => 'قائمة \"بدي أجرّب\" 🎯';

  @override
  String get tryListInfoBody => 'هون بتلاقي الأماكن اللي حابب تجرّبها.\n\n• اضغط \"جرّبتها ✅\" عشان تنقلها للمفضلة\n• اضغط ✕ عشان تشيلها من القائمة\n• اضغط على المكان عشان تشوف تفاصيله';

  @override
  String get tryListInfoDismiss => 'فهمت';

  @override
  String get helpTitle => 'المساعدة';

  @override
  String get helpContactUs => 'تواصل معنا';

  @override
  String get helpEmail => 'البريد الإلكتروني';

  @override
  String get helpWhatsApp => 'واتساب';

  @override
  String get helpFaq => 'الأسئلة الشائعة';

  @override
  String get helpFaqOffersQ => 'كيف أستخدم العروض؟';

  @override
  String get helpFaqOffersA => 'اضغط على أي عرض متاح، ثم اضغط \"احصل على العرض\". سيظهر لك رمز QR يمكنك إظهاره للتاجر خلال 10 دقائق.';

  @override
  String get helpFaqMultiUseQ => 'هل يمكنني استخدام العرض أكثر من مرة؟';

  @override
  String get helpFaqMultiUseA => 'كل عرض له حد استخدام معين. بعض العروض يمكن استخدامها مرة واحدة فقط، بينما البعض الآخر يمكن استخدامه عدة مرات.';

  @override
  String get helpFaqLocationQ => 'لماذا لا يظهر موقعي؟';

  @override
  String get helpFaqLocationA => 'تأكد من السماح للتطبيق بالوصول للموقع من إعدادات الهاتف. اذهب إلى الإعدادات > التطبيقات > وين > الأذونات > الموقع.';

  @override
  String get helpFaqAddPlaceQ => 'كيف أضيف مكاني للتطبيق؟';

  @override
  String get helpFaqAddPlaceA => 'إذا كنت صاحب مطعم أو كافيه وترغب في الانضمام، تواصل معنا عبر البريد الإلكتروني وسنقوم بإضافة مكانك.';

  @override
  String get helpFaqFreeQ => 'هل التطبيق مجاني؟';

  @override
  String get helpFaqFreeA => 'نعم! التطبيق مجاني تماماً للمستخدمين. نحن نعمل مع الشركاء لتوفير أفضل العروض لكم.';

  @override
  String get privacyTitle => 'سياسة الخصوصية';

  @override
  String get privacyLastUpdate => 'آخر تحديث: فبراير 2026';

  @override
  String get privacySection1Title => '1. المعلومات التي نجمعها';

  @override
  String get privacySection1Body => '• معلومات الموقع الجغرافي لعرض الأماكن القريبة منك\n• معرّف الجهاز للتعرف على حسابك\n• الأماكن المفضلة والعروض المستخدمة\n• إحصائيات الاستخدام لتحسين التطبيق';

  @override
  String get privacySection2Title => '2. كيف نستخدم معلوماتك';

  @override
  String get privacySection2Body => '• تقديم توصيات مخصصة للأماكن\n• عرض العروض المتاحة في منطقتك\n• تحسين تجربة المستخدم\n• التواصل معك بخصوص العروض الجديدة';

  @override
  String get privacySection3Title => '3. مشاركة المعلومات';

  @override
  String get privacySection3Body => 'نحن لا نبيع أو نشارك معلوماتك الشخصية مع أطراف ثالثة إلا في الحالات التالية:\n• بموافقتك الصريحة\n• للامتثال للقوانين والأنظمة\n• لحماية حقوقنا أو ممتلكاتنا';

  @override
  String get privacySection4Title => '4. أمان البيانات';

  @override
  String get privacySection4Body => 'نستخدم تقنيات تشفير متقدمة لحماية بياناتك. يتم تخزين جميع البيانات على خوادم Firebase المؤمنة.';

  @override
  String get privacySection5Title => '5. حقوقك';

  @override
  String get privacySection5Body => '• يمكنك طلب حذف بياناتك في أي وقت\n• يمكنك إيقاف خدمات الموقع من الإعدادات\n• يمكنك التواصل معنا لأي استفسارات';

  @override
  String get privacySection6Title => '6. التواصل معنا';

  @override
  String get privacySection6Body => 'للاستفسارات حول سياسة الخصوصية:\nالبريد الإلكتروني: privacy@wain.app';

  @override
  String get notificationsTitle => 'الإشعارات 🔔';

  @override
  String get notificationsMarkAllRead => 'تحديد الكل كمقروء';

  @override
  String notificationsError(String error) {
    return 'خطأ: $error';
  }

  @override
  String get notificationsEmpty => 'لا توجد إشعارات حالياً';

  @override
  String get notificationsNewNotif => 'إشعار جديد';

  @override
  String get notificationsHintReview => 'اضغط لفتح التقييمات والرد بسرعة';

  @override
  String get notificationsHintOffer => 'اضغط لفتح العروض ومتابعة الأداء';

  @override
  String get notificationsHintWelcome => 'اضغط لفتح لوحة التاجر';

  @override
  String get resultsSuggestions => 'اقتراحاتنا';

  @override
  String get resultsBestMatch => 'أفضل اقتراح';

  @override
  String get resultsBestMatchSub => 'بناءً على اختياراتك';

  @override
  String get resultsChangeChoices => 'غيّر الاختيارات';

  @override
  String get filterTitle => 'تصفية وترتيب';

  @override
  String get filterReset => 'إعادة تعيين';

  @override
  String get filterBudgetRange => 'نطاق السعر للشخص';

  @override
  String get filterSortBy => 'ترتيب حسب';

  @override
  String get filterCuisineType => 'نوع المطبخ';

  @override
  String get filterApply => 'تطبيق';

  @override
  String get filterSortRating => 'التقييم';

  @override
  String get filterSortDistance => 'المسافة';

  @override
  String get filterSortBudgetLow => 'السعر ↑';

  @override
  String get filterSortBudgetHigh => 'السعر ↓';

  @override
  String get filterCuisineArabic => 'عربي';

  @override
  String get filterCuisineItalian => 'إيطالي';

  @override
  String get filterCuisineAsian => 'آسيوي';

  @override
  String get filterCuisineAmerican => 'أمريكي';

  @override
  String get filterCuisineFastFood => 'وجبات سريعة';

  @override
  String get filterCuisineDesserts => 'حلويات';

  @override
  String get filterCuisineCoffee => 'قهوة';

  @override
  String get filterCuisineSeafood => 'مأكولات بحرية';

  @override
  String get editProfileTitle => 'تعديل الملف الشخصي';

  @override
  String get editProfileSave => 'حفظ';

  @override
  String get editProfileUsername => 'اسم المستخدم';

  @override
  String get editProfileUsernameHint => 'اختر اسم مستخدم فريد';

  @override
  String get editProfileUsernameRules => '3-20 حرف، أحرف وأرقام و _ فقط';

  @override
  String get editProfileDisplayName => 'الاسم الظاهر';

  @override
  String get editProfileDisplayNameHint => 'أدخل اسمك';

  @override
  String get editProfileUsernameTooShort => 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';

  @override
  String get editProfileUsernameNotAvailable => 'اسم المستخدم غير متاح';

  @override
  String get editProfileSaved => 'تم حفظ التغييرات';

  @override
  String get aboutTitle => 'عن وين';

  @override
  String get aboutAppName => 'وين';

  @override
  String get aboutVersion => 'الإصدار 1.0.0';

  @override
  String get aboutDescription => 'وين هو تطبيق ذكي لاكتشاف أفضل الأماكن في فلسطين. نساعدك على إيجاد المطاعم والكافيهات المناسبة لمزاجك ومناسبتك.\n\nسواء كنت تبحث عن مكان رومانسي، أو تجمع عائلي، أو مكان للعمل - وين سيساعدك على اتخاذ القرار الصحيح!';

  @override
  String get aboutFeatureDiscover => 'اكتشف الأماكن القريبة';

  @override
  String get aboutFeatureOffers => 'عروض حصرية للمستخدمين';

  @override
  String get aboutFeatureFavorites => 'احفظ أماكنك المفضلة';

  @override
  String get aboutFeatureNavigation => 'توجيه مباشر للمكان';

  @override
  String dashboardRefreshSuccess(String views, String calls, String navs) {
    return 'تم تحديث بيانات الأداء • مشاهدات: $views • اتصالات: $calls • تنقل: $navs';
  }

  @override
  String dashboardRefreshFailed(String error) {
    return 'فشل تحديث بيانات الأداء: $error';
  }

  @override
  String get dashboardErrorPermission => 'الحساب غير مربوط كتاجر بشكل صحيح. افتح كود الدعوة وأعد الربط.';

  @override
  String get dashboardErrorIndex => 'ينقص Index للتحليلات في Firestore. نفّذ deploy لـ firestore:indexes.';

  @override
  String get dashboardErrorNoVenue => 'لا يوجد محل مربوط بهذا الحساب. اربط المحل أولاً ثم أعد المحاولة.';

  @override
  String get dashboardErrorUnauthenticated => 'يلزم تسجيل الدخول مرة أخرى قبل التحديث.';

  @override
  String merchantPhotosErrorInline(String error) {
    return '❌ خطأ: $error';
  }

  @override
  String get merchantStoriesPromote1Day => 'يوم واحد (1\$)';

  @override
  String get merchantStoriesPromote3Days => '3 أيام (2.5\$)';

  @override
  String get merchantStoriesPromote7Days => 'أسبوع (5\$)';

  @override
  String get questionOccasionTitle => 'المناسبة؟';

  @override
  String get questionMoodTitle => 'شو المود اليوم؟';

  @override
  String get questionCuisineTitle => 'قربنا نخلص\nشو حابب تاكل؟';

  @override
  String get questionCompanionTitle => 'مع مين رايح؟';

  @override
  String questionStepOf(String step, String total) {
    return 'خطوة $step من $total';
  }

  @override
  String get questionMap => 'الخريطة';

  @override
  String get questionSkip => 'تخطي';

  @override
  String get optionBirthday => 'عيد ميلاد';

  @override
  String get optionAnniversary => 'ذكرى سنوية';

  @override
  String get optionMeeting => 'اجتماع';

  @override
  String get optionFastFood => 'اكل سريع';

  @override
  String get optionSoloTime => 'وقت لحالي';

  @override
  String get optionOutdoor => 'قعدات خارجية';

  @override
  String get optionCouples => 'اجواء رومانسية';

  @override
  String get optionFamily => 'اجواء عيلة';

  @override
  String get optionWork => 'عمل';

  @override
  String get optionChill => 'رواق';

  @override
  String get optionFun => 'ترفيه';

  @override
  String get optionPalestinian => 'فلسطيني/شامي';

  @override
  String get optionKhaleeji => 'خليجي';

  @override
  String get optionItalian => 'إيطالي';

  @override
  String get optionAsian => 'آسيوي';

  @override
  String get optionDesserts => 'حلويات';

  @override
  String get optionCafe => 'كافيه/قهوة';

  @override
  String get optionFriends => 'الأصدقاء';

  @override
  String get optionPartner => 'خطيب/زوج';

  @override
  String get optionFamilyKids => 'العائلة والأطفال';

  @override
  String get optionSolo => 'لحالي';

  @override
  String get optionBusiness => 'لقاء عمل';

  @override
  String get homeHeading => 'مش عارف وين تروح؟';

  @override
  String get homeSubtitle => 'خليني أساعدك تلاقي أفضل مكان بـ 4\nأسئلة سريعة';

  @override
  String get homeStart => 'يلا نبدأ';

  @override
  String get homeNoThanks => 'لا شكراً';

  @override
  String get statsDefaultName => 'بك';

  @override
  String get dashboard7Days => '7 أيام';

  @override
  String get dashboard30Days => '30 يوم';

  @override
  String tryListError(String error) {
    return 'خطأ: $error';
  }
}
