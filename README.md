# Smart Cleaner Pro – Storage & Phone Optimizer

Cross-platform (Android + iOS) storage cleaner built with Flutter, Clean
Architecture, Riverpod, Freezed, GoRouter, and GetIt/Injectable.

## Status of this scaffold

Fully implemented, end-to-end, as reference patterns for the rest:
- **Dashboard** — storage stats, animated circular progress, quick actions
- **Junk Cleaner** — isolate-based scan, categorized results, multi-select
  delete with confirmation dialog, ad hook on completion
- Core layer: theme, DI, router, permissions, isolate file-scan engine,
  ads service, IAP service
- Unit tests for the Junk Cleaner repository (delete logic)

Stubbed with clear TODOs and the exact wiring needed, following the same
repository → ViewModel → view pattern as Junk Cleaner:
- Duplicate Finder (`FileScanService.scanForDuplicates` already built —
  just needs the ViewModel + view)
- Image Compressor, File Manager, App Manager, Battery Monitor (Battery
  Monitor's basic percentage/state is already wired)

## Getting started

```bash
flutter pub get

# Generate freezed/riverpod/json code
dart run build_runner build --delete-conflicting-outputs

flutter run
```

## Folder structure

```
lib/
 ├── core/
 │    ├── theme/         Material 3 tokens, light/dark themes, gradients
 │    ├── utils/          formatting helpers
 │    ├── services/       PermissionService, FileScanService (isolates),
 │    │                   StorageStatsService, AdsService, PurchaseService
 │    ├── constants/      app-wide constants, pref keys, ad unit IDs
 │    ├── di/             GetIt service locator
 │    └── router/         GoRouter route table
 ├── features/
 │    ├── dashboard/       data/domain/presentation (full slice)
 │    ├── junk_cleaner/    data/domain/presentation (full slice)
 │    ├── duplicate_finder/
 │    ├── image_compressor/
 │    ├── file_manager/
 │    ├── app_manager/
 │    ├── battery_monitor/
 │    ├── onboarding/      splash + 3-slide onboarding
 │    └── paywall/         Remove Ads upsell
 ├── shared/
 └── main.dart
```

## Completing the remaining features

Each stub view has an inline comment describing exactly what to wire up.
The pattern to copy from Junk Cleaner for each one:

1. `domain/<feature>_state.dart` — a `@freezed` sealed state (idle /
   loading / loaded / error, feature-specific variants as needed)
2. `data/<feature>_repository.dart` — an interface + impl that calls the
   relevant `core/services/*` class
3. `presentation/viewmodel/<feature>_viewmodel.dart` — a
   `StateNotifier<State>` exposing intent methods
4. `presentation/view/<feature>_view.dart` — a `ConsumerWidget` that
   pattern-matches on state with `.when(...)`

## Before you ship

- Replace all AdMob IDs in `app_constants.dart`, `AndroidManifest.xml`,
  and `ios/Runner/Info.plist` with your real IDs (currently Google's
  public **test** IDs).
- Implement `RamStatsService`/battery temperature via native
  `MethodChannel`s per platform — no reliable cross-platform plugin
  exists; do not fabricate values (see COMPLIANCE notes below).
- Wire `injectable`/`riverpod_generator` codegen if you want annotation-
  driven DI instead of the manual `service_locator.dart` registration
  used here to keep this scaffold buildable without a codegen step.
- Add real app icons, splash Lottie files, and screenshots.
- Read `docs/PLAY_STORE_SUBMISSION_GUIDE.md` and
  `docs/APPLE_APP_STORE_NOTES.md` before submitting.

## Compliance notes (already reflected in code)

- No fake "RAM boost" claims — RAM usage is left at 0%/unimplemented
  until backed by a real native reading, rather than showing a fabricated
  number.
- Deletion is always explicit and user-confirmed (see
  `JunkCleanerView._confirmAndClean`).
- `MANAGE_EXTERNAL_STORAGE` and `QUERY_ALL_PACKAGES` are only requested
  because the App Manager and whole-device Junk/Duplicate scans
  genuinely need them — both require a Play Console permissions
  declaration, covered in the submission guide.
- App Manager is Android-only and hard-gated behind `Platform.isAndroid`
  — iOS cannot and must not attempt to list other installed apps.
