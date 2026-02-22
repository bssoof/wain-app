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
  String get errorPrefix => 'An error occurred';

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
  String get tryListRemoved => 'Removed from list';

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
  String get tabMenu => 'Menu';

  @override
  String get tabReviews => 'Reviews';

  @override
  String get tabAbout => 'About';

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
  String get merchantOffersDeleteTitle => 'Delete Offer';

  @override
  String get merchantOffersDeleteConfirm => 'Are you sure you want to delete this offer?';

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
  String merchantOffersSubmitError(String error) {
    return '❌ Error: $error';
  }

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
  String get merchantOffersDurationLabel => '📅 Offer duration';

  @override
  String get merchantOffersStartDate => 'Start';

  @override
  String get merchantOffersEndDate => 'End';

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

  // --- Batch 5: Map Screen ---
  @override
  String get mapNoVenuesInArea => 'No venues in this area currently';
  @override
  String mapFoundVenuesWithOffers(String count, String offers) => 'Found $count venues ($offers offers available 🔥)';
  @override
  String mapFoundVenues(String count) => 'Found $count venues';
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
  String mapVenueCount(String count) => '$count venues';
  @override
  String mapDistanceAway(String distance) => '$distance km away';
  @override
  String get mapNeedsConnection => 'Needs connection';
  @override
  String get mapStartNavigation => 'Start Navigation';
  @override
  String get mapRouteFetchFailed => 'Failed to fetch route';

  // --- Batch 6: Profile & Shared Widgets ---
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
  String get profileSectionAbout => 'About';
  @override
  String get profileAboutWain => 'About WAIN';
  @override
  String get profilePrivacy => 'Privacy Policy';
  @override
  String get profileHelp => 'Help';
  @override
  String profileVersion(String version) => 'Version $version';
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
  String get nearbyVenuesTitle => 'Nearby Venues';
  @override
  String get nearbyApproxLocation => 'Approximate location';
  @override
  String get categoryGeneral => 'General';
}
