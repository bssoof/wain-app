import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/auth/presentation/screens/signup_screen.dart';
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

Future<void> tapSubmit(WidgetTester tester) async {
  final submitButton = find.byType(ElevatedButton).first;
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

void main() {
  group('SignupScreen Widget Tests', () {
    testWidgets('renders signup screen with core fields', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('W'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.textContaining('الاسم'), findsOneWidget);
    });

    testWidgets('can enter form data', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'باسل');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'basil@test.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'pass123');
      await tester.enterText(find.byType(TextFormField).at(3), 'pass123');

      expect(find.text('باسل'), findsOneWidget);
      expect(find.text('basil@test.com'), findsOneWidget);
    });

    testWidgets('validates empty fields on submit', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      await tapSubmit(tester);

      expect(find.textContaining('الرجاء'), findsAtLeastNWidgets(1));
    });

    testWidgets('validates email format', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Test Name');
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
      await tester.enterText(find.byType(TextFormField).at(2), 'pass123');
      await tester.enterText(find.byType(TextFormField).at(3), 'pass123');

      await tapSubmit(tester);

      expect(find.textContaining('غير صالح'), findsWidgets);
    });

    testWidgets('validates password mismatch', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Test Name');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test@email.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'pass123');
      await tester.enterText(find.byType(TextFormField).at(3), 'different');

      await tapSubmit(tester);

      expect(find.textContaining('غير متطابقة'), findsWidgets);
    });

    testWidgets('validates short password', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Test Name');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test@email.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), '12');
      await tester.enterText(find.byType(TextFormField).at(3), '12');

      await tapSubmit(tester);

      expect(find.textContaining('6'), findsWidgets);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('shows login link at bottom', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('سجّل دخول'), findsOneWidget);
    });
  });
}
