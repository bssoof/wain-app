import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository using Firebase Auth
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  AppLocalizations? _l10n;

  static const String _usersCollection = 'users';

  // OTP settings per PRD
  static const Duration _otpTimeout = Duration(minutes: 5);
  static const int _maxOtpAttempts = 3;

  // Track OTP attempts
  final Map<String, int> _otpAttempts = {};

  AuthRepositoryImpl({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Set the localization instance from the UI layer
  void setLocalizations(AppLocalizations l10n) {
    _l10n = l10n;
  }

  /// Get Firestore users collection
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  // ============ AUTH STATE ============

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      // Check if user data exists in Firestore
      final firestoreUser = await getUserFromFirestore(user.uid);
      if (firestoreUser != null) {
        return firestoreUser;
      }

      // Firestore can lag behind the auth-state emission after Google sign-in.
      // Keep provider consumers useful by preserving Firebase Auth profile data.
      return _appUserFromFirebaseUser(user);
    });
  }

  @override
  Future<AppUser?> get currentUser async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final firestoreUser = await getUserFromFirestore(user.uid);
    return firestoreUser ?? _appUserFromFirebaseUser(user);
  }

  @override
  Future<bool> get isLoggedIn async {
    return _auth.currentUser != null;
  }

  @override
  Future<bool> get isGuest async {
    return _auth.currentUser?.isAnonymous ?? true;
  }

  // ============ PHONE OTP AUTH ============

  @override
  Future<String> sendOtp(String phoneNumber) async {
    // Validate phone format (Palestine: +970 or +972)
    if (!_isValidPhoneNumber(phoneNumber)) {
      throw AuthException(_l10n?.authInvalidPhone ?? 'Invalid phone number');
    }

    // Check OTP attempts
    final attempts = _otpAttempts[phoneNumber] ?? 0;
    if (attempts >= _maxOtpAttempts) {
      throw AuthException(_l10n?.authTooManyAttempts ?? 'Too many attempts');
    }

    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: _otpTimeout,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification (Android only)
        debugPrint('✅ Auto-verification completed');
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('❌ Verification failed: ${e.code} - ${e.message}');
        if (!completer.isCompleted) {
          completer.completeError(AuthException(_mapFirebaseError(e.code)));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('📱 OTP sent to $phoneNumber');
        _otpAttempts[phoneNumber] = attempts + 1;
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('⏰ Auto-retrieval timeout');
        // If completer hasn't completed, complete with the verificationId
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw AuthException(_l10n?.authTimeout ?? 'Timed out');
      },
    );
  }

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      final appUser = AppUser(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        isAnonymous: false,
      );

      // Save to Firestore
      await saveUserToFirestore(appUser);

      // Clear OTP attempts for this phone number
      _otpAttempts.remove(user.phoneNumber);

      debugPrint('✅ User signed in: ${user.uid}');
      return appUser;
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  // ============ GUEST AUTH ============

  @override
  Future<AppUser> continueAsGuest() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user!;

      debugPrint('✅ Guest signed in: ${user.uid}');

      return AppUser.guest(user.uid);
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<AppUser> linkPhoneToGuest({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.currentUser!.linkWithCredential(
        credential,
      );
      final user = userCredential.user!;

      final appUser = AppUser(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        isAnonymous: false,
      );

      await saveUserToFirestore(appUser);

      debugPrint('✅ Guest linked to phone: ${user.phoneNumber}');
      return appUser;
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  // ============ SIGN OUT ============

  @override
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {
        // Email/phone sessions may not have an attached Google account.
      }
    }
    await _auth.signOut();
    debugPrint('👋 User signed out');
  }

  // ============ FIRESTORE ============

  @override
  Future<void> saveUserToFirestore(AppUser user) async {
    await _usersRef.doc(user.uid).set(user.toJson(), SetOptions(merge: true));
  }

  @override
  Future<AppUser?> getUserFromFirestore(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  // ============ GOOGLE SIGN IN ============

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      late final UserCredential userCredential;
      String? googleDisplayName;
      String? googleEmail;
      String? googlePhotoUrl;

      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          throw AuthException(
            _l10n?.authGoogleCancelled ?? 'Sign in cancelled',
          );
        }
        googleDisplayName = googleUser.displayName;
        googleEmail = googleUser.email;
        googlePhotoUrl = googleUser.photoUrl;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }
      final user = userCredential.user!;

      final appUser = AppUser(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        displayName: _firstNonEmpty(user.displayName, googleDisplayName),
        email: _firstNonEmpty(user.email, googleEmail),
        photoUrl: _firstNonEmpty(user.photoURL, googlePhotoUrl),
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        isAnonymous: false,
      );

      // Save to Firestore
      await saveUserToFirestore(appUser);

      debugPrint('✅ User signed in with Google: ${user.email}');
      return appUser;
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      final mapped = _mapFirebaseError(e.code);
      final generic = _l10n?.authGenericError ?? 'An error occurred';
      if (mapped == generic) {
        final details = (e.message != null && e.message!.trim().isNotEmpty)
            ? '${e.code}: ${e.message}'
            : e.code;
        throw AuthException(
          '${_l10n?.authGoogleFailed ?? 'Google sign in failed'} ($details)',
        );
      }
      throw AuthException(mapped);
    } catch (e) {
      if (e.toString().contains('popup_closed_by_user')) {
        throw AuthException(_l10n?.authGoogleCancelled ?? 'Sign in cancelled');
      }
      throw AuthException(
        '${_l10n?.authGoogleFailed ?? 'Google sign in failed'}: $e',
      );
    }
  }

  // ============ EMAIL AUTH ============

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;

      try {
        await user.sendEmailVerification();
      } catch (e) {
        debugPrint('⚠️ Email verification send failed after signup: $e');
      }

      final appUser = AppUser(
        uid: user.uid,
        phoneNumber: '',
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        isAnonymous: false,
      );

      await saveUserToFirestore(appUser);

      debugPrint('✅ User signed up with email: ${user.email}');
      return appUser;
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user!;

      final appUser = AppUser(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        isAnonymous: false,
      );

      debugPrint('✅ User signed in with email: ${user.email}');
      return appUser;
    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      debugPrint('📧 Verification email sent to ${user.email}');
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  // ============ USERNAME & PROFILE ============

  @override
  Future<void> updateUsername(String uid, String username) async {
    // Validate username format
    if (!_isValidUsername(username)) {
      throw AuthException(
        _l10n?.authUsernameInvalid ?? 'Invalid username format',
      );
    }

    // Check availability
    final available = await isUsernameAvailable(username);
    if (!available) {
      throw AuthException(_l10n?.authUsernameTaken ?? 'Username taken');
    }

    // Update in users collection
    await _firestore.collection('users').doc(uid).update({
      'username': username.toLowerCase(),
    });

    // Store in usernames collection for uniqueness lookup
    await _firestore.collection('usernames').doc(username.toLowerCase()).set({
      'uid': uid,
      'created_at': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Username updated: @$username');
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    if (!_isValidUsername(username)) return false;

    final doc = await _firestore
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();

    return !doc.exists;
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};

    if (displayName != null) {
      updates['display_name'] = displayName;
    }
    if (photoUrl != null) {
      updates['photo_url'] = photoUrl;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
      debugPrint('✅ Profile updated');
    }
  }

  bool _isValidUsername(String username) {
    // 3-20 characters, alphanumeric and underscore only
    final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return regex.hasMatch(username);
  }

  AppUser _appUserFromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      phoneNumber: user.phoneNumber ?? '',
      displayName: _firstNonEmpty(user.displayName),
      email: _firstNonEmpty(user.email),
      photoUrl: _firstNonEmpty(user.photoURL),
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      isAnonymous: user.isAnonymous,
    );
  }

  String? _firstNonEmpty(String? primary, [String? secondary]) {
    for (final value in [primary, secondary]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  // ============ HELPERS ============

  bool _isValidPhoneNumber(String phone) {
    // Palestine phone formats: +970 or +972
    final regex = RegExp(r'^\+97[02]\d{8,9}$');
    return regex.hasMatch(phone);
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return _l10n?.authInvalidVerificationCode ??
            'Invalid verification code';
      case 'invalid-phone-number':
        return _l10n?.authInvalidPhoneNumber ?? 'Invalid phone number';
      case 'too-many-requests':
        return _l10n?.authTooManyRequests ?? 'Too many requests';
      case 'session-expired':
        return _l10n?.authSessionExpired ?? 'Session expired';
      case 'email-already-in-use':
        return _l10n?.authEmailAlreadyInUse ?? 'Email already in use';
      case 'invalid-email':
        return _l10n?.authInvalidEmail ?? 'Invalid email';
      case 'weak-password':
        return _l10n?.authWeakPassword ?? 'Weak password';
      case 'user-not-found':
        return _l10n?.authUserNotFound ?? 'User not found';
      case 'wrong-password':
        return _l10n?.authWrongPassword ?? 'Wrong password';
      case 'invalid-credential':
        return _l10n?.authInvalidCredential ?? 'Invalid credential';
      case 'popup-blocked':
        return _l10n?.authPopupBlocked ??
            'Popup blocked. Allow popups and try again';
      case 'popup-closed-by-user':
        return _l10n?.authGoogleCancelled ?? 'Sign in cancelled';
      case 'cancelled-popup-request':
        return _l10n?.authGoogleCancelled ?? 'Sign in cancelled';
      case 'unauthorized-domain':
        return _l10n?.authUnauthorizedDomain ??
            'This domain is not authorized for Google sign in';
      case 'operation-not-allowed':
        return _l10n?.authGoogleProviderDisabled ??
            'Google sign in is not enabled';
      case 'configuration-not-found':
        return _l10n?.authGoogleProviderDisabled ??
            'Google sign in is not enabled';
      case 'operation-not-supported-in-this-environment':
        return _l10n?.authWebPopupUnsupported ??
            'Google sign in is not supported in this browser environment';
      case 'network-request-failed':
        return _l10n?.authNetworkFailed ??
            'Network error. Check your connection and try again';
      case 'web-storage-unsupported':
        return _l10n?.authWebStorageUnsupported ??
            'Browser storage is blocked. Allow cookies/storage and try again';
      default:
        return _l10n?.authGenericError ?? 'An error occurred';
    }
  }
}

/// Custom exception for auth errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
