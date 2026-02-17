// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calculate distance between user and venue
/// Returns distance in kilometers

@ProviderFor(distanceToVenue)
final distanceToVenueProvider = DistanceToVenueFamily._();

/// Calculate distance between user and venue
/// Returns distance in kilometers

final class DistanceToVenueProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// Calculate distance between user and venue
  /// Returns distance in kilometers
  DistanceToVenueProvider._({
    required DistanceToVenueFamily super.from,
    required ({
      double venueLat,
      double venueLng,
      double userLat,
      double userLng,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'distanceToVenueProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$distanceToVenueHash();

  @override
  String toString() {
    return r'distanceToVenueProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    final argument =
        this.argument
            as ({
              double venueLat,
              double venueLng,
              double userLat,
              double userLng,
            });
    return distanceToVenue(
      ref,
      venueLat: argument.venueLat,
      venueLng: argument.venueLng,
      userLat: argument.userLat,
      userLng: argument.userLng,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DistanceToVenueProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$distanceToVenueHash() => r'b9ebefe13a6df7b930bdd40dd2f3f88b199f233c';

/// Calculate distance between user and venue
/// Returns distance in kilometers

final class DistanceToVenueFamily extends $Family
    with
        $FunctionalFamilyOverride<
          double,
          ({double venueLat, double venueLng, double userLat, double userLng})
        > {
  DistanceToVenueFamily._()
    : super(
        retry: null,
        name: r'distanceToVenueProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Calculate distance between user and venue
  /// Returns distance in kilometers

  DistanceToVenueProvider call({
    required double venueLat,
    required double venueLng,
    required double userLat,
    required double userLng,
  }) => DistanceToVenueProvider._(
    argument: (
      venueLat: venueLat,
      venueLng: venueLng,
      userLat: userLat,
      userLng: userLng,
    ),
    from: this,
  );

  @override
  String toString() => r'distanceToVenueProvider';
}
