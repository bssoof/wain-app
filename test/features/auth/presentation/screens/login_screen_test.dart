import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/auth/presentation/screens/login_screen.dart';

Widget createTestableWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: child),
  );
}

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('renders login screen core elements', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('W'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget); // Google
      expect(find.byType(TextField), findsOneWidget); // phone mode default
      expect(find.byType(TextButton), findsNWidgets(2)); // mode toggle + guest
    });

    testWidgets('renders phone mode by default', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('+970599123456'), findsOneWidget);
    });

    testWidgets('can switch to email mode and enter credentials', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final toEmailMode = find.widgetWithIcon(TextButton, Icons.email);
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

      final toEmailMode = find.widgetWithIcon(TextButton, Icons.email);
      await tester.ensureVisible(toEmailMode);
      await tester.tap(toEmailMode);
      await tester.pumpAndSettle();

      final visibilityToggle = find.byIcon(Icons.visibility_off_outlined);
      await tester.ensureVisible(visibilityToggle);
      expect(visibilityToggle, findsOneWidget);

      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('switches from email mode back to phone mode', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final toEmailMode = find.widgetWithIcon(TextButton, Icons.email);
      await tester.ensureVisible(toEmailMode);
      await tester.tap(toEmailMode); // phone -> email
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));

      final toPhoneMode = find.widgetWithIcon(TextButton, Icons.phone);
      await tester.ensureVisible(toPhoneMode);
      await tester.tap(toPhoneMode); // email -> phone
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('+970599123456'), findsOneWidget);
    });

    testWidgets('shows continue as guest control', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Last TextButton in phone mode is "Continue as guest"
      expect(find.byType(TextButton), findsNWidgets(2));
      expect(find.textContaining('ضيف'), findsOneWidget);
    });
  });
}
