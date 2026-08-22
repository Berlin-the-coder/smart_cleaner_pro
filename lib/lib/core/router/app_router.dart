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
import '../../features/onboarding/presentation/onboarding_view.dart';
import '../../features/onboarding/presentation/splash_view.dart';
import '../../features/paywall/presentation/paywall_view.dart';
import '../../features/settings/presentation/view/settings_view.dart';

abstract class AppRoutes {
  static const splash = '/';
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

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashView(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingView(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardView(),
    ),
    GoRoute(
      path: AppRoutes.junkCleaner,
      builder: (context, state) => const JunkCleanerView(),
    ),
    GoRoute(
      path: AppRoutes.duplicateFinder,
      builder: (context, state) => const DuplicateFinderView(),
    ),
    GoRoute(
      path: AppRoutes.imageCompressor,
      builder: (context, state) => const ImageCompressorView(),
    ),
    GoRoute(
      path: AppRoutes.fileManager,
      builder: (context, state) => const FileManagerView(),
    ),
    GoRoute(
      path: AppRoutes.appManager,
      builder: (context, state) => const AppManagerView(),
    ),
    GoRoute(
      path: AppRoutes.batteryMonitor,
      builder: (context, state) => const BatteryMonitorView(),
    ),
    GoRoute(
      path: AppRoutes.deviceInfo,
      builder: (context, state) => const DeviceInfoView(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsView(),
    ),
    GoRoute(
      path: AppRoutes.paywall,
      builder: (context, state) => const PaywallView(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);