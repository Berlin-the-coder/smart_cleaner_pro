import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/app_manager/presentation/view/app_manager_view.dart';
import '../../features/battery_monitor/presentation/battery_monitor_view.dart';
import '../../features/dashboard/presentation/view/dashboard_view.dart';
import '../../features/device_info/presentation/device_info_view.dart';
import '../../features/duplicate_finder/presentation/view/duplicate_finder_view.dart';
import '../../features/file_manager/presentation/view/file_manager_view.dart';
import '../../features/image_compressor/presentation/view/image_compressor_view.dart';
import '../../features/junk_cleaner/presentation/view/junk_cleaner_view.dart';
import '../../features/onboarding/presentation/language_selection_view.dart';
import '../../features/onboarding/presentation/onboarding_view.dart';
import '../../features/onboarding/presentation/splash_view.dart';
import '../../features/paywall/presentation/paywall_view.dart';
import '../../features/settings/presentation/view/settings_view.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const junkCleaner = '/junk-cleaner';
  static const duplicateFinder = '/duplicate-finder';
  static const imageCompressor = '/image-compressor';
  static const fileManager = '/file-manager';
  static const appManager = '/app-manager';
  static const batteryMonitor = '/battery-monitor';
  static const deviceInfo = '/device-info';
  static const settings = '/settings';
  static const paywall = '/paywall';
}

/// Shared page transition used by every route below: a subtle
/// fade + slide-in (Material's "shared axis" style), ~300ms with an
/// ease-out curve. Deliberately cheap — Opacity and a translated
/// Offset are both GPU-accelerated and don't touch layout, so this
/// adds visual polish without any measurable cost to scan/scroll
/// performance elsewhere in the app.
Page<void> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => _buildPage(state, const SplashView()),
    ),
    GoRoute(
      path: AppRoutes.language,
      pageBuilder: (context, state) =>
          _buildPage(state, const LanguageSelectionView()),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) =>
          _buildPage(state, const OnboardingView()),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      pageBuilder: (context, state) =>
          _buildPage(state, const DashboardView()),
    ),
    GoRoute(
      path: AppRoutes.junkCleaner,
      pageBuilder: (context, state) =>
          _buildPage(state, const JunkCleanerView()),
    ),
    GoRoute(
      path: AppRoutes.duplicateFinder,
      pageBuilder: (context, state) =>
          _buildPage(state, const DuplicateFinderView()),
    ),
    GoRoute(
      path: AppRoutes.imageCompressor,
      pageBuilder: (context, state) =>
          _buildPage(state, const ImageCompressorView()),
    ),
    GoRoute(
      path: AppRoutes.fileManager,
      pageBuilder: (context, state) =>
          _buildPage(state, const FileManagerView()),
    ),
    GoRoute(
      path: AppRoutes.appManager,
      pageBuilder: (context, state) =>
          _buildPage(state, const AppManagerView()),
    ),
    GoRoute(
      path: AppRoutes.batteryMonitor,
      pageBuilder: (context, state) =>
          _buildPage(state, const BatteryMonitorView()),
    ),
    GoRoute(
      path: AppRoutes.deviceInfo,
      pageBuilder: (context, state) =>
          _buildPage(state, const DeviceInfoView()),
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) =>
          _buildPage(state, const SettingsView()),
    ),
    GoRoute(
      path: AppRoutes.paywall,
      pageBuilder: (context, state) =>
          _buildPage(state, const PaywallView()),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);