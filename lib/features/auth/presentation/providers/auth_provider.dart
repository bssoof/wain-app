import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/notification_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'package:wain_app/l10n/app_localizations.dart';

part 'auth_provider.g.dart';

// ============ REPOSITORY PROVIDER ============

/// Provides AuthRepository instance
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
}

/// Call this from UI layer to inject l10n into the auth repository.
/// Usage: ref.read(authRepositoryProvider).setLocalizations(l10n);
/// (AuthRepository interface doesn't have it, cast to impl)

// ============ AUTH STATE ============

/// Stream of current user (null if not logged in)
@Riverpod(keepAlive: true)
Stream<AppUser?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

/// Current user (async)
@riverpod
Future<AppUser?> currentUser(Ref ref) {
  return ref.watch(authRepositoryProvider).currentUser;
}

/// Whether user is logged in
@riverpod
Future<bool> isLoggedIn(Ref ref) {
  return ref.watch(authRepositoryProvider).isLoggedIn;
}

/// Whether current user is a guest
@riverpod
Future<bool> isGuest(Ref ref) {
  return ref.watch(authRepositoryProvider).isGuest;
}

// ============ AUTH ACTIONS ============

/// Notifier for authentication actions
@Riverpod(keepAlive: true)
class AuthActions extends _$AuthActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Inject l10n into the auth repository for localized error messages.
  void _injectL10n(AppLocalizations l10n) {
    final repo = ref.read(authRepositoryProvider);
    if (repo is AuthRepositoryImpl) {
      repo.setLocalizations(l10n);
    }
  }

  /// Send OTP to phone number
  Future<String?> sendOtp(String phoneNumber, {AppLocalizations? l10n}) async {
    if (l10n != null) _injectL10n(l10n);
    state = const AsyncValue.loading();
    try {
      final verificationId = await ref
          .read(authRepositoryProvider)
          .sendOtp(phoneNumber);
      state = const AsyncValue.data(null);
      return verificationId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Verify OTP and sign in
  Future<AppUser?> verifyOtp({
    required String verificationId,
    required String smsCode,
    AppLocalizations? l10n,
  }) async {
    if (l10n != null) _injectL10n(l10n);
    state = const AsyncValue.loading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .verifyOtp(verificationId: verificationId, smsCode: smsCode);
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Continue as guest
  Future<AppUser?> continueAsGuest() async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).continueAsGuest();
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Sign in with Google
  Future<AppUser?> signInWithGoogle({AppLocalizations? l10n}) async {
    if (l10n != null) _injectL10n(l10n);
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Link guest account to phone
  Future<AppUser?> linkPhoneToGuest({
    required String verificationId,
    required String smsCode,
    AppLocalizations? l10n,
  }) async {
    if (l10n != null) _injectL10n(l10n);
    state = const AsyncValue.loading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .linkPhoneToGuest(verificationId: verificationId, smsCode: smsCode);
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Sign up with email and password
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    AppLocalizations? l10n,
  }) async {
    if (l10n != null) _injectL10n(l10n);
    state = const AsyncValue.loading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(email: email, password: password);
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
    AppLocalizations? l10n,
  }) async {
    if (l10n != null) _injectL10n(l10n);
    state = const AsyncValue.loading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);

      // Best-effort only: token failures should never block login success.
      try {
        await NotificationService().saveTokenToFirestore();
      } catch (_) {}

      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
    } catch (e) {
      // Ignore errors
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    return await ref.read(authRepositoryProvider).isEmailVerified();
  }
}
