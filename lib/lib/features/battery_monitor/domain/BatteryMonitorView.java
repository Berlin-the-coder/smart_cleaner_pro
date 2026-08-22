import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../data/battery_details_service.dart';

class BatteryMonitorView extends StatefulWidget {
  const BatteryMonitorView({super.key});

  @override
  State<BatteryMonitorView> createState() => _BatteryMonitorViewState();
}

class _BatteryMonitorViewState extends State<BatteryMonitorView> {
  final _battery = Battery();
  final _detailsService = BatteryDetailsService();

  int? _level;
  BatteryState? _state;
  BatteryDetails _details = BatteryDetails.unavailable;
  int _selectedNavIndex = 3;

  @override
  void initState() {
    super.initState();
    _load();
    _battery.onBatteryStateChanged.listen((state) {
      if (mounted) setState(() => _state = state);
      _loadDetails();
    });
  }

  Future<void> _load() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    if (mounted) {
      setState(() {
        _level = level;
        _state = state;
      });
    }
    await _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await _detailsService.getDetails();
    if (mounted) setState(() => _details = details);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF5),
      body: _level == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
                          _buildUsageCard(context),
                          const SizedBox(height: 16),
                          _buildDrainingAppsCard(context),
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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildSliverHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Battery',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Monitor battery usage\nand extend battery life',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Action icons
            Column(
              children: [
                Row(
                  children: [
                    _HeaderIconButton(icon: Icons.help_outline),
                    const SizedBox(width: 8),
                    _HeaderIconButton(icon: Icons.settings_outlined),
                  ],
                ),
                const SizedBox(height: 12),
                // Battery illustration
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
    final level = _level ?? 0;
    final tempStr = _details.temperatureCelsius != null
        ? '${_details.temperatureCelsius!.toStringAsFixed(1)}°C'
        : 'N/A';
    final health = _details.health ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular indicator
          _CircularBatteryIndicator(level: level),
          const SizedBox(width: 20),
          // Right side
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated remaining time',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Rough time estimate based on level
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.success),
                    children: [
                      TextSpan(
                        text: '${(level * 0.082).toStringAsFixed(0)}h ',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '${((level * 0.082 % 1) * 60).toStringAsFixed(0)}m',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatChip(
                      icon: Icons.thermostat_outlined,
                      label: 'Temperature',
                      value: tempStr,
                    ),
                    _StatChip(
                      icon: Icons.power_outlined,
                      label: 'Status',
                      value: _shortStateLabel(_state),
                    ),
                    _StatChip(
                      icon: Icons.favorite_outline,
                      label: 'Health',
                      value: health,
                      valueColor: health == 'Good' ? AppColors.success : null,
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

  // ── Usage card ───────────────────────────────────────────────────────────────

  Widget _buildUsageCard(BuildContext context) {
    // Static illustrative data — replace with real UsageStats data if available
    final items = [
      _UsageItem(icon: Icons.smartphone_outlined, label: 'Screen', percent: 38),
      _UsageItem(icon: Icons.apps_outlined, label: 'Apps', percent: 31),
      _UsageItem(icon: Icons.settings_outlined, label: 'System', percent: 18),
      _UsageItem(icon: Icons.more_horiz, label: 'Other', percent: 13),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Battery usage',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  Text(
                    'Last 24 hours',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((e) => _UsageTile(item: e)).toList(),
          ),
        ],
      ),
    );
  }

  // ── Draining apps card ───────────────────────────────────────────────────────

  Widget _buildDrainingAppsCard(BuildContext context) {
    // Static illustrative data
    final apps = [
      _AppDrainItem(
        name: 'Instagram',
        detail: 'Used for 48m · Background 32m',
        percent: 14,
        color: const Color(0xFFE1306C),
        icon: Icons.camera_alt_outlined,
      ),
      _AppDrainItem(
        name: 'YouTube',
        detail: 'Used for 36m · Background 18m',
        percent: 9,
        color: const Color(0xFFFF0000),
        icon: Icons.play_circle_outline,
      ),
      _AppDrainItem(
        name: 'TikTok',
        detail: 'Used for 28m · Background 12m',
        percent: 7,
        color: Colors.black,
        icon: Icons.music_note_outlined,
      ),
      _AppDrainItem(
        name: 'Chrome',
        detail: 'Used for 20m · Background 9m',
        percent: 5,
        color: AppColors.success,
        icon: Icons.public_outlined,
      ),
      _AppDrainItem(
        name: 'WhatsApp',
        detail: 'Used for 15m · Background 28m',
        percent: 4,
        color: AppColors.success,
        icon: Icons.chat_bubble_outline,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Battery draining apps',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'View all',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...apps.map((a) => _AppDrainTile(item: a)),
        ],
      ),
    );
  }

  // ── Optimization card ────────────────────────────────────────────────────────

  Widget _buildOptimizationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Battery optimization',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Optimize settings to extend battery life',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Optimize now',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom navigation ────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Home'),
      (Icons.folder_outlined, 'Files'),
      (Icons.apps_outlined, 'Apps'),
      (Icons.battery_full_outlined, 'Battery'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == _selectedNavIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedNavIndex = i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].$1,
                      color: selected ? AppColors.success : Colors.black38,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? AppColors.success : Colors.black38,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  String _shortStateLabel(BatteryState? state) => switch (state) {
        BatteryState.charging => 'Charging',
        BatteryState.discharging => 'Not charging',
        BatteryState.full => 'Full',
        BatteryState.connectedNotCharging => 'Connected',
        _ => 'Unknown',
      };
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  const _HeaderIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: Colors.black54),
    );
  }
}

class _BatteryIllustration extends StatelessWidget {
  final int level;
  const _BatteryIllustration({required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.battery_charging_full_rounded,
            size: 52,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _CircularBatteryIndicator extends StatelessWidget {
  final int level;
  const _CircularBatteryIndicator({required this.level});

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: Colors.grey.shade100,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$level%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Text(
                'Good',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.black45),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black45),
        ),
      ],
    );
  }
}

// ── Usage ────────────────────────────────────────────────────────────────────

class _UsageItem {
  final IconData icon;
  final String label;
  final int percent;
  const _UsageItem({
    required this.icon,
    required this.label,
    required this.percent,
  });
}

class _UsageTile extends StatelessWidget {
  final _UsageItem item;
  const _UsageTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, color: AppColors.success, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          '${item.percent}%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: item.percent / 100,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Draining apps ────────────────────────────────────────────────────────────

class _AppDrainItem {
  final String name;
  final String detail;
  final int percent;
  final Color color;
  final IconData icon;

  const _AppDrainItem({
    required this.name,
    required this.detail,
    required this.percent,
    required this.color,
    required this.icon,
  });
}

class _AppDrainTile extends StatelessWidget {
  final _AppDrainItem item;
  const _AppDrainTile({required this.item});

  @override
  Widget build(BuildContext context) {
    // High drain = orange/red tint, low drain = green
    final percentColor = item.percent >= 10
        ? const Color(0xFFFF6B35)
        : item.percent >= 7
            ? const Color(0xFFFFA500)
            : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.detail,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          Text(
            '${item.percent}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: percentColor,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.black26, size: 18),
        ],
      ),
    );
  }
}