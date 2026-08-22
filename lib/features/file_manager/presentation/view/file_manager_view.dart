// file_manager_view.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/services/file_scan_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/utils/format_utils.dart';
import '../../domain/file_manager_state.dart';
import '../viewmodel/file_manager_viewmodel.dart';

const _kBlue   = Color(0xFF2F6BFF);
const _kDanger = Color(0xFFFF5A5F);

const _kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4F86FF), Color(0xFF2F6BFF)],
);

const _kBtnGradient = LinearGradient(
  colors: [Color(0xFF2F6BFF), Color(0xFF1B3FBF)],
);

Color _surfaceColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E2A)
        : Colors.white;

Color _cardColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF252535)
        : Colors.white;

Color _scaffoldColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF13131E)
        : const Color(0xFFF7F9FC);

Color _textPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

Color _textSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black45;

Color _iconMuted(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white38
        : Colors.black38;

Color _dividerColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.black12;

Color _thumbnailBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A3A)
        : const Color(0xFFF0F2F6);

Color _shadowColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.06);

Color _catColor(FileCategory c) => switch (c) {
  FileCategory.images    => const Color(0xFF2F6BFF),
  FileCategory.videos    => const Color(0xFF8E5CF7),
  FileCategory.audio     => const Color(0xFFE91E8C),
  FileCategory.documents => const Color(0xFF2ECC71),
  FileCategory.apks      => const Color(0xFF00BFA5),
  FileCategory.zips      => const Color(0xFFFFB020),
  FileCategory.downloads => const Color(0xFF4CAF50),
};

List<Color> _catGradient(FileCategory c) => switch (c) {
  FileCategory.images    => const [Color(0xFF9C6FF0), Color(0xFFC08AF7)],
  FileCategory.videos    => const [Color(0xFFEC4899), Color(0xFFFF7AA8)],
  FileCategory.audio     => const [Color(0xFF3B82F6), Color(0xFF6AA6FF)],
  FileCategory.documents => const [Color(0xFF14B8A6), Color(0xFF3FD9BE)],
  FileCategory.apks      => const [Color(0xFF6D5DFC), Color(0xFF9C90FF)],
  FileCategory.zips      => const [Color(0xFFFFB020), Color(0xFFFFCB66)],
  FileCategory.downloads => const [Color(0xFF22C55E), Color(0xFF5CDB86)],
};

final _thumbnailCache = <String, Uint8List?>{};

/// Bounds how many video thumbnails decode at once. video_thumbnail
/// makes a real native decoder call per thumbnail — when the GridView
/// builds many _VideoThumb cells at nearly the same time (e.g. initial
/// layout, fast scroll), firing that many decoder calls simultaneously
/// overloads the native decoder on many devices and a large fraction
/// of them fail outright. Those failures used to be cached as
/// permanent — which is why thumbnails would inconsistently show up
/// "sometimes but not others": whichever ones happened to decode
/// before the pile-up looked fine forever, everything else stayed a
/// generic icon forever. Queueing to a small number of concurrent
/// decodes fixes the pile-up at its source.
class _VideoThumbLimiter {
  _VideoThumbLimiter._();
  static final _VideoThumbLimiter instance = _VideoThumbLimiter._();

  static const _maxConcurrent = 3;
  int _active = 0;
  final _queue = <Completer<void>>[];

  Future<void> acquire() async {
    if (_active < _maxConcurrent) {
      _active++;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  void release() {
    _active--;
    if (_queue.isNotEmpty) {
      _active++;
      _queue.removeAt(0).complete();
    }
  }
}

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
      case 3: context.go(AppRoutes.settings); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      (icon: Icons.home_outlined,        selectedIcon: Icons.home_rounded,         label: T.of('home')),
      (icon: Icons.folder_outlined,      selectedIcon: Icons.folder_rounded,       label: T.of('files')),
      (icon: Icons.grid_view_outlined,   selectedIcon: Icons.grid_view_rounded,    label: T.of('apps')),
      (icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded, label: T.of('settings')),
    ];

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
              )),
            );
          }),
        ),
      ),
    );
  }

  Color _activeColor(int index) {
    switch (index) {
      case 1:  return _kBlue;
      case 2:  return const Color(0xFF6C63FF);
      case 3:  return const Color(0xFF00C2A8);
      default: return _kBlue;
    }
  }
}

// ─── Small "still scanning" badge, shown while a category streams in ────────
class _ScanningBadge extends StatelessWidget {
  const _ScanningBadge();

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 6),
          Text(
            'Scanning…',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class FileManagerView extends ConsumerWidget {
  const FileManagerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileManagerViewModelProvider);
    final vm    = ref.read(fileManagerViewModelProvider.notifier);

    // Only allow the system/hardware back button to pop this screen's
    // ROUTE (back to Dashboard) when we're already at the category
    // overview. If a category is open, hardware back should behave the
    // same as the header's back arrow — return to the overview first —
    // instead of skipping straight past this whole screen.
    final atOverview = state is FileManagerOverview ||
        state is FileManagerPermissionRequired ||
        state is FileManagerOverviewLoading ||
        state is FileManagerError;

    return PopScope(
      canPop: atOverview,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) vm.backToOverview();
      },
      child: Scaffold(
      backgroundColor: _scaffoldColor(context),
      bottomNavigationBar: const _BottomNav(currentIndex: 1),
      body: state.when(
        overviewLoading: () => Column(
          children: [
            const _Header(),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: _kBlue),
              ),
            ),
          ],
        ),
        overview: (categories, usedBytes, totalBytes, query, results) =>
            _OverviewPage(
              categories:       categories,
              usedBytes:        usedBytes,
              totalBytes:       totalBytes,
              searchQuery:      query,
              searchResults:    results,
              onSelectCategory: vm.openCategory,
              onSearchChanged:  vm.search,
              onRefresh:        vm.loadOverview,
              onDelete:         vm.deleteFile,
              onRename:         vm.renameFile,
              onShare:          vm.shareFile,
            ),
        permissionRequired: () => Column(
          children: [
            const _Header(),
            Expanded(child: _PermissionBody(onRetry: vm.loadOverview)),
          ],
        ),
        loading: (category) => Column(
          children: [
            _CategoryHeader(
                title: category.label, onBack: vm.backToOverview),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: _kBlue),
              ),
            ),
          ],
        ),
        loaded: (category, files, sortBy, viewMode) => Stack(
          children: [
            _FileListPage(
              category:     category,
              files:        files,
              sortBy:       sortBy,
              viewMode:     viewMode,
              onBack:       vm.backToOverview,
              onToggleView: vm.toggleViewMode,
              onSort:       vm.setSortBy,
              onDelete:     vm.deleteFile,
              onRename:     vm.renameFile,
              onShare:      vm.shareFile,
            ),
            if (ref.watch(fileManagerScanningProvider))
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                right: 16,
                child: const _ScanningBadge(),
              ),
          ],
        ),
        error: (message) => Column(
          children: [
            const _Header(),
            Expanded(
              child: _ErrorBody(
                  message: message, onRetry: vm.loadOverview),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─── GRADIENT HEADER ──────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(gradient: _kGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
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
            const SizedBox(height: 12),
            Text(
              T.of('fileManager'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              T.of('manageYourFiles'),
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            const _FolderIllustration(),
          ],
        ),
      ),
    ),
  );
}

// ─── FOLDER ILLUSTRATION ──────────────────────────────────────────────────────
class _FolderIllustration extends StatelessWidget {
  const _FolderIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 90,
    width: double.infinity,
    child: Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 180,
        height: 90,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 30,
              top: 10,
              child: Icon(Icons.folder_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 72),
            ),
            Positioned(
              right: 46,
              top: -6,
              child: Icon(Icons.description_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 40),
            ),
            Positioned(
              left: 10,
              top: 6,
              child: _MiniChip(
                  icon: Icons.image_rounded,
                  color: Colors.white),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: _MiniChip(
                  icon: Icons.music_note_rounded,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final Color    color;
  const _MiniChip({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: Colors.white, size: 20),
  );
}

// ─── CATEGORY DETAIL HEADER ───────────────────────────────────────────────────
class _CategoryHeader extends StatelessWidget {
  final String       title;
  final VoidCallback onBack;
  final Widget?      trailing;

  const _CategoryHeader({
    required this.title,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: _kGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white),
              onPressed: onBack,
            ),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    ),
  );
}

// ─── OVERVIEW PAGE ────────────────────────────────────────────────────────────
class _OverviewPage extends StatefulWidget {
  final List<CategorySummary>         categories;
  final int                           usedBytes;
  final int                           totalBytes;
  final String?                       searchQuery;
  final List<ScannedFile>?            searchResults;
  final void Function(FileCategory)   onSelectCategory;
  final void Function(String)         onSearchChanged;
  final VoidCallback                  onRefresh;
  final void Function(String)         onDelete;
  final void Function(String, String) onRename;
  final void Function(String)         onShare;

  const _OverviewPage({
    required this.categories,
    required this.usedBytes,
    required this.totalBytes,
    required this.searchQuery,
    required this.searchResults,
    required this.onSelectCategory,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onDelete,
    required this.onRename,
    required this.onShare,
  });

  @override
  State<_OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<_OverviewPage> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search =
        TextEditingController(text: widget.searchQuery ?? '');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CategorySummary> get _sortedCategories =>
      [...widget.categories]
        ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

  @override
  Widget build(BuildContext context) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final isSearching   = (widget.searchQuery ?? '').isNotEmpty;
    final sorted        = _sortedCategories;
    final nonEmptyCount =
        sorted.where((c) => c.sizeBytes > 0).length;

    return Column(
      children: [
        const _Header(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // ── SEARCH BAR ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: _cardColor(context),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _shadowColor(context),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.search,
                        color: _iconMuted(context), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged:  widget.onSearchChanged,
                        style: TextStyle(
                            color: _textPrimary(context)),
                        decoration: InputDecoration(
                          hintText: T.of('searchFiles'),
                          hintStyle: TextStyle(
                              color: _textSecondary(context)),
                          border:  InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (isSearching)
                      IconButton(
                        icon: Icon(Icons.close,
                            color: _iconMuted(context)),
                        onPressed: () {
                          _search.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    else
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            color: isDark
                                ? Colors.white
                                : Colors.black45),
                        color: _cardColor(context),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14)),
                        onSelected: (v) {
                          if (v == 'refresh') widget.onRefresh();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'refresh',
                            child: Text(T.of('refresh'),
                                style: TextStyle(
                                    color:
                                    _textPrimary(context))),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (isSearching) ...[
                Text(
                  '${widget.searchResults?.length ?? 0} ${T.of('results')}',
                  style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary(context)),
                ),
                const SizedBox(height: 10),
                if ((widget.searchResults ?? []).isEmpty)
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        T.of('noMatchingFiles'),
                        style: TextStyle(
                            color: _textSecondary(context)),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: _cardColor(context),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _shadowColor(context),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: widget.searchResults!
                          .map((f) => _FileListTile(
                        file:     f,
                        category: _guessCategory(f),
                        onDelete: widget.onDelete,
                        onRename: widget.onRename,
                        onShare:  widget.onShare,
                      ))
                          .toList(),
                    ),
                  ),
              ] else ...[
                // ── STORAGE SUMMARY ────────────────────────────────────
                _StorageCard(
                  usedBytes:  widget.usedBytes,
                  totalBytes: widget.totalBytes,
                  categories: sorted,
                ),
                const SizedBox(height: 24),

                // ── CATEGORIES HEADER ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      T.of('categories'),
                      style: TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.bold,
                        color:      _textPrimary(context),
                      ),
                    ),
                    Text(
                      '$nonEmptyCount ${T.of('withFiles')}',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: _textSecondary(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── CATEGORY GRID ──────────────────────────────────────
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:   2,
                    mainAxisSpacing:  14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: widget.categories.length,
                  itemBuilder: (_, i) => _CategoryCard(
                    summary: widget.categories[i],
                    onTap: () => widget.onSelectCategory(
                        widget.categories[i].category),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  FileCategory _guessCategory(ScannedFile f) {
    const images = ['.jpg', '.jpeg', '.png', '.webp', '.heic'];
    const videos = ['.mp4', '.mov', '.mkv', '.avi'];
    const audio  = ['.mp3', '.wav', '.aac', '.m4a'];
    final ext    = f.extension.toLowerCase();
    if (images.contains(ext)) return FileCategory.images;
    if (videos.contains(ext)) return FileCategory.videos;
    if (audio.contains(ext))  return FileCategory.audio;
    return FileCategory.documents;
  }
}

// ─── STORAGE SUMMARY CARD ─────────────────────────────────────────────────────
class _StorageCard extends StatelessWidget {
  final int                   usedBytes;
  final int                   totalBytes;
  final List<CategorySummary> categories;

  const _StorageCard({
    required this.usedBytes,
    required this.totalBytes,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final usedFraction =
    totalBytes == 0 ? 0.0 : usedBytes / totalBytes;
    final top      = categories.take(4).toList();
    final topBytes = top.fold<int>(0, (s, c) => s + c.sizeBytes);
    final otherBytes =
    (usedBytes - topBytes).clamp(0, usedBytes);

    final segments =
    <MapEntry<String, ({int bytes, Color color})>>[
      for (final c in top)
        MapEntry(
          c.category.label,
          (bytes: c.sizeBytes, color: _catColor(c.category)),
        ),
      if (otherBytes > 0)
        MapEntry(
          T.of('other'),
          (
          bytes: otherBytes,
          color: isDark
              ? Colors.grey.shade600
              : Colors.grey.shade400,
          ),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kBlue.withValues(
                      alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_android_rounded,
                    color: _kBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      T.of('internalStorage'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _textPrimary(context),
                      ),
                    ),
                    Text(
                      '${FormatUtils.formatBytes(usedBytes)} / '
                          '${FormatUtils.formatBytes(totalBytes)} '
                          '${T.of('used')}',
                      style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary(context)),
                    ),
                  ],
                ),
              ),
              Text(
                '${(usedFraction * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kBlue,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: isDark
                      ? Colors.white24
                      : Colors.black26),
            ],
          ),
          const SizedBox(height: 16),
          // Segmented bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final s in segments)
                    Expanded(
                      flex: usedBytes == 0
                          ? 1
                          : ((s.value.bytes / usedBytes) * 1000)
                          .round()
                          .clamp(1, 1000),
                      child: ColoredBox(color: s.value.color),
                    ),
                  if (usedBytes < totalBytes)
                    Expanded(
                      flex: ((((totalBytes - usedBytes) /
                          totalBytes) *
                          1000))
                          .round()
                          .clamp(1, 1000),
                      child: ColoredBox(
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.shade200),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: segments
                .map((s) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: s.value.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(s.key,
                    style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary(context))),
                const SizedBox(width: 4),
                Text(
                  FormatUtils.formatBytes(
                      s.value.bytes),
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color:      _textPrimary(context),
                  ),
                ),
              ],
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── CATEGORY CARD ────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final CategorySummary summary;
  final VoidCallback    onTap;

  const _CategoryCard(
      {required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradient = _catGradient(summary.category);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(summary.category.icon,
                        color: Colors.white, size: 20),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white70, size: 20),
                ],
              ),
              const Spacer(),
              Text(
                summary.category.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:   16,
                  color:      Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                FormatUtils.formatBytes(summary.sizeBytes),
                style: TextStyle(
                    fontSize: 12.5,
                    color:
                    Colors.white.withValues(alpha: 0.85)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FILE LIST PAGE ───────────────────────────────────────────────────────────
class _FileListPage extends StatefulWidget {
  final FileCategory                  category;
  final List<ScannedFile>             files;
  final FileSortBy                    sortBy;
  final FileViewMode                  viewMode;
  final VoidCallback                  onBack;
  final VoidCallback                  onToggleView;
  final void Function(FileSortBy)     onSort;
  final void Function(String)         onDelete;
  final void Function(String, String) onRename;
  final void Function(String)         onShare;

  const _FileListPage({
    required this.category,
    required this.files,
    required this.sortBy,
    required this.viewMode,
    required this.onBack,
    required this.onToggleView,
    required this.onSort,
    required this.onDelete,
    required this.onRename,
    required this.onShare,
  });

  @override
  State<_FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<_FileListPage> {
  final Set<String> _selected = {};

  bool get _selectionMode => _selected.isNotEmpty;

  void _toggle(String path) => setState(() => _selected.contains(path)
      ? _selected.remove(path)
      : _selected.add(path));

  void _clearSelection() => setState(_selected.clear);

  void _selectAll() => setState(
          () => _selected.addAll(widget.files.map((f) => f.path)));

  void _openFile(int index) {
    if (widget.category == FileCategory.images) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ImageViewerScreen(
          files:        widget.files,
          initialIndex: index,
          onDelete:     widget.onDelete,
          onShare:      widget.onShare,
        ),
      ));
    } else if (widget.category == FileCategory.videos) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _VideoPlayerScreen(
          file:     widget.files[index],
          onDelete: widget.onDelete,
          onShare:  widget.onShare,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final files  = widget.files;

    return Scaffold(
      backgroundColor: _scaffoldColor(context),
      bottomNavigationBar: _selectionMode
          ? _SelectionBar(
        count:   _selected.length,
        onShare: () {
          for (final path in _selected.toList()) {
            widget.onShare(path);
          }
        },
        onDelete: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: _cardColor(context),
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(20)),
              title: Text(
                '${T.of('delete')} ${_selected.length} ${T.of('files')}?',
                style: TextStyle(
                    color: _textPrimary(context)),
              ),
              content: Text(
                T.of('cannotBeUndone'),
                style: TextStyle(
                    color: _textSecondary(context)),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, false),
                  child: Text(T.of('cancel')),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: _kDanger),
                  onPressed: () =>
                      Navigator.pop(ctx, true),
                  child: Text(T.of('delete')),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            for (final path in _selected.toList()) {
              widget.onDelete(path);
            }
            _clearSelection();
          }
        },
      )
          : null,
      body: Column(
        children: [
          _CategoryHeader(
            title: _selectionMode
                ? '${_selected.length} ${T.of('selected')}'
                : widget.category.label,
            onBack:
            _selectionMode ? _clearSelection : widget.onBack,
            trailing: _selectionMode
                ? Row(
              children: [
                TextButton(
                  onPressed:
                  _selected.length == files.length
                      ? _clearSelection
                      : _selectAll,
                  child: Text(
                    _selected.length == files.length
                        ? T.of('deselectAll')
                        : T.of('selectAll'),
                    style: const TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
                : Row(
              children: [
                GestureDetector(
                  onTap: widget.onToggleView,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.viewMode ==
                          FileViewMode.grid
                          ? Icons.view_list_outlined
                          : Icons.grid_view_outlined,
                      color: Colors.white,
                      size:  18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<FileSortBy>(
                  color: _cardColor(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sort,
                        color: Colors.white, size: 18),
                  ),
                  onSelected: widget.onSort,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: FileSortBy.name,
                      child: Text(T.of('name'),
                          style: TextStyle(
                              color:
                              _textPrimary(context))),
                    ),
                    PopupMenuItem(
                      value: FileSortBy.date,
                      child: Text(T.of('date'),
                          style: TextStyle(
                              color:
                              _textPrimary(context))),
                    ),
                    PopupMenuItem(
                      value: FileSortBy.size,
                      child: Text(T.of('size'),
                          style: TextStyle(
                              color:
                              _textPrimary(context))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: files.isEmpty
                ? Center(
              child: Text(
                T.of('noFilesFound'),
                style: TextStyle(
                    color: _textSecondary(context)),
              ),
            )
                : widget.viewMode == FileViewMode.list
                ? ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  12, 12, 12, 16),
              itemCount: files.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(
                    bottom: 8),
                decoration: BoxDecoration(
                  color: _cardColor(context),
                  borderRadius:
                  BorderRadius.circular(16),
                  border: _selected
                      .contains(files[i].path)
                      ? Border.all(
                      color: _kBlue, width: 1.6)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black
                          .withValues(alpha: 0.2)
                          : Colors.black
                          .withValues(alpha: 0.03),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: _FileListTile(
                  file:          files[i],
                  category:      widget.category,
                  onDelete:      widget.onDelete,
                  onRename:      widget.onRename,
                  onShare:       widget.onShare,
                  selectionMode: _selectionMode,
                  selected: _selected
                      .contains(files[i].path),
                  onTap: () => _selectionMode
                      ? _toggle(files[i].path)
                      : _openFile(i),
                  onLongPress: () =>
                      _toggle(files[i].path),
                ),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                  12, 12, 12, 16),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   3,
                mainAxisSpacing:  10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: files.length,
              itemBuilder: (_, i) => _FileGridTile(
                file:          files[i],
                category:      widget.category,
                onDelete:      widget.onDelete,
                onRename:      widget.onRename,
                onShare:       widget.onShare,
                selectionMode: _selectionMode,
                selected: _selected
                    .contains(files[i].path),
                onTap: () => _selectionMode
                    ? _toggle(files[i].path)
                    : _openFile(i),
                onLongPress: () =>
                    _toggle(files[i].path),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SELECTION ACTION BAR ─────────────────────────────────────────────────────
class _SelectionBar extends StatelessWidget {
  final int          count;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _SelectionBar({
    required this.count,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '$count ${T.of('selected')}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize:   14,
              color:      _textPrimary(context),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: count == 0 ? null : onShare,
            icon: const Icon(Icons.share_outlined,
                color: _kBlue, size: 18),
            label: Text(T.of('share'),
                style: const TextStyle(color: _kBlue)),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: count == 0 ? null : onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: _kDanger, size: 18),
            label: Text(T.of('delete'),
                style: const TextStyle(color: _kDanger)),
          ),
        ],
      ),
    ),
  );
}

// ─── LIST TILE ────────────────────────────────────────────────────────────────
class _FileListTile extends StatelessWidget {
  final ScannedFile                   file;
  final FileCategory                  category;
  final void Function(String)         onDelete;
  final void Function(String, String) onRename;
  final void Function(String)         onShare;
  final bool                          selectionMode;
  final bool                          selected;
  final VoidCallback?                 onTap;
  final VoidCallback?                 onLongPress;

  const _FileListTile({
    required this.file,
    required this.category,
    required this.onDelete,
    required this.onRename,
    required this.onShare,
    this.selectionMode = false,
    this.selected      = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap:       onTap,
    onLongPress: onLongPress,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    leading: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width:  52,
            height: 52,
            child: _FileThumbnail(
                file: file, category: category),
          ),
        ),
        if (selectionMode)
          Positioned(
            right:  -2,
            bottom: -2,
            child:  _SelectionDot(selected: selected),
          ),
      ],
    ),
    title: Text(
      file.path.split('/').last,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize:   13,
        fontWeight: FontWeight.w600,
        color:      _textPrimary(context),
      ),
    ),
    subtitle: Text(
      FormatUtils.formatBytes(file.sizeBytes),
      style: TextStyle(
          fontSize: 11, color: _textSecondary(context)),
    ),
    trailing: selectionMode
        ? null
        : _FileActionsMenu(
      file:     file,
      onDelete: onDelete,
      onRename: onRename,
      onShare:  onShare,
    ),
  );
}

// ─── GRID TILE ────────────────────────────────────────────────────────────────
class _FileGridTile extends StatelessWidget {
  final ScannedFile                   file;
  final FileCategory                  category;
  final void Function(String)         onDelete;
  final void Function(String, String) onRename;
  final void Function(String)         onShare;
  final bool                          selectionMode;
  final bool                          selected;
  final VoidCallback?                 onTap;
  final VoidCallback?                 onLongPress;

  const _FileGridTile({
    required this.file,
    required this.category,
    required this.onDelete,
    required this.onRename,
    required this.onShare,
    this.selectionMode = false,
    this.selected      = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap:       onTap,
    onLongPress: onLongPress,
    child: Container(
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: selected
            ? Border.all(color: _kBlue, width: 1.8)
            : null,
        boxShadow: [
          BoxShadow(
            color: _shadowColor(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _FileThumbnail(
                    file: file,
                    category: category,
                    expandFit: true),
                if (selectionMode)
                  Positioned(
                    top:   6,
                    right: 6,
                    child: _SelectionDot(selected: selected),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 8, right: 2, top: 4, bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.path.split('/').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color:      _textPrimary(context),
                        ),
                      ),
                      Text(
                        FormatUtils.formatBytes(
                            file.sizeBytes),
                        style: TextStyle(
                            fontSize: 10,
                            color: _textSecondary(context)),
                      ),
                    ],
                  ),
                ),
                if (!selectionMode)
                  _FileActionsMenu(
                    file:     file,
                    onDelete: onDelete,
                    onRename: onRename,
                    onShare:  onShare,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SelectionDot extends StatelessWidget {
  final bool selected;
  const _SelectionDot({required this.selected});

  @override
  Widget build(BuildContext context) => Container(
    width:  22,
    height: 22,
    decoration: BoxDecoration(
      color:  selected ? _kBlue : _cardColor(context),
      shape:  BoxShape.circle,
      border: Border.all(
        color: selected ? _kBlue : _dividerColor(context),
        width: 1.4,
      ),
    ),
    child: selected
        ? const Icon(Icons.check, color: Colors.white, size: 14)
        : null,
  );
}

// ─── THUMBNAIL ────────────────────────────────────────────────────────────────
class _FileThumbnail extends StatelessWidget {
  final ScannedFile  file;
  final FileCategory category;
  final bool         expandFit;

  const _FileThumbnail({
    required this.file,
    required this.category,
    this.expandFit = false,
  });

  bool get _isVideo => category == FileCategory.videos;
  bool get _isImage => category == FileCategory.images;

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      return Container(
        color: _thumbnailBg(context),
        child: Stack(
          fit: expandFit ? StackFit.expand : StackFit.loose,
          children: [
            _VideoThumb(path: file.path, expandFit: expandFit),
            const Positioned.fill(
              child: Center(
                child: Icon(Icons.play_circle_fill,
                    color: Colors.white70, size: 28),
              ),
            ),
          ],
        ),
      );
    }

    if (_isImage) {
      // cacheWidth forces Flutter's image decoder to downscale DURING
      // decode instead of decoding the full original resolution (which
      // could be a 12MP+ photo) and THEN shrinking it for a ~100px grid
      // cell. This was the main cause of images being slow to appear —
      // every tile was paying full-resolution JPEG/PNG decode cost.
      final targetPx =
          (100 * MediaQuery.of(context).devicePixelRatio).round();
      return Image.file(
        File(file.path),
        fit:        BoxFit.cover,
        width:      double.infinity,
        height:     double.infinity,
        cacheWidth: targetPx,
        errorBuilder: (_, __, ___) => Container(
          color: _thumbnailBg(context),
          child: const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 32, color: Colors.white30),
          ),
        ),
      );
    }

    return Container(
      color: _thumbnailBg(context),
      child: Center(
        child: Icon(_fileIcon,
            size:  30,
            color:
            _catColor(category).withValues(alpha: 0.8)),
      ),
    );
  }

  IconData get _fileIcon {
    switch (file.extension.toLowerCase()) {
      case '.pdf':  return Icons.picture_as_pdf_outlined;
      case '.doc':
      case '.docx': return Icons.description_outlined;
      case '.xls':
      case '.xlsx': return Icons.table_chart_outlined;
      case '.ppt':
      case '.pptx': return Icons.slideshow_outlined;
      case '.mp3':
      case '.wav':
      case '.aac':
      case '.m4a':
      case '.flac': return Icons.audio_file_outlined;
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
  final bool   expandFit;
  const _VideoThumb(
      {required this.path, this.expandFit = false});

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

    await _VideoThumbLimiter.instance.acquire();
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video:       widget.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth:    200,
        quality:     60,
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
      // Deliberately NOT cached as a permanent failure — with the
      // limiter above, failures should now be rare (a genuinely
      // corrupt/unsupported file) rather than the common case, so it's
      // worth retrying next time this widget mounts instead of
      // showing a generic icon forever for what might just have been
      // a momentary decoder overload.
      if (mounted) setState(() => _loading = false);
    } finally {
      _VideoThumbLimiter.instance.release();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width:  18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: _kBlue),
        ),
      );
    }
    if (_thumb == null) {
      return Center(
        child: Icon(Icons.videocam_outlined,
            size: 32,
            color: Theme.of(context).brightness ==
                Brightness.dark
                ? Colors.white30
                : Colors.black26),
      );
    }
    return Image.memory(
      _thumb!,
      fit:    BoxFit.cover,
      width:  widget.expandFit ? double.infinity : null,
      height: widget.expandFit ? double.infinity : null,
    );
  }
}

// ─── FULLSCREEN IMAGE VIEWER ──────────────────────────────────────────────────
class _ImageViewerScreen extends StatefulWidget {
  final List<ScannedFile>     files;
  final int                   initialIndex;
  final void Function(String) onDelete;
  final void Function(String) onShare;

  const _ImageViewerScreen({
    required this.files,
    required this.initialIndex,
    required this.onDelete,
    required this.onShare,
  });

  @override
  State<_ImageViewerScreen> createState() =>
      _ImageViewerScreenState();
}

class _ImageViewerScreenState
    extends State<_ImageViewerScreen> {
  late final PageController _controller;
  late int               _index;
  late List<ScannedFile> _files;

  @override
  void initState() {
    super.initState();
    _files      = [...widget.files];
    _index      = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final file      = _files[_index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(T.of('deleteImage'),
            style: const TextStyle(color: Colors.white)),
        content: Text(
          '"${file.path.split('/').last}"\n${T.of('cannotBeUndoneShort')}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(T.of('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: _kDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(T.of('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    widget.onDelete(file.path);
    setState(() => _files.removeAt(_index));
    if (_files.isEmpty && mounted) {
      Navigator.of(context).pop();
    } else if (_index >= _files.length) {
      setState(() => _index = _files.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_files.isEmpty) return const SizedBox.shrink();
    final current = _files[_index];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          current.path.split('/').last,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => widget.onShare(current.path),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: PageView.builder(
        controller:    _controller,
        itemCount:     _files.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.file(
              File(_files[i].path),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white38,
                size:  64,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            '${_index + 1} / ${_files.length}  •  '
                '${FormatUtils.formatBytes(current.sizeBytes)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white54, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// ─── FULLSCREEN VIDEO PLAYER ──────────────────────────────────────────────────
class _VideoPlayerScreen extends StatefulWidget {
  final ScannedFile           file;
  final void Function(String) onDelete;
  final void Function(String) onShare;

  const _VideoPlayerScreen({
    required this.file,
    required this.onDelete,
    required this.onShare,
  });

  @override
  State<_VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState
    extends State<_VideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _ready  = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller =
    VideoPlayerController.file(File(widget.file.path))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      }).catchError((_) {
        if (mounted) setState(() => _failed = true);
      });
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(T.of('deleteVideo'),
            style: const TextStyle(color: Colors.white)),
        content: Text(
          '"${widget.file.path.split('/').last}"\n'
              '${T.of('cannotBeUndoneShort')}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(T.of('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: _kDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(T.of('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onDelete(widget.file.path);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.file.path.split('/').last,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () =>
                widget.onShare(widget.file.path),
          ),
          IconButton(
            icon:      const Icon(Icons.delete_outline_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: Center(
        child: _failed
            ? Text(
          T.of('videoPlaybackFailed'),
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        )
            : !_ready
            ? const CircularProgressIndicator(
            color: Colors.white)
            : GestureDetector(
          onTap: () => setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          }),
          child: AspectRatio(
            aspectRatio:
            _controller.value.aspectRatio == 0
                ? 16 / 9
                : _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                if (!_controller.value.isPlaying)
                  Container(
                    width:  64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _ready && !_failed
          ? SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor:     _kBlue,
              backgroundColor: Colors.white24,
              bufferedColor:   Colors.white38,
            ),
          ),
        ),
      )
          : null,
    );
  }
}

// ─── ACTIONS MENU ─────────────────────────────────────────────────────────────
class _FileActionsMenu extends StatelessWidget {
  final ScannedFile                   file;
  final void Function(String)         onDelete;
  final void Function(String, String) onRename;
  final void Function(String)         onShare;

  const _FileActionsMenu({
    required this.file,
    required this.onDelete,
    required this.onRename,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) =>
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert,
            size: 18, color: _iconMuted(context)),
        color: _cardColor(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        onSelected: (action) async {
          switch (action) {
            case 'share':
              onShare(file.path);
            case 'rename':
              final controller = TextEditingController(
                  text: file.path.split('/').last);
              final newName = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: _cardColor(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text(T.of('renameFile'),
                      style: TextStyle(
                          color: _textPrimary(context))),
                  content: TextField(
                    controller: controller,
                    autofocus:  true,
                    style: TextStyle(
                        color: _textPrimary(context)),
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: _dividerColor(context)),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(T.of('cancel')),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: _kBlue),
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text),
                      child: Text(T.of('rename')),
                    ),
                  ],
                ),
              );
              if (newName != null && newName.isNotEmpty) {
                onRename(file.path, newName);
              }
            case 'delete':
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: _cardColor(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text(T.of('deleteFile'),
                      style: TextStyle(
                          color: _textPrimary(context))),
                  content: Text(
                    '"${file.path.split('/').last}"\n'
                        '${T.of('cannotBeUndoneShort')}',
                    style: TextStyle(
                        color: _textSecondary(context)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(ctx, false),
                      child: Text(T.of('cancel')),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: _kDanger),
                      onPressed: () =>
                          Navigator.pop(ctx, true),
                      child: Text(T.of('delete')),
                    ),
                  ],
                ),
              );
              if (confirmed == true) onDelete(file.path);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'share',
            child: Text(T.of('share'),
                style:
                TextStyle(color: _textPrimary(context))),
          ),
          PopupMenuItem(
            value: 'rename',
            child: Text(T.of('rename'),
                style:
                TextStyle(color: _textPrimary(context))),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text(T.of('delete'),
                style:
                TextStyle(color: _textPrimary(context))),
          ),
        ],
      );
}

// ─── PERMISSION BODY ──────────────────────────────────────────────────────────
class _PermissionBody extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionBody({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_off_outlined,
              size: 72,
              color: Theme.of(context).brightness ==
                  Brightness.dark
                  ? Colors.white38
                  : Colors.grey),
          const SizedBox(height: 16),
          Text(
            T.of('storageAccess'),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15,
                color: _textSecondary(context)),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient:     _kBtnGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Text(
                T.of('grantAccess'),
                style: const TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── ERROR BODY ───────────────────────────────────────────────────────────────
class _ErrorBody extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorBody(
      {required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              size: 64, color: _kDanger),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary(context)),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient:     _kBtnGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Text(
                T.of('retry'),
                style: const TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}