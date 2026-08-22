import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';

import '../../data/app_manager_repository.dart';
import '../../domain/app_manager_state.dart';

final appManagerRepositoryProvider = Provider<AppManagerRepository>((ref) {
  return AppManagerRepositoryImpl();
});

final appManagerViewModelProvider =
    StateNotifierProvider<AppManagerViewModel, AppManagerState>((ref) {
  return AppManagerViewModel(ref.watch(appManagerRepositoryProvider), ref);
});

/// Separate, plain (non-freezed) flag the UI can watch to show a small
/// "loading icons…" spinner without needing a new AppManagerState case.
/// Kept outside the freezed union deliberately — the union's generated
/// .freezed.dart file isn't being regenerated in this environment, so
/// every state emitted by the ViewModel MUST use one of the existing
/// constructors (loading / loaded / unsupportedPlatform / error).
final appManagerIconsLoadingProvider = StateProvider<bool>((ref) => false);

/// Session-scoped cache for the full (icons-included) installed apps
/// list. Riverpod's StateNotifierProvider (not autoDispose here) should
/// already keep AppManagerViewModel — and its state — alive across
/// navigation, so revisiting this screen shouldn't normally re-fetch at
/// all. This cache is a belt-and-suspenders guarantee on top of that:
/// even if the ViewModel instance itself gets recreated for any reason,
/// a fresh instance still finds this and skips straight to an instant
/// `loaded` state instead of re-querying the native plugin (which is
/// the actual slow part — a platform-channel call whose cost we can't
/// reduce further from the Dart side).
class _AppListCache {
  _AppListCache._();
  static List<AppInfo>? apps;
  static AppSortOrder? sortOrder;
}

class AppManagerViewModel extends StateNotifier<AppManagerState> {
  final AppManagerRepository _repository;
  final Ref _ref;
  List<AppInfo> _masterList = [];

  AppManagerViewModel(this._repository, this._ref)
      : super(const AppManagerState.loading()) {
    load();
  }

  /// Two-phase load, both phases using the SAME `loaded` state shape.
  /// [forceRefresh] bypasses the cache (used by pull-to-refresh) since
  /// the user might have installed/uninstalled apps outside this app.
  Future<void> load({bool forceRefresh = false}) async {
    if (!_repository.isSupported) {
      state = const AppManagerState.unsupportedPlatform();
      return;
    }

    // Cache hit — show instantly, no native calls at all.
    if (!forceRefresh && _AppListCache.apps != null) {
      _masterList = List.of(_AppListCache.apps!);
      state = AppManagerState.loaded(
        apps: List.of(_masterList),
        sortOrder: _AppListCache.sortOrder ?? AppSortOrder.nameAsc,
      );
      return;
    }

    state = const AppManagerState.loading();

    try {
      // ── Phase 1: fast, no icons ──────────────────────────────────────
      final apps = await _repository.getInstalledAppsWithoutIcons();
      apps.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _masterList = List.of(apps);

      state = AppManagerState.loaded(
        apps: List.of(_masterList),
        sortOrder: AppSortOrder.nameAsc,
      );

      // ── Phase 2: icons arrive one at a time, UI updates as each one
      // is ready — not one big wait-then-show-all. A short (~120ms)
      // coalescing window batches together whichever icons land in
      // that window so we're not calling setState 300 times a second,
      // while still feeling continuous/incremental to the user.
      _ref.read(appManagerIconsLoadingProvider.notifier).state = true;

      final packageNames = _masterList.map((a) => a.packageName).toList();
      final positionByPackage = {
        for (var i = 0; i < _masterList.length; i++)
          _masterList[i].packageName: i,
      };

      var pendingSinceFlush = 0;
      Timer? flushTimer;

      void flush(AppSortOrder order) {
        flushTimer?.cancel();
        flushTimer = null;
        pendingSinceFlush = 0;
        _applySort(order);
      }

      final currentOrderAtStart = (state is AppManagerLoaded)
          ? (state as AppManagerLoaded).sortOrder
          : AppSortOrder.nameAsc;

      await for (final appWithIcon
          in _repository.loadIconsForAppsStream(packageNames)) {
        final idx = positionByPackage[appWithIcon.packageName];
        if (idx != null) _masterList[idx] = appWithIcon;

        pendingSinceFlush++;
        if (pendingSinceFlush >= 4) {
          flush(currentOrderAtStart);
        } else {
          flushTimer ??= Timer(
            const Duration(milliseconds: 120),
            () => flush(currentOrderAtStart),
          );
        }
      }

      flushTimer?.cancel();
      final finalOrder = (state is AppManagerLoaded)
          ? (state as AppManagerLoaded).sortOrder
          : AppSortOrder.nameAsc;
      _applySort(finalOrder);

      _AppListCache.apps = List.of(_masterList);
      _AppListCache.sortOrder = finalOrder;
    } catch (e) {
      state = AppManagerState.error('Failed to load apps: $e');
    } finally {
      _ref.read(appManagerIconsLoadingProvider.notifier).state = false;
    }
  }

  void setSortOrder(AppSortOrder order) => _applySort(order);

  /// Launching InstalledApps.uninstallApp() only STARTS the OS
  /// uninstall confirmation flow — it doesn't guarantee the package is
  /// actually gone by the time the call returns, and Android can take
  /// a moment more to finish removing it even after the user confirms.
  /// Immediately calling load() afterwards was racing that process, so
  /// the just-uninstalled app kept showing up (it was still installed
  /// at the moment we re-queried). Instead: remove it from the visible
  /// list right away (optimistic — matches what the user just did),
  /// then reconcile with a real reload shortly after in the background
  /// in case the uninstall was cancelled or failed.
  Future<void> uninstall(String packageName) async {
    final removed = _masterList.where((a) => a.packageName == packageName);
    if (removed.isNotEmpty) {
      _masterList =
          _masterList.where((a) => a.packageName != packageName).toList();
      final current = state;
      final order =
          current is AppManagerLoaded ? current.sortOrder : AppSortOrder.nameAsc;
      state = AppManagerState.loaded(apps: List.of(_masterList), sortOrder: order);
      _AppListCache.apps = List.of(_masterList);
    }

    await _repository.uninstallApp(packageName);

    // Reconcile shortly after, WITHOUT a full reload (which would reset
    // to a loading state and re-stream every icon again). If the app
    // is still installed, the user cancelled the system dialog — bring
    // it back with a real reload. Otherwise it's already correctly
    // gone from the list and nothing further needs to happen.
    await Future.delayed(const Duration(milliseconds: 700));
    try {
      final stillInstalled = await _repository.getInstalledAppsWithoutIcons();
      final wasCancelled =
          stillInstalled.any((a) => a.packageName == packageName);
      if (wasCancelled) await load(forceRefresh: true);
    } catch (_) {}
  }

  void _applySort(AppSortOrder order) {
    final sorted = List.of(_masterList);
    switch (order) {
      case AppSortOrder.nameAsc:
        sorted.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case AppSortOrder.installDateDesc:
        sorted.sort(
            (a, b) => b.installedTimestamp.compareTo(a.installedTimestamp));
        break;
    }
    state = AppManagerState.loaded(apps: sorted, sortOrder: order);
    _AppListCache.sortOrder = order;
  }
}
