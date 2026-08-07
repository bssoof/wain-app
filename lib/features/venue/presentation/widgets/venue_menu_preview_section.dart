import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueMenuPreviewSection extends ConsumerWidget {
  final Venue venue;
  final VoidCallback onOpenMenu;

  const VenueMenuPreviewSection({
    super.key,
    required this.venue,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final menuAsync = ref.watch(menuItemsProvider(venue.id));

    return menuAsync.when(
      loading: () => const _MenuActionCardLoading(),
      error: (error, stackTrace) => _MenuActionCard(
        child: _MenuActionMessage(
          icon: Icons.error_outline_rounded,
          message: l10n.menuLoadFailed,
        ),
      ),
      data: (items) {
        final availableItems = items.where((item) => item.isAvailable).toList();
        final sectionCount = availableItems
            .map((item) => item.category)
            .toSet()
            .length;
        final hasMenuContent =
            availableItems.isNotEmpty || venue.menuImages.isNotEmpty;

        if (!hasMenuContent) {
          return _MenuActionCard(
            child: _MenuActionMessage(
              icon: Icons.menu_book_outlined,
              message: l10n.noMenuAvailable,
            ),
          );
        }

        final subtitle = availableItems.isNotEmpty
            ? l10n.menuResultsSummary(availableItems.length, sectionCount)
            : l10n.menuViewFull;

        return _MenuActionCard(
          onTap: onOpenMenu,
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurfaceColor,
                    borderRadius: AppSpacing.radiusMd,
                  ),
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.menuTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Capped rather than made Flexible: the call to action is sized
                // to its own text so it stays flush with the end of the card,
                // and a Flexible sibling of an Expanded one leaves a gap there
                // instead. Uncapped, the label grew with the text scale until
                // it pushed the row past its own width — 6 px over at 320,
                // 67 px at 320 with large text. A third of the card is enough
                // for it to wrap onto a second line.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth / 3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.menuViewFull,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuActionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _MenuActionCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.radiusLg,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(color: theme.colorScheme.outline),
            boxShadow: AppShadows.elevated,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MenuActionMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MenuActionMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _MenuActionCardLoading extends StatelessWidget {
  const _MenuActionCardLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _MenuActionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 18,
            width: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.radiusFull,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 14,
            width: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.radiusFull,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.radiusMd,
            ),
          ),
        ],
      ),
    );
  }
}
