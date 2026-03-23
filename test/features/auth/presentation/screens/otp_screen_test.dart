import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/auth/presentation/screens/otp_screen.dart';
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
  group('OtpScreen Widget Tests', () {
    const screen = OtpScreen(
      phoneNumber: '+970599123456',
      verificationId: 'test-verification-id',
    );

    testWidgets('renders OTP screen with phone number', (tester) async {
      await tester.pumpWidget(createTestableWidget(screen));
      await tester.pumpAndSettle();

      expect(find.textContaining('رمز'), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText && w.text.toPlainText().contains('+970599123456'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders 6 digit input fields', (tester) async {
      await tester.pumpWidget(createTestableWidget(screen));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('shows countdown timer text', (tester) async {
      await tester.pumpWidget(createTestableWidget(screen));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data?.contains('(') ?? false) &&
              (w.data?.contains(')') ?? false),
        ),
        findsWidgets,
      );
    });

    testWidgets('shows change number option', (tester) async {
      await tester.pumpWidget(createTestableWidget(screen));
      await tester.pump();

      expect(
        find.widgetWithIcon(TextButton, Icons.phone_outlined),
        findsOneWidget,
      );
    });

    testWidgets('can enter digits in OTP fields', (tester) async {
      await tester.pumpWidget(createTestableWidget(screen));
      await tester.pumpAndSettle();

      final firstField = find.byType(TextField).first;
      await tester.tap(firstField);
      await tester.enterText(firstField, '1');
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });
  });
}
