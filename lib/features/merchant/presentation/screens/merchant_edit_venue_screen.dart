import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../providers/merchant_dashboard_providers.dart';

class MerchantEditVenueScreen extends ConsumerStatefulWidget {
  const MerchantEditVenueScreen({super.key});

  @override
  ConsumerState<MerchantEditVenueScreen> createState() =>
      _MerchantEditVenueScreenState();
}

class _MerchantEditVenueScreenState
    extends ConsumerState<MerchantEditVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _initFields(Map<String, dynamic> venue) {
    if (_initialized) {
      return;
    }

    _nameArController.text = venue['name_ar'] ?? '';
    _nameEnController.text = venue['name_en'] ?? '';
    _phoneController.text = venue['phone'] ?? '';
    _cityController.text = venue['city'] ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) {
        throw Exception(l10n.editVenueNoVenue);
      }

      await FirebaseFirestore.instance
          .collection('venues')
          .doc(venueId)
          .update({
            'name_ar': _nameArController.text.trim(),
            'name_en': _nameEnController.text.trim(),
            'phone': _phoneController.text.trim(),
            'city': _cityController.text.trim(),
            'updated_at': FieldValue.serverTimestamp(),
          });

      ref.invalidate(merchantVenueProvider);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.editVenueSaved),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.popOrGo('/merchant/dashboard');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.editVenueSaveError(error.toString())),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final venueAsync = ref.watch(merchantVenueProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.popOrGo('/merchant/dashboard'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.editVenueTitle),
      ),
      body: venueAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.editVenueError(error.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (venue) {
          if (venue == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AppEmptyState(
                  icon: Icons.storefront_outlined,
                  message: l10n.editVenueNoVenue,
                  actionLabel: l10n.merchantEnterInviteBtn,
                  onAction: () => context.push('/merchant/invite'),
                ),
              ),
            );
          }

          _initFields(venue);
          final textTheme = Theme.of(context).textTheme;
          final colorScheme = Theme.of(context).colorScheme;

          return Form(
            key: _formKey,
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                _CardShell(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: AppSpacing.radiusMd,
                        ),
                        child: Icon(
                          Icons.storefront_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue['name_ar'] ??
                                  venue['name_en'] ??
                                  l10n.editVenueTitle,
                              style: textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              venue['city']?.toString().trim().isNotEmpty ==
                                      true
                                  ? venue['city']
                                  : l10n.editVenueTitle,
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _CardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.editVenueTitle, style: textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.lg),
                      _VenueTextField(
                        controller: _nameArController,
                        label: l10n.editVenueNameAr,
                        icon: Icons.text_fields_rounded,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? l10n.editVenueRequired
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _VenueTextField(
                        controller: _nameEnController,
                        label: l10n.editVenueNameEn,
                        icon: Icons.language_rounded,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _VenueTextField(
                        controller: _phoneController,
                        label: l10n.editVenuePhone,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _VenueTextField(
                        controller: _cityController,
                        label: l10n.editVenueCity,
                        icon: Icons.location_city_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _CardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.editVenueEditHours,
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        venue['is_24h'] == true
                            ? l10n.hoursOpen24
                            : l10n.hoursScheduleHint,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton.secondary(
                        label: l10n.editVenueEditHours,
                        onPressed: () => context.push('/merchant/venue/hours'),
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton.primary(
                  label: l10n.editVenueSaveBtn,
                  onPressed: _isLoading ? null : _save,
                  isLoading: _isLoading,
                  icon: const Icon(Icons.save_outlined, size: 18),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VenueTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _VenueTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;

  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}
