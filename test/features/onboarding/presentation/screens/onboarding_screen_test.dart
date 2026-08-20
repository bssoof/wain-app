import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wain_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final fontLoader = FontLoader('Cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo-Variable.ttf'));
    await fontLoader.load();
  });

  testWidgets('matches the three Figma onboarding steps', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('ar'),
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(OnboardingScreen));
      for (final path in const [
        'assets/images/onboarding_welcome.png',
        'assets/images/onboarding_filters.png',
        'assets/images/onboarding_discounts.png',
      ]) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await tester.pump();

    final artwork = tester.renderObject<RenderImage>(
      find.byKey(const ValueKey('onboarding-artwork-0')),
    );
    expect(artwork.image, isNotNull);

    expect(find.byKey(const ValueKey('onboarding-artwork-0')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-active-dot-0')),
      findsOneWidget,
    );
    expect(find.text('التالي'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-next-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('onboarding-active-dot-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('onboarding-artwork-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-next-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('onboarding-active-dot-2')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('onboarding-artwork-2')), findsOneWidget);
  });
}
