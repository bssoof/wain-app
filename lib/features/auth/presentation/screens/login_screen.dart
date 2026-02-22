import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Login Screen -- Simplified: Phone, Email, Google, Guest
/// OTP and Sign Up have been moved to separate screens.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isEmailMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============ ACTIONS ============

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError(AppLocalizations.of(context)!.loginErrorPhone);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final verificationId = await ref
          .read(authActionsProvider.notifier)
          .sendOtp(phone);
      if (!mounted) return;
      if (verificationId != null) {
        // Navigate to OTP screen
        context.push(
          '/otp',
          extra: {'phoneNumber': phone, 'verificationId': verificationId},
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError(AppLocalizations.of(context)!.loginErrorEmailPassword);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ref
          .read(authActionsProvider.notifier)
          .signInWithEmail(email: email, password: password);
      if (!mounted) return;
      if (user != null) {
        context.pop();
        _showSuccess(AppLocalizations.of(context)!.loginWelcome);
      }
    } catch (e) {
      if (mounted) _showError(_mapErrorMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await ref
          .read(authActionsProvider.notifier)
          .signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        context.pop();
        _showSuccess(AppLocalizations.of(context)!.loginWelcomeUser(user.displayName ?? ''));
      } else {
        _showError(AppLocalizations.of(context)!.loginGoogleFailed);
      }
    } catch (e) {
      if (mounted) _showError(AppLocalizations.of(context)!.loginErrorGeneric(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authActionsProvider.notifier).continueAsGuest();
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapErrorMessage(String error) {
    final l10n = AppLocalizations.of(context)!;
    if (error.contains('user-not-found')) {
      return l10n.loginErrorUserNotFound;
    } else if (error.contains('wrong-password')) {
      return l10n.loginErrorWrongPassword;
    } else if (error.contains('invalid-credential')) {
      return l10n.loginErrorInvalidCredential;
    }
    return l10n.loginErrorDefault;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
    );
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close),
                ),
              ),

              const SizedBox(height: 40),

              // Logo
              Center(
                child: Text(
                  'W',
                  style: TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                l10n.loginTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loginSubtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Google Sign In
              _buildGoogleButton(),
              const SizedBox(height: 16),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.loginOr,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 16),

              // Phone / Email modes
              if (!_isEmailMode) ...[
                _buildPhoneInput(),
                const SizedBox(height: 16),
                _buildSendOtpButton(),
              ] else ...[
                _buildEmailInput(),
                const SizedBox(height: 12),
                _buildPasswordInput(),
                const SizedBox(height: 16),
                _buildEmailLoginButton(),
                const SizedBox(height: 12),
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.loginNoAccount,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: Text(
                        l10n.loginCreateAccount,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Toggle Phone/Email
              TextButton.icon(
                onPressed: () {
                  setState(() => _isEmailMode = !_isEmailMode);
                },
                icon: Icon(_isEmailMode ? Icons.phone : Icons.email),
                label: Text(
                  _isEmailMode
                      ? l10n.loginUsePhone
                      : l10n.loginUseEmail,
                ),
              ),

              const SizedBox(height: 32),

              // Continue as Guest
              TextButton(
                onPressed: _isLoading ? null : _continueAsGuest,
                child: Text(
                  l10n.loginContinueGuest,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ WIDGETS ============

  Widget _buildGoogleButton() {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _signInWithGoogle,
      icon: Image.network(
        'https://www.google.com/favicon.ico',
        width: 24,
        height: 24,
        errorBuilder: (_, _, _) => const Icon(Icons.g_mobiledata, size: 24),
      ),
      label: Text(l10n.loginGoogle),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPhoneInput() {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: l10n.loginPhoneLabel,
        hintText: l10n.loginPhoneHint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSendOtpButton() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: WainLoadingIndicator(),
              )
            : Text(
                l10n.loginSendOtp,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildEmailInput() {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        hintText: l10n.loginEmailHint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.mail_outline, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPasswordInput() {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        hintText: l10n.loginPasswordHint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppTheme.textSecondary,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildEmailLoginButton() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: WainLoadingIndicator(),
              )
            : Text(
                l10n.loginEmailBtn,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
