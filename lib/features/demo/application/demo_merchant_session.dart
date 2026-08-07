import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/demo/demo_mode.dart';

/// Whether the merchant-side walkthrough is running.
///
/// The customer side keys off a venue id sitting in the route, so
/// `DemoMode.isDemoVenue` is enough to decide what to serve. The merchant side
/// has no venue id in the route: the real app derives it from the signed-in
/// user's `merchant_venue_id`. A walkthrough has no signed-in merchant, so the
/// gate has to be an explicit session flag instead — turned on by the debug
/// `/demo/merchant` entry point, off everywhere else, never persisted.
///
/// [DemoMode.isEnabled] still guards it, so this cannot be switched on in a
/// release build even by calling [enter] directly.
class DemoMerchantSession extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() {
    if (!DemoMode.isEnabled) return;
    state = true;
  }

  void leave() => state = false;
}

final demoMerchantSessionProvider = NotifierProvider<DemoMerchantSession, bool>(
  DemoMerchantSession.new,
);

/// The one question every merchant provider asks before choosing an adapter.
///
/// Watched rather than read: leaving the walkthrough has to tear the demo
/// repositories back down, not leave them installed for the rest of the
/// process.
bool isDemoMerchantSession(Ref ref) =>
    DemoMode.isEnabled && ref.watch(demoMerchantSessionProvider);
