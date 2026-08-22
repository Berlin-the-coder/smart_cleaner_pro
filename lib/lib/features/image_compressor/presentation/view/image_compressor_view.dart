// image_compressor_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/utils/format_utils.dart';
import '../../domain/image_compressor_state.dart';
import '../viewmodel/image_compressor_viewmodel.dart';

const _kTeal = Color(0xFF00C2A8);

const _kGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF00C2A8), Color(0xFF2F6BFF)],
);

const _kBtnGradient = LinearGradient(
  colors: [Color(0xFF00C2A8), Color(0xFF008F7A)],
);

const _kDimensions = [640, 1280, 1920, 2560];

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
        : const Color(0xFFF0FDFB);

Color _textPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

Color _textSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black45;

Color _shadowColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.05);

Color _dimBtnUnselected(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A3A)
        : Colors.grey.shade100;

Color _placeholderBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A3A)
        : Colors.grey.shade100;

Color _dividerColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.black12;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

  Color _activeColor(int index) {
    switch (index) {
      case 1:  return const Color(0xFF2F6BFF);
      case 2:  return const Color(0xFF6C63FF);
      case 3:  return _kTeal;
      default: return const Color(0xFF2F6BFF);
    }
  }
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class ImageCompressorView extends ConsumerWidget {
  const ImageCompressorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageCompressorViewModelProvider);
    final vm    = ref.read(imageCompressorViewModelProvider.notifier);

    const navIndex = 1;

    return Scaffold(
      backgroundColor: _scaffoldColor(context),
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: state.when(
              idle: () => _IdleBody(onPick: vm.pickImages),
              picked: (images, quality, maxDim) => _PickedBody(
                images:           images,
                quality:          quality,
                maxDimension:     maxDim,
                onQualityChanged: vm.updateQuality,
                onDimChanged:     vm.updateMaxDimension,
                onPick:           vm.pickImages,
              ),
              error: (msg) => _CenterMsg(
                icon:       Icons.error_outline,
                iconColor:  Colors.red,
                message:    msg,
                buttonText: T.of('retry'),
                onTap:      vm.reset,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: state.maybeWhen(
        picked: (images, quality, maxDim) {
          final anyCompressing = images.any((i) => i.isCompressing);
          final allDone        = images.isNotEmpty &&
              images.every((i) => i.compressedPath != null);
          final anyPending =
          images.any((i) => i.compressedPath == null);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CompressBar(
                anyCompressing: anyCompressing,
                allDone:        allDone,
                anyPending:     anyPending,
                onCompress:     vm.compressAll,
                onPickNew: () {
                  vm.reset();
                  vm.pickImages();
                },
              ),
              const _BottomNav(currentIndex: navIndex),
            ],
          );
        },
        orElse: () => const _BottomNav(currentIndex: navIndex),
      ),
    );
  }
}

// ─── GRADIENT HEADER ──────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: _kGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width:  36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size:  20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    T.of('compressor'),
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    T.of('compressorSubtitle'),
                    style: const TextStyle(
                      color:    Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width:  90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.photo_size_select_large_rounded,
                color: Colors.white,
                size:  50,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── IDLE BODY ────────────────────────────────────────────────────────────────
class _IdleBody extends StatelessWidget {
  final VoidCallback onPick;
  const _IdleBody({required this.onPick});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  110,
            height: 110,
            decoration: BoxDecoration(
              color: _kTeal.withValues(
                  alpha: Theme.of(context).brightness ==
                      Brightness.dark
                      ? 0.18
                      : 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_size_select_large_rounded,
              size:  52,
              color: _kTeal,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            T.of('compressImages'),
            style: TextStyle(
              fontSize:   20,
              fontWeight: FontWeight.bold,
              color:      _textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            T.of('compressSub'),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: _textSecondary(context)),
          ),
          const SizedBox(height: 32),
          _GradientBtn(
            text:  T.of('pickImages'),
            icon:  Icons.photo_library_rounded,
            onTap: onPick,
          ),
        ],
      ),
    ),
  );
}

// ─── PICKED BODY ──────────────────────────────────────────────────────────────
class _PickedBody extends StatelessWidget {
  final List<CompressibleImage> images;
  final int                     quality;
  final int                     maxDimension;
  final void Function(int)      onQualityChanged;
  final void Function(int)      onDimChanged;
  final VoidCallback            onPick;

  const _PickedBody({
    required this.images,
    required this.quality,
    required this.maxDimension,
    required this.onQualityChanged,
    required this.onDimChanged,
    required this.onPick,
  });

  int get _totalOriginal =>
      images.fold<int>(0, (s, i) => s + i.originalBytes);
  int get _totalSaved =>
      images.fold<int>(0, (s, i) => s + i.savedBytes);
  bool get _allDone =>
      images.isNotEmpty &&
          images.every((i) => i.compressedPath != null);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        if (_allDone) ...[
          const SizedBox(height: 16),
          _SummaryCard(
            totalOriginal: _totalOriginal,
            totalSaved:    _totalSaved,
          ),
        ],
        const SizedBox(height: 16),
        _SettingsCard(
          quality:          quality,
          maxDimension:     maxDimension,
          onQualityChanged: onQualityChanged,
          onDimChanged:     onDimChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '${images.length} ${T.of('imagesSelected')}',
              style: TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.bold,
                color:      _textPrimary(context),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onPick,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kTeal.withValues(
                      alpha: Theme.of(context).brightness ==
                          Brightness.dark
                          ? 0.18
                          : 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: _kTeal, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      T.of('addMore'),
                      style: const TextStyle(
                        color:      _kTeal,
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...images.map((img) => _ImageTile(image: img)),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── SUMMARY CARD ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int totalOriginal;
  final int totalSaved;

  const _SummaryCard({
    required this.totalOriginal,
    required this.totalSaved,
  });

  double get _percent =>
      totalOriginal == 0
          ? 0
          : (totalSaved / totalOriginal) * 100;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient:     _kGradient,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color:      _kTeal.withValues(alpha: 0.3),
          blurRadius: 16,
          offset:     const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width:  56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Colors.white,
            size:  30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                T.of('spaceSaved'),
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                FormatUtils.formatBytes(totalSaved),
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_percent.toStringAsFixed(1)}% ${T.of('reduction')} '
                    '${FormatUtils.formatBytes(totalOriginal)}',
                style: const TextStyle(
                  color:    Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─── SETTINGS CARD ────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final int                quality;
  final int                maxDimension;
  final void Function(int) onQualityChanged;
  final void Function(int) onDimChanged;

  const _SettingsCard({
    required this.quality,
    required this.maxDimension,
    required this.onQualityChanged,
    required this.onDimChanged,
  });

  Color get _qualityColor {
    if (quality >= 80) return Colors.green;
    if (quality >= 50) return _kTeal;
    return Colors.orange;
  }

  String _qualityLabel() {
    if (quality >= 80) return T.of('highQuality');
    if (quality >= 50) return T.of('balanced');
    return T.of('maxCompression');
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            T.of('compressionSettings'),
            style: TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.bold,
              color:      _textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                T.of('quality'),
                style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary(context)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _qualityColor.withValues(
                      alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$quality% — ${_qualityLabel()}',
                  style: TextStyle(
                    color:      _qualityColor,
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _kTeal,
              inactiveTrackColor:
              _kTeal.withValues(alpha: isDark ? 0.30 : 0.20),
              thumbColor:   _kTeal,
              overlayColor: _kTeal.withValues(alpha: 0.1),
              trackHeight:  4,
            ),
            child: Slider(
              value:     quality.toDouble(),
              min:       10,
              max:       100,
              divisions: 18,
              onChanged: (v) => onQualityChanged(v.round()),
            ),
          ),
          Divider(height: 24, color: _dividerColor(context)),
          Text(
            T.of('maxDimension'),
            style: TextStyle(
                fontSize: 13,
                color: _textSecondary(context)),
          ),
          const SizedBox(height: 10),
          Row(
            children: _kDimensions.map((d) {
              final sel = maxDimension == d;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onDimChanged(d),
                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? _kTeal
                            : _dimBtnUnselected(context),
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${d}px',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: sel
                              ? Colors.white
                              : _textSecondary(context),
                          fontSize:   12,
                          fontWeight: sel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── IMAGE TILE ───────────────────────────────────────────────────────────────
class _ImageTile extends StatelessWidget {
  final CompressibleImage image;
  const _ImageTile({required this.image});

  double get _savingPercent {
    if (image.compressedBytes == null ||
        image.originalBytes == 0) return 0;
    return ((image.originalBytes - image.compressedBytes!) /
        image.originalBytes) *
        100;
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      _shadowColor(context),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── side-by-side previews ────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      _SafeFileImage(
                        path:   image.originalPath,
                        height: 140,
                      ),
                      Positioned(
                        top:  8,
                        left: 8,
                        child: _Badge(
                          label: T.of('original'),
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width:  2,
                  height: 140,
                  color: isDark
                      ? Colors.black
                      : Colors.white,
                ),
                Expanded(
                  child: image.isCompressing
                      ? Container(
                    height: 140,
                    color:  _placeholderBg(context),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color:       _kTeal,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            T.of('compressing'),
                            style: const TextStyle(
                              fontSize: 11,
                              color:    Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : image.compressedPath != null
                      ? Stack(
                    children: [
                      _SafeFileImage(
                        path:   image.compressedPath!,
                        height: 140,
                      ),
                      Positioned(
                        top:  8,
                        left: 8,
                        child: _Badge(
                          label: T.of('compressed'),
                          color: _kTeal,
                        ),
                      ),
                    ],
                  )
                      : Container(
                    height: 140,
                    color:  _placeholderBg(context),
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: isDark
                            ? Colors.white24
                            : Colors.black26,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── file info row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        image.originalPath.split('/').last,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      _textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FormatUtils.formatBytes(
                            image.originalBytes),
                        style: TextStyle(
                          fontSize: 11,
                          color:    _textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (image.compressedBytes != null) ...[
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: isDark
                        ? Colors.white24
                        : Colors.black26,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: [
                      Text(
                        FormatUtils.formatBytes(
                            image.compressedBytes!),
                        style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      _kTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(
                              alpha: isDark ? 0.18 : 0.10),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Text(
                          '-${_savingPercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize:   11,
                            color:      Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // ── Saved to Gallery strip ────────────────────────────────
          if (image.compressedPath != null)
            Container(
              margin:  const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(
                    alpha: Theme.of(context).brightness ==
                        Brightness.dark
                        ? 0.12
                        : 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.green.withValues(
                      alpha: Theme.of(context).brightness ==
                          Brightness.dark
                          ? 0.30
                          : 0.20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      T.of('savedToGallery'),
                      style: const TextStyle(
                        fontSize:   12,
                        color:      Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
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

// ─── SAFE FILE IMAGE ──────────────────────────────────────────────────────────
class _SafeFileImage extends StatelessWidget {
  final String path;
  final double height;

  const _SafeFileImage(
      {required this.path, required this.height});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) return _placeholder(context);

    return Image.file(
      file,
      height: height,
      width:  double.infinity,
      fit:    BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    height: height,
    width:  double.infinity,
    color:  _placeholderBg(context),
    child: Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white24
            : Colors.black26,
        size: 36,
      ),
    ),
  );
}

// ─── BADGE ────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:        color.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color:      Colors.white,
        fontSize:   10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// ─── GRADIENT BUTTON ──────────────────────────────────────────────────────────
class _GradientBtn extends StatelessWidget {
  final String        text;
  final IconData?     icon;
  final VoidCallback? onTap;

  const _GradientBtn(
      {required this.text, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 54,
      width:  double.infinity,
      decoration: BoxDecoration(
        gradient: onTap != null
            ? _kBtnGradient
            : const LinearGradient(
            colors: [Colors.grey, Colors.grey]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: onTap != null
            ? [
          BoxShadow(
            color:      _kTeal.withValues(alpha: 0.4),
            blurRadius: 14,
            offset:     const Offset(0, 5),
          ),
        ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── CENTER MESSAGE ───────────────────────────────────────────────────────────
class _CenterMsg extends StatelessWidget {
  final IconData     icon;
  final Color?       iconColor;
  final String       message;
  final String       buttonText;
  final VoidCallback onTap;

  const _CenterMsg({
    required this.icon,
    this.iconColor,
    required this.message,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size:  72,
              color: iconColor ??
                  (Theme.of(context).brightness ==
                      Brightness.dark
                      ? Colors.white38
                      : Colors.grey)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15,
                color: _textSecondary(context)),
          ),
          const SizedBox(height: 24),
          _GradientBtn(text: buttonText, onTap: onTap),
        ],
      ),
    ),
  );
}

// ─── COMPRESS BOTTOM BAR ──────────────────────────────────────────────────────
class _CompressBar extends StatelessWidget {
  final bool         anyCompressing;
  final bool         allDone;
  final bool         anyPending;
  final VoidCallback onCompress;
  final VoidCallback onPickNew;

  const _CompressBar({
    required this.anyCompressing,
    required this.allDone,
    required this.anyPending,
    required this.onCompress,
    required this.onPickNew,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: _surfaceColor(context),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).brightness ==
              Brightness.dark
              ? Colors.black.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset:     const Offset(0, -4),
        ),
      ],
    ),
    child: allDone
        ? _GradientBtn(
      text:  T.of('compressNewImage'),
      icon:  Icons.add_photo_alternate_rounded,
      onTap: onPickNew,
    )
        : _GradientBtn(
      text: anyCompressing
          ? T.of('compressing')
          : T.of('compressAndSave'),
      icon: anyCompressing
          ? null
          : Icons.compress_rounded,
      onTap: anyCompressing || !anyPending
          ? null
          : onCompress,
    ),
  );
}