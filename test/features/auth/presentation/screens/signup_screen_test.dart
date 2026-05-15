import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:wain_app/features/auth/domain/entities/app_user.dart';
import 'package:wain_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
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

Future<void> enterValidSignupForm(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'باسل');
  await tester.enterText(find.byType(TextFormField).at(1), 'basil@test.com');
  await tester.enterText(find.byType(TextFormField).at(2), 'pass123');
  await tester.enterText(find.byType(TextFormField).at(3), 'pass123');
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

    testWidgets('shows repository signup error instead of generic error', (
      tester,
    ) async {
      const errorMessage = 'البريد الإلكتروني مستخدم بالفعل';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _SignupAuthRepository(signupError: AuthException(errorMessage)),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SignupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await enterValidSignupForm(tester);
      await tapSubmit(tester);

      final context = tester.element(find.byType(SignupScreen));
      final l10n = AppLocalizations.of(context)!;
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text(l10n.loginErrorDefault), findsNothing);
    });

    testWidgets('continues signup when display name update fails', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/signup',
        routes: [
          GoRoute(
            path: '/signup',
            builder: (context, state) =>
                const SignupScreen(redirectTo: '/done'),
          ),
          GoRoute(
            path: '/done',
            builder: (context, state) => const Scaffold(body: Text('done')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _SignupAuthRepository(
                profileUpdateError: AuthException('profile update failed'),
              ),
            ),
          ],
          child: MaterialApp.router(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await enterValidSignupForm(tester);
      await tapSubmit(tester);

      expect(find.text('done'), findsOneWidget);
    });
  });
}

class _SignupAuthRepository implements AuthRepository {
  _SignupAuthRepository({this.signupError, this.profileUpdateError});

  final Object? signupError;
  final Object? profileUpdateError;

  AppUser get _user => AppUser(
    uid: 'user-1',
    phoneNumber: '',
    email: 'basil@test.com',
    createdAt: DateTime(2026),
  );

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
  }) async => _user;

  @override
  Future<AppUser> signInWithGoogle() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final error = signupError;
    if (error != null) {
      throw error;
    }
    return _user;
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {
    final error = profileUpdateError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> updateUsername(String uid, String username) async {}

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async => _user;
}
