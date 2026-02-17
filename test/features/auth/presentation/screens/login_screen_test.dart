import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/auth/presentation/screens/login_screen.dart';

void main() {
  // Helper to create a testable widget with Riverpod and Material
  Widget createTestableWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders login screen with all key elements', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Check for logo text
      expect(find.text('W'), findsOneWidget);

      // Check for title
      expect(find.text('تسجيل الدخول'), findsOneWidget);

      // Check for subtitle
      expect(find.text('سجّل دخولك للاستمتاع بجميع ميزات وين'), findsOneWidget);

      // Check for Google button
      expect(find.text('تسجيل الدخول بحساب Google'), findsOneWidget);

      // Check for divider text
      expect(find.text('أو'), findsOneWidget);
    });

    testWidgets('renders email mode by default', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Check email login button
      expect(find.text('تسجيل الدخول'), findsWidgets); // title + button
      
      // Check for "Create account" link
      expect(find.text('إنشاء حساب'), findsOneWidget);
    });

    testWidgets('can enter email and password', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Find email field and enter text
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');

      // Find password field and enter text (second TextField)
      final passwordField = find.byType(TextField).at(1);
      await tester.enterText(passwordField, 'password123');

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Find visibility toggle button
      final visibilityToggle = find.byIcon(Icons.visibility_outlined);
      expect(visibilityToggle, findsOneWidget);

      // Tap to toggle
      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      // Now it should show visibility_off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('switches to phone mode', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Find phone number option
      final phoneOption = find.text('استخدم رقم الهاتف');
      expect(phoneOption, findsOneWidget);

      // Tap to switch to phone mode
      await tester.tap(phoneOption);
      await tester.pumpAndSettle();

      // Now should show phone input hint
      expect(find.text('+970599123456'), findsOneWidget);
    });

    testWidgets('shows "Continue as guest" button', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('متابعة كضيف'), findsOneWidget);
    });
  });
}
