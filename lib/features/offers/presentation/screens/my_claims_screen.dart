import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/offers/domain/entities/offer.dart';
import 'package:wain_app/features/offers/presentation/providers/offers_providers.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
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
        centerTitle: true,
      ),
      body: claimsAsync.when(
        data: (claims) {
          if (claims.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: claims.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return ClaimCard(claim: claims[index]);
            },
          );
        },
        loading: () => _buildLoadingState(),
        error: (err, stack) => Center(
          child: Text('${l10n.errorPrefix}: $err'), // Ideally custom error widget
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            l10n.myClaimsEmptyTitle,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.myClaimsEmptyDesc,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/map'),
            child: Text(l10n.myClaimsExploreBtn),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class ClaimCard extends ConsumerWidget {
  final OfferClaim claim;

  const ClaimCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine status color
    final isRedeemed = claim.status == 'redeemed';
    final isCancelled = claim.status == 'cancelled';
    
    // Fetch offer details to get title/image
    final offerAsync = ref.watch(offerByIdProvider(offerId: claim.offerId));
    // Fetch venue details (if needed, but offer usually has context)
    // We can rely on offer details for simplicity if it denormalizes venue name, 
    // but `Offer` entity doesn't have venueName. 
    // So we assume cachedVenuesProvider has the venue.
    final venuesState = ref.watch(cachedVenuesProvider());
    final venue = venuesState.venues.cast<Venue?>().firstWhere((v) => v?.id == claim.venueId, orElse: () => null);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
            // Navigate to offer details (or QR code if pending)
             if (!isRedeemed && !isCancelled) {
               // We need the full offer object to navigate usually, or fetch it.
               // For now, push to venue details or a dedicated Claim details page?
               // Let's go to venue details -> offer logic, or just offer details
               context.push('/offer/${claim.offerId}');
             }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
               // Image
               Container(
                 width: 80,
                 height: 80,
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(8),
                   color: Colors.grey.shade200,
                   image: (offerAsync.value?.imageUrl != null) 
                       ? DecorationImage(
                           image: NetworkImage(offerAsync.value!.imageUrl!),
                           fit: BoxFit.cover,
                         )
                       : null,
                 ),
                 child: offerAsync.value?.imageUrl == null 
                     ? Icon(Icons.store, color: Colors.grey.shade400) 
                     : null,
               ),
               const SizedBox(width: 12),
               
               // Details
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Venue Name
                     if (venue != null)
                      Text(
                        venue.nameAr,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      
                     // Offer Title
                     Text(
                       offerAsync.value?.titleAr ?? '...',
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                     const SizedBox(height: 4),
                     
                     // Status Badge
                     _buildStatusBadge(context, claim.status),
                   ],
                 ),
               ),
               
               // Date/Time column
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                    if (claim.timestamp != null)
                      Text(
                        _formatDate(claim.timestamp!),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 4),
                    if (!isRedeemed && !isCancelled)
                      const Icon(Icons.qr_code, color: AppTheme.primaryColor),
                 ],
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String text;

    switch (status) {
      case 'redeemed':
        color = Colors.green;
        text = l10n.myClaimsStatusUsed;
        break;
      case 'cancelled':
        color = Colors.red;
        text = l10n.myClaimsStatusCancelled;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        text = l10n.myClaimsStatusActive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Color.fromARGB((0.1 * 255).round(), color.r.toInt(), color.g.toInt(), color.b.toInt()),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Color.fromARGB((0.5 * 255).round(), color.r.toInt(), color.g.toInt(), color.b.toInt())),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}
