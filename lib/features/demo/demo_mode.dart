import 'package:flutter/foundation.dart';

/// The single gate every demo surface must go through.
///
/// Nothing in this module may be reachable from a release build: [isEnabled] is
/// the only place that decision is made, so there is exactly one line to audit.
/// Demo data is served by adapters that sit *in front of* the production
/// repositories — no production repository, query, or security rule is changed
/// to accommodate the demo.
class DemoMode {
  const DemoMode._();

  /// Deliberately not the id of any published venue. The demo must never write
  /// to, read from, or visually impersonate a real shop.
  static const String venueId = 'wain-demo-cafe-showcase';

  static const String venueNameAr = 'مقهى وين التجريبي';
  static const String venueNameEn = 'WAIN Demo Café';

  /// Shown on every demo surface.
  static const String badgeLabelAr =
      'وضع العرض — بيانات تجريبية، لا يتم تنفيذ عمليات حقيقية';
  static const String badgeLabelEn =
      'Demo mode — sample data, no real operations are performed';

  static bool get isEnabled => kDebugMode;

  static bool isDemoVenue(String? id) => isEnabled && id == venueId;
}
