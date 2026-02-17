import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:wain_app/features/favorites/presentation/providers/favorites_provider.dart';

/// Provider: count of reviews written by current user
/// Reads from user doc reviews_count field (updated on submit/delete)
final userReviewCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final count = ((doc.data()?['reviews_count'] as num?)?.toInt() ?? 0).clamp(0, 999999);
    debugPrint('📊 User reviews count: $count');
    return count;
  } catch (e) {
    debugPrint('❌ Error fetching user reviews: $e');
    return 0;
  }
});

/// Provider: count of offer claims by current user
final userClaimCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('offer_claims')
        .where('user_id', isEqualTo: userId)
        .get();
    debugPrint('📊 User claims count: ${snapshot.docs.length}');
    return snapshot.docs.length;
  } catch (e) {
    debugPrint('❌ Error fetching user claims: $e');
    return 0;
  }
});

/// User Stats Dashboard Screen
class UserStatsScreen extends ConsumerWidget {
  const UserStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائياتي'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: user == null || user.isAnonymous
          ? _buildLoginPrompt(context)
          : _buildStats(context, ref, user),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'سجّل دخولك لعرض إحصائياتك',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, WidgetRef ref, dynamic user) {
    final userId = user.uid as String;
    final reviewCountAsync = ref.watch(userReviewCountProvider(userId));
    final claimCountAsync = ref.watch(userClaimCountProvider(userId));
    final favCountAsync = ref.watch(favoritesCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName?.isNotEmpty == true
                              ? user.displayName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'مرحباً ${user.displayName ?? 'بك'}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ملخص نشاطك على وين',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats cards row - REAL DATA
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_offer_rounded,
                  value: claimCountAsync.when(
                    data: (c) => '$c',
                    loading: () => '...',
                    error: (_, _) => '0',
                  ),
                  label: 'عروض مستخدمة',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_rounded,
                  value: reviewCountAsync.when(
                    data: (c) => '$c',
                    loading: () => '...',
                    error: (_, _) => '0',
                  ),
                  label: 'تقييمات',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite_rounded,
                  value: favCountAsync.when(
                    data: (c) => '$c',
                    loading: () => '...',
                    error: (_, _) => '0',
                  ),
                  label: 'مفضلات',
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Activity section
          const Text(
            'نشاطك الأخير',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildActivityItem(
            icon: Icons.star_rounded,
            color: Colors.amber,
            title: 'ميزة التقييمات جاهزة!',
            subtitle: 'قيّم الأماكن اللي زرتها',
            time: 'الآن',
          ),
          _buildActivityItem(
            icon: Icons.local_offer_rounded,
            color: AppTheme.primaryColor,
            title: 'استكشف العروض الحصرية',
            subtitle: 'عروض جديدة كل يوم',
            time: 'اليوم',
          ),
          _buildActivityItem(
            icon: Icons.explore_rounded,
            color: Colors.teal,
            title: 'اكتشف أماكن جديدة',
            subtitle: 'جرّب سؤال "وين أروح؟"',
            time: 'جديد',
          ),

          const SizedBox(height: 32),

          // Achievements section - unlock based on real data
          const Text(
            'إنجازاتك',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildAchievementBadge('🌟', 'مستكشف جديد', true),
              _buildAchievementBadge(
                '✍️',
                'مقيّم',
                reviewCountAsync.asData?.value != null &&
                    reviewCountAsync.asData!.value > 0,
              ),
              _buildAchievementBadge(
                '🎯',
                'صائد عروض',
                claimCountAsync.asData?.value != null &&
                    claimCountAsync.asData!.value > 0,
              ),
              _buildAchievementBadge(
                '❤️',
                'محب الأماكن',
                favCountAsync.asData?.value != null &&
                    favCountAsync.asData!.value >= 3,
              ),
              _buildAchievementBadge(
                '👑',
                'خبير وين',
                reviewCountAsync.asData?.value != null &&
                    reviewCountAsync.asData!.value >= 5,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String emoji, String label, bool unlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked ? Colors.amber.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? Colors.amber.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 20, color: unlocked ? null : Colors.grey)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: unlocked ? Colors.amber.shade800 : Colors.grey,
            ),
          ),
          if (unlocked) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle, size: 14, color: Colors.amber.shade700),
          ],
        ],
      ),
    );
  }
}
