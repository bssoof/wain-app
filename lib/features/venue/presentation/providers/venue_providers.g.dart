// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(venueRepository)
final venueRepositoryProvider = VenueRepositoryProvider._();

final class VenueRepositoryProvider
    extends
        $FunctionalProvider<VenueRepository, VenueRepository, VenueRepository>
    with $Provider<VenueRepository> {
  VenueRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'venueRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$venueRepositoryHash();

  @$internal
  @override
  $ProviderElement<VenueRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VenueRepository create(Ref ref) {
    return venueRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VenueRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VenueRepository>(value),
    );
  }
}

String _$venueRepositoryHash() => r'56f2c3d336f59fd7de64f661a508913457fdf7f6';

@ProviderFor(venueById)
final venueByIdProvider = VenueByIdFamily._();

final class VenueByIdProvider
    extends $FunctionalProvider<AsyncValue<Venue?>, Venue?, FutureOr<Venue?>>
    with $FutureModifier<Venue?>, $FutureProvider<Venue?> {
  VenueByIdProvider._({
    required VenueByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'venueByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$venueByIdHash();

  @override
  String toString() {
    return r'venueByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Venue?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Venue?> create(Ref ref) {
    final argument = this.argument as String;
    return venueById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VenueByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$venueByIdHash() => r'ef1e7964585030913f434099f0f68901101b1f40';

final class VenueByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Venue?>, String> {
  VenueByIdFamily._()
    : super(
        retry: null,
        name: r'venueByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VenueByIdProvider call(String id) =>
      VenueByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'venueByIdProvider';
}

/// Cache-first venues provider with offline support

@ProviderFor(CachedVenues)
final cachedVenuesProvider = CachedVenuesFamily._();

/// Cache-first venues provider with offline support
final class CachedVenuesProvider
    extends $NotifierProvider<CachedVenues, VenuesState> {
  /// Cache-first venues provider with offline support
  CachedVenuesProvider._({
    required CachedVenuesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cachedVenuesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cachedVenuesHash();

  @override
  String toString() {
    return r'cachedVenuesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CachedVenues create() => CachedVenues();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VenuesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VenuesState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CachedVenuesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cachedVenuesHash() => r'475f6132ceb045d05fe920f8f0fab6e81f25f2c0';

/// Cache-first venues provider with offline support

final class CachedVenuesFamily extends $Family
    with
        $ClassFamilyOverride<
          CachedVenues,
          VenuesState,
          VenuesState,
          VenuesState,
          String
        > {
  CachedVenuesFamily._()
    : super(
        retry: null,
        name: r'cachedVenuesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Cache-first venues provider with offline support

  CachedVenuesProvider call({String city = AppConstants.defaultCity}) =>
      CachedVenuesProvider._(argument: city, from: this);

  @override
  String toString() => r'cachedVenuesProvider';
}

/// Cache-first venues provider with offline support

abstract class _$CachedVenues extends $Notifier<VenuesState> {
  late final _$args = ref.$arg as String;
  String get city => _$args;

  VenuesState build({String city = AppConstants.defaultCity});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VenuesState, VenuesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VenuesState, VenuesState>,
              VenuesState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(city: _$args));
  }
}

/// Simple venues provider (for backward compatibility)

@ProviderFor(venuesByCity)
final venuesByCityProvider = VenuesByCityFamily._();

/// Simple venues provider (for backward compatibility)

final class VenuesByCityProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Venue>>,
          List<Venue>,
          FutureOr<List<Venue>>
        >
    with $FutureModifier<List<Venue>>, $FutureProvider<List<Venue>> {
  /// Simple venues provider (for backward compatibility)
  VenuesByCityProvider._({
    required VenuesByCityFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'venuesByCityProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$venuesByCityHash();

  @override
  String toString() {
    return r'venuesByCityProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Venue>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Venue>> create(Ref ref) {
    final argument = this.argument as String;
    return venuesByCity(ref, city: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VenuesByCityProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$venuesByCityHash() => r'0a113f3c7c506aa35ca03cfff89fdee15878265d';

/// Simple venues provider (for backward compatibility)

final class VenuesByCityFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Venue>>, String> {
  VenuesByCityFamily._()
    : super(
        retry: null,
        name: r'venuesByCityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Simple venues provider (for backward compatibility)

  VenuesByCityProvider call({String city = AppConstants.defaultCity}) =>
      VenuesByCityProvider._(argument: city, from: this);

  @override
  String toString() => r'venuesByCityProvider';
}

@ProviderFor(recommendations)
final recommendationsProvider = RecommendationsFamily._();

final class RecommendationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Venue>>,
          List<Venue>,
          FutureOr<List<Venue>>
        >
    with $FutureModifier<List<Venue>>, $FutureProvider<List<Venue>> {
  RecommendationsProvider._({
    required RecommendationsFamily super.from,
    required ({
      List<String> moodTags,
      List<String> occasionTags,
      List<String> timeTags,
      int minBudget,
      int maxBudget,
      List<String> cuisineTypes,
      String city,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'recommendationsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recommendationsHash();

  @override
  String toString() {
    return r'recommendationsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Venue>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Venue>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              List<String> moodTags,
              List<String> occasionTags,
              List<String> timeTags,
              int minBudget,
              int maxBudget,
              List<String> cuisineTypes,
              String city,
            });
    return recommendations(
      ref,
      moodTags: argument.moodTags,
      occasionTags: argument.occasionTags,
      timeTags: argument.timeTags,
      minBudget: argument.minBudget,
      maxBudget: argument.maxBudget,
      cuisineTypes: argument.cuisineTypes,
      city: argument.city,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecommendationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recommendationsHash() => r'4a3fef7d6a823996a72c33a60e85a543eb8efcc8';

final class RecommendationsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Venue>>,
          ({
            List<String> moodTags,
            List<String> occasionTags,
            List<String> timeTags,
            int minBudget,
            int maxBudget,
            List<String> cuisineTypes,
            String city,
          })
        > {
  RecommendationsFamily._()
    : super(
        retry: null,
        name: r'recommendationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  RecommendationsProvider call({
    required List<String> moodTags,
    required List<String> occasionTags,
    required List<String> timeTags,
    int minBudget = 30,
    int maxBudget = 200,
    List<String> cuisineTypes = const [],
    String city = AppConstants.defaultCity,
  }) => RecommendationsProvider._(
    argument: (
      moodTags: moodTags,
      occasionTags: occasionTags,
      timeTags: timeTags,
      minBudget: minBudget,
      maxBudget: maxBudget,
      cuisineTypes: cuisineTypes,
      city: city,
    ),
    from: this,
  );

  @override
  String toString() => r'recommendationsProvider';
}

/// Get nearest 5 venues sorted by distance

@ProviderFor(nearbyVenues)
final nearbyVenuesProvider = NearbyVenuesFamily._();

/// Get nearest 5 venues sorted by distance

final class NearbyVenuesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VenueWithDistance>>,
          List<VenueWithDistance>,
          FutureOr<List<VenueWithDistance>>
        >
    with
        $FutureModifier<List<VenueWithDistance>>,
        $FutureProvider<List<VenueWithDistance>> {
  /// Get nearest 5 venues sorted by distance
  NearbyVenuesProvider._({
    required NearbyVenuesFamily super.from,
    required ({double userLat, double userLng, int limit, String city})
    super.argument,
  }) : super(
         retry: null,
         name: r'nearbyVenuesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nearbyVenuesHash();

  @override
  String toString() {
    return r'nearbyVenuesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<VenueWithDistance>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<VenueWithDistance>> create(Ref ref) {
    final argument =
        this.argument
            as ({double userLat, double userLng, int limit, String city});
    return nearbyVenues(
      ref,
      userLat: argument.userLat,
      userLng: argument.userLng,
      limit: argument.limit,
      city: argument.city,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NearbyVenuesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nearbyVenuesHash() => r'fe223c405579b09533b91bb429e8049930713835';

/// Get nearest 5 venues sorted by distance

final class NearbyVenuesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<VenueWithDistance>>,
          ({double userLat, double userLng, int limit, String city})
        > {
  NearbyVenuesFamily._()
    : super(
        retry: null,
        name: r'nearbyVenuesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get nearest 5 venues sorted by distance

  NearbyVenuesProvider call({
    required double userLat,
    required double userLng,
    int limit = 5,
    String city = AppConstants.defaultCity,
  }) => NearbyVenuesProvider._(
    argument: (userLat: userLat, userLng: userLng, limit: limit, city: city),
    from: this,
  );

  @override
  String toString() => r'nearbyVenuesProvider';
}

/// Get active stories for a venue

@ProviderFor(venueStories)
final venueStoriesProvider = VenueStoriesFamily._();

/// Get active stories for a venue

final class VenueStoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  /// Get active stories for a venue
  VenueStoriesProvider._({
    required VenueStoriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'venueStoriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$venueStoriesHash();

  @override
  String toString() {
    return r'venueStoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return venueStories(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VenueStoriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$venueStoriesHash() => r'472be271b9ec70632ec79141dd6c493ea94259bc';

/// Get active stories for a venue

final class VenueStoriesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Map<String, dynamic>>>, String> {
  VenueStoriesFamily._()
    : super(
        retry: null,
        name: r'venueStoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get active stories for a venue

  VenueStoriesProvider call(String venueId) =>
      VenueStoriesProvider._(argument: venueId, from: this);

  @override
  String toString() => r'venueStoriesProvider';
}
