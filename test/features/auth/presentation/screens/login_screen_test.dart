import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/auth/presentation/screens/login_screen.dart';
import 'package:wain_app/l10n/app_localizations.dart';

Widget createTestableWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('renders login screen core elements', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LoginScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.byKey(const ValueKey('login-hero-image')), findsOneWidget);
      expect(find.text(l10n.loginGoogle), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(TextButton), findsNWidgets(2));
    });

    testWidgets('renders phone mode by default', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LoginScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(l10n.loginPhoneHint), findsOneWidget);
    });

    testWidgets('can switch to email mode and enter credentials', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final toEmailMode = find.widgetWithIcon(TextButton, Icons.mail_outline);
      await tester.ensureVisible(toEmailMode);
      await tester.tap(toEmailMode);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('toggles password visibility in email mode', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final toEmailMode = find.widgetWithIcon(TextButton, Icons.mail_outline);
      await tester.ensureVisible(toEmailMode);
      await tester.tap(toEmailMode);
      await tester.pumpAndSettle();

      final visibilityToggle = find.byIcon(Icons.visibility_off_outlined);
      expect(visibilityToggle, findsOneWidget);

      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('switches from email mode back to phone mode', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final toEmailMode = find.widgetWithIcon(TextButton, Icons.mail_outline);
      await tester.ensureVisible(toEmailMode);
      await tester.tap(toEmailMode);
      await tester.pumpAndSettle();

      final toPhoneMode = find.widgetWithIcon(TextButton, Icons.phone_outlined);
      await tester.ensureVisible(toPhoneMode);
      await tester.tap(toPhoneMode);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LoginScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(l10n.loginPhoneHint), findsOneWidget);
    });

    testWidgets('shows continue as guest control', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LoginScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.byType(TextButton), findsNWidgets(2));
      expect(find.text(l10n.loginContinueGuest), findsOneWidget);
    });
  });
}
