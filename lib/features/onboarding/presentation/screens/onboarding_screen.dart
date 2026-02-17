import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/onboarding/presentation/providers/onboarding_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = [
    _OnboardingItem(
      title: 'استكشف واكتشف',
      description: 'اكتشف أفضل الكافيهات والمطاعم والأماكن الترفيهية حولك بسهولة.',
      icon: Icons.explore,
      color: Colors.blue,
    ),
    _OnboardingItem(
      title: 'عروض حصرية',
      description: 'استفد من خصومات وعروض خاصة للمستخدمين عند زيارة شركائنا.',
      icon: Icons.local_offer,
      color: Colors.orange,
    ),
    _OnboardingItem(
      title: 'حدد وجهتك',
      description: 'احصل على اتجاهات دقيقة وتعرف على الأماكن المفتوحة الآن.',
      icon: Icons.navigation,
      color: Colors.green,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(seenOnboardingProvider.notifier).complete();
    if (mounted) {
      context.go('/home'); // Start discovery flow
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topLeft,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text('تخطي'),
              ),
            ),
            
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: item.color.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            size: 100,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Dots & Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Dots
                   Row(
                     children: List.generate(_items.length, (index) {
                       return AnimatedContainer(
                         duration: const Duration(milliseconds: 300),
                         margin: const EdgeInsets.symmetric(horizontal: 4),
                         height: 8,
                         width: _currentPage == index ? 24 : 8,
                         decoration: BoxDecoration(
                           color: _currentPage == index 
                               ? AppTheme.primaryColor 
                               : Colors.grey.shade300,
                           borderRadius: BorderRadius.circular(4),
                         ),
                       );
                     }),
                   ),
                   
                   // Button
                   ElevatedButton(
                     onPressed: _nextPage,
                     style: ElevatedButton.styleFrom(
                       shape: const CircleBorder(),
                       padding: const EdgeInsets.all(20),
                       backgroundColor: AppTheme.primaryColor,
                       foregroundColor: Colors.white,
                     ),
                     child: Icon(
                       _currentPage == _items.length - 1 
                           ? Icons.check 
                           : Icons.arrow_forward,
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
