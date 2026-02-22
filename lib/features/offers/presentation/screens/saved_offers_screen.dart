import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../domain/entities/offer.dart';
import '../providers/offers_providers.dart';

/// Screen showing saved/favorite offers
class SavedOffersScreen extends ConsumerWidget {
  const SavedOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedOffersAsync = ref.watch(savedOffersFullProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('العروض المحفوظة'),
      ),
      body: savedOffersAsync.when(
        data: (offers) => _buildOffersList(context, ref, offers),
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: 4,
          itemBuilder: (context, index) => const MenuItemSkeleton(),
        ),
        error: (error, _) => AppErrorWidget(
          exception: _asAppException(error),
          onRetry: () => ref.invalidate(savedOffersFullProvider),
        ),
      ),
    );
  }

  Widget _buildOffersList(
    BuildContext context,
    WidgetRef ref,
    List<Offer> offers,
  ) {
    if (offers.isEmpty) {
      return AppEmptyState.noSavedOffers(onBrowse: () => context.go('/home'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return _buildOfferCard(context, ref, offer);
      },
    );
  }

  Widget _buildOfferCard(BuildContext context, WidgetRef ref, Offer offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/offer/${offer.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Discount Badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    offer.discountType == DiscountType.percent
                        ? '${offer.discountValue.toInt()}%'
                        : offer.discountType == DiscountType.freeItem
                        ? '🎁'
                        : '${offer.discountValue.toInt()}₪',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Offer Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.validityText,
                      style: TextStyle(
                        fontSize: 13,
                        color: offer.validityText == 'ينتهي قريباً'
                            ? Colors.orange
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Remove from saved Button
              IconButton(
                onPressed: () async {
                  await ref
                      .read(savedOffersListProvider.notifier)
                      .toggle(offer.id);
                },
                icon: Icon(Icons.bookmark, color: AppTheme.primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppException _asAppException(Object error) {
    if (error is AppException) return error;
    return OfferException(error.toString());
  }
}
