import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Screen for editing user profile (username, display name)
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

    // If same as current username, it's available
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
    } catch (e) {
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

    if (user == null) return;

    // Validate username
    if (username.isNotEmpty && username.length < 3) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context)!.editProfileUsernameTooShort);
      return;
    }

    if (_isUsernameAvailable == false) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context)!.editProfileUsernameNotAvailable);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);

      // Update username if changed
      if (username.isNotEmpty &&
          username.toLowerCase() != _currentUsername?.toLowerCase()) {
        await repo.updateUsername(user.uid, username);
      }

      // Update display name if changed
      if (displayName.isNotEmpty && displayName != user.displayName) {
        await repo.updateProfile(uid: user.uid, displayName: displayName);
      }

      // Invalidate auth state to refresh user data
      ref.invalidate(authStateProvider);

      if (mounted) {
        _showSuccess(AppLocalizations.of(context)!.editProfileSaved);
        context.pop();
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(l10n.editProfileTitle),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: WainLoadingIndicator(),
                  )
                : Text(l10n.editProfileSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Username Section
          Text(
            l10n.editProfileUsername,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: l10n.editProfileUsernameHint,
              prefixText: '@',
              prefixStyle: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              suffixIcon: _buildUsernameStatusIcon(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              _checkUsernameAvailability(value);
            },
          ),
          const SizedBox(height: 4),
          Text(
            l10n.editProfileUsernameRules,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 24),

          // Display Name Section
          Text(
            l10n.editProfileDisplayName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(
              hintText: l10n.editProfileDisplayNameHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
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
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (_isUsernameAvailable == false) {
      return const Icon(Icons.cancel, color: Colors.red);
    }

    return null;
  }
}
