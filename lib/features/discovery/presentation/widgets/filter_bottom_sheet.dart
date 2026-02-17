import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/search_state.dart';

/// Filter Bottom Sheet for search results
class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late RangeValues _budgetRange;
  late SortBy _sortBy;
  late Set<String> _selectedCuisines;

  // Available cuisine types
  static const List<Map<String, String>> _cuisineOptions = [
    {'id': 'arabic', 'label': 'عربي'},
    {'id': 'italian', 'label': 'إيطالي'},
    {'id': 'asian', 'label': 'آسيوي'},
    {'id': 'american', 'label': 'أمريكي'},
    {'id': 'fast_food', 'label': 'وجبات سريعة'},
    {'id': 'desserts', 'label': 'حلويات'},
    {'id': 'coffee', 'label': 'قهوة'},
    {'id': 'seafood', 'label': 'مأكولات بحرية'},
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تصفية وترتيب',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('إعادة تعيين'),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Budget Range
                  _buildSectionTitle('نطاق السعر للشخص'),
                  const SizedBox(height: 8),
                  _buildBudgetSlider(),
                  
                  const SizedBox(height: 24),
                  
                  // Sort By
                  _buildSectionTitle('ترتيب حسب'),
                  const SizedBox(height: 12),
                  _buildSortOptions(),
                  
                  const SizedBox(height: 24),
                  
                  // Cuisine Types
                  _buildSectionTitle('نوع المطبخ'),
                  const SizedBox(height: 12),
                  _buildCuisineChips(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Apply Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تطبيق',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildBudgetSlider() {
    return Column(
      children: [
        RangeSlider(
          values: _budgetRange,
          min: 30,
          max: 200,
          divisions: 17,
          activeColor: AppTheme.primaryColor,
          labels: RangeLabels(
            '${_budgetRange.start.round()}₪',
            '${_budgetRange.end.round()}₪',
          ),
          onChanged: (values) {
            setState(() {
              _budgetRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_budgetRange.start.round()}₪',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_budgetRange.end.round()}₪',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildSortChip(SortBy.rating, 'التقييم', Icons.star),
        _buildSortChip(SortBy.distance, 'المسافة', Icons.location_on),
        _buildSortChip(SortBy.budgetLow, 'السعر ↑', Icons.attach_money),
        _buildSortChip(SortBy.budgetHigh, 'السعر ↓', Icons.attach_money),
      ],
    );
  }

  Widget _buildSortChip(SortBy value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = value;
          });
        }
      },
    );
  }

  Widget _buildCuisineChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _cuisineOptions.map((cuisine) {
        final isSelected = _selectedCuisines.contains(cuisine['id']);
        return FilterChip(
          label: Text(cuisine['label']!),
          selected: isSelected,
          selectedColor: AppTheme.primaryColor.withAlpha(51),
          checkmarkColor: AppTheme.primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
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
    
    Navigator.of(context).pop();
  }
}

/// Show filter bottom sheet
Future<void> showFilterBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => const FilterBottomSheet(),
    ),
  );
}
