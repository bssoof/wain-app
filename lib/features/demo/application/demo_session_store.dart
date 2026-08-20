import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/demo/application/demo_merchant_session.dart';
import 'package:wain_app/features/demo/data/demo_reviews_catalog.dart';

/// All mutable demo state, held in memory for the lifetime of the app process.
///
/// Nothing here touches a repository, a database, or the network — a demo run
/// must leave no trace, and [reset] must put the next run back on identical
/// footing. Every mutable demo surface has to store its state here rather than
/// in its own field, otherwise "Reset Demo" silently stops being complete.
@immutable
class DemoSessionState {
  const DemoSessionState({
    this.favouriteVenueIds = const <String>{},
    this.tryListVenueIds = const <String>{},
  });

  final Set<String> favouriteVenueIds;
  final Set<String> tryListVenueIds;

  bool get isPristine => favouriteVenueIds.isEmpty && tryListVenueIds.isEmpty;

  DemoSessionState copyWith({
    Set<String>? favouriteVenueIds,
    Set<String>? tryListVenueIds,
  }) {
    return DemoSessionState(
      favouriteVenueIds: favouriteVenueIds ?? this.favouriteVenueIds,
      tryListVenueIds: tryListVenueIds ?? this.tryListVenueIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DemoSessionState &&
      setEquals(other.favouriteVenueIds, favouriteVenueIds) &&
      setEquals(other.tryListVenueIds, tryListVenueIds);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(favouriteVenueIds),
    Object.hashAllUnordered(tryListVenueIds),
  );
}

class DemoSessionStore extends Notifier<DemoSessionState> {
  /// The state every demo run starts from.
  static const DemoSessionState initialState = DemoSessionState();

  @override
  DemoSessionState build() => initialState;

  bool isFavourite(String venueId) => state.favouriteVenueIds.contains(venueId);

  bool isOnTryList(String venueId) => state.tryListVenueIds.contains(venueId);

  void toggleFavourite(String venueId) {
    final next = Set<String>.of(state.favouriteVenueIds);
    if (!next.remove(venueId)) next.add(venueId);
    state = state.copyWith(favouriteVenueIds: next);
  }

  void toggleTryList(String venueId) {
    final next = Set<String>.of(state.tryListVenueIds);
    if (!next.remove(venueId)) next.add(venueId);
    state = state.copyWith(tryListVenueIds: next);
  }

  /// Returns the demo to the state it had before the first interaction.
  ///
  /// Includes state that lives outside this notifier — anything a presenter can
  /// change has to be reachable from one reset, or the next walkthrough starts
  /// dirty.
  void reset() {
    clearDemoSubmittedReview();
    ref.invalidate(demoMerchantStoreProvider);
    ref.invalidate(demoMenuStoreProvider);
    state = initialState;
  }
}

final demoSessionStoreProvider =
    NotifierProvider<DemoSessionStore, DemoSessionState>(DemoSessionStore.new);
