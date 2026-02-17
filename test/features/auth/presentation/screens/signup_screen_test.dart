import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/auth/presentation/screens/signup_screen.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('SignupScreen Widget Tests', () {
    testWidgets('renders signup screen with all form fields', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      // Check for logo
      expect(find.text('W'), findsOneWidget);

      // Check for title
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);

      // Check for subtitle
      expect(find.text('أنشئ حسابك واستمتع بميزات تطبيق وين'), findsOneWidget);

      // Check for form labels
      expect(find.text('الاسم الكامل'), findsOneWidget);
    });

    testWidgets('shows all input fields', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      // Should have 4 TextFormFields: name, email, password, confirm password
      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('can enter form data', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextFormField).at(0), 'باسل');
      // Enter email
      await tester.enterText(find.byType(TextFormField).at(1), 'basil@test.com');
      // Enter password
      await tester.enterText(find.byType(TextFormField).at(2), 'pass123');
      // Enter confirm password
      await tester.enterText(find.byType(TextFormField).at(3), 'pass123');

      expect(find.text('باسل'), findsOneWidget);
      expect(find.text('basil@test.com'), findsOneWidget);
    });

    testWidgets('validates empty fields on submit', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      // Find and tap submit button
      final submitButton = find.text('إنشاء حساب');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('الرجاء إدخال الاسم'), findsOneWidget);
      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
      expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
      expect(find.text('الرجاء تأكيد كلمة المرور'), findsOneWidget);
    });

    testWidgets('validates email format', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Name');
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
      await tester.enterText(find.byType(TextFormField).at(2), 'pass123');
      await tester.enterText(find.byType(TextFormField).at(3), 'pass123');

      // Submit
      await tester.tap(find.text('إنشاء حساب'));
      await tester.pumpAndSettle();

      expect(find.text('البريد الإلكتروني غير صالح'), findsOneWidget);
    });

    testWidgets('validates password mismatch', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Test Name');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@email.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'pass123');
      await tester.enterText(find.byType(TextFormField).at(3), 'different');

      // Scroll down to make submit button visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('إنشاء حساب'));
      await tester.pumpAndSettle();

      expect(find.text('كلمة المرور غير متطابقة'), findsWidgets);
    });

    testWidgets('validates short password', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Test Name');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@email.com');
      await tester.enterText(find.byType(TextFormField).at(2), '12');
      await tester.enterText(find.byType(TextFormField).at(3), '12');

      // Scroll down to make submit button visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('إنشاء حساب'));
      await tester.pumpAndSettle();

      // Either short password error or mismatch error should show
      final shortPwdError = find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      expect(shortPwdError, findsWidgets);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      // Should have 2 visibility toggles (password + confirm password)
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));

      // Tap first toggle
      await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
      await tester.pumpAndSettle();

      // Now one should be visibility_outlined
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('shows login link at bottom', (tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('لديك حساب؟  '), findsOneWidget);
      expect(find.text('سجّل دخول'), findsOneWidget);
    });
  });
}
