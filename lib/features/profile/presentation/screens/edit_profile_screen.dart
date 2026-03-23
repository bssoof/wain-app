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

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final user = await ref.read(authStateProvider.future);
    if (user != null && mounted) {
      setState(() {
        _currentUsername = user.username;
        _usernameController.text = user.username ?? '';
        _displayNameController.text = user.displayName ?? '';
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
      });
      return;
    }

    if (username.toLowerCase() == _currentUsername?.toLowerCase()) {
      setState(() {
        _isUsernameAvailable = true;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
    });

    try {
      final available = await ref
          .read(authRepositoryProvider)
          .isUsernameAvailable(username);
      if (mounted) {
        setState(() {
          _isUsernameAvailable = available;
          _isCheckingUsername = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isUsernameAvailable = null;
          _isCheckingUsername = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final user = await ref.read(authStateProvider.future);

    if (user == null) {
      return;
    }

    if (username.isNotEmpty && username.length < 3) {
      if (!mounted) {
        return;
      }
      _showError(AppLocalizations.of(context)!.editProfileUsernameTooShort);
      return;
    }

    if (_isUsernameAvailable == false) {
      if (!mounted) {
        return;
      }
      _showError(AppLocalizations.of(context)!.editProfileUsernameNotAvailable);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);

      if (username.isNotEmpty &&
          username.toLowerCase() != _currentUsername?.toLowerCase()) {
        await repo.updateUsername(user.uid, username);
      }

      if (displayName.isNotEmpty && displayName != user.displayName) {
        await repo.updateProfile(uid: user.uid, displayName: displayName);
      }

      ref.invalidate(authStateProvider);

      if (mounted) {
        _showSuccess(AppLocalizations.of(context)!.editProfileSaved);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
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
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: AppButton.primary(
          label: l10n.editProfileSave,
          onPressed: _isLoading ? null : _saveProfile,
          isLoading: _isLoading,
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppSpacing.radiusLg,
              border: Border.all(color: colorScheme.outline),
              boxShadow: AppShadows.elevated,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.editProfileTitle, style: textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.editProfileUsernameRules,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _FieldSection(
            label: l10n.editProfileUsername,
            child: TextField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: l10n.editProfileUsernameHint,
                prefixText: '@',
                prefixStyle: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                ),
                suffixIcon: _buildUsernameStatusIcon(),
              ),
              onChanged: _checkUsernameAvailability,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _FieldSection(
            label: l10n.editProfileDisplayName,
            helper: l10n.editProfileDisplayNameHint,
            child: TextField(
              controller: _displayNameController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _isLoading ? null : _saveProfile(),
              decoration: InputDecoration(
                hintText: l10n.editProfileDisplayNameHint,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget? _buildUsernameStatusIcon() {
    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(width: 20, height: 20, child: WainLoadingIndicator()),
      );
    }

    if (_isUsernameAvailable == true) {
      return const Icon(
        Icons.check_circle_rounded,
        color: AppTheme.successColor,
      );
    }

    if (_isUsernameAvailable == false) {
      return const Icon(Icons.cancel_rounded, color: AppTheme.errorColor);
    }

    return null;
  }
}

class _FieldSection extends StatelessWidget {
  final String label;
  final String? helper;
  final Widget child;

  const _FieldSection({required this.label, required this.child, this.helper});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            child,
            if (helper != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                helper!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
