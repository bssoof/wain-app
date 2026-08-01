// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get venueNotFound => 'Venue not found';

  @override
  String get selectMapApp => 'Choose map app';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get openInWaze => 'Open in Waze';

  @override
  String get call => 'Call';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get navigate => 'Navigate';

  @override
  String get menuNoMatchingResults => 'No matching menu results';

  @override
  String get photoSingle => 'photo';

  @override
  String get photoPlural => 'photos';

  @override
  String get noMenuAvailable => 'No menu is available right now';

  @override
  String get menuLoadFailed => 'Failed to load menu right now';

  @override
  String get importantNotice => 'Important notice';

  @override
  String get offerValidTenMinutes => 'This offer is valid for only 10 minutes!';

  @override
  String get offerActivationWarning => 'Please do not activate the offer unless you are inside the venue and in front of the cashier.\\n\\nOnce activated, the timer will start and cannot be stopped.';

  @override
  String get cancel => 'Cancel';

  @override
  String get activateOfferNow => 'Activate offer now';

  @override
  String get errorPrefix => 'Error';

  @override
  String get claimRequestFailed => 'Failed to submit claim';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get meterUnit => 'm';

  @override
  String get kilometerUnit => 'km';

  @override
  String distanceAway(String distance) {
    return '$distance away';
  }

  @override
  String get detectingLocation => 'Detecting location...';

  @override
  String get failedToDetectLocation => 'Failed to detect location';

  @override
  String get menuItemCounter => 'items';

  @override
  String get menuTitle => 'Menu';

  @override
  String get menuViewFull => 'View full menu';

  @override
  String get searchInMenuHint => 'Search in menu...';

  @override
  String get featuredItems => 'Featured items';

  @override
  String get all => 'All';

  @override
  String get offersAvailable => 'Available offers';

  @override
  String get offersLoadFailed => 'Failed to load offers';

  @override
  String get noOffersNow => 'No offers currently available';

  @override
  String get followForNewOffers => 'Follow us for new offers';

  @override
  String get venueOffersAllTitle => 'All offers';

  @override
  String get venueOffersAvailableNow => 'Available now';

  @override
  String get venueOffersPreviouslyUsed => 'Previously used';

  @override
  String venueOffersViewAll(int count) {
    return 'View all offers ($count)';
  }

  @override
  String get hoursTitle => 'Working hours';

  @override
  String get closed => 'Closed';

  @override
  String get openNow => 'Open';

  @override
  String get open24Hours => 'Open 24 hours';

  @override
  String get dayMonday => 'Monday';

  @override
  String get dayTuesday => 'Tuesday';

  @override
  String get dayWednesday => 'Wednesday';

  @override
  String get dayThursday => 'Thursday';

  @override
  String get dayFriday => 'Friday';

  @override
  String get daySaturday => 'Saturday';

  @override
  String get daySunday => 'Sunday';

  @override
  String get generalCategory => 'General';

  @override
  String get socialLinks => 'Social links';

  @override
  String get tryListAdded => 'Added to try list';

  @override
  String get venueStories => 'Venue stories';

  @override
  String get video => 'Video';

  @override
  String get story => 'Story';

  @override
  String get partnerBadge => 'Partner';

  @override
  String get offerDetails => 'Offer details';

  @override
  String get getOffer => 'Get offer';

  @override
  String get needConnection => 'Connection needed';

  @override
  String get offlineBannerCachedCopy => 'You\'re offline — showing the latest saved copy';

  @override
  String get offlineBannerUpdateFailed => 'Couldn\'t update data — showing the latest saved copy';

  @override
  String get offlineScreenRequiresConnection => 'You\'re offline — this screen needs an internet connection';

  @override
  String get offlineActionRequiresConnection => 'This action needs an internet connection';

  @override
  String get offlineEmptyTitle => 'No internet connection';

  @override
  String get offlineEmptySubtitle => 'Connect to the internet to view this content';

  @override
  String get offlineScreenUnavailableSubtitle => 'This screen does not work offline in the current version.';

  @override
  String get merchantStoriesOfflineTitle => 'Story management needs an internet connection';

  @override
  String get merchantMenuOfflineTitle => 'Menu management needs an internet connection';

  @override
  String get offlineAgeNow => 'Just now';

  @override
  String offlineAgeMinutes(int count) {
    return '$count minutes ago';
  }

  @override
  String offlineAgeHours(int count) {
    return '$count hours ago';
  }

  @override
  String offlineAgeDays(int count) {
    return '$count days ago';
  }

  @override
  String get tabMenu => 'Menu';

  @override
  String get tabReviews => 'Reviews';

  @override
  String get tabAbout => 'About';

  @override
  String get tabOffersMenu => 'Offers & Menu';

  @override
  String get reviewFormSelectRating => 'Please select a rating';

  @override
  String get reviewFormLoginRequired => 'You must login to add a review';

  @override
  String get reviewFormSuccess => 'Your review was added successfully!';

  @override
  String reviewFormError(String error) {
    return 'Failed to add review: $error';
  }

  @override
  String reviewFormTitlePrefix(String venue) {
    return 'Review $venue';
  }

  @override
  String get reviewFormSubtitle => 'Share your experience with this place';

  @override
  String get reviewFormHint => 'Write your review here (optional)...';

  @override
  String get reviewFormSubmitBtn => 'Submit Review';

  @override
  String get reviewRatingTerrible => 'Terrible';

  @override
  String get reviewRatingPoor => 'Poor';

  @override
  String get reviewRatingGood => 'Good';

  @override
  String get reviewRatingVeryGood => 'Very Good';

  @override
  String get reviewRatingExcellent => 'Excellent!';

  @override
  String get reviewRatingPrompt => 'Choose your rating';

  @override
  String get reviewsSectionTitle => 'Ratings & Reviews';

  @override
  String get reviewsSectionAddBtn => 'Add Review';

  @override
  String get reviewsSectionLoadFail => 'Failed to load reviews';

  @override
  String get reviewsSectionEmptyTitle => 'No reviews yet';

  @override
  String get reviewsSectionEmptySubtitle => 'Be the first to review this place!';

  @override
  String reviewsSectionCountLabel(num count) {
    return '$count reviews';
  }

  @override
  String reviewsSectionViewAllCount(num count) {
    return 'View all reviews ($count)';
  }

  @override
  String get reviewsSectionMerchantReply => 'Owner\'s reply';

  @override
  String get reviewsSectionDeleteTitle => 'Delete Review';

  @override
  String get reviewsSectionDeleteConfirm => 'Are you sure you want to delete your review?';

  @override
  String get reviewsSectionCancel => 'Cancel';

  @override
  String get reviewsSectionDeleteBtn => 'Delete';

  @override
  String reviewsSectionAllTitle(num count) {
    return 'All Reviews ($count)';
  }

  @override
  String get reviewsTimeNow => 'Just now';

  @override
  String reviewsTimeMins(num mins) {
    return '$mins mins ago';
  }

  @override
  String reviewsTimeHours(num hours) {
    return '$hours hours ago';
  }

  @override
  String reviewsTimeDays(num days) {
    return '$days days ago';
  }

  @override
  String reviewsTimeWeeks(num weeks) {
    return '$weeks weeks ago';
  }

  @override
  String get priceLabel => 'Price';

  @override
  String menuShowAll(int count) {
    return 'Show all (+$count)';
  }

  @override
  String get menuShowLess => 'Show less';

  @override
  String menuResultsSummary(int itemsCount, int sectionsCount) {
    return '$itemsCount items in $sectionsCount sections';
  }

  @override
  String get venueSummaryStatus => 'Status';

  @override
  String get venueSummaryDistance => 'Distance';

  @override
  String get venueSummaryClosesAt => 'Closes at';

  @override
  String get venueSummaryPriceRange => 'Price range';

  @override
  String get venueSummaryNotAvailable => 'Not available';

  @override
  String get venueSummaryClosedToday => 'Closed today';

  @override
  String get venueAllFeaturesTitle => 'Venue features';

  @override
  String get venueShowAllFeatures => 'Show all venue features';

  @override
  String get merchantDashboardTitle => 'Merchant Dashboard';

  @override
  String get merchantManageVenue => 'Manage Venue';

  @override
  String get merchantNoVenueLinked => 'No venue linked to your account';

  @override
  String get merchantEnterInvitePrompt => 'Enter invite code to link your venue';

  @override
  String get merchantEnterInviteBtn => 'Enter invite code';

  @override
  String get merchantStats => 'Statistics';

  @override
  String get merchantAnalyticsTitle => 'Analytics';

  @override
  String get merchantAnalyticsOpenDetails => 'Open details';

  @override
  String get merchantAnalyticsViewsThisPeriod => 'Views this period';

  @override
  String get merchantAnalyticsContactIntent => 'Contact intent';

  @override
  String get merchantAnalyticsContactRate => 'Contact rate';

  @override
  String get merchantAnalyticsInsights => 'Insights';

  @override
  String get merchantAnalyticsNoInsights => 'No major changes detected yet.';

  @override
  String get merchantAnalyticsHighlightsTitle => 'Decision highlights';

  @override
  String get merchantAnalyticsDetailTitle => 'Detailed analytics';

  @override
  String get merchantAnalyticsOverviewTitle => 'Overview';

  @override
  String get merchantAnalyticsFunnelTitle => 'Conversion funnel';

  @override
  String get merchantAnalyticsFunnelEmpty => 'Not enough offer activity yet to show a funnel.';

  @override
  String get merchantAnalyticsDemandTrendsTitle => 'Demand trends';

  @override
  String get merchantAnalyticsConversionTrendsTitle => 'Conversion trends';

  @override
  String get merchantAnalyticsTimelineTitle => 'Timeline';

  @override
  String get merchantAnalyticsOfferDetailViews => 'Offer detail views';

  @override
  String get merchantAnalyticsClaimClicks => 'Claim clicks';

  @override
  String get merchantAnalyticsClaimsCreated => 'Claims created';

  @override
  String get merchantAnalyticsRedemptions => 'Redemptions';

  @override
  String get merchantAnalyticsDetailToClickRateShort => 'Detail to click';

  @override
  String get merchantAnalyticsViewToClaimRateShort => 'View to claim';

  @override
  String get merchantAnalyticsClaimToRedemptionRateShort => 'Claim to redemption';

  @override
  String get merchantAnalyticsTopOffersTitle => 'Top offers';

  @override
  String get merchantAnalyticsTopOffersEmpty => 'No offer activity is strong enough for this period yet.';

  @override
  String merchantAnalyticsTopOfferRedemptions(String count) {
    return '$count redemptions';
  }

  @override
  String merchantAnalyticsTopOfferClaims(String count) {
    return '$count claims';
  }

  @override
  String merchantAnalyticsTopOfferConversion(String value) {
    return '$value redemption rate';
  }

  @override
  String merchantAnalyticsDailyAverage(String value) {
    return 'Avg/day $value';
  }

  @override
  String get merchantAnalyticsBestDayLabel => 'Best day';

  @override
  String get merchantAnalyticsWorstDayLabel => 'Slowest day';

  @override
  String get merchantAnalyticsDetailNote => 'This page uses the same analytics data as the dashboard today. Funnel and top-offer drill-down will arrive in a later release.';

  @override
  String get merchantAnalyticsViewsUpTitle => 'Views are up';

  @override
  String merchantAnalyticsViewsUpBody(String percent) {
    return 'Views increased by $percent% compared with the previous period.';
  }

  @override
  String get merchantAnalyticsViewsDownTitle => 'Views are down';

  @override
  String merchantAnalyticsViewsDownBody(String percent) {
    return 'Views dropped by $percent% compared with the previous period.';
  }

  @override
  String get merchantAnalyticsHighContactRateTitle => 'High contact intent';

  @override
  String merchantAnalyticsHighContactRateBody(String percent) {
    return 'Visitors are turning into calls or navigation taps at $percent% this period.';
  }

  @override
  String get merchantAnalyticsLowContactRateTitle => 'Low contact intent';

  @override
  String merchantAnalyticsLowContactRateBody(String percent) {
    return 'Views are not turning into calls or navigation taps yet. Current contact rate is $percent%.';
  }

  @override
  String get merchantAnalyticsStoryBoostTitle => 'Stories are helping';

  @override
  String merchantAnalyticsStoryBoostBody(String percent) {
    return 'Story views equal $percent% of venue views this period.';
  }

  @override
  String get merchantAnalyticsStablePerformanceTitle => 'Stable week';

  @override
  String merchantAnalyticsStablePerformanceBody(String percent) {
    return 'Performance is steady and contact rate is holding around $percent%.';
  }

  @override
  String get merchantAnalyticsDataStaleTitle => 'Data is stale';

  @override
  String merchantAnalyticsDataStaleBody(String hours) {
    return 'Analytics were last refreshed about $hours hours ago.';
  }

  @override
  String get merchantAnalyticsNoRecentDataTitle => 'No recent data';

  @override
  String get merchantAnalyticsNoRecentDataBody => 'There isn\'t enough recent activity yet to draw a useful trend.';

  @override
  String get merchantAnalyticsTrafficUpNoConversionTitle => 'Traffic is rising, conversion is not';

  @override
  String merchantAnalyticsTrafficUpNoConversionBody(String percent, String claims) {
    return 'Views increased by $percent%, but claims stayed low at $claims.';
  }

  @override
  String get merchantAnalyticsContactDropTitle => 'Contact intent dropped';

  @override
  String merchantAnalyticsContactDropBody(String percent) {
    return 'Calls and navigation intent dropped by $percent% versus the previous period.';
  }

  @override
  String get merchantAnalyticsOfferInterestNoRedemptionTitle => 'Offer interest is not converting';

  @override
  String merchantAnalyticsOfferInterestNoRedemptionBody(String claims, String rate) {
    return '$claims claims were created, but redemption is only $rate%.';
  }

  @override
  String get merchantAnalyticsQuietPeriodTitle => 'Quiet period';

  @override
  String get merchantAnalyticsQuietPeriodBody => 'Traffic and conversions are both very low right now.';

  @override
  String get merchantAnalyticsTopOfferConcentratedTitle => 'One offer is carrying most redemptions';

  @override
  String merchantAnalyticsTopOfferConcentratedBody(String share, String redemptions) {
    return 'A single offer is driving $share% of redemptions, with $redemptions redemptions on its own.';
  }

  @override
  String get merchantAnalyticsStoryLiftTitle => 'Stories are lifting traffic';

  @override
  String merchantAnalyticsStoryLiftBody(String percent) {
    return 'Story views grew by $percent% and venue views moved up with them.';
  }

  @override
  String get merchantRating => 'Rating';

  @override
  String get merchantReviewCount => 'Reviews';

  @override
  String get merchantVisitorEngagement => 'Visitor engagement';

  @override
  String get merchantThisWeek => 'This week';

  @override
  String get merchantViews => 'Views';

  @override
  String get merchantCalls => 'Calls';

  @override
  String get merchantNavs => 'Navigation';

  @override
  String get merchantStoryViews => 'Stories';

  @override
  String merchantTotalLabel(int total) {
    return 'Total: $total';
  }

  @override
  String get merchantTrends => 'Performance trends';

  @override
  String get merchantNoTrendData => 'Not enough data to display trends yet';

  @override
  String get merchantTrendLoadFailed => 'Failed to load trend data';

  @override
  String get merchantNoChartActivity => 'Not enough activity to display chart';

  @override
  String merchantBestDay(String dateKey, int views) {
    return 'Best day: $dateKey • $views views';
  }

  @override
  String merchantViewsLast(String range) {
    return 'Views last $range';
  }

  @override
  String merchantCallsLast(String range) {
    return 'Calls last $range';
  }

  @override
  String merchantNavsLast(String range) {
    return 'Navigation last $range';
  }

  @override
  String get merchantViewsWow => 'Views WoW';

  @override
  String get merchantCallsWow => 'Calls WoW';

  @override
  String get merchantNavsWow => 'Navigation WoW';

  @override
  String get merchantRecentReviews => 'Recent reviews';

  @override
  String get merchantNoReviewsYet => 'No reviews yet';

  @override
  String get merchantDefaultUser => 'User';

  @override
  String get merchantOffers => 'Offers';

  @override
  String get merchantNoOffersNow => 'No offers right now';

  @override
  String get merchantDefaultOfferTitle => 'Offer';

  @override
  String get merchantVenueInfo => 'Venue info';

  @override
  String get merchantInfoName => 'Name';

  @override
  String get merchantInfoCity => 'City';

  @override
  String get merchantInfoPhone => 'Phone';

  @override
  String get merchantInfoCategory => 'Category';

  @override
  String get merchantOpenNow => 'Open now';

  @override
  String get merchantClosed => 'Closed';

  @override
  String get merchantDefaultVenueName => 'Venue name';

  @override
  String get merchantDefaultType => 'Restaurant';

  @override
  String merchantErrorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String merchantRefreshSuccess(int views, int calls, int navs) {
    return 'Performance data updated • Views: $views • Calls: $calls • Navs: $navs';
  }

  @override
  String merchantRefreshFailed(String error) {
    return 'Failed to update performance data: $error';
  }

  @override
  String get merchantBackfillPermissionDenied => 'Account not properly linked as merchant. Re-enter invite code.';

  @override
  String get merchantBackfillMissingIndex => 'Missing Firestore analytics index. Deploy firestore:indexes.';

  @override
  String get merchantBackfillNoVenue => 'No venue linked to this account. Link venue first then retry.';

  @override
  String get merchantBackfillUnauthenticated => 'Please sign in again before refreshing.';

  @override
  String merchantBackfillDefaultError(String message) {
    return 'Failed to update performance data: $message';
  }

  @override
  String get merchantQuickActionScan => 'QR Scanner';

  @override
  String get merchantQuickActionEdit => 'Edit Info';

  @override
  String get merchantQuickActionOffers => 'Manage Offers';

  @override
  String get merchantQuickActionPhotos => 'Venue Photos';

  @override
  String get merchantQuickActionReviews => 'Reviews';

  @override
  String get merchantQuickActionMenu => 'Menu';

  @override
  String get merchantQuickActionHours => 'Working Hours';

  @override
  String get merchantQuickActionStories => 'Stories';

  @override
  String get merchantContentHealthTitle => 'Content Health';

  @override
  String get merchantContentHealthLoadFailed => 'Couldn\'t load content health right now.';

  @override
  String get merchantContentHealthHealthyTitle => 'Content looks healthy';

  @override
  String get merchantContentHealthHealthyMessage => 'Your menu, photos, stories, hours, and venue info are all in good shape.';

  @override
  String get merchantContentHealthMenuTitle => 'Menu';

  @override
  String get merchantContentHealthPhotosTitle => 'Photos';

  @override
  String get merchantContentHealthStoriesTitle => 'Stories';

  @override
  String get merchantContentHealthHoursTitle => 'Hours';

  @override
  String get merchantContentHealthProfileTitle => 'Profile';

  @override
  String get merchantContentHealthMenuMissing => 'No published menu is available right now.';

  @override
  String merchantContentHealthMenuStale(String days) {
    return 'The menu was last published $days days ago.';
  }

  @override
  String merchantContentHealthPhotosCritical(String count) {
    return 'Only $count photos are available. Add more to improve the venue page.';
  }

  @override
  String merchantContentHealthPhotosWarning(String count) {
    return 'You only have $count photos. Add a few more to improve the listing.';
  }

  @override
  String merchantContentHealthStoriesCritical(String days) {
    return 'No active story is available, and the last publish was $days days ago.';
  }

  @override
  String merchantContentHealthStoriesWarning(String days) {
    return 'The last story was published $days days ago.';
  }

  @override
  String get merchantContentHealthHoursCritical => 'Add working hours so customers know when to visit.';

  @override
  String merchantContentHealthHoursWarning(String count) {
    return 'Hours are complete for only $count days.';
  }

  @override
  String merchantContentHealthProfileCritical(String count) {
    return 'The profile is missing $count required fields.';
  }

  @override
  String merchantContentHealthProfileWarning(String count) {
    return 'The profile is missing just $count field.';
  }

  @override
  String get merchantDays7 => '7 days';

  @override
  String get merchantDays30 => '30 days';

  @override
  String get merchantPhotosTitle => 'Venue Photos 📸';

  @override
  String get merchantPhotosEmpty => 'No photos yet';

  @override
  String get merchantPhotosAddPrompt => 'Add photos so customers can see your venue!';

  @override
  String get merchantPhotosAddBtn => 'Add Photos';

  @override
  String get merchantPhotosUploading => 'Uploading...';

  @override
  String merchantPhotosUploadSuccess(int count) {
    return '✅ Uploaded $count photos';
  }

  @override
  String merchantPhotosUploadFailed(String error) {
    return '❌ Upload failed: $error';
  }

  @override
  String get merchantPhotosDeleteTitle => 'Delete Photo';

  @override
  String get merchantPhotosDeleteConfirm => 'Are you sure you want to delete this photo?';

  @override
  String get merchantPhotosNo => 'No';

  @override
  String get merchantPhotosYes => 'Yes';

  @override
  String get merchantPhotosSetCover => 'Set as cover';

  @override
  String get merchantPhotosDelete => 'Delete';

  @override
  String get merchantPhotosCoverLabel => 'Cover';

  @override
  String get merchantPhotosCoverSet => '✅ Photo set as cover';

  @override
  String get merchantPhotosNoVenue => 'No venue linked';

  @override
  String merchantPhotosErrorGeneric(String error) {
    return '❌ Error: $error';
  }

  @override
  String get merchantReviewsTitle => 'Reviews 💬';

  @override
  String get merchantReviewsEmpty => 'No reviews yet';

  @override
  String get merchantReviewsFilterAll => 'All';

  @override
  String get merchantReviewsFilterNoReply => 'No reply';

  @override
  String merchantReviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get merchantReviewsNoResults => 'No reviews matching this filter';

  @override
  String get merchantReviewsReplySent => '✅ Reply sent';

  @override
  String get merchantReviewsReplyDeleted => '🗑️ Reply deleted';

  @override
  String get merchantReviewsDeleteReplyTitle => 'Delete reply';

  @override
  String get merchantReviewsDeleteReplyConfirm => 'Are you sure you want to delete your reply?';

  @override
  String get merchantReviewsCancel => 'Cancel';

  @override
  String get merchantReviewsDelete => 'Delete';

  @override
  String get merchantReviewsOwnerReply => 'Owner reply';

  @override
  String get merchantReviewsReplyHint => 'Write your reply...';

  @override
  String get merchantReviewsEdit => 'Edit';

  @override
  String get merchantReviewsDeleteTooltip => 'Delete reply';

  @override
  String get merchantReviewsAddReply => 'Add reply';

  @override
  String get merchantReviewsDefaultUser => 'User';

  @override
  String get merchantReviewsDefaultInitial => '?';

  @override
  String merchantReviewsErrorGeneric(String error) {
    return '❌ Error: $error';
  }

  @override
  String get merchantStoriesTitle => 'Stories 📖';

  @override
  String get merchantStoriesNewStory => 'New Story';

  @override
  String get merchantStoriesError => 'Error';

  @override
  String get merchantStoriesNoVenue => 'No venue linked';

  @override
  String get merchantStoriesEmpty => 'No stories yet';

  @override
  String get merchantStoriesEmptyPrompt => 'Post a story so your customers can see it!';

  @override
  String get merchantStoriesVideo => '🎬 Video';

  @override
  String get merchantStoriesPromoted => 'Promoted';

  @override
  String merchantStoriesPromotedUntil(String dateTime) {
    return 'Promoted until $dateTime';
  }

  @override
  String get merchantStoriesExpired => 'Expired';

  @override
  String get merchantStoriesActive => 'Active';

  @override
  String get merchantStoriesExtendPromo => 'Extend promotion';

  @override
  String get merchantStoriesPromote => 'Promote 🚀';

  @override
  String get merchantStoriesDeleteTooltip => 'Delete';

  @override
  String get merchantStoriesPromoteTitle => 'Promote Story 🚀';

  @override
  String get merchantStoriesPromoteDesc => 'Your story will appear on the home page for all users!';

  @override
  String get merchantStoriesChooseDuration => 'Choose duration:';

  @override
  String get merchantStoriesCancel => 'Cancel';

  @override
  String get merchantStoriesPromoteSuccess => '✅ Story promoted successfully!';

  @override
  String merchantStoriesPromoteError(String error) {
    return '❌ Error: $error';
  }

  @override
  String get merchantStoriesVenueInactive => 'This story can\'t be promoted because the venue is currently inactive.';

  @override
  String get merchantStoriesPricingUnavailable => 'Promotion pricing couldn\'t be loaded right now. Please try again shortly.';

  @override
  String get merchantStoriesInsufficientBalance => 'Your balance is too low to promote this story. Top up WAIN Credit and try again.';

  @override
  String get merchantStoriesWalletMissing => 'This venue doesn\'t have a WAIN Credit wallet yet. Open the wallet and submit a top-up first.';

  @override
  String get merchantStoriesWalletInactive => 'This story can\'t be promoted because the venue wallet is not active right now.';

  @override
  String get merchantStoriesOpenWallet => 'Open WAIN Credit';

  @override
  String get merchantStoriesPromotionConflict => 'This promotion request was already used in a conflicting way. Start a new promotion request.';

  @override
  String get merchantStoriesUnexpectedError => '❌ Unexpected error occurred';

  @override
  String get merchantStoriesDeleteTitle => 'Delete Story';

  @override
  String get merchantStoriesDeleteConfirm => 'Are you sure?';

  @override
  String get merchantStoriesNo => 'No';

  @override
  String get merchantStoriesYes => 'Yes';

  @override
  String get merchantStoriesDeleted => 'Story deleted';

  @override
  String merchantStoriesDeleteFailed(String error) {
    return 'Failed to delete story: $error';
  }

  @override
  String get merchantStoriesPromote1 => '1 Day (\$1)';

  @override
  String get merchantStoriesPromote3 => '3 Days (\$2.5)';

  @override
  String get merchantStoriesPromote7 => '1 Week (\$5)';

  @override
  String get storiesBarTitle => '📢 Venue Stories';

  @override
  String get storiesBarDefaultVenue => 'Venue';

  @override
  String get storiesFeaturedBadge => 'Featured';

  @override
  String storiesFeaturedError(String error) {
    return '⚠️ Error loading featured: $error';
  }

  @override
  String storyViewerVisitVenue(String venue) {
    return 'Visit $venue';
  }

  @override
  String get storyViewerLoadingVideo => 'Loading video...';

  @override
  String get storyViewerSpecialOffer => 'Special Offer!';

  @override
  String get storyViewerOpenAppToActivate => 'Open App to Activate';

  @override
  String storyViewerMinsAgo(num mins) {
    return '${mins}m ago';
  }

  @override
  String storyViewerHoursAgo(num hours) {
    return '${hours}h ago';
  }

  @override
  String get storyViewerYesterday => 'Yesterday';

  @override
  String get merchantStoriesAddContent => 'Add text, image, or video at minimum';

  @override
  String get merchantStoriesPublished => '✅ Story published';

  @override
  String merchantStoriesPublishError(String error) {
    return '❌ Error: $error';
  }

  @override
  String get merchantStoriesNewStoryTitle => 'New Story 📖';

  @override
  String get merchantStoriesPhoto => '📷 Photo';

  @override
  String get merchantStoriesVideoSelected => '✅ Video selected';

  @override
  String get merchantStoriesVideoLimit => '(Max 30 seconds)';

  @override
  String get merchantStoriesTextHint => 'Write your story text...';

  @override
  String get merchantStoriesDuration => 'Story duration:';

  @override
  String get merchantStories24h => '24 hours';

  @override
  String get merchantStories48h => '48 hours';

  @override
  String get merchantStoriesPublishBtn => 'Publish Story';

  @override
  String get savedOffersTitle => 'Saved Offers';

  @override
  String get offerEndingSoon => 'Ending soon';

  @override
  String get offerQrDiscountCode => 'Discount Code';

  @override
  String get offerQrCodeExpired => 'Code expired';

  @override
  String get offerQrValidFor => 'Valid for';

  @override
  String get offerQrRedeemed => 'Offer redeemed';

  @override
  String get offerQrPeriodExpired => 'Validity period expired';

  @override
  String get offerQrShowToCashier => 'Show this code to the cashier';

  @override
  String get offerDetailsRequestFail => 'Failed to submit request';

  @override
  String get offerDetailsRequestFailFallback => 'Failed to submit request';

  @override
  String get offerDetailsUnexpectedError => 'An unexpected error occurred';

  @override
  String get offerDetailsAlreadyUsed => 'This offer has already been used or is unavailable';

  @override
  String get offerDetailsLimitExceeded => 'Usage limit exceeded, try again later';

  @override
  String get offerDetailsNoInternet => 'Check your internet connection';

  @override
  String get offerDetailsLoadFail => 'Failed to load offer';

  @override
  String get offerDetailsNotFound => 'Offer not found';

  @override
  String get offerDetailsVenueLoadFail => 'Failed to load venue data';

  @override
  String get offerDetailsVenueNotFound => 'Venue not found';

  @override
  String get offerDetailsSaveRemoved => 'Unsaved';

  @override
  String get offerDetailsSaved => 'Saved';

  @override
  String get offerDetailsExclusive => 'Exclusive Partner Offer';

  @override
  String get offerDetailsValidity => 'Validity';

  @override
  String get offerDetailsTerms => 'Terms & Conditions';

  @override
  String get myClaimsTitle => 'My Offers';

  @override
  String get myClaimsEmptyTitle => 'No saved offers yet';

  @override
  String get myClaimsEmptyDesc => 'Explore places and get exclusive discounts!';

  @override
  String get myClaimsExploreBtn => 'Explore Map';

  @override
  String get myClaimsStatusUsed => 'Used';

  @override
  String get myClaimsStatusCancelled => 'Cancelled';

  @override
  String get myClaimsStatusActive => 'Active';

  @override
  String offerDiscountPercent(String value) {
    return '$value% Discount';
  }

  @override
  String offerDiscountCurrency(String value, String currency) {
    return '$value $currency Discount';
  }

  @override
  String get offerDiscountFree => 'Free Offer';

  @override
  String get offerValidityAlways => 'Always Available';

  @override
  String get offerValidityExpired => 'Expired';

  @override
  String offerValidityDays(int days) {
    return '$days days left';
  }

  @override
  String offerValidityHours(int hours) {
    return '$hours hours left';
  }

  @override
  String get offerValiditySoon => 'Ending soon';

  @override
  String get offerErrorSaveFailed => 'Failed to save request';

  @override
  String get offerErrorAlreadyUsed => 'You have already used this offer';

  @override
  String get offerErrorExpired => 'This offer has expired and is no longer available';

  @override
  String get offerErrorUnavailable => 'This offer is currently unavailable';

  @override
  String get merchantOffersTitle => 'Manage Offers 🎁';

  @override
  String get merchantOffersNewOffer => 'New Offer';

  @override
  String merchantOffersErrorLoad(String error) {
    return 'Error: $error';
  }

  @override
  String get merchantOffersEmpty => 'No offers yet';

  @override
  String get merchantOffersEmptyPrompt => 'Create your first offer!';

  @override
  String get merchantOffersDefaultTitle => 'Offer';

  @override
  String get merchantOffersEndingSoon => 'Ending soon';

  @override
  String get merchantOffersEdit => 'Edit';

  @override
  String get merchantOffersDeleteMenu => 'Delete';

  @override
  String get merchantOffersActive => 'Active';

  @override
  String get merchantOffersPaused => 'Paused';

  @override
  String get merchantOffersExpired => 'Expired';

  @override
  String get merchantOffersNoDate => 'No date set';

  @override
  String merchantOffersClaims(int count) {
    return '$count interested';
  }

  @override
  String merchantOffersRedeemed(int count) {
    return '$count redeemed';
  }

  @override
  String merchantOffersConversion(String rate) {
    return '$rate% conversion';
  }

  @override
  String get merchantOffersTopPerformerLabel => 'Top performer';

  @override
  String get merchantOffersNoPerformanceData => 'No performance data yet';

  @override
  String get merchantReviewQualityTitle => 'Reply quality';

  @override
  String merchantReviewReplyRate(String rate) {
    return '$rate% reply rate';
  }

  @override
  String merchantReviewAverageReplyHours(String hours) {
    return '${hours}h avg reply';
  }

  @override
  String merchantReviewAverageReplyDays(String days) {
    return '${days}d avg reply';
  }

  @override
  String get merchantReviewAverageReplyUnderOneHour => '<1h avg reply';

  @override
  String get merchantReviewNoReplyDataYet => 'No reply data yet';

  @override
  String merchantReviewOldestUnansweredHours(String hours) {
    return 'Oldest unanswered: ${hours}h';
  }

  @override
  String merchantReviewOldestUnansweredDays(String days) {
    return 'Oldest unanswered: ${days}d';
  }

  @override
  String get merchantReviewOldestUnansweredUnderOneHour => 'Oldest unanswered: <1h';

  @override
  String get merchantOffersDeleteTitle => 'Delete Offer';

  @override
  String get merchantOffersDeleteConfirm => 'Are you sure you want to delete this offer?';

  @override
  String get merchantOffersDeleteSuccess => 'Offer deleted';

  @override
  String merchantOffersDeleteError(String error) {
    return 'Failed to delete offer: $error';
  }

  @override
  String get merchantOffersNo => 'No';

  @override
  String get merchantOffersYesDelete => 'Yes, delete';

  @override
  String merchantOffersDiscountAmount(String value) {
    return '$value ₪ off';
  }

  @override
  String get merchantOffersDiscountFree => 'Free offer';

  @override
  String merchantOffersDiscountPercent(String value) {
    return '$value% off';
  }

  @override
  String get merchantOffersPreviewTitle => 'Offer Preview';

  @override
  String get merchantOffersPreviewClose => 'Close';

  @override
  String get merchantOffersPreviewPublish => 'Publish Offer ✅';

  @override
  String get merchantOffersEditUpdated => '✅ Offer updated';

  @override
  String get merchantOffersCreated => '✅ Offer created';

  @override
  String merchantOffersToggleUpdated(String status) {
    return 'Offer status updated to $status';
  }

  @override
  String merchantOffersToggleError(String error) {
    return 'Failed to update offer status: $error';
  }

  @override
  String get merchantOffersPin => 'Feature offer';

  @override
  String get merchantOffersFeaturedBadge => 'Featured';

  @override
  String merchantOffersFeaturedUntil(String date) {
    return 'Featured until $date';
  }

  @override
  String get merchantOffersPinTitle => 'Feature this offer';

  @override
  String get merchantOffersPinSubtitle => 'Choose duration and price';

  @override
  String merchantOffersPinOption(int days, String amount) {
    return '$days days - $amount ILS';
  }

  @override
  String get merchantOffersPinSuccess => 'Offer featured successfully';

  @override
  String merchantOffersPinError(String error) {
    return 'Failed to feature offer: $error';
  }

  @override
  String get merchantOffersPinInsufficientBalance => 'Insufficient wallet balance to feature this offer';

  @override
  String get merchantOffersPinGoWallet => 'Open wallet';

  @override
  String get merchantOffersPinPricingUnavailable => 'Feature pricing is unavailable right now';

  @override
  String merchantOffersSubmitError(String error) {
    return '❌ Error: $error';
  }

  @override
  String get merchantOffersNoVenueLinked => 'No venue linked to this merchant account.';

  @override
  String get merchantOffersFormEditTitle => 'Edit Offer';

  @override
  String get merchantOffersFormNewTitle => 'New Offer 🎁';

  @override
  String get merchantOffersFieldRequired => 'Required';

  @override
  String get merchantOffersFieldOfferTitle => 'Offer title';

  @override
  String get merchantOffersFieldOfferTitleHint => 'Example: 20% off all orders';

  @override
  String get merchantOffersFieldDescription => 'Offer description';

  @override
  String get merchantOffersFieldDescHint => 'Offer details...';

  @override
  String get merchantOffersFieldDiscountType => 'Discount type';

  @override
  String get merchantOffersTypePercent => 'Percent %';

  @override
  String get merchantOffersTypeAmount => 'Amount ₪';

  @override
  String get merchantOffersTypeFree => 'Free';

  @override
  String get merchantOffersFieldValue => 'Value';

  @override
  String get merchantOffersValueRequired => 'Enter a discount value';

  @override
  String get merchantOffersValueInvalid => 'Enter a valid number';

  @override
  String get merchantOffersValuePositive => 'Discount value must be greater than zero';

  @override
  String get merchantOffersValuePercentRange => 'Percentage discount must be between 1 and 100';

  @override
  String get merchantOffersDurationLabel => '📅 Offer duration';

  @override
  String get merchantOffersStartDate => 'Start';

  @override
  String get merchantOffersEndDate => 'End';

  @override
  String get merchantOffersDateRangeInvalid => 'End date must be after the start date';

  @override
  String get merchantOffersUsageLabel => 'Usage policy';

  @override
  String get merchantOffersUsageHint => 'Choose whether each customer can use this offer once only or on every visit.';

  @override
  String get merchantOffersUsageSingle => 'One time per customer';

  @override
  String get merchantOffersUsageRepeatable => 'Repeatable';

  @override
  String get merchantOffersUsageBadgeSingle => 'One-time';

  @override
  String get merchantOffersUsageBadgeRepeatable => 'Repeatable';

  @override
  String get merchantOffersFieldTerms => 'Terms (optional)';

  @override
  String get merchantOffersFieldTermsHint => 'Example: Offer excludes delivery';

  @override
  String get merchantOffersPreviewBtn => 'Preview';

  @override
  String get merchantOffersSaveChanges => 'Save changes';

  @override
  String get merchantOffersPublish => 'Publish offer';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginSubtitle => 'Sign in to enjoy all WAIN features';

  @override
  String get loginGoogle => 'Sign in with Google';

  @override
  String get loginOr => 'or';

  @override
  String get loginPhoneLabel => 'Phone number';

  @override
  String get loginSendOtp => 'Send verification code';

  @override
  String get loginEmailHint => 'Email';

  @override
  String get loginPasswordHint => 'Password';

  @override
  String get loginEmailBtn => 'Sign In';

  @override
  String get loginNoAccount => 'Don\'t have an account?  ';

  @override
  String get loginCreateAccount => 'Create account';

  @override
  String get loginUsePhone => 'Use phone number';

  @override
  String get loginUseEmail => 'Use email';

  @override
  String get loginContinueGuest => 'Continue as guest';

  @override
  String get loginWelcome => 'Welcome!';

  @override
  String loginWelcomeUser(String name) {
    return 'Welcome $name!';
  }

  @override
  String get loginGoogleFailed => 'Google sign-in failed, please try again';

  @override
  String loginErrorGeneric(String error) {
    return 'Sign-in error: $error';
  }

  @override
  String get loginErrorPhone => 'Please enter your phone number';

  @override
  String get loginErrorEmailPassword => 'Please enter email and password';

  @override
  String get loginErrorUserNotFound => 'No account found with this email';

  @override
  String get loginErrorWrongPassword => 'Incorrect password';

  @override
  String get loginErrorInvalidCredential => 'Invalid email or password';

  @override
  String get loginErrorDefault => 'An error occurred, please try again';

  @override
  String get signupTitle => 'Create New Account';

  @override
  String get signupSubtitle => 'Create your account and enjoy WAIN app features';

  @override
  String get signupNameLabel => 'Full Name';

  @override
  String get signupNameHint => 'Enter your full name';

  @override
  String get signupNameRequired => 'Please enter your name';

  @override
  String get signupEmailLabel => 'Email';

  @override
  String get signupEmailRequired => 'Please enter your email';

  @override
  String get signupEmailInvalid => 'Invalid email address';

  @override
  String get signupPasswordLabel => 'Password';

  @override
  String get signupPasswordRequired => 'Please enter a password';

  @override
  String get signupPasswordWeak => 'Password must be at least 6 characters';

  @override
  String get signupConfirmLabel => 'Confirm Password';

  @override
  String get signupConfirmRequired => 'Please confirm your password';

  @override
  String get signupConfirmMismatch => 'Passwords do not match';

  @override
  String get signupBtn => 'Create Account';

  @override
  String get signupHaveAccount => 'Already have an account?  ';

  @override
  String get signupLogin => 'Sign in';

  @override
  String get signupSuccess => 'Account created successfully! 🎉';

  @override
  String get signupErrorEmailInUse => 'Email already in use';

  @override
  String get signupErrorWeakPassword => 'Password is too weak';

  @override
  String get signupErrorInvalidEmail => 'Invalid email address';

  @override
  String get otpTitle => 'Verification Code';

  @override
  String get otpSentTo => 'Verification code sent to\n';

  @override
  String get otpVerifyBtn => 'Verify';

  @override
  String get otpNotReceived => 'Didn\'t receive the code?  ';

  @override
  String otpResendCountdown(int seconds) {
    return 'Resend ($seconds)';
  }

  @override
  String get otpResend => 'Resend';

  @override
  String get otpChangePhone => 'Change phone number';

  @override
  String get otpInvalid => 'Please enter the 6-digit verification code';

  @override
  String get otpSuccess => 'Signed in successfully!';

  @override
  String get otpResent => 'Verification code resent';

  @override
  String get inviteTitle => 'Join as Merchant';

  @override
  String get inviteEnterCode => 'Enter invite code';

  @override
  String get inviteSubtitle => 'If you own a business, enter the code you received\nto manage your venue from the app';

  @override
  String get inviteCodeEmpty => 'Enter the invite code';

  @override
  String get inviteVerifyBtn => 'Verify code';

  @override
  String get inviteHelpText => 'Don\'t have a code? Contact the WAIN team to register as a merchant.';

  @override
  String get editVenueTitle => 'Edit Venue Info';

  @override
  String editVenueError(String error) {
    return 'Error: $error';
  }

  @override
  String get editVenueNoVenue => 'No venue linked';

  @override
  String get editVenueNameAr => 'Venue name (Arabic)';

  @override
  String get editVenueNameEn => 'Venue name (English)';

  @override
  String get editVenuePhone => 'Phone number';

  @override
  String get editVenueCity => 'City';

  @override
  String get editVenueRequired => 'Required';

  @override
  String get editVenueEditHours => 'Edit working hours';

  @override
  String get editVenueSaveBtn => 'Save changes';

  @override
  String get editVenueSaved => '✅ Changes saved';

  @override
  String editVenueSaveError(String error) {
    return '❌ Save failed: $error';
  }

  @override
  String get hours24hToggle => 'Open 24 hours';

  @override
  String get hours24hSubtitle => 'Venue will always show as \"Open\"';

  @override
  String get hoursScheduleHint => 'Set working hours for each day:';

  @override
  String get hoursSaveBtn => 'Save changes';

  @override
  String get hoursSaved => '✅ Working hours saved';

  @override
  String hoursSaveError(String error) {
    return '❌ Save failed: $error';
  }

  @override
  String get hoursCopyAll => 'Copy to all days';

  @override
  String get hoursAddShift => 'Add shift';

  @override
  String get hoursClosed => 'Closed';

  @override
  String get hoursCopiedAll => 'Hours copied to all days';

  @override
  String get hoursMonday => 'Monday';

  @override
  String get hoursTuesday => 'Tuesday';

  @override
  String get hoursWednesday => 'Wednesday';

  @override
  String get hoursThursday => 'Thursday';

  @override
  String get hoursFriday => 'Friday';

  @override
  String get hoursSaturday => 'Saturday';

  @override
  String get hoursSunday => 'Sunday';

  @override
  String get scanTitle => 'QR Scanner (Merchants)';

  @override
  String get scanRedeemSuccess => '✅ Offer redeemed successfully!';

  @override
  String get scanRedeemError => '❌ Error during redemption';

  @override
  String get scanValidOffer => 'Valid Offer';

  @override
  String get scanInvalidOffer => 'Invalid Offer';

  @override
  String get scanUnnamedOffer => 'Unnamed offer';

  @override
  String get scanUnknownVenue => 'Unknown venue';

  @override
  String scanReasonPrefix(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get scanRedeemBtn => 'Redeem Offer';

  @override
  String get scanMerchantRequired => 'You must be signed in as a merchant to redeem offers';

  @override
  String get scanCancelRescan => 'Cancel / Scan again';

  @override
  String get scanBillAmountLabel => 'Bill total before discount';

  @override
  String scanBillAmountHint(String percent) {
    return 'This is optional for percentage offers. Enter it to record the actual savings from the $percent% discount.';
  }

  @override
  String scanBillAmountField(String currency) {
    return 'Bill amount ($currency)';
  }

  @override
  String get scanBillAmountOptionalHint => 'Leave blank to redeem without recording confirmed savings';

  @override
  String get scanBillAmountHelper => 'If you enter the bill total, Wain will calculate the confirmed savings automatically.';

  @override
  String get scanBillAmountInvalid => 'Enter a valid amount greater than zero and not more than 100000';

  @override
  String get scanBeforeDiscountLabel => 'Before discount';

  @override
  String get scanConfirmedSavingsLabel => 'Confirmed savings';

  @override
  String get scanAfterDiscountLabel => 'After discount';

  @override
  String get menuSectionOther => 'Other';

  @override
  String get menuErrorNotMerchant => 'You must be signed in as merchant.';

  @override
  String get menuDraftPublished => 'Draft published successfully';

  @override
  String menuDraftPublishFailed(String error) {
    return 'Failed to publish draft: $error';
  }

  @override
  String get menuNoArchivedVersions => 'No archived versions available';

  @override
  String get menuSelectArchivedVersion => 'Select archived version';

  @override
  String get menuRollbackSuccess => 'Rollback completed successfully';

  @override
  String menuRollbackFailed(String error) {
    return 'Rollback failed: $error';
  }

  @override
  String get menuNoEditableSections => 'No editable sections in this draft yet.';

  @override
  String get menuManageSections => 'Manage Sections';

  @override
  String get menuAdd => 'Add';

  @override
  String menuReorderFailed(String error) {
    return 'Failed to reorder: $error';
  }

  @override
  String get menuRename => 'Rename';

  @override
  String get menuDelete => 'Delete';

  @override
  String get menuSectionNameHint => 'Section name';

  @override
  String get menuCancel => 'Cancel';

  @override
  String get menuSave => 'Save';

  @override
  String get menuAddSectionTitle => 'Add Section';

  @override
  String get menuSectionAdded => 'Section added';

  @override
  String menuSectionAddFailed(String error) {
    return 'Failed to add section: $error';
  }

  @override
  String get menuRenameSectionTitle => 'Rename Section';

  @override
  String get menuSectionUpdated => 'Section updated';

  @override
  String menuSectionUpdateFailed(String error) {
    return 'Failed to update section: $error';
  }

  @override
  String get menuKeepOneSection => 'Must keep at least one section.';

  @override
  String get menuDeleteSectionTitle => 'Delete Section';

  @override
  String menuDeleteSectionConfirm(String sectionName) {
    return 'Section \"$sectionName\" will be deleted.';
  }

  @override
  String get menuMoveItemsTo => 'Move items to:';

  @override
  String get menuSectionDeleted => 'Section deleted successfully';

  @override
  String menuSectionDeleteFailed(String error) {
    return 'Failed to delete section: $error';
  }

  @override
  String get menuManageMenuTitle => 'Manage Menu';

  @override
  String get menuManageCategoriesTooltip => 'Manage categories';

  @override
  String get menuPublishDraftTooltip => 'Publish draft';

  @override
  String get menuRollbackTooltip => 'Rollback to archived version';

  @override
  String menuError(String error) {
    return 'Error: $error';
  }

  @override
  String get menuNoVenueLinked => 'No merchant venue is linked to this account';

  @override
  String menuDraftPrepareFailed(String error) {
    return 'Failed to prepare draft: $error';
  }

  @override
  String get menuDraftPublishedCreateNew => 'Last draft was published. Create a new draft to continue editing.';

  @override
  String get menuCreateNewDraftBtn => 'Create new draft';

  @override
  String menuSectionsError(String error) {
    return 'Menu sections error: $error';
  }

  @override
  String get menuNoSectionsAvailable => 'No menu sections available';

  @override
  String get menuEditingUnpublishedDraft => 'Editing new unpublished draft';

  @override
  String menuEditingDraftOverActive(String versionId) {
    return 'Editing draft over active version: $versionId';
  }

  @override
  String get menuManageSectionsBtn => 'Manage Sections';

  @override
  String get menuAddSectionBtn => 'Add Section';

  @override
  String get menuEmptyAddFirstItem => 'Menu is currently empty. Add your first item via the + button';

  @override
  String menuNoItemsInSection(String sectionName) {
    return 'No items in section $sectionName';
  }

  @override
  String menuReorderItemsFailed(String error) {
    return 'Failed to reorder items: $error';
  }

  @override
  String menuSaveItemFailed(String error) {
    return 'Failed to save item: $error';
  }

  @override
  String get menuAddItemTitle => 'Add item';

  @override
  String get menuEditItemTitle => 'Edit item';

  @override
  String get menuItemNameLabel => 'Item name';

  @override
  String get menuItemDescLabel => 'Description';

  @override
  String get menuItemPriceLabel => 'Price';

  @override
  String get menuItemAvailableToggle => 'Available';

  @override
  String get menuItemFeaturedToggle => 'Featured';

  @override
  String get menuItemChooseImage => 'Choose image';

  @override
  String get menuItemImageSelected => 'Image selected';

  @override
  String get menuItemSaved => 'Menu item saved';

  @override
  String get menuItemDeleted => 'Menu item deleted';

  @override
  String menuItemAvailabilityFailed(String error) {
    return 'Failed to update item availability: $error';
  }

  @override
  String get brandGoogleMaps => 'Google Maps';

  @override
  String get brandWaze => 'Waze';

  @override
  String get brandAiBadge => 'AI';

  @override
  String hoursLoadError(String error) {
    return 'Error loading hours: $error';
  }

  @override
  String get scanUnknownReason => 'Unknown';

  @override
  String get inviteCodeHint => 'WAIN-XXXXXX';

  @override
  String get loginPhoneHint => '+970599123456';

  @override
  String get signupEmailHint => 'example@email.com';

  @override
  String get signupPasswordPlaceholder => '????????';

  @override
  String get retryButton => 'Try again';

  @override
  String get doubleBackToExitMessage => 'Press back again to exit';

  @override
  String get emptyNoResults => 'No matching results, try adjusting filters';

  @override
  String get emptyNoResultsAction => 'Adjust filters';

  @override
  String get emptyNoFavorites => 'No favorite places yet';

  @override
  String get emptyNoFavoritesAction => 'Explore places';

  @override
  String get emptyNoReviews => 'No reviews yet';

  @override
  String get emptyNoReviewsAction => 'Add review';

  @override
  String get emptyNoSavedOffers => 'No saved offers yet';

  @override
  String get emptyNoSavedOffersAction => 'Browse offers';

  @override
  String get emptyOffline => 'Could not load new data, showing cached version';

  @override
  String get emptyOfflineAction => 'Refresh';

  @override
  String get hoursOpen24 => 'Open 24 hours';

  @override
  String get hoursUnavailable => 'Hours not available';

  @override
  String get hoursUnknown => 'Unknown';

  @override
  String get hoursClosedToday => 'Closed today';

  @override
  String get hoursBadgeOpen => 'Open';

  @override
  String get hoursBadgeClosed => 'Closed';

  @override
  String hoursOpenUntil(String time) {
    return 'Open until $time';
  }

  @override
  String get hoursOpenNow => 'Open now';

  @override
  String hoursOpensAt(String time) {
    return 'Opens at $time';
  }

  @override
  String get hoursPeriodAm => 'AM';

  @override
  String get hoursPeriodPm => 'PM';

  @override
  String get navDialogTitle => 'Navigate to';

  @override
  String get navCancel => 'Cancel';

  @override
  String get cacheUnknown => 'Unknown';

  @override
  String get cacheJustNow => 'Just now';

  @override
  String cacheMinsAgo(int mins) {
    return '$mins min ago';
  }

  @override
  String cacheHoursAgo(int hours) {
    return '$hours hr ago';
  }

  @override
  String cacheDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String distanceMeters(String meters) {
    return '$meters m';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String durationMins(String mins) {
    return '$mins min';
  }

  @override
  String durationHoursMins(String hours, String mins) {
    return '$hours hr $mins min';
  }

  @override
  String geofenceNearby(String venue) {
    return '📍 You\'re near $venue!';
  }

  @override
  String get geofenceOffers => '🎁 Exclusive offers waiting for you!';

  @override
  String get geofenceDiscover => '⭐ Discover this special place';

  @override
  String get shareVenueText => 'Check out this place on WAIN! 🌟';

  @override
  String get errorPageNotFound => 'Page not found';

  @override
  String get errorGoHome => 'Go to home';

  @override
  String get mapNoVenuesInArea => 'No venues in this area currently';

  @override
  String mapFoundVenuesWithOffers(String count, String offers) {
    return 'Found $count venues ($offers offers available 🔥)';
  }

  @override
  String mapFoundVenues(String count) {
    return 'Found $count venues';
  }

  @override
  String get mapSearchError => 'Search error occurred';

  @override
  String get mapBoundsTooLarge => 'Area too large, please zoom in more';

  @override
  String get mapRateLimited => 'Search rate limit exceeded';

  @override
  String get mapNavModeActive => 'Navigation mode active';

  @override
  String get mapSearchHint => 'Search for a place...';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get mapFilterTopRated => 'Top Rated';

  @override
  String get mapFilterExplore => 'Explore';

  @override
  String get mapFilterOpenNow => 'Open Now';

  @override
  String get mapFilterPartners => 'Partners';

  @override
  String get mapFilterOffers => 'Offers';

  @override
  String get mapFilterRestaurants => 'Restaurants';

  @override
  String get mapFilterCafes => 'Cafes';

  @override
  String get mapFilterRomantic => 'Romantic';

  @override
  String get mapFilterFamily => 'Family';

  @override
  String get mapOfflineBanner => 'You are offline - browsing saved version';

  @override
  String get mapOfferAvailable => 'Offer available';

  @override
  String get mapCategoryGeneral => 'General';

  @override
  String get mapGetOfferNow => 'Get the offer now';

  @override
  String get mapDetails => 'Details';

  @override
  String get mapDirections => 'Directions';

  @override
  String mapVenueCount(String count) {
    return '$count venues';
  }

  @override
  String mapDistanceAway(String distance) {
    return '$distance km away';
  }

  @override
  String get mapNeedsConnection => 'Needs connection';

  @override
  String get mapStartNavigation => 'Start Navigation';

  @override
  String get mapRouteFetchFailed => 'Failed to fetch route';

  @override
  String get profileTitle => 'Settings';

  @override
  String get profileSectionActivity => 'My Activity';

  @override
  String get profileMyOffers => 'My Offers';

  @override
  String get profileMyOffersSubtitle => 'Used offers';

  @override
  String get profileSavedOffers => 'Saved Offers';

  @override
  String get profileSavedOffersSubtitle => 'Offers you saved';

  @override
  String get profileMyStats => 'My Stats';

  @override
  String get profileMyStatsSubtitle => 'Your activity summary on WAIN';

  @override
  String get profileTryList => 'Want to try 🎯';

  @override
  String get profileTryListSubtitle => 'Places you want to visit';

  @override
  String get profileAdminTopUpReview => 'Admin top-up review';

  @override
  String get profileAdminTopUpReviewSubtitle => 'Review merchant top-up requests';

  @override
  String get profileMerchantDashboard => 'Merchant Dashboard 📊';

  @override
  String get profileMerchantDashboardSubtitle => 'Manage your shop and stats';

  @override
  String get profileJoinMerchant => 'Join as Merchant';

  @override
  String get profileJoinMerchantSubtitle => 'Have a shop? Enter invite code';

  @override
  String get profileSectionSettings => 'Settings';

  @override
  String get profileCity => 'City';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageAr => 'Arabic';

  @override
  String get profileTheme => 'Theme';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileGeofenceNotifs => 'Proximity Notifications';

  @override
  String get profileGeofenceNotifsSubtitle => 'Alert when near special places';

  @override
  String get profileWalletNotifications => 'Wallet activity notifications';

  @override
  String get profileWalletNotificationsSubtitle => 'Get notified when wallet requests, approvals, reversals, and low-balance events happen';

  @override
  String get profileWalletExpiryReminders => 'Wallet expiry reminders';

  @override
  String get profileWalletExpiryRemindersSubtitle => 'Remind me before story promotions or featured offers expire';

  @override
  String get profileAdminWalletNotifications => 'Admin wallet notifications';

  @override
  String get profileAdminWalletNotificationsSubtitle => 'Get notified about new merchant top-up requests';

  @override
  String get profileSectionAbout => 'About';

  @override
  String get profileAboutWain => 'About WAIN';

  @override
  String get profilePrivacy => 'Privacy Policy';

  @override
  String get profileHelp => 'Help';

  @override
  String profileVersion(String version) {
    return 'Version $version';
  }

  @override
  String get profileMerchantScan => 'Merchant Access (Scan)';

  @override
  String get profileChooseCity => 'Choose City';

  @override
  String get profileUser => 'User';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileGuestUser => 'Guest User';

  @override
  String get profileGuestSubtitle => 'Sign in to save favorites';

  @override
  String get profileSignIn => 'Sign In';

  @override
  String get venueCardBestMatch => 'Best Match';

  @override
  String get venueCardOpen => 'Open';

  @override
  String get venueCardClosed => 'Closed';

  @override
  String get nearbyVenuesTitle => 'Nearby';

  @override
  String get nearbyApproxLocation => 'Approximate location';

  @override
  String get categoryGeneral => 'General';

  @override
  String get statsTitle => 'My Stats';

  @override
  String get statsLoginPrompt => 'Sign in to view your stats';

  @override
  String statsWelcome(String name) {
    return 'Hello $name!';
  }

  @override
  String get statsActivitySummary => 'Your activity summary on WAIN';

  @override
  String get statsUsedOffers => 'Used offers';

  @override
  String get statsConfirmedSavings => 'Confirmed savings';

  @override
  String get statsActiveClaims => 'Active claims';

  @override
  String get statsReviews => 'Reviews';

  @override
  String get statsFavorites => 'Favorites';

  @override
  String get statsSavingsHint => 'These are the confirmed savings from offers where the actual savings were recorded';

  @override
  String get statsAdditionalDiscounts => 'Extra discounts';

  @override
  String statsAdditionalDiscountsSub(int count) {
    return 'You used $count extra percent/free-item offers';
  }

  @override
  String get statsUsedOffersDetails => 'Recently used offers';

  @override
  String get statsNoUsedOffersYet => 'No used offers yet';

  @override
  String get statsNoUsedOffersYetSub => 'Once you redeem your first offer, your benefit details will appear here';

  @override
  String statsUsedOnDate(String date) {
    return 'Used $date';
  }

  @override
  String statsOfferSavingsValue(String amount) {
    return 'Saved $amount';
  }

  @override
  String get statsOfferUsedStatus => 'Used';

  @override
  String get statsRecentActivity => 'Recent Activity';

  @override
  String get statsReviewsReady => 'Reviews feature is ready!';

  @override
  String get statsReviewsReadySub => 'Rate the places you visited';

  @override
  String get statsTimeNow => 'Now';

  @override
  String get statsExploreOffers => 'Explore exclusive offers';

  @override
  String get statsExploreOffersSub => 'New offers every day';

  @override
  String get statsTimeToday => 'Today';

  @override
  String get statsDiscoverPlaces => 'Discover new places';

  @override
  String get statsDiscoverPlacesSub => 'Try asking \"Where should I go?\"';

  @override
  String get statsTimeNew => 'New';

  @override
  String get statsAchievements => 'Achievements';

  @override
  String get statsNewExplorer => 'New Explorer';

  @override
  String get statsReviewer => 'Reviewer';

  @override
  String get statsOfferHunter => 'Offer Hunter';

  @override
  String get statsPlaceLover => 'Place Lover';

  @override
  String get statsWainExpert => 'WAIN Expert';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingWelcomeTitlePrefix => 'Welcome to';

  @override
  String get onboardingWelcomeTitleAccent => 'WAIN!';

  @override
  String get onboardingWelcomeDesc => 'Discover the best restaurants and cafes in Ramallah quickly and easily.';

  @override
  String get onboardingSmartTitlePrefix => 'Use smart';

  @override
  String get onboardingSmartTitleAccent => 'filters!';

  @override
  String get onboardingSmartDesc => 'Choose who you\'re with, your mood, and budget to get ideal results.';

  @override
  String get onboardingDiscountsTitlePrefix => 'Exclusive';

  @override
  String get onboardingDiscountsTitleAccent => 'discounts!';

  @override
  String get onboardingDiscountsDesc => 'Get 10-20% off at all partner restaurants!';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get tryListTitle => 'Want to try 🎯';

  @override
  String tryListMovedToFav(String name) {
    return '✅ $name moved to favorites!';
  }

  @override
  String get tryListUndo => 'Undo';

  @override
  String tryListRemoved(String name) {
    return '🗑️ $name removed from list';
  }

  @override
  String tryListTriedIt(String name) {
    return '🎉 $name tried it! Moved to favorites';
  }

  @override
  String get tryListTriedItBtn => 'Tried it';

  @override
  String get tryListEmptyTitle => 'No places added yet';

  @override
  String get tryListEmptySubtitle => 'Tap 🎯 on any place to add it to your \"Want to try\" list';

  @override
  String get tryListExploreBtn => 'Discover places';

  @override
  String get tryListInfoTitle => '\"Want to try\" list 🎯';

  @override
  String get tryListInfoBody => 'Here you\'ll find places you want to try.\n\n• Tap \"Tried it ✅\" to move to favorites\n• Tap ✕ to remove from list\n• Tap a place to see details';

  @override
  String get tryListInfoDismiss => 'Got it';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpContactUs => 'Contact Us';

  @override
  String get helpEmail => 'Email';

  @override
  String get helpWhatsApp => 'WhatsApp';

  @override
  String get helpFaq => 'FAQ';

  @override
  String get helpFaqOffersQ => 'How do I use offers?';

  @override
  String get helpFaqOffersA => 'Tap any available offer, then tap \"Get Offer\". A QR code will appear that you can show to the merchant within 10 minutes.';

  @override
  String get helpFaqMultiUseQ => 'Can I use an offer more than once?';

  @override
  String get helpFaqMultiUseA => 'Each offer has a specific usage limit. Some offers can only be used once, while others can be used multiple times.';

  @override
  String get helpFaqLocationQ => 'Why doesn\'t my location show?';

  @override
  String get helpFaqLocationA => 'Make sure to allow the app to access your location from phone settings. Go to Settings > Apps > WAIN > Permissions > Location.';

  @override
  String get helpFaqAddPlaceQ => 'How do I add my place to the app?';

  @override
  String get helpFaqAddPlaceA => 'If you own a restaurant or cafe and want to join, contact us via email and we\'ll add your place.';

  @override
  String get helpFaqFreeQ => 'Is the app free?';

  @override
  String get helpFaqFreeA => 'Yes! The app is completely free for users. We work with partners to provide the best offers for you.';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get privacyLastUpdate => 'Last updated: February 2026';

  @override
  String get privacySection1Title => '1. Information We Collect';

  @override
  String get privacySection1Body => '• Location information to show nearby places\n• Device ID to identify your account\n• Favorite places and used offers\n• Usage statistics to improve the app';

  @override
  String get privacySection2Title => '2. How We Use Your Information';

  @override
  String get privacySection2Body => '• Provide personalized place recommendations\n• Show available offers in your area\n• Improve user experience\n• Communicate with you about new offers';

  @override
  String get privacySection3Title => '3. Information Sharing';

  @override
  String get privacySection3Body => 'We do not sell or share your personal information with third parties except in the following cases:\n• With your explicit consent\n• To comply with laws and regulations\n• To protect our rights or property';

  @override
  String get privacySection4Title => '4. Data Security';

  @override
  String get privacySection4Body => 'We use advanced encryption technologies to protect your data. All data is stored on secure Firebase servers.';

  @override
  String get privacySection5Title => '5. Your Rights';

  @override
  String get privacySection5Body => '• You can request deletion of your data at any time\n• You can disable location services from settings\n• You can contact us for any inquiries';

  @override
  String get privacySection6Title => '6. Contact Us';

  @override
  String get privacySection6Body => 'For privacy policy inquiries:\nEmail: privacy@wain.app';

  @override
  String get notificationsTitle => 'Notifications 🔔';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String notificationsError(String error) {
    return 'Error: $error';
  }

  @override
  String get notificationsEmpty => 'No notifications at the moment';

  @override
  String get notificationsNewNotif => 'New notification';

  @override
  String get notificationsHintReview => 'Tap to open reviews and respond quickly';

  @override
  String get notificationsHintOffer => 'Tap to open offers and track performance';

  @override
  String get notificationsHintWelcome => 'Tap to open merchant dashboard';

  @override
  String get notificationsHintWallet => 'Tap to open wallet details and recent activity';

  @override
  String get notificationsHintAdminTopup => 'Tap to review pending top-up requests';

  @override
  String get notificationsHintWalletStoryExpiry => 'Tap to review promoted stories before they expire';

  @override
  String get notificationsHintWalletOfferExpiry => 'Tap to review featured offers before they expire';

  @override
  String get resultsSuggestions => 'Our Suggestions';

  @override
  String get resultsBestMatch => 'Best Match';

  @override
  String get resultsBestMatchSub => 'Based on your choices';

  @override
  String get resultsChangeChoices => 'Change choices';

  @override
  String get resultsStatsShowMore => 'Show more';

  @override
  String resultsCount(int count) {
    return '$count results';
  }

  @override
  String resultsSortedBy(String sort) {
    return 'Sorted by $sort';
  }

  @override
  String get resultsNavAccount => 'Account';

  @override
  String get resultsNavSettings => 'Settings';

  @override
  String get resultsNavSuggestions => 'Suggestions';

  @override
  String get resultsNavStats => 'Stats';

  @override
  String get resultsNavFavorites => 'Favorites';

  @override
  String get resultsNavMap => 'Map';

  @override
  String get filterTitle => 'Filter & Sort';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterBudgetRange => 'Budget per person';

  @override
  String get filterBudgetQuestion => 'What\'s your budget today?';

  @override
  String get filterBudgetMin => 'Minimum';

  @override
  String get filterBudgetMax => 'Maximum';

  @override
  String get filterBudgetInvalid => 'Enter a valid price';

  @override
  String get filterBudgetInvalidRange => 'Minimum price must be less than maximum';

  @override
  String get filterPreResultsHint => 'Before we show suggestions, adjust your budget and key filters';

  @override
  String get filterSortBy => 'Sort by';

  @override
  String get filterCuisineType => 'Cuisine type';

  @override
  String get filterDestination => 'Going for';

  @override
  String get filterCompanion => 'With who';

  @override
  String get filterMood => 'Mood';

  @override
  String get filterMore => 'More';

  @override
  String get filterApply => 'Apply';

  @override
  String get filterSeeSuggestions => 'See suggestions';

  @override
  String get filterSortRating => 'Rating';

  @override
  String get filterSortDistance => 'Distance';

  @override
  String get filterSortBudgetLow => 'Price ↑';

  @override
  String get filterSortBudgetHigh => 'Price ↓';

  @override
  String get filterCuisineArabic => 'Arabic';

  @override
  String get filterCuisineItalian => 'Italian';

  @override
  String get filterCuisineAsian => 'Asian';

  @override
  String get filterCuisineAmerican => 'American';

  @override
  String get filterCuisineFastFood => 'Fast Food';

  @override
  String get filterCuisineDesserts => 'Desserts';

  @override
  String get filterCuisineCoffee => 'Coffee';

  @override
  String get filterCuisineSeafood => 'Seafood';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileSave => 'Save';

  @override
  String get editProfileUsername => 'Username';

  @override
  String get editProfileUsernameHint => 'Choose a unique username';

  @override
  String get editProfileUsernameRules => '3-20 chars, letters, numbers and _ only';

  @override
  String get editProfileDisplayName => 'Display Name';

  @override
  String get editProfileDisplayNameHint => 'Enter your name';

  @override
  String get editProfileUsernameTooShort => 'Username must be at least 3 characters';

  @override
  String get editProfileUsernameNotAvailable => 'Username not available';

  @override
  String get editProfileSaved => 'Changes saved';

  @override
  String get aboutTitle => 'About WAIN';

  @override
  String get aboutAppName => 'WAIN';

  @override
  String get aboutVersion => 'Version 1.0.0';

  @override
  String get aboutDescription => 'WAIN is a smart app for discovering the best places in Palestine. We help you find restaurants and cafes that match your mood and occasion.\n\nWhether you\'re looking for a romantic spot, a family gathering, or a workspace — WAIN will help you make the right choice!';

  @override
  String get aboutFeatureDiscover => 'Discover nearby places';

  @override
  String get aboutFeatureOffers => 'Exclusive offers for users';

  @override
  String get aboutFeatureFavorites => 'Save your favorite places';

  @override
  String get aboutFeatureNavigation => 'Direct navigation to venue';

  @override
  String dashboardRefreshSuccess(String views, String calls, String navs) {
    return 'Performance updated • Views: $views • Calls: $calls • Navigation: $navs';
  }

  @override
  String dashboardRefreshFailed(String error) {
    return 'Failed to update performance: $error';
  }

  @override
  String get dashboardErrorPermission => 'Account not linked as merchant correctly. Open the invite code and re-link.';

  @override
  String get dashboardErrorIndex => 'Missing Firestore analytics index. Deploy firestore:indexes.';

  @override
  String get dashboardErrorNoVenue => 'No venue linked to this account. Link your venue first then retry.';

  @override
  String get dashboardErrorUnauthenticated => 'Please log in again before refreshing.';

  @override
  String get dashboardBusyTimesReady => 'Busy times were refreshed for this venue.';

  @override
  String get dashboardBusyTimesReadyDemo => 'Busy times were generated in demo mode for this venue.';

  @override
  String get dashboardBusyTimesPendingHours => 'Busy times are not ready yet: opening hours are incomplete.';

  @override
  String get dashboardBusyTimesPendingTimezone => 'Busy times are not ready yet: venue timezone is missing.';

  @override
  String get dashboardBusyTimesPendingSignals => 'Busy times are not ready yet: more usage signals are needed.';

  @override
  String get dashboardBusyTimesPendingActiveDays => 'Busy times are not ready yet: more active days are needed.';

  @override
  String get dashboardBusyTimesPendingGeneric => 'Busy times are not ready yet.';

  @override
  String get merchantActionFeedTitle => 'Needs attention';

  @override
  String get merchantActionRefreshAnalyticsTitle => 'Refresh analytics';

  @override
  String merchantActionRefreshAnalyticsBody(String hours) {
    return 'Analytics are stale. Last meaningful update was about $hours hours ago.';
  }

  @override
  String get merchantActionRefreshAnalyticsCta => 'Refresh now';

  @override
  String get merchantActionExpiringOfferTitle => 'Offer ending soon';

  @override
  String merchantActionExpiringOfferBody(String title, String hours) {
    return '\"$title\" ends in about $hours hours.';
  }

  @override
  String get merchantActionExpiredOfferTitle => 'Expired offer';

  @override
  String merchantActionExpiredOfferBody(String title) {
    return '\"$title\" has expired and may need replacement or archive.';
  }

  @override
  String get merchantActionUnansweredReviewsTitle => 'Reviews need a reply';

  @override
  String merchantActionUnansweredReviewsBody(int count) {
    return 'You have $count reviews older than 24 hours without a merchant reply.';
  }

  @override
  String get merchantActionReviewsReplyCta => 'Reply to reviews';

  @override
  String get merchantActionNoActiveOffersTitle => 'Visits without an active offer';

  @override
  String merchantActionNoActiveOffersBody(int views) {
    return 'You had $views venue views this week with no active offer running.';
  }

  @override
  String get merchantFreshnessLabel => 'Last updated';

  @override
  String get merchantFreshnessNeverUpdated => 'Not updated yet';

  @override
  String merchantPhotosErrorInline(String error) {
    return '❌ Error: $error';
  }

  @override
  String get merchantStoriesPromote1Day => '1 day';

  @override
  String get merchantStoriesPromote3Days => '3 days';

  @override
  String get merchantStoriesPromote7Days => '1 week';

  @override
  String merchantStoriesPromotionOption(String duration, String price, String currency) {
    return '$duration ($price $currency)';
  }

  @override
  String get merchantStoriesRenewPromotion => 'Renew promotion';

  @override
  String get merchantStoriesPromotionActiveState => 'Promotion active';

  @override
  String get merchantStoriesPromotionExpiringState => 'Promotion expiring soon';

  @override
  String get merchantStoriesPromotionExpiredState => 'Promotion ended';

  @override
  String merchantStoriesPromotionStateWithTime(String state, String dateTime) {
    return '$state until $dateTime';
  }

  @override
  String get merchantOffersRenewFeature => 'Renew feature';

  @override
  String get merchantOffersFeatureActive => 'Feature is active';

  @override
  String get merchantOffersFeatureExpiringSoon => 'Feature expires soon';

  @override
  String get merchantOffersFeatureExpired => 'Feature ended';

  @override
  String get merchantOffersFeatureEndedBadge => 'Feature ended';

  @override
  String get merchantOffersExpiredFeatureRenewUnavailable => 'This offer has ended, so its feature cannot be renewed.';

  @override
  String get merchantOffersFeatureNeverSet => 'Not featured yet';

  @override
  String get questionOccasionTitle => 'The occasion?';

  @override
  String get questionMoodTitle => 'What\'s the mood today?';

  @override
  String get questionCuisineTitle => 'Almost done!\nWhat do you want to eat?';

  @override
  String get questionCompanionTitle => 'Who are you going with?';

  @override
  String questionStepOf(String step, String total) {
    return 'Step $step of $total';
  }

  @override
  String get questionMap => 'Map';

  @override
  String get questionSkip => 'Skip';

  @override
  String get optionBirthday => 'Birthday';

  @override
  String get optionAnniversary => 'Anniversary';

  @override
  String get optionMeeting => 'Meeting';

  @override
  String get optionFastFood => 'Quick bite';

  @override
  String get optionSoloTime => 'Solo time';

  @override
  String get optionOutdoor => 'Outdoor seating';

  @override
  String get optionCouples => 'Romantic';

  @override
  String get optionFamily => 'Family vibes';

  @override
  String get optionWork => 'Work';

  @override
  String get optionChill => 'Chill';

  @override
  String get optionFun => 'Fun';

  @override
  String get optionPalestinian => 'Palestinian/Levantine';

  @override
  String get optionKhaleeji => 'Gulf';

  @override
  String get optionItalian => 'Italian';

  @override
  String get optionAsian => 'Asian';

  @override
  String get optionDesserts => 'Desserts';

  @override
  String get optionCafe => 'Cafe/Coffee';

  @override
  String get optionFriends => 'Friends';

  @override
  String get optionPartner => 'Partner';

  @override
  String get optionFamilyKids => 'Family & Kids';

  @override
  String get optionSolo => 'Solo';

  @override
  String get optionBusiness => 'Business meeting';

  @override
  String get homeHeading => 'Don\'t know where to go?';

  @override
  String get homeSubtitle => 'Let me help you find the best place in 4\nquick questions';

  @override
  String get homeStart => 'Let\'s go';

  @override
  String get homeNoThanks => 'No thanks';

  @override
  String get statsDefaultName => 'you';

  @override
  String get dashboard7Days => '7D';

  @override
  String get dashboard30Days => '30D';

  @override
  String tryListError(String error) {
    return 'Error: $error';
  }

  @override
  String get authInvalidPhone => 'Invalid phone number. Must start with +970 or +972';

  @override
  String get authTooManyAttempts => 'Too many attempts. Try again later.';

  @override
  String get authTimeout => 'Timed out. Try again.';

  @override
  String get authGoogleCancelled => 'Sign in cancelled';

  @override
  String get authGoogleFailed => 'Google sign in failed';

  @override
  String get authUsernameInvalid => 'Username must be 3-20 chars (letters, numbers, _)';

  @override
  String get authUsernameTaken => 'Username already taken';

  @override
  String get authInvalidVerificationCode => 'Invalid verification code';

  @override
  String get authInvalidPhoneNumber => 'Invalid phone number';

  @override
  String get authTooManyRequests => 'Too many attempts. Try later';

  @override
  String get authSessionExpired => 'Code expired. Resend';

  @override
  String get authEmailAlreadyInUse => 'Email already in use';

  @override
  String get authInvalidEmail => 'Invalid email';

  @override
  String get authWeakPassword => 'Password too weak';

  @override
  String get authUserNotFound => 'No account with this email';

  @override
  String get authWrongPassword => 'Wrong password';

  @override
  String get authInvalidCredential => 'Invalid credentials';

  @override
  String get authPopupBlocked => 'Sign-in popup was blocked. Allow popups and try again';

  @override
  String get authUnauthorizedDomain => 'This domain is not authorized for Google sign in. Add localhost to Authorized domains';

  @override
  String get authGoogleProviderDisabled => 'Google sign in is not enabled in Firebase Auth';

  @override
  String get authWebPopupUnsupported => 'This browser or environment does not support the Google sign-in popup';

  @override
  String get authNetworkFailed => 'Network request failed. Check your connection and try again';

  @override
  String get authWebStorageUnsupported => 'Browser storage or cookies are blocked. Allow them and try again';

  @override
  String get authGenericError => 'An error occurred. Try again';

  @override
  String get inviteLoginRequired => 'You must sign in first';

  @override
  String get inviteSuccess => '🎉 Merchant account activated successfully!';

  @override
  String get inviteActivationFailed => 'Activation failed';

  @override
  String get inviteUnexpectedError => 'An unexpected error occurred';

  @override
  String get inviteInvalidCode => 'Invalid invite code';

  @override
  String get inviteAppCheckFailed => 'App security check failed. Update the app or contact support.';

  @override
  String get inviteCodeExpired => 'This code has expired';

  @override
  String get inviteCodeUsed => 'This code is already used';

  @override
  String get inviteCodeUnavailable => 'Cannot use this code at this time';

  @override
  String get inviteRateLimited => 'Rate limit exceeded. Please try later.';

  @override
  String get inviteAborted => 'Problem with invite code. Please contact support.';

  @override
  String get inviteUnauthenticated => 'You must sign in';

  @override
  String get inviteConnectionError => 'Connection error occurred';

  @override
  String get inviteRetryError => 'An error occurred. Try again.';

  @override
  String get merchantValidationUnknown => 'Unknown error';

  @override
  String get errNetwork => 'Check your internet connection';

  @override
  String get errServer => 'Server issue, try again';

  @override
  String get errNoResults => 'No matching results, try adjusting filters';

  @override
  String get errVenueNotFound => 'Venue not found or deleted';

  @override
  String get errLocationPermission => 'Enable location for better results';

  @override
  String get errAuthInvalidCode => 'Invalid verification code';

  @override
  String get errAuthSessionExpired => 'Code expired, request a new one';

  @override
  String get errAuthTooMany => 'Too many attempts, try later';

  @override
  String get errAuthInvalidPhone => 'Invalid phone number';

  @override
  String get errAuthGeneric => 'Verification error occurred';

  @override
  String get errCache => 'Could not read local data';

  @override
  String get errReview => 'Review submission failed, try again';

  @override
  String get errOffer => 'Offer action failed, try again';

  @override
  String get errTimeout => 'Connection timed out, try again';

  @override
  String get busyTimesTitle => 'Typical busy times';

  @override
  String get busyTimesDataPreliminary => 'Preliminary data';

  @override
  String get busyTimesBasedOnUsage => 'Based on usage signals during the last 30 days';

  @override
  String get busyTimesQuietNow => 'Usually quiet now';

  @override
  String get busyTimesMediumNow => 'Usually moderately busy now';

  @override
  String get busyTimesBusyNow => 'Usually busy now';

  @override
  String busyTimesBestVisitWindow(String window) {
    return 'Best visit window is usually $window';
  }

  @override
  String get transportTitle => 'Waselni';

  @override
  String get transportSubtitle => 'Check the ride cost to this venue before you go';

  @override
  String get transportComingSoon => 'Coming soon';

  @override
  String get transportCurrentLocation => 'Your current location';

  @override
  String get transportCityFallback => 'City center estimate';

  @override
  String get transportShowOptions => 'Show transport options';

  @override
  String get transportLocationWarning => 'Set your current location before using Waselni, then try again.';

  @override
  String get transportLocationRequired => 'Set your current location to view Waselni options and accurate prices.';

  @override
  String get transportEnableLocation => 'Set my location';

  @override
  String get transportLocationDenied => 'Allow WAIN to access your location, then try again.';

  @override
  String get transportLocationSettingsHint => 'Enable location in your phone settings, then return to WAIN and try again.';

  @override
  String get transportLocationUnavailable => 'We could not determine your location. Make sure location is enabled and try again.';

  @override
  String get transportOpenNavigation => 'Start navigation yourself';

  @override
  String get transportRefreshQuotes => 'Refresh quotes';

  @override
  String get transportCheapest => 'Cheapest';

  @override
  String get transportFastest => 'Fastest';

  @override
  String get transportPriceLabel => 'Price';

  @override
  String get transportEtaLabel => 'Pickup ETA';

  @override
  String get transportTripLabel => 'Trip';

  @override
  String get transportPriceEstimate => 'Estimated price';

  @override
  String get transportQuoteExpired => 'This quote expired. Refresh prices and try again.';

  @override
  String get transportUnavailable => 'This transport option is not available right now.';

  @override
  String get transportStartHandoff => 'Continue with partner';

  @override
  String get transportNoCoverage => 'No transport is currently available for this venue';

  @override
  String get transportLoadFailed => 'Failed to load transport options';

  @override
  String get transportHandoffFailed => 'Failed to start the transport handoff';

  @override
  String get transportRateLimited => 'Too many transport requests. Try again shortly.';

  @override
  String get transportTooFar => 'This venue is too far for the current transport range';

  @override
  String get transportMinuteShort => 'min';

  @override
  String get merchantWalletTitle => 'WAIN Credit';

  @override
  String get merchantWalletBalance => 'Available Balance';

  @override
  String get merchantWalletTopUp => 'Top-up Request';

  @override
  String get merchantWalletLowBalance => 'Attention! Balance is low, recharge to avoid feature interruption.';

  @override
  String get merchantWalletStatus => 'Wallet Status';

  @override
  String get merchantWalletActive => 'Active';

  @override
  String get merchantWalletSuspended => 'Suspended';

  @override
  String get merchantWalletClosed => 'Closed';

  @override
  String get merchantWalletTransactions => 'Transactions';

  @override
  String get merchantWalletTopUpRequests => 'Top-up Requests';

  @override
  String get merchantWalletTopUpAmount => 'Requested Amount';

  @override
  String get merchantWalletTopUpProof => 'Transfer Receipt (Optional)';

  @override
  String get merchantWalletProofPickImage => 'Pick receipt image';

  @override
  String get merchantWalletProofInvalidType => 'Unsupported file type. Use JPG, PNG, or WEBP.';

  @override
  String get merchantWalletProofTooLarge => 'Receipt image must be less than 5 MB.';

  @override
  String get merchantWalletTopUpRef => 'Transfer Reference (Optional)';

  @override
  String get merchantWalletTopUpNote => 'Notes (Optional)';

  @override
  String get merchantWalletTopUpSubmit => 'Submit Request';

  @override
  String get merchantWalletTopUpAmountRequired => 'Amount is required';

  @override
  String get merchantWalletTopUpAmountInvalid => 'Please enter a valid amount';

  @override
  String get merchantWalletTopUpSuccess => '✅ Top-up request submitted and pending review';

  @override
  String get merchantWalletTopUpError => '❌ Failed to submit request';

  @override
  String get merchantWalletStatusPending => 'Pending';

  @override
  String get merchantWalletStatusCredited => 'Credited';

  @override
  String get merchantWalletStatusRejected => 'Rejected';

  @override
  String get merchantWalletNoEntries => 'No wallet activity yet';

  @override
  String get merchantWalletTopUpReflected => 'This top-up has already been reflected in your balance';

  @override
  String merchantWalletRejectedReason(String reason) {
    return 'Rejection reason: $reason';
  }

  @override
  String merchantWalletBalanceAfter(String balance, String currency) {
    return 'Balance after: $balance $currency';
  }

  @override
  String get merchantWalletNoTopUpRequests => 'No previous top-up requests';

  @override
  String get merchantWalletLoadError => 'Failed to load wallet data right now';

  @override
  String get merchantWalletEntryTopUp => 'Balance top-up';

  @override
  String get merchantWalletEntryStoryPromotion => 'Story promotion';

  @override
  String merchantWalletEntryStoryPromotionDays(String days) {
    return 'Story promotion $days days';
  }

  @override
  String get merchantWalletEntryGeneric => 'Wallet activity';

  @override
  String get merchantWalletSummaryTitle => 'Wallet Summary';

  @override
  String merchantWalletSummaryTotalCredited(String amount, String currency) {
    return 'Total credited: $amount $currency';
  }

  @override
  String merchantWalletSummaryTotalDebited(String amount, String currency) {
    return 'Total debited: $amount $currency';
  }

  @override
  String merchantWalletSummaryLast30Debited(String amount, String currency) {
    return 'Last 30 days spent: $amount $currency';
  }

  @override
  String merchantWalletSummaryMostUsedFeature(String feature) {
    return 'Most used debit: $feature';
  }

  @override
  String get merchantWalletSummaryOfferPin => 'Offer pin';

  @override
  String get adminTopUpReviewTitle => 'Top-up Review Queue';

  @override
  String get adminTopUpReviewNoAccess => 'You do not have admin access.';

  @override
  String get adminTopUpReviewEmpty => 'No pending top-up requests.';

  @override
  String get adminTopUpReviewLoadError => 'Failed to load top-up review queue.';

  @override
  String get adminTopUpReviewVenue => 'Venue';

  @override
  String get adminTopUpReviewRequester => 'Requested by';

  @override
  String get adminTopUpReviewCreatedAt => 'Created at';

  @override
  String get adminTopUpReviewReference => 'Reference';

  @override
  String get adminTopUpReviewNote => 'Note';

  @override
  String get adminTopUpReviewApprove => 'Approve';

  @override
  String get adminTopUpReviewReject => 'Reject';

  @override
  String get adminTopUpReviewRejectNoteRequired => 'Rejection note is required';

  @override
  String get adminTopUpReviewApproved => 'Top-up request approved';

  @override
  String get adminTopUpReviewRejected => 'Top-up request rejected';

  @override
  String get adminTopUpReviewActionError => 'Review action failed';

  @override
  String get adminWalletAuditTitle => 'Wallet Audit';

  @override
  String get adminWalletAuditEmpty => 'No wallet audit events yet.';

  @override
  String get adminWalletAuditEmptyHint => 'Audit rows will appear here after the first financial event.';

  @override
  String get adminWalletAuditFilterType => 'Event type';

  @override
  String get adminWalletAuditFilterAll => 'All events';

  @override
  String get adminWalletAuditRequestId => 'Request ID';

  @override
  String get adminWalletAuditLinkedEntry => 'Linked entry';

  @override
  String get adminWalletAuditReversedLabel => 'Reversal';

  @override
  String get adminWalletAuditReversedTag => 'Reversed';

  @override
  String get adminWalletAuditReverseCta => 'Reverse';

  @override
  String get adminWalletAuditReverseDialogTitle => 'Reverse wallet entry';

  @override
  String get adminWalletAuditReverseReasonLabel => 'Reason (required)';

  @override
  String get adminWalletAuditReverseReasonRequired => 'Reason is required';

  @override
  String get adminWalletAuditReverseAdminNoteLabel => 'Admin note (optional)';

  @override
  String get adminWalletAuditReverseConfirm => 'Confirm reversal';

  @override
  String get adminWalletAuditReverseSuccess => 'Entry reversed successfully';
}
