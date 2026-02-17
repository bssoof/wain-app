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
  String get openInGoogleMaps => 'فتح في خرائط جوجل';

  @override
  String get openInWaze => 'فتح في ويز';

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
  String get importantNotice => 'تنبيه هام';

  @override
  String get offerValidTenMinutes => 'هذا العرض صالح لمدة 10 دقائق فقط!';

  @override
  String get offerActivationWarning => 'يرجى عدم تفعيل العرض إلا عند تواجدك داخل المطعم وأمام الكاشير.\n\nبمجرد التفعيل، سيبدأ العداد ولن تتمكن من إيقافه.';

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
  String get dayMonday => 'الإثنين';

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
  String get tryListAdded => 'تمت الإضافة لقائمة \"بدي أجرّب\"';

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
  String get offerDetails => 'عرض التفاصيل';

  @override
  String get getOffer => 'احصل على العرض';

  @override
  String get needConnection => 'تحتاج اتصال';
}
