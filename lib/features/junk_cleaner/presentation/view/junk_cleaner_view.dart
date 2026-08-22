// junk_cleaner_view.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/services/file_scan_service.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/junk_cleaner_state.dart';
import '../viewmodel/junk_cleaner_viewmodel.dart';

const _junkGradient = LinearGradient(
  colors: [Color(0xFFFF9D42), Color(0xFFFF7A3D)],
);

const _kOrange = Color(0xFFFF7A3D);

class _CategoryStyle {
  final IconData icon;
  final Color    color;
  const _CategoryStyle(this.icon, this.color);
}

const _categoryStyles = <JunkCategory, _CategoryStyle>{
  JunkCategory.cacheFiles:    _CategoryStyle(Icons.grid_view_rounded,         Color(0xFFFF7A3D)),
  JunkCategory.tempFiles:     _CategoryStyle(Icons.folder_rounded,            Color(0xFFFFC24B)),
  JunkCategory.residualFiles: _CategoryStyle(Icons.description_rounded,       Color(0xFF23C6A6)),
  JunkCategory.apkFiles:      _CategoryStyle(Icons.android_rounded,           Color(0xFF7C6BF7)),
  JunkCategory.largeFiles:    _CategoryStyle(Icons.insert_drive_file_rounded, Color(0xFF4C8DFF)),
};

_CategoryStyle _styleFor(JunkCategory category) =>
    _categoryStyles[category] ??
        const _CategoryStyle(Icons.folder_rounded, Color(0xFFFF7A3D));

// ─── CATEGORY TEXT HELPERS (translated) ───────────────────────────────────────
String _categoryTitle(JunkCategory category) => switch (category) {
  JunkCategory.cacheFiles    => T.of('cacheFiles'),
  JunkCategory.tempFiles     => T.of('temporaryFiles'),
  JunkCategory.residualFiles => T.of('residualFiles'),
  JunkCategory.apkFiles      => T.of('uselessApks'),
  JunkCategory.largeFiles    => T.of('largeFiles'),
};

String _categoryDescription(JunkCategory category) => switch (category) {
  JunkCategory.cacheFiles    => T.of('cacheFilesDesc'),
  JunkCategory.tempFiles     => T.of('temporaryFilesDesc'),
  JunkCategory.residualFiles => T.of('residualFilesDesc'),
  JunkCategory.apkFiles      => T.of('uselessApksDesc'),
  JunkCategory.largeFiles    => T.of('largeFilesDesc'),
};

String _categoryShortLabel(JunkCategory category) => switch (category) {
  JunkCategory.apkFiles      => T.of('apks'),
  JunkCategory.cacheFiles    => T.of('cache'),
  JunkCategory.tempFiles     => T.of('temporary'),
  JunkCategory.largeFiles    => T.of('large'),
  JunkCategory.residualFiles => T.of('residual'),
};

final _thumbnailCache = <String, Uint8List?>{};

bool _isImageFile(String ext) =>
    AppConstants.imageExtensions.contains(ext.toLowerCase());
bool _isVideoFile(String ext) =>
    AppConstants.videoExtensions.contains(ext.toLowerCase());

// ─── DARK MODE HELPERS ────────────────────────────────────────────────────────
Color _scaffoldColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF13131E)
        : AppColors.surfaceLight;

Color _cardColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF252535)
        : Colors.white;

Color _surfaceColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E2A)
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

Color _shadowColorMd(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.05);

Color _placeholderBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A3A)
        : Colors.grey.shade100;

Color _placeholderIcon(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.grey.shade500;

Color _dividerColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.black12;

// ─── SHARED BOTTOM NAV ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  List<({IconData icon, IconData selectedIcon, String label})> get _items => [
    (icon: Icons.home_outlined,        selectedIcon: Icons.home_rounded,         label: T.of('home')),
    (icon: Icons.folder_outlined,      selectedIcon: Icons.folder_rounded,       label: T.of('files')),
    (icon: Icons.grid_view_outlined,   selectedIcon: Icons.grid_view_rounded,    label: T.of('apps')),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded, label: T.of('settings')),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items  = _items;
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
            final item     = items[index];
            final selected = index == currentIndex;
            final color    = selected
                ? _activeColor(index)
                : (isDark ? Colors.white38 : Colors.black38);
            return Expanded(
              child: Pressable(
                onTap: () => _onTap(context, index),
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
                      item.label,
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
              )),
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
class JunkCleanerView extends ConsumerWidget {
  const JunkCleanerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state     = ref.watch(junkCleanerViewModelProvider);
    final viewModel = ref.read(junkCleanerViewModelProvider.notifier);

    const navIndex = 0;

    // Only let hardware back pop this screen's ROUTE (back to Dashboard)
    // when we're at the idle/start state. Otherwise — mid-scan, results
    // shown, or cleaning in progress — hardware back should do the same
    // thing the header's back arrow does (reset to idle) instead of
    // skipping past this whole screen.
    final atIdle = state is JunkCleanerIdle ||
        state is JunkCleanerPermissionRequired ||
        state is JunkCleanerError;

    return PopScope(
      canPop: atIdle,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) viewModel.reset();
      },
      child: Scaffold(
      backgroundColor: _scaffoldColor(context),
      bottomNavigationBar: const _BottomNav(currentIndex: navIndex),
      body: state.when(
        idle: () => _IdleView(onScan: viewModel.startScan),
        permissionRequired: () =>
            _PermissionView(onRetry: viewModel.startScan),
        scanning: (groups) => _ScanBody(
          groups:           groups,
          isScanning:       true,
          onToggleCategory: viewModel.toggleCategory,
          onToggleFile:     viewModel.toggleFile,
          onClean:          () {},
          onBack:           viewModel.reset,
        ),
        scanned: (groups) => _ScanBody(
          groups:           groups,
          isScanning:       false,
          onToggleCategory: viewModel.toggleCategory,
          onToggleFile:     viewModel.toggleFile,
          onClean: () => _confirmAndClean(context, ref, groups),
          onBack:  viewModel.reset,
        ),
        cleaning:  () => const _CleaningView(),
        cleaned: (deleted, freed) => _CleanedView(
          filesDeleted: deleted,
          bytesFreed:   freed,
          onDone:       viewModel.reset,
        ),
        error: (message) => _ErrorView(
          message: message,
          onRetry: viewModel.startScan,
        ),
      ),
      ),
    );
  }

  Future<void> _confirmAndClean(
      BuildContext    context,
      WidgetRef       ref,
      List<JunkGroup> groups,
      ) async {
    final selectedBytes =
    groups.fold<int>(0, (sum, g) => sum + g.selectedBytes);
    final selectedCount =
    groups.fold<int>(0, (sum, g) => sum + g.selectedPaths.length);
    if (selectedCount == 0) return;

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xFF252535) : Colors.white,
        title: Text(
          T.of('deleteJunkFiles'),
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          '${T.of('deleteJunkDesc')} $selectedCount ${T.of('andFreeUp')} '
              '${FormatUtils.formatBytes(selectedBytes)}. ${T.of('cannotBeUndone')}',
          style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:     Text(T.of('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child:     Text(T.of('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(junkCleanerViewModelProvider.notifier)
          .cleanSelected();
    }
  }
}

// ─── IDLE VIEW ────────────────────────────────────────────────────────────────
class _IdleView extends StatelessWidget {
  final VoidCallback onScan;
  const _IdleView({required this.onScan});

  List<(IconData, String, Color)> get _categories => [
    (Icons.grid_view_rounded,         T.of('cacheFiles'),     Color(0xFFFF7A3D)),
    (Icons.folder_rounded,            T.of('temporaryFiles'), Color(0xFFFFC24B)),
    (Icons.description_rounded,       T.of('residualFiles'),  Color(0xFF23C6A6)),
    (Icons.android_rounded,           T.of('uselessApks'),    Color(0xFF7C6BF7)),
    (Icons.insert_drive_file_rounded, T.of('largeFiles'),     Color(0xFF4C8DFF)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        // ── HERO HEADER ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 64, 20, 36),
            decoration: const BoxDecoration(
              gradient: _junkGradient,
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -10,
                  top:   -10,
                  child: Icon(
                    Icons.delete_sweep_rounded,
                    size:  110,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: const Padding(
                            padding: EdgeInsets.only(
                                right: 8, bottom: 4),
                            child: Icon(Icons.arrow_back,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      T.of('junkCleaner'),
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      T.of('freeUpSpace'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Container(
                        width:  96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cleaning_services_rounded,
                          size:  46,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── SECTION TITLE ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Text(
              T.of('whatWeScan'),
              style: TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.bold,
                color:      _textPrimary(context),
              ),
            ),
          ),
        ),

        // ── CATEGORY LIST ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final c in _categories)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _cardColor(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:      _shadowColor(context),
                          blurRadius: 10,
                          offset:     const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width:     38,
                          height:    38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.$3.withValues(
                                alpha: isDark ? 0.20 : 0.12),
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: Icon(c.$1,
                              color: c.$3, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          c.$2,
                          style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w600,
                            color:      _textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── PRIVACY NOTE ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    size: 16, color: _textMuted(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    T.of('privacyNote'),
                    style: TextStyle(
                        fontSize: 12.5,
                        color: _textMuted(context)),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── SCAN BUTTON ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: SizedBox(
              width: double.infinity,
              child: Pressable(
                pressedScale: 0.98,
                onTap: onScan,
                child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: onScan,
                icon:      const Icon(Icons.search_rounded),
                label: Text(
                  T.of('startScan'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── PERMISSION VIEW ─────────────────────────────────────────────────────────
class _PermissionView extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_off_outlined,
                size:  40,
                color: isDark
                    ? Colors.white38
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              T.of('storageAccessNeeded'),
              style: TextStyle(
                fontSize:   17,
                fontWeight: FontWeight.bold,
                color:      _textPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              T.of('permissionDesc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:    _textSecondary(context),
                height:   1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: onRetry,
                child: Text(T.of('grantAccess'),
                    style:
                    const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SCAN BODY ────────────────────────────────────────────────────────────────
class _ScanBody extends StatefulWidget {
  final List<JunkGroup>                     groups;
  final bool                                isScanning;
  final void Function(JunkCategory)         onToggleCategory;
  final void Function(JunkCategory, String) onToggleFile;
  final VoidCallback                        onClean;
  final VoidCallback                        onBack;

  const _ScanBody({
    required this.groups,
    required this.isScanning,
    required this.onToggleCategory,
    required this.onToggleFile,
    required this.onClean,
    required this.onBack,
  });

  @override
  State<_ScanBody> createState() => _ScanBodyState();
}

class _ScanBodyState extends State<_ScanBody> {
  JunkCategory? _filter;

  String _shortLabel(JunkCategory category) => _categoryShortLabel(category);

  @override
  Widget build(BuildContext context) {
    final totalBytes =
    widget.groups.fold<int>(0, (sum, g) => sum + g.totalBytes);
    final selectedBytes =
    widget.groups.fold<int>(0, (sum, g) => sum + g.selectedBytes);
    final visibleGroups = _filter == null
        ? widget.groups
        : widget.groups.where((g) => g.category == _filter).toList();

    return CustomScrollView(
      slivers: [
        // ── SCAN HEADER ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _ScanHeader(
            isScanning:      widget.isScanning,
            totalBytes:      totalBytes,
            filter:          _filter,
            onFilterChanged: (cat) =>
                setState(() => _filter = cat),
            shortLabel:      _shortLabel,
            onBack:          widget.onBack,
          ),
        ),

        // ── SUMMARY CARD ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _SummaryCard(
              totalBytes: totalBytes,
              groups:     widget.groups,
            ),
          ),
        ),

        // ── SCANNING PROGRESS BAR ────────────────────────────────────────────
        if (widget.isScanning)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                child: LinearProgressIndicator(
                  minHeight:       4,
                  backgroundColor: Color(0x1AFF7A3D),
                  valueColor:
                  AlwaysStoppedAnimation(Color(0xFFFF7A3D)),
                ),
              ),
            ),
          ),

        // ── CATEGORY TILES ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                if (visibleGroups.isEmpty && !widget.isScanning)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Text(
                      T.of('noJunkInCategory'),
                      style: TextStyle(
                          color: _textSecondary(context)),
                    ),
                  )
                else
                  for (final group in visibleGroups)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CategoryTile(
                        group: group,
                        onToggleCategory: () =>
                            widget.onToggleCategory(group.category),
                        onToggleFile: (path) =>
                            widget.onToggleFile(group.category, path),
                      ),
                    ),
              ],
            ),
          ),
        ),

        // ── EXCLUDED ITEMS ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: _ExcludedItemsRow(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          T.of('exclusionsComingSoon'))),
                );
              },
            ),
          ),
        ),

        // ── CLEAN BUTTON ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: (widget.isScanning || selectedBytes == 0)
                    ? null
                    : widget.onClean,
                icon:  const Icon(Icons.cleaning_services_rounded),
                label: Text(
                  '${T.of('clean')} ${FormatUtils.formatBytes(selectedBytes)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── SCAN HEADER ──────────────────────────────────────────────────────────────
class _ScanHeader extends StatelessWidget {
  final bool                         isScanning;
  final int                          totalBytes;
  final JunkCategory?                filter;
  final void Function(JunkCategory?) onFilterChanged;
  final String Function(JunkCategory) shortLabel;
  final VoidCallback                 onBack;

  const _ScanHeader({
    required this.isScanning,
    required this.totalBytes,
    required this.filter,
    required this.onFilterChanged,
    required this.shortLabel,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 56, 20, 24),
      decoration: const BoxDecoration(
        gradient: _junkGradient,
        borderRadius:
        BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top:   -4,
            child: Icon(
              Icons.delete_sweep_rounded,
              size:  92,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white),
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Text(
                      T.of('junkCleaner'),
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    if (isScanning) ...[
                      const SizedBox(
                        width:  13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                              Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isScanning
                          ? T.of('scanning')
                          : '${FormatUtils.formatBytes(totalBytes)} ${T.of('canBeRemoved')}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label:    T.of('recommended'),
                        selected: filter == null,
                        onTap: () => onFilterChanged(null),
                      ),
                      for (final category in JunkCategory.values)
                        Padding(
                          padding:
                          const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label:    shortLabel(category),
                            selected: filter == category,
                            onTap: () =>
                                onFilterChanged(category),
                          ),
                        ),
                    ],
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

// ─── SUMMARY CARD ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int             totalBytes;
  final List<JunkGroup> groups;

  const _SummaryCard(
      {required this.totalBytes, required this.groups});

  @override
  Widget build(BuildContext context) {
    final formatted =
    FormatUtils.formatBytes(totalBytes).split(' ');
    final nonEmpty =
    groups.where((g) => g.totalBytes > 0).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:      _shadowColorMd(context),
            blurRadius: 18,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: formatted.isNotEmpty ? formatted[0] : '0',
                  style: TextStyle(
                    color:      _textPrimary(context),
                    fontSize:   36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: formatted.length > 1
                      ? ' ${formatted[1]}'
                      : '',
                  style: TextStyle(
                    color:      _textPrimary(context),
                    fontSize:   20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            T.of('totalJunkFound'),
            style: TextStyle(
              color:    _textSecondary(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          if (nonEmpty.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (final group in nonEmpty)
                      Expanded(
                        flex:  group.totalBytes,
                        child: Container(
                            color:
                            _styleFor(group.category).color),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing:    24,
              runSpacing: 12,
              children: [
                for (final group in nonEmpty)
                  SizedBox(
                    width: (MediaQuery.of(context).size.width -
                        40 -
                        22 * 2 -
                        24) /
                        2,
                    child: Row(
                      children: [
                        Container(
                          width:  10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _styleFor(group.category)
                                .color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _categoryShortLabel(group.category),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color:    _textPrimary(context),
                            ),
                          ),
                        ),
                        Text(
                          FormatUtils.formatBytes(
                              group.totalBytes),
                          style: TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                            color:      _textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── FILTER CHIP ─────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding:   const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _kOrange : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize:   13,
          ),
        ),
      ),
    );
  }
}

// ─── CATEGORY TILE ───────────────────────────────────────────────────────────
class _CategoryTile extends StatefulWidget {
  final JunkGroup                  group;
  final VoidCallback               onToggleCategory;
  final void Function(String path) onToggleFile;

  const _CategoryTile({
    required this.group,
    required this.onToggleCategory,
    required this.onToggleFile,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final group  = widget.group;
    final style  = _styleFor(group.category);

    return Container(
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      _shadowColor(context),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── HEADER ROW ───────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: (group.files.isEmpty || group.isScanning)
                ? null
                : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width:     44,
                    height:    44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: style.color.withValues(
                          alpha: isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(style.icon,
                        color: style.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _categoryTitle(group.category),
                          style: TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.bold,
                            color:      _textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _categoryDescription(group.category),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (group.isScanning)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10),
                      child: SizedBox(
                        width:  18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(
                              _kOrange),
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      FormatUtils.formatBytes(
                          group.totalBytes),
                      style: TextStyle(
                        fontSize:   13.5,
                        fontWeight: FontWeight.w600,
                        color:      _textPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: group.allSelected,
                      activeColor: _kOrange,
                      onChanged: group.files.isEmpty
                          ? null
                          : (_) => widget.onToggleCategory(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── EXPANDED FILE LIST ───────────────────────────────────────────
          if (_expanded && group.files.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Divider(height: 1, color: _dividerColor(context)),
                  for (final file in group.files.take(50))
                    CheckboxListTile(
                      value: group.selectedPaths
                          .contains(file.path),
                      onChanged: (_) =>
                          widget.onToggleFile(file.path),
                      dense:           true,
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor:     _kOrange,
                      secondary: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width:  44,
                          height: 44,
                          child: _JunkFileThumbnail(file: file),
                        ),
                      ),
                      title: Text(
                        file.path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: _textPrimary(context)),
                      ),
                      subtitle: Text(
                        FormatUtils.formatBytes(file.sizeBytes),
                        style: TextStyle(
                            color: _textSecondary(context)),
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

// ─── JUNK FILE THUMBNAIL ──────────────────────────────────────────────────────
class _JunkFileThumbnail extends StatelessWidget {
  final ScannedFile file;
  const _JunkFileThumbnail({required this.file});

  @override
  Widget build(BuildContext context) {
    if (_isImageFile(file.extension)) {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: _placeholderBg(context),
          child: Icon(Icons.broken_image_outlined,
              size: 20, color: _placeholderIcon(context)),
        ),
      );
    }

    if (_isVideoFile(file.extension)) {
      return _VideoThumb(path: file.path);
    }

    return Container(
      color: _placeholderBg(context),
      child: Icon(_fileIcon(file.extension),
          size: 20, color: _placeholderIcon(context)),
    );
  }

  IconData _fileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':  return Icons.picture_as_pdf_outlined;
      case '.doc':
      case '.docx': return Icons.description_outlined;
      case '.xls':
      case '.xlsx': return Icons.table_chart_outlined;
      case '.mp3':
      case '.wav':
      case '.aac':
      case '.m4a':  return Icons.audio_file_outlined;
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':   return Icons.folder_zip_outlined;
      case '.apk':  return Icons.android_outlined;
      default:      return Icons.insert_drive_file_outlined;
    }
  }
}

// ─── VIDEO THUMBNAIL ──────────────────────────────────────────────────────────
class _VideoThumb extends StatefulWidget {
  final String path;
  const _VideoThumb({required this.path});

  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  Uint8List? _thumb;
  bool       _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_thumbnailCache.containsKey(widget.path)) {
      if (mounted) {
        setState(() {
          _thumb   = _thumbnailCache[widget.path];
          _loading = false;
        });
      }
      return;
    }

    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video:       widget.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth:    120,
        quality:     50,
        timeMs:      1000,
      );
      _thumbnailCache[widget.path] = bytes;
      if (mounted) {
        setState(() {
          _thumb   = bytes;
          _loading = false;
        });
      }
    } catch (_) {
      _thumbnailCache[widget.path] = null;
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: _placeholderBg(context),
        child: const Center(
          child: SizedBox(
            width:  14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _kOrange),
          ),
        ),
      );
    }

    if (_thumb == null) {
      return Container(
        color: _placeholderBg(context),
        child: Icon(Icons.videocam_outlined,
            size: 20, color: _placeholderIcon(context)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(_thumb!, fit: BoxFit.cover),
        const Center(
          child: Icon(Icons.play_circle_fill,
              color: Colors.white70, size: 16),
        ),
      ],
    );
  }
}

// ─── EXCLUDED ITEMS ROW ───────────────────────────────────────────────────────
class _ExcludedItemsRow extends StatelessWidget {
  final VoidCallback onTap;
  const _ExcludedItemsRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color:        _cardColor(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap:        onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width:     44,
                height:    44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kOrange.withValues(
                      alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: _kOrange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:       MainAxisSize.min,
                  children: [
                    Text(
                      T.of('excludedItems'),
                      style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.bold,
                        color:      _textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      T.of('excludedItemsRow'),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          color: _textSecondary(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kOrange.withValues(
                      alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '0 ${T.of('exclusions')}',
                  style: const TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color:      _kOrange,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  color: _textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CLEANING VIEW ────────────────────────────────────────────────────────────
class _CleaningView extends StatelessWidget {
  const _CleaningView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width:  64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth:  4,
              valueColor:   const AlwaysStoppedAnimation(_kOrange),
              backgroundColor:
              _kOrange.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            T.of('cleaningUp'),
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      _textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            T.of('onlyMoment'),
            style: TextStyle(
              color:    _textSecondary(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CLEANED VIEW ─────────────────────────────────────────────────────────────
class _CleanedView extends StatelessWidget {
  final int          filesDeleted;
  final int          bytesFreed;
  final VoidCallback onDone;

  const _CleanedView({
    required this.filesDeleted,
    required this.bytesFreed,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 96, color: AppColors.success),
          const SizedBox(height: 16),
          Text(
            '${T.of('freed')} ${FormatUtils.formatBytes(bytesFreed)}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: _textPrimary(context)),
          ),
          Text(
            '$filesDeleted ${T.of('filesDeleted')}',
            style: TextStyle(color: _textSecondary(context)),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: _kOrange),
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
              style: TextStyle(color: _textSecondary(context)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: _kOrange),
              onPressed: onRetry,
              child: Text(T.of('retry')),
            ),
          ],
        ),
      ),
    );
  }
}