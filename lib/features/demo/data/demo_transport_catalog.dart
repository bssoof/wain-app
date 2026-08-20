import 'package:wain_app/features/demo/demo_mode.dart';

/// One priced transport option, computed by nobody.
///
/// The real flow calls `getTransportQuotes` and then `createTransportHandoff`,
/// which reaches an actual dispatch partner. Neither may run for a venue that
/// does not exist, so the demo carries fixed sample figures and says on the
/// booking control that nothing is being booked.
class DemoTransportOption {
  const DemoTransportOption({
    required this.id,
    required this.providerNameAr,
    required this.vehicleAr,
    required this.priceIls,
    required this.etaMinutes,
  });

  final String id;
  final String providerNameAr;
  final String vehicleAr;
  final int priceIls;
  final int etaMinutes;
}

/// Deliberately invented operator names: no real transport company is named,
/// pictured, or implied as a partner.
const List<DemoTransportOption> demoTransportOptions = <DemoTransportOption>[
  DemoTransportOption(
    id: 'demo_transport_economy',
    providerNameAr: 'مزوّد تجريبي أ',
    vehicleAr: 'سيارة اقتصادية',
    priceIls: 18,
    etaMinutes: 7,
  ),
  DemoTransportOption(
    id: 'demo_transport_comfort',
    providerNameAr: 'مزوّد تجريبي ب',
    vehicleAr: 'سيارة مريحة',
    priceIls: 26,
    etaMinutes: 4,
  ),
];

const String demoTransportNoticeAr =
    'عرض تجريبي — لا يوجد حجز حقيقي ولا شريك نقل';

bool shouldUseDemoTransport(String venueId) => DemoMode.isDemoVenue(venueId);
