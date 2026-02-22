import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @venueNotFound.
  ///
  /// In en, this message translates to:
  /// **'Venue not found'**
  String get venueNotFound;

  /// No description provided for @selectMapApp.
  ///
  /// In en, this message translates to:
  /// **'Choose map app'**
  String get selectMapApp;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @openInWaze.
  ///
  /// In en, this message translates to:
  /// **'Open in Waze'**
  String get openInWaze;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @menuNoMatchingResults.
  ///
  /// In en, this message translates to:
  /// **'No matching menu results'**
  String get menuNoMatchingResults;

  /// No description provided for @photoSingle.
  ///
  /// In en, this message translates to:
  /// **'photo'**
  String get photoSingle;

  /// No description provided for @photoPlural.
  ///
  /// In en, this message translates to:
  /// **'photos'**
  String get photoPlural;

  /// No description provided for @noMenuAvailable.
  ///
  /// In en, this message translates to:
  /// **'No menu is available right now'**
  String get noMenuAvailable;

  /// No description provided for @menuLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load menu right now'**
  String get menuLoadFailed;

  /// No description provided for @importantNotice.
  ///
  /// In en, this message translates to:
  /// **'Important notice'**
  String get importantNotice;

  /// No description provided for @offerValidTenMinutes.
  ///
  /// In en, this message translates to:
  /// **'This offer is valid for only 10 minutes!'**
  String get offerValidTenMinutes;

  /// No description provided for @offerActivationWarning.
  ///
  /// In en, this message translates to:
  /// **'Please do not activate the offer unless you are inside the venue and in front of the cashier.\\n\\nOnce activated, the timer will start and cannot be stopped.'**
  String get offerActivationWarning;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @activateOfferNow.
  ///
  /// In en, this message translates to:
  /// **'Activate offer now'**
  String get activateOfferNow;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @claimRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit claim'**
  String get claimRequestFailed;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @meterUnit.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get meterUnit;

  /// No description provided for @kilometerUnit.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kilometerUnit;

  /// No description provided for @distanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String distanceAway(String distance);

  /// No description provided for @detectingLocation.
  ///
  /// In en, this message translates to:
  /// **'Detecting location...'**
  String get detectingLocation;

  /// No description provided for @failedToDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to detect location'**
  String get failedToDetectLocation;

  /// No description provided for @menuItemCounter.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get menuItemCounter;

  /// No description provided for @menuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @searchInMenuHint.
  ///
  /// In en, this message translates to:
  /// **'Search in menu...'**
  String get searchInMenuHint;

  /// No description provided for @featuredItems.
  ///
  /// In en, this message translates to:
  /// **'Featured items'**
  String get featuredItems;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @offersAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available offers'**
  String get offersAvailable;

  /// No description provided for @offersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load offers'**
  String get offersLoadFailed;

  /// No description provided for @noOffersNow.
  ///
  /// In en, this message translates to:
  /// **'No offers currently available'**
  String get noOffersNow;

  /// No description provided for @followForNewOffers.
  ///
  /// In en, this message translates to:
  /// **'Follow us for new offers'**
  String get followForNewOffers;

  /// No description provided for @hoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get hoursTitle;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openNow;

  /// No description provided for @open24Hours.
  ///
  /// In en, this message translates to:
  /// **'Open 24 hours'**
  String get open24Hours;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// No description provided for @generalCategory.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalCategory;

  /// No description provided for @socialLinks.
  ///
  /// In en, this message translates to:
  /// **'Social links'**
  String get socialLinks;

  /// No description provided for @tryListAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to try list'**
  String get tryListAdded;

  /// No description provided for @tryListRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from list'**
  String get tryListRemoved;

  /// No description provided for @venueStories.
  ///
  /// In en, this message translates to:
  /// **'Venue stories'**
  String get venueStories;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @story.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get story;

  /// No description provided for @partnerBadge.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get partnerBadge;

  /// No description provided for @offerDetails.
  ///
  /// In en, this message translates to:
  /// **'Offer details'**
  String get offerDetails;

  /// No description provided for @getOffer.
  ///
  /// In en, this message translates to:
  /// **'Get offer'**
  String get getOffer;

  /// No description provided for @needConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection needed'**
  String get needConnection;

  /// No description provided for @tabMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get tabMenu;

  /// No description provided for @tabReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get tabReviews;

  /// No description provided for @tabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get tabAbout;

  /// No description provided for @reviewFormSelectRating.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating'**
  String get reviewFormSelectRating;

  /// No description provided for @reviewFormLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'You must login to add a review'**
  String get reviewFormLoginRequired;

  /// No description provided for @reviewFormSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your review was added successfully!'**
  String get reviewFormSuccess;

  /// No description provided for @reviewFormError.
  ///
  /// In en, this message translates to:
  /// **'Failed to add review: {error}'**
  String reviewFormError(String error);

  /// No description provided for @reviewFormTitlePrefix.
  ///
  /// In en, this message translates to:
  /// **'Review {venue}'**
  String reviewFormTitlePrefix(String venue);

  /// No description provided for @reviewFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your experience with this place'**
  String get reviewFormSubtitle;

  /// No description provided for @reviewFormHint.
  ///
  /// In en, this message translates to:
  /// **'Write your review here (optional)...'**
  String get reviewFormHint;

  /// No description provided for @reviewFormSubmitBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get reviewFormSubmitBtn;

  /// No description provided for @reviewRatingTerrible.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get reviewRatingTerrible;

  /// No description provided for @reviewRatingPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get reviewRatingPoor;

  /// No description provided for @reviewRatingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reviewRatingGood;

  /// No description provided for @reviewRatingVeryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get reviewRatingVeryGood;

  /// No description provided for @reviewRatingExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get reviewRatingExcellent;

  /// No description provided for @reviewRatingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose your rating'**
  String get reviewRatingPrompt;

  /// No description provided for @reviewsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Reviews'**
  String get reviewsSectionTitle;

  /// No description provided for @reviewsSectionAddBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Review'**
  String get reviewsSectionAddBtn;

  /// No description provided for @reviewsSectionLoadFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reviews'**
  String get reviewsSectionLoadFail;

  /// No description provided for @reviewsSectionEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get reviewsSectionEmptyTitle;

  /// No description provided for @reviewsSectionEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be the first to review this place!'**
  String get reviewsSectionEmptySubtitle;

  /// No description provided for @reviewsSectionCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsSectionCountLabel(num count);

  /// No description provided for @reviewsSectionViewAllCount.
  ///
  /// In en, this message translates to:
  /// **'View all reviews ({count})'**
  String reviewsSectionViewAllCount(num count);

  /// No description provided for @reviewsSectionMerchantReply.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s reply'**
  String get reviewsSectionMerchantReply;

  /// No description provided for @reviewsSectionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Review'**
  String get reviewsSectionDeleteTitle;

  /// No description provided for @reviewsSectionDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your review?'**
  String get reviewsSectionDeleteConfirm;

  /// No description provided for @reviewsSectionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reviewsSectionCancel;

  /// No description provided for @reviewsSectionDeleteBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get reviewsSectionDeleteBtn;

  /// No description provided for @reviewsSectionAllTitle.
  ///
  /// In en, this message translates to:
  /// **'All Reviews ({count})'**
  String reviewsSectionAllTitle(num count);

  /// No description provided for @reviewsTimeNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get reviewsTimeNow;

  /// No description provided for @reviewsTimeMins.
  ///
  /// In en, this message translates to:
  /// **'{mins} mins ago'**
  String reviewsTimeMins(num mins);

  /// No description provided for @reviewsTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String reviewsTimeHours(num hours);

  /// No description provided for @reviewsTimeDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String reviewsTimeDays(num days);

  /// No description provided for @reviewsTimeWeeks.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks ago'**
  String reviewsTimeWeeks(num weeks);

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @menuShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all (+{count})'**
  String menuShowAll(int count);

  /// No description provided for @menuShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get menuShowLess;

  /// No description provided for @menuResultsSummary.
  ///
  /// In en, this message translates to:
  /// **'{itemsCount} items in {sectionsCount} sections'**
  String menuResultsSummary(int itemsCount, int sectionsCount);

  /// No description provided for @venueSummaryStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get venueSummaryStatus;

  /// No description provided for @venueSummaryDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get venueSummaryDistance;

  /// No description provided for @venueSummaryClosesAt.
  ///
  /// In en, this message translates to:
  /// **'Closes at'**
  String get venueSummaryClosesAt;

  /// No description provided for @venueSummaryPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get venueSummaryPriceRange;

  /// No description provided for @venueSummaryNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get venueSummaryNotAvailable;

  /// No description provided for @venueSummaryClosedToday.
  ///
  /// In en, this message translates to:
  /// **'Closed today'**
  String get venueSummaryClosedToday;

  /// No description provided for @merchantDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Merchant Dashboard'**
  String get merchantDashboardTitle;

  /// No description provided for @merchantManageVenue.
  ///
  /// In en, this message translates to:
  /// **'Manage Venue'**
  String get merchantManageVenue;

  /// No description provided for @merchantNoVenueLinked.
  ///
  /// In en, this message translates to:
  /// **'No venue linked to your account'**
  String get merchantNoVenueLinked;

  /// No description provided for @merchantEnterInvitePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter invite code to link your venue'**
  String get merchantEnterInvitePrompt;

  /// No description provided for @merchantEnterInviteBtn.
  ///
  /// In en, this message translates to:
  /// **'Enter invite code'**
  String get merchantEnterInviteBtn;

  /// No description provided for @merchantStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get merchantStats;

  /// No description provided for @merchantRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get merchantRating;

  /// No description provided for @merchantReviewCount.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get merchantReviewCount;

  /// No description provided for @merchantVisitorEngagement.
  ///
  /// In en, this message translates to:
  /// **'Visitor engagement'**
  String get merchantVisitorEngagement;

  /// No description provided for @merchantThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get merchantThisWeek;

  /// No description provided for @merchantViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get merchantViews;

  /// No description provided for @merchantCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get merchantCalls;

  /// No description provided for @merchantNavs.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get merchantNavs;

  /// No description provided for @merchantStoryViews.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get merchantStoryViews;

  /// No description provided for @merchantTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}'**
  String merchantTotalLabel(int total);

  /// No description provided for @merchantTrends.
  ///
  /// In en, this message translates to:
  /// **'Performance trends'**
  String get merchantTrends;

  /// No description provided for @merchantNoTrendData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to display trends yet'**
  String get merchantNoTrendData;

  /// No description provided for @merchantTrendLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load trend data'**
  String get merchantTrendLoadFailed;

  /// No description provided for @merchantNoChartActivity.
  ///
  /// In en, this message translates to:
  /// **'Not enough activity to display chart'**
  String get merchantNoChartActivity;

  /// No description provided for @merchantBestDay.
  ///
  /// In en, this message translates to:
  /// **'Best day: {dateKey} • {views} views'**
  String merchantBestDay(String dateKey, int views);

  /// No description provided for @merchantViewsLast.
  ///
  /// In en, this message translates to:
  /// **'Views last {range}'**
  String merchantViewsLast(String range);

  /// No description provided for @merchantCallsLast.
  ///
  /// In en, this message translates to:
  /// **'Calls last {range}'**
  String merchantCallsLast(String range);

  /// No description provided for @merchantNavsLast.
  ///
  /// In en, this message translates to:
  /// **'Navigation last {range}'**
  String merchantNavsLast(String range);

  /// No description provided for @merchantViewsWow.
  ///
  /// In en, this message translates to:
  /// **'Views WoW'**
  String get merchantViewsWow;

  /// No description provided for @merchantCallsWow.
  ///
  /// In en, this message translates to:
  /// **'Calls WoW'**
  String get merchantCallsWow;

  /// No description provided for @merchantNavsWow.
  ///
  /// In en, this message translates to:
  /// **'Navigation WoW'**
  String get merchantNavsWow;

  /// No description provided for @merchantRecentReviews.
  ///
  /// In en, this message translates to:
  /// **'Recent reviews'**
  String get merchantRecentReviews;

  /// No description provided for @merchantNoReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get merchantNoReviewsYet;

  /// No description provided for @merchantDefaultUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get merchantDefaultUser;

  /// No description provided for @merchantOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get merchantOffers;

  /// No description provided for @merchantNoOffersNow.
  ///
  /// In en, this message translates to:
  /// **'No offers right now'**
  String get merchantNoOffersNow;

  /// No description provided for @merchantDefaultOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get merchantDefaultOfferTitle;

  /// No description provided for @merchantVenueInfo.
  ///
  /// In en, this message translates to:
  /// **'Venue info'**
  String get merchantVenueInfo;

  /// No description provided for @merchantInfoName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get merchantInfoName;

  /// No description provided for @merchantInfoCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get merchantInfoCity;

  /// No description provided for @merchantInfoPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get merchantInfoPhone;

  /// No description provided for @merchantInfoCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get merchantInfoCategory;

  /// No description provided for @merchantOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get merchantOpenNow;

  /// No description provided for @merchantClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get merchantClosed;

  /// No description provided for @merchantDefaultVenueName.
  ///
  /// In en, this message translates to:
  /// **'Venue name'**
  String get merchantDefaultVenueName;

  /// No description provided for @merchantDefaultType.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get merchantDefaultType;

  /// No description provided for @merchantErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String merchantErrorGeneric(String error);

  /// No description provided for @merchantRefreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Performance data updated • Views: {views} • Calls: {calls} • Navs: {navs}'**
  String merchantRefreshSuccess(int views, int calls, int navs);

  /// No description provided for @merchantRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update performance data: {error}'**
  String merchantRefreshFailed(String error);

  /// No description provided for @merchantBackfillPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Account not properly linked as merchant. Re-enter invite code.'**
  String get merchantBackfillPermissionDenied;

  /// No description provided for @merchantBackfillMissingIndex.
  ///
  /// In en, this message translates to:
  /// **'Missing Firestore analytics index. Deploy firestore:indexes.'**
  String get merchantBackfillMissingIndex;

  /// No description provided for @merchantBackfillNoVenue.
  ///
  /// In en, this message translates to:
  /// **'No venue linked to this account. Link venue first then retry.'**
  String get merchantBackfillNoVenue;

  /// No description provided for @merchantBackfillUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again before refreshing.'**
  String get merchantBackfillUnauthenticated;

  /// No description provided for @merchantBackfillDefaultError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update performance data: {message}'**
  String merchantBackfillDefaultError(String message);

  /// No description provided for @merchantQuickActionScan.
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get merchantQuickActionScan;

  /// No description provided for @merchantQuickActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Info'**
  String get merchantQuickActionEdit;

  /// No description provided for @merchantQuickActionOffers.
  ///
  /// In en, this message translates to:
  /// **'Manage Offers'**
  String get merchantQuickActionOffers;

  /// No description provided for @merchantQuickActionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Venue Photos'**
  String get merchantQuickActionPhotos;

  /// No description provided for @merchantQuickActionReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get merchantQuickActionReviews;

  /// No description provided for @merchantQuickActionMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get merchantQuickActionMenu;

  /// No description provided for @merchantQuickActionHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get merchantQuickActionHours;

  /// No description provided for @merchantQuickActionStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get merchantQuickActionStories;

  /// No description provided for @merchantDays7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get merchantDays7;

  /// No description provided for @merchantDays30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get merchantDays30;

  /// No description provided for @merchantPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Venue Photos 📸'**
  String get merchantPhotosTitle;

  /// No description provided for @merchantPhotosEmpty.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get merchantPhotosEmpty;

  /// No description provided for @merchantPhotosAddPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add photos so customers can see your venue!'**
  String get merchantPhotosAddPrompt;

  /// No description provided for @merchantPhotosAddBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get merchantPhotosAddBtn;

  /// No description provided for @merchantPhotosUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get merchantPhotosUploading;

  /// No description provided for @merchantPhotosUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Uploaded {count} photos'**
  String merchantPhotosUploadSuccess(int count);

  /// No description provided for @merchantPhotosUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Upload failed: {error}'**
  String merchantPhotosUploadFailed(String error);

  /// No description provided for @merchantPhotosDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get merchantPhotosDeleteTitle;

  /// No description provided for @merchantPhotosDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this photo?'**
  String get merchantPhotosDeleteConfirm;

  /// No description provided for @merchantPhotosNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get merchantPhotosNo;

  /// No description provided for @merchantPhotosYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get merchantPhotosYes;

  /// No description provided for @merchantPhotosSetCover.
  ///
  /// In en, this message translates to:
  /// **'Set as cover'**
  String get merchantPhotosSetCover;

  /// No description provided for @merchantPhotosDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get merchantPhotosDelete;

  /// No description provided for @merchantPhotosCoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get merchantPhotosCoverLabel;

  /// No description provided for @merchantPhotosCoverSet.
  ///
  /// In en, this message translates to:
  /// **'✅ Photo set as cover'**
  String get merchantPhotosCoverSet;

  /// No description provided for @merchantPhotosNoVenue.
  ///
  /// In en, this message translates to:
  /// **'No venue linked'**
  String get merchantPhotosNoVenue;

  /// No description provided for @merchantPhotosErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String merchantPhotosErrorGeneric(String error);

  /// No description provided for @merchantReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews 💬'**
  String get merchantReviewsTitle;

  /// No description provided for @merchantReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get merchantReviewsEmpty;

  /// No description provided for @merchantReviewsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get merchantReviewsFilterAll;

  /// No description provided for @merchantReviewsFilterNoReply.
  ///
  /// In en, this message translates to:
  /// **'No reply'**
  String get merchantReviewsFilterNoReply;

  /// No description provided for @merchantReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String merchantReviewsCount(int count);

  /// No description provided for @merchantReviewsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No reviews matching this filter'**
  String get merchantReviewsNoResults;

  /// No description provided for @merchantReviewsReplySent.
  ///
  /// In en, this message translates to:
  /// **'✅ Reply sent'**
  String get merchantReviewsReplySent;

  /// No description provided for @merchantReviewsReplyDeleted.
  ///
  /// In en, this message translates to:
  /// **'🗑️ Reply deleted'**
  String get merchantReviewsReplyDeleted;

  /// No description provided for @merchantReviewsDeleteReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete reply'**
  String get merchantReviewsDeleteReplyTitle;

  /// No description provided for @merchantReviewsDeleteReplyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your reply?'**
  String get merchantReviewsDeleteReplyConfirm;

  /// No description provided for @merchantReviewsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get merchantReviewsCancel;

  /// No description provided for @merchantReviewsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get merchantReviewsDelete;

  /// No description provided for @merchantReviewsOwnerReply.
  ///
  /// In en, this message translates to:
  /// **'Owner reply'**
  String get merchantReviewsOwnerReply;

  /// No description provided for @merchantReviewsReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reply...'**
  String get merchantReviewsReplyHint;

  /// No description provided for @merchantReviewsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get merchantReviewsEdit;

  /// No description provided for @merchantReviewsDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete reply'**
  String get merchantReviewsDeleteTooltip;

  /// No description provided for @merchantReviewsAddReply.
  ///
  /// In en, this message translates to:
  /// **'Add reply'**
  String get merchantReviewsAddReply;

  /// No description provided for @merchantReviewsDefaultUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get merchantReviewsDefaultUser;

  /// No description provided for @merchantReviewsDefaultInitial.
  ///
  /// In en, this message translates to:
  /// **'?'**
  String get merchantReviewsDefaultInitial;

  /// No description provided for @merchantReviewsErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String merchantReviewsErrorGeneric(String error);

  /// No description provided for @merchantStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories 📖'**
  String get merchantStoriesTitle;

  /// No description provided for @merchantStoriesNewStory.
  ///
  /// In en, this message translates to:
  /// **'New Story'**
  String get merchantStoriesNewStory;

  /// No description provided for @merchantStoriesError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get merchantStoriesError;

  /// No description provided for @merchantStoriesNoVenue.
  ///
  /// In en, this message translates to:
  /// **'No venue linked'**
  String get merchantStoriesNoVenue;

  /// No description provided for @merchantStoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stories yet'**
  String get merchantStoriesEmpty;

  /// No description provided for @merchantStoriesEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Post a story so your customers can see it!'**
  String get merchantStoriesEmptyPrompt;

  /// No description provided for @merchantStoriesVideo.
  ///
  /// In en, this message translates to:
  /// **'🎬 Video'**
  String get merchantStoriesVideo;

  /// No description provided for @merchantStoriesPromoted.
  ///
  /// In en, this message translates to:
  /// **'Promoted'**
  String get merchantStoriesPromoted;

  /// No description provided for @merchantStoriesExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get merchantStoriesExpired;

  /// No description provided for @merchantStoriesActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get merchantStoriesActive;

  /// No description provided for @merchantStoriesExtendPromo.
  ///
  /// In en, this message translates to:
  /// **'Extend promotion'**
  String get merchantStoriesExtendPromo;

  /// No description provided for @merchantStoriesPromote.
  ///
  /// In en, this message translates to:
  /// **'Promote 🚀'**
  String get merchantStoriesPromote;

  /// No description provided for @merchantStoriesDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get merchantStoriesDeleteTooltip;

  /// No description provided for @merchantStoriesPromoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote Story 🚀'**
  String get merchantStoriesPromoteTitle;

  /// No description provided for @merchantStoriesPromoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Your story will appear on the home page for all users!'**
  String get merchantStoriesPromoteDesc;

  /// No description provided for @merchantStoriesChooseDuration.
  ///
  /// In en, this message translates to:
  /// **'Choose duration:'**
  String get merchantStoriesChooseDuration;

  /// No description provided for @merchantStoriesCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get merchantStoriesCancel;

  /// No description provided for @merchantStoriesPromoteSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Story promoted successfully!'**
  String get merchantStoriesPromoteSuccess;

  /// No description provided for @merchantStoriesPromoteError.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String merchantStoriesPromoteError(String error);

  /// No description provided for @merchantStoriesUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'❌ Unexpected error occurred'**
  String get merchantStoriesUnexpectedError;

  /// No description provided for @merchantStoriesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Story'**
  String get merchantStoriesDeleteTitle;

  /// No description provided for @merchantStoriesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get merchantStoriesDeleteConfirm;

  /// No description provided for @merchantStoriesNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get merchantStoriesNo;

  /// No description provided for @merchantStoriesYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get merchantStoriesYes;

  /// No description provided for @merchantStoriesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Story deleted'**
  String get merchantStoriesDeleted;

  /// No description provided for @merchantStoriesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete story: {error}'**
  String merchantStoriesDeleteFailed(String error);

  /// No description provided for @merchantStoriesPromote1.
  ///
  /// In en, this message translates to:
  /// **'1 Day (\$1)'**
  String get merchantStoriesPromote1;

  /// No description provided for @merchantStoriesPromote3.
  ///
  /// In en, this message translates to:
  /// **'3 Days (\$2.5)'**
  String get merchantStoriesPromote3;

  /// No description provided for @merchantStoriesPromote7.
  ///
  /// In en, this message translates to:
  /// **'1 Week (\$5)'**
  String get merchantStoriesPromote7;

  /// No description provided for @storiesBarTitle.
  ///
  /// In en, this message translates to:
  /// **'📢 Venue Stories'**
  String get storiesBarTitle;

  /// No description provided for @storiesBarDefaultVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get storiesBarDefaultVenue;

  /// No description provided for @storiesFeaturedBadge.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get storiesFeaturedBadge;

  /// No description provided for @storiesFeaturedError.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Error loading featured: {error}'**
  String storiesFeaturedError(String error);

  /// No description provided for @storyViewerVisitVenue.
  ///
  /// In en, this message translates to:
  /// **'Visit {venue}'**
  String storyViewerVisitVenue(String venue);

  /// No description provided for @storyViewerLoadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get storyViewerLoadingVideo;

  /// No description provided for @storyViewerSpecialOffer.
  ///
  /// In en, this message translates to:
  /// **'Special Offer!'**
  String get storyViewerSpecialOffer;

  /// No description provided for @storyViewerOpenAppToActivate.
  ///
  /// In en, this message translates to:
  /// **'Open App to Activate'**
  String get storyViewerOpenAppToActivate;

  /// No description provided for @storyViewerMinsAgo.
  ///
  /// In en, this message translates to:
  /// **'{mins}m ago'**
  String storyViewerMinsAgo(num mins);

  /// No description provided for @storyViewerHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String storyViewerHoursAgo(num hours);

  /// No description provided for @storyViewerYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get storyViewerYesterday;

  /// No description provided for @merchantStoriesAddContent.
  ///
  /// In en, this message translates to:
  /// **'Add text, image, or video at minimum'**
  String get merchantStoriesAddContent;

  /// No description provided for @merchantStoriesPublished.
  ///
  /// In en, this message translates to:
  /// **'✅ Story published'**
  String get merchantStoriesPublished;

  /// No description provided for @merchantStoriesPublishError.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String merchantStoriesPublishError(String error);

  /// No description provided for @merchantStoriesNewStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New Story 📖'**
  String get merchantStoriesNewStoryTitle;

  /// No description provided for @merchantStoriesPhoto.
  ///
  /// In en, this message translates to:
  /// **'📷 Photo'**
  String get merchantStoriesPhoto;

  /// No description provided for @merchantStoriesVideoSelected.
  ///
  /// In en, this message translates to:
  /// **'✅ Video selected'**
  String get merchantStoriesVideoSelected;

  /// No description provided for @merchantStoriesVideoLimit.
  ///
  /// In en, this message translates to:
  /// **'(Max 30 seconds)'**
  String get merchantStoriesVideoLimit;

  /// No description provided for @merchantStoriesTextHint.
  ///
  /// In en, this message translates to:
  /// **'Write your story text...'**
  String get merchantStoriesTextHint;

  /// No description provided for @merchantStoriesDuration.
  ///
  /// In en, this message translates to:
  /// **'Story duration:'**
  String get merchantStoriesDuration;

  /// No description provided for @merchantStories24h.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get merchantStories24h;

  /// No description provided for @merchantStories48h.
  ///
  /// In en, this message translates to:
  /// **'48 hours'**
  String get merchantStories48h;

  /// No description provided for @merchantStoriesPublishBtn.
  ///
  /// In en, this message translates to:
  /// **'Publish Story'**
  String get merchantStoriesPublishBtn;

  /// No description provided for @savedOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Offers'**
  String get savedOffersTitle;

  /// No description provided for @offerEndingSoon.
  ///
  /// In en, this message translates to:
  /// **'Ending soon'**
  String get offerEndingSoon;

  /// No description provided for @offerQrDiscountCode.
  ///
  /// In en, this message translates to:
  /// **'Discount Code'**
  String get offerQrDiscountCode;

  /// No description provided for @offerQrCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired'**
  String get offerQrCodeExpired;

  /// No description provided for @offerQrValidFor.
  ///
  /// In en, this message translates to:
  /// **'Valid for'**
  String get offerQrValidFor;

  /// No description provided for @offerQrRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Offer redeemed'**
  String get offerQrRedeemed;

  /// No description provided for @offerQrPeriodExpired.
  ///
  /// In en, this message translates to:
  /// **'Validity period expired'**
  String get offerQrPeriodExpired;

  /// No description provided for @offerQrShowToCashier.
  ///
  /// In en, this message translates to:
  /// **'Show this code to the cashier'**
  String get offerQrShowToCashier;

  /// No description provided for @offerDetailsRequestFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit request'**
  String get offerDetailsRequestFail;

  /// No description provided for @offerDetailsRequestFailFallback.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit request'**
  String get offerDetailsRequestFailFallback;

  /// No description provided for @offerDetailsUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get offerDetailsUnexpectedError;

  /// No description provided for @offerDetailsAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This offer has already been used or is unavailable'**
  String get offerDetailsAlreadyUsed;

  /// No description provided for @offerDetailsLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Usage limit exceeded, try again later'**
  String get offerDetailsLimitExceeded;

  /// No description provided for @offerDetailsNoInternet.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection'**
  String get offerDetailsNoInternet;

  /// No description provided for @offerDetailsLoadFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to load offer'**
  String get offerDetailsLoadFail;

  /// No description provided for @offerDetailsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Offer not found'**
  String get offerDetailsNotFound;

  /// No description provided for @offerDetailsVenueLoadFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to load venue data'**
  String get offerDetailsVenueLoadFail;

  /// No description provided for @offerDetailsVenueNotFound.
  ///
  /// In en, this message translates to:
  /// **'Venue not found'**
  String get offerDetailsVenueNotFound;

  /// No description provided for @offerDetailsSaveRemoved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get offerDetailsSaveRemoved;

  /// No description provided for @offerDetailsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get offerDetailsSaved;

  /// No description provided for @offerDetailsExclusive.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Partner Offer'**
  String get offerDetailsExclusive;

  /// No description provided for @offerDetailsValidity.
  ///
  /// In en, this message translates to:
  /// **'Validity'**
  String get offerDetailsValidity;

  /// No description provided for @offerDetailsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get offerDetailsTerms;

  /// No description provided for @myClaimsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Offers'**
  String get myClaimsTitle;

  /// No description provided for @myClaimsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved offers yet'**
  String get myClaimsEmptyTitle;

  /// No description provided for @myClaimsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Explore places and get exclusive discounts!'**
  String get myClaimsEmptyDesc;

  /// No description provided for @myClaimsExploreBtn.
  ///
  /// In en, this message translates to:
  /// **'Explore Map'**
  String get myClaimsExploreBtn;

  /// No description provided for @myClaimsStatusUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get myClaimsStatusUsed;

  /// No description provided for @myClaimsStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get myClaimsStatusCancelled;

  /// No description provided for @myClaimsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get myClaimsStatusActive;

  /// No description provided for @offerDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}% Discount'**
  String offerDiscountPercent(String value);

  /// No description provided for @offerDiscountCurrency.
  ///
  /// In en, this message translates to:
  /// **'{value} {currency} Discount'**
  String offerDiscountCurrency(String value, String currency);

  /// No description provided for @offerDiscountFree.
  ///
  /// In en, this message translates to:
  /// **'Free Offer'**
  String get offerDiscountFree;

  /// No description provided for @offerValidityAlways.
  ///
  /// In en, this message translates to:
  /// **'Always Available'**
  String get offerValidityAlways;

  /// No description provided for @offerValidityExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get offerValidityExpired;

  /// No description provided for @offerValidityDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String offerValidityDays(int days);

  /// No description provided for @offerValidityHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours left'**
  String offerValidityHours(int hours);

  /// No description provided for @offerValiditySoon.
  ///
  /// In en, this message translates to:
  /// **'Ending soon'**
  String get offerValiditySoon;

  /// No description provided for @offerErrorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save request'**
  String get offerErrorSaveFailed;

  /// No description provided for @offerErrorAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'You have already used this offer'**
  String get offerErrorAlreadyUsed;

  /// No description provided for @merchantOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Offers 🎁'**
  String get merchantOffersTitle;

  /// No description provided for @merchantOffersNewOffer.
  ///
  /// In en, this message translates to:
  /// **'New Offer'**
  String get merchantOffersNewOffer;

  /// No description provided for @merchantOffersErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String merchantOffersErrorLoad(String error);

  /// No description provided for @merchantOffersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No offers yet'**
  String get merchantOffersEmpty;

  /// No description provided for @merchantOffersEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create your first offer!'**
  String get merchantOffersEmptyPrompt;

  /// No description provided for @merchantOffersDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get merchantOffersDefaultTitle;

  /// No description provided for @merchantOffersEndingSoon.
  ///
  /// In en, this message translates to:
  /// **'Ending soon'**
  String get merchantOffersEndingSoon;

  /// No description provided for @merchantOffersEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get merchantOffersEdit;

  /// No description provided for @merchantOffersDeleteMenu.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get merchantOffersDeleteMenu;

  /// No description provided for @merchantOffersActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get merchantOffersActive;

  /// No description provided for @merchantOffersPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get merchantOffersPaused;

  /// No description provided for @merchantOffersExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get merchantOffersExpired;

  /// No description provided for @merchantOffersNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date set'**
  String get merchantOffersNoDate;

  /// No description provided for @merchantOffersClaims.
  ///
  /// In en, this message translates to:
  /// **'{count} interested'**
  String merchantOffersClaims(int count);

  /// No description provided for @merchantOffersRedeemed.
  ///
  /// In en, this message translates to:
  /// **'{count} redeemed'**
  String merchantOffersRedeemed(int count);

  /// No description provided for @merchantOffersConversion.
  ///
  /// In en, this message translates to:
  /// **'{rate}% conversion'**
  String merchantOffersConversion(String rate);

  /// No description provided for @merchantOffersDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Offer'**
  String get merchantOffersDeleteTitle;

  /// No description provided for @merchantOffersDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this offer?'**
  String get merchantOffersDeleteConfirm;

  /// No description provided for @merchantOffersNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get merchantOffersNo;

  /// No description provided for @merchantOffersYesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete'**
  String get merchantOffersYesDelete;

  /// No description provided for @merchantOffersDiscountAmount.
  ///
  /// In en, this message translates to:
  /// **'{value} ₪ off'**
  String merchantOffersDiscountAmount(String value);

  /// No description provided for @merchantOffersDiscountFree.
  ///
  /// In en, this message translates to:
  /// **'Free offer'**
  String get merchantOffersDiscountFree;

  /// No description provided for @merchantOffersDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}% off'**
  String merchantOffersDiscountPercent(String value);

  /// No description provided for @merchantOffersPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer Preview'**
  String get merchantOffersPreviewTitle;

  /// No description provided for @merchantOffersPreviewClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get merchantOffersPreviewClose;

  /// No description provided for @merchantOffersPreviewPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish Offer ✅'**
  String get merchantOffersPreviewPublish;

  /// No description provided for @merchantOffersEditUpdated.
  ///
  /// In en, this message translates to:
  /// **'✅ Offer updated'**
  String get merchantOffersEditUpdated;

  /// No description provided for @merchantOffersCreated.
  ///
  /// In en, this message translates to:
  /// **'✅ Offer created'**
  String get merchantOffersCreated;

  /// No description provided for @merchantOffersSubmitError.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String merchantOffersSubmitError(String error);

  /// No description provided for @merchantOffersFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Offer'**
  String get merchantOffersFormEditTitle;

  /// No description provided for @merchantOffersFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Offer 🎁'**
  String get merchantOffersFormNewTitle;

  /// No description provided for @merchantOffersFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get merchantOffersFieldRequired;

  /// No description provided for @merchantOffersFieldOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer title'**
  String get merchantOffersFieldOfferTitle;

  /// No description provided for @merchantOffersFieldOfferTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Example: 20% off all orders'**
  String get merchantOffersFieldOfferTitleHint;

  /// No description provided for @merchantOffersFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Offer description'**
  String get merchantOffersFieldDescription;

  /// No description provided for @merchantOffersFieldDescHint.
  ///
  /// In en, this message translates to:
  /// **'Offer details...'**
  String get merchantOffersFieldDescHint;

  /// No description provided for @merchantOffersFieldDiscountType.
  ///
  /// In en, this message translates to:
  /// **'Discount type'**
  String get merchantOffersFieldDiscountType;

  /// No description provided for @merchantOffersTypePercent.
  ///
  /// In en, this message translates to:
  /// **'Percent %'**
  String get merchantOffersTypePercent;

  /// No description provided for @merchantOffersTypeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount ₪'**
  String get merchantOffersTypeAmount;

  /// No description provided for @merchantOffersTypeFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get merchantOffersTypeFree;

  /// No description provided for @merchantOffersFieldValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get merchantOffersFieldValue;

  /// No description provided for @merchantOffersDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'📅 Offer duration'**
  String get merchantOffersDurationLabel;

  /// No description provided for @merchantOffersStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get merchantOffersStartDate;

  /// No description provided for @merchantOffersEndDate.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get merchantOffersEndDate;

  /// No description provided for @merchantOffersFieldTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms (optional)'**
  String get merchantOffersFieldTerms;

  /// No description provided for @merchantOffersFieldTermsHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Offer excludes delivery'**
  String get merchantOffersFieldTermsHint;

  /// No description provided for @merchantOffersPreviewBtn.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get merchantOffersPreviewBtn;

  /// No description provided for @merchantOffersSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get merchantOffersSaveChanges;

  /// No description provided for @merchantOffersPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish offer'**
  String get merchantOffersPublish;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to enjoy all WAIN features'**
  String get loginSubtitle;

  /// No description provided for @loginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginGoogle;

  /// No description provided for @loginOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get loginOr;

  /// No description provided for @loginPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get loginPhoneLabel;

  /// No description provided for @loginSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send verification code'**
  String get loginSendOtp;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordHint;

  /// No description provided for @loginEmailBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginEmailBtn;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?  '**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get loginCreateAccount;

  /// No description provided for @loginUsePhone.
  ///
  /// In en, this message translates to:
  /// **'Use phone number'**
  String get loginUsePhone;

  /// No description provided for @loginUseEmail.
  ///
  /// In en, this message translates to:
  /// **'Use email'**
  String get loginUseEmail;

  /// No description provided for @loginContinueGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get loginContinueGuest;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get loginWelcome;

  /// No description provided for @loginWelcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}!'**
  String loginWelcomeUser(String name);

  /// No description provided for @loginGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed, please try again'**
  String get loginGoogleFailed;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Sign-in error: {error}'**
  String loginErrorGeneric(String error);

  /// No description provided for @loginErrorPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get loginErrorPhone;

  /// No description provided for @loginErrorEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter email and password'**
  String get loginErrorEmailPassword;

  /// No description provided for @loginErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email'**
  String get loginErrorUserNotFound;

  /// No description provided for @loginErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get loginErrorWrongPassword;

  /// No description provided for @loginErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get loginErrorInvalidCredential;

  /// No description provided for @loginErrorDefault.
  ///
  /// In en, this message translates to:
  /// **'An error occurred, please try again'**
  String get loginErrorDefault;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account and enjoy WAIN app features'**
  String get signupSubtitle;

  /// No description provided for @signupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get signupNameLabel;

  /// No description provided for @signupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get signupNameHint;

  /// No description provided for @signupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get signupNameRequired;

  /// No description provided for @signupEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signupEmailLabel;

  /// No description provided for @signupEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get signupEmailRequired;

  /// No description provided for @signupEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get signupEmailInvalid;

  /// No description provided for @signupPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupPasswordLabel;

  /// No description provided for @signupPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get signupPasswordRequired;

  /// No description provided for @signupPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get signupPasswordWeak;

  /// No description provided for @signupConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signupConfirmLabel;

  /// No description provided for @signupConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get signupConfirmRequired;

  /// No description provided for @signupConfirmMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signupConfirmMismatch;

  /// No description provided for @signupBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupBtn;

  /// No description provided for @signupHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?  '**
  String get signupHaveAccount;

  /// No description provided for @signupLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signupLogin;

  /// No description provided for @signupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! 🎉'**
  String get signupSuccess;

  /// No description provided for @signupErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get signupErrorEmailInUse;

  /// No description provided for @signupErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get signupErrorWeakPassword;

  /// No description provided for @signupErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get signupErrorInvalidEmail;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to\n'**
  String get otpSentTo;

  /// No description provided for @otpVerifyBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerifyBtn;

  /// No description provided for @otpNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?  '**
  String get otpNotReceived;

  /// No description provided for @otpResendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend ({seconds})'**
  String otpResendCountdown(int seconds);

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get otpResend;

  /// No description provided for @otpChangePhone.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get otpChangePhone;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit verification code'**
  String get otpInvalid;

  /// No description provided for @otpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully!'**
  String get otpSuccess;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'Verification code resent'**
  String get otpResent;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Join as Merchant'**
  String get inviteTitle;

  /// No description provided for @inviteEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter invite code'**
  String get inviteEnterCode;

  /// No description provided for @inviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If you own a business, enter the code you received\nto manage your venue from the app'**
  String get inviteSubtitle;

  /// No description provided for @inviteCodeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the invite code'**
  String get inviteCodeEmpty;

  /// No description provided for @inviteVerifyBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get inviteVerifyBtn;

  /// No description provided for @inviteHelpText.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have a code? Contact the WAIN team to register as a merchant.'**
  String get inviteHelpText;

  /// No description provided for @editVenueTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Venue Info'**
  String get editVenueTitle;

  /// No description provided for @editVenueError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String editVenueError(String error);

  /// No description provided for @editVenueNoVenue.
  ///
  /// In en, this message translates to:
  /// **'No venue linked'**
  String get editVenueNoVenue;

  /// No description provided for @editVenueNameAr.
  ///
  /// In en, this message translates to:
  /// **'Venue name (Arabic)'**
  String get editVenueNameAr;

  /// No description provided for @editVenueNameEn.
  ///
  /// In en, this message translates to:
  /// **'Venue name (English)'**
  String get editVenueNameEn;

  /// No description provided for @editVenuePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get editVenuePhone;

  /// No description provided for @editVenueCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get editVenueCity;

  /// No description provided for @editVenueRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get editVenueRequired;

  /// No description provided for @editVenueEditHours.
  ///
  /// In en, this message translates to:
  /// **'Edit working hours'**
  String get editVenueEditHours;

  /// No description provided for @editVenueSaveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editVenueSaveBtn;

  /// No description provided for @editVenueSaved.
  ///
  /// In en, this message translates to:
  /// **'✅ Changes saved'**
  String get editVenueSaved;

  /// No description provided for @editVenueSaveError.
  ///
  /// In en, this message translates to:
  /// **'❌ Save failed: {error}'**
  String editVenueSaveError(String error);

  /// No description provided for @hours24hToggle.
  ///
  /// In en, this message translates to:
  /// **'Open 24 hours'**
  String get hours24hToggle;

  /// No description provided for @hours24hSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Venue will always show as \"Open\"'**
  String get hours24hSubtitle;

  /// No description provided for @hoursScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Set working hours for each day:'**
  String get hoursScheduleHint;

  /// No description provided for @hoursSaveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get hoursSaveBtn;

  /// No description provided for @hoursSaved.
  ///
  /// In en, this message translates to:
  /// **'✅ Working hours saved'**
  String get hoursSaved;

  /// No description provided for @hoursSaveError.
  ///
  /// In en, this message translates to:
  /// **'❌ Save failed: {error}'**
  String hoursSaveError(String error);

  /// No description provided for @hoursCopyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy to all days'**
  String get hoursCopyAll;

  /// No description provided for @hoursAddShift.
  ///
  /// In en, this message translates to:
  /// **'Add shift'**
  String get hoursAddShift;

  /// No description provided for @hoursClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get hoursClosed;

  /// No description provided for @hoursCopiedAll.
  ///
  /// In en, this message translates to:
  /// **'Hours copied to all days'**
  String get hoursCopiedAll;

  /// No description provided for @hoursMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get hoursMonday;

  /// No description provided for @hoursTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get hoursTuesday;

  /// No description provided for @hoursWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get hoursWednesday;

  /// No description provided for @hoursThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get hoursThursday;

  /// No description provided for @hoursFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get hoursFriday;

  /// No description provided for @hoursSaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get hoursSaturday;

  /// No description provided for @hoursSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get hoursSunday;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'QR Scanner (Merchants)'**
  String get scanTitle;

  /// No description provided for @scanRedeemSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Offer redeemed successfully!'**
  String get scanRedeemSuccess;

  /// No description provided for @scanRedeemError.
  ///
  /// In en, this message translates to:
  /// **'❌ Error during redemption'**
  String get scanRedeemError;

  /// No description provided for @scanValidOffer.
  ///
  /// In en, this message translates to:
  /// **'Valid Offer'**
  String get scanValidOffer;

  /// No description provided for @scanInvalidOffer.
  ///
  /// In en, this message translates to:
  /// **'Invalid Offer'**
  String get scanInvalidOffer;

  /// No description provided for @scanUnnamedOffer.
  ///
  /// In en, this message translates to:
  /// **'Unnamed offer'**
  String get scanUnnamedOffer;

  /// No description provided for @scanUnknownVenue.
  ///
  /// In en, this message translates to:
  /// **'Unknown venue'**
  String get scanUnknownVenue;

  /// No description provided for @scanReasonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String scanReasonPrefix(String reason);

  /// No description provided for @scanRedeemBtn.
  ///
  /// In en, this message translates to:
  /// **'Redeem Offer'**
  String get scanRedeemBtn;

  /// No description provided for @scanMerchantRequired.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in as a merchant to redeem offers'**
  String get scanMerchantRequired;

  /// No description provided for @scanCancelRescan.
  ///
  /// In en, this message translates to:
  /// **'Cancel / Scan again'**
  String get scanCancelRescan;

  /// No description provided for @menuSectionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get menuSectionOther;

  /// No description provided for @menuErrorNotMerchant.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in as merchant.'**
  String get menuErrorNotMerchant;

  /// No description provided for @menuDraftPublished.
  ///
  /// In en, this message translates to:
  /// **'Draft published successfully'**
  String get menuDraftPublished;

  /// No description provided for @menuDraftPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish draft: {error}'**
  String menuDraftPublishFailed(String error);

  /// No description provided for @menuNoArchivedVersions.
  ///
  /// In en, this message translates to:
  /// **'No archived versions available'**
  String get menuNoArchivedVersions;

  /// No description provided for @menuSelectArchivedVersion.
  ///
  /// In en, this message translates to:
  /// **'Select archived version'**
  String get menuSelectArchivedVersion;

  /// No description provided for @menuRollbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Rollback completed successfully'**
  String get menuRollbackSuccess;

  /// No description provided for @menuRollbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Rollback failed: {error}'**
  String menuRollbackFailed(String error);

  /// No description provided for @menuNoEditableSections.
  ///
  /// In en, this message translates to:
  /// **'No editable sections in this draft yet.'**
  String get menuNoEditableSections;

  /// No description provided for @menuManageSections.
  ///
  /// In en, this message translates to:
  /// **'Manage Sections'**
  String get menuManageSections;

  /// No description provided for @menuAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get menuAdd;

  /// No description provided for @menuReorderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reorder: {error}'**
  String menuReorderFailed(String error);

  /// No description provided for @menuRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get menuRename;

  /// No description provided for @menuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get menuDelete;

  /// No description provided for @menuSectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Section name'**
  String get menuSectionNameHint;

  /// No description provided for @menuCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get menuCancel;

  /// No description provided for @menuSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get menuSave;

  /// No description provided for @menuAddSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get menuAddSectionTitle;

  /// No description provided for @menuSectionAdded.
  ///
  /// In en, this message translates to:
  /// **'Section added'**
  String get menuSectionAdded;

  /// No description provided for @menuSectionAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add section: {error}'**
  String menuSectionAddFailed(String error);

  /// No description provided for @menuRenameSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Section'**
  String get menuRenameSectionTitle;

  /// No description provided for @menuSectionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Section updated'**
  String get menuSectionUpdated;

  /// No description provided for @menuSectionUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update section: {error}'**
  String menuSectionUpdateFailed(String error);

  /// No description provided for @menuKeepOneSection.
  ///
  /// In en, this message translates to:
  /// **'Must keep at least one section.'**
  String get menuKeepOneSection;

  /// No description provided for @menuDeleteSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Section'**
  String get menuDeleteSectionTitle;

  /// No description provided for @menuDeleteSectionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Section \"{sectionName}\" will be deleted.'**
  String menuDeleteSectionConfirm(String sectionName);

  /// No description provided for @menuMoveItemsTo.
  ///
  /// In en, this message translates to:
  /// **'Move items to:'**
  String get menuMoveItemsTo;

  /// No description provided for @menuSectionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Section deleted successfully'**
  String get menuSectionDeleted;

  /// No description provided for @menuSectionDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete section: {error}'**
  String menuSectionDeleteFailed(String error);

  /// No description provided for @menuManageMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Menu'**
  String get menuManageMenuTitle;

  /// No description provided for @menuManageCategoriesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get menuManageCategoriesTooltip;

  /// No description provided for @menuPublishDraftTooltip.
  ///
  /// In en, this message translates to:
  /// **'Publish draft'**
  String get menuPublishDraftTooltip;

  /// No description provided for @menuRollbackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rollback to archived version'**
  String get menuRollbackTooltip;

  /// No description provided for @menuError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String menuError(String error);

  /// No description provided for @menuNoVenueLinked.
  ///
  /// In en, this message translates to:
  /// **'No merchant venue is linked to this account'**
  String get menuNoVenueLinked;

  /// No description provided for @menuDraftPrepareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to prepare draft: {error}'**
  String menuDraftPrepareFailed(String error);

  /// No description provided for @menuDraftPublishedCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Last draft was published. Create a new draft to continue editing.'**
  String get menuDraftPublishedCreateNew;

  /// No description provided for @menuCreateNewDraftBtn.
  ///
  /// In en, this message translates to:
  /// **'Create new draft'**
  String get menuCreateNewDraftBtn;

  /// No description provided for @menuSectionsError.
  ///
  /// In en, this message translates to:
  /// **'Menu sections error: {error}'**
  String menuSectionsError(String error);

  /// No description provided for @menuNoSectionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No menu sections available'**
  String get menuNoSectionsAvailable;

  /// No description provided for @menuEditingUnpublishedDraft.
  ///
  /// In en, this message translates to:
  /// **'Editing new unpublished draft'**
  String get menuEditingUnpublishedDraft;

  /// No description provided for @menuEditingDraftOverActive.
  ///
  /// In en, this message translates to:
  /// **'Editing draft over active version: {versionId}'**
  String menuEditingDraftOverActive(String versionId);

  /// No description provided for @menuManageSectionsBtn.
  ///
  /// In en, this message translates to:
  /// **'Manage Sections'**
  String get menuManageSectionsBtn;

  /// No description provided for @menuAddSectionBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get menuAddSectionBtn;

  /// No description provided for @menuEmptyAddFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Menu is currently empty. Add your first item via the + button'**
  String get menuEmptyAddFirstItem;

  /// No description provided for @menuNoItemsInSection.
  ///
  /// In en, this message translates to:
  /// **'No items in section {sectionName}'**
  String menuNoItemsInSection(String sectionName);

  /// No description provided for @menuReorderItemsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reorder items: {error}'**
  String menuReorderItemsFailed(String error);

  /// No description provided for @menuSaveItemFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save item: {error}'**
  String menuSaveItemFailed(String error);

  /// No description provided for @menuAddItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get menuAddItemTitle;

  /// No description provided for @menuEditItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get menuEditItemTitle;

  /// No description provided for @menuItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get menuItemNameLabel;

  /// No description provided for @menuItemDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get menuItemDescLabel;

  /// No description provided for @menuItemPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get menuItemPriceLabel;

  /// No description provided for @menuItemAvailableToggle.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get menuItemAvailableToggle;

  /// No description provided for @menuItemFeaturedToggle.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get menuItemFeaturedToggle;

  /// No description provided for @menuItemChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get menuItemChooseImage;

  /// No description provided for @menuItemImageSelected.
  ///
  /// In en, this message translates to:
  /// **'Image selected'**
  String get menuItemImageSelected;

  /// No description provided for @brandGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get brandGoogleMaps;

  /// No description provided for @brandWaze.
  ///
  /// In en, this message translates to:
  /// **'Waze'**
  String get brandWaze;

  /// No description provided for @brandAiBadge.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get brandAiBadge;

  /// No description provided for @hoursLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading hours: {error}'**
  String hoursLoadError(String error);

  /// No description provided for @scanUnknownReason.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get scanUnknownReason;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'WAIN-XXXXXX'**
  String get inviteCodeHint;

  /// No description provided for @loginPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+970599123456'**
  String get loginPhoneHint;

  /// No description provided for @signupEmailHint.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get signupEmailHint;

  /// No description provided for @signupPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'????????'**
  String get signupPasswordPlaceholder;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
