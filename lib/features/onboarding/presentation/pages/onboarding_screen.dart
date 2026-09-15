import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/welcome_screen.dart'; 
import '../../domain/entities/onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skip() {
    _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final List<OnboardingData> pages = [
      OnboardingData(
        titleTop: l10n.onboarding1TitleTop,
        titleAccent: l10n.onboarding1TitleAccent,
        subtitle: l10n.onboarding1Subtitle,
        imagePath: 'assets/images/Onboarding Screen 1.png',
        accentColor: AppColors.orange,
        primaryButtonText: l10n.btnNext,
      ),
      OnboardingData(
        titleTop: l10n.onboarding2TitleTop,
        titleAccent: l10n.onboarding2TitleAccent,
        subtitle: l10n.onboarding2Subtitle,
        imagePath: 'assets/images/Onboarding Screen 2.png',
        accentColor: AppColors.primaryBlue,
        primaryButtonText: l10n.btnNext,
      ),
      OnboardingData(
        titleTop: l10n.onboarding3TitleTop,
        titleAccent: l10n.onboarding3TitleAccent,
        subtitle: l10n.onboarding3Subtitle,
        imagePath: 'assets/images/Onboarding Screen 3.png',
        accentColor: AppColors.primaryBlue,
        primaryButtonText: l10n.btnNext,
      ),
    ];

    final currentPageData = pages[_currentPage];
    final accentColor = currentPageData.accentColor;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Dynamic Swiping Content (Images and Text)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final data = pages[index];
                  return Column(
                    children: [
                      // Illustration at the top
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                          child: Image.asset(
                            data.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(Icons.image_not_supported, size: 80, color: theme.colorScheme.primary),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary, // Using primary theme color (Dark Blue)
                              height: 1.2,
                            ),
                            children: [
                              TextSpan(text: data.titleTop),
                              TextSpan(
                                text: data.titleAccent,
                                style: TextStyle(color: theme.colorScheme.primary), // Keep it same or use accentColor if desired
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),

            // Fixed Bottom Section (Dots & Buttons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 12 : 8,
                        height: isActive ? 12 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),

                  // Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: TextButton(
                            onPressed: _skip,
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary.withOpacity(0.7),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(l10n.btnSkip),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _goNext(pages.length),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(currentPageData.primaryButtonText),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
