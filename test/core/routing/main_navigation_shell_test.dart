import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/routing/main_navigation_shell.dart';
import 'package:wain_app/features/map/presentation/providers/map_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';

void main() {
  testWidgets('map tab clears inherited filters and uses compact nav height', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(mapFilterProvider.notifier).setBudget(40, 90);
    expect(container.read(mapFilterProvider).hasActiveFilters, isTrue);

    final router = GoRouter(
      initialLocation: '/results',
      routes: [
        GoRoute(
          path: '/results',
          builder: (context, state) => const MainNavigationShell(
            currentLocation: '/results',
            child: SizedBox.shrink(),
          ),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const MainNavigationShell(
            currentLocation: '/map',
            child: SizedBox.shrink(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(MainNavigationShell));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.questionMap));
    await tester.pumpAndSettle();

    expect(container.read(mapFilterProvider).hasActiveFilters, isFalse);
    expect(router.routeInformationProvider.value.uri.path, '/map');
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 90,
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 80,
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == 60,
      ),
      findsWidgets,
    );
  });
}
