# Apple App Store Notes

iOS's sandboxing model means several features work differently than on
Android — plan the App Store build as a **reduced-scope sibling app**,
not a 1:1 port:

## Features that must change on iOS

- **App Manager** — not possible. Apple does not allow apps to enumerate
  or uninstall other installed apps (Guideline 2.5.1). Hide this tab
  entirely on iOS (already gated via `Platform.isAndroid` in
  `app_manager_view.dart`).
- **Junk Cleaner / Duplicate Finder** — scope to the app's own sandbox
  (Documents/tmp/Caches directories) and to the Photo Library via
  `PhotosUI`, not a device-wide filesystem walk. There is no
  `MANAGE_EXTERNAL_STORAGE` equivalent on iOS, by design.
- **Battery temperature/health** — iOS exposes even less battery detail
  than Android through public APIs. Battery percentage and charging
  state (via `battery_plus`) are available; do not fabricate
  temperature/health values — omit those fields on iOS or clearly mark
  them "Not available on iOS".

## App Review checklist

- [ ] `NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription`
      strings in `Info.plist` clearly explain why access is needed
      (already added).
- [ ] If using personalized ads, implement App Tracking Transparency
      (`app_tracking_transparency` package) and request permission before
      any IDFA-based ad request.
- [ ] In-App Purchase "Remove Ads" product created in App Store Connect
      matching `AppConstants.removeAdsProductId`, and restore-purchases
      flow tested (`PurchaseService.initialize()` already calls
      `restorePurchases()` on launch).
- [ ] No "storage cleaner" claims that require system-level access
      Apple doesn't grant — App Review routinely rejects apps implying
      they can "clean" or "optimize" iOS itself. Frame iOS marketing
      copy around "organize your photos and app storage", not "clean
      your iPhone".
- [ ] Privacy policy URL set in App Store Connect and linked in-app.
- [ ] Test on a physical device — Photos permission flows behave
      differently in Simulator.
