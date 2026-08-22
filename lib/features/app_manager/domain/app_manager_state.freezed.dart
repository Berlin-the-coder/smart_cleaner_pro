// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_manager_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AppManagerState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(List<AppInfo> apps, AppSortOrder sortOrder)
        loaded,
    required TResult Function() unsupportedPlatform,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(List<AppInfo> apps, AppSortOrder sortOrder)? loaded,
    TResult? Function()? unsupportedPlatform,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(List<AppInfo> apps, AppSortOrder sortOrder)? loaded,
    TResult Function()? unsupportedPlatform,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppManagerLoading value) loading,
    required TResult Function(AppManagerLoaded value) loaded,
    required TResult Function(AppManagerUnsupportedPlatform value)
        unsupportedPlatform,
    required TResult Function(AppManagerError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppManagerLoading value)? loading,
    TResult? Function(AppManagerLoaded value)? loaded,
    TResult? Function(AppManagerUnsupportedPlatform value)? unsupportedPlatform,
    TResult? Function(AppManagerError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppManagerLoading value)? loading,
    TResult Function(AppManagerLoaded value)? loaded,
    TResult Function(AppManagerUnsupportedPlatform value)? unsupportedPlatform,
    TResult Function(AppManagerError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppManagerStateCopyWith<$Res> {
  factory $AppManagerStateCopyWith(
          AppManagerState value, $Res Function(AppManagerState) then) =
      _$AppManagerStateCopyWithImpl<$Res, AppManagerState>;
}

/// @nodoc
class _$AppManagerStateCopyWithImpl<$Res, $Val extends AppManagerState>
    implements $AppManagerStateCopyWith<$Res> {
  _$AppManagerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppManagerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AppManagerLoadingImplCopyWith<$Res> {
  factory _$$AppManagerLoadingImplCopyWith(_$AppManagerLoadingImpl value,
          $Res Function(_$AppManagerLoadingImpl) then) =
      __$$AppManagerLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AppManagerLoadingImplCopyWithImpl<$Res>
    extends _$AppManagerStateCopyWithImpl<$Res, _$AppManagerLoadingImpl>
    implements _$$AppManagerLoadingImplCopyWith<$Res> {
  __$$AppManagerLoadingImplCopyWithImpl(_$AppManagerLoadingImpl _value,
      $Res Function(_$AppManagerLoadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppManagerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AppManagerLoadingImpl implements AppManagerLoading {
  const _$AppManagerLoadingImpl();

  @override
  String toString() {
    return 'AppManagerState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AppManagerLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(List<AppInfo> apps, AppSortOrder sortOrder)
        loaded,
    required TResult Function() unsupportedPlatform,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(List<AppInfo> apps, AppSortOrder sortOrder)? loaded,
    TResult? Function()? unsupportedPlatform,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(List<AppInfo> apps, AppSortOrder sortOrder)? loaded,
    TResult Function()? unsupportedPlatform,
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
    required TResult Function(AppManagerLoading value) loading,
    required TResult Function(AppManagerLoaded value) loaded,
    required TResult Function(AppManagerUnsupportedPlatform value)
        unsupportedPlatform,
    required TResult Function(AppManagerError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppManagerLoading value)? loading,
    TResult? Function(AppManagerLoaded value)? loaded,
    TResult? Function(AppManagerUnsupportedPlatform value)? unsupportedPlatform,
    TResult? Function(AppManagerError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppManagerLoading value)? loading,
    TResult Function(AppManagerLoaded value)? loaded,
    TResult Function(AppManagerUnsupportedPlatform value)? unsupportedPlatform,
    TResult Function(AppManagerError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class AppManagerLoading implements AppManagerState {
  const factory AppManagerLoading() = _$AppManagerLoadingImpl;
}

/// @nodoc
abstract class _$$AppManagerLoadedImplCopyWith<$Res> {
  factory _$$AppManagerLoadedImplCopyWith(_$AppManagerLoadedImpl value,
          $Res Function(_$AppManagerLoadedImpl) then) =
      __$$AppManagerLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<AppInfo> apps, AppSortOrder sortOrder});
}

/// @nodoc
class __$$AppManagerLoadedImplCopyWithImpl<$Res>
    extends _$AppManagerStateCopyWithImpl<$Res, _$AppManagerLoadedImpl>
    implements _$$AppManagerLoadedImplCopyWith<$Res> {
  __$$AppManagerLoadedImplCopyWithImpl(_$AppManagerLoadedImpl _value,
      $Res Function(_$AppManagerLoadedImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppManagerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apps = null,
    Object? sortOrder = null,
  }) {
    return _then(_$AppManagerLoadedImpl(
      apps: null == apps
          ? _value._apps
          : apps // ignore: cast_nullable_to_non_nullable
              as List<AppInfo>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as AppSortOrder,
    ));
  }
}

/// @nodoc

class _$AppManagerLoadedImpl implements AppManagerLoaded {
  const _$AppManagerLoadedImpl(
      {required final List<AppInfo> apps, required this.sortOrder})
      : _apps = apps;

  final List<AppInfo> _apps;
  @override
  List<AppInfo> get apps {
    if (_apps is EqualUnmodifiableListView) return _apps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_apps);
  }

  @override
  final AppSortOrder sortOrder;

  @override
  String toString() {
    return 'AppManagerState.loaded(apps: $apps, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppManagerLoadedImpl &&
            const DeepCollectionEquality().equals(other._apps, _apps) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_apps), sortOrder);

  /// Create a copy of AppManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppManagerLoadedImplCopyWith<_$AppManagerLoadedImpl> get copyWith =>
      __$$AppManagerLoadedImplCopyWithImpl<_$AppManagerLoadedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(List<AppInfo> apps, AppSortOrder sortOrder)
        loaded,
    required TResult Function() unsupportedPlatform,
    required TResult Function(String message) error,
  }) {
    return loaded(apps, sortOrder);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(List<AppInfo> apps, AppSortOrder sortOrder)? loaded,
    TResult? Function()? unsupportedPlatform,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(apps, sortOrder);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(List<AppInfo> apps, AppSortOrder sortOrder)? loaded,
    TResult Function()? unsupportedPlatform,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(apps, sortOrder);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppManagerLoading value) loading,
    required TResult Function(AppManagerLoaded value) loaded,
    required TResult Function(AppManagerUnsupportedPlatform value)
        unsupportedPlatform,
    required TResult Function(AppManagerError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppManagerLoading value)? loading,
    TResult? Function(AppManagerLoaded value)? loaded,
    TResult? Function(AppManagerUnsupportedPlatform value)? unsupportedPlatform,
    TResult? Function(AppManagerError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppManagerLoading value)? loading,
    TResult Function(AppManagerLoaded value)? loaded,
    TResult Function(AppManagerUnsupportedPlatform value)? unsupportedPlatform,
    TResult Function(AppManagerError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class AppManagerLoaded implements AppManagerState {
  const factory AppManagerLoaded(
      {required final List<AppInfo> apps,
      required final AppSortOrder sortOrder}) = _$AppManagerLoadedImpl;

  List<AppInfo> get apps;
  AppSortOrder get sortOrder;

  /// Create a copy of AppManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppManagerLoadedImplCopyWith<_$AppManagerLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AppManagerUnsupportedPlatformImplCopyWith<$Res> {
  factory _$$AppManagerUnsupportedPlatformImplCopyWith(
          _$AppManagerUnsupportedPlatformImpl value,
          $Res Function(_$AppManagerUnsupportedPlatformImpl) then) =
      __$$AppManagerUnsupportedPlatformImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AppManagerUnsupportedPlatformImplCopyWithImpl<$Res>
    extends _$AppManagerStateCopyWithImpl<$Res,
        _$AppManagerUnsupportedPlatformImpl>
    implements _$$AppManagerUnsupportedPlatformImplCopyWith<$Res> {
  __$$AppManagerUnsupportedPlatformImplCopyWithImpl(
      _$AppManagerUnsupportedPlatformImpl _value,
      $Res Function(_$AppManagerUnsupportedPlatformImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppManagerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AppManagerUnsupportedPlatformImpl
    implements AppManagerUnsupportedPlatform {
  const _$AppManagerUnsupportedPlatformImpl();

  @override
  String toString() {
    return 'AppManagerState.unsupportedPlatform()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppManagerUnsupportedPlatformImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(List<AppInfo> apps, AppSortOrder sortOrder)
        loaded,
    required TResult Function() unsupportedPlatform,
    required TResult Function(String message) error,
  }) {
    return unsupportedPlatform();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(List<AppInfo> apps, AppSortOrder sortOrder)? loaded,
    TResult? Function()? unsupportedPlatform,
    TResult? Function(String message)? error,
  }) {
    return unsupportedPlatform?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(List<AppInfo> apps, AppSortOrder sortOrder)? loaded,
    TResult Function()? unsupportedPlatform,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (unsupportedPlatform != null) {
      return unsupportedPlatform();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppManagerLoading value) loading,
    required TResult Function(AppManagerLoaded value) loaded,
    required TResult Function(AppManagerUnsupportedPlatform value)
        unsupportedPlatform,
    required TResult Function(AppManagerError value) error,
  }) {
    return unsupportedPlatform(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppManagerLoading value)? loading,
    TResult? Function(AppManagerLoaded value)? loaded,
    TResult? Function(AppManagerUnsupportedPlatform value)? unsupportedPlatform,
    TResult? Function(AppManagerError value)? error,
  }) {
    return unsupportedPlatform?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppManagerLoading value)? loading,
    TResult Function(AppManagerLoaded value)? loaded,
    TResult Function(AppManagerUnsupportedPlatform value)? unsupportedPlatform,
    TResult Function(AppManagerError value)? error,
    required TResult orElse(),
  }) {
    if (unsupportedPlatform != null) {
      return unsupportedPlatform(this);
    }
    return orElse();
  }
}

abstract class AppManagerUnsupportedPlatform implements AppManagerState {
  const factory AppManagerUnsupportedPlatform() =
      _$AppManagerUnsupportedPlatformImpl;
}

/// @nodoc
abstract class _$$AppManagerErrorImplCopyWith<$Res> {
  factory _$$AppManagerErrorImplCopyWith(_$AppManagerErrorImpl value,
          $Res Function(_$AppManagerErrorImpl) then) =
      __$$AppManagerErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$AppManagerErrorImplCopyWithImpl<$Res>
    extends _$AppManagerStateCopyWithImpl<$Res, _$AppManagerErrorImpl>
    implements _$$AppManagerErrorImplCopyWith<$Res> {
  __$$AppManagerErrorImplCopyWithImpl(
      _$AppManagerErrorImpl _value, $Res Function(_$AppManagerErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppManagerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$AppManagerErrorImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$AppManagerErrorImpl implements AppManagerError {
  const _$AppManagerErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AppManagerState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppManagerErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AppManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppManagerErrorImplCopyWith<_$AppManagerErrorImpl> get copyWith =>
      __$$AppManagerErrorImplCopyWithImpl<_$AppManagerErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(List<AppInfo> apps, AppSortOrder sortOrder)
        loaded,
    required TResult Function() unsupportedPlatform,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(List<AppInfo> apps, AppSortOrder sortOrder)? loaded,
    TResult? Function()? unsupportedPlatform,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(List<AppInfo> apps, AppSortOrder sortOrder)? loaded,
    TResult Function()? unsupportedPlatform,
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
    required TResult Function(AppManagerLoading value) loading,
    required TResult Function(AppManagerLoaded value) loaded,
    required TResult Function(AppManagerUnsupportedPlatform value)
        unsupportedPlatform,
    required TResult Function(AppManagerError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppManagerLoading value)? loading,
    TResult? Function(AppManagerLoaded value)? loaded,
    TResult? Function(AppManagerUnsupportedPlatform value)? unsupportedPlatform,
    TResult? Function(AppManagerError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppManagerLoading value)? loading,
    TResult Function(AppManagerLoaded value)? loaded,
    TResult Function(AppManagerUnsupportedPlatform value)? unsupportedPlatform,
    TResult Function(AppManagerError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class AppManagerError implements AppManagerState {
  const factory AppManagerError(final String message) = _$AppManagerErrorImpl;

  String get message;

  /// Create a copy of AppManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppManagerErrorImplCopyWith<_$AppManagerErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
