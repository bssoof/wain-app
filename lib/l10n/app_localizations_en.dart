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
  String get importantNotice => 'Important notice';

  @override
  String get offerValidTenMinutes => 'This offer is valid for only 10 minutes!';

  @override
  String get offerActivationWarning => 'Please do not activate the offer unless you are inside the venue and in front of the cashier.\n\nOnce activated, the timer will start and cannot be stopped.';

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
  String get tryListRemoved => 'Removed from try list';

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
  String get needConnection => 'Connection required';
}
