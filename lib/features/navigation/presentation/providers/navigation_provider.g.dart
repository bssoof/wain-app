// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides NavigationRepository instance

@ProviderFor(navigationRepository)
final navigationRepositoryProvider = NavigationRepositoryProvider._();

/// Provides NavigationRepository instance

final class NavigationRepositoryProvider
    extends
        $FunctionalProvider<
          NavigationRepository,
          NavigationRepository,
          NavigationRepository
        >
    with $Provider<NavigationRepository> {
  /// Provides NavigationRepository instance
  NavigationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationRepositoryHash();

  @$internal
  @override
  $ProviderElement<NavigationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NavigationRepository create(Ref ref) {
    return navigationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NavigationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NavigationRepository>(value),
    );
  }
}

String _$navigationRepositoryHash() =>
    r'0f826d0c41c000a12558ad04eb6209d86aa7334a';

/// Log a navigation click and return the click ID

@ProviderFor(logNavigationClick)
final logNavigationClickProvider = LogNavigationClickFamily._();

/// Log a navigation click and return the click ID

final class LogNavigationClickProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Log a navigation click and return the click ID
  LogNavigationClickProvider._({
    required LogNavigationClickFamily super.from,
    required ({String venueId, String? userId, String navApp}) super.argument,
  }) : super(
         retry: null,
         name: r'logNavigationClickProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$logNavigationClickHash();

  @override
  String toString() {
    return r'logNavigationClickProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument =
        this.argument as ({String venueId, String? userId, String navApp});
    return logNavigationClick(
      ref,
      venueId: argument.venueId,
      userId: argument.userId,
      navApp: argument.navApp,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LogNavigationClickProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$logNavigationClickHash() =>
    r'1a222c779583fc5915298303da63e6abb9d2f450';

/// Log a navigation click and return the click ID

final class LogNavigationClickFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<String>,
          ({String venueId, String? userId, String navApp})
        > {
  LogNavigationClickFamily._()
    : super(
        retry: null,
        name: r'logNavigationClickProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Log a navigation click and return the click ID

  LogNavigationClickProvider call({
    required String venueId,
    String? userId,
    required String navApp,
  }) => LogNavigationClickProvider._(
    argument: (venueId: venueId, userId: userId, navApp: navApp),
    from: this,
  );

  @override
  String toString() => r'logNavigationClickProvider';
}

/// Get device ID

@ProviderFor(deviceId)
final deviceIdProvider = DeviceIdProvider._();

/// Get device ID

final class DeviceIdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Get device ID
  DeviceIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return deviceId(ref);
  }
}

String _$deviceIdHash() => r'494d42f6a742660914f2cd6fe3ea2aa381c02d41';
