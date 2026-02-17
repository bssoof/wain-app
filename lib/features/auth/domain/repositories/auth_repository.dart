import '../entities/app_user.dart';

/// Abstract interface for Authentication Repository
/// Handles Firebase Phone Auth with OTP
abstract class AuthRepository {
  /// Stream of auth state changes
  Stream<AppUser?> get authStateChanges;

  /// Get current user (null if not logged in)
  Future<AppUser?> get currentUser;

  /// Check if user is logged in
  Future<bool> get isLoggedIn;

  /// Check if current user is a guest (anonymous)
  Future<bool> get isGuest;

  /// Send OTP to phone number
  /// Returns verification ID needed for verifyOtp
  Future<String> sendOtp(String phoneNumber);

  /// Verify OTP and sign in
  /// Returns the authenticated user
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Continue as guest (anonymous auth)
  Future<AppUser> continueAsGuest();

  /// Sign out
  Future<void> signOut();

  /// Link anonymous account to phone number
  Future<AppUser> linkPhoneToGuest({
    required String verificationId,
    required String smsCode,
  });

  /// Save user data to Firestore
  Future<void> saveUserToFirestore(AppUser user);

  /// Get user data from Firestore
  Future<AppUser?> getUserFromFirestore(String uid);

  /// Sign in with Google
  Future<AppUser> signInWithGoogle();

  /// Sign up with email and password
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with email and password
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Send email verification
  Future<void> sendEmailVerification();

  /// Check if email is verified
  Future<bool> isEmailVerified();

  /// Update user's username
  Future<void> updateUsername(String uid, String username);

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username);

  /// Update user profile (displayName, photoUrl)
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
  });
}
