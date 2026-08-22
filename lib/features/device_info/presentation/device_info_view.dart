// device_info_view.dart
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/services/device_memory_service.dart';
import '../../../core/services/storage_stats_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../battery_monitor/data/battery_details_service.dart';
import '../data/device_info_repository.dart';

// ─── DARK COLORS ──────────────────────────────────────────────────────────────
const _kBgDark   = Color(0xFF11151C);
const _kCardDark = Color(0xFF1B212C);

// ─── SHARED BOTTOM NAV ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

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
    3    => const Color(0xFF00C2A8),
    _    => const Color(0xFF2F6BFF),
  };
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class DeviceInfoView extends StatefulWidget {
  const DeviceInfoView({super.key});

  @override
  State<DeviceInfoView> createState() => _DeviceInfoViewState();
}

class _DeviceInfoViewState extends State<DeviceInfoView> {
  final _repository            = DeviceInfoRepository();
  final _memoryService         = DeviceMemoryService();
  final _batteryDetailsService = BatteryDetailsService();
  final _battery               = Battery();

  DeviceSpecs?   _specs;
  StorageStats?  _storage;
  DeviceMemory?  _memory;
  BatteryDetails _batteryDetails = BatteryDetails.unavailable;
  int?           _batteryPercent;
  String?        _error;
  int            _selectedTab = 0;

  // Section keys are translation-key strings so they stay stable.
  late final Map<String, bool> _expanded = {
    'sectionProcessor': true,
    'sectionMemory':    true,
    'sectionDisplay':   true,
    'sectionSoftware':  true,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final specs          = await _repository.getSpecs();
      final storage        = await getIt<StorageStatsService>().getStats();
      final memory         = await _memoryService.getMemory();
      final batteryDetails = await _batteryDetailsService.getDetails();
      int? batteryPercent;
      try {
        batteryPercent = await _battery.batteryLevel;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _specs          = specs;
        _storage        = storage;
        _memory         = memory;
        _batteryDetails = batteryDetails;
        _batteryPercent = batteryPercent;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '${T.of('failedToReadDeviceInfo')}: $e');
    }
  }

  // ── Computed condition label ───────────────────────────────────────────────
  String get _condition {
    if (_storage == null) return T.of('checkingDevice');
    if (_storage!.usedPercent >= 90) return T.of('storageAlmostFull');
    if (_storage!.usedPercent >= 75) return T.of('fairCondition');
    return T.of('goodCondition');
  }

  // ── Share report ──────────────────────────────────────────────────────────
  Future<void> _shareReport() async {
    final specs = _specs;
    if (specs == null) return;

    final buffer = StringBuffer()
      ..writeln(
          '${T.of('deviceReport')} — ${specs.manufacturer} ${specs.model}')
      ..writeln(
          'Android ${specs.androidRelease} (SDK ${specs.androidSdkInt})')
      ..writeln(
          '${T.of('cpu')}: ${specs.cpuCoreCount} ${T.of('cores')}, '
              '${specs.supportedAbis.isNotEmpty ? specs.supportedAbis.first : T.of('notAvailable')}')
      ..writeln(
          '${T.of('hardware')}: ${specs.hardware} / '
              '${T.of('board')} ${specs.board}');
    if (_memory != null) {
      buffer.writeln(
          '${T.of('ramLabel')}: '
              '${_memory!.availableGB.toStringAsFixed(1)} GB ${T.of('free')} '
              '${T.of('of')} ${_memory!.totalGB.toStringAsFixed(1)} GB');
    }
    if (_storage != null) {
      buffer.writeln(
          '${T.of('storage')}: '
              '${_storage!.usedGB.toStringAsFixed(1)} GB ${T.of('used')} '
              '${T.of('of')} ${_storage!.totalGB.toStringAsFixed(1)} GB');
    }
    if (_batteryPercent != null) {
      buffer.writeln(
          '${T.of('battery')}: $_batteryPercent%'
              '${_batteryDetails.health != null ? ' (${_batteryDetails.health})' : ''}');
    }
    if (specs.securityPatch != null) {
      buffer.writeln('${T.of('securityPatch')}: ${specs.securityPatch}');
    }
    if (specs.kernelVersion != null) {
      buffer.writeln('${T.of('kernel')}: ${specs.kernelVersion}');
    }
    buffer.writeln('${T.of('appVersion')}: ${specs.appVersion}');

    await SharePlus.instance.share(
      ShareParams(text: buffer.toString(), subject: T.of('deviceReport')),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? _kBgDark : const Color(0xFFF0F2F8),
      bottomNavigationBar: const _BottomNav(currentIndex: -1),
      body: _error != null
          ? Column(
        children: [
          _MinimalBackHeader(isDark: isDark),
          Expanded(
            child: Center(
              child: Text(
                _error!,
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ],
      )
          : _specs == null
          ? Column(
        children: [
          _MinimalBackHeader(isDark: isDark),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildQuickStats(context)),
            SliverToBoxAdapter(child: _buildTabBar(context)),
            SliverToBoxAdapter(child: _buildSections(context)),
            SliverToBoxAdapter(child: _buildReportBar(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final specs      = _specs!;
    final statusBarH = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4B6BFB), Color(0xFF6B8EFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, statusBarH + 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CircleIconBtn(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.dashboard),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      T.of('deviceInfoTitle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      T.of('deviceInfoSub'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _CircleIconBtn(
                  icon: Icons.ios_share_outlined, onTap: _shareReport),
            ],
          ),
          const SizedBox(height: 24),
          // ── Device card ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        T.of('yourDevice'),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      specs.model,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      specs.manufacturer,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_outlined,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 5),
                          Text(
                            _condition,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ChipWidget(
                  coreCount: specs.cpuCoreCount,
                  hardware:  specs.hardware),
            ],
          ),
        ],
      ),
    );
  }

  // ── QUICK STATS ───────────────────────────────────────────────────────────
  Widget _buildQuickStats(BuildContext context) {
    final isDark = context.isDark;

    final tiles = [
      _StatTileData(
        icon:      Icons.memory_rounded,
        iconBg:    isDark ? const Color(0xFF1E2A3A) : const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF4B6BFB),
        title:     T.of('ramLabel'),
        value:     _memory != null
            ? '${_memory!.totalGB.toStringAsFixed(0)} GB'
            : T.of('notAvailable'),
        sub: _memory != null
            ? '${_memory!.availableGB.toStringAsFixed(1)} GB ${T.of('available')}'
            : T.of('needsNativeSetup'),
      ),
      _StatTileData(
        icon:      Icons.storage_rounded,
        iconBg:    isDark ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        title:     T.of('storage'),
        value:     _storage != null
            ? '${_storage!.totalGB.toStringAsFixed(0)} GB'
            : T.of('notAvailable'),
        sub: _storage != null
            ? '${_storage!.freeGB.toStringAsFixed(1)} GB ${T.of('available')}'
            : '',
      ),
      _StatTileData(
        icon:      Icons.android_rounded,
        iconBg:    isDark ? const Color(0xFF2A1A2E) : const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF8E24AA),
        title:     'Android',
        value:     _specs!.androidRelease,
        sub:       'SDK ${_specs!.androidSdkInt}',
      ),
      _StatTileData(
        icon:      Icons.battery_charging_full_rounded,
        iconBg:    isDark ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        title:     T.of('battery'),
        value:     _batteryPercent != null
            ? '$_batteryPercent%'
            : T.of('notAvailable'),
        sub: _batteryDetails.health ?? '',
      ),
    ];

    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color:        isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow:    isDark ? [] : _shadow(),
      ),
      child: Row(
        children: tiles
            .map((t) => Expanded(child: _StatTile(data: t)))
            .toList(),
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────────────────────
  Widget _buildTabBar(BuildContext context) {
    final isDark = context.isDark;

    final tabs = [
      (Icons.grid_view_rounded,           T.of('tabOverview')),
      (Icons.format_list_bulleted_rounded, T.of('tabDetailedSpecs')),
      (Icons.info_outline_rounded,         T.of('tabAboutDevice')),
    ];

    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:        isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:    isDark ? [] : _shadow(),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF4B6BFB)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabs[i].$1,
                      size: 14,
                      color: selected
                          ? Colors.white
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        tabs[i].$2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : (isDark
                              ? Colors.white54
                              : Colors.black45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── SECTIONS ──────────────────────────────────────────────────────────────
  Widget _buildSections(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: switch (_selectedTab) {
        0 => _overviewSections(context),
        1 => _detailedSpecsSections(context),
        _ => _aboutDeviceSection(context),
      },
    );
  }

  // ── Overview tab ──────────────────────────────────────────────────────────
  Widget _overviewSections(BuildContext context) {
    final isDark = context.isDark;
    final specs  = _specs!;

    return Column(
      children: [
        _Section(
          icon:       Icons.developer_board_rounded,
          iconBg:     isDark
              ? const Color(0xFF2A1F3D)
              : const Color(0xFFEDE7F6),
          iconColor:  const Color(0xFF7C4DFF),
          title:      T.of('sectionProcessor'),
          isExpanded: _expanded['sectionProcessor']!,
          onToggle:   () => setState(() => _expanded['sectionProcessor'] =
          !_expanded['sectionProcessor']!),
          rows: [
            _SpecRow(
              T.of('cores'),
              '${specs.cpuCoreCount} ${T.of('cores')}',
              T.of('architecture'),
              specs.supportedAbis.isNotEmpty
                  ? specs.supportedAbis.first
                  : T.of('notAvailable'),
            ),
            _SpecRow(
              T.of('hardware'),
              specs.hardware,
              T.of('board'),
              specs.board,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          icon:       Icons.memory_rounded,
          iconBg:     isDark
              ? const Color(0xFF2A1F3D)
              : const Color(0xFFEDE7F6),
          iconColor:  const Color(0xFF7C4DFF),
          title:      T.of('sectionMemory'),
          isExpanded: _expanded['sectionMemory']!,
          onToggle:   () => setState(() =>
          _expanded['sectionMemory'] = !_expanded['sectionMemory']!),
          rows: [
            if (_memory != null)
              _SpecRow(
                T.of('totalRam'),
                '${_memory!.totalGB.toStringAsFixed(1)} GB',
                T.of('available'),
                '${_memory!.availableGB.toStringAsFixed(1)} GB',
              )
            else
              _SpecRow(
                T.of('totalRam'),
                T.of('notAvailable'),
                T.of('available'),
                T.of('notAvailable'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          icon:       Icons.code_rounded,
          iconBg:     isDark
              ? const Color(0xFF1A2E1A)
              : const Color(0xFFE8F5E9),
          iconColor:  const Color(0xFF2E7D32),
          title:      T.of('sectionSoftware'),
          isExpanded: _expanded['sectionSoftware']!,
          onToggle:   () => setState(() => _expanded['sectionSoftware'] =
          !_expanded['sectionSoftware']!),
          rows: [
            _SpecRow(
              T.of('androidVersion'),
              specs.androidRelease,
              T.of('sdkLevel'),
              '${specs.androidSdkInt}',
            ),
            _SpecRow(
              T.of('securityPatch'),
              specs.securityPatch ?? T.of('notAvailable'),
              T.of('physicalDevice'),
              specs.isPhysicalDevice
                  ? T.of('yes')
                  : T.of('noEmulator'),
            ),
          ],
        ),
      ],
    );
  }

  // ── Detailed specs tab ────────────────────────────────────────────────────
  Widget _detailedSpecsSections(BuildContext context) {
    final isDark      = context.isDark;
    final view        = View.of(context);
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    final refreshRate = view.display.refreshRate;

    return Column(
      children: [
        _Section(
          icon:       Icons.smartphone_rounded,
          iconBg:     isDark
              ? const Color(0xFF1A2A3D)
              : const Color(0xFFE3F2FD),
          iconColor:  const Color(0xFF1E88E5),
          title:      T.of('sectionDisplay'),
          isExpanded: _expanded['sectionDisplay']!,
          onToggle:   () => setState(() =>
          _expanded['sectionDisplay'] = !_expanded['sectionDisplay']!),
          rows: [
            _SpecRow(
              T.of('logicalSize'),
              '${logicalSize.width.toStringAsFixed(0)}'
                  '×${logicalSize.height.toStringAsFixed(0)} dp',
              T.of('physicalResolution'),
              '${view.physicalSize.width.toStringAsFixed(0)}'
                  '×${view.physicalSize.height.toStringAsFixed(0)} px',
            ),
            _SpecRow(
              T.of('pixelRatio'),
              '${view.devicePixelRatio.toStringAsFixed(2)}×',
              T.of('refreshRate'),
              refreshRate > 0
                  ? '${refreshRate.toStringAsFixed(0)} Hz'
                  : T.of('notAvailable'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          icon:       Icons.developer_board_rounded,
          iconBg:     isDark
              ? const Color(0xFF2A1F3D)
              : const Color(0xFFEDE7F6),
          iconColor:  const Color(0xFF7C4DFF),
          title:      T.of('sectionHardware'),
          isExpanded: true,
          onToggle:   () {},
          rows: [
            _SpecRow(
              T.of('manufacturer'),
              _specs!.manufacturer,
              T.of('model'),
              _specs!.model,
            ),
            _SpecRow(
              T.of('board'),
              _specs!.board,
              T.of('hardware'),
              _specs!.hardware,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          icon:       Icons.terminal_rounded,
          iconBg:     isDark
              ? const Color(0xFF2E1A0A)
              : const Color(0xFFFFF3E0),
          iconColor:  const Color(0xFFE65100),
          title:      T.of('sectionKernel'),
          isExpanded: true,
          onToggle:   () {},
          rows: [
            _SpecRow(
              T.of('kernelVersion'),
              _specs!.kernelVersion ?? T.of('notAvailable'),
              T.of('supportedAbis'),
              _specs!.supportedAbis.isNotEmpty
                  ? _specs!.supportedAbis.join(', ')
                  : T.of('notAvailable'),
            ),
          ],
        ),
      ],
    );
  }

  // ── About device tab ──────────────────────────────────────────────────────
  Widget _aboutDeviceSection(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      children: [
        _Section(
          icon:       Icons.info_outline_rounded,
          iconBg:     isDark
              ? const Color(0xFF1A2A3D)
              : const Color(0xFFE3F2FD),
          iconColor:  const Color(0xFF1E88E5),
          title:      T.of('sectionApp'),
          isExpanded: true,
          onToggle:   () {},
          rows: [
            _SpecRow(T.of('appVersion'), _specs!.appVersion, '', ''),
          ],
        ),
      ],
    );
  }

  // ── REPORT BAR ────────────────────────────────────────────────────────────
  Widget _buildReportBar(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color:        isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow:    isDark ? [] : _shadow(),
      ),
      child: TextButton.icon(
        onPressed: _shareReport,
        icon:  const Icon(Icons.share_outlined, size: 18),
        label: Text(
          T.of('shareDeviceReport'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4B6BFB),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  List<BoxShadow> _shadow() => [
    BoxShadow(
      color:      Colors.black.withValues(alpha: 0.07),
      blurRadius: 14,
      offset:     const Offset(0, 4),
    ),
  ];
}

// ── STAT TILE DATA ────────────────────────────────────────────────────────────
class _StatTileData {
  final IconData icon;
  final Color    iconBg;
  final Color    iconColor;
  final String   title;
  final String   value;
  final String   sub;

  const _StatTileData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.sub,
  });
}

class _StatTile extends StatelessWidget {
  final _StatTileData data;
  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      children: [
        Container(
          width:  46,
          height: 46,
          decoration: BoxDecoration(
            color:        data.iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(data.icon, color: data.iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          data.title,
          style: TextStyle(
            fontSize:   11,
            color:      isDark ? Colors.white54 : const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          data.value,
          style: TextStyle(
            fontSize:   14,
            fontWeight: FontWeight.bold,
            color:      isDark ? Colors.white : const Color(0xFF1C1E21),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          data.sub,
          style: TextStyle(
            fontSize: 9.5,
            color:    isDark ? Colors.white38 : const Color(0xFF9AA0AC),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── EXPANDABLE SECTION ────────────────────────────────────────────────────────
class _SpecRow {
  final String label1, value1, label2, value2;
  const _SpecRow(this.label1, this.value1, this.label2, this.value2);
}

class _Section extends StatelessWidget {
  final IconData       icon;
  final Color          iconBg;
  final Color          iconColor;
  final String         title;
  final bool           isExpanded;
  final VoidCallback   onToggle;
  final List<_SpecRow> rows;

  const _Section({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color:        isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width:  38,
                      height: 38,
                      decoration: BoxDecoration(
                        color:        iconBg,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size:  22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                Divider(
                  height:    1,
                  color:     isDark ? Colors.white12 : Colors.grey.shade100,
                  indent:    16,
                  endIndent: 16,
                ),
                for (var i = 0; i < rows.length; i++)
                  _SpecRowTile(row: rows[i], isLast: i == rows.length - 1),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SpecRowTile extends StatelessWidget {
  final _SpecRow row;
  final bool     isLast;
  const _SpecRowTile({required this.row, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Cell(label: row.label1, value: row.value1)),
              if (row.label2.isNotEmpty)
                Expanded(child: _Cell(label: row.label2, value: row.value2)),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height:    1,
            color:     isDark ? Colors.white12 : Colors.grey.shade100,
            indent:    16,
            endIndent: 16,
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  const _Cell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark        = context.isDark;
    final display       = value.trim().isEmpty ? '—' : value;
    final isPlaceholder =
        display == '—' || display == T.of('notAvailable');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize:    10.5,
            color:       isDark ? Colors.white38 : const Color(0xFF9AA0AC),
            fontWeight:  FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          display,
          style: TextStyle(
            fontSize:   14,
            fontWeight: FontWeight.w700,
            color: isPlaceholder
                ? (isDark ? Colors.white24 : const Color(0xFFB0B4BB))
                : (isDark ? Colors.white : const Color(0xFF1C1E21)),
            fontStyle:
            isPlaceholder ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}

// ── CIRCLE ICON BUTTON ────────────────────────────────────────────────────────
// ── Minimal header with just a back button, shown while loading/error ──────
class _MinimalBackHeader extends StatelessWidget {
  final bool isDark;
  const _MinimalBackHeader({required this.isDark});

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.dashboard),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CircleIconBtn extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  const _CircleIconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width:  38,
      height: 38,
      decoration: BoxDecoration(
        color:  Colors.white.withValues(alpha: 0.22),
        shape:  BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    ),
  );
}

// ── CHIP WIDGET (CPU illustration) ────────────────────────────────────────────
class _ChipWidget extends StatelessWidget {
  final int    coreCount;
  final String hardware;
  const _ChipWidget({required this.coreCount, required this.hardware});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width:  130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width:  105,
            height: 105,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A8F), Color(0xFF2255CC)],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset:     const Offset(4, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$coreCount',
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   30,
                      fontWeight: FontWeight.bold,
                      height:     1.0,
                    ),
                  ),
                  Text(
                    T.of('cpuCores'),
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hardware,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:    Colors.white.withValues(alpha: 0.75),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ..._pins(top: true),
          ..._pins(top: false),
        ],
      ),
    );
  }

  List<Widget> _pins({required bool top}) {
    return List.generate(4, (i) {
      final left = 18.0 + i * 22.0;
      return Positioned(
        top:    top ? 4 : null,
        bottom: top ? null : 4,
        left:   left,
        child: Container(
          width:  8,
          height: 10,
          decoration: BoxDecoration(
            color:        Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    });
  }
}