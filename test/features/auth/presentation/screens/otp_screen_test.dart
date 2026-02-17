import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/features/auth/presentation/screens/otp_screen.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('OtpScreen Widget Tests', () {
    testWidgets('renders OTP screen with phone number', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const OtpScreen(
          phoneNumber: '+970599123456',
          verificationId: 'test-verification-id',
        ),
      ));
      await tester.pumpAndSettle();

      // Check for title
      expect(find.text('رمز التحقق'), findsOneWidget);

      // Check for phone number display
      expect(find.textContaining('+970599123456'), findsOneWidget);
    });

    testWidgets('renders 6 digit input fields', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const OtpScreen(
          phoneNumber: '+970599123456',
          verificationId: 'test-verification-id',
        ),
      ));
      await tester.pumpAndSettle();

      // Should have 6 TextField widgets for OTP digits
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('shows countdown timer', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const OtpScreen(
          phoneNumber: '+970599123456',
          verificationId: 'test-verification-id',
        ),
      ));
      await tester.pump(); // Don't settle due to timer animations

      // Should show resend text or countdown
      expect(find.textContaining('إعادة إرسال'), findsOneWidget);
    });

    testWidgets('shows change number option', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const OtpScreen(
          phoneNumber: '+970599123456',
          verificationId: 'test-verification-id',
        ),
      ));
      await tester.pump();

      // Should show "change number" option
      expect(find.text('تغيير الرقم'), findsOneWidget);
    });

    testWidgets('can enter digits in OTP fields', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const OtpScreen(
          phoneNumber: '+970599123456',
          verificationId: 'test-verification-id',
        ),
      ));
      await tester.pumpAndSettle();

      // Enter digit in first field
      final firstField = find.byType(TextField).first;
      await tester.tap(firstField);
      await tester.enterText(firstField, '1');
      await tester.pump();

      // Verify digit was entered
      expect(find.text('1'), findsOneWidget);
    });
  });
}
