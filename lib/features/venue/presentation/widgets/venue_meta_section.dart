import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueMetaSection extends StatelessWidget {
  final Venue venue;
  final List<String> displayTags;
  final bool isEmbedded;

  const VenueMetaSection({
    super.key,
    required this.venue,
    required this.displayTags,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final visibleTags = displayTags.take(isEmbedded ? 2 : 2).toList();
    final hiddenTagsCount = displayTags.length - visibleTags.length;
    final categoryLabel = venue.categories.isNotEmpty
        ? venue.categories.first
        : l10n.generalCategory;

    if (isEmbedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (venue.nameEn.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        venue.nameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _buildRatingBadge(context),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildMetaChip(context, categoryLabel, isCategory: true),
              ...visibleTags.map((tag) => _buildMetaChip(context, tag)),
              if (hiddenTagsCount > 0)
                _buildMetaChip(context, '+$hiddenTagsCount'),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.nameAr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium,
                  ),
                  if (venue.nameEn.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      venue.nameEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(categoryLabel, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _buildRatingBadge(context),
          ],
        ),
        if (displayTags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ...visibleTags.map((tag) => _buildMetaChip(context, tag)),
              if (hiddenTagsCount > 0)
                _buildMetaChip(context, '+$hiddenTagsCount'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetaChip(
    BuildContext context,
    String label, {
    bool isCategory = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isCategory
            ? theme.colorScheme.surfaceContainerHighest
            : AppTheme.primarySurfaceColor,
        borderRadius: AppSpacing.radiusFull,
        border: isCategory
            ? Border.all(color: theme.colorScheme.outlineVariant)
            : null,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isCategory
              ? theme.colorScheme.onSurfaceVariant
              : AppTheme.primaryColor,
          fontWeight: isCategory ? FontWeight.w600 : null,
        ),
      ),
    );
  }

  Widget _buildRatingBadge(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withAlpha(24),
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(color: AppTheme.warningColor.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: AppTheme.warningColor, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${venue.rating}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.warningColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
