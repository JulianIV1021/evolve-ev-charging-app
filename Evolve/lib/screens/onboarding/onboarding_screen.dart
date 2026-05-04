import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

const _kOnboardingKey = 'onboarding_complete';

/// Call from main() or the router to check if onboarding has been seen.
Future<bool> isOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingKey) ?? false;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      emoji: '⚡',
      emojiColor: AppColors.accent,
      title: 'Find Chargers Near You',
      body:
          'See every available EV charger on a live map. Filter by connector type, speed, and availability.',
    ),
    _Slide(
      emoji: '📱',
      emojiColor: Color(0xFF007AFF),
      title: 'Scan & Start Charging',
      body:
          'Point your camera at any EvolvePRO QR code to start a session instantly. No card, no fuss.',
    ),
    _Slide(
      emoji: '🌿',
      emojiColor: AppColors.success,
      title: 'Drive Greener',
      body:
          'Our smart routing picks the most energy-efficient path to your charger, saving CO₂ every trip.',
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: SafeArea(
        child: Stack(
          children: [
            // ── Skip button ──────────────────────────────────────────
            if (!isLast)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.lg,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _complete,
                  child: Text(
                    'Skip',
                    style: AppTypography.callout
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),

            // ── Page view ────────────────────────────────────────────
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
            ),

            // ── Bottom controls ──────────────────────────────────────
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.xl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppColors.accent
                              : const Color(0xFFC7C7CC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(14),
                      onPressed: _next,
                      child: Text(
                        isLast ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
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
}

// ---------------------------------------------------------------------------
// Single slide view
// ---------------------------------------------------------------------------

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60), // Space for skip button
          // Icon / emoji
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.emojiColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                slide.emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            slide.title,
            style: AppTypography.largeTitle.copyWith(
              color: AppColors.label,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            slide.body,
            style: AppTypography.callout
                .copyWith(color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 160), // Space for bottom controls
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------

class _Slide {
  const _Slide({
    required this.emoji,
    required this.emojiColor,
    required this.title,
    required this.body,
  });

  final String emoji;
  final Color emojiColor;
  final String title;
  final String body;
}
