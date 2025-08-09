import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    } else {
      // Navigate to auth/login screen
      // Get.toNamed('/auth');
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              children: [
                _buildPage1(context, height),

                _buildPage2(context, height),

                _buildPage3(context, height),
              ],
            ),

            Positioned(
              top: height * 0.08,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.asset('assets/icons/logo.png'),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: height * 0.15,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage.round() == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage.round() == index
                          ? AppColors.primary
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            Positioned(
              left: 20,
              right: 20,
              bottom: height * 0.05,
              child: _currentPage.round() == 2
                  ? _buildGetStartedButton()
                  : _buildNextSkipButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1(BuildContext context, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          SizedBox(height: height * 0.22),

          Flexible(
            flex: 4,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: height * 0.25,
                maxHeight: height * 0.4,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/onboard/page1.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Flexible(flex: 1, child: SizedBox(height: height * 0.04)),

          Text(
            "Organize Ideas.\nAchieve Goals.",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: height < 700 ? 28 : 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: height * 0.02),

          Text(
            "Visual project management\nmade easy",
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: height < 700 ? 14 : 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildPage2(BuildContext context, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          SizedBox(height: height * 0.22),

          Flexible(
            flex: 4,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: height * 0.25,
                maxHeight: height * 0.4,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/onboard/page2.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Flexible(flex: 1, child: SizedBox(height: height * 0.04)),

          Text(
            "Create Boards That\nWork for You",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: height < 700 ? 28 : 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: height * 0.02),

          Text(
            "Whether it's your next big idea or daily to-\ndos — organize it your way.",
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: height < 700 ? 14 : 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildPage3(BuildContext context, double height) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0),
      child: Column(
        children: [
          SizedBox(height: height * 0.22),

          Flexible(
            flex: 4,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: height * 0.25,
                maxHeight: height * 0.4,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/onboard/page3.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Flexible(flex: 1, child: SizedBox(height: height * 0.04)),

          Text(
            "Plan Smarter. Together.",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: height < 700 ? 28 : 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: height * 0.02),
          Text(
            "Work with friends, classmates or teammates\nfrom idea to execution.",
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: height < 700 ? 14 : 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Get Started',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildNextSkipButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: _skipToEnd,
          child: Text(
            'Skip',
            style: TextStyle(color: AppColors.secondary, fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text(
            'Next',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
