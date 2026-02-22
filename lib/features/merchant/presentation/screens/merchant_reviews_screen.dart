import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import '../providers/merchant_dashboard_providers.dart';

/// Merchant Reviews Screen — التقييمات والرد عليها
class MerchantReviewsScreen extends ConsumerStatefulWidget {
  const MerchantReviewsScreen({super.key});

  @override
  ConsumerState<MerchantReviewsScreen> createState() =>
      _MerchantReviewsScreenState();
}

class _MerchantReviewsScreenState extends ConsumerState<MerchantReviewsScreen> {
  /// null = show all, 0 = no reply, 1-5 = star rating
  int? _activeFilter;

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> reviews) {
    if (_activeFilter == null) return reviews;
    if (_activeFilter == 0) {
      // "بدون رد" -- no merchant reply
      return reviews.where((r) {
        final reply = r['merchant_reply'] as String?;
        return reply == null || reply.isEmpty;
      }).toList();
    }
    // Star filter
    return reviews.where((r) {
      final rating = (r['rating'] as num?)?.toInt() ?? 0;
      return rating == _activeFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Use the new provider that fetches up to 100 reviews (or more)
    final reviewsAsync = ref.watch(merchantReviewsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.merchantReviewsTitle),
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (err, _) => Center(child: Text(l10n.merchantReviewsErrorGeneric(err.toString()))),
        data: (allReviews) {
          if (allReviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.merchantReviewsEmpty,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          final filtered = _applyFilter(allReviews);

          return Column(
            children: [
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _filterChip(l10n.merchantReviewsFilterAll, null),
                    _filterChip('⭐ 5', 5),
                    _filterChip('⭐ 4', 4),
                    _filterChip('⭐ 3', 3),
                    _filterChip('⭐ 2', 2),
                    _filterChip('⭐ 1', 1),
                    _filterChip(l10n.merchantReviewsFilterNoReply, 0),
                  ],
                ),
              ),
              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      l10n.merchantReviewsCount(filtered.length),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Review list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.merchantReviewsNoResults,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 80,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _ReviewCard(review: filtered[index], ref: ref);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, int? value) {
    final isActive = _activeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => setState(() => _activeFilter = value),
        selectedColor: AppTheme.primaryColor.withValues(
          alpha: 0.12,
        ), // Updated from withOpacity
        labelStyle: TextStyle(
          color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  final WidgetRef ref;

  const _ReviewCard({required this.review, required this.ref});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  final _replyController = TextEditingController();
  bool _showReplyField = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existingReply = widget.review['merchant_reply'] as String?;
    if (existingReply != null) {
      _replyController.text = existingReply;
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final l10n = AppLocalizations.of(context)!;
    final reply = _replyController.text.trim();
    if (reply.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final venueId = await widget.ref.read(merchantVenueIdProvider.future);
      if (venueId == null) return;

      final reviewId = widget.review['id'] as String;

      await FirebaseFirestore.instance
          .collection('venues')
          .doc(venueId)
          .collection('reviews')
          .doc(reviewId)
          .update({
            'merchant_reply': reply,
            'merchant_reply_at': FieldValue.serverTimestamp(),
            'merchant_reply_by': FirebaseAuth.instance.currentUser?.uid,
          });

      // Invalidate BOTH providers to update lists
      widget.ref.invalidate(merchantReviewsProvider);
      widget.ref.invalidate(merchantStatsProvider);

      if (!mounted) return;
      setState(() => _showReplyField = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantReviewsReplySent),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.merchantReviewsErrorGeneric(e.toString())), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteReply() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.merchantReviewsDeleteReplyTitle),
        content: Text(l10n.merchantReviewsDeleteReplyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.merchantReviewsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.merchantReviewsDelete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final venueId = await widget.ref.read(merchantVenueIdProvider.future);
      if (venueId == null) return;

      final reviewId = widget.review['id'] as String;

      await FirebaseFirestore.instance
          .collection('venues')
          .doc(venueId)
          .collection('reviews')
          .doc(reviewId)
          .update({
            'merchant_reply': FieldValue.delete(),
            'merchant_reply_at': FieldValue.delete(),
            'merchant_reply_by': FieldValue.delete(),
          });

      widget.ref.invalidate(merchantReviewsProvider);
      widget.ref.invalidate(merchantStatsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantReviewsReplyDeleted),
          backgroundColor: Colors.grey,
        ),
      );
      _replyController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.merchantReviewsErrorGeneric(e.toString())), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rating = (widget.review['rating'] as num?)?.toDouble() ?? 0.0;
    final comment = widget.review['comment'] as String? ?? '';
    final userName = widget.review['user_name'] as String? ?? l10n.merchantReviewsDefaultUser;
    final userInitial = userName.isNotEmpty ? userName[0] : l10n.merchantReviewsDefaultInitial;
    final createdAt = widget.review['created_at'] as Timestamp?;
    final merchantReply = widget.review['merchant_reply'] as String?;
    final dateStr = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ), // Updated
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(
                  alpha: 0.1,
                ), // Updated
                child: Text(
                  userInitial,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),

          // Comment
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(comment, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],

          // Existing Reply
          if (merchantReply != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05), // Updated
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ), // Updated
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        l10n.merchantReviewsOwnerReply,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(merchantReply, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],

          // Actions
          const SizedBox(height: 8),
          if (_showReplyField) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: l10n.merchantReviewsReplyHint,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSubmitting ? null : _submitReply,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: WainLoadingIndicator(),
                        )
                      : Icon(Icons.send, color: AppTheme.primaryColor),
                ),
              ],
            ),
            // Cancel edit button if in edit mode
            if (merchantReply != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    _replyController.text = merchantReply;
                    setState(() => _showReplyField = false);
                  },
                  child: Text(
                    l10n.merchantReviewsCancel,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ] else if (merchantReply != null) ...[
            // Actions for existing reply (Edit / Delete)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showReplyField = true),
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(l10n.merchantReviewsEdit),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSubmitting ? null : _deleteReply,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: l10n.merchantReviewsDeleteTooltip,
                ),
              ],
            ),
          ] else
            // Add new reply button
            TextButton.icon(
              onPressed: () => setState(() => _showReplyField = true),
              icon: const Icon(Icons.reply, size: 18),
              label: Text(l10n.merchantReviewsAddReply),
            ),
        ],
      ),
    );
  }
}

