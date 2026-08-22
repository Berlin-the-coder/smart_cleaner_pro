// app_manager_view.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import 'package:smart_cleaner_pro/core/router/app_router.dart';
import 'package:smart_cleaner_pro/core/theme/theme_extensions.dart';
import 'package:smart_cleaner_pro/features/app_manager/presentation/view/unused_apps_view.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/settings_notifier.dart';
import '../../../../core/services/translation_service.dart';
import '../../domain/app_manager_state.dart';
import '../viewmodel/app_manager_viewmodel.dart';

// ─── CONSTANTS ────────────────────────────────────────────────────────────────
const _kPurple     = Color(0xFF6C63FF);
const _kPurpleDark = Color(0xFF5546E8);

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
      case 1:  return const Color(0xFF2F6BFF); // Files
      case 2:  return _kPurple;                // Apps
      case 3:  return const Color(0xFF00C2A8); // Battery
      default: return const Color(0xFF2F6BFF); // Home
    }
  }
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class AppManagerView extends ConsumerWidget {
  const AppManagerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(appManagerViewModelProvider);
    final vm     = ref.read(appManagerViewModelProvider.notifier);
    final isDark = context.isDark;
    final settings = getIt<SettingsNotifier>();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
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
            body: state.when(
              loading: () => Column(
                children: [
                  const _Header(appCount: null),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: _kPurple),
                    ),
                  ),
                ],
              ),
              loaded: (apps, sortOrder) => _LoadedPage(
                apps: apps,
                onRefresh: vm.load,
                onUninstall: vm.uninstall,
              ),
              unsupportedPlatform: () => Column(
                children: [
                  const _Header(appCount: null),
                  Expanded(
                    child: _CenterMsg(
                      icon: Icons.block_rounded,
                      message: T.of('unsupportedPlatform'),
                    ),
                  ),
                ],
              ),
              error: (msg) => Column(
                children: [
                  const _Header(appCount: null),
                  Expanded(
                    child: _CenterMsg(
                      icon: Icons.error_outline,
                      iconColor: Colors.red,
                      message: msg,
                      buttonText: T.of('retry'),
                      onTap: vm.load,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── HEADER (gradient — same look in both modes) ─────────────────────────────
class _Header extends StatelessWidget {
  final int? appCount;
  const _Header({required this.appCount});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(gradient: _kGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
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
                        T.of('appManager'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        T.of('appManagerSub'),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const _AppsIllustration(),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── ILLUSTRATION ─────────────────────────────────────────────────────────────
class _AppsIllustration extends StatelessWidget {
  const _AppsIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 120,
    height: 100,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 0, top: 0,
          child: Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 13, top: 13,
          child: Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.apps_rounded, color: _kPurple, size: 34),
          ),
        ),
        Positioned(
          left: 0, top: 0,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.download_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        Positioned(
          right: 0, bottom: 0,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFB39DFF).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sd_storage_rounded,
                color: Colors.white, size: 17),
          ),
        ),
        Positioned(
          left: 4, bottom: 4,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.settings_rounded,
                color: Colors.white, size: 15),
          ),
        ),
      ],
    ),
  );
}

// ─── LOADED PAGE ──────────────────────────────────────────────────────────────
class _LoadedPage extends StatefulWidget {
  final List<AppInfo> apps;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String) onUninstall;

  const _LoadedPage({
    required this.apps,
    required this.onRefresh,
    required this.onUninstall,
  });

  @override
  State<_LoadedPage> createState() => _LoadedPageState();
}

enum _Filter { all, user, system, recent }

class _LoadedPageState extends State<_LoadedPage> {
  String  _query  = '';
  _Filter _filter = _Filter.all;

  int get _userCount   => widget.apps.where((a) => a.isSystemApp != true).length;
  int get _systemCount => widget.apps.where((a) => a.isSystemApp == true).length;
  int get _recentCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return widget.apps
        .where((a) => DateTime.fromMillisecondsSinceEpoch(
        a.installedTimestamp).isAfter(cutoff))
        .length;
  }

  List<AppInfo> get _filtered {
    var list = widget.apps;
    switch (_filter) {
      case _Filter.user:
        list = list.where((a) => a.isSystemApp != true).toList();
      case _Filter.system:
        list = list.where((a) => a.isSystemApp == true).toList();
      case _Filter.recent:
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        list = list
            .where((a) => DateTime.fromMillisecondsSinceEpoch(
            a.installedTimestamp).isAfter(cutoff))
            .toList();
      case _Filter.all:
        break;
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((a) => a.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> _confirmUninstall(AppInfo app) async {
    final isDark = context.isDark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? _kCardDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${T.of('uninstall')} ${app.name}?',
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
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A5F)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(T.of('uninstall')),
          ),
        ],
      ),
    );
    if (ok == true) await widget.onUninstall(app.packageName);
  }

  void _showAppInfo(AppInfo app) {
    final isDark = context.isDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? _kCardDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _AppIcon(icon: app.icon, size: 64),
            const SizedBox(height: 14),
            Text(
              app.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              app.packageName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            _InfoRow(
              label: T.of('type'),
              value: app.isSystemApp == true
                  ? T.of('systemAppLabel')
                  : T.of('userAppLabel'),
            ),
            const SizedBox(height: 20),
            if (app.isSystemApp != true)
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _confirmUninstall(app);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFFF5A5F).withValues(alpha: 0.15)
                          : const Color(0xFFFFEBEC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        T.of('uninstall'),
                        style: const TextStyle(
                          color: Color(0xFFFF5A5F),
                          fontWeight: FontWeight.bold,
                        ),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final isDark   = context.isDark;

    return RefreshIndicator(
      color: _kPurple,
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(appCount: widget.apps.length),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCard(
                    total: widget.apps.length,
                    userCount: _userCount,
                    systemCount: _systemCount,
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('${T.of('all')} (${widget.apps.length})', _Filter.all),
                        _chip('${T.of('user')} ($_userCount)', _Filter.user),
                        _chip('${T.of('system')} ($_systemCount)', _Filter.system),
                        _chip('${T.of('recent')} ($_recentCount)', _Filter.recent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? _kCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark
                          ? []
                          : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: T.of('searchApps'),
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  T.of('noAppsFound'),
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) => _AppTile(
                    app: filtered[i],
                    onUninstall: () => _confirmUninstall(filtered[i]),
                    onInfo: () => _showAppInfo(filtered[i]),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: _SmartCleanCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UnusedAppsView(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter f) {
    final isDark = context.isDark;
    final sel = _filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? _kPurple : (isDark ? _kCardDark : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: sel
                  ? _kPurple
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
              fontSize: 13,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SUMMARY CARD ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int total, userCount, systemCount;
  const _SummaryCard({
    required this.total,
    required this.userCount,
    required this.systemCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark   = context.isDark;
    final userFrac = total == 0 ? 0.0 : userCount / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.apps_rounded,
                    color: _kPurple, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total ${T.of('appsInstalled')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '$userCount ${T.of('userApps')} • $systemCount ${T.of('systemApps')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: userFrac,
              minHeight: 10,
              backgroundColor:
              isDark ? Colors.white12 : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(_kPurple),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Legend(
                  color: _kPurple,
                  label: T.of('userApps'),
                  value: '$userCount'),
              const SizedBox(width: 20),
              _Legend(
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                  label: T.of('systemApps'),
                  value: '$systemCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label, value;
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9, height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54)),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87)),
      ],
    );
  }
}

// ─── APP TILE ─────────────────────────────────────────────────────────────────
class _AppTile extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onUninstall;
  final VoidCallback onInfo;

  const _AppTile({
    required this.app,
    required this.onUninstall,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _AppIcon(icon: app.icon, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  app.packageName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          if (app.isSystemApp != true)
            GestureDetector(
              onTap: onUninstall,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  T.of('uninstall'),
                  style: const TextStyle(
                    color: _kPurple,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                T.of('system'),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onInfo,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              child: Icon(
                Icons.info_outline,
                size: 15,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── APP ICON ─────────────────────────────────────────────────────────────────
class _AppIcon extends StatelessWidget {
  final Uint8List? icon;
  final double size;
  const _AppIcon({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: icon != null
          ? Image.memory(icon!, width: size, height: size, fit: BoxFit.cover)
          : Container(
        width: size, height: size,
        color: isDark ? Colors.white10 : Colors.grey.shade200,
        child: Icon(Icons.android,
            size: size * 0.6,
            color: isDark ? Colors.white38 : Colors.grey),
      ),
    );
  }
}

// ─── SMART CLEAN CARD ─────────────────────────────────────────────────────────
class _SmartCleanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SmartCleanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPurple.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: isDark ? _kCardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.cleaning_services_rounded,
                color: _kPurple, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  T.of('freeUpMoreSpace'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  T.of('reviewUserApps'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: _kBtnGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                T.of('view'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── INFO ROW ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}

// ─── CENTER MESSAGE ───────────────────────────────────────────────────────────
class _CenterMsg extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String message;
  final String? buttonText;
  final VoidCallback? onTap;

  const _CenterMsg({
    required this.icon,
    this.iconColor,
    required this.message,
    this.buttonText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: iconColor ?? Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            if (buttonText != null && onTap != null) ...[
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
                    buttonText!,
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