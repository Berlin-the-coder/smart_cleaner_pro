// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/services/settings_notifier.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Started, NOT awaited here — see serviceLocatorReady's doc comment.
  // runApp() below can now paint the first frame (our own splash
  // screen) right away instead of waiting behind a blank native screen
  // for however long setup takes.
  serviceLocatorReady = setupServiceLocator();
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SettingsNotifier? _settings;

  @override
  void initState() {
    super.initState();
    _awaitSettings();
  }

  Future<void> _awaitSettings() async {
    // Wait for setup to actually finish before touching GetIt at all —
    // SettingsNotifier registers LAST (after Ads/Purchases init), so
    // reading it any earlier is exactly what caused the
    // "SettingsNotifier is not registered inside GetIt" crash once
    // runApp() started firing before setup completed.
    if (serviceLocatorReady != null) await serviceLocatorReady;
    if (!mounted) return;
    setState(() => _settings = getIt<SettingsNotifier>());
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    // Before setup finishes: render with a sensible default theme and
    // no GetIt access at all. This is only ever visible for a brief
    // instant — SplashView (the router's initial route) itself also
    // awaits serviceLocatorReady before navigating anywhere, and by
    // the time it would need theme-dependent settings for later
    // screens, this widget has already rebuilt with the real
    // SettingsNotifier.
    if (settings == null) {
      return MaterialApp.router(
        title:                    'Smart Cleaner',
        debugShowCheckedModeBanner: false,
        theme:                    AppTheme.light(),
        darkTheme:                AppTheme.dark(),
        themeMode:                ThemeMode.system,
        routerConfig:             appRouter,
      );
    }

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp.router(
          title:                    'Smart Cleaner',
          debugShowCheckedModeBanner: false,
          theme:                    AppTheme.light(),
          darkTheme:                AppTheme.dark(),
          themeMode: settings.darkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          routerConfig: appRouter,
        );
      },
    );
  }
}