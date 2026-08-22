import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/settings_notifier.dart';
import '../../../core/theme/app_theme.dart';

class _LangOption {
  final String code;
  final String label;
  final String flag;
  const _LangOption(this.code, this.label, this.flag);
}

const _languages = [
  _LangOption('en', 'English', '🇬🇧'),
  _LangOption('ur', 'اردو', '🇵🇰'),
  _LangOption('es', 'Español', '🇪🇸'),
  _LangOption('fr', 'Français', '🇫🇷'),
  _LangOption('ar', 'العربية', '🇸🇦'),
  _LangOption('hi', 'हिन्दी', '🇮🇳'),
  _LangOption('zh', '中文', '🇨🇳'),
];

/// Full-screen language selector shown once, between Splash and
/// Onboarding, for first-time users only. Returning users (who already
/// finished onboarding) never see this screen again — see SplashView's
/// routing logic.
class LanguageSelectionView extends StatefulWidget {
  const LanguageSelectionView({super.key});

  @override
  State<LanguageSelectionView> createState() => _LanguageSelectionViewState();
}

class _LanguageSelectionViewState extends State<LanguageSelectionView> {
  String _selected = 'en';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = getIt<SettingsNotifier>().languageCode;
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    await getIt<SettingsNotifier>().setLanguageCode(_selected);
    if (!mounted) return;
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF13131E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(Icons.language_rounded, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Choose your language',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You can change this later in Settings',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _languages.length,
                itemBuilder: (context, i) {
                  final lang = _languages[i];
                  final selected = lang.code == _selected;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selected = lang.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.secondary.withValues(alpha: 0.1)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.03)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.secondary
                              : Colors.transparent,
                          width: 1.4,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(lang.flag,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              lang.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.secondary, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
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
                  onPressed: _saving ? null : _continue,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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
