import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_colors.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _backgroundColor = Color(0xFFE8E8E8);
  static const _inactiveDotColor = Color(0xFFE99BC6);
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<_OnboardingItem> _buildItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _OnboardingItem(
        titlePrefix: l10n.onboardingWelcomeTitlePrefix,
        titleAccent: l10n.onboardingWelcomeTitleAccent,
        description: l10n.onboardingWelcomeDesc,
        assetPath: 'assets/images/onboarding_welcome.png',
      ),
      _OnboardingItem(
        titlePrefix: l10n.onboardingSmartTitlePrefix,
        titleAccent: l10n.onboardingSmartTitleAccent,
        description: l10n.onboardingSmartDesc,
        assetPath: 'assets/images/onboarding_filters.png',
      ),
      _OnboardingItem(
        titlePrefix: l10n.onboardingDiscountsTitlePrefix,
        titleAccent: l10n.onboardingDiscountsTitleAccent,
        description: l10n.onboardingDiscountsDesc,
        assetPath: 'assets/images/onboarding_discounts.png',
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
    if (_currentPage >= itemCount - 1) {
      _completeOnboarding();
      return;
    }

    _pageController.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _buildItems(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _OnboardingHeader(
                skipLabel: l10n.onboardingSkip,
                onSkip: _completeOnboarding,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: items.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) => _OnboardingPage(
                    key: ValueKey('onboarding-page-$index'),
                    item: items[index],
                    index: index,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(items.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            key: isActive
                                ? ValueKey('onboarding-active-dot-$index')
                                : null,
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : _inactiveDotColor,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        key: const ValueKey('onboarding-next-button'),
                        onPressed: () => _nextPage(items.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: Text(l10n.onboardingNext),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  final String skipLabel;
  final VoidCallback onSkip;
  const _OnboardingHeader({required this.skipLabel, required this.onSkip});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Semantics(
              label: 'WAIN',
              child: const Text(
                'Wain',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              key: const ValueKey('onboarding-skip-button'),
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(AppSpacing.touchTargetMin, 48),
              ),
              child: Text(
                skipLabel,
                textDirection: Directionality.of(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingItem item;
  final int index;
  const _OnboardingPage({super.key, required this.item, required this.index});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Semantics(
            image: true,
            label: '${item.titlePrefix} ${item.titleAccent}',
            child: ClipRect(
              child: Image.asset(
                item.assetPath,
                key: ValueKey('onboarding-artwork-$index'),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${item.titlePrefix} '),
                    TextSpan(
                      text: item.titleAccent,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
                key: ValueKey('onboarding-title-$index'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingItem {
  final String titlePrefix;
  final String titleAccent;
  final String description;
  final String assetPath;
  const _OnboardingItem({
    required this.titlePrefix,
    required this.titleAccent,
    required this.description,
    required this.assetPath,
  });
}
