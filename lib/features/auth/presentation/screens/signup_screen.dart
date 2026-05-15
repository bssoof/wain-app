import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Email registration screen brought onto the shared design system while
/// preserving the existing auth behavior.
class SignupScreen extends ConsumerStatefulWidget {
  final String? redirectTo;

  const SignupScreen({super.key, this.redirectTo});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _finishAuthFlow() {
    final redirectTo = widget.redirectTo;
    if (redirectTo != null && redirectTo.isNotEmpty) {
      context.go(redirectTo);
      return;
    }
    final landing = ref.read(discoveryCompletedProvider) ? '/results' : '/home';
    context.go(landing);
  }

  String get _loginRoute => Uri(
    path: '/login',
    queryParameters: widget.redirectTo == null
        ? null
        : {'redirectTo': widget.redirectTo!},
  ).toString();

  void _dismiss() {
    context.popOrGo(_loginRoute);
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ref
          .read(authActionsProvider.notifier)
          .signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            l10n: AppLocalizations.of(context)!,
          );
      if (!mounted || user == null) {
        return;
      }

      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        try {
          await ref
              .read(authRepositoryProvider)
              .updateProfile(uid: user.uid, displayName: name);
        } catch (e) {
          debugPrint('⚠️ Profile name update failed after signup: $e');
        }
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        message: AppLocalizations.of(context)!.signupSuccess,
        color: AppTheme.successColor,
      );

      _finishAuthFlow();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final message = _normalizeAuthError(e.toString());
        _showSnackBar(
          message: message.isNotEmpty ? message : l10n.loginErrorDefault,
          color: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _normalizeAuthError(String error) {
    if (error.startsWith('Exception: ')) {
      return error.substring(11).trim();
    }
    return error.trim();
  }

  void _showSnackBar({required String message, required Color color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                      onPressed: _dismiss,
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
                    child: Form(
                      key: _formKey,
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
                            l10n.signupTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.signupSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildNameInput(l10n),
                          const SizedBox(height: AppSpacing.md),
                          _buildEmailInput(l10n),
                          const SizedBox(height: AppSpacing.md),
                          _buildPasswordInput(l10n),
                          const SizedBox(height: AppSpacing.md),
                          _buildConfirmPasswordInput(l10n),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton.primary(
                            label: l10n.signupBtn,
                            onPressed: _handleSignUp,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.signupHaveAccount,
                                style: theme.textTheme.bodyMedium,
                              ),
                              GestureDetector(
                                onTap: _dismiss,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: AppSpacing.xs,
                                  ),
                                  child: Text(
                                    l10n.signupLogin,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildNameInput(AppLocalizations l10n) {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: l10n.signupNameLabel,
        hintText: l10n.signupNameHint,
        prefixIcon: const Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.signupNameRequired;
        }
        return null;
      },
    );
  }

  Widget _buildEmailInput(AppLocalizations l10n) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: l10n.signupEmailLabel,
        hintText: l10n.signupEmailHint,
        prefixIcon: const Icon(Icons.mail_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.signupEmailRequired;
        }
        final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
        if (!emailRegex.hasMatch(value.trim())) {
          return l10n.signupEmailInvalid;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordInput(AppLocalizations l10n) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: l10n.signupPasswordLabel,
        hintText: l10n.signupPasswordPlaceholder,
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
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.signupPasswordRequired;
        }
        if (value.length < 6) {
          return l10n.signupPasswordWeak;
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordInput(AppLocalizations l10n) {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: l10n.signupConfirmLabel,
        hintText: l10n.signupPasswordPlaceholder,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => _obscureConfirm = !_obscureConfirm);
          },
          icon: Icon(
            _obscureConfirm
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.signupConfirmRequired;
        }
        if (value != _passwordController.text) {
          return l10n.signupConfirmMismatch;
        }
        return null;
      },
    );
  }
}
