import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/models/onboarding_item.dart';
import 'package:seerah_timeline/widget/onboarding_content.dart';
import 'package:seerah_timeline/auth/auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<OnboardingItem> _pages = [
    OnboardingItem(
      title: "Journey Through Seerah",
      description:
          "Explore the authentic life events of the Prophet Muhammad ﷺ step by step with our interactive timelines.",
      imagePath: "", // Placeholder, utilizing icons in the content widget
    ),
    OnboardingItem(
      title: "Interactive Lessons",
      description:
          "Dive deep into engaging wisdom filled with historical context and profound lessons.",
      imagePath: "",
    ),
    OnboardingItem(
      title: "Learn & Play",
      description:
          "Test your knowledge with fun and challenging quizzes after every milestone.",
      imagePath: "",
    ),
    OnboardingItem(
      title: "AI Chatbot",
      description:
          "Got questions? Get instant, profound insights about the life of the Prophet ﷺ from our Smart AI.",
      imagePath: "",
    ),
    OnboardingItem(
      title: "The Shumail",
      description:
          "Discover the beautiful character, appearance and timeless teachings of the Prophet Muhammad ﷺ.",
      imagePath: "",
    ),
  ];

  final List<IconData> _pageIcons = [
    Icons.timeline_rounded,
    Icons.menu_book_rounded,
    Iconsax.medal_star,
    Icons.auto_awesome_rounded, // Universal AI sparkle symbol
    Icons
        .volunteer_activism_rounded, // Emphasizes compassion, character, and teachings
  ];

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

  void _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      // Navigate to AuthGate once onboarding is finished.
      // AuthGate will decide if the user sees the dashboard or the login screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TextButton(
                  onPressed: _onFinish,
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingContent(
                    item: _pages[index],
                    displayIcon: _pageIcons[index],
                    isActive: index == _currentIndex,
                  );
                },
              ),
            ),

            // Bottom Navigation & Indicators
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(index: index),
                    ),
                  ),

                  // Next / Get Started Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentIndex == _pages.length - 1 ? 140 : 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        if (_currentIndex == _pages.length - 1) {
                          _onFinish();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease,
                          );
                        }
                      },
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentIndex == _pages.length - 1
                              ? const Text(
                                  "Get Started",
                                  key: ValueKey("text"),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  key: ValueKey("icon"),
                                  color: Colors.white,
                                ),
                        ),
                      ),
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

  Widget _buildDot({required int index}) {
    final isActive = _currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.accent
            : AppColors.primaryLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
