import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 5500));
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(PrefKeys.onboardingComplete) ?? false;
    if (!mounted) return;
    context.go(onboardingDone ? AppRoutes.dashboard : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dark mode gradient: subtle, professional dark gradient
    const darkGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0F0F1E),
        Color(0xFF1A1A2E),
      ],
    );

    // Use dashboard gradient for light mode, dark gradient for dark mode
    final gradient = isDark ? darkGradient : AppColors.dashboardGradient;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── LOTTIE ANIMATION ────────────────────────────────────────
              SizedBox(
                width:  200,
                height: 200,
                child: Lottie.asset(
                  'assets/animations/cleaningsplash.json',
                  fit:    BoxFit.contain,
                  repeat: true,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.cleaning_services_rounded,
                    size:  96,
                    color: isDark ? Colors.white : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── APP NAME ────────────────────────────────────────────────
              Text(
                AppConstants.appName,
                style: TextStyle(
                  color:         Colors.white,
                  fontSize:      28,
                  fontWeight:    FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // ── LOADING MESSAGE ─────────────────────────────────────────
              const Text(
                'Cleaning in progress...',
                style: TextStyle(
                  color:    Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}