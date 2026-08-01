import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
  late final TextEditingController _minBudgetController;
  late final TextEditingController _maxBudgetController;
  late int _minBudget;
  late int _maxBudget;
  String? _budgetError;
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
    _minBudget = state.minBudget;
    _maxBudget = state.maxBudget;
    _minBudgetController = TextEditingController(text: '$_minBudget');
    _maxBudgetController = TextEditingController(text: '$_maxBudget');
    _sortBy = state.sortBy;
    _selectedCuisines = Set<String>.from(state.cuisineTypes);
  }

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
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
                    child: _buildBudgetInputs(context),
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

  Widget _buildBudgetInputs(BuildContext context) {
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
                        '${_formatBudgetValue(_minBudget)} - ${_formatBudgetValue(_maxBudget)}',
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
        Row(
          children: [
            Expanded(
              child: _BudgetInputField(
                controller: _minBudgetController,
                label: l10n.filterBudgetMin,
                onChanged: () => _syncBudgetInputs(l10n),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _BudgetInputField(
                controller: _maxBudgetController,
                label: l10n.filterBudgetMax,
                onChanged: () => _syncBudgetInputs(l10n),
              ),
            ),
          ],
        ),
        if (_budgetError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _budgetError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
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
      _minBudget = 30;
      _maxBudget = 200;
      _minBudgetController.text = '30';
      _maxBudgetController.text = '200';
      _budgetError = null;
      _sortBy = SortBy.rating;
      _selectedCuisines.clear();
    });
  }

  void _applyFilters() {
    final l10n = AppLocalizations.of(context)!;
    if (!_syncBudgetInputs(l10n)) return;

    final notifier = ref.read(searchProvider.notifier);
    notifier.setBudgetRange(_minBudget, _maxBudget);
    notifier.setSortBy(_sortBy);
    notifier.setCuisineTypes(_selectedCuisines.toList());
    Navigator.of(context).pop(true);
  }

  bool _syncBudgetInputs(AppLocalizations l10n) {
    final min = int.tryParse(_minBudgetController.text.trim());
    final max = int.tryParse(_maxBudgetController.text.trim());
    String? error;

    if (min == null || max == null || min < 0 || max < 0) {
      error = l10n.filterBudgetInvalid;
    } else if (min > max) {
      error = l10n.filterBudgetInvalidRange;
    }

    setState(() {
      if (min != null) _minBudget = min;
      if (max != null) _maxBudget = max;
      _budgetError = error;
    });

    return error == null;
  }

  String _formatBudgetValue(int value) {
    return '$value ₪';
  }
}

class _BudgetInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  const _BudgetInputField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        suffixText: '₪',
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMd,
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
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
