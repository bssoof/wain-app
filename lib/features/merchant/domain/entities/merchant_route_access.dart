enum MerchantRouteAccessStatus {
  unauthenticated,
  needsInvite,
  ready,
  brokenVenueLink,
}

class MerchantRouteAccess {
  final MerchantRouteAccessStatus status;
  final String? venueId;

  const MerchantRouteAccess._({required this.status, this.venueId});

  const MerchantRouteAccess.unauthenticated()
    : this._(status: MerchantRouteAccessStatus.unauthenticated);

  const MerchantRouteAccess.needsInvite()
    : this._(status: MerchantRouteAccessStatus.needsInvite);

  const MerchantRouteAccess.ready(String venueId)
    : this._(status: MerchantRouteAccessStatus.ready, venueId: venueId);

  const MerchantRouteAccess.brokenVenueLink({String? venueId})
    : this._(
        status: MerchantRouteAccessStatus.brokenVenueLink,
        venueId: venueId,
      );

  bool get isUnauthenticated =>
      status == MerchantRouteAccessStatus.unauthenticated;

  bool get needsInviteFlow => status == MerchantRouteAccessStatus.needsInvite;

  bool get isReady => status == MerchantRouteAccessStatus.ready;

  bool get hasBrokenVenueLink =>
      status == MerchantRouteAccessStatus.brokenVenueLink;
}
