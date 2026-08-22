// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_manager_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FileManagerState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() overviewLoading,
    required TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)
        overview,
    required TResult Function() permissionRequired,
    required TResult Function(FileCategory category) loading,
    required TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)
        loaded,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? overviewLoading,
    TResult? Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult? Function()? permissionRequired,
    TResult? Function(FileCategory category)? loading,
    TResult? Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? overviewLoading,
    TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult Function()? permissionRequired,
    TResult Function(FileCategory category)? loading,
    TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FileManagerOverviewLoading value) overviewLoading,
    required TResult Function(FileManagerOverview value) overview,
    required TResult Function(FileManagerPermissionRequired value)
        permissionRequired,
    required TResult Function(FileManagerLoading value) loading,
    required TResult Function(FileManagerLoaded value) loaded,
    required TResult Function(FileManagerError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult? Function(FileManagerOverview value)? overview,
    TResult? Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult? Function(FileManagerLoading value)? loading,
    TResult? Function(FileManagerLoaded value)? loaded,
    TResult? Function(FileManagerError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult Function(FileManagerOverview value)? overview,
    TResult Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult Function(FileManagerLoading value)? loading,
    TResult Function(FileManagerLoaded value)? loaded,
    TResult Function(FileManagerError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileManagerStateCopyWith<$Res> {
  factory $FileManagerStateCopyWith(
          FileManagerState value, $Res Function(FileManagerState) then) =
      _$FileManagerStateCopyWithImpl<$Res, FileManagerState>;
}

/// @nodoc
class _$FileManagerStateCopyWithImpl<$Res, $Val extends FileManagerState>
    implements $FileManagerStateCopyWith<$Res> {
  _$FileManagerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$FileManagerOverviewLoadingImplCopyWith<$Res> {
  factory _$$FileManagerOverviewLoadingImplCopyWith(
          _$FileManagerOverviewLoadingImpl value,
          $Res Function(_$FileManagerOverviewLoadingImpl) then) =
      __$$FileManagerOverviewLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$FileManagerOverviewLoadingImplCopyWithImpl<$Res>
    extends _$FileManagerStateCopyWithImpl<$Res,
        _$FileManagerOverviewLoadingImpl>
    implements _$$FileManagerOverviewLoadingImplCopyWith<$Res> {
  __$$FileManagerOverviewLoadingImplCopyWithImpl(
      _$FileManagerOverviewLoadingImpl _value,
      $Res Function(_$FileManagerOverviewLoadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$FileManagerOverviewLoadingImpl implements FileManagerOverviewLoading {
  const _$FileManagerOverviewLoadingImpl();

  @override
  String toString() {
    return 'FileManagerState.overviewLoading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileManagerOverviewLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() overviewLoading,
    required TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)
        overview,
    required TResult Function() permissionRequired,
    required TResult Function(FileCategory category) loading,
    required TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)
        loaded,
    required TResult Function(String message) error,
  }) {
    return overviewLoading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? overviewLoading,
    TResult? Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult? Function()? permissionRequired,
    TResult? Function(FileCategory category)? loading,
    TResult? Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return overviewLoading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? overviewLoading,
    TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult Function()? permissionRequired,
    TResult Function(FileCategory category)? loading,
    TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (overviewLoading != null) {
      return overviewLoading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FileManagerOverviewLoading value) overviewLoading,
    required TResult Function(FileManagerOverview value) overview,
    required TResult Function(FileManagerPermissionRequired value)
        permissionRequired,
    required TResult Function(FileManagerLoading value) loading,
    required TResult Function(FileManagerLoaded value) loaded,
    required TResult Function(FileManagerError value) error,
  }) {
    return overviewLoading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult? Function(FileManagerOverview value)? overview,
    TResult? Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult? Function(FileManagerLoading value)? loading,
    TResult? Function(FileManagerLoaded value)? loaded,
    TResult? Function(FileManagerError value)? error,
  }) {
    return overviewLoading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult Function(FileManagerOverview value)? overview,
    TResult Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult Function(FileManagerLoading value)? loading,
    TResult Function(FileManagerLoaded value)? loaded,
    TResult Function(FileManagerError value)? error,
    required TResult orElse(),
  }) {
    if (overviewLoading != null) {
      return overviewLoading(this);
    }
    return orElse();
  }
}

abstract class FileManagerOverviewLoading implements FileManagerState {
  const factory FileManagerOverviewLoading() = _$FileManagerOverviewLoadingImpl;
}

/// @nodoc
abstract class _$$FileManagerOverviewImplCopyWith<$Res> {
  factory _$$FileManagerOverviewImplCopyWith(_$FileManagerOverviewImpl value,
          $Res Function(_$FileManagerOverviewImpl) then) =
      __$$FileManagerOverviewImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {List<CategorySummary> categories,
      int usedBytes,
      int totalBytes,
      String? searchQuery,
      List<ScannedFile>? searchResults});
}

/// @nodoc
class __$$FileManagerOverviewImplCopyWithImpl<$Res>
    extends _$FileManagerStateCopyWithImpl<$Res, _$FileManagerOverviewImpl>
    implements _$$FileManagerOverviewImplCopyWith<$Res> {
  __$$FileManagerOverviewImplCopyWithImpl(_$FileManagerOverviewImpl _value,
      $Res Function(_$FileManagerOverviewImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
    Object? usedBytes = null,
    Object? totalBytes = null,
    Object? searchQuery = freezed,
    Object? searchResults = freezed,
  }) {
    return _then(_$FileManagerOverviewImpl(
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<CategorySummary>,
      usedBytes: null == usedBytes
          ? _value.usedBytes
          : usedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      totalBytes: null == totalBytes
          ? _value.totalBytes
          : totalBytes // ignore: cast_nullable_to_non_nullable
              as int,
      searchQuery: freezed == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String?,
      searchResults: freezed == searchResults
          ? _value._searchResults
          : searchResults // ignore: cast_nullable_to_non_nullable
              as List<ScannedFile>?,
    ));
  }
}

/// @nodoc

class _$FileManagerOverviewImpl implements FileManagerOverview {
  const _$FileManagerOverviewImpl(
      {required final List<CategorySummary> categories,
      required this.usedBytes,
      required this.totalBytes,
      this.searchQuery,
      final List<ScannedFile>? searchResults})
      : _categories = categories,
        _searchResults = searchResults;

  final List<CategorySummary> _categories;
  @override
  List<CategorySummary> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  final int usedBytes;
  @override
  final int totalBytes;
  @override
  final String? searchQuery;
  final List<ScannedFile>? _searchResults;
  @override
  List<ScannedFile>? get searchResults {
    final value = _searchResults;
    if (value == null) return null;
    if (_searchResults is EqualUnmodifiableListView) return _searchResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'FileManagerState.overview(categories: $categories, usedBytes: $usedBytes, totalBytes: $totalBytes, searchQuery: $searchQuery, searchResults: $searchResults)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileManagerOverviewImpl &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            (identical(other.usedBytes, usedBytes) ||
                other.usedBytes == usedBytes) &&
            (identical(other.totalBytes, totalBytes) ||
                other.totalBytes == totalBytes) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            const DeepCollectionEquality()
                .equals(other._searchResults, _searchResults));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_categories),
      usedBytes,
      totalBytes,
      searchQuery,
      const DeepCollectionEquality().hash(_searchResults));

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileManagerOverviewImplCopyWith<_$FileManagerOverviewImpl> get copyWith =>
      __$$FileManagerOverviewImplCopyWithImpl<_$FileManagerOverviewImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() overviewLoading,
    required TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)
        overview,
    required TResult Function() permissionRequired,
    required TResult Function(FileCategory category) loading,
    required TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)
        loaded,
    required TResult Function(String message) error,
  }) {
    return overview(
        categories, usedBytes, totalBytes, searchQuery, searchResults);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? overviewLoading,
    TResult? Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult? Function()? permissionRequired,
    TResult? Function(FileCategory category)? loading,
    TResult? Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return overview?.call(
        categories, usedBytes, totalBytes, searchQuery, searchResults);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? overviewLoading,
    TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult Function()? permissionRequired,
    TResult Function(FileCategory category)? loading,
    TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (overview != null) {
      return overview(
          categories, usedBytes, totalBytes, searchQuery, searchResults);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FileManagerOverviewLoading value) overviewLoading,
    required TResult Function(FileManagerOverview value) overview,
    required TResult Function(FileManagerPermissionRequired value)
        permissionRequired,
    required TResult Function(FileManagerLoading value) loading,
    required TResult Function(FileManagerLoaded value) loaded,
    required TResult Function(FileManagerError value) error,
  }) {
    return overview(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult? Function(FileManagerOverview value)? overview,
    TResult? Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult? Function(FileManagerLoading value)? loading,
    TResult? Function(FileManagerLoaded value)? loaded,
    TResult? Function(FileManagerError value)? error,
  }) {
    return overview?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult Function(FileManagerOverview value)? overview,
    TResult Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult Function(FileManagerLoading value)? loading,
    TResult Function(FileManagerLoaded value)? loaded,
    TResult Function(FileManagerError value)? error,
    required TResult orElse(),
  }) {
    if (overview != null) {
      return overview(this);
    }
    return orElse();
  }
}

abstract class FileManagerOverview implements FileManagerState {
  const factory FileManagerOverview(
      {required final List<CategorySummary> categories,
      required final int usedBytes,
      required final int totalBytes,
      final String? searchQuery,
      final List<ScannedFile>? searchResults}) = _$FileManagerOverviewImpl;

  List<CategorySummary> get categories;
  int get usedBytes;
  int get totalBytes;
  String? get searchQuery;
  List<ScannedFile>? get searchResults;

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileManagerOverviewImplCopyWith<_$FileManagerOverviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FileManagerPermissionRequiredImplCopyWith<$Res> {
  factory _$$FileManagerPermissionRequiredImplCopyWith(
          _$FileManagerPermissionRequiredImpl value,
          $Res Function(_$FileManagerPermissionRequiredImpl) then) =
      __$$FileManagerPermissionRequiredImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$FileManagerPermissionRequiredImplCopyWithImpl<$Res>
    extends _$FileManagerStateCopyWithImpl<$Res,
        _$FileManagerPermissionRequiredImpl>
    implements _$$FileManagerPermissionRequiredImplCopyWith<$Res> {
  __$$FileManagerPermissionRequiredImplCopyWithImpl(
      _$FileManagerPermissionRequiredImpl _value,
      $Res Function(_$FileManagerPermissionRequiredImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$FileManagerPermissionRequiredImpl
    implements FileManagerPermissionRequired {
  const _$FileManagerPermissionRequiredImpl();

  @override
  String toString() {
    return 'FileManagerState.permissionRequired()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileManagerPermissionRequiredImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() overviewLoading,
    required TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)
        overview,
    required TResult Function() permissionRequired,
    required TResult Function(FileCategory category) loading,
    required TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)
        loaded,
    required TResult Function(String message) error,
  }) {
    return permissionRequired();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? overviewLoading,
    TResult? Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult? Function()? permissionRequired,
    TResult? Function(FileCategory category)? loading,
    TResult? Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return permissionRequired?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? overviewLoading,
    TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult Function()? permissionRequired,
    TResult Function(FileCategory category)? loading,
    TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (permissionRequired != null) {
      return permissionRequired();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FileManagerOverviewLoading value) overviewLoading,
    required TResult Function(FileManagerOverview value) overview,
    required TResult Function(FileManagerPermissionRequired value)
        permissionRequired,
    required TResult Function(FileManagerLoading value) loading,
    required TResult Function(FileManagerLoaded value) loaded,
    required TResult Function(FileManagerError value) error,
  }) {
    return permissionRequired(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult? Function(FileManagerOverview value)? overview,
    TResult? Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult? Function(FileManagerLoading value)? loading,
    TResult? Function(FileManagerLoaded value)? loaded,
    TResult? Function(FileManagerError value)? error,
  }) {
    return permissionRequired?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult Function(FileManagerOverview value)? overview,
    TResult Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult Function(FileManagerLoading value)? loading,
    TResult Function(FileManagerLoaded value)? loaded,
    TResult Function(FileManagerError value)? error,
    required TResult orElse(),
  }) {
    if (permissionRequired != null) {
      return permissionRequired(this);
    }
    return orElse();
  }
}

abstract class FileManagerPermissionRequired implements FileManagerState {
  const factory FileManagerPermissionRequired() =
      _$FileManagerPermissionRequiredImpl;
}

/// @nodoc
abstract class _$$FileManagerLoadingImplCopyWith<$Res> {
  factory _$$FileManagerLoadingImplCopyWith(_$FileManagerLoadingImpl value,
          $Res Function(_$FileManagerLoadingImpl) then) =
      __$$FileManagerLoadingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({FileCategory category});
}

/// @nodoc
class __$$FileManagerLoadingImplCopyWithImpl<$Res>
    extends _$FileManagerStateCopyWithImpl<$Res, _$FileManagerLoadingImpl>
    implements _$$FileManagerLoadingImplCopyWith<$Res> {
  __$$FileManagerLoadingImplCopyWithImpl(_$FileManagerLoadingImpl _value,
      $Res Function(_$FileManagerLoadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
  }) {
    return _then(_$FileManagerLoadingImpl(
      null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as FileCategory,
    ));
  }
}

/// @nodoc

class _$FileManagerLoadingImpl implements FileManagerLoading {
  const _$FileManagerLoadingImpl(this.category);

  @override
  final FileCategory category;

  @override
  String toString() {
    return 'FileManagerState.loading(category: $category)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileManagerLoadingImpl &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @override
  int get hashCode => Object.hash(runtimeType, category);

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileManagerLoadingImplCopyWith<_$FileManagerLoadingImpl> get copyWith =>
      __$$FileManagerLoadingImplCopyWithImpl<_$FileManagerLoadingImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() overviewLoading,
    required TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)
        overview,
    required TResult Function() permissionRequired,
    required TResult Function(FileCategory category) loading,
    required TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)
        loaded,
    required TResult Function(String message) error,
  }) {
    return loading(category);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? overviewLoading,
    TResult? Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult? Function()? permissionRequired,
    TResult? Function(FileCategory category)? loading,
    TResult? Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call(category);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? overviewLoading,
    TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult Function()? permissionRequired,
    TResult Function(FileCategory category)? loading,
    TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(category);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FileManagerOverviewLoading value) overviewLoading,
    required TResult Function(FileManagerOverview value) overview,
    required TResult Function(FileManagerPermissionRequired value)
        permissionRequired,
    required TResult Function(FileManagerLoading value) loading,
    required TResult Function(FileManagerLoaded value) loaded,
    required TResult Function(FileManagerError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult? Function(FileManagerOverview value)? overview,
    TResult? Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult? Function(FileManagerLoading value)? loading,
    TResult? Function(FileManagerLoaded value)? loaded,
    TResult? Function(FileManagerError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult Function(FileManagerOverview value)? overview,
    TResult Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult Function(FileManagerLoading value)? loading,
    TResult Function(FileManagerLoaded value)? loaded,
    TResult Function(FileManagerError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class FileManagerLoading implements FileManagerState {
  const factory FileManagerLoading(final FileCategory category) =
      _$FileManagerLoadingImpl;

  FileCategory get category;

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileManagerLoadingImplCopyWith<_$FileManagerLoadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FileManagerLoadedImplCopyWith<$Res> {
  factory _$$FileManagerLoadedImplCopyWith(_$FileManagerLoadedImpl value,
          $Res Function(_$FileManagerLoadedImpl) then) =
      __$$FileManagerLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {FileCategory category,
      List<ScannedFile> files,
      FileSortBy sortBy,
      FileViewMode viewMode});
}

/// @nodoc
class __$$FileManagerLoadedImplCopyWithImpl<$Res>
    extends _$FileManagerStateCopyWithImpl<$Res, _$FileManagerLoadedImpl>
    implements _$$FileManagerLoadedImplCopyWith<$Res> {
  __$$FileManagerLoadedImplCopyWithImpl(_$FileManagerLoadedImpl _value,
      $Res Function(_$FileManagerLoadedImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? files = null,
    Object? sortBy = null,
    Object? viewMode = null,
  }) {
    return _then(_$FileManagerLoadedImpl(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as FileCategory,
      files: null == files
          ? _value._files
          : files // ignore: cast_nullable_to_non_nullable
              as List<ScannedFile>,
      sortBy: null == sortBy
          ? _value.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as FileSortBy,
      viewMode: null == viewMode
          ? _value.viewMode
          : viewMode // ignore: cast_nullable_to_non_nullable
              as FileViewMode,
    ));
  }
}

/// @nodoc

class _$FileManagerLoadedImpl implements FileManagerLoaded {
  const _$FileManagerLoadedImpl(
      {required this.category,
      required final List<ScannedFile> files,
      required this.sortBy,
      required this.viewMode})
      : _files = files;

  @override
  final FileCategory category;
  final List<ScannedFile> _files;
  @override
  List<ScannedFile> get files {
    if (_files is EqualUnmodifiableListView) return _files;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_files);
  }

  @override
  final FileSortBy sortBy;
  @override
  final FileViewMode viewMode;

  @override
  String toString() {
    return 'FileManagerState.loaded(category: $category, files: $files, sortBy: $sortBy, viewMode: $viewMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileManagerLoadedImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(other._files, _files) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.viewMode, viewMode) ||
                other.viewMode == viewMode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, category,
      const DeepCollectionEquality().hash(_files), sortBy, viewMode);

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileManagerLoadedImplCopyWith<_$FileManagerLoadedImpl> get copyWith =>
      __$$FileManagerLoadedImplCopyWithImpl<_$FileManagerLoadedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() overviewLoading,
    required TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)
        overview,
    required TResult Function() permissionRequired,
    required TResult Function(FileCategory category) loading,
    required TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)
        loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(category, files, sortBy, viewMode);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? overviewLoading,
    TResult? Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult? Function()? permissionRequired,
    TResult? Function(FileCategory category)? loading,
    TResult? Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(category, files, sortBy, viewMode);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? overviewLoading,
    TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult Function()? permissionRequired,
    TResult Function(FileCategory category)? loading,
    TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(category, files, sortBy, viewMode);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FileManagerOverviewLoading value) overviewLoading,
    required TResult Function(FileManagerOverview value) overview,
    required TResult Function(FileManagerPermissionRequired value)
        permissionRequired,
    required TResult Function(FileManagerLoading value) loading,
    required TResult Function(FileManagerLoaded value) loaded,
    required TResult Function(FileManagerError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult? Function(FileManagerOverview value)? overview,
    TResult? Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult? Function(FileManagerLoading value)? loading,
    TResult? Function(FileManagerLoaded value)? loaded,
    TResult? Function(FileManagerError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult Function(FileManagerOverview value)? overview,
    TResult Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult Function(FileManagerLoading value)? loading,
    TResult Function(FileManagerLoaded value)? loaded,
    TResult Function(FileManagerError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class FileManagerLoaded implements FileManagerState {
  const factory FileManagerLoaded(
      {required final FileCategory category,
      required final List<ScannedFile> files,
      required final FileSortBy sortBy,
      required final FileViewMode viewMode}) = _$FileManagerLoadedImpl;

  FileCategory get category;
  List<ScannedFile> get files;
  FileSortBy get sortBy;
  FileViewMode get viewMode;

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileManagerLoadedImplCopyWith<_$FileManagerLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FileManagerErrorImplCopyWith<$Res> {
  factory _$$FileManagerErrorImplCopyWith(_$FileManagerErrorImpl value,
          $Res Function(_$FileManagerErrorImpl) then) =
      __$$FileManagerErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$FileManagerErrorImplCopyWithImpl<$Res>
    extends _$FileManagerStateCopyWithImpl<$Res, _$FileManagerErrorImpl>
    implements _$$FileManagerErrorImplCopyWith<$Res> {
  __$$FileManagerErrorImplCopyWithImpl(_$FileManagerErrorImpl _value,
      $Res Function(_$FileManagerErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$FileManagerErrorImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$FileManagerErrorImpl implements FileManagerError {
  const _$FileManagerErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'FileManagerState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileManagerErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileManagerErrorImplCopyWith<_$FileManagerErrorImpl> get copyWith =>
      __$$FileManagerErrorImplCopyWithImpl<_$FileManagerErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() overviewLoading,
    required TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)
        overview,
    required TResult Function() permissionRequired,
    required TResult Function(FileCategory category) loading,
    required TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)
        loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? overviewLoading,
    TResult? Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult? Function()? permissionRequired,
    TResult? Function(FileCategory category)? loading,
    TResult? Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? overviewLoading,
    TResult Function(
            List<CategorySummary> categories,
            int usedBytes,
            int totalBytes,
            String? searchQuery,
            List<ScannedFile>? searchResults)?
        overview,
    TResult Function()? permissionRequired,
    TResult Function(FileCategory category)? loading,
    TResult Function(FileCategory category, List<ScannedFile> files,
            FileSortBy sortBy, FileViewMode viewMode)?
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
    required TResult Function(FileManagerOverviewLoading value) overviewLoading,
    required TResult Function(FileManagerOverview value) overview,
    required TResult Function(FileManagerPermissionRequired value)
        permissionRequired,
    required TResult Function(FileManagerLoading value) loading,
    required TResult Function(FileManagerLoaded value) loaded,
    required TResult Function(FileManagerError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult? Function(FileManagerOverview value)? overview,
    TResult? Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult? Function(FileManagerLoading value)? loading,
    TResult? Function(FileManagerLoaded value)? loaded,
    TResult? Function(FileManagerError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FileManagerOverviewLoading value)? overviewLoading,
    TResult Function(FileManagerOverview value)? overview,
    TResult Function(FileManagerPermissionRequired value)? permissionRequired,
    TResult Function(FileManagerLoading value)? loading,
    TResult Function(FileManagerLoaded value)? loaded,
    TResult Function(FileManagerError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class FileManagerError implements FileManagerState {
  const factory FileManagerError(final String message) = _$FileManagerErrorImpl;

  String get message;

  /// Create a copy of FileManagerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileManagerErrorImplCopyWith<_$FileManagerErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
