import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import '../providers/search_state.dart';

/// Filter bottom sheet for search results and pre-results tuning.
class FilterBottomSheet extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final bool preResultsFlow;

  const FilterBottomSheet({
    super.key,
    this.scrollController,
    this.preResultsFlow = false,
  });

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late RangeValues _budgetRange;
  late SortBy _sortBy;
  late Set<String> _selectedCuisines;

  List<Map<String, String>> _cuisineOptions(AppLocalizations l10n) => [
    {'id': 'arabic', 'label': l10n.filterCuisineArabic},
    {'id': 'italian', 'label': l10n.filterCuisineItalian},
    {'id': 'asian', 'label': l10n.filterCuisineAsian},
    {'id': 'american', 'label': l10n.filterCuisineAmerican},
    {'id': 'fast_food', 'label': l10n.filterCuisineFastFood},
    {'id': 'desserts', 'label': l10n.filterCuisineDesserts},
    {'id': 'coffee', 'label': l10n.filterCuisineCoffee},
    {'id': 'seafood', 'label': l10n.filterCuisineSeafood},
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(searchProvider);
    _budgetRange = RangeValues(
      state.minBudget.toDouble(),
      state.maxBudget.toDouble(),
    );
    _sortBy = state.sortBy;
    _selectedCuisines = Set<String>.from(state.cuisineTypes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final applyLabel = widget.preResultsFlow
        ? l10n.filterSeeSuggestions
        : l10n.filterApply;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppShadows.overlay,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: AppSpacing.radiusFull,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.filterTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (widget.preResultsFlow) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.filterPreResultsHint,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(l10n.filterReset),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionShell(
                    context,
                    title: l10n.filterBudgetRange,
                    child: _buildBudgetSlider(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionShell(
                    context,
                    title: l10n.filterSortBy,
                    child: _buildSortOptions(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionShell(
                    context,
                    title: l10n.filterCuisineType,
                    child: _buildCuisineChips(context),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline)),
            ),
            child: SafeArea(
              top: false,
              child: AppButton.primary(
                label: applyLabel,
                onPressed: _applyFilters,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionShell(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
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
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildBudgetSlider(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.primarySurfaceColor,
            borderRadius: AppSpacing.radiusMd,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: AppSpacing.radiusMd,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.filterBudgetQuestion,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_formatBudgetValue(_budgetRange.start)} - ${_formatBudgetValue(_budgetRange.end)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: AppTheme.primarySurfaceColor,
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withAlpha(24),
            valueIndicatorColor: theme.colorScheme.primary,
            valueIndicatorTextStyle: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
          child: RangeSlider(
            values: _budgetRange,
            min: 30,
            max: 200,
            divisions: 17,
            labels: RangeLabels(
              _formatBudgetValue(_budgetRange.start),
              _formatBudgetValue(_budgetRange.end),
            ),
            onChanged: (values) => setState(() => _budgetRange = values),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BudgetChip(value: _formatBudgetValue(_budgetRange.start)),
            _BudgetChip(value: _formatBudgetValue(_budgetRange.end)),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _buildSortChip(
          context,
          SortBy.rating,
          l10n.filterSortRating,
          Icons.star,
        ),
        _buildSortChip(
          context,
          SortBy.distance,
          l10n.filterSortDistance,
          Icons.location_on_outlined,
        ),
        _buildSortChip(
          context,
          SortBy.budgetLow,
          l10n.filterSortBudgetLow,
          Icons.south_rounded,
        ),
        _buildSortChip(
          context,
          SortBy.budgetHigh,
          l10n.filterSortBudgetHigh,
          Icons.north_rounded,
        ),
      ],
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    SortBy value,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
      ),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _sortBy = value);
        }
      },
    );
  }

  Widget _buildCuisineChips(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _cuisineOptions(AppLocalizations.of(context)!).map((cuisine) {
        final isSelected = _selectedCuisines.contains(cuisine['id']);
        return FilterChip(
          label: Text(cuisine['label']!),
          selected: isSelected,
          selectedColor: AppTheme.primarySurfaceColor,
          checkmarkColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary.withAlpha(110)
                : theme.colorScheme.outline,
          ),
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCuisines.add(cuisine['id']!);
              } else {
                _selectedCuisines.remove(cuisine['id']);
              }
            });
          },
        );
      }).toList(),
    );
  }

  void _resetFilters() {
    setState(() {
      _budgetRange = const RangeValues(30, 200);
      _sortBy = SortBy.rating;
      _selectedCuisines.clear();
    });
  }

  void _applyFilters() {
    final notifier = ref.read(searchProvider.notifier);
    notifier.setBudgetRange(
      _budgetRange.start.round(),
      _budgetRange.end.round(),
    );
    notifier.setSortBy(_sortBy);
    notifier.setCuisineTypes(_selectedCuisines.toList());
    Navigator.of(context).pop(true);
  }

  String _formatBudgetValue(double value) {
    return '${value.round()} ₪';
  }
}

class _BudgetChip extends StatelessWidget {
  final String value;

  const _BudgetChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primarySurfaceColor,
        borderRadius: AppSpacing.radiusFull,
      ),
      child: Text(
        value,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

Future<bool?> showFilterBottomSheet(
  BuildContext context, {
  bool preResultsFlow = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => FilterBottomSheet(
        scrollController: scrollController,
        preResultsFlow: preResultsFlow,
      ),
    ),
  );
}
