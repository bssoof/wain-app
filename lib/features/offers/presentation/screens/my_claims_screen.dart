import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/app_error_widget.dart';
import 'package:wain_app/core/widgets/app_skeleton.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/features/offers/presentation/providers/offers_providers.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class MyClaimsScreen extends ConsumerWidget {
  const MyClaimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(myClaimsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myClaimsTitle),
        leading: IconButton(
          onPressed: () => context.popOrGo('/profile'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: claimsAsync.when(
        data: (claims) {
          if (claims.isEmpty) {
            return AppEmptyState(
              icon: Icons.local_offer_outlined,
              message:
                  '${l10n.myClaimsEmptyTitle}\n\n${l10n.myClaimsEmptyDesc}',
              actionLabel: l10n.myClaimsExploreBtn,
              onAction: () => context.push('/map'),
            );
          }

          return ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: claims.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => ClaimCard(claim: claims[index]),
          );
        },
        loading: () => ListView.builder(
          padding: AppSpacing.screenPadding,
          itemCount: 4,
          itemBuilder: (_, _) => const _ClaimCardSkeleton(),
        ),
        error: (error, _) => AppErrorWidget(
          exception: _asAppException(error),
          onRetry: () => ref.invalidate(myClaimsProvider),
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

class ClaimCard extends ConsumerWidget {
  final OfferClaim claim;

  const ClaimCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isRedeemed = claim.status == 'redeemed';
    final isCancelled = claim.status == 'cancelled';
    final city = ref.watch(cityProvider);
    final offerAsync = ref.watch(offerByIdProvider(offerId: claim.offerId));
    final venuesState = ref.watch(cachedVenuesProvider(city: city));
    final venue = venuesState.venues.cast<Venue?>().firstWhere(
      (item) => item?.id == claim.venueId,
      orElse: () => null,
    );
    final statusMeta = _ClaimStatusMeta.fromStatus(context, claim.status);

    final offer = offerAsync.asData?.value;
    final imageUrl = offer?.imageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.radiusLg,
        onTap: () {
          if (!isRedeemed && !isCancelled) {
            context.push('/offer/${claim.offerId}');
          }
        },
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
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.radiusMd,
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: imageUrl == null
                    ? Icon(
                        Icons.local_offer_rounded,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (venue != null)
                      Text(
                        venue.nameAr,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      offer?.titleAr ?? '...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatusBadge(meta: statusMeta),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (claim.timestamp != null)
                    Text(
                      _formatDate(claim.timestamp!),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  if (!isRedeemed && !isCancelled)
                    Icon(Icons.qr_code_rounded, color: colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class _ClaimStatusMeta {
  final String label;
  final Color color;

  const _ClaimStatusMeta({required this.label, required this.color});

  factory _ClaimStatusMeta.fromStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case 'redeemed':
        return const _ClaimStatusMeta(
          label: '',
          color: AppTheme.successColor,
        ).copyWith(label: l10n.myClaimsStatusUsed);
      case 'cancelled':
        return const _ClaimStatusMeta(
          label: '',
          color: AppTheme.errorColor,
        ).copyWith(label: l10n.myClaimsStatusCancelled);
      case 'pending':
      default:
        return const _ClaimStatusMeta(
          label: '',
          color: AppTheme.warningColor,
        ).copyWith(label: l10n.myClaimsStatusActive);
    }
  }

  _ClaimStatusMeta copyWith({String? label, Color? color}) {
    return _ClaimStatusMeta(
      label: label ?? this.label,
      color: color ?? this.color,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _ClaimStatusMeta meta;

  const _StatusBadge({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: meta.color.withAlpha(20),
        borderRadius: AppSpacing.radiusSm,
        border: Border.all(color: meta.color.withAlpha(70)),
      ),
      child: Text(
        meta.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: meta.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ClaimCardSkeleton extends StatelessWidget {
  const _ClaimCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const MenuItemSkeleton();
  }
}
