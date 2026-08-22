import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class _Slide {
  final String  title;
  final String  description;
  final IconData icon;
  const _Slide(this.title, this.description, this.icon);
}

const _slides = [
  _Slide(
    'Clean junk in one tap',
    'Find and remove cache, temporary and residual files safely.',
    Icons.cleaning_services_rounded,
  ),
  _Slide(
    'Find duplicate files',
    'Free up space by removing duplicate photos, videos and audio.',
    Icons.copy_all_rounded,
  ),
  _Slide(
    'Monitor your device',
    'Track battery health and manage installed apps effortlessly.',
    Icons.battery_charging_full_rounded,
  ),
];

// ─── DARK MODE HELPERS ────────────────────────────────────────────────────────
Color _scaffoldBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF13131E)
        : Colors.white;

Color _dotInactive(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.grey.shade300;

Color _iconBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? AppColors.primary.withValues(alpha: 0.15)
        : AppColors.primary.withValues(alpha: 0.08);

Color _textSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;

// ─── VIEW ─────────────────────────────────────────────────────────────────────
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.onboardingComplete, true);
    if (!mounted) return;
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _scaffoldBg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── SKIP BUTTON ─────────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white60
                        : AppColors.primary,
                  ),
                ),
              ),
            ),

            // ── PAGE VIEW ───────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount:  _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with subtle tinted background circle
                        Container(
                          width:  160,
                          height: 160,
                          decoration: BoxDecoration(
                            color:  _iconBg(context),
                            shape:  BoxShape.circle,
                          ),
                          child: Icon(
                            slide.icon,
                            size:  80,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            color: isDark
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: _textSecondary(context),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── PAGE INDICATOR DOTS ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                    (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width:  i == _index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? AppColors.primary
                        : _dotInactive(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            // ── NEXT / GET STARTED BUTTON ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (_index == _slides.length - 1) {
                      _complete();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve:    Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _index == _slides.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: const TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}