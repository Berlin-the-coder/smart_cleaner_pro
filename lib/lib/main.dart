// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/services/settings_notifier.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = getIt<SettingsNotifier>();

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
          // ── NO localizationsDelegates needed anymore ──
          routerConfig: appRouter,
        );
      },
    );
  }
}