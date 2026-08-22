// battery_monitor_view.dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_settings/app_settings.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extensions.dart';
import '../data/battery_details_service.dart';

// ─── DARK MODE COLORS ─────────────────────────────────────────────────────────
const _kBgDark   = Color(0xFF0D1A0D);
const _kCardDark = Color(0xFF1A2E1A);

/// Simple in-memory cache, alive for the whole app session (not tied to
/// this screen's widget lifecycle). Without this, every time the user
/// navigated to Battery Monitor the app re-queried and re-decoded every
/// installed app's icon from scratch, even if they'd just been on this
/// screen a moment ago. First visit still does the real scan; every
/// visit after that is instant until the app process restarts.
class _InstalledAppsCache {
  _InstalledAppsCache._();
  static List<AppInfo>? apps;
}

class _LevelSample {
  final DateTime time;
  final int      level;
  final bool     charging;
  const _LevelSample(this.time, this.level, this.charging);
}

// ─── SHARED BOTTOM NAV ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  // Labels are intentionally kept static here because the nav bar
  // rebuilds via the parent on language change; if you want live
  // switching, wrap the whole Scaffold in a StreamBuilder / Provider.
  static List<(IconData, IconData, String)> _navItems() => [
    (Icons.home_outlined,        Icons.home_rounded,         T.of('home')),
    (Icons.folder_outlined,      Icons.folder_rounded,       T.of('files')),
    (Icons.grid_view_outlined,   Icons.grid_view_rounded,    T.of('apps')),
    (Icons.settings_outlined, Icons.settings_rounded, T.of('settings')),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0: context.go(AppRoutes.dashboard);      break;
      case 1: context.go(AppRoutes.fileManager);    break;
      case 2: context.go(AppRoutes.appManager);     break;
      case 3: context.go(AppRoutes.settings); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark        = context.isDark;
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;
    final items         = _navItems();

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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final (inactiveIcon, activeIcon, label) = items[index];
            final selected = index == currentIndex;
            final color    = selected ? _activeColor(index) : inactiveColor;

            return Expanded(
              child: Pressable(
                onTap: () => _onTap(context, index),
                child: InkWell(
                onTap: () => _onTap(context, index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? activeIcon : inactiveIcon,
                      color: color,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
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
              )),
            );
          }),
        ),
      ),
    );
  }

  Color _activeColor(int index) => switch (index) {
    1    => const Color(0xFF2F6BFF),
    2    => const Color(0xFF6C63FF),
    3    => AppColors.success,
    _    => const Color(0xFF2F6BFF),
  };
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class BatteryMonitorView extends StatefulWidget {
  const BatteryMonitorView({super.key});

  @override
  State<BatteryMonitorView> createState() => _BatteryMonitorViewState();
}

class _BatteryMonitorViewState extends State<BatteryMonitorView> {
  final _battery        = Battery();
  final _detailsService = BatteryDetailsService();

  int?           _level;
  BatteryState?  _state;
  BatteryDetails _details = BatteryDetails.unavailable;

  final List<_LevelSample> _samples = [];
  StreamSubscription<BatteryState>? _stateSub;
  Timer? _pollTimer;

  List<AppInfo> _installedApps = [];
  bool          _appsLoading   = true;
  bool          _iconsLoading  = false;

  @override
  void initState() {
    super.initState();
    _load();
    _stateSub  = _battery.onBatteryStateChanged.listen((_) => _load());
    _pollTimer = Timer.periodic(const Duration(minutes: 2), (_) => _load());
    _loadInstalledApps();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Data loaders ────────────────────────────────────────────────────────────
  Future<void> _load() async {
    // batteryLevel, batteryState, and the native battery-details call
    // are three independent platform-channel round trips that don't
    // depend on each other's results — running them one after another
    // just adds their latencies together. Firing them together cuts
    // this to whichever single one is slowest instead of the sum.
    final results = await Future.wait([
      _battery.batteryLevel,
      _battery.batteryState,
      _detailsService.getDetails(),
    ]);
    if (!mounted) return;

    final level = results[0] as int;
    final state = results[1] as BatteryState;
    final details = results[2] as BatteryDetails;

    setState(() {
      _level = level;
      _state = state;
      _details = details;
      _samples.add(
        _LevelSample(DateTime.now(), level, state == BatteryState.charging),
      );
      if (_samples.length > 40) _samples.removeAt(0);
    });
  }

  Future<void> _loadInstalledApps() async {
    if (!Platform.isAndroid) {
      if (mounted) setState(() => _appsLoading = false);
      return;
    }

    // Cache hit — show instantly, no rescan, no icon-loading spinner.
    final cached = _InstalledAppsCache.apps;
    if (cached != null) {
      setState(() {
        _installedApps = cached;
        _appsLoading   = false;
        _iconsLoading  = false;
      });
      return;
    }

    try {
      // Phase 1 — fast: names + packages, NO icons. The previous
      // withIcon: true here was the cause of "finding apps" taking a
      // long time on this screen — decoding every launcher icon just
      // to show a per-app battery-usage list.
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
        withIcon: false,
      );
      apps.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      if (!mounted) return;
      setState(() {
        _installedApps = apps;
        _appsLoading   = false;
        _iconsLoading  = true;
      });

      // Phase 2 — icons stream in one at a time (bounded concurrency),
      // each one updating the list as soon as it's ready, instead of
      // waiting for every single icon before showing any of them.
      final positionByPackage = {
        for (var i = 0; i < apps.length; i++) apps[i].packageName: i,
      };

      const concurrency = 10;
      var nextIndex   = 0;
      var active      = 0;
      var pendingFlush = 0;
      Timer? flushTimer;
      final completer = Completer<void>();

      void flush() {
        flushTimer?.cancel();
        flushTimer = null;
        pendingFlush = 0;
        if (!mounted) return;
        setState(() => _installedApps = List.of(_installedApps));
      }

      void maybeComplete() {
        if (nextIndex >= apps.length && active == 0 && !completer.isCompleted) {
          completer.complete();
        }
      }

      void pump() {
        while (active < concurrency && nextIndex < apps.length) {
          final pkg = apps[nextIndex++].packageName;
          active++;
          InstalledApps.getAppInfo(pkg).then((info) {
            active--;
            if (info != null) {
              final idx = positionByPackage[pkg];
              if (idx != null) _installedApps[idx] = info;
              pendingFlush++;
              if (pendingFlush >= 4) {
                flush();
              } else {
                flushTimer ??= Timer(
                  const Duration(milliseconds: 120),
                  flush,
                );
              }
            }
            pump();
            maybeComplete();
          }).catchError((_) {
            active--;
            pump();
            maybeComplete();
          });
        }
      }

      pump();
      await completer.future;
      flushTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _installedApps = List.of(_installedApps);
        _iconsLoading  = false;
      });
      _InstalledAppsCache.apps = List.of(_installedApps);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appsLoading  = false;
        _iconsLoading = false;
      });
    }
  }

  // ── Estimation ──────────────────────────────────────────────────────────────
  ({int hours, int minutes})? _estimateRemaining() {
    if (_level == null || _state == null) return null;
    final charging = _state == BatteryState.charging;
    final relevant =
    _samples.where((s) => s.charging == charging).toList();
    if (relevant.length < 2) return null;

    final first          = relevant.first;
    final last           = relevant.last;
    final minutesElapsed = last.time.difference(first.time).inMinutes;
    if (minutesElapsed < 3) return null;

    final levelDelta    = last.level - first.level;
    final ratePerMinute = levelDelta / minutesElapsed;

    if (charging) {
      if (ratePerMinute <= 0) return null;
      final mins = ((100 - last.level) / ratePerMinute).round();
      return (hours: mins ~/ 60, minutes: mins % 60);
    } else {
      if (ratePerMinute >= 0) return null;
      final mins = (last.level / -ratePerMinute).round();
      return (hours: mins ~/ 60, minutes: mins % 60);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? _kBgDark : const Color(0xFFF5FFF5),
      bottomNavigationBar: const _BottomNav(currentIndex: -1),
      body: _level == null
          ? Center(
        child: CircularProgressIndicator(color: AppColors.success),
      )
          : RefreshIndicator(
        color: AppColors.success,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            _buildSliverHeader(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildMainCard(context),
                    const SizedBox(height: 16),
                    _buildAppsCard(context),
                    const SizedBox(height: 16),
                    _buildOptimizationCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver header ────────────────────────────────────────────────────────────
  Widget _buildSliverHeader(BuildContext context) {
    final isDark = context.isDark;

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
            colors: [Color(0xFF1A3D1A), Color(0xFF0F2A0F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Color(0xFFB8F0B8), Color(0xFFDFF7DF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 20,
          right: 20,
          bottom: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back button ──────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── Title row ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        T.of('batteryMonitor'),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        T.of('batteryMonitorSub'),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white70
                              : Colors.black.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                _BatteryIllustration(level: _level ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Main card ────────────────────────────────────────────────────────────────
  Widget _buildMainCard(BuildContext context) {
    final isDark     = context.isDark;
    final level      = _level ?? 0;
    final tempStr    = _details.temperatureCelsius != null
        ? '${_details.temperatureCelsius!.toStringAsFixed(1)}°C'
        : T.of('unavailable');
    final health     = _details.health ?? T.of('unavailable');
    final isCharging = _state == BatteryState.charging;
    final isFull     = _state == BatteryState.full || level >= 100;
    final estimate   = _estimateRemaining();

    // ── Determine time-label text ────────────────────────────────────────
    final String timeLabelText;
    if (isFull) {
      timeLabelText = T.of('batteryStatus');
    } else if (isCharging) {
      timeLabelText = T.of('estimatedTimeToFull');
    } else {
      timeLabelText = T.of('estimatedRemainingTime');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircularBatteryIndicator(
            level: level,
            health: _details.health,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Time label ──────────────────────────────────────────
                Text(
                  timeLabelText,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                // ── Status / time value ─────────────────────────────────
                if (isFull)
                  Text(
                    T.of('fullyCharged'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  )
                else if (estimate == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      T.of('calculating'),
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? Colors.white38
                            : Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                else
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.success),
                      children: [
                        TextSpan(
                          text: '${estimate.hours}${T.of('hourShort')} ',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '${estimate.minutes}${T.of('minuteShort')}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Sub-hint ────────────────────────────────────────────
                if (!isFull && estimate == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      T.of('calculatingHint'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white38
                            : Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                else if (!isFull)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      T.of('basedOnSession'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white38
                            : Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Stat chips ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatChip(
                      icon: Icons.thermostat_outlined,
                      label: T.of('temperature'),
                      value: tempStr,
                    ),
                    _StatChip(
                      icon: Icons.power_outlined,
                      label: T.of('status'),
                      value: _shortStateLabel(_state),
                    ),
                    _StatChip(
                      icon: Icons.favorite_outline,
                      label: T.of('health'),
                      value: health,
                      valueColor: _details.health == 'Good'
                          ? AppColors.success
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Installed apps card ──────────────────────────────────────────────────────
  Widget _buildAppsCard(BuildContext context) {
    final isDark = context.isDark;
    final apps   = _installedApps.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                T.of('installedApps'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.appManager),
                child: Text(
                  T.of('viewAll'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            T.of('installedAppsSub'),
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white54
                  : Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),

          // ── Body ──────────────────────────────────────────────────────
          if (_appsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.success,
                ),
              ),
            )
          else if (apps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                Platform.isAndroid
                    ? T.of('noAppsFound')
                    : T.of('unsupportedPlatform'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            )
          else
            ...apps.map((a) => _InstalledAppTile(app: a)),
        ],
      ),
    );
  }

  // ── Optimisation card ────────────────────────────────────────────────────────
  Widget _buildOptimizationCard(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_outlined, color: AppColors.success),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  T.of('batteryOptimization'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  T.of('batteryOptimizationSub'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              if (Platform.isAndroid) {
                AppSettings.openAppSettings(
                  type: AppSettingsType.batteryOptimization,
                );
              } else {
                AppSettings.openAppSettings();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            child: Text(
              T.of('reviewApps'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _shortStateLabel(BatteryState? state) => switch (state) {
    BatteryState.charging             => T.of('charging'),
    BatteryState.discharging          => T.of('notCharging'),
    BatteryState.full                 => T.of('full'),
    BatteryState.connectedNotCharging => T.of('connected'),
    _                                 => T.of('unknown'),
  };
}

// ─── SUB-WIDGETS ──────────────────────────────────────────────────────────────
Color _healthColor(String? health) => switch (health) {
  'Good' => AppColors.success,
  null   => Colors.black45,
  _      => const Color(0xFFFFA500),
};

// ─── BATTERY ILLUSTRATION ─────────────────────────────────────────────────────
class _BatteryIllustration extends StatelessWidget {
  final int level;
  const _BatteryIllustration({required this.level});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 90,
    height: 90,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
        const Icon(
          Icons.battery_charging_full_rounded,
          size: 52,
          color: AppColors.success,
        ),
      ],
    ),
  );
}

// ─── CIRCULAR BATTERY INDICATOR ───────────────────────────────────────────────
class _CircularBatteryIndicator extends StatelessWidget {
  final int     level;
  final String? health;
  const _CircularBatteryIndicator({required this.level, this.health});

  @override
  Widget build(BuildContext context) {
    final isDark       = context.isDark;
    final healthLabel  = health ?? '—';

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: level / 100,
              strokeWidth: 8,
              backgroundColor:
              isDark ? Colors.white12 : Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$level%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                healthLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: _healthColor(health),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── STAT CHIP ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white38 : Colors.black45,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ??
                (isDark ? Colors.white : const Color(0xFF1A1A1A)),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

// ─── INSTALLED APP TILE ───────────────────────────────────────────────────────
class _InstalledAppTile extends StatelessWidget {
  final AppInfo app;
  const _InstalledAppTile({required this.app});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => InstalledApps.openSettings(app.packageName),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: app.icon != null
                  ? Image.memory(
                app.icon!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 40,
                height: 40,
                color: AppColors.success.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.android_rounded,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    app.packageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}