import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingItem> _buildItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _OnboardingItem(
        title: l10n.onboardingExploreTitle,
        description: l10n.onboardingExploreDesc,
        icon: Icons.explore_rounded,
        accent: const Color(0xFFE94A8A),
        surface: const Color(0xFFFFEDF4),
      ),
      _OnboardingItem(
        title: l10n.onboardingOffersTitle,
        description: l10n.onboardingOffersDesc,
        icon: Icons.local_offer_rounded,
        accent: const Color(0xFFF59E0B),
        surface: const Color(0xFFFFF6E5),
      ),
      _OnboardingItem(
        title: l10n.onboardingNavigateTitle,
        description: l10n.onboardingNavigateDesc,
        icon: Icons.navigation_rounded,
        accent: const Color(0xFF10B981),
        surface: const Color(0xFFEAFBF4),
      ),
    ];
  }

  Future<void> _completeOnboarding() async {
    await ref.read(seenOnboardingProvider.notifier).complete();
    if (mounted) {
      context.go('/home');
    }
  }

  void _nextPage(int itemCount) {
    if (_currentPage < itemCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final items = _buildItems(context);
    final nextLabel = l10n.localeName.startsWith('ar') ? 'التالي' : 'Next';
    final startLabel = l10n.localeName.startsWith('ar') ? 'ابدأ' : 'Start';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'W',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  AppButton.tertiary(
                    label: l10n.onboardingSkip,
                    onPressed: _completeOnboarding,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: items.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: AppSpacing.radiusLg,
                        border: Border.all(color: theme.colorScheme.outline),
                        boxShadow: AppShadows.elevated,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.topStart,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              decoration: BoxDecoration(
                                color: item.surface,
                                borderRadius: AppSpacing.radiusLg,
                              ),
                              child: Icon(
                                item.icon,
                                size: 72,
                                color: item.accent,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.title,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            item.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Row(
                    children: List.generate(items.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsetsDirectional.only(
                          end: AppSpacing.sm,
                        ),
                        width: isActive ? 28 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: AppSpacing.radiusFull,
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 156,
                    child: AppButton.primary(
                      label: _currentPage == items.length - 1
                          ? startLabel
                          : nextLabel,
                      onPressed: () => _nextPage(items.length),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final Color surface;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.surface,
  });
}
