import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';

class VenueMenuLoadingSkeleton extends StatelessWidget {
  const VenueMenuLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        _skeletonLine(width: 180, height: 18),
        const SizedBox(height: 12),
        _skeletonLine(width: double.infinity, height: 48),
        const SizedBox(height: 14),
        _skeletonLine(width: 140, height: 16),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _skeletonLine(width: double.infinity, height: 88)),
            const SizedBox(width: 12),
            Expanded(child: _skeletonLine(width: double.infinity, height: 88)),
          ],
        ),
      ],
    );
  }

  Widget _skeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class VenueMenuHeader extends StatelessWidget {
  final int? itemCount;
  final String counterLabel;

  const VenueMenuHeader({
    super.key,
    this.itemCount,
    this.counterLabel = 'صنف',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.restaurant_menu,
            color: Colors.orange.shade800,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'المنيو',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (itemCount != null)
          Text(
            '$itemCount $counterLabel',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
      ],
    );
  }
}

class VenueMenuSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const VenueMenuSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ابحث داخل المنيو...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: onChanged,
    );
  }
}

class VenueFeaturedItemsRow extends StatelessWidget {
  final List<MenuItem> items;

  const VenueFeaturedItemsRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⭐ الأصناف المميزة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (_, i) => VenueMenuFeaturedCard(item: items[i]),
          ),
        ),
      ],
    );
  }
}

class VenueMenuFeaturedCard extends StatelessWidget {
  final MenuItem item;

  const VenueMenuFeaturedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: item.photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.photoUrl,
                    height: 100,
                    width: 150,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(height: 100, color: Colors.grey.shade200),
                    errorWidget: (context, url, error) => Container(
                      height: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  )
                : Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price} ${item.currency}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VenueMenuCategoryChips extends StatelessWidget {
  final List<MenuSection> sections;
  final String selectedSectionId;
  final ValueChanged<String> onSelected;

  const VenueMenuCategoryChips({
    super.key,
    required this.sections,
    required this.selectedSectionId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('الكل'),
            selected: selectedSectionId == 'all',
            onSelected: (_) => onSelected('all'),
          ),
          const SizedBox(width: 8),
          ...sections.map((section) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(section.nameAr),
                selected: selectedSectionId == section.id,
                onSelected: (_) => onSelected(section.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class VenueMenuSectionBlock extends StatelessWidget {
  final MenuSection section;
  final List<MenuItem> items;

  const VenueMenuSectionBlock({
    super.key,
    required this.section,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final sectionIcon = _menuIconForKey(section.icon);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                sectionIcon,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.nameAr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => VenueMenuItemTile(item: item)),
        const Divider(height: 24),
      ],
    );
  }
}

class VenueMenuItemTile extends StatelessWidget {
  final MenuItem item;

  const VenueMenuItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (item.photoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item.photoUrl,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 55,
                  height: 55,
                  color: Colors.grey.shade200,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 55,
                  height: 55,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.fastfood, size: 20, color: Colors.grey),
                ),
              ),
            ),
          if (item.photoUrl.isNotEmpty) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (item.descriptionAr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.descriptionAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.price} ${item.currency}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class VenueMenuImageGallery extends StatelessWidget {
  final List<String> images;

  const VenueMenuImageGallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final url = images[index];
          return GestureDetector(
            onTap: () => _openImagePreview(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: url,
                width: 150,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 150,
                  height: 200,
                  color: Colors.grey.shade200,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 150,
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openImagePreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url)),
      ),
    );
  }
}

class VenueMenuEmptyState extends StatelessWidget {
  final String message;

  const VenueMenuEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class PinnedMenuHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const PinnedMenuHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant PinnedMenuHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

IconData _menuIconForKey(String key) {
  const icons = <String, IconData>{
    'coffee': Icons.coffee,
    'local_drink': Icons.local_drink,
    'local_bar': Icons.local_bar,
    'smoking_rooms': Icons.smoking_rooms,
    'cake': Icons.cake,
    'fastfood': Icons.fastfood,
    'restaurant': Icons.restaurant,
    'dinner_dining': Icons.dinner_dining,
    'outdoor_grill': Icons.outdoor_grill,
    'soup_kitchen': Icons.soup_kitchen,
    'lunch_dining': Icons.lunch_dining,
    'kebab_dining': Icons.kebab_dining,
    'local_pizza': Icons.local_pizza,
    'tapas': Icons.tapas,
    'bakery_dining': Icons.bakery_dining,
    'icecream': Icons.icecream,
    'blender': Icons.blender,
    'more_horiz': Icons.more_horiz,
  };
  return icons[key] ?? Icons.restaurant_menu;
}
