// lib/features/dashboard/presentation/widgets/quick_action_grid.dart
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/settings_notifier.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';

class _Action {
  final String   labelKey;
  final String   value;      // raw value (numbers/sizes — NOT translated)
  final String?  valueKey;   // optional: if value itself needs translation
  final IconData icon;
  final Color    color;
  final String   route;
  final bool     fullWidth;

  const _Action(
      this.labelKey,
      this.value,
      this.icon,
      this.color,
      this.route, {
        this.valueKey,
        this.fullWidth = false,
      });
}

// ─── GRID ─────────────────────────────────────────────────────────────────────
class QuickActionGrid extends StatefulWidget {
  final void Function(String route) onTap;
  final int? batteryPercent;
  final int? installedAppCount;

  const QuickActionGrid({
    super.key,
    required this.onTap,
    this.batteryPercent,
    this.installedAppCount,
  });

  @override
  State<QuickActionGrid> createState() => _QuickActionGridState();
}

class _QuickActionGridState extends State<QuickActionGrid> {
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

  List<_Action> _buildActions() => [
    const _Action('junk',       '1.8 GB',
        Icons.delete_sweep_rounded,
        AppColors.warning, AppRoutes.junkCleaner),
    const _Action('duplicates', '342 MB',
        Icons.copy_all_rounded,
        Color(0xFF8E5CF7), AppRoutes.duplicateFinder),
    const _Action('compressor', '24 items',
        Icons.photo_size_select_large_rounded,
        AppColors.secondary, AppRoutes.imageCompressor),
    const _Action('fileManager', '1,284 files',
        Icons.folder_rounded,
        AppColors.primary, AppRoutes.fileManager),
    _Action(
      'appManager',
      widget.installedAppCount != null
          ? '${widget.installedAppCount} ${T.of('apps')}'
          : '-- ${T.of('apps')}',
      Icons.grid_view_rounded,
      const Color(0xFF8E5CF7),
      AppRoutes.appManager,
    ),
    _Action(
      'battery',
      widget.batteryPercent != null
          ? '${widget.batteryPercent}%'
          : '--%',
      Icons.battery_full_rounded,
      AppColors.success,
      AppRoutes.batteryMonitor,
    ),
    const _Action(
      'deviceInfo',
      '',                      // empty — valueKey se aayega
      Icons.memory_rounded,
      AppColors.primary,
      AppRoutes.deviceInfo,
      valueKey:  'viewDeviceDetails',
      fullWidth: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final actions = _buildActions();
    final rows    = <Widget>[];
    var i = 0;

    while (i < actions.length) {
      final action = actions[i];
      if (action.fullWidth) {
        rows.add(_ActionCard(action: action, onTap: widget.onTap));
        i += 1;
      } else if (i + 1 < actions.length && !actions[i + 1].fullWidth) {
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _ActionCard(
                      action: actions[i], onTap: widget.onTap)),
              const SizedBox(width: 14),
              Expanded(
                  child: _ActionCard(
                      action: actions[i + 1], onTap: widget.onTap)),
            ],
          ),
        );
        i += 2;
      } else {
        rows.add(_ActionCard(action: action, onTap: widget.onTap));
        i += 1;
      }
      if (i < actions.length) rows.add(const SizedBox(height: 14));
    }

    return Column(children: rows);
  }
}

// ─── CARD ─────────────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final _Action               action;
  final void Function(String) onTap;

  const _ActionCard({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark       = context.isDark;
    final cardColor    = isDark ? AppColors.cardDark : Colors.white;
    final titleColor   = isDark ? Colors.white       : Colors.black87;
    final chevronColor = isDark
        ? Colors.white30
        : Colors.black.withValues(alpha: 0.30);
    final iconBgColor  =
    action.color.withValues(alpha: isDark ? 0.20 : 0.12);
    final shadowColor  = isDark
        ? Colors.transparent
        : Colors.black.withValues(alpha: 0.04);

    // Translated label
    final label        = T.of(action.labelKey);

    // Value: use valueKey if provided, else raw value
    final displayValue = action.valueKey != null
        ? T.of(action.valueKey!)
        : action.value;

    final subtitleColor = action.fullWidth
        ? (isDark
        ? Colors.white38
        : Colors.black.withValues(alpha: 0.45))
        : action.color;

    return Material(
      color:        cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onTap(action.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // ── Icon badge ───────────────────────────────────────────
              Container(
                width:     42,
                height:    42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:        iconBgColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(action.icon,
                    color: action.color, size: 21),
              ),
              const SizedBox(width: 10),

              // ── Label + value ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:       MainAxisSize.min,
                  children: [
                    // BUG FIX 1: softWrap true, no ellipsis overflow
                    // so long translated words wrap to next line
                    Text(
                      label,
                      softWrap:  true,
                      maxLines:  2,
                      overflow:  TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize:   13.5,
                        fontWeight: FontWeight.bold,
                        color:      titleColor,
                        height:     1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayValue,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Chevron ──────────────────────────────────────────────
              Icon(Icons.chevron_right_rounded,
                  color: chevronColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}