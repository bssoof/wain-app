import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';

class VenueMarkerWidget extends StatelessWidget {
  final Venue venue;
  final bool isSelected;
  final VoidCallback onTap;

  const VenueMarkerWidget({
    super.key,
    required this.venue,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(venue);
    final categoryIcon = _getCategoryIcon(venue);
    
    // Size changes on selection
    final double size = isSelected ? 60.0 : 45.0;
    final double iconSize = isSelected ? 30.0 : 24.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? categoryColor : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: categoryColor,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withAlpha(102),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Main Icon
            Icon(
              categoryIcon,
              color: isSelected ? Colors.white : categoryColor,
              size: iconSize,
            ),

            // "Open Now" Indicator (Green dot)
            // Note: In real app, check OpeningHoursUtils.isOpenNow(venue.hours)
            // For now, we rely on a hypothetical 'isOpen' or just omit if heavy calculation needed here.
            // Let's stick to category styling first to keep it performant.
            
            // Offer Badge (if applicable)
            // if (venue.hasOffer) ...
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(Venue venue) {
    if (venue.categories.isEmpty) return Icons.place;
    
    final cat = venue.categories.first.toLowerCase();
    
    if (cat.contains('cafe') || cat.contains('coffee') || cat.contains('كافيه')) {
      return Icons.local_cafe;
    } else if (cat.contains('restaurant') || cat.contains('food') || cat.contains('مطعم')) {
      return Icons.restaurant;
    } else if (cat.contains('shisha') || cat.contains('hookah') || cat.contains('argileh')) {
      return Icons.smoke_free; 
    } else if (cat.contains('bar') || cat.contains('pub')) {
      return Icons.nightlife;
    } else if (cat.contains('shop') || cat.contains('store') || cat.contains('market')) {
      return Icons.shopping_bag;
    } else if (cat.contains('park') || cat.contains('garden')) {
      return Icons.park;
    }
    
    return Icons.place;
  }

  Color _getCategoryColor(Venue venue) {
    if (venue.categories.isEmpty) return AppTheme.primaryColor;
    
    final cat = venue.categories.first.toLowerCase();
    
    if (cat.contains('cafe') || cat.contains('coffee')) {
      return Colors.brown.shade400;
    } else if (cat.contains('restaurant') || cat.contains('food')) {
      return AppTheme.primaryColor; 
    } else if (cat.contains('shisha')) {
      return Colors.purple.shade400;
    } else if (cat.contains('park')) {
      return Colors.green.shade600;
    } else if (cat.contains('bar')) {
      return Colors.indigo.shade400;
    }
    
    return AppTheme.primaryColor;
  }
}
