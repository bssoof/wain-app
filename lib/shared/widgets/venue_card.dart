import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

/// Reusable venue card aligned with the app design system.
class VenueCard extends StatelessWidget {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String? distance;
  final bool isBestMatch;
  final bool isFavorite;
  final bool? isOpen;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final String? imageUrl;
  final Timestamp? lastStoryAt;

  const VenueCard({
    super.key,
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    this.distance,
    this.isBestMatch = false,
    this.isFavorite = false,
    this.isOpen,
    this.compact = false,
    this.onTap,
    this.onFavoriteToggle,
    this.imageUrl,
    this.lastStoryAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasActiveStory =
        lastStoryAt != null &&
        lastStoryAt!.toDate().isAfter(
          DateTime.now().subtract(const Duration(hours: 24)),
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.radiusLg,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(
              color: isBestMatch
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: isBestMatch ? 1.4 : 1,
            ),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageHeader(context, theme, l10n, hasActiveStory),
              Padding(
                padding: EdgeInsets.all(
                  compact ? AppSpacing.md : AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _InfoBadge(
                          icon: Icons.star_rounded,
                          label: rating.toStringAsFixed(1),
                          backgroundColor: AppTheme.warningColor.withAlpha(22),
                          foregroundColor: AppTheme.warningColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _InfoBadge(
                          icon: Icons.restaurant_menu_rounded,
                          label: category,
                          backgroundColor: theme.colorScheme.surface,
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          outlined: true,
                        ),
                        if (distance?.isNotEmpty == true)
                          _InfoBadge(
                            icon: Icons.location_on_outlined,
                            label: distance!,
                            backgroundColor: AppTheme.primarySurfaceColor,
                            foregroundColor: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool hasActiveStory,
  ) {
    final imageRadius = const BorderRadius.vertical(top: Radius.circular(20));
    final imageContent = ClipRRect(
      borderRadius: hasActiveStory ? AppSpacing.radiusMd : imageRadius,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              memCacheHeight: 400,
              memCacheWidth: 600,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: WainLoadingIndicator()),
              ),
              errorWidget: (context, url, error) => _buildImageFallback(theme),
            )
          : _buildImageFallback(theme),
    );

    return Container(
      height: compact ? 110 : 152,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: imageRadius,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasActiveStory)
            Padding(
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: AppSpacing.radiusLg,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: imageContent,
                ),
              ),
            )
          else
            imageContent,
          if (isBestMatch)
            PositionedDirectional(
              top: AppSpacing.md,
              end: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: AppSpacing.radiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.venueCardBestMatch,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          PositionedDirectional(
            top: AppSpacing.md,
            start: AppSpacing.md,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppSpacing.radiusFull,
                border: Border.all(color: theme.colorScheme.outline),
                boxShadow: AppShadows.elevated,
              ),
              child: IconButton(
                onPressed: onFavoriteToggle,
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
                  color: isFavorite
                      ? AppTheme.errorColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (isOpen != null)
            PositionedDirectional(
              start: AppSpacing.md,
              bottom: AppSpacing.md,
              child: _InfoBadge(
                icon: isOpen! ? Icons.check_circle : Icons.cancel_outlined,
                label: isOpen! ? l10n.venueCardOpen : l10n.venueCardClosed,
                backgroundColor: isOpen!
                    ? AppTheme.successColor.withAlpha(24)
                    : AppTheme.errorColor.withAlpha(24),
                foregroundColor: isOpen!
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageFallback(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.radiusMd,
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 44,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool outlined;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.radiusFull,
        border: outlined ? Border.all(color: theme.colorScheme.outline) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: foregroundColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
