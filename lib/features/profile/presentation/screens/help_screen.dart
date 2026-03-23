import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          _SectionShell(
            title: l10n.helpContactUs,
            child: Column(
              children: [
                _ContactTile(
                  icon: Icons.email_outlined,
                  title: l10n.helpEmail,
                  subtitle: 'support@wain.app',
                  onTap: _launchEmail,
                ),
                const SizedBox(height: AppSpacing.md),
                _ContactTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: l10n.helpWhatsApp,
                  subtitle: '+970 59 XXX XXXX',
                  onTap: _launchWhatsApp,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionShell(
            title: l10n.helpFaq,
            child: Column(
              children: [
                _FaqTile(
                  question: l10n.helpFaqOffersQ,
                  answer: l10n.helpFaqOffersA,
                ),
                const SizedBox(height: AppSpacing.md),
                _FaqTile(
                  question: l10n.helpFaqMultiUseQ,
                  answer: l10n.helpFaqMultiUseA,
                ),
                const SizedBox(height: AppSpacing.md),
                _FaqTile(
                  question: l10n.helpFaqLocationQ,
                  answer: l10n.helpFaqLocationA,
                ),
                const SizedBox(height: AppSpacing.md),
                _FaqTile(
                  question: l10n.helpFaqAddPlaceQ,
                  answer: l10n.helpFaqAddPlaceA,
                ),
                const SizedBox(height: AppSpacing.md),
                _FaqTile(
                  question: l10n.helpFaqFreeQ,
                  answer: l10n.helpFaqFreeA,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.helpTitle,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@wain.app',
      query: 'subject=Inquiry from WAIN app',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/970590000000?text=Hello, I have an inquiry',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: AppSpacing.radiusMd,
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: AppSpacing.radiusMd,
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: colorScheme.outline),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          iconColor: colorScheme.primary,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radiusMd,
          ),
          title: Text(question, style: textTheme.titleMedium),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(answer, style: textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
