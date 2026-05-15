import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:wain_app/features/auth/domain/entities/app_user.dart';
import 'package:wain_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
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

    testWidgets(
      'shows repository email auth message instead of generic error',
      (tester) async {
        const errorMessage = 'بيانات الدخول غير صحيحة';

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                _FailingEmailAuthRepository(errorMessage),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final toEmailMode = find.widgetWithIcon(TextButton, Icons.mail_outline);
        await tester.ensureVisible(toEmailMode);
        await tester.tap(toEmailMode);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextField).at(1), 'password123');

        final context = tester.element(find.byType(LoginScreen));
        final l10n = AppLocalizations.of(context)!;
        await tester.tap(find.widgetWithText(AppButton, l10n.loginEmailBtn));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text(errorMessage), findsOneWidget);
        expect(find.text(l10n.loginErrorDefault), findsNothing);
      },
    );
  });
}

class _FailingEmailAuthRepository implements AuthRepository {
  _FailingEmailAuthRepository(this.errorMessage);

  final String errorMessage;

  AppUser get _user =>
      AppUser(uid: 'user-1', phoneNumber: '', createdAt: DateTime(2026));

  @override
  Stream<AppUser?> get authStateChanges => Stream<AppUser?>.value(null);

  @override
  Future<AppUser?> get currentUser async => null;

  @override
  Future<bool> get isLoggedIn async => false;

  @override
  Future<bool> get isGuest async => true;

  @override
  Future<AppUser> continueAsGuest() async => _user;

  @override
  Future<AppUser?> getUserFromFirestore(String uid) async => null;

  @override
  Future<bool> isEmailVerified() async => false;

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<AppUser> linkPhoneToGuest({
    required String verificationId,
    required String smsCode,
  }) async => _user;

  @override
  Future<void> saveUserToFirestore(AppUser user) async {}

  @override
  Future<String> sendOtp(String phoneNumber) async => 'verification-id';

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw AuthException(errorMessage);
  }

  @override
  Future<AppUser> signInWithGoogle() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {}

  @override
  Future<void> updateUsername(String uid, String username) async {}

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async => _user;
}
