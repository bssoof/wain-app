import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

/// Login screen that preserves all current auth methods while moving
/// the UI onto shared theme tokens and components.
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
          .sendOtp(phone, l10n: AppLocalizations.of(context)!);
      if (!mounted) return;
      if (verificationId != null) {
        context.push(
          '/otp',
          extra: {'phoneNumber': phone, 'verificationId': verificationId},
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          .signInWithEmail(
            email: email,
            password: password,
            l10n: AppLocalizations.of(context)!,
          );
      if (!mounted) return;
      if (user != null) {
        context.pop();
        _showSuccess(AppLocalizations.of(context)!.loginWelcome);
      }
    } catch (e) {
      if (mounted) _showError(_mapErrorMessage(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await ref
          .read(authActionsProvider.notifier)
          .signInWithGoogle(l10n: AppLocalizations.of(context)!);
      if (!mounted) return;
      if (user != null) {
        context.pop();
        _showSuccess(
          AppLocalizations.of(
            context,
          )!.loginWelcomeUser(user.displayName ?? ''),
        );
      } else {
        _showError(AppLocalizations.of(context)!.loginGoogleFailed);
      }
    } catch (e) {
      if (mounted) {
        _showError(_normalizeAuthError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapErrorMessage(String error) {
    final l10n = AppLocalizations.of(context)!;
    if (error.contains('user-not-found')) {
      return l10n.loginErrorUserNotFound;
    }
    if (error.contains('wrong-password')) {
      return l10n.loginErrorWrongPassword;
    }
    if (error.contains('invalid-credential')) {
      return l10n.loginErrorInvalidCredential;
    }
    return l10n.loginErrorDefault;
  }

  String _normalizeAuthError(String error) {
    if (error.startsWith('Exception: ')) {
      return error.substring(11).trim();
    }
    return error;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.successColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: theme.colorScheme.outline),
                      boxShadow: AppShadows.elevated,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'W',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.loginTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.loginSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildGoogleButton(theme),
                        const SizedBox(height: AppSpacing.lg),
                        _buildDivider(theme, l10n.loginOr),
                        const SizedBox(height: AppSpacing.lg),
                        if (_isEmailMode) ...[
                          _buildEmailInput(l10n),
                          const SizedBox(height: AppSpacing.md),
                          _buildPasswordInput(l10n),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton.primary(
                            label: l10n.loginEmailBtn,
                            onPressed: _signInWithEmail,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.loginNoAccount,
                                style: theme.textTheme.bodyMedium,
                              ),
                              GestureDetector(
                                onTap: () => context.push('/signup'),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: AppSpacing.xs,
                                  ),
                                  child: Text(
                                    l10n.loginCreateAccount,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildPhoneInput(l10n),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton.primary(
                            label: l10n.loginSendOtp,
                            onPressed: _sendOtp,
                            isLoading: _isLoading,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        AppButton.tertiary(
                          label: _isEmailMode
                              ? l10n.loginUsePhone
                              : l10n.loginUseEmail,
                          icon: Icon(
                            _isEmailMode
                                ? Icons.phone_outlined
                                : Icons.mail_outline,
                            size: 18,
                          ),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() => _isEmailMode = !_isEmailMode);
                                },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: _isLoading ? null : _continueAsGuest,
                          child: Text(
                            l10n.loginContinueGuest,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        icon: _isLoading
            ? SizedBox.square(
                dimension: 20,
                child: WainLoadingIndicator(
                  size: 20,
                  fallbackColor: theme.colorScheme.primary,
                ),
              )
            : Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'G',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
        label: Text(l10n.loginGoogle),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme, String label) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outline)),
      ],
    );
  }

  Widget _buildPhoneInput(AppLocalizations l10n) {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _isLoading ? null : _sendOtp(),
      decoration: InputDecoration(
        labelText: l10n.loginPhoneLabel,
        hintText: l10n.loginPhoneHint,
        prefixIcon: const Icon(Icons.phone_outlined),
      ),
    );
  }

  Widget _buildEmailInput(AppLocalizations l10n) {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textDirection: TextDirection.ltr,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: l10n.loginEmailHint,
        hintText: l10n.loginEmailHint,
        prefixIcon: const Icon(Icons.mail_outline),
      ),
    );
  }

  Widget _buildPasswordInput(AppLocalizations l10n) {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textDirection: TextDirection.ltr,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _isLoading ? null : _signInWithEmail(),
      decoration: InputDecoration(
        labelText: l10n.loginPasswordHint,
        hintText: l10n.loginPasswordHint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
    );
  }
}
