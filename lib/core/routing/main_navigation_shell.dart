import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';
import 'package:wain_app/features/map/presentation/providers/map_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class MainNavigationShell extends ConsumerWidget {
  final String currentLocation;
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: SizedBox(
          height: 90,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withAlpha(246),
                    borderRadius: AppSpacing.radiusLg,
                    border: Border.all(
                      color: theme.colorScheme.outline.withAlpha(42),
                    ),
                    boxShadow: AppShadows.overlay,
                  ),
                  child: const SizedBox(height: 58),
                ),
              ),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _MainNavItem(
                      icon: Icons.map_outlined,
                      label: l10n.questionMap,
                      selected: currentLocation == '/map',
                      onTap: () {
                        final searchState = ref.read(searchProvider);
                        ref
                            .read(mapFilterProvider.notifier)
                            .applyFromSearchState(
                              moodTags: searchState.moodTags,
                              occasionTags: searchState.occasionTags,
                              timeTags: searchState.timeTags,
                              categories: searchState.cuisineTypes,
                              minBudget: searchState.minBudget,
                              maxBudget: searchState.maxBudget,
                              sortBy: searchState.sortBy,
                            );
                        context.go('/map');
                      },
                    ),
                  ),
                  Expanded(
                    child: _MainNavItem(
                      icon: Icons.bar_chart_rounded,
                      label: l10n.statsTitle,
                      selected: currentLocation == '/stats',
                      onTap: () => context.go('/stats'),
                    ),
                  ),
                  Expanded(
                    child: _MainNavItem(
                      icon: Icons.auto_awesome_rounded,
                      label: l10n.resultsSuggestions,
                      selected: currentLocation == '/results',
                      onTap: () => context.go('/results'),
                    ),
                  ),
                  Expanded(
                    child: _MainNavItem(
                      icon: Icons.favorite_border_rounded,
                      label: l10n.favoritesTitle,
                      selected: currentLocation == '/favorites',
                      onTap: () => context.go('/favorites'),
                    ),
                  ),
                  Expanded(
                    child: _MainNavItem(
                      icon: Icons.settings_outlined,
                      label: l10n.profileTitle,
                      selected: currentLocation == '/profile',
                      onTap: () => context.go('/profile'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MainNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: AppSpacing.radiusFull,
        onTap: onTap,
        child: SizedBox(
          height: 90,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                top: selected ? 0 : 40,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: selected ? 56 : 26,
                    height: selected ? 56 : 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: selected
                          ? Border.all(
                              color: theme.colorScheme.surface,
                              width: 4,
                            )
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withAlpha(100),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: selected ? 26 : 22,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 2,
                right: 2,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  style:
                      theme.textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 10,
                        height: 1,
                      ) ??
                      TextStyle(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 10,
                        height: 1,
                      ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
