// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offers_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for OffersRepository

@ProviderFor(offersRepository)
final offersRepositoryProvider = OffersRepositoryProvider._();

/// Provider for OffersRepository

final class OffersRepositoryProvider
    extends
        $FunctionalProvider<
          OffersRepository,
          OffersRepository,
          OffersRepository
        >
    with $Provider<OffersRepository> {
  /// Provider for OffersRepository
  OffersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offersRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offersRepositoryHash();

  @$internal
  @override
  $ProviderElement<OffersRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OffersRepository create(Ref ref) {
    return offersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OffersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OffersRepository>(value),
    );
  }
}

String _$offersRepositoryHash() => r'34441be62c2a9f609ed5660d6ab810ac928a63c4';

/// Provider for offers by venue

@ProviderFor(offersByVenue)
final offersByVenueProvider = OffersByVenueFamily._();

/// Provider for offers by venue

final class OffersByVenueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Offer>>,
          List<Offer>,
          FutureOr<List<Offer>>
        >
    with $FutureModifier<List<Offer>>, $FutureProvider<List<Offer>> {
  /// Provider for offers by venue
  OffersByVenueProvider._({
    required OffersByVenueFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'offersByVenueProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$offersByVenueHash();

  @override
  String toString() {
    return r'offersByVenueProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Offer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Offer>> create(Ref ref) {
    final argument = this.argument as String;
    return offersByVenue(ref, venueId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OffersByVenueProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$offersByVenueHash() => r'7e7ab09e461650513cdb25e0ddee8f3e2486056d';

/// Provider for offers by venue

final class OffersByVenueFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Offer>>, String> {
  OffersByVenueFamily._()
    : super(
        retry: null,
        name: r'offersByVenueProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for offers by venue

  OffersByVenueProvider call({required String venueId}) =>
      OffersByVenueProvider._(argument: venueId, from: this);

  @override
  String toString() => r'offersByVenueProvider';
}

/// Provider for single offer by ID

@ProviderFor(offerById)
final offerByIdProvider = OfferByIdFamily._();

/// Provider for single offer by ID

final class OfferByIdProvider
    extends $FunctionalProvider<AsyncValue<Offer?>, Offer?, FutureOr<Offer?>>
    with $FutureModifier<Offer?>, $FutureProvider<Offer?> {
  /// Provider for single offer by ID
  OfferByIdProvider._({
    required OfferByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'offerByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$offerByIdHash();

  @override
  String toString() {
    return r'offerByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Offer?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Offer?> create(Ref ref) {
    final argument = this.argument as String;
    return offerById(ref, offerId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OfferByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$offerByIdHash() => r'c6dde9cf5c42e0ebc314657e7957bbf78c4a634c';

/// Provider for single offer by ID

final class OfferByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Offer?>, String> {
  OfferByIdFamily._()
    : super(
        retry: null,
        name: r'offerByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for single offer by ID

  OfferByIdProvider call({required String offerId}) =>
      OfferByIdProvider._(argument: offerId, from: this);

  @override
  String toString() => r'offerByIdProvider';
}

/// Notifier for claiming offers

@ProviderFor(ClaimOffer)
final claimOfferProvider = ClaimOfferProvider._();

/// Notifier for claiming offers
final class ClaimOfferProvider
    extends $NotifierProvider<ClaimOffer, ClaimState> {
  /// Notifier for claiming offers
  ClaimOfferProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'claimOfferProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$claimOfferHash();

  @$internal
  @override
  ClaimOffer create() => ClaimOffer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClaimState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClaimState>(value),
    );
  }
}

String _$claimOfferHash() => r'5a68675c68b0aa273531c0f17f66e0ba02a47ff3';

/// Notifier for claiming offers

abstract class _$ClaimOffer extends $Notifier<ClaimState> {
  ClaimState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ClaimState, ClaimState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClaimState, ClaimState>,
              ClaimState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provides SavedOffersRepository instance

@ProviderFor(savedOffersRepository)
final savedOffersRepositoryProvider = SavedOffersRepositoryProvider._();

/// Provides SavedOffersRepository instance

final class SavedOffersRepositoryProvider
    extends
        $FunctionalProvider<
          SavedOffersRepository,
          SavedOffersRepository,
          SavedOffersRepository
        >
    with $Provider<SavedOffersRepository> {
  /// Provides SavedOffersRepository instance
  SavedOffersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedOffersRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedOffersRepositoryHash();

  @$internal
  @override
  $ProviderElement<SavedOffersRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SavedOffersRepository create(Ref ref) {
    return savedOffersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedOffersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedOffersRepository>(value),
    );
  }
}

String _$savedOffersRepositoryHash() =>
    r'bd8326b201156ff2f46edc50da31219b8a26dda2';

/// Holds the current list of saved offer IDs

@ProviderFor(SavedOffersList)
final savedOffersListProvider = SavedOffersListProvider._();

/// Holds the current list of saved offer IDs
final class SavedOffersListProvider
    extends $AsyncNotifierProvider<SavedOffersList, List<String>> {
  /// Holds the current list of saved offer IDs
  SavedOffersListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedOffersListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedOffersListHash();

  @$internal
  @override
  SavedOffersList create() => SavedOffersList();
}

String _$savedOffersListHash() => r'cff9edddaafe8f9b6c4b0e9f97e7c9618e75f98c';

/// Holds the current list of saved offer IDs

abstract class _$SavedOffersList extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Check if a specific offer is saved

@ProviderFor(isOfferSaved)
final isOfferSavedProvider = IsOfferSavedFamily._();

/// Check if a specific offer is saved

final class IsOfferSavedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Check if a specific offer is saved
  IsOfferSavedProvider._({
    required IsOfferSavedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isOfferSavedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isOfferSavedHash();

  @override
  String toString() {
    return r'isOfferSavedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isOfferSaved(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsOfferSavedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isOfferSavedHash() => r'e3c6281c4ebfb30b67d6889845fedab71b2490a2';

/// Check if a specific offer is saved

final class IsOfferSavedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsOfferSavedFamily._()
    : super(
        retry: null,
        name: r'isOfferSavedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Check if a specific offer is saved

  IsOfferSavedProvider call(String offerId) =>
      IsOfferSavedProvider._(argument: offerId, from: this);

  @override
  String toString() => r'isOfferSavedProvider';
}

/// Provider to get full Offer objects for saved offer IDs

@ProviderFor(savedOffersFull)
final savedOffersFullProvider = SavedOffersFullProvider._();

/// Provider to get full Offer objects for saved offer IDs

final class SavedOffersFullProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Offer>>,
          List<Offer>,
          FutureOr<List<Offer>>
        >
    with $FutureModifier<List<Offer>>, $FutureProvider<List<Offer>> {
  /// Provider to get full Offer objects for saved offer IDs
  SavedOffersFullProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedOffersFullProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedOffersFullHash();

  @$internal
  @override
  $FutureProviderElement<List<Offer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Offer>> create(Ref ref) {
    return savedOffersFull(ref);
  }
}

String _$savedOffersFullHash() => r'c6d1d1fbc158a124e79dfbc5ef654bdbbd9f2c57';
