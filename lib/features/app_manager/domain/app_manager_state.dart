import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:installed_apps/app_info.dart';

part 'app_manager_state.freezed.dart';

enum AppSortOrder { nameAsc, installDateDesc }

@freezed
class AppManagerState with _$AppManagerState {
  const factory AppManagerState.loading() = AppManagerLoading;
  const factory AppManagerState.loaded({
    required List<AppInfo> apps,
    required AppSortOrder sortOrder,
  }) = AppManagerLoaded;
  const factory AppManagerState.unsupportedPlatform() =
      AppManagerUnsupportedPlatform;
  const factory AppManagerState.error(String message) = AppManagerError;
}
