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
  String get tryListRemoved => 'تم الحذف من القائمة';

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
  String get merchantStories7d => '7 أيام';

  @override
  String get merchantStoriesPublishBtn => 'نشر الستوري';

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
}
