import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueSocialLinksSection extends StatelessWidget {
  final Venue venue;

  const VenueSocialLinksSection({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final links = <_SocialLink>[
      if (venue.instagram.isNotEmpty)
        _SocialLink(
          icon: Icons.camera_alt_rounded,
          label: 'Instagram',
          url: 'https://instagram.com/${venue.instagram}',
        ),
      if (venue.facebook.isNotEmpty)
        _SocialLink(
          icon: Icons.facebook_rounded,
          label: 'Facebook',
          url: venue.facebook,
        ),
      if (venue.website.isNotEmpty)
        _SocialLink(
          icon: Icons.language_rounded,
          label: 'Website',
          url: venue.website,
        ),
      if (venue.whatsapp.isNotEmpty)
        _SocialLink(
          icon: Icons.chat_bubble_outline_rounded,
          label: l10n.whatsapp,
          url: 'https://wa.me/${venue.whatsappNumber}',
        ),
    ];

    if (links.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurfaceColor,
                  borderRadius: AppSpacing.radiusMd,
                ),
                child: Icon(
                  Icons.link_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(l10n.socialLinks, style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: links.map((link) => _SocialLinkChip(link: link)).toList(),
          ),
        ],
      ),
    );
  }
}

class _SocialLinkChip extends StatelessWidget {
  final _SocialLink link;

  const _SocialLinkChip({required this.link});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: AppSpacing.radiusFull,
      onTap: () async {
        final uri = Uri.tryParse(link.url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primarySurfaceColor,
          borderRadius: AppSpacing.radiusFull,
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(link.icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              link.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialLink {
  final IconData icon;
  final String label;
  final String url;

  const _SocialLink({
    required this.icon,
    required this.label,
    required this.url,
  });
}
