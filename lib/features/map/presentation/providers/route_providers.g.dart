// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for RouteService

@ProviderFor(routeService)
final routeServiceProvider = RouteServiceProvider._();

/// Provider for RouteService

final class RouteServiceProvider
    extends $FunctionalProvider<RouteService, RouteService, RouteService>
    with $Provider<RouteService> {
  /// Provider for RouteService
  RouteServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeServiceHash();

  @$internal
  @override
  $ProviderElement<RouteService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RouteService create(Ref ref) {
    return routeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RouteService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RouteService>(value),
    );
  }
}

String _$routeServiceHash() => r'4aafc5c025b429b2b1ba3e216ff1a0a8147051c5';
