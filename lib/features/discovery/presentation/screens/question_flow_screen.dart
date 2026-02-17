import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// SVG removed - using PNG for better performance
import 'package:go_router/go_router.dart';
import '../providers/search_state.dart';

/// New Question Screen - Figma Design Implementation
/// Multi-step question flow with image cards
class QuestionFlowScreen extends ConsumerStatefulWidget {
  const QuestionFlowScreen({super.key});

  @override
  ConsumerState<QuestionFlowScreen> createState() => _QuestionFlowScreenState();
}

class _QuestionFlowScreenState extends ConsumerState<QuestionFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Selections
  String? selectedOccasion;
  String? selectedMood;
  String? selectedCuisine;
  String? selectedCompanion;

  // Question data with images
  final List<QuestionData> questions = [
    QuestionData(
      title: 'المناسبة؟',
      options: [
        QuestionOption(key: 'birthday', label: 'عيد ميلاد', image: 'why/Property 1=Birthday.png'),
        QuestionOption(key: 'anniversary', label: 'ذكرى سنوية', image: 'why/Property 1=Anniversary.png'),
        QuestionOption(key: 'meeting', label: 'اجتماع', image: 'why/Property 1=Meeting.png'),
        QuestionOption(key: 'fast_food', label: 'اكل سريع', image: 'why/Property 1=Quick bite.png'),
        QuestionOption(key: 'solo_time', label: 'وقت لحالي', image: 'why/Property 1=Solo time.png'),
      ],
    ),
    QuestionData(
      title: 'شو المود اليوم؟',
      options: [
        QuestionOption(key: 'outdoor', label: 'قعدات خارجية', image: 'mood/Property 1=outdoor.png'),
        QuestionOption(key: 'couples', label: 'اجواء رومانسية', image: 'mood/Property 1=romantic.png'),
        QuestionOption(key: 'family', label: 'اجواء عيلة', image: 'mood/Property 1=family.png'),
        QuestionOption(key: 'work', label: 'عمل', image: 'mood/Property 1=work.png'),
        QuestionOption(key: 'chill', label: 'رواق', image: 'mood/Property 1=chill.png'),
        QuestionOption(key: 'fun', label: 'ترفيه', image: 'mood/Property 1=fun.png'),
      ],
    ),
    QuestionData(
      title: 'قربنا نخلص\nشو حابب تاكل؟',
      options: [
        QuestionOption(key: 'palestinian', label: 'فلسطيني/شامي', image: 'cuisine/Property 1=Palestinian - levant.png'),
        QuestionOption(key: 'khaleeji', label: 'خليجي', image: 'cuisine/Property 1=Gulf.png'),
        QuestionOption(key: 'italian', label: 'إيطالي', image: 'cuisine/Property 1=italian.png'),
        QuestionOption(key: 'asian', label: 'آسيوي', image: 'cuisine/Property 1=asian.png'),
        QuestionOption(key: 'desserts', label: 'حلويات', image: 'cuisine/Property 1=sweets.png'),
        QuestionOption(key: 'cafe', label: 'كافيه/قهوة', image: 'cuisine/Property 1=cafe.png'),
      ],
    ),
    QuestionData(
      title: 'مع مين رايح؟',
      options: [
        QuestionOption(key: 'friends', label: 'الأصدقاء', image: 'with who/Property 1=friends 1.png'),
        QuestionOption(key: 'partner', label: 'خطيب/زوج', image: 'with who/Property 1=date 1.png'),
        QuestionOption(key: 'family_kids', label: 'العائلة والأطفال', image: 'with who/family 1.png'),
        QuestionOption(key: 'solo', label: 'لحالي', image: 'with who/Property 1=alone 1.png'),
        QuestionOption(key: 'business', label: 'لقاء عمل', image: 'with who/Meeting.png'),
      ],
    ),
  ];

  void _onOptionSelected(String key) {
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
    
    // Auto-advance after short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_currentStep < questions.length - 1) {
        _nextPage();
      } else {
        _submit();
      }
    });
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _submit() {
    final notifier = ref.read(searchProvider.notifier);
    
    // Set selections to search state
    if (selectedOccasion != null) {
      notifier.setOccasions([selectedOccasion!]);
    }
    if (selectedMood != null) {
      notifier.setMoods([selectedMood!]);
    }
    if (selectedCuisine != null) {
      notifier.setCuisineTypes([selectedCuisine!]);
    }
    
    context.push('/results');
  }

  void _skip() {
    if (_currentStep < questions.length - 1) {
      _nextPage();
    } else {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Question pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionPage(questions[index], index);
                },
              ),
            ),
            
            // Page indicator and skip button
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Logo (Left)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Wain',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC0006F),
              ),
            ),
          ),
          
          // Step Title (Center)
          Text(
            'خطوة ${_currentStep + 1} من ${questions.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC0006F),
            ),
          ),

          // Map Button (Right)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/map'),
              icon: const Icon(Icons.map, color: Color(0xFFC0006F), size: 20),
              label: const Text(
                'الخريطة',
                style: TextStyle(
                  color: Color(0xFFC0006F),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(QuestionData question, int index) {
    final String? currentSelection;
    switch (index) {
      case 0:
        currentSelection = selectedOccasion;
        break;
      case 1:
        currentSelection = selectedMood;
        break;
      case 2:
        currentSelection = selectedCuisine;
        break;
      case 3:
        currentSelection = selectedCompanion;
        break;
      default:
        currentSelection = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Title
          Text(
            question.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          
          // Options grid
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: question.options.length > 5 ? 0.9 : 0.85,
              ),
              itemCount: question.options.length,
              itemBuilder: (context, i) {
                final option = question.options[i];
                final isSelected = currentSelection == option.key;
                
                return _buildOptionCard(option, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(QuestionOption option, bool isSelected) {
    return GestureDetector(
      onTap: () => _onOptionSelected(option.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFC0006F) : Colors.transparent,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(13, 0, 0, 0),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration or Icon
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: option.image != null
                    ? Image.asset(
                        'assets/icons/${option.image}',
                        fit: BoxFit.contain,
                        width: 100,
                        height: 100,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackIcon(option),
                      )
                    : _buildFallbackIcon(option),
              ),
            ),
            // Label
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                option.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected 
                      ? const Color(0xFFC0006F)
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(QuestionOption option) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          option.icon ?? Icons.help_outline,
          size: 32,
          color: const Color(0xFFC0006F),
        ),
      ),
    );
  }

  // _getIconForOption is no longer needed as we store icons in the model

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(questions.length, (index) {
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentStep
                      ? const Color(0xFFC0006F)
                      : const Color.fromARGB(77, 192, 0, 111),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          
          // Skip button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _skip,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0006F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'تخطي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_back),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// Question data model
class QuestionData {
  final String title;
  final List<QuestionOption> options;

  QuestionData({required this.title, required this.options});
}

/// Question option model
class QuestionOption {
  final String key;
  final String label;
  final String? image;
  final IconData? icon;

  QuestionOption({
    required this.key, 
    required this.label, 
    this.image,
    this.icon,
  });
}
