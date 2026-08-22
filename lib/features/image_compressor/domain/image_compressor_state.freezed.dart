// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_compressor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ImageCompressorState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(
            List<CompressibleImage> images, int quality, int maxDimension)
        picked,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
            List<CompressibleImage> images, int quality, int maxDimension)?
        picked,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
            List<CompressibleImage> images, int quality, int maxDimension)?
        picked,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ImageCompressorIdle value) idle,
    required TResult Function(ImageCompressorPicked value) picked,
    required TResult Function(ImageCompressorError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ImageCompressorIdle value)? idle,
    TResult? Function(ImageCompressorPicked value)? picked,
    TResult? Function(ImageCompressorError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ImageCompressorIdle value)? idle,
    TResult Function(ImageCompressorPicked value)? picked,
    TResult Function(ImageCompressorError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImageCompressorStateCopyWith<$Res> {
  factory $ImageCompressorStateCopyWith(ImageCompressorState value,
          $Res Function(ImageCompressorState) then) =
      _$ImageCompressorStateCopyWithImpl<$Res, ImageCompressorState>;
}

/// @nodoc
class _$ImageCompressorStateCopyWithImpl<$Res,
        $Val extends ImageCompressorState>
    implements $ImageCompressorStateCopyWith<$Res> {
  _$ImageCompressorStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImageCompressorState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ImageCompressorIdleImplCopyWith<$Res> {
  factory _$$ImageCompressorIdleImplCopyWith(_$ImageCompressorIdleImpl value,
          $Res Function(_$ImageCompressorIdleImpl) then) =
      __$$ImageCompressorIdleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ImageCompressorIdleImplCopyWithImpl<$Res>
    extends _$ImageCompressorStateCopyWithImpl<$Res, _$ImageCompressorIdleImpl>
    implements _$$ImageCompressorIdleImplCopyWith<$Res> {
  __$$ImageCompressorIdleImplCopyWithImpl(_$ImageCompressorIdleImpl _value,
      $Res Function(_$ImageCompressorIdleImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImageCompressorState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ImageCompressorIdleImpl implements ImageCompressorIdle {
  const _$ImageCompressorIdleImpl();

  @override
  String toString() {
    return 'ImageCompressorState.idle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageCompressorIdleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(
            List<CompressibleImage> images, int quality, int maxDimension)
        picked,
    required TResult Function(String message) error,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
            List<CompressibleImage> images, int quality, int maxDimension)?
        picked,
    TResult? Function(String message)? error,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
            List<CompressibleImage> images, int quality, int maxDimension)?
        picked,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ImageCompressorIdle value) idle,
    required TResult Function(ImageCompressorPicked value) picked,
    required TResult Function(ImageCompressorError value) error,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ImageCompressorIdle value)? idle,
    TResult? Function(ImageCompressorPicked value)? picked,
    TResult? Function(ImageCompressorError value)? error,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ImageCompressorIdle value)? idle,
    TResult Function(ImageCompressorPicked value)? picked,
    TResult Function(ImageCompressorError value)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class ImageCompressorIdle implements ImageCompressorState {
  const factory ImageCompressorIdle() = _$ImageCompressorIdleImpl;
}

/// @nodoc
abstract class _$$ImageCompressorPickedImplCopyWith<$Res> {
  factory _$$ImageCompressorPickedImplCopyWith(
          _$ImageCompressorPickedImpl value,
          $Res Function(_$ImageCompressorPickedImpl) then) =
      __$$ImageCompressorPickedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<CompressibleImage> images, int quality, int maxDimension});
}

/// @nodoc
class __$$ImageCompressorPickedImplCopyWithImpl<$Res>
    extends _$ImageCompressorStateCopyWithImpl<$Res,
        _$ImageCompressorPickedImpl>
    implements _$$ImageCompressorPickedImplCopyWith<$Res> {
  __$$ImageCompressorPickedImplCopyWithImpl(_$ImageCompressorPickedImpl _value,
      $Res Function(_$ImageCompressorPickedImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImageCompressorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? images = null,
    Object? quality = null,
    Object? maxDimension = null,
  }) {
    return _then(_$ImageCompressorPickedImpl(
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<CompressibleImage>,
      quality: null == quality
          ? _value.quality
          : quality // ignore: cast_nullable_to_non_nullable
              as int,
      maxDimension: null == maxDimension
          ? _value.maxDimension
          : maxDimension // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$ImageCompressorPickedImpl implements ImageCompressorPicked {
  const _$ImageCompressorPickedImpl(
      {required final List<CompressibleImage> images,
      required this.quality,
      required this.maxDimension})
      : _images = images;

  final List<CompressibleImage> _images;
  @override
  List<CompressibleImage> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  final int quality;
// 10-100
  @override
  final int maxDimension;

  @override
  String toString() {
    return 'ImageCompressorState.picked(images: $images, quality: $quality, maxDimension: $maxDimension)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageCompressorPickedImpl &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.quality, quality) || other.quality == quality) &&
            (identical(other.maxDimension, maxDimension) ||
                other.maxDimension == maxDimension));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_images), quality, maxDimension);

  /// Create a copy of ImageCompressorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageCompressorPickedImplCopyWith<_$ImageCompressorPickedImpl>
      get copyWith => __$$ImageCompressorPickedImplCopyWithImpl<
          _$ImageCompressorPickedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(
            List<CompressibleImage> images, int quality, int maxDimension)
        picked,
    required TResult Function(String message) error,
  }) {
    return picked(images, quality, maxDimension);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
            List<CompressibleImage> images, int quality, int maxDimension)?
        picked,
    TResult? Function(String message)? error,
  }) {
    return picked?.call(images, quality, maxDimension);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
            List<CompressibleImage> images, int quality, int maxDimension)?
        picked,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (picked != null) {
      return picked(images, quality, maxDimension);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ImageCompressorIdle value) idle,
    required TResult Function(ImageCompressorPicked value) picked,
    required TResult Function(ImageCompressorError value) error,
  }) {
    return picked(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ImageCompressorIdle value)? idle,
    TResult? Function(ImageCompressorPicked value)? picked,
    TResult? Function(ImageCompressorError value)? error,
  }) {
    return picked?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ImageCompressorIdle value)? idle,
    TResult Function(ImageCompressorPicked value)? picked,
    TResult Function(ImageCompressorError value)? error,
    required TResult orElse(),
  }) {
    if (picked != null) {
      return picked(this);
    }
    return orElse();
  }
}

abstract class ImageCompressorPicked implements ImageCompressorState {
  const factory ImageCompressorPicked(
      {required final List<CompressibleImage> images,
      required final int quality,
      required final int maxDimension}) = _$ImageCompressorPickedImpl;

  List<CompressibleImage> get images;
  int get quality; // 10-100
  int get maxDimension;

  /// Create a copy of ImageCompressorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImageCompressorPickedImplCopyWith<_$ImageCompressorPickedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ImageCompressorErrorImplCopyWith<$Res> {
  factory _$$ImageCompressorErrorImplCopyWith(_$ImageCompressorErrorImpl value,
          $Res Function(_$ImageCompressorErrorImpl) then) =
      __$$ImageCompressorErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ImageCompressorErrorImplCopyWithImpl<$Res>
    extends _$ImageCompressorStateCopyWithImpl<$Res, _$ImageCompressorErrorImpl>
    implements _$$ImageCompressorErrorImplCopyWith<$Res> {
  __$$ImageCompressorErrorImplCopyWithImpl(_$ImageCompressorErrorImpl _value,
      $Res Function(_$ImageCompressorErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImageCompressorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ImageCompressorErrorImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ImageCompressorErrorImpl implements ImageCompressorError {
  const _$ImageCompressorErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'ImageCompressorState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageCompressorErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of ImageCompressorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageCompressorErrorImplCopyWith<_$ImageCompressorErrorImpl>
      get copyWith =>
          __$$ImageCompressorErrorImplCopyWithImpl<_$ImageCompressorErrorImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(
            List<CompressibleImage> images, int quality, int maxDimension)
        picked,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(
            List<CompressibleImage> images, int quality, int maxDimension)?
        picked,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(
            List<CompressibleImage> images, int quality, int maxDimension)?
        picked,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ImageCompressorIdle value) idle,
    required TResult Function(ImageCompressorPicked value) picked,
    required TResult Function(ImageCompressorError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ImageCompressorIdle value)? idle,
    TResult? Function(ImageCompressorPicked value)? picked,
    TResult? Function(ImageCompressorError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ImageCompressorIdle value)? idle,
    TResult Function(ImageCompressorPicked value)? picked,
    TResult Function(ImageCompressorError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class ImageCompressorError implements ImageCompressorState {
  const factory ImageCompressorError(final String message) =
      _$ImageCompressorErrorImpl;

  String get message;

  /// Create a copy of ImageCompressorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImageCompressorErrorImplCopyWith<_$ImageCompressorErrorImpl>
      get copyWith => throw _privateConstructorUsedError;
}
