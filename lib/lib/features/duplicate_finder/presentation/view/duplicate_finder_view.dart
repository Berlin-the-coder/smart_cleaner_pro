// duplicate_finder_view.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

import '../../../../core/router/app_router.dart';
import '../../../../core/services/file_scan_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/format_utils.dart';
import '../../domain/duplicate_finder_state.dart';
import '../viewmodel/duplicate_finder_viewmodel.dart';

const _kBgDark   = Color(0xFF11151C);
const _kCardDark = Color(0xFF1B212C);

// ─── SHARED BOTTOM NAV ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0: context.go(AppRoutes.dashboard);      break;
      case 1: context.go(AppRoutes.fileManager);    break;
      case 2: context.go(AppRoutes.appManager);     break;
      case 3: context.go(AppRoutes.batteryMonitor); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark        = context.isDark;
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;

    final items = [
      (icon: Icons.home_outlined,        selectedIcon: Icons.home_rounded,         label: T.of('home')),
      (icon: Icons.folder_outlined,      selectedIcon: Icons.folder_rounded,       label: T.of('files')),
      (icon: Icons.grid_view_outlined,   selectedIcon: Icons.grid_view_rounded,    label: T.of('apps')),
      (icon: Icons.battery_std_outlined, selectedIcon: Icons.battery_full_rounded, label: T.of('battery')),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? _kCardDark : Colors.white,
          boxShadow: isDark
              ? []
              : [BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -3),
          )],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item     = items[index];
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
                      item.label,
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
  }

  Color _activeColor(int index) {
    switch (index) {
      case 1:  return const Color(0xFF2F6BFF);
      case 2:  return const Color(0xFF6C63FF);
      case 3:  return const Color(0xFF00C2A8);
      default: return const Color(0xFF2F6BFF);
    }
  }
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class DuplicateFinderView extends ConsumerWidget {
  const DuplicateFinderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state     = ref.watch(duplicateFinderViewModelProvider);
    final viewModel = ref.read(duplicateFinderViewModelProvider.notifier);
    final isDark    = context.isDark;

    final atTypePicker    = state is DuplicateFinderTypePicker;
    final hasCustomHeader = state is DuplicateFinderTypePicker ||
        state is DuplicateFinderScanned ||
        state is DuplicateFinderScanning ||
        state is DuplicateFinderDeleting;

    return PopScope(
      canPop: atTypePicker,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) viewModel.reset();
      },
      child: Scaffold(
        backgroundColor: isDark ? _kBgDark : AppColors.surfaceLight,
        bottomNavigationBar: (atTypePicker || state is DuplicateFinderScanned)
            ? const _BottomNav(currentIndex: 1)
            : null,
        appBar: hasCustomHeader
            ? null
            : AppBar(title: Text(T.of('duplicateFinder'))),
        body: state.when(
          typePicker: () => Column(
            children: [
              const _DuplicateHeader(),
              Expanded(
                child: _TypePickerView(
                  onScanType: (type) => viewModel.startScan(onlyType: type),
                  onScanAll: () => viewModel.startScan(),
                ),
              ),
            ],
          ),
          permissionRequired: () =>
              _PermissionView(onRetry: viewModel.retryPermission),
          scanning: () => _ProcessingView(
            title: T.of('scanning4Dups'),
            subtitle: T.of('scanningMoment'),
          ),
          scanned: (groups) => Column(
            children: [
              const _ResultsHeader(),
              Expanded(
                child: _ScannedView(
                  groups: groups,
                  onToggle: viewModel.toggleFile,
                  onDelete: () => _confirmAndDelete(context, ref, groups),
                  onReview: (group) => _showReviewSheet(context, ref, group),
                ),
              ),
            ],
          ),
          deleting: () => _ProcessingView(
            title: T.of('cleaningDups'),
            subtitle: T.of('removingDups'),
          ),
          deleted: (deleted, freed) => _DeletedView(
            filesDeleted: deleted,
            bytesFreed: freed,
            onDone: viewModel.reset,
          ),
          error: (message) =>
              _ErrorView(message: message, onRetry: viewModel.reset),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(
      BuildContext context,
      WidgetRef ref,
      List<DuplicateGroup> groups,
      ) async {
    final isDark        = context.isDark;
    final selectedBytes = groups.fold<int>(0, (s, g) => s + g.selectedBytes);
    final selectedCount = groups.fold<int>(0, (s, g) => s + g.selectedPaths.length);
    if (selectedCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? _kCardDark : Colors.white,
        title: Text(
          T.of('deleteJunkFiles'),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          '${T.of('deleteJunkDesc')} $selectedCount ${T.of('duplicatesLabel')} '
              '${T.of('andFreeUp')} ${FormatUtils.formatBytes(selectedBytes)}. '
              '${T.of('newestKeptNote')} ${T.of('cannotBeUndone')}',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(T.of('cancel'),
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(T.of('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(duplicateFinderViewModelProvider.notifier)
          .deleteSelected();
    }
  }
}

// ─── DUPLICATE HEADER ─────────────────────────────────────────────────────────
class _DuplicateHeader extends StatelessWidget {
  const _DuplicateHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9B7CF7), Color(0xFF7C5CFC)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 14),
          Text(
            T.of('duplicates'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            T.of('findDuplicates'),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── TYPE PICKER ──────────────────────────────────────────────────────────────
class _TypePickerView extends StatelessWidget {
  final void Function(DuplicateMediaType type) onScanType;
  final VoidCallback onScanAll;

  const _TypePickerView(
      {required this.onScanType, required this.onScanAll});

  IconData _iconFor(DuplicateMediaType type) => switch (type) {
    DuplicateMediaType.images    => Icons.image_rounded,
    DuplicateMediaType.videos    => Icons.videocam_rounded,
    DuplicateMediaType.audio     => Icons.music_note_rounded,
    DuplicateMediaType.documents => Icons.description_rounded,
  };

  String _subtitleFor(DuplicateMediaType type) => switch (type) {
    DuplicateMediaType.images    => T.of('photos'),
    DuplicateMediaType.videos    => T.of('clips'),
    DuplicateMediaType.audio     => T.of('musicVoice'),
    DuplicateMediaType.documents => T.of('pdfsDocs'),
  };

  List<Color> _gradientFor(DuplicateMediaType type) => switch (type) {
    DuplicateMediaType.images =>
    const [Color(0xFF8B5CF6), Color(0xFFB794F6)],
    DuplicateMediaType.videos =>
    const [Color(0xFFEC4899), Color(0xFFFFA1C4)],
    DuplicateMediaType.audio =>
    const [Color(0xFF3B82F6), Color(0xFF7DAEFF)],
    DuplicateMediaType.documents =>
    const [Color(0xFF14B8A6), Color(0xFF6EE7D6)],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text(
          T.of('scanByType'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          T.of('pickCategory'),
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey.shade600,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            for (final type in DuplicateMediaType.values)
              _TypeCard(
                icon: _iconFor(type),
                gradientColors: _gradientFor(type),
                label: type.label.replaceFirst('Duplicate ', ''),
                subtitle: _subtitleFor(type),
                onTap: () => onScanType(type),
              ),
          ],
        ),
        const SizedBox(height: 20),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onScanAll,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9B7CF7), Color(0xFF6D3FE0)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.folder_copy_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        T.of('scanAllFiles'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        T.of('checkEveryCategory'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── TYPE CARD ────────────────────────────────────────────────────────────────
class _TypeCard extends StatelessWidget {
  final IconData     icon;
  final List<Color>  gradientColors;
  final String       label;
  final String       subtitle;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.gradientColors,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.85)),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PERMISSION VIEW ──────────────────────────────────────────────────────────
class _PermissionView extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined,
                size: 72,
                color: isDark ? Colors.white38 : Colors.grey),
            const SizedBox(height: 16),
            Text(
              T.of('permissionDesc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: Text(T.of('grantAccess')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROCESSING VIEW ──────────────────────────────────────────────────────────
class _ProcessingView extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ProcessingView(
      {required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B7CF7), Color(0xFF6D3FE0)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _PulsingIcon(),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon();

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
            scale: 1 + (_controller.value * 0.12), child: child);
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.image_search_rounded,
          color: Colors.white,
          size: 46,
        ),
      ),
    );
  }
}

// ─── RESULTS HEADER ───────────────────────────────────────────────────────────
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1530), Color(0xFF191520)],
        )
            : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEDE7FB), Color(0xFFF7F5FC)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -10,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF8E5CF7).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 34,
            right: 14,
            child: Icon(
              Icons.image_search_rounded,
              size: 60,
              color: const Color(0xFF8E5CF7)
                  .withValues(alpha: isDark ? 0.2 : 0.35),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                T.of('duplicates'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                T.of('findDuplicates'),
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData      icon;
  final VoidCallback? onTap;
  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Material(
      color: isDark ? Colors.white12 : Colors.white,
      shape: const CircleBorder(),
      elevation: isDark ? 0 : 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon,
              size: 20,
              color: isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

// ─── SIZE BUCKET ──────────────────────────────────────────────────────────────
enum _SizeBucket { all, large, medium, small }

// ─── SCANNED VIEW ─────────────────────────────────────────────────────────────
class _ScannedView extends StatefulWidget {
  final List<DuplicateGroup>      groups;
  final void Function(String, String) onToggle;
  final VoidCallback              onDelete;
  final void Function(DuplicateGroup) onReview;

  const _ScannedView({
    required this.groups,
    required this.onToggle,
    required this.onDelete,
    required this.onReview,
  });

  @override
  State<_ScannedView> createState() => _ScannedViewState();
}

class _ScannedViewState extends State<_ScannedView> {
  DuplicateMediaType? _selectedType;
  _SizeBucket         _bucket = _SizeBucket.all;

  bool _matchesBucket(DuplicateGroup g) {
    final size = g.files.isEmpty ? 0 : g.files.first.sizeBytes;
    switch (_bucket) {
      case _SizeBucket.all:    return true;
      case _SizeBucket.large:  return size > 10 * 1024 * 1024;
      case _SizeBucket.medium: return size >= 1024 * 1024 && size <= 10 * 1024 * 1024;
      case _SizeBucket.small:  return size < 1024 * 1024;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark        = context.isDark;
    final groups        = widget.groups;
    final selectedBytes =
    groups.fold<int>(0, (sum, g) => sum + g.selectedBytes);

    // ── Empty state ──
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: AppColors.success,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                T.of('noDuplicates'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                T.of('allSetClean'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final byType = <DuplicateMediaType, List<DuplicateGroup>>{};
    for (final g in groups) {
      byType.putIfAbsent(g.type, () => []).add(g);
    }

    final bytesByType = <DuplicateMediaType, int>{
      for (final entry in byType.entries)
        entry.key: entry.value.fold<int>(
          0,
              (sum, g) => sum + g.files.first.sizeBytes * (g.files.length - 1),
        ),
    };
    final totalRecoverable =
    bytesByType.values.fold<int>(0, (a, b) => a + b);

    final filtered = groups
        .where((g) => _selectedType == null || g.type == _selectedType)
        .where(_matchesBucket)
        .toList()
      ..sort((a, b) {
        final sA = a.files.first.sizeBytes * (a.files.length - 1);
        final sB = b.files.first.sizeBytes * (b.files.length - 1);
        return sB.compareTo(sA);
      });

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              _SummaryCard(
                totalRecoverable: totalRecoverable,
                bytesByType: bytesByType,
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Duplicate type label ──
                  Text(
                    T.of('duplicateType'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: byType.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final type     = byType.keys.elementAt(index);
                        final isSelected = _selectedType == type;
                        return _TypeFilterChip(
                          type: type,
                          totalBytes: bytesByType[type] ?? 0,
                          groupCount: byType[type]!.length,
                          selected: isSelected,
                          onTap: () => setState(() =>
                          _selectedType =
                          isSelected ? null : type),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  // ── Duplicate groups label ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        T.of('duplicateGroups'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${filtered.length} ${T.of('groups')}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ── Size bucket chips ──
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _SizeBucketChip(
                          label: T.of('sizeBucketAll'),
                          selected: _bucket == _SizeBucket.all,
                          onTap: () =>
                              setState(() => _bucket = _SizeBucket.all),
                        ),
                        const SizedBox(width: 8),
                        _SizeBucketChip(
                          label: T.of('sizeBucketLarge'),
                          selected: _bucket == _SizeBucket.large,
                          onTap: () =>
                              setState(() => _bucket = _SizeBucket.large),
                        ),
                        const SizedBox(width: 8),
                        _SizeBucketChip(
                          label: T.of('sizeBucketMedium'),
                          selected: _bucket == _SizeBucket.medium,
                          onTap: () =>
                              setState(() => _bucket = _SizeBucket.medium),
                        ),
                        const SizedBox(width: 8),
                        _SizeBucketChip(
                          label: T.of('sizeBucketSmall'),
                          selected: _bucket == _SizeBucket.small,
                          onTap: () =>
                              setState(() => _bucket = _SizeBucket.small),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          T.of('noGroupsInFilter'),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final group in filtered)
                      _DuplicateGroupCard(
                        group: group,
                        onReview: () => widget.onReview(group),
                      ),
                ],
              ),
            ],
          ),
        ),

        // ── Bottom action bar ──
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: isDark ? _kCardDark : Colors.white,
              boxShadow: isDark
                  ? []
                  : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E5CF7)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFF8E5CF7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        T.of('youCanFreeUp'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? Colors.white54
                              : Colors.black54,
                        ),
                      ),
                      Text(
                        FormatUtils.formatBytes(selectedBytes),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8E5CF7),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed:
                  selectedBytes > 0 ? widget.onDelete : null,
                  child: Text(
                    T.of('reviewAndClean'),
                    style:
                    const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── SIZE BUCKET CHIP ─────────────────────────────────────────────────────────
class _SizeBucketChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  const _SizeBucketChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF8E5CF7)
              : (isDark ? _kCardDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF8E5CF7)
                : (isDark ? Colors.white12 : Colors.grey.shade200),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}

// ─── TYPE COLORS ──────────────────────────────────────────────────────────────
const _typeColors = {
  DuplicateMediaType.images:    Color(0xFF8B5CF6),
  DuplicateMediaType.videos:    Color(0xFFEC4899),
  DuplicateMediaType.audio:     Color(0xFF3B82F6),
  DuplicateMediaType.documents: Color(0xFF14B8A6),
};

// ─── SUMMARY CARD ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int                          totalRecoverable;
  final Map<DuplicateMediaType, int> bytesByType;

  const _SummaryCard({
    required this.totalRecoverable,
    required this.bytesByType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark    = context.isDark;
    final formatted =
    FormatUtils.formatBytes(totalRecoverable).split(' ');
    final sortedTypes = bytesByType.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          T.of('totalDuplicateFiles'),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.info_outline_rounded,
                            size: 14,
                            color: isDark
                                ? Colors.white38
                                : Colors.black54),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: formatted.isNotEmpty
                                ? formatted[0]
                                : '0',
                            style: const TextStyle(
                              color: Color(0xFF6D3FE0),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: formatted.length > 1
                                ? ' ${formatted[1]}'
                                : '',
                            style: const TextStyle(
                              color: Color(0xFF6D3FE0),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      T.of('canBeRecovered'),
                      style: TextStyle(
                        color:
                        isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  size: const Size(90, 90),
                  painter: _DonutPainter(
                    bytesByType: bytesByType,
                    total: totalRecoverable,
                  ),
                ),
              ),
            ],
          ),
          if (sortedTypes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.grey.shade200),
            const SizedBox(height: 12),
            for (final entry in sortedTypes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _typeColors[entry.key],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key.label
                            .replaceFirst('Duplicate ', ''),
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      FormatUtils.formatBytes(entry.value),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                        isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── DONUT PAINTER ────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final Map<DuplicateMediaType, int> bytesByType;
  final int total;

  _DonutPainter({required this.bytesByType, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final rect =
    Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    var startAngle = -3.14159 / 2;
    final paint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap   = StrokeCap.butt;

    for (final entry in bytesByType.entries) {
      if (entry.value == 0) continue;
      final sweep = (entry.value / total) * 2 * 3.14159;
      paint.color = _typeColors[entry.key] ?? Colors.grey;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.bytesByType != bytesByType || old.total != total;
}

// ─── TYPE FILTER CHIP ─────────────────────────────────────────────────────────
class _TypeFilterChip extends StatelessWidget {
  final DuplicateMediaType type;
  final int                totalBytes;
  final int                groupCount;
  final bool               selected;
  final VoidCallback       onTap;

  const _TypeFilterChip({
    required this.type,
    required this.totalBytes,
    required this.groupCount,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon => switch (type) {
    DuplicateMediaType.images    => Icons.image_rounded,
    DuplicateMediaType.videos    => Icons.videocam_rounded,
    DuplicateMediaType.audio     => Icons.music_note_rounded,
    DuplicateMediaType.documents => Icons.description_rounded,
  };

  Color  get _color => _typeColors[type] ?? AppColors.primary;
  String get _label => type.label.replaceFirst('Duplicate ', '');

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 108,
        padding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? _kCardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _color
                : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (selected)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_icon, color: _color, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  _label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${FormatUtils.formatBytes(totalBytes)} • $groupCount ${T.of('groups')}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? Colors.white38
                        : Colors.grey.shade600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── THUMBNAIL HELPERS ────────────────────────────────────────────────────────
const _imageExtensions = {
  'jpg', 'jpeg', 'png', 'webp', 'heic', 'gif', 'bmp',
};
const _videoExtensions = {
  'mp4', 'mov', 'mkv', 'avi', '3gp', 'webm',
};
const _audioExtensions = {
  'mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg',
};

Widget _buildThumb(ScannedFile file,
    {double size = 56, Color? accentColor}) {
  final ext    = file.extension.replaceFirst('.', '').toLowerCase();
  final radius = BorderRadius.circular(12);

  if (_imageExtensions.contains(ext)) {
    return ClipRRect(
      borderRadius: radius,
      child: Image.file(
        File(file.path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackThumb(
          size,
          radius,
          Icons.image_rounded,
          accentColor ?? AppColors.primary,
        ),
      ),
    );
  }

  if (_videoExtensions.contains(ext)) {
    return _VideoThumb(
      path: file.path,
      size: size,
      accentColor:
      accentColor ?? _typeColors[DuplicateMediaType.videos]!,
    );
  }

  final icon = _audioExtensions.contains(ext)
      ? Icons.music_note_rounded
      : Icons.insert_drive_file_rounded;
  return _fallbackThumb(
      size, radius, icon, accentColor ?? Colors.blueGrey);
}

// ─── VIDEO META ───────────────────────────────────────────────────────────────
class _VideoMeta {
  final Uint8List? thumbnail;
  final Duration?  duration;
  const _VideoMeta({this.thumbnail, this.duration});
}

final Map<String, Future<_VideoMeta>> _videoMetaCache = {};

Future<_VideoMeta> _loadVideoMeta(String path) {
  return _videoMetaCache.putIfAbsent(path, () async {
    Uint8List? thumb;
    Duration?  duration;

    try {
      thumb = await vt.VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: vt.ImageFormat.JPEG,
        maxHeight: 240,
        quality: 70,
      );
    } catch (_) {}

    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      duration = controller.value.duration;
      await controller.dispose();
    } catch (_) {}

    return _VideoMeta(thumbnail: thumb, duration: duration);
  });
}

String _formatDuration(Duration d) {
  final hours   = d.inHours;
  final minutes =
  d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds =
  d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:$minutes:$seconds'
      : '$minutes:$seconds';
}

// ─── VIDEO THUMB ──────────────────────────────────────────────────────────────
class _VideoThumb extends StatelessWidget {
  final String path;
  final double size;
  final Color  accentColor;

  const _VideoThumb({
    required this.path,
    required this.size,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VideoMeta>(
      future: _loadVideoMeta(path),
      builder: (context, snapshot) {
        final meta     = snapshot.data;
        final thumb    = meta?.thumbnail;
        final duration = meta?.duration;

        return Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                Image.memory(thumb, fit: BoxFit.cover)
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor,
                        accentColor.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: size * 0.42,
                  shadows: const [
                    Shadow(color: Colors.black45, blurRadius: 6),
                  ],
                ),
              ),
              if (duration != null &&
                  duration.inMilliseconds > 0 &&
                  size >= 60)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _formatDuration(duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

Widget _fallbackThumb(
    double size, BorderRadius radius, IconData icon, Color color) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: radius,
    ),
    child: Icon(icon, color: color, size: 22),
  );
}

// ─── THUMBNAIL STACK ──────────────────────────────────────────────────────────
class _ThumbnailStack extends StatelessWidget {
  final List<ScannedFile> files;
  final Color             accentColor;
  const _ThumbnailStack(
      {required this.files, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    const size    = 52.0;
    const overlap = 14.0;
    final shown   = files.take(3).toList();
    final extra   = files.length - shown.length;

    return SizedBox(
      width: size + overlap * shown.length,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _buildThumb(shown[i],
                    size: size, accentColor: accentColor),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * overlap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── DUPLICATE GROUP CARD ─────────────────────────────────────────────────────
class _DuplicateGroupCard extends StatelessWidget {
  final DuplicateGroup group;
  final VoidCallback   onReview;

  const _DuplicateGroupCard({
    required this.group,
    required this.onReview,
  });

  String get _folderHint {
    final first = group.files.first.path;
    final parts = first.split('/');
    return parts.length >= 2 ? parts[parts.length - 2] : '';
  }

  IconData get _badgeIcon => switch (group.type) {
    DuplicateMediaType.images    => Icons.image_rounded,
    DuplicateMediaType.videos    => Icons.videocam_rounded,
    DuplicateMediaType.audio     => Icons.music_note_rounded,
    DuplicateMediaType.documents => Icons.description_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final isDark      = context.isDark;
    final recoverable =
        group.files.first.sizeBytes * (group.files.length - 1);
    final color       = _typeColors[group.type] ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _kCardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThumbnailStack(files: group.files, accentColor: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${group.files.length} ${T.of('similarFiles')} '
                      '${group.type.label.replaceFirst('Duplicate ', '').toLowerCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (_folderHint.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _folderHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white54
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(_badgeIcon,
                        size: 13, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      T.of('newestKept'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FormatUtils.formatBytes(recoverable),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  side: BorderSide(
                      color: color.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: onReview,
                child: Text(
                  T.of('review'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── REVIEW BOTTOM SHEET ──────────────────────────────────────────────────────
void _showReviewSheet(
    BuildContext context,
    WidgetRef ref,
    DuplicateGroup initialGroup,
    ) {
  final isDark = context.isDark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? _kCardDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius:
      BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, _) {
              final state  = ref.watch(duplicateFinderViewModelProvider);
              final groups = state.maybeWhen(
                scanned: (g) => g,
                orElse: () => const <DuplicateGroup>[],
              );
              final group = groups.firstWhere(
                    (g) => g.hash == initialGroup.hash,
                orElse: () => initialGroup,
              );
              final notifier = ref.read(
                  duplicateFinderViewModelProvider.notifier);
              final sorted = [...group.files]
                ..sort((a, b) => b.modified.compareTo(a.modified));
              final markedBytes = group.selectedBytes;
              final accentColor =
                  _typeColors[group.type] ?? AppColors.primary;

              return Padding(
                padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white24
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${group.files.length} ${T.of('similarFiles')}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                        isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      T.of('tapToMark'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? Colors.white54
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        itemCount: sorted.length,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemBuilder: (context, index) {
                          final file = sorted[index];
                          final marked = group.selectedPaths
                              .contains(file.path);
                          return GestureDetector(
                            onTap: () => notifier.toggleFile(
                                group.hash, file.path),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(
                                            14),
                                        child: _buildThumb(
                                          file,
                                          size: 200,
                                          accentColor: accentColor,
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(
                                                14),
                                            border: Border.all(
                                              color: marked
                                                  ? AppColors.danger
                                                  : AppColors.success,
                                              width: 2.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          padding:
                                          const EdgeInsets.all(
                                              3),
                                          decoration: BoxDecoration(
                                            color: marked
                                                ? AppColors.danger
                                                : AppColors.success,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            marked
                                                ? Icons.delete_rounded
                                                : Icons.check_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  FormatUtils.formatBytes(
                                      file.sizeBytes),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${T.of('markedForDeletion')}: '
                                '${FormatUtils.formatBytes(markedBytes)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF8E5CF7),
                          ),
                          onPressed: () =>
                              Navigator.of(context).pop(),
                          child: Text(T.of('done')),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

// ─── DELETED VIEW ─────────────────────────────────────────────────────────────
class _DeletedView extends StatelessWidget {
  final int          filesDeleted;
  final int          bytesFreed;
  final VoidCallback onDone;

  const _DeletedView({
    required this.filesDeleted,
    required this.bytesFreed,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 96, color: AppColors.success),
          const SizedBox(height: 16),
          Text(
            '${T.of('freed')} ${FormatUtils.formatBytes(bytesFreed)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            '$filesDeleted ${T.of('filesDeleted')}',
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onDone,
            child: Text(T.of('done')),
          ),
        ],
      ),
    );
  }
}

// ─── ERROR VIEW ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(T.of('retry')),
            ),
          ],
        ),
      ),
    );
  }
}