import 'package:flutter/material.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';

import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutTitle),
        leading: IconButton(
          onPressed: () => context.popOrGo('/profile'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(color: colorScheme.outline),
                boxShadow: AppShadows.elevated,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: AppSpacing.radiusLg,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.place_rounded,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.aboutAppName,
                      style: textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.aboutVersion,
                      style: textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.aboutDescription,
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
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
                    Text(l10n.aboutTitle, style: textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.lg),
                    _FeatureRow(
                      icon: Icons.location_on_rounded,
                      text: l10n.aboutFeatureDiscover,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FeatureRow(
                      icon: Icons.local_offer_rounded,
                      text: l10n.aboutFeatureOffers,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FeatureRow(
                      icon: Icons.favorite_rounded,
                      text: l10n.aboutFeatureFavorites,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FeatureRow(
                      icon: Icons.navigation_rounded,
                      text: l10n.aboutFeatureNavigation,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '2026 WAIN App',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSpacing.touchTargetMin,
          height: AppSpacing.touchTargetMin,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: AppSpacing.radiusMd,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(text, style: textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}
