import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/offer.dart';
import '../providers/offers_providers.dart';

class SavedOffersScreen extends ConsumerWidget {
  const SavedOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedOffersAsync = ref.watch(savedOffersFullProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savedOffersTitle),
        leading: IconButton(
          onPressed: () => context.popOrGo('/profile'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: savedOffersAsync.when(
        data: (offers) => _OffersList(offers: offers),
        loading: () => ListView.builder(
          padding: AppSpacing.screenPadding,
          itemCount: 4,
          itemBuilder: (_, _) => const MenuItemSkeleton(),
        ),
        error: (error, _) => AppErrorWidget(
          exception: _asAppException(error),
          onRetry: () => ref.invalidate(savedOffersFullProvider),
        ),
      ),
    );
  }

  AppException _asAppException(Object error) {
    if (error is AppException) {
      return error;
    }
    return OfferException(error.toString());
  }
}

class _OffersList extends ConsumerWidget {
  final List<Offer> offers;

  const _OffersList({required this.offers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (offers.isEmpty) {
      return AppEmptyState.noSavedOffers(
        context,
        onBrowse: () => context.go('/results'),
      );
    }

    return ListView.separated(
      padding: AppSpacing.screenPadding,
      itemCount: offers.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final offer = offers[index];
        return _OfferCard(offer: offer);
      },
    );
  }
}

class _OfferCard extends ConsumerWidget {
  final Offer offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    final validityText = offer.getValidityText(l10n);
    final isUrgent = validityText == l10n.offerEndingSoon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.radiusLg,
        onTap: () => context.push('/offer/${offer.id}'),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(color: colorScheme.outline),
            boxShadow: AppShadows.elevated,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              _DiscountBadge(offer: offer),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      offer.getDiscountText(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      validityText,
                      style: textTheme.labelMedium?.copyWith(
                        color: isUrgent
                            ? AppTheme.warningColor
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: () async {
                  await ref
                      .read(savedOffersListProvider.notifier)
                      .toggle(offer.id);
                },
                icon: Icon(Icons.bookmark_rounded, color: colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final Offer offer;

  const _DiscountBadge({required this.offer});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final label = switch (offer.discountType) {
      DiscountType.percent => '${offer.discountValue.toInt()}%',
      DiscountType.amount =>
        '${offer.discountValue.toInt()} ${offer.currency ?? 'ILS'}',
      DiscountType.freeItem => AppLocalizations.of(context)!.offerDiscountFree,
    };

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: AppSpacing.radiusLg,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textTheme.titleMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
