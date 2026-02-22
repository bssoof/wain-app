import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/profile/presentation/screens/user_stats_screen.dart';
import 'package:wain_app/features/reviews/presentation/providers/reviews_provider.dart';
import 'package:wain_app/features/reviews/presentation/widgets/star_rating_widget.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

/// Bottom sheet form for submitting a review
class ReviewFormSheet extends ConsumerStatefulWidget {
  final String venueId;
  final String venueName;

  const ReviewFormSheet({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  @override
  ConsumerState<ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends ConsumerState<ReviewFormSheet> {
  double _rating = 0;
  final _textController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار تقييم'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.asData?.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول لإضافة تقييم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(reviewsRepositoryProvider)
          .submitReview(
            venueId: widget.venueId,
            userId: user.uid,
            userName: user.displayName ?? 'مستخدم',
            userPhotoUrl: user.photoUrl,
            rating: _rating,
            text: _textController.text.trim(),
          );

      ref.invalidate(venueReviewsProvider(widget.venueId));
      ref.invalidate(venueRatingSummaryProvider(widget.venueId));
      ref.invalidate(userReviewCountProvider(user.uid));

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة تقييمك بنجاح!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إضافة التقييم: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'تقييم ${widget.venueName}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'شاركنا تجربتك مع هذا المكان',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: StarRatingPicker(
              rating: _rating,
              onRatingChanged: (value) => setState(() => _rating = value),
              starSize: 44,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingLabel(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _rating > 0
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _textController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'اكتب تعليقك هنا (اختياري)...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: WainLoadingIndicator(),
                    )
                  : const Text(
                      'إرسال التقييم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel() {
    switch (_rating.toInt()) {
      case 1:
        return 'سيء جدًا';
      case 2:
        return 'مقبول';
      case 3:
        return 'جيد';
      case 4:
        return 'ممتاز';
      case 5:
        return 'رائع!';
      default:
        return 'اختر تقييمك';
    }
  }
}
