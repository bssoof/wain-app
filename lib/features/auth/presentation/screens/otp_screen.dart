import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/auth/presentation/utils/auth_landing_resolver.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// OTP verification screen aligned with the shared design system.
class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final String? redirectTo;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.redirectTo,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _timer;
  late String _verificationId;

  Future<void> _finishAuthFlow({String? signedInUid}) async {
    final landing = await resolvePostAuthLandingRoute(
      ref,
      redirectTo: widget.redirectTo,
      signedInUid: signedInUid,
    );
    if (!mounted) return;
    context.go(landing);
  }

  String get _loginRoute => Uri(
    path: '/login',
    queryParameters: widget.redirectTo == null
        ? null
        : {'redirectTo': widget.redirectTo!},
  ).toString();

  void _returnToLogin() {
    context.popOrGo(_loginRoute);
  }

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startCountdown();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String get _otpCode =>
      _controllers.map((controller) => controller.text).join();

  Future<void> _verifyOtp() async {
    final l10n = AppLocalizations.of(context)!;
    if (_otpCode.length != 6) {
      _showSnackBar(
        message: l10n.otpInvalid,
        color: Theme.of(context).colorScheme.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ref
          .read(authActionsProvider.notifier)
          .verifyOtp(
            verificationId: _verificationId,
            smsCode: _otpCode,
            l10n: l10n,
          );

      if (!mounted || user == null) {
        return;
      }

      await _finishAuthFlow(signedInUid: user.uid);
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          message: e.toString(),
          color: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final l10n = AppLocalizations.of(context)!;
      final newVerificationId = await ref
          .read(authActionsProvider.notifier)
          .sendOtp(widget.phoneNumber, l10n: l10n);
      if (!mounted || newVerificationId == null) {
        return;
      }

      _verificationId = newVerificationId;
      _startCountdown();
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes.first.requestFocus();
      _showSnackBar(message: l10n.otpResent, color: AppTheme.successColor);
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          message: e.toString(),
          color: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      onPressed: _returnToLogin,
                      icon: const Icon(Icons.arrow_back_rounded),
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
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: theme.colorScheme.primary,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.otpTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        RichText(
                          textAlign: TextAlign.start,
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(text: l10n.otpSentTo),
                              TextSpan(
                                text: widget.phoneNumber,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (index) {
                              return Container(
                                width: 48,
                                height: 56,
                                margin: EdgeInsetsDirectional.only(
                                  start: index == 0 ? 0 : 6,
                                ),
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 5) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  },
                                  style: theme.textTheme.headlineSmall,
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppButton.primary(
                          label: l10n.otpVerifyBtn,
                          onPressed: _verifyOtp,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: TextButton(
                            onPressed: _isLoading || _resendCountdown > 0
                                ? null
                                : _resendOtp,
                            child: Text(
                              _resendCountdown > 0
                                  ? l10n.otpResendCountdown(_resendCountdown)
                                  : l10n.otpResend,
                            ),
                          ),
                        ),
                        AppButton.tertiary(
                          label: l10n.otpChangePhone,
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          onPressed: _isLoading ? null : _returnToLogin,
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
}
