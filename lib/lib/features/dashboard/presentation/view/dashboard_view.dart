// lib/features/dashboard/presentation/view/dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/settings_notifier.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/dashboard_state.dart';
import '../viewmodel/dashboard_viewmodel.dart';
import '../widgets/quick_action_grid.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state     = ref.watch(dashboardViewModelProvider);
    final viewModel = ref.read(dashboardViewModelProvider.notifier);
    final isDark    = context.isDark;

    // ── Listen to SettingsNotifier so language/theme changes rebuild this ──
    final settings = getIt<SettingsNotifier>();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          body: RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(state: state)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // NOT const — must rebuild on language change
                        const _QuickCleanCard(),
                        const SizedBox(height: 20),
                        state.maybeWhen(
                          loaded: (total, used, free, usedPercent,
                              batteryPercent, installedAppCount) =>
                              QuickActionGrid(
                                onTap: (route) => context.push(route),
                                batteryPercent:    batteryPercent,
                                installedAppCount: installedAppCount,
                              ),
                          orElse: () => QuickActionGrid(
                            onTap: (route) => context.push(route),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const _BottomNav(currentIndex: 0),
        );
      },
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final DashboardState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark   = context.isDark;
    final settings = getIt<SettingsNotifier>();

    const darkHeaderGradient = LinearGradient(
      begin: Alignment.topLeft,
      end:   Alignment.bottomRight,
      colors: [Color(0xFF1A1F2E), Color(0xFF0F1923)],
    );

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          decoration: BoxDecoration(
            gradient: isDark
                ? darkHeaderGradient
                : AppColors.dashboardGradient,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32)),
            border: isDark
                ? Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    T.of('appName'),
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => context.push(AppRoutes.settings),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings_outlined,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // ── Subtitle ────────────────────────────────────────────────
              state.maybeWhen(
                loaded: (total, used, free, usedPercent,
                    batteryPercent, installedAppCount) =>
                    Text(
                      usedPercent < 75
                          ? T.of('deviceLookingGood')
                          : T.of('deviceNeedsClean'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 15),
                    ),
                orElse: () => Text(
                  T.of('checkingDevice'),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 15),
                ),
              ),
              const SizedBox(height: 28),

              // ── Storage row ──────────────────────────────────────────────
              state.when(
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                error: (message) => SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                loaded: (total, used, free, usedPercent,
                    batteryPercent, installedAppCount) =>
                    _StorageRow(
                      usedGB:      used,
                      totalGB:     total,
                      usedPercent: usedPercent,
                    ),
              ),
              const SizedBox(height: 20),

              // ── Info chips ───────────────────────────────────────────────
              state.maybeWhen(
                loaded: (total, used, free, usedPercent,
                    batteryPercent, installedAppCount) =>
                    _InfoChipsRow(
                      batteryPercent: batteryPercent,
                      usedPercent:    usedPercent,
                    ),
                orElse: () => const SizedBox(height: 86),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ─── STORAGE ROW ──────────────────────────────────────────────────────────────
class _StorageRow extends StatelessWidget {
  final double usedGB;
  final double totalGB;
  final double usedPercent;

  const _StorageRow({
    required this.usedGB,
    required this.totalGB,
    required this.usedPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                T.of('storage'),
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: usedGB.toStringAsFixed(1),
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text: ' GB / ',
                        style: TextStyle(
                            color: Colors.white, fontSize: 18),
                      ),
                      TextSpan(
                        text: '${totalGB.toStringAsFixed(0)} GB',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '${usedPercent.toStringAsFixed(0)}% ${T.of('used')}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        CircularPercentIndicator(
          radius:            55,
          lineWidth:         9,
          percent:           (usedPercent / 100).clamp(0.0, 1.0),
          animation:         true,
          animationDuration: 900,
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor:   Colors.white24,
          progressColor:     Colors.white,
          center: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storage_rounded,
                color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }
}

// ─── INFO CHIPS ROW ───────────────────────────────────────────────────────────
class _InfoChipsRow extends StatelessWidget {
  final int?   batteryPercent;
  final double usedPercent;

  const _InfoChipsRow({
    required this.batteryPercent,
    required this.usedPercent,
  });

  @override
  Widget build(BuildContext context) {
    final condition      = usedPercent < 75
        ? T.of('good')
        : T.of('fair');
    final conditionColor =
    usedPercent < 75 ? AppColors.success : AppColors.warning;

    return Row(
      children: [
        Expanded(
          child: _InfoChip(
            icon:      Icons.battery_charging_full_rounded,
            iconColor: Colors.white,
            value:     batteryPercent != null
                ? '$batteryPercent%'
                : '--',
            label: T.of('batteryLevel'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _InfoChip(
            icon:      Icons.gpp_good_rounded,
            iconColor: conditionColor,
            value:     condition,
            label:     T.of('deviceCondition'),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   value;
  final String   label;

  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width:     40,
            height:    40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:       MainAxisSize.min,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:    Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QUICK CLEAN CARD ─────────────────────────────────────────────────────────
// StatefulWidget so it can listen to SettingsNotifier and rebuild on language change
class _QuickCleanCard extends StatefulWidget {
  const _QuickCleanCard();

  @override
  State<_QuickCleanCard> createState() => _QuickCleanCardState();
}

class _QuickCleanCardState extends State<_QuickCleanCard> {
  late final SettingsNotifier _settings;

  @override
  void initState() {
    super.initState();
    _settings = getIt<SettingsNotifier>();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        )
            : null,
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  T.of('quickClean'),
                  style: TextStyle(
                    fontSize:   22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  T.of('quickCleanSub'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 14),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: '2.4 ',
                          style: TextStyle(
                            color:      AppColors.primary,
                            fontSize:   18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: T.of('gbAvailable'),
                          style: const TextStyle(
                            color:      AppColors.primary,
                            fontSize:   15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Icon(
                Icons.cleaning_services_rounded,
                size:  56,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 18),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.push(AppRoutes.junkCleaner),
                child: Container(
                  width:     44,
                  height:    44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── BOTTOM NAV ───────────────────────────────────────────────────────────────
class _BottomNav extends StatefulWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  State<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<_BottomNav> {
  late final SettingsNotifier _settings;

  @override
  void initState() {
    super.initState();
    _settings = getIt<SettingsNotifier>();
    _settings.addListener(_rebuild);
  }

  @override
  void dispose() {
    _settings.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  static const _icons = [
    (icon: Icons.home_outlined,        selectedIcon: Icons.home_rounded),
    (icon: Icons.folder_outlined,      selectedIcon: Icons.folder_rounded),
    (icon: Icons.grid_view_outlined,   selectedIcon: Icons.grid_view_rounded),
    (icon: Icons.battery_std_outlined, selectedIcon: Icons.battery_full_rounded),
  ];

  static const _labelKeys = ['home', 'files', 'apps', 'battery'];

  void _onTap(BuildContext context, int index) {
    if (index == widget.currentIndex) return;
    switch (index) {
      case 0: context.go(AppRoutes.dashboard);        break;
      case 1: context.push(AppRoutes.fileManager);    break;
      case 2: context.push(AppRoutes.appManager);     break;
      case 3: context.push(AppRoutes.batteryMonitor); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark        = context.isDark;
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;

    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset:     const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_icons.length, (index) {
            final item     = _icons[index];
            final selected = index == widget.currentIndex;
            final color    = selected ? AppColors.primary : inactiveColor;
            return Expanded(
              child: InkWell(
                onTap: () => _onTap(context, index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? item.selectedIcon : item.icon,
                      color: color,
                      size:  24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      T.of(_labelKeys[index]),
                      style: TextStyle(
                        color:      color,
                        fontSize:   12,
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
  }
}