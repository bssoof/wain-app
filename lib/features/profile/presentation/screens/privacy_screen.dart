import 'package:flutter/material.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';

import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyTitle),
        leading: IconButton(
          onPressed: () => context.popOrGo('/profile'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(l10n.privacyTitle, style: textTheme.displayMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(l10n.privacyLastUpdate, style: textTheme.titleSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _PrivacySection(
                title: l10n.privacySection1Title,
                body: l10n.privacySection1Body,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PrivacySection(
                title: l10n.privacySection2Title,
                body: l10n.privacySection2Body,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PrivacySection(
                title: l10n.privacySection3Title,
                body: l10n.privacySection3Body,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PrivacySection(
                title: l10n.privacySection4Title,
                body: l10n.privacySection4Body,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PrivacySection(
                title: l10n.privacySection5Title,
                body: l10n.privacySection5Body,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PrivacySection(
                title: l10n.privacySection6Title,
                body: l10n.privacySection6Body,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final String body;

  const _PrivacySection({required this.title, required this.body});

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
            Text(title, style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Text(body, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
