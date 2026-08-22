// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DashboardState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)
        loaded,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)?
        loaded,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DashboardLoading value) loading,
    required TResult Function(DashboardLoaded value) loaded,
    required TResult Function(DashboardError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DashboardLoading value)? loading,
    TResult? Function(DashboardLoaded value)? loaded,
    TResult? Function(DashboardError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DashboardLoading value)? loading,
    TResult Function(DashboardLoaded value)? loaded,
    TResult Function(DashboardError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardStateCopyWith<$Res> {
  factory $DashboardStateCopyWith(
          DashboardState value, $Res Function(DashboardState) then) =
      _$DashboardStateCopyWithImpl<$Res, DashboardState>;
}

/// @nodoc
class _$DashboardStateCopyWithImpl<$Res, $Val extends DashboardState>
    implements $DashboardStateCopyWith<$Res> {
  _$DashboardStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$DashboardLoadingImplCopyWith<$Res> {
  factory _$$DashboardLoadingImplCopyWith(_$DashboardLoadingImpl value,
          $Res Function(_$DashboardLoadingImpl) then) =
      __$$DashboardLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DashboardLoadingImplCopyWithImpl<$Res>
    extends _$DashboardStateCopyWithImpl<$Res, _$DashboardLoadingImpl>
    implements _$$DashboardLoadingImplCopyWith<$Res> {
  __$$DashboardLoadingImplCopyWithImpl(_$DashboardLoadingImpl _value,
      $Res Function(_$DashboardLoadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$DashboardLoadingImpl implements DashboardLoading {
  const _$DashboardLoadingImpl();

  @override
  String toString() {
    return 'DashboardState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$DashboardLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)
        loaded,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DashboardLoading value) loading,
    required TResult Function(DashboardLoaded value) loaded,
    required TResult Function(DashboardError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DashboardLoading value)? loading,
    TResult? Function(DashboardLoaded value)? loaded,
    TResult? Function(DashboardError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DashboardLoading value)? loading,
    TResult Function(DashboardLoaded value)? loaded,
    TResult Function(DashboardError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class DashboardLoading implements DashboardState {
  const factory DashboardLoading() = _$DashboardLoadingImpl;
}

/// @nodoc
abstract class _$$DashboardLoadedImplCopyWith<$Res> {
  factory _$$DashboardLoadedImplCopyWith(_$DashboardLoadedImpl value,
          $Res Function(_$DashboardLoadedImpl) then) =
      __$$DashboardLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {double totalGB,
      double usedGB,
      double freeGB,
      double usedPercent,
      int? batteryPercent,
      int? installedAppCount});
}

/// @nodoc
class __$$DashboardLoadedImplCopyWithImpl<$Res>
    extends _$DashboardStateCopyWithImpl<$Res, _$DashboardLoadedImpl>
    implements _$$DashboardLoadedImplCopyWith<$Res> {
  __$$DashboardLoadedImplCopyWithImpl(
      _$DashboardLoadedImpl _value, $Res Function(_$DashboardLoadedImpl) _then)
      : super(_value, _then);

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalGB = null,
    Object? usedGB = null,
    Object? freeGB = null,
    Object? usedPercent = null,
    Object? batteryPercent = freezed,
    Object? installedAppCount = freezed,
  }) {
    return _then(_$DashboardLoadedImpl(
      totalGB: null == totalGB
          ? _value.totalGB
          : totalGB // ignore: cast_nullable_to_non_nullable
              as double,
      usedGB: null == usedGB
          ? _value.usedGB
          : usedGB // ignore: cast_nullable_to_non_nullable
              as double,
      freeGB: null == freeGB
          ? _value.freeGB
          : freeGB // ignore: cast_nullable_to_non_nullable
              as double,
      usedPercent: null == usedPercent
          ? _value.usedPercent
          : usedPercent // ignore: cast_nullable_to_non_nullable
              as double,
      batteryPercent: freezed == batteryPercent
          ? _value.batteryPercent
          : batteryPercent // ignore: cast_nullable_to_non_nullable
              as int?,
      installedAppCount: freezed == installedAppCount
          ? _value.installedAppCount
          : installedAppCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$DashboardLoadedImpl implements DashboardLoaded {
  const _$DashboardLoadedImpl(
      {required this.totalGB,
      required this.usedGB,
      required this.freeGB,
      required this.usedPercent,
      this.batteryPercent,
      this.installedAppCount});

  @override
  final double totalGB;
  @override
  final double usedGB;
  @override
  final double freeGB;
  @override
  final double usedPercent;
// Real reads only — both cheap enough to fetch on dashboard load
// without a full storage scan. Null when unavailable (e.g. iOS
// doesn't expose an app count the same way) rather than a fake 0.
  @override
  final int? batteryPercent;
  @override
  final int? installedAppCount;

  @override
  String toString() {
    return 'DashboardState.loaded(totalGB: $totalGB, usedGB: $usedGB, freeGB: $freeGB, usedPercent: $usedPercent, batteryPercent: $batteryPercent, installedAppCount: $installedAppCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardLoadedImpl &&
            (identical(other.totalGB, totalGB) || other.totalGB == totalGB) &&
            (identical(other.usedGB, usedGB) || other.usedGB == usedGB) &&
            (identical(other.freeGB, freeGB) || other.freeGB == freeGB) &&
            (identical(other.usedPercent, usedPercent) ||
                other.usedPercent == usedPercent) &&
            (identical(other.batteryPercent, batteryPercent) ||
                other.batteryPercent == batteryPercent) &&
            (identical(other.installedAppCount, installedAppCount) ||
                other.installedAppCount == installedAppCount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, totalGB, usedGB, freeGB,
      usedPercent, batteryPercent, installedAppCount);

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardLoadedImplCopyWith<_$DashboardLoadedImpl> get copyWith =>
      __$$DashboardLoadedImplCopyWithImpl<_$DashboardLoadedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)
        loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(totalGB, usedGB, freeGB, usedPercent, batteryPercent,
        installedAppCount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(totalGB, usedGB, freeGB, usedPercent, batteryPercent,
        installedAppCount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(totalGB, usedGB, freeGB, usedPercent, batteryPercent,
          installedAppCount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DashboardLoading value) loading,
    required TResult Function(DashboardLoaded value) loaded,
    required TResult Function(DashboardError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DashboardLoading value)? loading,
    TResult? Function(DashboardLoaded value)? loaded,
    TResult? Function(DashboardError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DashboardLoading value)? loading,
    TResult Function(DashboardLoaded value)? loaded,
    TResult Function(DashboardError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class DashboardLoaded implements DashboardState {
  const factory DashboardLoaded(
      {required final double totalGB,
      required final double usedGB,
      required final double freeGB,
      required final double usedPercent,
      final int? batteryPercent,
      final int? installedAppCount}) = _$DashboardLoadedImpl;

  double get totalGB;
  double get usedGB;
  double get freeGB;
  double
      get usedPercent; // Real reads only — both cheap enough to fetch on dashboard load
// without a full storage scan. Null when unavailable (e.g. iOS
// doesn't expose an app count the same way) rather than a fake 0.
  int? get batteryPercent;
  int? get installedAppCount;

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardLoadedImplCopyWith<_$DashboardLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DashboardErrorImplCopyWith<$Res> {
  factory _$$DashboardErrorImplCopyWith(_$DashboardErrorImpl value,
          $Res Function(_$DashboardErrorImpl) then) =
      __$$DashboardErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$DashboardErrorImplCopyWithImpl<$Res>
    extends _$DashboardStateCopyWithImpl<$Res, _$DashboardErrorImpl>
    implements _$$DashboardErrorImplCopyWith<$Res> {
  __$$DashboardErrorImplCopyWithImpl(
      _$DashboardErrorImpl _value, $Res Function(_$DashboardErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$DashboardErrorImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DashboardErrorImpl implements DashboardError {
  const _$DashboardErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'DashboardState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardErrorImplCopyWith<_$DashboardErrorImpl> get copyWith =>
      __$$DashboardErrorImplCopyWithImpl<_$DashboardErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)
        loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(double totalGB, double usedGB, double freeGB,
            double usedPercent, int? batteryPercent, int? installedAppCount)?
        loaded,
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
    required TResult Function(DashboardLoading value) loading,
    required TResult Function(DashboardLoaded value) loaded,
    required TResult Function(DashboardError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DashboardLoading value)? loading,
    TResult? Function(DashboardLoaded value)? loaded,
    TResult? Function(DashboardError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DashboardLoading value)? loading,
    TResult Function(DashboardLoaded value)? loaded,
    TResult Function(DashboardError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class DashboardError implements DashboardState {
  const factory DashboardError(final String message) = _$DashboardErrorImpl;

  String get message;

  /// Create a copy of DashboardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardErrorImplCopyWith<_$DashboardErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
