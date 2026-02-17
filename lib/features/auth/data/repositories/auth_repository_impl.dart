import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository using Firebase Auth
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';

  // OTP settings per PRD
  static const Duration _otpTimeout = Duration(minutes: 5);
  static const int _maxOtpAttempts = 3;

  // Track OTP attempts
  final Map<String, int> _otpAttempts = {};

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

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

      // Return basic user from Firebase Auth
      return AppUser(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        isAnonymous: user.isAnonymous,
      );
    });
  }

  @override
  Future<AppUser?> get currentUser async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final firestoreUser = await getUserFromFirestore(user.uid);
    return firestoreUser ?? AppUser(
      uid: user.uid,
      phoneNumber: user.phoneNumber ?? '',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      isAnonymous: user.isAnonymous,
    );
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
      throw AuthException('رقم الهاتف غير صالح. يجب أن يبدأ بـ +970 أو +972');
    }

    // Check OTP attempts
    final attempts = _otpAttempts[phoneNumber] ?? 0;
    if (attempts >= _maxOtpAttempts) {
      throw AuthException('تم تجاوز عدد المحاولات المسموحة. حاول لاحقاً.');
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
        throw AuthException('انتهت المهلة. حاول مرة أخرى.');
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

      final userCredential = await _auth.currentUser!.linkWithCredential(credential);
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
    await _auth.signOut();
    debugPrint('👋 User signed out');
  }

  // ============ FIRESTORE ============

  @override
  Future<void> saveUserToFirestore(AppUser user) async {
    await _usersRef.doc(user.uid).set(
      user.toJson(),
      SetOptions(merge: true),
    );
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
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        throw AuthException('تم إلغاء تسجيل الدخول');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
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

      // Save to Firestore
      await saveUserToFirestore(appUser);

      debugPrint('✅ User signed in with Google: ${user.email}');
      return appUser;

    } on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } catch (e) {
      throw AuthException('فشل تسجيل الدخول بحساب Google');
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

      // Send verification email
      await user.sendEmailVerification();

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
      throw AuthException('اسم المستخدم يجب أن يكون 3-20 حرف (أحرف، أرقام، _)');
    }

    // Check availability
    final available = await isUsernameAvailable(username);
    if (!available) {
      throw AuthException('اسم المستخدم مستخدم بالفعل');
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

  // ============ HELPERS ============

  bool _isValidPhoneNumber(String phone) {
    // Palestine phone formats: +970 or +972
    final regex = RegExp(r'^\+97[02]\d{8,9}$');
    return regex.hasMatch(phone);
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صالح';
      case 'too-many-requests':
        return 'محاولات كثيرة. حاول لاحقاً';
      case 'session-expired':
        return 'انتهت صلاحية الرمز. أعد الإرسال';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-credential':
        return 'بيانات الدخول غير صحيحة';
      default:
        return 'حدث خطأ. حاول مرة أخرى';
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
