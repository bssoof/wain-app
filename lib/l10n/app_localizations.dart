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

  /// No description provided for @menuViewFull.
  ///
  /// In en, this message translates to:
  /// **'View full menu'**
  String get menuViewFull;

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

  /// No description provided for @venueOffersAllTitle.
  ///
  /// In en, this message translates to:
  /// **'All offers'**
  String get venueOffersAllTitle;

  /// No description provided for @venueOffersAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get venueOffersAvailableNow;

  /// No description provided for @venueOffersPreviouslyUsed.
  ///
  /// In en, this message translates to:
  /// **'Previously used'**
  String get venueOffersPreviouslyUsed;

  /// No description provided for @venueOffersViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all offers ({count})'**
  String venueOffersViewAll(int count);

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

  /// No description provided for @offlineBannerCachedCopy.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — showing the latest saved copy'**
  String get offlineBannerCachedCopy;

  /// No description provided for @offlineBannerUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update data — showing the latest saved copy'**
  String get offlineBannerUpdateFailed;

  /// No description provided for @offlineScreenRequiresConnection.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — this screen needs an internet connection'**
  String get offlineScreenRequiresConnection;

  /// No description provided for @offlineActionRequiresConnection.
  ///
  /// In en, this message translates to:
  /// **'This action needs an internet connection'**
  String get offlineActionRequiresConnection;

  /// No description provided for @offlineEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get offlineEmptyTitle;

  /// No description provided for @offlineEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to view this content'**
  String get offlineEmptySubtitle;

  /// No description provided for @offlineScreenUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This screen does not work offline in the current version.'**
  String get offlineScreenUnavailableSubtitle;

  /// No description provided for @merchantStoriesOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Story management needs an internet connection'**
  String get merchantStoriesOfflineTitle;

  /// No description provided for @merchantMenuOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu management needs an internet connection'**
  String get merchantMenuOfflineTitle;

  /// No description provided for @offlineAgeNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get offlineAgeNow;

  /// No description provided for @offlineAgeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String offlineAgeMinutes(int count);

  /// No description provided for @offlineAgeHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String offlineAgeHours(int count);

  /// No description provided for @offlineAgeDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String offlineAgeDays(int count);

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

  /// No description provided for @tabOffersMenu.
  ///
  /// In en, this message translates to:
  /// **'Offers & Menu'**
  String get tabOffersMenu;

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

  /// No description provided for @merchantAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get merchantAnalyticsTitle;

  /// No description provided for @merchantAnalyticsOpenDetails.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get merchantAnalyticsOpenDetails;

  /// No description provided for @merchantAnalyticsViewsThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Views this period'**
  String get merchantAnalyticsViewsThisPeriod;

  /// No description provided for @merchantAnalyticsContactIntent.
  ///
  /// In en, this message translates to:
  /// **'Contact intent'**
  String get merchantAnalyticsContactIntent;

  /// No description provided for @merchantAnalyticsContactRate.
  ///
  /// In en, this message translates to:
  /// **'Contact rate'**
  String get merchantAnalyticsContactRate;

  /// No description provided for @merchantAnalyticsInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get merchantAnalyticsInsights;

  /// No description provided for @merchantAnalyticsNoInsights.
  ///
  /// In en, this message translates to:
  /// **'No major changes detected yet.'**
  String get merchantAnalyticsNoInsights;

  /// No description provided for @merchantAnalyticsHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Decision highlights'**
  String get merchantAnalyticsHighlightsTitle;

  /// No description provided for @merchantAnalyticsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed analytics'**
  String get merchantAnalyticsDetailTitle;

  /// No description provided for @merchantAnalyticsOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get merchantAnalyticsOverviewTitle;

  /// No description provided for @merchantAnalyticsFunnelTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversion funnel'**
  String get merchantAnalyticsFunnelTitle;

  /// No description provided for @merchantAnalyticsFunnelEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not enough offer activity yet to show a funnel.'**
  String get merchantAnalyticsFunnelEmpty;

  /// No description provided for @merchantAnalyticsDemandTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Demand trends'**
  String get merchantAnalyticsDemandTrendsTitle;

  /// No description provided for @merchantAnalyticsConversionTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversion trends'**
  String get merchantAnalyticsConversionTrendsTitle;

  /// No description provided for @merchantAnalyticsTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get merchantAnalyticsTimelineTitle;

  /// No description provided for @merchantAnalyticsOfferDetailViews.
  ///
  /// In en, this message translates to:
  /// **'Offer detail views'**
  String get merchantAnalyticsOfferDetailViews;

  /// No description provided for @merchantAnalyticsClaimClicks.
  ///
  /// In en, this message translates to:
  /// **'Claim clicks'**
  String get merchantAnalyticsClaimClicks;

  /// No description provided for @merchantAnalyticsClaimsCreated.
  ///
  /// In en, this message translates to:
  /// **'Claims created'**
  String get merchantAnalyticsClaimsCreated;

  /// No description provided for @merchantAnalyticsRedemptions.
  ///
  /// In en, this message translates to:
  /// **'Redemptions'**
  String get merchantAnalyticsRedemptions;

  /// No description provided for @merchantAnalyticsDetailToClickRateShort.
  ///
  /// In en, this message translates to:
  /// **'Detail to click'**
  String get merchantAnalyticsDetailToClickRateShort;

  /// No description provided for @merchantAnalyticsViewToClaimRateShort.
  ///
  /// In en, this message translates to:
  /// **'View to claim'**
  String get merchantAnalyticsViewToClaimRateShort;

  /// No description provided for @merchantAnalyticsClaimToRedemptionRateShort.
  ///
  /// In en, this message translates to:
  /// **'Claim to redemption'**
  String get merchantAnalyticsClaimToRedemptionRateShort;

  /// No description provided for @merchantAnalyticsTopOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Top offers'**
  String get merchantAnalyticsTopOffersTitle;

  /// No description provided for @merchantAnalyticsTopOffersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No offer activity is strong enough for this period yet.'**
  String get merchantAnalyticsTopOffersEmpty;

  /// No description provided for @merchantAnalyticsTopOfferRedemptions.
  ///
  /// In en, this message translates to:
  /// **'{count} redemptions'**
  String merchantAnalyticsTopOfferRedemptions(String count);

  /// No description provided for @merchantAnalyticsTopOfferClaims.
  ///
  /// In en, this message translates to:
  /// **'{count} claims'**
  String merchantAnalyticsTopOfferClaims(String count);

  /// No description provided for @merchantAnalyticsTopOfferConversion.
  ///
  /// In en, this message translates to:
  /// **'{value} redemption rate'**
  String merchantAnalyticsTopOfferConversion(String value);

  /// No description provided for @merchantAnalyticsDailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Avg/day {value}'**
  String merchantAnalyticsDailyAverage(String value);

  /// No description provided for @merchantAnalyticsBestDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Best day'**
  String get merchantAnalyticsBestDayLabel;

  /// No description provided for @merchantAnalyticsWorstDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Slowest day'**
  String get merchantAnalyticsWorstDayLabel;

  /// No description provided for @merchantAnalyticsDetailNote.
  ///
  /// In en, this message translates to:
  /// **'This page uses the same analytics data as the dashboard today. Funnel and top-offer drill-down will arrive in a later release.'**
  String get merchantAnalyticsDetailNote;

  /// No description provided for @merchantAnalyticsViewsUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Views are up'**
  String get merchantAnalyticsViewsUpTitle;

  /// No description provided for @merchantAnalyticsViewsUpBody.
  ///
  /// In en, this message translates to:
  /// **'Views increased by {percent}% compared with the previous period.'**
  String merchantAnalyticsViewsUpBody(String percent);

  /// No description provided for @merchantAnalyticsViewsDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Views are down'**
  String get merchantAnalyticsViewsDownTitle;

  /// No description provided for @merchantAnalyticsViewsDownBody.
  ///
  /// In en, this message translates to:
  /// **'Views dropped by {percent}% compared with the previous period.'**
  String merchantAnalyticsViewsDownBody(String percent);

  /// No description provided for @merchantAnalyticsHighContactRateTitle.
  ///
  /// In en, this message translates to:
  /// **'High contact intent'**
  String get merchantAnalyticsHighContactRateTitle;

  /// No description provided for @merchantAnalyticsHighContactRateBody.
  ///
  /// In en, this message translates to:
  /// **'Visitors are turning into calls or navigation taps at {percent}% this period.'**
  String merchantAnalyticsHighContactRateBody(String percent);

  /// No description provided for @merchantAnalyticsLowContactRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Low contact intent'**
  String get merchantAnalyticsLowContactRateTitle;

  /// No description provided for @merchantAnalyticsLowContactRateBody.
  ///
  /// In en, this message translates to:
  /// **'Views are not turning into calls or navigation taps yet. Current contact rate is {percent}%.'**
  String merchantAnalyticsLowContactRateBody(String percent);

  /// No description provided for @merchantAnalyticsStoryBoostTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories are helping'**
  String get merchantAnalyticsStoryBoostTitle;

  /// No description provided for @merchantAnalyticsStoryBoostBody.
  ///
  /// In en, this message translates to:
  /// **'Story views equal {percent}% of venue views this period.'**
  String merchantAnalyticsStoryBoostBody(String percent);

  /// No description provided for @merchantAnalyticsStablePerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Stable week'**
  String get merchantAnalyticsStablePerformanceTitle;

  /// No description provided for @merchantAnalyticsStablePerformanceBody.
  ///
  /// In en, this message translates to:
  /// **'Performance is steady and contact rate is holding around {percent}%.'**
  String merchantAnalyticsStablePerformanceBody(String percent);

  /// No description provided for @merchantAnalyticsDataStaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Data is stale'**
  String get merchantAnalyticsDataStaleTitle;

  /// No description provided for @merchantAnalyticsDataStaleBody.
  ///
  /// In en, this message translates to:
  /// **'Analytics were last refreshed about {hours} hours ago.'**
  String merchantAnalyticsDataStaleBody(String hours);

  /// No description provided for @merchantAnalyticsNoRecentDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent data'**
  String get merchantAnalyticsNoRecentDataTitle;

  /// No description provided for @merchantAnalyticsNoRecentDataBody.
  ///
  /// In en, this message translates to:
  /// **'There isn\'t enough recent activity yet to draw a useful trend.'**
  String get merchantAnalyticsNoRecentDataBody;

  /// No description provided for @merchantAnalyticsTrafficUpNoConversionTitle.
  ///
  /// In en, this message translates to:
  /// **'Traffic is rising, conversion is not'**
  String get merchantAnalyticsTrafficUpNoConversionTitle;

  /// No description provided for @merchantAnalyticsTrafficUpNoConversionBody.
  ///
  /// In en, this message translates to:
  /// **'Views increased by {percent}%, but claims stayed low at {claims}.'**
  String merchantAnalyticsTrafficUpNoConversionBody(String percent, String claims);

  /// No description provided for @merchantAnalyticsContactDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact intent dropped'**
  String get merchantAnalyticsContactDropTitle;

  /// No description provided for @merchantAnalyticsContactDropBody.
  ///
  /// In en, this message translates to:
  /// **'Calls and navigation intent dropped by {percent}% versus the previous period.'**
  String merchantAnalyticsContactDropBody(String percent);

  /// No description provided for @merchantAnalyticsOfferInterestNoRedemptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer interest is not converting'**
  String get merchantAnalyticsOfferInterestNoRedemptionTitle;

  /// No description provided for @merchantAnalyticsOfferInterestNoRedemptionBody.
  ///
  /// In en, this message translates to:
  /// **'{claims} claims were created, but redemption is only {rate}%.'**
  String merchantAnalyticsOfferInterestNoRedemptionBody(String claims, String rate);

  /// No description provided for @merchantAnalyticsQuietPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet period'**
  String get merchantAnalyticsQuietPeriodTitle;

  /// No description provided for @merchantAnalyticsQuietPeriodBody.
  ///
  /// In en, this message translates to:
  /// **'Traffic and conversions are both very low right now.'**
  String get merchantAnalyticsQuietPeriodBody;

  /// No description provided for @merchantAnalyticsTopOfferConcentratedTitle.
  ///
  /// In en, this message translates to:
  /// **'One offer is carrying most redemptions'**
  String get merchantAnalyticsTopOfferConcentratedTitle;

  /// No description provided for @merchantAnalyticsTopOfferConcentratedBody.
  ///
  /// In en, this message translates to:
  /// **'A single offer is driving {share}% of redemptions, with {redemptions} redemptions on its own.'**
  String merchantAnalyticsTopOfferConcentratedBody(String share, String redemptions);

  /// No description provided for @merchantAnalyticsStoryLiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories are lifting traffic'**
  String get merchantAnalyticsStoryLiftTitle;

  /// No description provided for @merchantAnalyticsStoryLiftBody.
  ///
  /// In en, this message translates to:
  /// **'Story views grew by {percent}% and venue views moved up with them.'**
  String merchantAnalyticsStoryLiftBody(String percent);

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

  /// No description provided for @merchantContentHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Content Health'**
  String get merchantContentHealthTitle;

  /// No description provided for @merchantContentHealthLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load content health right now.'**
  String get merchantContentHealthLoadFailed;

  /// No description provided for @merchantContentHealthHealthyTitle.
  ///
  /// In en, this message translates to:
  /// **'Content looks healthy'**
  String get merchantContentHealthHealthyTitle;

  /// No description provided for @merchantContentHealthHealthyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your menu, photos, stories, hours, and venue info are all in good shape.'**
  String get merchantContentHealthHealthyMessage;

  /// No description provided for @merchantContentHealthMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get merchantContentHealthMenuTitle;

  /// No description provided for @merchantContentHealthPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get merchantContentHealthPhotosTitle;

  /// No description provided for @merchantContentHealthStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get merchantContentHealthStoriesTitle;

  /// No description provided for @merchantContentHealthHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get merchantContentHealthHoursTitle;

  /// No description provided for @merchantContentHealthProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get merchantContentHealthProfileTitle;

  /// No description provided for @merchantContentHealthMenuMissing.
  ///
  /// In en, this message translates to:
  /// **'No published menu is available right now.'**
  String get merchantContentHealthMenuMissing;

  /// No description provided for @merchantContentHealthMenuStale.
  ///
  /// In en, this message translates to:
  /// **'The menu was last published {days} days ago.'**
  String merchantContentHealthMenuStale(String days);

  /// No description provided for @merchantContentHealthPhotosCritical.
  ///
  /// In en, this message translates to:
  /// **'Only {count} photos are available. Add more to improve the venue page.'**
  String merchantContentHealthPhotosCritical(String count);

  /// No description provided for @merchantContentHealthPhotosWarning.
  ///
  /// In en, this message translates to:
  /// **'You only have {count} photos. Add a few more to improve the listing.'**
  String merchantContentHealthPhotosWarning(String count);

  /// No description provided for @merchantContentHealthStoriesCritical.
  ///
  /// In en, this message translates to:
  /// **'No active story is available, and the last publish was {days} days ago.'**
  String merchantContentHealthStoriesCritical(String days);

  /// No description provided for @merchantContentHealthStoriesWarning.
  ///
  /// In en, this message translates to:
  /// **'The last story was published {days} days ago.'**
  String merchantContentHealthStoriesWarning(String days);

  /// No description provided for @merchantContentHealthHoursCritical.
  ///
  /// In en, this message translates to:
  /// **'Add working hours so customers know when to visit.'**
  String get merchantContentHealthHoursCritical;

  /// No description provided for @merchantContentHealthHoursWarning.
  ///
  /// In en, this message translates to:
  /// **'Hours are complete for only {count} days.'**
  String merchantContentHealthHoursWarning(String count);

  /// No description provided for @merchantContentHealthProfileCritical.
  ///
  /// In en, this message translates to:
  /// **'The profile is missing {count} required fields.'**
  String merchantContentHealthProfileCritical(String count);

  /// No description provided for @merchantContentHealthProfileWarning.
  ///
  /// In en, this message translates to:
  /// **'The profile is missing just {count} field.'**
  String merchantContentHealthProfileWarning(String count);

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

  /// No description provided for @merchantStoriesPromotedUntil.
  ///
  /// In en, this message translates to:
  /// **'Promoted until {dateTime}'**
  String merchantStoriesPromotedUntil(String dateTime);

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

  /// No description provided for @merchantStoriesVenueInactive.
  ///
  /// In en, this message translates to:
  /// **'This story can\'t be promoted because the venue is currently inactive.'**
  String get merchantStoriesVenueInactive;

  /// No description provided for @merchantStoriesPricingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Promotion pricing couldn\'t be loaded right now. Please try again shortly.'**
  String get merchantStoriesPricingUnavailable;

  /// No description provided for @merchantStoriesInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance is too low to promote this story. Top up WAIN Credit and try again.'**
  String get merchantStoriesInsufficientBalance;

  /// No description provided for @merchantStoriesWalletMissing.
  ///
  /// In en, this message translates to:
  /// **'This venue doesn\'t have a WAIN Credit wallet yet. Open the wallet and submit a top-up first.'**
  String get merchantStoriesWalletMissing;

  /// No description provided for @merchantStoriesWalletInactive.
  ///
  /// In en, this message translates to:
  /// **'This story can\'t be promoted because the venue wallet is not active right now.'**
  String get merchantStoriesWalletInactive;

  /// No description provided for @merchantStoriesOpenWallet.
  ///
  /// In en, this message translates to:
  /// **'Open WAIN Credit'**
  String get merchantStoriesOpenWallet;

  /// No description provided for @merchantStoriesPromotionConflict.
  ///
  /// In en, this message translates to:
  /// **'This promotion request was already used in a conflicting way. Start a new promotion request.'**
  String get merchantStoriesPromotionConflict;

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

  /// No description provided for @offerErrorExpired.
  ///
  /// In en, this message translates to:
  /// **'This offer has expired and is no longer available'**
  String get offerErrorExpired;

  /// No description provided for @offerErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This offer is currently unavailable'**
  String get offerErrorUnavailable;

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

  /// No description provided for @merchantOffersTopPerformerLabel.
  ///
  /// In en, this message translates to:
  /// **'Top performer'**
  String get merchantOffersTopPerformerLabel;

  /// No description provided for @merchantOffersNoPerformanceData.
  ///
  /// In en, this message translates to:
  /// **'No performance data yet'**
  String get merchantOffersNoPerformanceData;

  /// No description provided for @merchantReviewQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply quality'**
  String get merchantReviewQualityTitle;

  /// No description provided for @merchantReviewReplyRate.
  ///
  /// In en, this message translates to:
  /// **'{rate}% reply rate'**
  String merchantReviewReplyRate(String rate);

  /// No description provided for @merchantReviewAverageReplyHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h avg reply'**
  String merchantReviewAverageReplyHours(String hours);

  /// No description provided for @merchantReviewAverageReplyDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d avg reply'**
  String merchantReviewAverageReplyDays(String days);

  /// No description provided for @merchantReviewAverageReplyUnderOneHour.
  ///
  /// In en, this message translates to:
  /// **'<1h avg reply'**
  String get merchantReviewAverageReplyUnderOneHour;

  /// No description provided for @merchantReviewNoReplyDataYet.
  ///
  /// In en, this message translates to:
  /// **'No reply data yet'**
  String get merchantReviewNoReplyDataYet;

  /// No description provided for @merchantReviewOldestUnansweredHours.
  ///
  /// In en, this message translates to:
  /// **'Oldest unanswered: {hours}h'**
  String merchantReviewOldestUnansweredHours(String hours);

  /// No description provided for @merchantReviewOldestUnansweredDays.
  ///
  /// In en, this message translates to:
  /// **'Oldest unanswered: {days}d'**
  String merchantReviewOldestUnansweredDays(String days);

  /// No description provided for @merchantReviewOldestUnansweredUnderOneHour.
  ///
  /// In en, this message translates to:
  /// **'Oldest unanswered: <1h'**
  String get merchantReviewOldestUnansweredUnderOneHour;

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

  /// No description provided for @merchantOffersDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Offer deleted'**
  String get merchantOffersDeleteSuccess;

  /// No description provided for @merchantOffersDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete offer: {error}'**
  String merchantOffersDeleteError(String error);

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

  /// No description provided for @merchantOffersToggleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Offer status updated to {status}'**
  String merchantOffersToggleUpdated(String status);

  /// No description provided for @merchantOffersToggleError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update offer status: {error}'**
  String merchantOffersToggleError(String error);

  /// No description provided for @merchantOffersPin.
  ///
  /// In en, this message translates to:
  /// **'Feature offer'**
  String get merchantOffersPin;

  /// No description provided for @merchantOffersFeaturedBadge.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get merchantOffersFeaturedBadge;

  /// No description provided for @merchantOffersFeaturedUntil.
  ///
  /// In en, this message translates to:
  /// **'Featured until {date}'**
  String merchantOffersFeaturedUntil(String date);

  /// No description provided for @merchantOffersPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature this offer'**
  String get merchantOffersPinTitle;

  /// No description provided for @merchantOffersPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose duration and price'**
  String get merchantOffersPinSubtitle;

  /// No description provided for @merchantOffersPinOption.
  ///
  /// In en, this message translates to:
  /// **'{days} days - {amount} ILS'**
  String merchantOffersPinOption(int days, String amount);

  /// No description provided for @merchantOffersPinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Offer featured successfully'**
  String get merchantOffersPinSuccess;

  /// No description provided for @merchantOffersPinError.
  ///
  /// In en, this message translates to:
  /// **'Failed to feature offer: {error}'**
  String merchantOffersPinError(String error);

  /// No description provided for @merchantOffersPinInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient wallet balance to feature this offer'**
  String get merchantOffersPinInsufficientBalance;

  /// No description provided for @merchantOffersPinGoWallet.
  ///
  /// In en, this message translates to:
  /// **'Open wallet'**
  String get merchantOffersPinGoWallet;

  /// No description provided for @merchantOffersPinPricingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Feature pricing is unavailable right now'**
  String get merchantOffersPinPricingUnavailable;

  /// No description provided for @merchantOffersSubmitError.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String merchantOffersSubmitError(String error);

  /// No description provided for @merchantOffersNoVenueLinked.
  ///
  /// In en, this message translates to:
  /// **'No venue linked to this merchant account.'**
  String get merchantOffersNoVenueLinked;

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

  /// No description provided for @merchantOffersValueRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a discount value'**
  String get merchantOffersValueRequired;

  /// No description provided for @merchantOffersValueInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get merchantOffersValueInvalid;

  /// No description provided for @merchantOffersValuePositive.
  ///
  /// In en, this message translates to:
  /// **'Discount value must be greater than zero'**
  String get merchantOffersValuePositive;

  /// No description provided for @merchantOffersValuePercentRange.
  ///
  /// In en, this message translates to:
  /// **'Percentage discount must be between 1 and 100'**
  String get merchantOffersValuePercentRange;

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

  /// No description provided for @merchantOffersDateRangeInvalid.
  ///
  /// In en, this message translates to:
  /// **'End date must be after the start date'**
  String get merchantOffersDateRangeInvalid;

  /// No description provided for @merchantOffersUsageLabel.
  ///
  /// In en, this message translates to:
  /// **'Usage policy'**
  String get merchantOffersUsageLabel;

  /// No description provided for @merchantOffersUsageHint.
  ///
  /// In en, this message translates to:
  /// **'Choose whether each customer can use this offer once only or on every visit.'**
  String get merchantOffersUsageHint;

  /// No description provided for @merchantOffersUsageSingle.
  ///
  /// In en, this message translates to:
  /// **'One time per customer'**
  String get merchantOffersUsageSingle;

  /// No description provided for @merchantOffersUsageRepeatable.
  ///
  /// In en, this message translates to:
  /// **'Repeatable'**
  String get merchantOffersUsageRepeatable;

  /// No description provided for @merchantOffersUsageBadgeSingle.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get merchantOffersUsageBadgeSingle;

  /// No description provided for @merchantOffersUsageBadgeRepeatable.
  ///
  /// In en, this message translates to:
  /// **'Repeatable'**
  String get merchantOffersUsageBadgeRepeatable;

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

  /// No description provided for @scanBillAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill total before discount'**
  String get scanBillAmountLabel;

  /// No description provided for @scanBillAmountHint.
  ///
  /// In en, this message translates to:
  /// **'This is optional for percentage offers. Enter it to record the actual savings from the {percent}% discount.'**
  String scanBillAmountHint(String percent);

  /// No description provided for @scanBillAmountField.
  ///
  /// In en, this message translates to:
  /// **'Bill amount ({currency})'**
  String scanBillAmountField(String currency);

  /// No description provided for @scanBillAmountOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to redeem without recording confirmed savings'**
  String get scanBillAmountOptionalHint;

  /// No description provided for @scanBillAmountHelper.
  ///
  /// In en, this message translates to:
  /// **'If you enter the bill total, Wain will calculate the confirmed savings automatically.'**
  String get scanBillAmountHelper;

  /// No description provided for @scanBillAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount greater than zero and not more than 100000'**
  String get scanBillAmountInvalid;

  /// No description provided for @scanBeforeDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Before discount'**
  String get scanBeforeDiscountLabel;

  /// No description provided for @scanConfirmedSavingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmed savings'**
  String get scanConfirmedSavingsLabel;

  /// No description provided for @scanAfterDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'After discount'**
  String get scanAfterDiscountLabel;

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

  /// No description provided for @menuItemSaved.
  ///
  /// In en, this message translates to:
  /// **'Menu item saved'**
  String get menuItemSaved;

  /// No description provided for @menuItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Menu item deleted'**
  String get menuItemDeleted;

  /// No description provided for @menuItemAvailabilityFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update item availability: {error}'**
  String menuItemAvailabilityFailed(String error);

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

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryButton;

  /// No description provided for @doubleBackToExitMessage.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get doubleBackToExitMessage;

  /// No description provided for @emptyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results, try adjusting filters'**
  String get emptyNoResults;

  /// No description provided for @emptyNoResultsAction.
  ///
  /// In en, this message translates to:
  /// **'Adjust filters'**
  String get emptyNoResultsAction;

  /// No description provided for @emptyNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorite places yet'**
  String get emptyNoFavorites;

  /// No description provided for @emptyNoFavoritesAction.
  ///
  /// In en, this message translates to:
  /// **'Explore places'**
  String get emptyNoFavoritesAction;

  /// No description provided for @emptyNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get emptyNoReviews;

  /// No description provided for @emptyNoReviewsAction.
  ///
  /// In en, this message translates to:
  /// **'Add review'**
  String get emptyNoReviewsAction;

  /// No description provided for @emptyNoSavedOffers.
  ///
  /// In en, this message translates to:
  /// **'No saved offers yet'**
  String get emptyNoSavedOffers;

  /// No description provided for @emptyNoSavedOffersAction.
  ///
  /// In en, this message translates to:
  /// **'Browse offers'**
  String get emptyNoSavedOffersAction;

  /// No description provided for @emptyOffline.
  ///
  /// In en, this message translates to:
  /// **'Could not load new data, showing cached version'**
  String get emptyOffline;

  /// No description provided for @emptyOfflineAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get emptyOfflineAction;

  /// No description provided for @hoursOpen24.
  ///
  /// In en, this message translates to:
  /// **'Open 24 hours'**
  String get hoursOpen24;

  /// No description provided for @hoursUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Hours not available'**
  String get hoursUnavailable;

  /// No description provided for @hoursUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get hoursUnknown;

  /// No description provided for @hoursClosedToday.
  ///
  /// In en, this message translates to:
  /// **'Closed today'**
  String get hoursClosedToday;

  /// No description provided for @hoursBadgeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get hoursBadgeOpen;

  /// No description provided for @hoursBadgeClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get hoursBadgeClosed;

  /// No description provided for @hoursOpenUntil.
  ///
  /// In en, this message translates to:
  /// **'Open until {time}'**
  String hoursOpenUntil(String time);

  /// No description provided for @hoursOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get hoursOpenNow;

  /// No description provided for @hoursOpensAt.
  ///
  /// In en, this message translates to:
  /// **'Opens at {time}'**
  String hoursOpensAt(String time);

  /// No description provided for @hoursPeriodAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get hoursPeriodAm;

  /// No description provided for @hoursPeriodPm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get hoursPeriodPm;

  /// No description provided for @navDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigate to'**
  String get navDialogTitle;

  /// No description provided for @navCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get navCancel;

  /// No description provided for @cacheUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get cacheUnknown;

  /// No description provided for @cacheJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get cacheJustNow;

  /// No description provided for @cacheMinsAgo.
  ///
  /// In en, this message translates to:
  /// **'{mins} min ago'**
  String cacheMinsAgo(int mins);

  /// No description provided for @cacheHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr ago'**
  String cacheHoursAgo(int hours);

  /// No description provided for @cacheDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String cacheDaysAgo(int days);

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(String meters);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @durationMins.
  ///
  /// In en, this message translates to:
  /// **'{mins} min'**
  String durationMins(String mins);

  /// No description provided for @durationHoursMins.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr {mins} min'**
  String durationHoursMins(String hours, String mins);

  /// No description provided for @geofenceNearby.
  ///
  /// In en, this message translates to:
  /// **'📍 You\'re near {venue}!'**
  String geofenceNearby(String venue);

  /// No description provided for @geofenceOffers.
  ///
  /// In en, this message translates to:
  /// **'🎁 Exclusive offers waiting for you!'**
  String get geofenceOffers;

  /// No description provided for @geofenceDiscover.
  ///
  /// In en, this message translates to:
  /// **'⭐ Discover this special place'**
  String get geofenceDiscover;

  /// No description provided for @shareVenueText.
  ///
  /// In en, this message translates to:
  /// **'Check out this place on WAIN! 🌟'**
  String get shareVenueText;

  /// No description provided for @errorPageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get errorPageNotFound;

  /// No description provided for @errorGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get errorGoHome;

  /// No description provided for @mapNoVenuesInArea.
  ///
  /// In en, this message translates to:
  /// **'No venues in this area currently'**
  String get mapNoVenuesInArea;

  /// No description provided for @mapFoundVenuesWithOffers.
  ///
  /// In en, this message translates to:
  /// **'Found {count} venues ({offers} offers available 🔥)'**
  String mapFoundVenuesWithOffers(String count, String offers);

  /// No description provided for @mapFoundVenues.
  ///
  /// In en, this message translates to:
  /// **'Found {count} venues'**
  String mapFoundVenues(String count);

  /// No description provided for @mapSearchError.
  ///
  /// In en, this message translates to:
  /// **'Search error occurred'**
  String get mapSearchError;

  /// No description provided for @mapBoundsTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Area too large, please zoom in more'**
  String get mapBoundsTooLarge;

  /// No description provided for @mapRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Search rate limit exceeded'**
  String get mapRateLimited;

  /// No description provided for @mapNavModeActive.
  ///
  /// In en, this message translates to:
  /// **'Navigation mode active'**
  String get mapNavModeActive;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a place...'**
  String get mapSearchHint;

  /// No description provided for @mapFilterTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get mapFilterTopRated;

  /// No description provided for @mapFilterExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get mapFilterExplore;

  /// No description provided for @mapFilterOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get mapFilterOpenNow;

  /// No description provided for @mapFilterPartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get mapFilterPartners;

  /// No description provided for @mapFilterOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get mapFilterOffers;

  /// No description provided for @mapFilterRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get mapFilterRestaurants;

  /// No description provided for @mapFilterCafes.
  ///
  /// In en, this message translates to:
  /// **'Cafes'**
  String get mapFilterCafes;

  /// No description provided for @mapFilterRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get mapFilterRomantic;

  /// No description provided for @mapFilterFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get mapFilterFamily;

  /// No description provided for @mapOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline - browsing saved version'**
  String get mapOfflineBanner;

  /// No description provided for @mapOfferAvailable.
  ///
  /// In en, this message translates to:
  /// **'Offer available'**
  String get mapOfferAvailable;

  /// No description provided for @mapCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get mapCategoryGeneral;

  /// No description provided for @mapGetOfferNow.
  ///
  /// In en, this message translates to:
  /// **'Get the offer now'**
  String get mapGetOfferNow;

  /// No description provided for @mapDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get mapDetails;

  /// No description provided for @mapDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get mapDirections;

  /// No description provided for @mapVenueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} venues'**
  String mapVenueCount(String count);

  /// No description provided for @mapDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String mapDistanceAway(String distance);

  /// No description provided for @mapNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Needs connection'**
  String get mapNeedsConnection;

  /// No description provided for @mapStartNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start Navigation'**
  String get mapStartNavigation;

  /// No description provided for @mapRouteFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch route'**
  String get mapRouteFetchFailed;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileTitle;

  /// No description provided for @profileSectionActivity.
  ///
  /// In en, this message translates to:
  /// **'My Activity'**
  String get profileSectionActivity;

  /// No description provided for @profileMyOffers.
  ///
  /// In en, this message translates to:
  /// **'My Offers'**
  String get profileMyOffers;

  /// No description provided for @profileMyOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used offers'**
  String get profileMyOffersSubtitle;

  /// No description provided for @profileSavedOffers.
  ///
  /// In en, this message translates to:
  /// **'Saved Offers'**
  String get profileSavedOffers;

  /// No description provided for @profileSavedOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offers you saved'**
  String get profileSavedOffersSubtitle;

  /// No description provided for @profileMyStats.
  ///
  /// In en, this message translates to:
  /// **'My Stats'**
  String get profileMyStats;

  /// No description provided for @profileMyStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your activity summary on WAIN'**
  String get profileMyStatsSubtitle;

  /// No description provided for @profileTryList.
  ///
  /// In en, this message translates to:
  /// **'Want to try 🎯'**
  String get profileTryList;

  /// No description provided for @profileTryListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Places you want to visit'**
  String get profileTryListSubtitle;

  /// No description provided for @profileAdminTopUpReview.
  ///
  /// In en, this message translates to:
  /// **'Admin top-up review'**
  String get profileAdminTopUpReview;

  /// No description provided for @profileAdminTopUpReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review merchant top-up requests'**
  String get profileAdminTopUpReviewSubtitle;

  /// No description provided for @profileMerchantDashboard.
  ///
  /// In en, this message translates to:
  /// **'Merchant Dashboard 📊'**
  String get profileMerchantDashboard;

  /// No description provided for @profileMerchantDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your shop and stats'**
  String get profileMerchantDashboardSubtitle;

  /// No description provided for @profileJoinMerchant.
  ///
  /// In en, this message translates to:
  /// **'Join as Merchant'**
  String get profileJoinMerchant;

  /// No description provided for @profileJoinMerchantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Have a shop? Enter invite code'**
  String get profileJoinMerchantSubtitle;

  /// No description provided for @profileSectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSectionSettings;

  /// No description provided for @profileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCity;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileLanguageAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get profileLanguageAr;

  /// No description provided for @profileTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileTheme;

  /// No description provided for @profileThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileThemeDark;

  /// No description provided for @profileThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileThemeLight;

  /// No description provided for @profileGeofenceNotifs.
  ///
  /// In en, this message translates to:
  /// **'Proximity Notifications'**
  String get profileGeofenceNotifs;

  /// No description provided for @profileGeofenceNotifsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alert when near special places'**
  String get profileGeofenceNotifsSubtitle;

  /// No description provided for @profileWalletNotifications.
  ///
  /// In en, this message translates to:
  /// **'Wallet activity notifications'**
  String get profileWalletNotifications;

  /// No description provided for @profileWalletNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when wallet requests, approvals, reversals, and low-balance events happen'**
  String get profileWalletNotificationsSubtitle;

  /// No description provided for @profileWalletExpiryReminders.
  ///
  /// In en, this message translates to:
  /// **'Wallet expiry reminders'**
  String get profileWalletExpiryReminders;

  /// No description provided for @profileWalletExpiryRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me before story promotions or featured offers expire'**
  String get profileWalletExpiryRemindersSubtitle;

  /// No description provided for @profileAdminWalletNotifications.
  ///
  /// In en, this message translates to:
  /// **'Admin wallet notifications'**
  String get profileAdminWalletNotifications;

  /// No description provided for @profileAdminWalletNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified about new merchant top-up requests'**
  String get profileAdminWalletNotificationsSubtitle;

  /// No description provided for @profileSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileSectionAbout;

  /// No description provided for @profileAboutWain.
  ///
  /// In en, this message translates to:
  /// **'About WAIN'**
  String get profileAboutWain;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profilePrivacy;

  /// No description provided for @profileHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get profileHelp;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String profileVersion(String version);

  /// No description provided for @profileMerchantScan.
  ///
  /// In en, this message translates to:
  /// **'Merchant Access (Scan)'**
  String get profileMerchantScan;

  /// No description provided for @profileChooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose City'**
  String get profileChooseCity;

  /// No description provided for @profileUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileUser;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileGuestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get profileGuestUser;

  /// No description provided for @profileGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save favorites'**
  String get profileGuestSubtitle;

  /// No description provided for @profileSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get profileSignIn;

  /// No description provided for @venueCardBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best Match'**
  String get venueCardBestMatch;

  /// No description provided for @venueCardOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get venueCardOpen;

  /// No description provided for @venueCardClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get venueCardClosed;

  /// No description provided for @nearbyVenuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyVenuesTitle;

  /// No description provided for @nearbyApproxLocation.
  ///
  /// In en, this message translates to:
  /// **'Approximate location'**
  String get nearbyApproxLocation;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get categoryGeneral;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Stats'**
  String get statsTitle;

  /// No description provided for @statsLoginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your stats'**
  String get statsLoginPrompt;

  /// No description provided for @statsWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}!'**
  String statsWelcome(String name);

  /// No description provided for @statsActivitySummary.
  ///
  /// In en, this message translates to:
  /// **'Your activity summary on WAIN'**
  String get statsActivitySummary;

  /// No description provided for @statsUsedOffers.
  ///
  /// In en, this message translates to:
  /// **'Used offers'**
  String get statsUsedOffers;

  /// No description provided for @statsConfirmedSavings.
  ///
  /// In en, this message translates to:
  /// **'Confirmed savings'**
  String get statsConfirmedSavings;

  /// No description provided for @statsActiveClaims.
  ///
  /// In en, this message translates to:
  /// **'Active claims'**
  String get statsActiveClaims;

  /// No description provided for @statsReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get statsReviews;

  /// No description provided for @statsFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get statsFavorites;

  /// No description provided for @statsSavingsHint.
  ///
  /// In en, this message translates to:
  /// **'These are the confirmed savings from offers where the actual savings were recorded'**
  String get statsSavingsHint;

  /// No description provided for @statsAdditionalDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Extra discounts'**
  String get statsAdditionalDiscounts;

  /// No description provided for @statsAdditionalDiscountsSub.
  ///
  /// In en, this message translates to:
  /// **'You used {count} extra percent/free-item offers'**
  String statsAdditionalDiscountsSub(int count);

  /// No description provided for @statsUsedOffersDetails.
  ///
  /// In en, this message translates to:
  /// **'Recently used offers'**
  String get statsUsedOffersDetails;

  /// No description provided for @statsNoUsedOffersYet.
  ///
  /// In en, this message translates to:
  /// **'No used offers yet'**
  String get statsNoUsedOffersYet;

  /// No description provided for @statsNoUsedOffersYetSub.
  ///
  /// In en, this message translates to:
  /// **'Once you redeem your first offer, your benefit details will appear here'**
  String get statsNoUsedOffersYetSub;

  /// No description provided for @statsUsedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Used {date}'**
  String statsUsedOnDate(String date);

  /// No description provided for @statsOfferSavingsValue.
  ///
  /// In en, this message translates to:
  /// **'Saved {amount}'**
  String statsOfferSavingsValue(String amount);

  /// No description provided for @statsOfferUsedStatus.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get statsOfferUsedStatus;

  /// No description provided for @statsRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get statsRecentActivity;

  /// No description provided for @statsReviewsReady.
  ///
  /// In en, this message translates to:
  /// **'Reviews feature is ready!'**
  String get statsReviewsReady;

  /// No description provided for @statsReviewsReadySub.
  ///
  /// In en, this message translates to:
  /// **'Rate the places you visited'**
  String get statsReviewsReadySub;

  /// No description provided for @statsTimeNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get statsTimeNow;

  /// No description provided for @statsExploreOffers.
  ///
  /// In en, this message translates to:
  /// **'Explore exclusive offers'**
  String get statsExploreOffers;

  /// No description provided for @statsExploreOffersSub.
  ///
  /// In en, this message translates to:
  /// **'New offers every day'**
  String get statsExploreOffersSub;

  /// No description provided for @statsTimeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsTimeToday;

  /// No description provided for @statsDiscoverPlaces.
  ///
  /// In en, this message translates to:
  /// **'Discover new places'**
  String get statsDiscoverPlaces;

  /// No description provided for @statsDiscoverPlacesSub.
  ///
  /// In en, this message translates to:
  /// **'Try asking \"Where should I go?\"'**
  String get statsDiscoverPlacesSub;

  /// No description provided for @statsTimeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statsTimeNew;

  /// No description provided for @statsAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get statsAchievements;

  /// No description provided for @statsNewExplorer.
  ///
  /// In en, this message translates to:
  /// **'New Explorer'**
  String get statsNewExplorer;

  /// No description provided for @statsReviewer.
  ///
  /// In en, this message translates to:
  /// **'Reviewer'**
  String get statsReviewer;

  /// No description provided for @statsOfferHunter.
  ///
  /// In en, this message translates to:
  /// **'Offer Hunter'**
  String get statsOfferHunter;

  /// No description provided for @statsPlaceLover.
  ///
  /// In en, this message translates to:
  /// **'Place Lover'**
  String get statsPlaceLover;

  /// No description provided for @statsWainExpert.
  ///
  /// In en, this message translates to:
  /// **'WAIN Expert'**
  String get statsWainExpert;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingExploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore and Discover'**
  String get onboardingExploreTitle;

  /// No description provided for @onboardingExploreDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover the best cafes, restaurants, and entertainment venues around you easily.'**
  String get onboardingExploreDesc;

  /// No description provided for @onboardingOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Offers'**
  String get onboardingOffersTitle;

  /// No description provided for @onboardingOffersDesc.
  ///
  /// In en, this message translates to:
  /// **'Benefit from discounts and special offers when visiting our partners.'**
  String get onboardingOffersDesc;

  /// No description provided for @onboardingNavigateTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Your Way'**
  String get onboardingNavigateTitle;

  /// No description provided for @onboardingNavigateDesc.
  ///
  /// In en, this message translates to:
  /// **'Get accurate directions and discover which places are open now.'**
  String get onboardingNavigateDesc;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @tryListTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to try 🎯'**
  String get tryListTitle;

  /// No description provided for @tryListMovedToFav.
  ///
  /// In en, this message translates to:
  /// **'✅ {name} moved to favorites!'**
  String tryListMovedToFav(String name);

  /// No description provided for @tryListUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get tryListUndo;

  /// No description provided for @tryListRemoved.
  ///
  /// In en, this message translates to:
  /// **'🗑️ {name} removed from list'**
  String tryListRemoved(String name);

  /// No description provided for @tryListTriedIt.
  ///
  /// In en, this message translates to:
  /// **'🎉 {name} tried it! Moved to favorites'**
  String tryListTriedIt(String name);

  /// No description provided for @tryListTriedItBtn.
  ///
  /// In en, this message translates to:
  /// **'Tried it'**
  String get tryListTriedItBtn;

  /// No description provided for @tryListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No places added yet'**
  String get tryListEmptyTitle;

  /// No description provided for @tryListEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap 🎯 on any place to add it to your \"Want to try\" list'**
  String get tryListEmptySubtitle;

  /// No description provided for @tryListExploreBtn.
  ///
  /// In en, this message translates to:
  /// **'Discover places'**
  String get tryListExploreBtn;

  /// No description provided for @tryListInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'\"Want to try\" list 🎯'**
  String get tryListInfoTitle;

  /// No description provided for @tryListInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Here you\'ll find places you want to try.\n\n• Tap \"Tried it ✅\" to move to favorites\n• Tap ✕ to remove from list\n• Tap a place to see details'**
  String get tryListInfoBody;

  /// No description provided for @tryListInfoDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get tryListInfoDismiss;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @helpContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get helpContactUs;

  /// No description provided for @helpEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get helpEmail;

  /// No description provided for @helpWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get helpWhatsApp;

  /// No description provided for @helpFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get helpFaq;

  /// No description provided for @helpFaqOffersQ.
  ///
  /// In en, this message translates to:
  /// **'How do I use offers?'**
  String get helpFaqOffersQ;

  /// No description provided for @helpFaqOffersA.
  ///
  /// In en, this message translates to:
  /// **'Tap any available offer, then tap \"Get Offer\". A QR code will appear that you can show to the merchant within 10 minutes.'**
  String get helpFaqOffersA;

  /// No description provided for @helpFaqMultiUseQ.
  ///
  /// In en, this message translates to:
  /// **'Can I use an offer more than once?'**
  String get helpFaqMultiUseQ;

  /// No description provided for @helpFaqMultiUseA.
  ///
  /// In en, this message translates to:
  /// **'Each offer has a specific usage limit. Some offers can only be used once, while others can be used multiple times.'**
  String get helpFaqMultiUseA;

  /// No description provided for @helpFaqLocationQ.
  ///
  /// In en, this message translates to:
  /// **'Why doesn\'t my location show?'**
  String get helpFaqLocationQ;

  /// No description provided for @helpFaqLocationA.
  ///
  /// In en, this message translates to:
  /// **'Make sure to allow the app to access your location from phone settings. Go to Settings > Apps > WAIN > Permissions > Location.'**
  String get helpFaqLocationA;

  /// No description provided for @helpFaqAddPlaceQ.
  ///
  /// In en, this message translates to:
  /// **'How do I add my place to the app?'**
  String get helpFaqAddPlaceQ;

  /// No description provided for @helpFaqAddPlaceA.
  ///
  /// In en, this message translates to:
  /// **'If you own a restaurant or cafe and want to join, contact us via email and we\'ll add your place.'**
  String get helpFaqAddPlaceA;

  /// No description provided for @helpFaqFreeQ.
  ///
  /// In en, this message translates to:
  /// **'Is the app free?'**
  String get helpFaqFreeQ;

  /// No description provided for @helpFaqFreeA.
  ///
  /// In en, this message translates to:
  /// **'Yes! The app is completely free for users. We work with partners to provide the best offers for you.'**
  String get helpFaqFreeA;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @privacyLastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last updated: February 2026'**
  String get privacyLastUpdate;

  /// No description provided for @privacySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Information We Collect'**
  String get privacySection1Title;

  /// No description provided for @privacySection1Body.
  ///
  /// In en, this message translates to:
  /// **'• Location information to show nearby places\n• Device ID to identify your account\n• Favorite places and used offers\n• Usage statistics to improve the app'**
  String get privacySection1Body;

  /// No description provided for @privacySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Your Information'**
  String get privacySection2Title;

  /// No description provided for @privacySection2Body.
  ///
  /// In en, this message translates to:
  /// **'• Provide personalized place recommendations\n• Show available offers in your area\n• Improve user experience\n• Communicate with you about new offers'**
  String get privacySection2Body;

  /// No description provided for @privacySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Information Sharing'**
  String get privacySection3Title;

  /// No description provided for @privacySection3Body.
  ///
  /// In en, this message translates to:
  /// **'We do not sell or share your personal information with third parties except in the following cases:\n• With your explicit consent\n• To comply with laws and regulations\n• To protect our rights or property'**
  String get privacySection3Body;

  /// No description provided for @privacySection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Data Security'**
  String get privacySection4Title;

  /// No description provided for @privacySection4Body.
  ///
  /// In en, this message translates to:
  /// **'We use advanced encryption technologies to protect your data. All data is stored on secure Firebase servers.'**
  String get privacySection4Body;

  /// No description provided for @privacySection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Your Rights'**
  String get privacySection5Title;

  /// No description provided for @privacySection5Body.
  ///
  /// In en, this message translates to:
  /// **'• You can request deletion of your data at any time\n• You can disable location services from settings\n• You can contact us for any inquiries'**
  String get privacySection5Body;

  /// No description provided for @privacySection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Contact Us'**
  String get privacySection6Title;

  /// No description provided for @privacySection6Body.
  ///
  /// In en, this message translates to:
  /// **'For privacy policy inquiries:\nEmail: privacy@wain.app'**
  String get privacySection6Body;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications 🔔'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String notificationsError(String error);

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications at the moment'**
  String get notificationsEmpty;

  /// No description provided for @notificationsNewNotif.
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get notificationsNewNotif;

  /// No description provided for @notificationsHintReview.
  ///
  /// In en, this message translates to:
  /// **'Tap to open reviews and respond quickly'**
  String get notificationsHintReview;

  /// No description provided for @notificationsHintOffer.
  ///
  /// In en, this message translates to:
  /// **'Tap to open offers and track performance'**
  String get notificationsHintOffer;

  /// No description provided for @notificationsHintWelcome.
  ///
  /// In en, this message translates to:
  /// **'Tap to open merchant dashboard'**
  String get notificationsHintWelcome;

  /// No description provided for @notificationsHintWallet.
  ///
  /// In en, this message translates to:
  /// **'Tap to open wallet details and recent activity'**
  String get notificationsHintWallet;

  /// No description provided for @notificationsHintAdminTopup.
  ///
  /// In en, this message translates to:
  /// **'Tap to review pending top-up requests'**
  String get notificationsHintAdminTopup;

  /// No description provided for @notificationsHintWalletStoryExpiry.
  ///
  /// In en, this message translates to:
  /// **'Tap to review promoted stories before they expire'**
  String get notificationsHintWalletStoryExpiry;

  /// No description provided for @notificationsHintWalletOfferExpiry.
  ///
  /// In en, this message translates to:
  /// **'Tap to review featured offers before they expire'**
  String get notificationsHintWalletOfferExpiry;

  /// No description provided for @resultsSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Our Suggestions'**
  String get resultsSuggestions;

  /// No description provided for @resultsBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best Match'**
  String get resultsBestMatch;

  /// No description provided for @resultsBestMatchSub.
  ///
  /// In en, this message translates to:
  /// **'Based on your choices'**
  String get resultsBestMatchSub;

  /// No description provided for @resultsChangeChoices.
  ///
  /// In en, this message translates to:
  /// **'Change choices'**
  String get resultsChangeChoices;

  /// No description provided for @resultsStatsShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get resultsStatsShowMore;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCount(int count);

  /// No description provided for @resultsSortedBy.
  ///
  /// In en, this message translates to:
  /// **'Sorted by {sort}'**
  String resultsSortedBy(String sort);

  /// No description provided for @resultsNavAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get resultsNavAccount;

  /// No description provided for @resultsNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get resultsNavSettings;

  /// No description provided for @resultsNavSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get resultsNavSuggestions;

  /// No description provided for @resultsNavStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get resultsNavStats;

  /// No description provided for @resultsNavFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get resultsNavFavorites;

  /// No description provided for @resultsNavMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get resultsNavMap;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get filterTitle;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterBudgetRange.
  ///
  /// In en, this message translates to:
  /// **'Budget per person'**
  String get filterBudgetRange;

  /// No description provided for @filterBudgetQuestion.
  ///
  /// In en, this message translates to:
  /// **'What\'s your budget today?'**
  String get filterBudgetQuestion;

  /// No description provided for @filterBudgetMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get filterBudgetMin;

  /// No description provided for @filterBudgetMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get filterBudgetMax;

  /// No description provided for @filterBudgetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get filterBudgetInvalid;

  /// No description provided for @filterBudgetInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'Minimum price must be less than maximum'**
  String get filterBudgetInvalidRange;

  /// No description provided for @filterPreResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Before we show suggestions, adjust your budget and key filters'**
  String get filterPreResultsHint;

  /// No description provided for @filterSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get filterSortBy;

  /// No description provided for @filterCuisineType.
  ///
  /// In en, this message translates to:
  /// **'Cuisine type'**
  String get filterCuisineType;

  /// No description provided for @filterDestination.
  ///
  /// In en, this message translates to:
  /// **'Going for'**
  String get filterDestination;

  /// No description provided for @filterCompanion.
  ///
  /// In en, this message translates to:
  /// **'With who'**
  String get filterCompanion;

  /// No description provided for @filterMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get filterMood;

  /// No description provided for @filterMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get filterMore;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @filterSeeSuggestions.
  ///
  /// In en, this message translates to:
  /// **'See suggestions'**
  String get filterSeeSuggestions;

  /// No description provided for @filterSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get filterSortRating;

  /// No description provided for @filterSortDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get filterSortDistance;

  /// No description provided for @filterSortBudgetLow.
  ///
  /// In en, this message translates to:
  /// **'Price ↑'**
  String get filterSortBudgetLow;

  /// No description provided for @filterSortBudgetHigh.
  ///
  /// In en, this message translates to:
  /// **'Price ↓'**
  String get filterSortBudgetHigh;

  /// No description provided for @filterCuisineArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get filterCuisineArabic;

  /// No description provided for @filterCuisineItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get filterCuisineItalian;

  /// No description provided for @filterCuisineAsian.
  ///
  /// In en, this message translates to:
  /// **'Asian'**
  String get filterCuisineAsian;

  /// No description provided for @filterCuisineAmerican.
  ///
  /// In en, this message translates to:
  /// **'American'**
  String get filterCuisineAmerican;

  /// No description provided for @filterCuisineFastFood.
  ///
  /// In en, this message translates to:
  /// **'Fast Food'**
  String get filterCuisineFastFood;

  /// No description provided for @filterCuisineDesserts.
  ///
  /// In en, this message translates to:
  /// **'Desserts'**
  String get filterCuisineDesserts;

  /// No description provided for @filterCuisineCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get filterCuisineCoffee;

  /// No description provided for @filterCuisineSeafood.
  ///
  /// In en, this message translates to:
  /// **'Seafood'**
  String get filterCuisineSeafood;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editProfileSave;

  /// No description provided for @editProfileUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get editProfileUsername;

  /// No description provided for @editProfileUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a unique username'**
  String get editProfileUsernameHint;

  /// No description provided for @editProfileUsernameRules.
  ///
  /// In en, this message translates to:
  /// **'3-20 chars, letters, numbers and _ only'**
  String get editProfileUsernameRules;

  /// No description provided for @editProfileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get editProfileDisplayName;

  /// No description provided for @editProfileDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get editProfileDisplayNameHint;

  /// No description provided for @editProfileUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get editProfileUsernameTooShort;

  /// No description provided for @editProfileUsernameNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Username not available'**
  String get editProfileUsernameNotAvailable;

  /// No description provided for @editProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get editProfileSaved;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About WAIN'**
  String get aboutTitle;

  /// No description provided for @aboutAppName.
  ///
  /// In en, this message translates to:
  /// **'WAIN'**
  String get aboutAppName;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get aboutVersion;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'WAIN is a smart app for discovering the best places in Palestine. We help you find restaurants and cafes that match your mood and occasion.\n\nWhether you\'re looking for a romantic spot, a family gathering, or a workspace — WAIN will help you make the right choice!'**
  String get aboutDescription;

  /// No description provided for @aboutFeatureDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover nearby places'**
  String get aboutFeatureDiscover;

  /// No description provided for @aboutFeatureOffers.
  ///
  /// In en, this message translates to:
  /// **'Exclusive offers for users'**
  String get aboutFeatureOffers;

  /// No description provided for @aboutFeatureFavorites.
  ///
  /// In en, this message translates to:
  /// **'Save your favorite places'**
  String get aboutFeatureFavorites;

  /// No description provided for @aboutFeatureNavigation.
  ///
  /// In en, this message translates to:
  /// **'Direct navigation to venue'**
  String get aboutFeatureNavigation;

  /// No description provided for @dashboardRefreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Performance updated • Views: {views} • Calls: {calls} • Navigation: {navs}'**
  String dashboardRefreshSuccess(String views, String calls, String navs);

  /// No description provided for @dashboardRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update performance: {error}'**
  String dashboardRefreshFailed(String error);

  /// No description provided for @dashboardErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Account not linked as merchant correctly. Open the invite code and re-link.'**
  String get dashboardErrorPermission;

  /// No description provided for @dashboardErrorIndex.
  ///
  /// In en, this message translates to:
  /// **'Missing Firestore analytics index. Deploy firestore:indexes.'**
  String get dashboardErrorIndex;

  /// No description provided for @dashboardErrorNoVenue.
  ///
  /// In en, this message translates to:
  /// **'No venue linked to this account. Link your venue first then retry.'**
  String get dashboardErrorNoVenue;

  /// No description provided for @dashboardErrorUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Please log in again before refreshing.'**
  String get dashboardErrorUnauthenticated;

  /// No description provided for @dashboardBusyTimesReady.
  ///
  /// In en, this message translates to:
  /// **'Busy times were refreshed for this venue.'**
  String get dashboardBusyTimesReady;

  /// No description provided for @dashboardBusyTimesReadyDemo.
  ///
  /// In en, this message translates to:
  /// **'Busy times were generated in demo mode for this venue.'**
  String get dashboardBusyTimesReadyDemo;

  /// No description provided for @dashboardBusyTimesPendingHours.
  ///
  /// In en, this message translates to:
  /// **'Busy times are not ready yet: opening hours are incomplete.'**
  String get dashboardBusyTimesPendingHours;

  /// No description provided for @dashboardBusyTimesPendingTimezone.
  ///
  /// In en, this message translates to:
  /// **'Busy times are not ready yet: venue timezone is missing.'**
  String get dashboardBusyTimesPendingTimezone;

  /// No description provided for @dashboardBusyTimesPendingSignals.
  ///
  /// In en, this message translates to:
  /// **'Busy times are not ready yet: more usage signals are needed.'**
  String get dashboardBusyTimesPendingSignals;

  /// No description provided for @dashboardBusyTimesPendingActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Busy times are not ready yet: more active days are needed.'**
  String get dashboardBusyTimesPendingActiveDays;

  /// No description provided for @dashboardBusyTimesPendingGeneric.
  ///
  /// In en, this message translates to:
  /// **'Busy times are not ready yet.'**
  String get dashboardBusyTimesPendingGeneric;

  /// No description provided for @merchantActionFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get merchantActionFeedTitle;

  /// No description provided for @merchantActionRefreshAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Refresh analytics'**
  String get merchantActionRefreshAnalyticsTitle;

  /// No description provided for @merchantActionRefreshAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'Analytics are stale. Last meaningful update was about {hours} hours ago.'**
  String merchantActionRefreshAnalyticsBody(String hours);

  /// No description provided for @merchantActionRefreshAnalyticsCta.
  ///
  /// In en, this message translates to:
  /// **'Refresh now'**
  String get merchantActionRefreshAnalyticsCta;

  /// No description provided for @merchantActionExpiringOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer ending soon'**
  String get merchantActionExpiringOfferTitle;

  /// No description provided for @merchantActionExpiringOfferBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" ends in about {hours} hours.'**
  String merchantActionExpiringOfferBody(String title, String hours);

  /// No description provided for @merchantActionExpiredOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Expired offer'**
  String get merchantActionExpiredOfferTitle;

  /// No description provided for @merchantActionExpiredOfferBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" has expired and may need replacement or archive.'**
  String merchantActionExpiredOfferBody(String title);

  /// No description provided for @merchantActionUnansweredReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews need a reply'**
  String get merchantActionUnansweredReviewsTitle;

  /// No description provided for @merchantActionUnansweredReviewsBody.
  ///
  /// In en, this message translates to:
  /// **'You have {count} reviews older than 24 hours without a merchant reply.'**
  String merchantActionUnansweredReviewsBody(int count);

  /// No description provided for @merchantActionReviewsReplyCta.
  ///
  /// In en, this message translates to:
  /// **'Reply to reviews'**
  String get merchantActionReviewsReplyCta;

  /// No description provided for @merchantActionNoActiveOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Visits without an active offer'**
  String get merchantActionNoActiveOffersTitle;

  /// No description provided for @merchantActionNoActiveOffersBody.
  ///
  /// In en, this message translates to:
  /// **'You had {views} venue views this week with no active offer running.'**
  String merchantActionNoActiveOffersBody(int views);

  /// No description provided for @merchantFreshnessLabel.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get merchantFreshnessLabel;

  /// No description provided for @merchantFreshnessNeverUpdated.
  ///
  /// In en, this message translates to:
  /// **'Not updated yet'**
  String get merchantFreshnessNeverUpdated;

  /// No description provided for @merchantPhotosErrorInline.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String merchantPhotosErrorInline(String error);

  /// No description provided for @merchantStoriesPromote1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get merchantStoriesPromote1Day;

  /// No description provided for @merchantStoriesPromote3Days.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get merchantStoriesPromote3Days;

  /// No description provided for @merchantStoriesPromote7Days.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get merchantStoriesPromote7Days;

  /// No description provided for @merchantStoriesPromotionOption.
  ///
  /// In en, this message translates to:
  /// **'{duration} ({price} {currency})'**
  String merchantStoriesPromotionOption(String duration, String price, String currency);

  /// No description provided for @merchantStoriesRenewPromotion.
  ///
  /// In en, this message translates to:
  /// **'Renew promotion'**
  String get merchantStoriesRenewPromotion;

  /// No description provided for @merchantStoriesPromotionActiveState.
  ///
  /// In en, this message translates to:
  /// **'Promotion active'**
  String get merchantStoriesPromotionActiveState;

  /// No description provided for @merchantStoriesPromotionExpiringState.
  ///
  /// In en, this message translates to:
  /// **'Promotion expiring soon'**
  String get merchantStoriesPromotionExpiringState;

  /// No description provided for @merchantStoriesPromotionExpiredState.
  ///
  /// In en, this message translates to:
  /// **'Promotion ended'**
  String get merchantStoriesPromotionExpiredState;

  /// No description provided for @merchantStoriesPromotionStateWithTime.
  ///
  /// In en, this message translates to:
  /// **'{state} until {dateTime}'**
  String merchantStoriesPromotionStateWithTime(String state, String dateTime);

  /// No description provided for @merchantOffersRenewFeature.
  ///
  /// In en, this message translates to:
  /// **'Renew feature'**
  String get merchantOffersRenewFeature;

  /// No description provided for @merchantOffersFeatureActive.
  ///
  /// In en, this message translates to:
  /// **'Feature is active'**
  String get merchantOffersFeatureActive;

  /// No description provided for @merchantOffersFeatureExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Feature expires soon'**
  String get merchantOffersFeatureExpiringSoon;

  /// No description provided for @merchantOffersFeatureExpired.
  ///
  /// In en, this message translates to:
  /// **'Feature ended'**
  String get merchantOffersFeatureExpired;

  /// No description provided for @merchantOffersFeatureEndedBadge.
  ///
  /// In en, this message translates to:
  /// **'Feature ended'**
  String get merchantOffersFeatureEndedBadge;

  /// No description provided for @merchantOffersExpiredFeatureRenewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This offer has ended, so its feature cannot be renewed.'**
  String get merchantOffersExpiredFeatureRenewUnavailable;

  /// No description provided for @merchantOffersFeatureNeverSet.
  ///
  /// In en, this message translates to:
  /// **'Not featured yet'**
  String get merchantOffersFeatureNeverSet;

  /// No description provided for @questionOccasionTitle.
  ///
  /// In en, this message translates to:
  /// **'The occasion?'**
  String get questionOccasionTitle;

  /// No description provided for @questionMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s the mood today?'**
  String get questionMoodTitle;

  /// No description provided for @questionCuisineTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost done!\nWhat do you want to eat?'**
  String get questionCuisineTitle;

  /// No description provided for @questionCompanionTitle.
  ///
  /// In en, this message translates to:
  /// **'Who are you going with?'**
  String get questionCompanionTitle;

  /// No description provided for @questionStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String questionStepOf(String step, String total);

  /// No description provided for @questionMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get questionMap;

  /// No description provided for @questionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get questionSkip;

  /// No description provided for @optionBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get optionBirthday;

  /// No description provided for @optionAnniversary.
  ///
  /// In en, this message translates to:
  /// **'Anniversary'**
  String get optionAnniversary;

  /// No description provided for @optionMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get optionMeeting;

  /// No description provided for @optionFastFood.
  ///
  /// In en, this message translates to:
  /// **'Quick bite'**
  String get optionFastFood;

  /// No description provided for @optionSoloTime.
  ///
  /// In en, this message translates to:
  /// **'Solo time'**
  String get optionSoloTime;

  /// No description provided for @optionOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor seating'**
  String get optionOutdoor;

  /// No description provided for @optionCouples.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get optionCouples;

  /// No description provided for @optionFamily.
  ///
  /// In en, this message translates to:
  /// **'Family vibes'**
  String get optionFamily;

  /// No description provided for @optionWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get optionWork;

  /// No description provided for @optionChill.
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get optionChill;

  /// No description provided for @optionFun.
  ///
  /// In en, this message translates to:
  /// **'Fun'**
  String get optionFun;

  /// No description provided for @optionPalestinian.
  ///
  /// In en, this message translates to:
  /// **'Palestinian/Levantine'**
  String get optionPalestinian;

  /// No description provided for @optionKhaleeji.
  ///
  /// In en, this message translates to:
  /// **'Gulf'**
  String get optionKhaleeji;

  /// No description provided for @optionItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get optionItalian;

  /// No description provided for @optionAsian.
  ///
  /// In en, this message translates to:
  /// **'Asian'**
  String get optionAsian;

  /// No description provided for @optionDesserts.
  ///
  /// In en, this message translates to:
  /// **'Desserts'**
  String get optionDesserts;

  /// No description provided for @optionCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe/Coffee'**
  String get optionCafe;

  /// No description provided for @optionFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get optionFriends;

  /// No description provided for @optionPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get optionPartner;

  /// No description provided for @optionFamilyKids.
  ///
  /// In en, this message translates to:
  /// **'Family & Kids'**
  String get optionFamilyKids;

  /// No description provided for @optionSolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get optionSolo;

  /// No description provided for @optionBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business meeting'**
  String get optionBusiness;

  /// No description provided for @homeHeading.
  ///
  /// In en, this message translates to:
  /// **'Don\'t know where to go?'**
  String get homeHeading;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let me help you find the best place in 4\nquick questions'**
  String get homeSubtitle;

  /// No description provided for @homeStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get homeStart;

  /// No description provided for @homeNoThanks.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get homeNoThanks;

  /// No description provided for @statsDefaultName.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get statsDefaultName;

  /// No description provided for @dashboard7Days.
  ///
  /// In en, this message translates to:
  /// **'7D'**
  String get dashboard7Days;

  /// No description provided for @dashboard30Days.
  ///
  /// In en, this message translates to:
  /// **'30D'**
  String get dashboard30Days;

  /// No description provided for @tryListError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String tryListError(String error);

  /// No description provided for @authInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number. Must start with +970 or +972'**
  String get authInvalidPhone;

  /// No description provided for @authTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authTooManyAttempts;

  /// No description provided for @authTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timed out. Try again.'**
  String get authTimeout;

  /// No description provided for @authGoogleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign in cancelled'**
  String get authGoogleCancelled;

  /// No description provided for @authGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign in failed'**
  String get authGoogleFailed;

  /// No description provided for @authUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Username must be 3-20 chars (letters, numbers, _)'**
  String get authUsernameInvalid;

  /// No description provided for @authUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username already taken'**
  String get authUsernameTaken;

  /// No description provided for @authInvalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get authInvalidVerificationCode;

  /// No description provided for @authInvalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get authInvalidPhoneNumber;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try later'**
  String get authTooManyRequests;

  /// No description provided for @authSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired. Resend'**
  String get authSessionExpired;

  /// No description provided for @authEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get authEmailAlreadyInUse;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get authInvalidEmail;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password too weak'**
  String get authWeakPassword;

  /// No description provided for @authUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account with this email'**
  String get authUserNotFound;

  /// No description provided for @authWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get authWrongPassword;

  /// No description provided for @authInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get authInvalidCredential;

  /// No description provided for @authPopupBlocked.
  ///
  /// In en, this message translates to:
  /// **'Sign-in popup was blocked. Allow popups and try again'**
  String get authPopupBlocked;

  /// No description provided for @authUnauthorizedDomain.
  ///
  /// In en, this message translates to:
  /// **'This domain is not authorized for Google sign in. Add localhost to Authorized domains'**
  String get authUnauthorizedDomain;

  /// No description provided for @authGoogleProviderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Google sign in is not enabled in Firebase Auth'**
  String get authGoogleProviderDisabled;

  /// No description provided for @authWebPopupUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This browser or environment does not support the Google sign-in popup'**
  String get authWebPopupUnsupported;

  /// No description provided for @authNetworkFailed.
  ///
  /// In en, this message translates to:
  /// **'Network request failed. Check your connection and try again'**
  String get authNetworkFailed;

  /// No description provided for @authWebStorageUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Browser storage or cookies are blocked. Allow them and try again'**
  String get authWebStorageUnsupported;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Try again'**
  String get authGenericError;

  /// No description provided for @inviteLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'You must sign in first'**
  String get inviteLoginRequired;

  /// No description provided for @inviteSuccess.
  ///
  /// In en, this message translates to:
  /// **'🎉 Merchant account activated successfully!'**
  String get inviteSuccess;

  /// No description provided for @inviteActivationFailed.
  ///
  /// In en, this message translates to:
  /// **'Activation failed'**
  String get inviteActivationFailed;

  /// No description provided for @inviteUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get inviteUnexpectedError;

  /// No description provided for @inviteInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid invite code'**
  String get inviteInvalidCode;

  /// No description provided for @inviteAppCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'App security check failed. Update the app or contact support.'**
  String get inviteAppCheckFailed;

  /// No description provided for @inviteCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired'**
  String get inviteCodeExpired;

  /// No description provided for @inviteCodeUsed.
  ///
  /// In en, this message translates to:
  /// **'This code is already used'**
  String get inviteCodeUsed;

  /// No description provided for @inviteCodeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cannot use this code at this time'**
  String get inviteCodeUnavailable;

  /// No description provided for @inviteRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Rate limit exceeded. Please try later.'**
  String get inviteRateLimited;

  /// No description provided for @inviteAborted.
  ///
  /// In en, this message translates to:
  /// **'Problem with invite code. Please contact support.'**
  String get inviteAborted;

  /// No description provided for @inviteUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'You must sign in'**
  String get inviteUnauthenticated;

  /// No description provided for @inviteConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error occurred'**
  String get inviteConnectionError;

  /// No description provided for @inviteRetryError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Try again.'**
  String get inviteRetryError;

  /// No description provided for @merchantValidationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get merchantValidationUnknown;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection'**
  String get errNetwork;

  /// No description provided for @errServer.
  ///
  /// In en, this message translates to:
  /// **'Server issue, try again'**
  String get errServer;

  /// No description provided for @errNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results, try adjusting filters'**
  String get errNoResults;

  /// No description provided for @errVenueNotFound.
  ///
  /// In en, this message translates to:
  /// **'Venue not found or deleted'**
  String get errVenueNotFound;

  /// No description provided for @errLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Enable location for better results'**
  String get errLocationPermission;

  /// No description provided for @errAuthInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get errAuthInvalidCode;

  /// No description provided for @errAuthSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired, request a new one'**
  String get errAuthSessionExpired;

  /// No description provided for @errAuthTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts, try later'**
  String get errAuthTooMany;

  /// No description provided for @errAuthInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get errAuthInvalidPhone;

  /// No description provided for @errAuthGeneric.
  ///
  /// In en, this message translates to:
  /// **'Verification error occurred'**
  String get errAuthGeneric;

  /// No description provided for @errCache.
  ///
  /// In en, this message translates to:
  /// **'Could not read local data'**
  String get errCache;

  /// No description provided for @errReview.
  ///
  /// In en, this message translates to:
  /// **'Review submission failed, try again'**
  String get errReview;

  /// No description provided for @errOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer action failed, try again'**
  String get errOffer;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out, try again'**
  String get errTimeout;

  /// No description provided for @busyTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Typical busy times'**
  String get busyTimesTitle;

  /// No description provided for @busyTimesDataPreliminary.
  ///
  /// In en, this message translates to:
  /// **'Preliminary data'**
  String get busyTimesDataPreliminary;

  /// No description provided for @busyTimesBasedOnUsage.
  ///
  /// In en, this message translates to:
  /// **'Based on usage signals during the last 30 days'**
  String get busyTimesBasedOnUsage;

  /// No description provided for @busyTimesQuietNow.
  ///
  /// In en, this message translates to:
  /// **'Usually quiet now'**
  String get busyTimesQuietNow;

  /// No description provided for @busyTimesMediumNow.
  ///
  /// In en, this message translates to:
  /// **'Usually moderately busy now'**
  String get busyTimesMediumNow;

  /// No description provided for @busyTimesBusyNow.
  ///
  /// In en, this message translates to:
  /// **'Usually busy now'**
  String get busyTimesBusyNow;

  /// No description provided for @busyTimesBestVisitWindow.
  ///
  /// In en, this message translates to:
  /// **'Best visit window is usually {window}'**
  String busyTimesBestVisitWindow(String window);

  /// No description provided for @transportTitle.
  ///
  /// In en, this message translates to:
  /// **'Waselni'**
  String get transportTitle;

  /// No description provided for @transportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the ride cost to this venue before you go'**
  String get transportSubtitle;

  /// No description provided for @transportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get transportComingSoon;

  /// No description provided for @transportCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Your current location'**
  String get transportCurrentLocation;

  /// No description provided for @transportCityFallback.
  ///
  /// In en, this message translates to:
  /// **'City center estimate'**
  String get transportCityFallback;

  /// No description provided for @transportShowOptions.
  ///
  /// In en, this message translates to:
  /// **'Show transport options'**
  String get transportShowOptions;

  /// No description provided for @transportLocationWarning.
  ///
  /// In en, this message translates to:
  /// **'Your current location is unavailable. Prices are estimated from the city center and may change.'**
  String get transportLocationWarning;

  /// No description provided for @transportOpenNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start navigation yourself'**
  String get transportOpenNavigation;

  /// No description provided for @transportRefreshQuotes.
  ///
  /// In en, this message translates to:
  /// **'Refresh quotes'**
  String get transportRefreshQuotes;

  /// No description provided for @transportCheapest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get transportCheapest;

  /// No description provided for @transportFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get transportFastest;

  /// No description provided for @transportPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get transportPriceLabel;

  /// No description provided for @transportEtaLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup ETA'**
  String get transportEtaLabel;

  /// No description provided for @transportTripLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get transportTripLabel;

  /// No description provided for @transportPriceEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated price'**
  String get transportPriceEstimate;

  /// No description provided for @transportQuoteExpired.
  ///
  /// In en, this message translates to:
  /// **'This quote expired. Refresh prices and try again.'**
  String get transportQuoteExpired;

  /// No description provided for @transportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This transport option is not available right now.'**
  String get transportUnavailable;

  /// No description provided for @transportStartHandoff.
  ///
  /// In en, this message translates to:
  /// **'Continue with partner'**
  String get transportStartHandoff;

  /// No description provided for @transportNoCoverage.
  ///
  /// In en, this message translates to:
  /// **'No transport is currently available for this venue'**
  String get transportNoCoverage;

  /// No description provided for @transportLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transport options'**
  String get transportLoadFailed;

  /// No description provided for @transportHandoffFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start the transport handoff'**
  String get transportHandoffFailed;

  /// No description provided for @transportRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many transport requests. Try again shortly.'**
  String get transportRateLimited;

  /// No description provided for @transportTooFar.
  ///
  /// In en, this message translates to:
  /// **'This venue is too far for the current transport range'**
  String get transportTooFar;

  /// No description provided for @transportMinuteShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get transportMinuteShort;

  /// No description provided for @merchantWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'WAIN Credit'**
  String get merchantWalletTitle;

  /// No description provided for @merchantWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get merchantWalletBalance;

  /// No description provided for @merchantWalletTopUp.
  ///
  /// In en, this message translates to:
  /// **'Top-up Request'**
  String get merchantWalletTopUp;

  /// No description provided for @merchantWalletLowBalance.
  ///
  /// In en, this message translates to:
  /// **'Attention! Balance is low, recharge to avoid feature interruption.'**
  String get merchantWalletLowBalance;

  /// No description provided for @merchantWalletStatus.
  ///
  /// In en, this message translates to:
  /// **'Wallet Status'**
  String get merchantWalletStatus;

  /// No description provided for @merchantWalletActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get merchantWalletActive;

  /// No description provided for @merchantWalletSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get merchantWalletSuspended;

  /// No description provided for @merchantWalletClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get merchantWalletClosed;

  /// No description provided for @merchantWalletTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get merchantWalletTransactions;

  /// No description provided for @merchantWalletTopUpRequests.
  ///
  /// In en, this message translates to:
  /// **'Top-up Requests'**
  String get merchantWalletTopUpRequests;

  /// No description provided for @merchantWalletTopUpAmount.
  ///
  /// In en, this message translates to:
  /// **'Requested Amount'**
  String get merchantWalletTopUpAmount;

  /// No description provided for @merchantWalletTopUpProof.
  ///
  /// In en, this message translates to:
  /// **'Transfer Receipt (Optional)'**
  String get merchantWalletTopUpProof;

  /// No description provided for @merchantWalletProofPickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick receipt image'**
  String get merchantWalletProofPickImage;

  /// No description provided for @merchantWalletProofInvalidType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type. Use JPG, PNG, or WEBP.'**
  String get merchantWalletProofInvalidType;

  /// No description provided for @merchantWalletProofTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Receipt image must be less than 5 MB.'**
  String get merchantWalletProofTooLarge;

  /// No description provided for @merchantWalletTopUpRef.
  ///
  /// In en, this message translates to:
  /// **'Transfer Reference (Optional)'**
  String get merchantWalletTopUpRef;

  /// No description provided for @merchantWalletTopUpNote.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get merchantWalletTopUpNote;

  /// No description provided for @merchantWalletTopUpSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get merchantWalletTopUpSubmit;

  /// No description provided for @merchantWalletTopUpAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get merchantWalletTopUpAmountRequired;

  /// No description provided for @merchantWalletTopUpAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get merchantWalletTopUpAmountInvalid;

  /// No description provided for @merchantWalletTopUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Top-up request submitted and pending review'**
  String get merchantWalletTopUpSuccess;

  /// No description provided for @merchantWalletTopUpError.
  ///
  /// In en, this message translates to:
  /// **'❌ Failed to submit request'**
  String get merchantWalletTopUpError;

  /// No description provided for @merchantWalletStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get merchantWalletStatusPending;

  /// No description provided for @merchantWalletStatusCredited.
  ///
  /// In en, this message translates to:
  /// **'Credited'**
  String get merchantWalletStatusCredited;

  /// No description provided for @merchantWalletStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get merchantWalletStatusRejected;

  /// No description provided for @merchantWalletNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No wallet activity yet'**
  String get merchantWalletNoEntries;

  /// No description provided for @merchantWalletTopUpReflected.
  ///
  /// In en, this message translates to:
  /// **'This top-up has already been reflected in your balance'**
  String get merchantWalletTopUpReflected;

  /// No description provided for @merchantWalletRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason: {reason}'**
  String merchantWalletRejectedReason(String reason);

  /// No description provided for @merchantWalletBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance after: {balance} {currency}'**
  String merchantWalletBalanceAfter(String balance, String currency);

  /// No description provided for @merchantWalletNoTopUpRequests.
  ///
  /// In en, this message translates to:
  /// **'No previous top-up requests'**
  String get merchantWalletNoTopUpRequests;

  /// No description provided for @merchantWalletLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load wallet data right now'**
  String get merchantWalletLoadError;

  /// No description provided for @merchantWalletEntryTopUp.
  ///
  /// In en, this message translates to:
  /// **'Balance top-up'**
  String get merchantWalletEntryTopUp;

  /// No description provided for @merchantWalletEntryStoryPromotion.
  ///
  /// In en, this message translates to:
  /// **'Story promotion'**
  String get merchantWalletEntryStoryPromotion;

  /// No description provided for @merchantWalletEntryStoryPromotionDays.
  ///
  /// In en, this message translates to:
  /// **'Story promotion {days} days'**
  String merchantWalletEntryStoryPromotionDays(String days);

  /// No description provided for @merchantWalletEntryGeneric.
  ///
  /// In en, this message translates to:
  /// **'Wallet activity'**
  String get merchantWalletEntryGeneric;

  /// No description provided for @merchantWalletSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet Summary'**
  String get merchantWalletSummaryTitle;

  /// No description provided for @merchantWalletSummaryTotalCredited.
  ///
  /// In en, this message translates to:
  /// **'Total credited: {amount} {currency}'**
  String merchantWalletSummaryTotalCredited(String amount, String currency);

  /// No description provided for @merchantWalletSummaryTotalDebited.
  ///
  /// In en, this message translates to:
  /// **'Total debited: {amount} {currency}'**
  String merchantWalletSummaryTotalDebited(String amount, String currency);

  /// No description provided for @merchantWalletSummaryLast30Debited.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days spent: {amount} {currency}'**
  String merchantWalletSummaryLast30Debited(String amount, String currency);

  /// No description provided for @merchantWalletSummaryMostUsedFeature.
  ///
  /// In en, this message translates to:
  /// **'Most used debit: {feature}'**
  String merchantWalletSummaryMostUsedFeature(String feature);

  /// No description provided for @merchantWalletSummaryOfferPin.
  ///
  /// In en, this message translates to:
  /// **'Offer pin'**
  String get merchantWalletSummaryOfferPin;

  /// No description provided for @adminTopUpReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Top-up Review Queue'**
  String get adminTopUpReviewTitle;

  /// No description provided for @adminTopUpReviewNoAccess.
  ///
  /// In en, this message translates to:
  /// **'You do not have admin access.'**
  String get adminTopUpReviewNoAccess;

  /// No description provided for @adminTopUpReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending top-up requests.'**
  String get adminTopUpReviewEmpty;

  /// No description provided for @adminTopUpReviewLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load top-up review queue.'**
  String get adminTopUpReviewLoadError;

  /// No description provided for @adminTopUpReviewVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get adminTopUpReviewVenue;

  /// No description provided for @adminTopUpReviewRequester.
  ///
  /// In en, this message translates to:
  /// **'Requested by'**
  String get adminTopUpReviewRequester;

  /// No description provided for @adminTopUpReviewCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get adminTopUpReviewCreatedAt;

  /// No description provided for @adminTopUpReviewReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get adminTopUpReviewReference;

  /// No description provided for @adminTopUpReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get adminTopUpReviewNote;

  /// No description provided for @adminTopUpReviewApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminTopUpReviewApprove;

  /// No description provided for @adminTopUpReviewReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminTopUpReviewReject;

  /// No description provided for @adminTopUpReviewRejectNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Rejection note is required'**
  String get adminTopUpReviewRejectNoteRequired;

  /// No description provided for @adminTopUpReviewApproved.
  ///
  /// In en, this message translates to:
  /// **'Top-up request approved'**
  String get adminTopUpReviewApproved;

  /// No description provided for @adminTopUpReviewRejected.
  ///
  /// In en, this message translates to:
  /// **'Top-up request rejected'**
  String get adminTopUpReviewRejected;

  /// No description provided for @adminTopUpReviewActionError.
  ///
  /// In en, this message translates to:
  /// **'Review action failed'**
  String get adminTopUpReviewActionError;

  /// No description provided for @adminWalletAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet Audit'**
  String get adminWalletAuditTitle;

  /// No description provided for @adminWalletAuditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No wallet audit events yet.'**
  String get adminWalletAuditEmpty;

  /// No description provided for @adminWalletAuditEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Audit rows will appear here after the first financial event.'**
  String get adminWalletAuditEmptyHint;

  /// No description provided for @adminWalletAuditFilterType.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get adminWalletAuditFilterType;

  /// No description provided for @adminWalletAuditFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All events'**
  String get adminWalletAuditFilterAll;

  /// No description provided for @adminWalletAuditRequestId.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get adminWalletAuditRequestId;

  /// No description provided for @adminWalletAuditLinkedEntry.
  ///
  /// In en, this message translates to:
  /// **'Linked entry'**
  String get adminWalletAuditLinkedEntry;

  /// No description provided for @adminWalletAuditReversedLabel.
  ///
  /// In en, this message translates to:
  /// **'Reversal'**
  String get adminWalletAuditReversedLabel;

  /// No description provided for @adminWalletAuditReversedTag.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get adminWalletAuditReversedTag;

  /// No description provided for @adminWalletAuditReverseCta.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get adminWalletAuditReverseCta;

  /// No description provided for @adminWalletAuditReverseDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse wallet entry'**
  String get adminWalletAuditReverseDialogTitle;

  /// No description provided for @adminWalletAuditReverseReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get adminWalletAuditReverseReasonLabel;

  /// No description provided for @adminWalletAuditReverseReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason is required'**
  String get adminWalletAuditReverseReasonRequired;

  /// No description provided for @adminWalletAuditReverseAdminNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin note (optional)'**
  String get adminWalletAuditReverseAdminNoteLabel;

  /// No description provided for @adminWalletAuditReverseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm reversal'**
  String get adminWalletAuditReverseConfirm;

  /// No description provided for @adminWalletAuditReverseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Entry reversed successfully'**
  String get adminWalletAuditReverseSuccess;
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
