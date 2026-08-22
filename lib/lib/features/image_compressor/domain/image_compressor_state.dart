import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_compressor_state.freezed.dart';

/// One image the user has picked, tracked through pick -> compress ->
/// done so the UI can show original vs. compressed size per item.
class CompressibleImage {
  final String originalPath;
  final int originalBytes;
  final String? compressedPath;
  final int? compressedBytes;
  final bool isCompressing;

  const CompressibleImage({
    required this.originalPath,
    required this.originalBytes,
    this.compressedPath,
    this.compressedBytes,
    this.isCompressing = false,
  });

  int get savedBytes =>
      compressedBytes == null ? 0 : (originalBytes - compressedBytes!);

  CompressibleImage copyWith({
    String? compressedPath,
    int? compressedBytes,
    bool? isCompressing,
  }) {
    return CompressibleImage(
      originalPath: originalPath,
      originalBytes: originalBytes,
      compressedPath: compressedPath ?? this.compressedPath,
      compressedBytes: compressedBytes ?? this.compressedBytes,
      isCompressing: isCompressing ?? this.isCompressing,
    );
  }
}

@freezed
class ImageCompressorState with _$ImageCompressorState {
  const factory ImageCompressorState.idle() = ImageCompressorIdle;
  const factory ImageCompressorState.picked({
    required List<CompressibleImage> images,
    required int quality, // 10-100
    required int maxDimension, // px, longest side
  }) = ImageCompressorPicked;
  const factory ImageCompressorState.error(String message) =
      ImageCompressorError;
}
