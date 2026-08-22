// lib/features/settings/presentation/views/settings_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/purchase_service.dart';
import '../../../../core/services/settings_notifier.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_theme.dart';

// ─── CONSTANTS ────────────────────────────────────────────────────────────

const _kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF00C2A8), Color(0xFF2F6BFF)],
);

// ─── LANGUAGE MODEL ───────────────────────────────────────────────────────

class AppLanguage {
  final String code;
  final String label;
  final String flag;
  const AppLanguage(this.code, this.label, this.flag);
}

const _languages = [
  AppLanguage('en', 'English', '🇬🇧'),
  AppLanguage('ur', 'اردو', '🇵🇰'),
  AppLanguage('es', 'Español', '🇪🇸'),
  AppLanguage('fr', 'Français', '🇫🇷'),
  AppLanguage('ar', 'العربية', '🇸🇦'),
  AppLanguage('hi', 'हिन्दी', '🇮🇳'),
  AppLanguage('zh', '中文', '🇨🇳'),
];

// ─── DARK MODE HELPERS ────────────────────────────────────────────────────

Color _scaffoldColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF13131E)
        : AppColors.surfaceLight;

Color _cardColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF252535)
        : Colors.white;

Color _textPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

Color _textSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;

Color _textMuted(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white38
        : Colors.black.withValues(alpha: 0.45);

Color _shadowColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.04);

Color _dividerColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.grey.shade100;

// ─── SHARED BOTTOM NAV ────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  List<({IconData icon, IconData selectedIcon, String label})> get _items => [
    (
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: T.of('home')
    ),
    (
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder_rounded,
    label: T.of('files')
    ),
    (
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
    label: T.of('apps')
    ),
    (
    icon: Icons.battery_std_outlined,
    selectedIcon: Icons.battery_full_rounded,
    label: T.of('battery')
    ),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.fileManager);
        break;
      case 2:
        context.go(AppRoutes.appManager);
        break;
      case 3:
        context.go(AppRoutes.batteryMonitor);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _items;
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == currentIndex;
            final color = selected
                ? _activeColor(index)
                : (isDark ? Colors.white38 : Colors.black38);
            return Expanded(
              child: InkWell(
                onTap: () => _onTap(context, index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? item.selectedIcon : item.icon,
                      color: color,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Color _activeColor(int index) {
    switch (index) {
      case 1:
        return const Color(0xFF2F6BFF);
      case 2:
        return const Color(0xFF6C63FF);
      case 3:
        return const Color(0xFF00C2A8);
      default:
        return const Color(0xFF2F6BFF);
    }
  }
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with TickerProviderStateMixin {
  bool _darkMode = false;
  bool _notifications = true;
  bool _hapticFeedback = true;
  bool _autoCleanReminders = true;
  bool _clearCacheOnExit = false;

  AppLanguage _language = _languages.first;
  String _appVersion = '';
  int _excludedItemsCount = 0;

  bool? _isPro;

  late final AnimationController _entrance;
  late final SettingsNotifier _settings;

  @override
  void initState() {
    super.initState();
    _settings = getIt<SettingsNotifier>();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _loadSavedSettings();
    _loadVersion();
    _loadProStatus();
    _loadExcludedCount();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  // ─── Loaders ────────────────────────────────────────────────────────────

  void _loadSavedSettings() {
    final savedLang = _languages.firstWhere(
          (l) => l.code == _settings.languageCode,
      orElse: () => _languages.first,
    );
    setState(() {
      _darkMode = _settings.darkMode;
      _notifications = _settings.notifications;
      _hapticFeedback = _settings.hapticFeedback;
      _autoCleanReminders = _settings.autoCleanReminders;
      _clearCacheOnExit = _settings.clearCacheOnExit;
      _language = savedLang;
    });
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      if (mounted) setState(() => _appVersion = T.of('unknown'));
    }
  }

  Future<void> _loadProStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _isPro = prefs.getBool(PrefKeys.isProUser) ?? false);
    }
    getIt<PurchaseService>().proStatusStream.listen((isPro) {
      if (mounted) setState(() => _isPro = isPro);
    });
  }

  Future<void> _loadExcludedCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _excludedItemsCount =
            (prefs.getStringList('excluded_items') ?? []).length;
      });
    }
  }

  // ─── Toggle Handlers ────────────────────────────────────────────────────

  Future<void> _onDarkModeChanged(bool v) async {
    _triggerHaptic();
    setState(() => _darkMode = v);
    await _settings.setDarkMode(v);
    _showToast(v ? T.of('darkModeEnabled') : T.of('darkModeDisabled'));
  }

  Future<void> _onNotificationsChanged(bool v) async {
    _triggerHaptic();
    setState(() => _notifications = v);
    await _settings.setNotifications(v);
    _showToast(
        v ? T.of('notificationsEnabled') : T.of('notificationsDisabled'));
  }

  Future<void> _onHapticChanged(bool v) async {
    setState(() => _hapticFeedback = v);
    await _settings.setHapticFeedback(v);
    if (v) HapticFeedback.lightImpact();
    _showToast(v ? T.of('hapticOn') : T.of('hapticOff'));
  }

  Future<void> _onAutoCleanChanged(bool v) async {
    _triggerHaptic();
    setState(() => _autoCleanReminders = v);
    await _settings.setAutoCleanReminders(v);
    _showToast(v ? T.of('autoCleanOn') : T.of('autoCleanOff'));
  }

  Future<void> _onClearCacheOnExitChanged(bool v) async {
    _triggerHaptic();
    if (v) {
      final confirmed = await _showConfirmDialog(
        title: T.of('clearCacheExitTitle'),
        message: T.of('clearCacheExitMessage'),
        confirmLabel: T.of('enable'),
        confirmColor: Colors.red,
      );
      if (!confirmed) return;
    }
    setState(() => _clearCacheOnExit = v);
    await _settings.setClearCacheOnExit(v);
    _showToast(v ? T.of('cacheOnExit') : T.of('autoClearDisabled'));
  }

  // ─── Action Handlers ────────────────────────────────────────────────────

  void _triggerHaptic() {
    if (_hapticFeedback) HapticFeedback.selectionClick();
  }

  Future<void> _shareApp() async {
    _triggerHaptic();
    await SharePlus.instance.share(
      ShareParams(
        text: T.of('shareAppMessage'),
        subject: T.of('appName'),
      ),
    );
  }

  Future<void> _pickLanguage() async {
    _triggerHaptic();

    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _LanguageSheet(current: _language),
    );
    if (selected != null && mounted) {
      setState(() => _language = selected);
      await _settings.setLanguageCode(selected.code);
      _showToast('${T.of('languageSet')} ${selected.label}');
    }
  }

  Future<void> _openExcludedItems() async {
    _triggerHaptic();
    await showDialog(
      context: context,
      builder: (ctx) => _ExcludedItemsDialog(
        onCountChanged: (count) {
          setState(() => _excludedItemsCount = count);
        },
      ),
    );
    _loadExcludedCount();
  }

  Future<void> _rateApp() async {
    _triggerHaptic();
    const url = 'https://play.google.com/store/apps/details?id=com.yourapp.id';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showToast(T.of('couldNotOpenStore'));
    }
  }

  Future<void> _openPrivacyPolicy() async {
    _triggerHaptic();
    const url = 'https://yourwebsite.com/privacy-policy';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTerms() async {
    _triggerHaptic();
    const url = 'https://yourwebsite.com/terms';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendFeedback() async {
    _triggerHaptic();
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@yourapp.com',
      queryParameters: {
        'subject': '${T.of('sendFeedback')} - ${T.of('appName')} v$_appVersion',
        'body': 'Hi team,\n\n',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showToast(T.of('noEmailApp'));
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E1E2E),
      ),
    );
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    Color confirmColor = Colors.red,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textPrimary(context),
          ),
        ),
        content: Text(
          message,
          style: TextStyle(color: _textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              T.of('cancel'),
              style: TextStyle(color: _textMuted(context)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Animation Helpers ──────────────────────────────────────────────────

  Animation<double> _stagger(int index) {
    final start = (index * 0.08).clamp(0.0, 0.6);
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        start,
        (start + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _animated(int index, Widget child) {
    final anim = _stagger(index);
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, (1 - anim.value) * 18),
          child: child,
        ),
      ),
      child: child,
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const navIndex = 0;

    return Scaffold(
      backgroundColor: _scaffoldColor(context),
      bottomNavigationBar: const _BottomNav(currentIndex: navIndex),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              onBack: () => context.pop(),
              isPro: _isPro,
              onUpgrade: () => context.push(AppRoutes.paywall),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── General ──────────────────────────────────────────
                  _animated(
                    0,
                    _SettingsSection(
                      title: T.of('general'),
                      children: [
                        _NavRow(
                          icon: Icons.translate_rounded,
                          iconColor: const Color(0xFF00BFA5),
                          title: T.of('language'),
                          subtitle: T.of('appDisplayLanguage'),
                          trailingText: '${_language.flag} ${_language.label}',
                          onTap: _pickLanguage,
                        ),
                        _ToggleRow(
                          icon: Icons.dark_mode_outlined,
                          iconColor: const Color(0xFF7C4DFF),
                          title: T.of('darkMode'),
                          subtitle: T.of('darkerColorTheme'),
                          value: _darkMode,
                          onChanged: _onDarkModeChanged,
                        ),
                        _ToggleRow(
                          icon: Icons.notifications_outlined,
                          iconColor: const Color(0xFF2F6BFF),
                          title: T.of('notifications'),
                          subtitle: T.of('notificationsSub'),
                          value: _notifications,
                          onChanged: _onNotificationsChanged,
                        ),
                        _ToggleRow(
                          icon: Icons.vibration_rounded,
                          iconColor: const Color(0xFFFFB020),
                          title: T.of('hapticFeedback'),
                          subtitle: T.of('hapticSub'),
                          value: _hapticFeedback,
                          onChanged: _onHapticChanged,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Cleaning ─────────────────────────────────────────
                  _animated(
                    1,
                    _SettingsSection(
                      title: T.of('cleaning'),
                      children: [
                        _NavRow(
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xFFFF7A3D),
                          title: T.of('excludedItems'),
                          subtitle: T.of('excludedSub'),
                          trailingText: '$_excludedItemsCount',
                          onTap: _openExcludedItems,
                        ),
                        _ToggleRow(
                          icon: Icons.notifications_active_outlined,
                          iconColor: const Color(0xFF2ECC71),
                          title: T.of('autoCleanReminders'),
                          subtitle: T.of('autoCleanSub'),
                          value: _autoCleanReminders,
                          onChanged: _onAutoCleanChanged,
                        ),
                        _ToggleRow(
                          icon: Icons.delete_sweep_outlined,
                          iconColor: const Color(0xFFFF5A5F),
                          title: T.of('clearCacheOnExit'),
                          subtitle: T.of('clearCacheSub'),
                          value: _clearCacheOnExit,
                          onChanged: _onClearCacheOnExitChanged,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── About ─────────────────────────────────────────────
                  _animated(
                    2,
                    _SettingsSection(
                      title: T.of('about'),
                      children: [
                        _NavRow(
                          icon: Icons.star_outline_rounded,
                          iconColor: const Color(0xFFFFB020),
                          title: T.of('rateApp'),
                          subtitle: T.of('rateAppSub'),
                          onTap: _rateApp,
                        ),
                        _NavRow(
                          icon: Icons.share_outlined,
                          iconColor: const Color(0xFF2F6BFF),
                          title: T.of('shareApp'),
                          subtitle: T.of('shareAppSub'),
                          onTap: _shareApp,
                        ),
                        _NavRow(
                          icon: Icons.privacy_tip_outlined,
                          iconColor: const Color(0xFF7C4DFF),
                          title: T.of('privacyPolicy'),
                          onTap: _openPrivacyPolicy,
                        ),
                        _NavRow(
                          icon: Icons.description_outlined,
                          iconColor: const Color(0xFF00BFA5),
                          title: T.of('termsOfService'),
                          onTap: _openTerms,
                        ),
                        _NavRow(
                          icon: Icons.feedback_outlined,
                          iconColor: const Color(0xFFE91E8C),
                          title: T.of('sendFeedback'),
                          onTap: _sendFeedback,
                        ),
                        _InfoRow(
                          icon: Icons.info_outline_rounded,
                          iconColor: _textMuted(context),
                          title: T.of('appVersion'),
                          value: _appVersion.isEmpty ? '…' : _appVersion,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final bool? isPro;
  final VoidCallback onUpgrade;

  const _Header({
    required this.onBack,
    required this.isPro,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 56, 20, 24),
      decoration: const BoxDecoration(
        gradient: _kGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -10,
            child: Icon(
              Icons.tune_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      T.of('settings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      T.of('customizeExperience'),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 4),
                child: _PremiumBanner(isPro: isPro, onUpgrade: onUpgrade),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── PREMIUM BANNER ───────────────────────────────────────────────────────

class _PremiumBanner extends StatefulWidget {
  final bool? isPro;
  final VoidCallback onUpgrade;

  const _PremiumBanner({required this.isPro, required this.onUpgrade});

  @override
  State<_PremiumBanner> createState() => _PremiumBannerState();
}

class _PremiumBannerState extends State<_PremiumBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPro == null) {
      return const SizedBox(height: 64);
    }

    final isPro = widget.isPro!;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isPro ? null : widget.onUpgrade,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final scale = isPro ? 1.0 : 1 + (_pulse.value * 0.12);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPro
                      ? Icons.verified_rounded
                      : Icons.workspace_premium_rounded,
                  color: const Color(0xFFFFD54F),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPro ? T.of('yourePro') : T.of('goPremium'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPro ? T.of('proSub') : T.of('premiumSub'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (!isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  T.of('upgrade'),
                  style: const TextStyle(
                    color: Color(0xFF2F6BFF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── LANGUAGE SHEET ───────────────────────────────────────────────────────

class _LanguageSheet extends StatelessWidget {
  final AppLanguage current;
  const _LanguageSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _textMuted(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    T.of('chooseLanguage'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    T.of('languageNote'),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                itemCount: _languages.length,
                itemBuilder: (ctx, i) {
                  final lang = _languages[i];
                  return _LanguageOptionTile(
                    language: lang,
                    selected: lang.code == current.code,
                    onTap: () => Navigator.of(context).pop(lang),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOptionTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language.label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: _textPrimary(context),
                ),
              ),
            ),
            AnimatedScale(
              scale: selected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SETTINGS SECTION ─────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _textMuted(context),
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _cardColor(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _shadowColor(context),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ─── TOGGLE ROW ───────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _IconBadge(icon: icon, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary(context),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.secondary,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: _dividerColor(context),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

// ─── NAV ROW ──────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback onTap;
  final bool isLast;

  const _NavRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailingText,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(20))
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _IconBadge(icon: icon, color: iconColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary(context),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingText != null) ...[
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      trailingText!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: _textMuted(context),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: _dividerColor(context),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

// ─── INFO ROW ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _IconBadge(icon: icon, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary(context),
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: _dividerColor(context),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

// ─── ICON BADGE ───────────────────────────────────────────────────────────

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ─── EXCLUDED ITEMS DIALOG ────────────────────────────────────────────────

class _ExcludedItemsDialog extends StatefulWidget {
  final ValueChanged<int> onCountChanged;
  const _ExcludedItemsDialog({required this.onCountChanged});

  @override
  State<_ExcludedItemsDialog> createState() => _ExcludedItemsDialogState();
}

class _ExcludedItemsDialogState extends State<_ExcludedItemsDialog> {
  List<String> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _items = prefs.getStringList('excluded_items') ?? [];
      });
    }
  }

  Future<void> _remove(String item) async {
    setState(() => _items.remove(item));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('excluded_items', _items);
    widget.onCountChanged(_items.length);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _cardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        T.of('excludedItems'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _textPrimary(context),
        ),
      ),
      content: _items.isEmpty
          ? Text(
        T.of('noExcludedItems'),
        style: TextStyle(color: _textSecondary(context)),
      )
          : SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _items.length,
          itemBuilder: (ctx, i) => ListTile(
            dense: true,
            title: Text(
              _items[i],
              style: TextStyle(
                fontSize: 13,
                color: _textPrimary(context),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              onPressed: () => _remove(_items[i]),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            T.of('close'),
            style: TextStyle(color: _textMuted(context)),
          ),
        ),
      ],
    );
  }
}