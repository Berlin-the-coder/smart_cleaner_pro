// unused_apps_view.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:smart_cleaner_pro/core/router/app_router.dart';
import 'package:smart_cleaner_pro/core/theme/theme_extensions.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/settings_notifier.dart';
import '../../../../core/services/translation_service.dart';

const _kPurple = Color(0xFF6C63FF);
const _kRed    = Color(0xFFFF5A5F);

const _kBgDark   = Color(0xFF14111F);
const _kCardDark = Color(0xFF1E1A2E);

const _kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFC9BFFF), Color(0xFF7B6FEF)],
);

const _kBtnGradient = LinearGradient(
  colors: [Color(0xFF6C63FF), Color(0xFF5546E8)],
);

// ─── SHARED BOTTOM NAV ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  static const _icons = [
    (icon: Icons.home_outlined,        selectedIcon: Icons.home_rounded),
    (icon: Icons.folder_outlined,      selectedIcon: Icons.folder_rounded),
    (icon: Icons.grid_view_outlined,   selectedIcon: Icons.grid_view_rounded),
    (icon: Icons.battery_std_outlined, selectedIcon: Icons.battery_full_rounded),
  ];

  static const _labelKeys = ['home', 'files', 'apps', 'battery'];

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
    final isDark = context.isDark;
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;
    final settings = getIt<SettingsNotifier>();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return SafeArea(
          top: false,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? _kCardDark : Colors.white,
              boxShadow: isDark
                  ? []
                  : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_icons.length, (index) {
                final item     = _icons[index];
                final selected = index == currentIndex;
                final color    = selected ? _activeColor(index) : inactiveColor;
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
                          T.of(_labelKeys[index]),
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
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
      },
    );
  }

  Color _activeColor(int index) {
    switch (index) {
      case 1:  return const Color(0xFF2F6BFF);
      case 2:  return _kPurple;
      case 3:  return const Color(0xFF00C2A8);
      default: return const Color(0xFF2F6BFF);
    }
  }
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class UnusedAppsView extends StatefulWidget {
  const UnusedAppsView({super.key});

  @override
  State<UnusedAppsView> createState() => _UnusedAppsViewState();
}

class _UnusedAppsViewState extends State<UnusedAppsView>
    with WidgetsBindingObserver {
  List<_UnusedApp> _apps = [];
  bool   _loading           = true;
  bool   _permissionDenied  = false;
  String? _error;
  int    _thresholdDays     = 60;

  late final SettingsNotifier _settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = getIt<SettingsNotifier>();
    _settings.addListener(_onSettingsChanged);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _permissionDenied) {
      _load();
    }
  }

  Future<bool> _hasPermission() async {
    try {
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openPermissionSettings() async {
    await UsageStats.grantUsagePermission();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading          = true;
      _permissionDenied = false;
      _error            = null;
    });

    final granted = await _hasPermission();
    if (!granted) {
      if (!mounted) return;
      setState(() { _permissionDenied = true; _loading = false; });
      return;
    }

    try {
      final List<AppInfo> installed = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => [],
      );

      if (installed.isEmpty) {
        if (!mounted) return;
        setState(() { _apps = []; _loading = false; });
        return;
      }

      Map<String, int> lastUsed = {};
      try {
        final end   = DateTime.now();
        final start = end.subtract(const Duration(days: 90));
        final stats = await UsageStats.queryUsageStats(start, end)
            .timeout(const Duration(seconds: 15));
        for (final s in stats) {
          if (s.packageName == null) continue;
          final lu = int.tryParse(s.lastTimeUsed ?? '0') ?? 0;
          if (lu > 0) lastUsed[s.packageName!] = lu;
        }
      } catch (_) {}

      final now      = DateTime.now();
      final cutoffMs = now
          .subtract(Duration(days: _thresholdDays))
          .millisecondsSinceEpoch;

      final unused = <_UnusedApp>[];
      for (final app in installed) {
        final lu = lastUsed[app.packageName];
        if (lu != null) {
          if (lu < cutoffMs) {
            unused.add(_UnusedApp(info: app, lastUsedMs: lu));
          }
        } else {
          final installedMs = app.installedTimestamp;
          if (installedMs < cutoffMs) {
            unused.add(_UnusedApp(info: app, lastUsedMs: 0));
          }
        }
      }

      unused.sort((a, b) => a.lastUsedMs.compareTo(b.lastUsedMs));

      if (!mounted) return;
      setState(() { _apps = unused; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _uninstall(_UnusedApp app) async {
    final isDark = context.isDark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? _kCardDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${T.of('uninstall')} ${app.info.name}?',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          T.of('uninstallConfirmDesc'),
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              T.of('cancel'),
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(T.of('uninstall')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await InstalledApps.uninstallApp(app.info.packageName);
      await Future.delayed(const Duration(seconds: 1));
      await _load();
    } catch (_) {
      await _load();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Theme(
      data: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primaryColor: _kPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _kPurple,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        scaffoldBackgroundColor: isDark ? _kBgDark : const Color(0xFFF6F5FF),
      ),
      child: Scaffold(
        backgroundColor: isDark ? _kBgDark : const Color(0xFFF6F5FF),
        bottomNavigationBar: const _BottomNav(currentIndex: 2),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    width: double.infinity,
    decoration: const BoxDecoration(gradient: _kGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        T.of('unusedApps'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        T.of('unusedAppsSub'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.hourglass_empty_rounded,
                      color: Colors.white, size: 38),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _thresholdBtn(T.of('twoMonths'), 60),
                const SizedBox(width: 10),
                _thresholdBtn(T.of('threeMonths'), 90),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _thresholdBtn(String label, int days) {
    final sel = _thresholdDays == days;
    return GestureDetector(
      onTap: _loading
          ? null
          : () {
        if (sel) return;
        setState(() => _thresholdDays = days);
        _load();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? _kPurple : Colors.white,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final isDark = context.isDark;

    if (_permissionDenied) {
      return _Placeholder(
        icon: Icons.lock_outline_rounded,
        title: T.of('usageAccessRequired'),
        subtitle: T.of('usageAccessDesc'),
        buttonLabel: T.of('openSettings'),
        onTap: _openPermissionSettings,
      );
    }

    if (_error != null) {
      return _Placeholder(
        icon: Icons.error_outline_rounded,
        iconColor: _kRed,
        title: T.of('somethingWrong'),
        subtitle: _error!,
        buttonLabel: T.of('retry'),
        onTap: _load,
      );
    }

    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _kPurple),
            const SizedBox(height: 16),
            Text(
              T.of('scanningAppUsage'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    if (_apps.isEmpty) {
      return _Placeholder(
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF2ECC71),
        title: T.of('allAppsActive'),
        subtitle: T.of('allAppsActiveDesc'),
      );
    }

    return RefreshIndicator(
      color: _kPurple,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _apps.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _infoCard();
          return _UnusedAppTile(
            app: _apps[i - 1],
            onUninstall: () => _uninstall(_apps[i - 1]),
          );
        },
      ),
    );
  }

  Widget _infoCard() {
    final isDark = context.isDark;
    final infoText = T
        .of('unusedAppsInfo')
        .replaceAll('{days}', '$_thresholdDays');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPurple.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: _kPurple, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_apps.length} ${T.of('apps')} $infoText',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DATA MODEL ───────────────────────────────────────────────────────────────
class _UnusedApp {
  final AppInfo info;
  final int     lastUsedMs;

  const _UnusedApp({required this.info, required this.lastUsedMs});

  String get lastUsedLabel {
    if (lastUsedMs == 0) return T.of('neverOpened');
    final days = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastUsedMs))
        .inDays;
    if (days == 0) return T.of('today');
    if (days < 30) return '$days ${T.of('daysAgo')}';
    final months = (days / 30).floor();
    return '$months ${months > 1 ? T.of('monthsAgo') : T.of('monthAgo')}';
  }
}

// ─── TILE ─────────────────────────────────────────────────────────────────────
class _UnusedAppTile extends StatelessWidget {
  final _UnusedApp   app;
  final VoidCallback onUninstall;

  const _UnusedAppTile({required this.app, required this.onUninstall});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: app.info.icon != null
                ? Image.memory(app.info.icon!,
                width: 46, height: 46, fit: BoxFit.cover)
                : Container(
              width: 46, height: 46,
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              child: Icon(Icons.android,
                  color: isDark ? Colors.white38 : Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.info.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12,
                        color: isDark ? Colors.white38 : Colors.black38),
                    const SizedBox(width: 4),
                    Text(
                      app.lastUsedLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onUninstall,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                T.of('uninstall'),
                style: const TextStyle(
                  color: _kRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PLACEHOLDER ──────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  final IconData      icon;
  final Color?        iconColor;
  final String        title;
  final String        subtitle;
  final String?       buttonLabel;
  final VoidCallback? onTap;

  const _Placeholder({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: (iconColor ?? _kPurple).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: iconColor ?? _kPurple),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
                height: 1.4,
              ),
            ),
            if (buttonLabel != null && onTap != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: _kBtnGradient,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    buttonLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}