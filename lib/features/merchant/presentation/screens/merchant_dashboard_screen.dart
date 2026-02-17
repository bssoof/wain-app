import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import '../providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';

/// Merchant Dashboard Screen — لوحة تحكم التاجر
class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  Future<void> _refreshDashboardData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('backfillMerchantAnalytics')
          .call({'days': 30});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات الأداء'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Backfill analytics failed: ${e.code} ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث بيانات الأداء: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Backfill analytics failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تحديث بيانات الأداء'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      ref.invalidate(merchantVenueProvider);
      ref.invalidate(merchantStatsProvider);
      ref.invalidate(merchantOffersProvider);
      ref.invalidate(merchantAnalyticsProvider);
      ref.invalidate(merchantAnalyticsDailyProvider(30));
      ref.invalidate(merchantAnalyticsDailyProvider(7));
      ref.invalidate(userNotificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueAsync = ref.watch(merchantVenueProvider);
    final statsAsync = ref.watch(merchantStatsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('لوحة التاجر 📊'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final countAsync = ref.watch(unreadNotificationsCountProvider);
              final count = countAsync.asData?.value ?? 0;
              return IconButton(
                onPressed: () => context.push('/merchant/notifications'),
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.notifications),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _refreshDashboardData(context, ref);
            },
          ),
        ],
      ),
      body: venueAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (err, _) => Center(child: Text('خطأ: $err')),
        data: (venue) {
          if (venue == null) {
            return _buildNotLinked(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _refreshDashboardData(context, ref);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Venue Header
                _buildVenueHeader(venue),
                const SizedBox(height: 20),

                // Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: 20),

                // Stats Cards
                statsAsync.when(
                  loading: () => const Center(child: WainLoadingIndicator()),
                  error: (e, s) => const SizedBox.shrink(),
                  data: (stats) => _buildStatsSection(stats),
                ),
                const SizedBox(height: 20),

                // Daily trends
                _buildTrendsSection(ref),
                const SizedBox(height: 20),

                // Recent Reviews
                statsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                  data: (stats) => _buildReviewsSection(stats),
                ),
                const SizedBox(height: 20),

                // Offers
                _buildOffersSection(ref),

                const SizedBox(height: 20),

                // Venue Info
                _buildVenueInfoSection(venue),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotLinked(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'ما في محل مربوط بحسابك',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'أدخل رمز الدعوة عشان تربط محلك',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/merchant/invite'),
              icon: const Icon(Icons.vpn_key),
              label: const Text('أدخل رمز الدعوة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.qr_code_scanner,
        label: 'ماسح الكود',
        color: Colors.red,
        route: '/merchant/scan',
      ),
      _QuickAction(
        icon: Icons.edit,
        label: 'تعديل المعلومات',
        color: Colors.indigo,
        route: '/merchant/edit-venue',
      ),
      _QuickAction(
        icon: Icons.local_offer,
        label: 'إدارة العروض',
        color: Colors.green,
        route: '/merchant/offers',
      ),
      _QuickAction(
        icon: Icons.photo_camera,
        label: 'صور المحل',
        color: Colors.orange,
        route: '/merchant/photos',
      ),
      _QuickAction(
        icon: Icons.rate_review,
        label: 'التقييمات',
        color: Colors.blue,
        route: '/merchant/reviews',
      ),
      _QuickAction(
        icon: Icons.restaurant_menu,
        label: 'المنيو',
        color: Colors.teal,
        route: '/merchant/venue/menu',
      ),
      _QuickAction(
        icon: Icons.access_time,
        label: 'ساعات العمل',
        color: Colors.brown,
        route: '/merchant/venue/hours',
      ),
      _QuickAction(
        icon: Icons.auto_stories,
        label: 'الستوريات',
        color: Colors.purple,
        route: '/merchant/stories',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إدارة المحل',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return GestureDetector(
              onTap: () => context.push(action.route),
              child: Container(
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: action.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, color: action.color, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      action.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: action.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVenueHeader(Map<String, dynamic> venue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Venue photo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                venue['photos'] != null && (venue['photos'] as List).isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      (venue['photos'] as List).first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  )
                : const Icon(Icons.store, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Type
                Text(
                  venue['name_ar'] ?? 'اسم المحل',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  venue['tags']?['mood']?.join(' • ') ?? 'مطعم',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 8),

                // Status Badge (Open/Closed) based on hours
                Builder(
                  builder: (context) {
                    try {
                      // Convert map to Venue object to use helper
                      final venueObj = Venue.fromJson(venue);
                      final isOpen = venueObj.isOpenNow();

                      if (isOpen == null) {
                        return const SizedBox.shrink(); // No hours set
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOpen ? 'مفتوح الآن' : 'مغلق',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } catch (e) {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(MerchantStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإحصائيات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Rating + Reviews row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.star_rounded,
                value: stats.rating.toStringAsFixed(1),
                label: 'التقييم',
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.rate_review_rounded,
                value: stats.reviewCount.toString(),
                label: 'التقييمات',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Analytics cards from server
        Consumer(
          builder: (context, ref, _) {
            final analyticsAsync = ref.watch(merchantAnalyticsProvider);
            return analyticsAsync.when(
              data: (analytics) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'تفاعل الزوار',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'هذا الأسبوع',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticsCard(
                            icon: Icons.visibility_rounded,
                            value: analytics.viewsThisWeek.toString(),
                            total: analytics.viewsTotal,
                            label: 'مشاهدات',
                            color: Colors.indigo,
                            wow: analytics.viewsWoW,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildAnalyticsCard(
                            icon: Icons.phone_rounded,
                            value: analytics.callsThisWeek.toString(),
                            total: analytics.callsTotal,
                            label: 'اتصالات',
                            color: Colors.green,
                            wow: analytics.callsWoW,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticsCard(
                            icon: Icons.navigation_rounded,
                            value: analytics.navsThisWeek.toString(),
                            total: analytics.navsTotal,
                            label: 'تنقل',
                            color: Colors.orange,
                            wow: analytics.navsWoW,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildAnalyticsCard(
                            icon: Icons.auto_stories_rounded,
                            value: analytics.storyViewsThisWeek.toString(),
                            total: analytics.storyViewsTotal,
                            label: 'ستوريات',
                            color: Colors.purple,
                            wow: null,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            );
          },
        ),
      ],
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String value,
    required int total,
    required String label,
    required Color color,
    required double? wow,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const Spacer(),
              if (wow != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: wow >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${wow >= 0 ? '+' : '-'}${wow.abs().toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: wow >= 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            'الإجمالي: $total',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(WidgetRef ref) {
    final dailyAsync = ref.watch(merchantAnalyticsDailyProvider(30));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اتجاهات الأداء',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        dailyAsync.when(
          loading: () => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(child: WainLoadingIndicator()),
          ),
          error: (_, _) =>
              _buildTrendsFallback('تعذر تحميل بيانات الاتجاهات الآن'),
          data: (points) {
            if (points.isEmpty) {
              return _buildTrendsFallback(
                'لا توجد بيانات كافية لعرض الاتجاهات بعد',
              );
            }

            final last7 = points.length > 7
                ? points.sublist(points.length - 7)
                : points;
            final prev7 = points.length > 7
                ? points.sublist(
                    math.max(0, points.length - 14),
                    points.length - 7,
                  )
                : <MerchantDailyPoint>[];

            final viewsWow = _calculateWoW(
              _sumMetric(last7, (p) => p.views),
              _sumMetric(prev7, (p) => p.views),
            );
            final callsWow = _calculateWoW(
              _sumMetric(last7, (p) => p.calls),
              _sumMetric(prev7, (p) => p.calls),
            );
            final navsWow = _calculateWoW(
              _sumMetric(last7, (p) => p.navs),
              _sumMetric(prev7, (p) => p.navs),
            );

            final topDay = points.reduce((a, b) => a.views >= b.views ? a : b);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTrendComparison(
                      'مشاهدات WoW',
                      viewsWow,
                      Colors.indigo,
                    ),
                    _buildTrendComparison(
                      'اتصالات WoW',
                      callsWow,
                      Colors.green,
                    ),
                    _buildTrendComparison('تنقل WoW', navsWow, Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTrendCard(
                  title: 'مشاهدات آخر 30 يوم',
                  values: points.map((p) => p.views).toList(),
                  color: Colors.indigo,
                ),
                const SizedBox(height: 10),
                _buildTrendCard(
                  title: 'اتصالات آخر 30 يوم',
                  values: points.map((p) => p.calls).toList(),
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                _buildTrendCard(
                  title: 'تنقل آخر 30 يوم',
                  values: points.map((p) => p.navs).toList(),
                  color: Colors.orange,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'أفضل يوم (حسب المشاهدات): ${topDay.dateKey} • ${topDay.views}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrendsFallback(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.show_chart_outlined, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendComparison(String label, double? wow, Color color) {
    final hasWow = wow != null;
    final isPositive = (wow ?? 0) >= 0;
    final backgroundColor = !hasWow
        ? Colors.grey.shade100
        : isPositive
        ? Colors.green.shade50
        : Colors.red.shade50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: !hasWow
              ? Colors.grey.shade300
              : isPositive
              ? Colors.green.shade200
              : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            !hasWow
                ? Icons.remove
                : isPositive
                ? Icons.trending_up
                : Icons.trending_down,
            size: 16,
            color: !hasWow
                ? Colors.grey.shade700
                : isPositive
                ? Colors.green.shade700
                : Colors.red.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            hasWow ? '${isPositive ? '+' : ''}${wow.toStringAsFixed(0)}%' : '—',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: !hasWow
                  ? Colors.grey.shade700
                  : isPositive
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard({
    required String title,
    required List<int> values,
    required Color color,
  }) {
    final allZero = values.every((v) => v == 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: allZero
                ? Center(
                    child: Text(
                      'لا يوجد نشاط كافٍ لعرض الرسم',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _SimpleLineChartPainter(
                      values: values,
                      color: color,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  int _sumMetric(
    List<MerchantDailyPoint> points,
    int Function(MerchantDailyPoint point) selector,
  ) {
    var total = 0;
    for (final point in points) {
      total += selector(point);
    }
    return total;
  }

  double? _calculateWoW(int current, int previous) {
    if (previous == 0) return current > 0 ? 100.0 : null;
    return ((current - previous) / previous) * 100;
  }

  Widget _buildReviewsSection(MerchantStats stats) {
    if (stats.recentReviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'ما في تقييمات بعد',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آخر التقييمات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...stats.recentReviews.map((review) => _buildReviewItem(review)),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
    final comment = review['comment'] as String? ?? '';
    final userName = review['user_name'] as String? ?? 'مستخدم';
    final createdAt = review['created_at'] as Timestamp?;
    final dateStr = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Stars
              ...List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  size: 16,
                  color: Colors.amber,
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              comment,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOffersSection(WidgetRef ref) {
    final offersAsync = ref.watch(merchantOffersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'العروض',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        offersAsync.when(
          loading: () => const Center(child: WainLoadingIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (offers) {
            if (offers.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'ما في عروض حالياً',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: offers
                  .map(
                    (offer) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer, color: Colors.green.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer['title_ar'] ?? offer['title'] ?? 'عرض',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (offer['description_ar'] != null ||
                                    offer['description'] != null)
                                  Text(
                                    offer['description_ar'] ??
                                        offer['description'] ??
                                        '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVenueInfoSection(Map<String, dynamic> venue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'معلومات المحل',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.store, 'الاسم', venue['name_ar'] ?? '-'),
              const Divider(),
              _buildInfoRow(Icons.location_on, 'المدينة', venue['city'] ?? '-'),
              const Divider(),
              _buildInfoRow(Icons.phone, 'الهاتف', venue['phone'] ?? '-'),
              if (venue['categories'] != null &&
                  (venue['categories'] as List).isNotEmpty) ...[
                const Divider(),
                _buildInfoRow(
                  Icons.category,
                  'التصنيف',
                  (venue['categories'] as List).join(', '),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleLineChartPainter extends CustomPainter {
  final List<int> values;
  final Color color;

  _SimpleLineChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final guidePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      guidePaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      guidePaint,
    );

    final maxValue = values.reduce(math.max).toDouble();
    final minValue = values.reduce(math.min).toDouble();
    final valueRange = (maxValue - minValue).abs() < 0.001
        ? 1.0
        : (maxValue - minValue);
    final usableHeight = math.max(1.0, size.height - 8);
    final stepX = values.length <= 1 ? 0.0 : size.width / (values.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final normalized = (values[i] - minValue) / valueRange;
      final x = stepX * i;
      final y = size.height - 4 - (normalized * usableHeight);
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.03)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(points.first, 2.8, dotPaint);
    if (points.length > 1) {
      canvas.drawCircle(points.last, 2.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleLineChartPainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.values.length != values.length) {
      return true;
    }
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

/// Data class for quick action buttons
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}
