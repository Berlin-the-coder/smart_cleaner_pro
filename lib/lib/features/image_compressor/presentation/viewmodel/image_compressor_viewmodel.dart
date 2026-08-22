import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/image_compressor_repository.dart';
import '../../domain/image_compressor_state.dart';

final imageCompressorRepositoryProvider =
    Provider<ImageCompressorRepository>((ref) {
  return ImageCompressorRepositoryImpl();
});

final imageCompressorViewModelProvider = StateNotifierProvider<
    ImageCompressorViewModel, ImageCompressorState>((ref) {
  return ImageCompressorViewModel(ref.watch(imageCompressorRepositoryProvider));
});

class ImageCompressorViewModel extends StateNotifier<ImageCompressorState> {
  final ImageCompressorRepository _repository;

  ImageCompressorViewModel(this._repository)
      : super(const ImageCompressorState.idle());

  Future<void> pickImages() async {
    try {
      final paths = await _repository.pickImages();
      if (paths.isEmpty) return;

      final images = <CompressibleImage>[];
      for (final path in paths) {
        final size = await _repository.fileSize(path);
        images.add(CompressibleImage(originalPath: path, originalBytes: size));
      }

      state = ImageCompressorState.picked(
        images: images,
        quality: 70,
        maxDimension: 1920,
      );
    } catch (e) {
      state = ImageCompressorState.error('Failed to pick images: $e');
    }
  }

  void updateQuality(int quality) {
    final current = state;
    if (current is! ImageCompressorPicked) return;
    state = ImageCompressorState.picked(
      images: current.images,
      quality: quality,
      maxDimension: current.maxDimension,
    );
  }

  void updateMaxDimension(int maxDimension) {
    final current = state;
    if (current is! ImageCompressorPicked) return;
    state = ImageCompressorState.picked(
      images: current.images,
      quality: current.quality,
      maxDimension: maxDimension,
    );
  }

  Future<void> compressAll() async {
    final current = state;
    if (current is! ImageCompressorPicked) return;

    for (var i = 0; i < current.images.length; i++) {
      await _compressAt(i);
    }
  }

  Future<void> _compressAt(int index) async {
    final current = state;
    if (current is! ImageCompressorPicked) return;

    _setImageAt(index, current.images[index].copyWith(isCompressing: true));

    final result = await _repository.compress(
      sourcePath: current.images[index].originalPath,
      quality: current.quality,
      maxDimension: current.maxDimension,
    );

    if (result == null) {
      _setImageAt(
        index,
        (state as ImageCompressorPicked).images[index].copyWith(isCompressing: false),
      );
      return;
    }

    final compressedSize = await _repository.fileSize(result);
    _setImageAt(
      index,
      (state as ImageCompressorPicked).images[index].copyWith(
            compressedPath: result,
            compressedBytes: compressedSize,
            isCompressing: false,
          ),
    );
  }

  void _setImageAt(int index, CompressibleImage updated) {
    final current = state;
    if (current is! ImageCompressorPicked) return;
    final images = [...current.images];
    images[index] = updated;
    state = ImageCompressorState.picked(
      images: images,
      quality: current.quality,
      maxDimension: current.maxDimension,
    );
  }

  void reset() => state = const ImageCompressorState.idle();
}
