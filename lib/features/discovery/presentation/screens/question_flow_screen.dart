import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/features/discovery/presentation/providers/search_state.dart';
import 'package:wain_app/features/discovery/presentation/widgets/filter_bottom_sheet.dart';
import 'package:wain_app/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:wain_app/features/profile/presentation/providers/settings_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Multi-step question flow with image cards.
class QuestionFlowScreen extends ConsumerStatefulWidget {
  const QuestionFlowScreen({super.key});

  @override
  ConsumerState<QuestionFlowScreen> createState() => _QuestionFlowScreenState();
}

class _QuestionFlowScreenState extends ConsumerState<QuestionFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  String? selectedOccasion;
  String? selectedMood;
  String? selectedCuisine;
  String? selectedCompanion;

  List<QuestionData> _buildQuestions(AppLocalizations l10n) => [
    QuestionData(
      title: l10n.questionOccasionTitle,
      options: [
        QuestionOption(
          key: 'birthday',
          label: l10n.optionBirthday,
          image: 'why/Property 1=Birthday.png',
        ),
        QuestionOption(
          key: 'anniversary',
          label: l10n.optionAnniversary,
          image: 'why/Property 1=Anniversary.png',
        ),
        QuestionOption(
          key: 'meeting',
          label: l10n.optionMeeting,
          image: 'why/Property 1=Meeting.png',
        ),
        QuestionOption(
          key: 'fast_food',
          label: l10n.optionFastFood,
          image: 'why/Property 1=Quick bite.png',
        ),
        QuestionOption(
          key: 'solo_time',
          label: l10n.optionSoloTime,
          image: 'why/Property 1=Solo time.png',
        ),
      ],
    ),
    QuestionData(
      title: l10n.questionMoodTitle,
      options: [
        QuestionOption(
          key: 'outdoor',
          label: l10n.optionOutdoor,
          image: 'mood/Property 1=outdoor.png',
        ),
        QuestionOption(
          key: 'couples',
          label: l10n.optionCouples,
          image: 'mood/Property 1=romantic.png',
        ),
        QuestionOption(
          key: 'family',
          label: l10n.optionFamily,
          image: 'mood/Property 1=family.png',
        ),
        QuestionOption(
          key: 'work',
          label: l10n.optionWork,
          image: 'mood/Property 1=work.png',
        ),
        QuestionOption(
          key: 'chill',
          label: l10n.optionChill,
          image: 'mood/Property 1=chill.png',
        ),
        QuestionOption(
          key: 'fun',
          label: l10n.optionFun,
          image: 'mood/Property 1=fun.png',
        ),
      ],
    ),
    QuestionData(
      title: l10n.questionCuisineTitle,
      options: [
        QuestionOption(
          key: 'palestinian',
          label: l10n.optionPalestinian,
          image: 'cuisine/Property 1=Palestinian - levant.png',
        ),
        QuestionOption(
          key: 'khaleeji',
          label: l10n.optionKhaleeji,
          image: 'cuisine/Property 1=Gulf.png',
        ),
        QuestionOption(
          key: 'italian',
          label: l10n.optionItalian,
          image: 'cuisine/Property 1=italian.png',
        ),
        QuestionOption(
          key: 'asian',
          label: l10n.optionAsian,
          image: 'cuisine/Property 1=asian.png',
        ),
        QuestionOption(
          key: 'desserts',
          label: l10n.optionDesserts,
          image: 'cuisine/Property 1=sweets.png',
        ),
        QuestionOption(
          key: 'cafe',
          label: l10n.optionCafe,
          image: 'cuisine/Property 1=cafe.png',
        ),
      ],
    ),
    QuestionData(
      title: l10n.questionCompanionTitle,
      options: [
        QuestionOption(
          key: 'friends',
          label: l10n.optionFriends,
          image: 'with who/Property 1=friends 1.png',
        ),
        QuestionOption(
          key: 'partner',
          label: l10n.optionPartner,
          image: 'with who/Property 1=date 1.png',
        ),
        QuestionOption(
          key: 'family_kids',
          label: l10n.optionFamilyKids,
          image: 'with who/family 1.png',
        ),
        QuestionOption(
          key: 'solo',
          label: l10n.optionSolo,
          image: 'with who/Property 1=alone 1.png',
        ),
        QuestionOption(
          key: 'business',
          label: l10n.optionBusiness,
          image: 'with who/Meeting.png',
        ),
      ],
    ),
  ];

  void _onOptionSelected(String key) {
    HapticFeedback.selectionClick();

    setState(() {
      switch (_currentStep) {
        case 0:
          selectedOccasion = key;
          break;
        case 1:
          selectedMood = key;
          break;
        case 2:
          selectedCuisine = key;
          break;
        case 3:
          selectedCompanion = key;
          break;
      }
    });

    final questionCount = _buildQuestions(AppLocalizations.of(context)!).length;
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (_currentStep < questionCount - 1) {
        _nextPage();
      } else {
        _submit();
      }
    });
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submit() async {
    final notifier = ref.read(searchProvider.notifier);
    final city = ref.read(cityProvider);

    notifier.setCity(city);

    final occasionTags = [?selectedOccasion, ?selectedCompanion];
    if (occasionTags.isNotEmpty) {
      notifier.setOccasions(occasionTags);
    }
    if (selectedMood != null) {
      notifier.setMoods([selectedMood!]);
    }
    if (selectedCuisine != null) {
      notifier.setCuisineTypes([selectedCuisine!]);
    }

    final applied = await showFilterBottomSheet(context, preResultsFlow: true);
    if (!mounted || applied != true) return;

    // Persist completion before navigation so the splash route can trust it.
    await ref.read(discoveryCompletedProvider.notifier).complete();
    if (!mounted) return;
    context.push('/results');
  }

  void _skip() {
    final questions = _buildQuestions(AppLocalizations.of(context)!);
    if (_currentStep < questions.length - 1) {
      _nextPage();
    } else {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final questions = _buildQuestions(l10n);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, l10n, questions),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: questions.length,
                onPageChanged: (index) => setState(() => _currentStep = index),
                itemBuilder: (context, index) {
                  return _buildQuestionPage(
                    context,
                    theme,
                    questions[index],
                    index,
                  );
                },
              ),
            ),
            _buildFooter(theme, l10n, questions.length),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AppLocalizations l10n,
    List<QuestionData> questions,
  ) {
    final progress = (_currentStep + 1) / questions.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Wain',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push('/map'),
                icon: Icon(
                  Icons.map_outlined,
                  color: theme.colorScheme.primary,
                ),
                label: Text(l10n.questionMap),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppSpacing.radiusLg,
              border: Border.all(color: theme.colorScheme.outline),
              boxShadow: AppShadows.elevated,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      l10n.questionStepOf(
                        (_currentStep + 1).toString(),
                        questions.length.toString(),
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurfaceColor,
                        borderRadius: AppSpacing.radiusFull,
                      ),
                      child: Text(
                        '${((_currentStep + 1) / questions.length * 100).round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: AppSpacing.radiusFull,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppTheme.primarySurfaceColor,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(
    BuildContext context,
    ThemeData theme,
    QuestionData question,
    int index,
  ) {
    final currentSelection = switch (index) {
      0 => selectedOccasion,
      1 => selectedMood,
      2 => selectedCuisine,
      3 => selectedCompanion,
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(
            question.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context)!.questionStepOf(
              (index + 1).toString(),
              _buildQuestions(AppLocalizations.of(context)!).length.toString(),
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: question.options.length > 5 ? 0.86 : 0.82,
              ),
              itemCount: question.options.length,
              itemBuilder: (context, optionIndex) {
                final option = question.options[optionIndex];
                final isSelected = currentSelection == option.key;
                return _buildOptionCard(theme, option, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    ThemeData theme,
    QuestionOption option,
    bool isSelected,
  ) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      child: GestureDetector(
        onTap: () => _onOptionSelected(option.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primarySurfaceColor
                : theme.colorScheme.surface,
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? AppShadows.overlay : AppShadows.elevated,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withAlpha(12)
                              : theme.colorScheme.surface,
                          borderRadius: AppSpacing.radiusMd,
                        ),
                        child: option.image != null
                            ? Image.asset(
                                'assets/icons/${option.image}',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackIcon(theme, option),
                              )
                            : _buildFallbackIcon(theme, option),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: AppSpacing.sm,
                end: AppSpacing.sm,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isSelected ? 1 : 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: AppSpacing.radiusFull,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme, QuestionOption option) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primarySurfaceColor,
        borderRadius: AppSpacing.radiusMd,
      ),
      child: Center(
        child: Icon(
          option.icon ?? Icons.help_outline_rounded,
          size: 36,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, AppLocalizations l10n, int totalSteps) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalSteps,
              (index) => _buildStepDot(theme, isActive: index == _currentStep),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.secondary(label: l10n.questionSkip, onPressed: _skip),
        ],
      ),
    );
  }

  Widget _buildStepDot(ThemeData theme, {required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      width: isActive ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withAlpha(70),
        borderRadius: AppSpacing.radiusFull,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class QuestionData {
  final String title;
  final List<QuestionOption> options;

  const QuestionData({required this.title, required this.options});
}

class QuestionOption {
  final String key;
  final String label;
  final String? image;
  final IconData? icon;

  const QuestionOption({
    required this.key,
    required this.label,
    this.image,
    this.icon,
  });
}
