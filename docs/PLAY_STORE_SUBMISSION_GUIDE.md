# Google Play Store Submission Guide

## 1. Permissions declarations (critical for cleaner apps)

Play Console will flag this app for review because it requests two
sensitive permission groups. Fill out the **Permissions declaration
form** under *App content* for both before submitting:

- **All files access (`MANAGE_EXTERNAL_STORAGE`)** — declare that it's
  required for the app's core function (device-wide junk/duplicate file
  scanning) and that no data is transmitted off-device. Record a short
  demo video showing the feature if requested.
- **Package visibility (`QUERY_ALL_PACKAGES`)** — declare it's required
  for the App Manager feature (listing/uninstalling installed apps),
  which is a core, prominently-disclosed feature, not incidental.

Apps that request these permissions without a clearly core, disclosed
use case are commonly rejected — make sure the Junk Cleaner and App
Manager features are genuinely prominent in your app, not vestigial.

## 2. Data safety section

Complete the **Data safety** form accurately:
- Declare any data the AdMob/IAP SDKs collect (device identifiers,
  purchase history) per their own disclosures.
- Declare that file metadata (names, sizes, paths) is processed
  on-device only and never uploaded, if that remains true of your
  implementation.
- Link your privacy policy URL (must be publicly reachable, not a
  placeholder).

## 3. Target API level & scoped storage

- Target the latest required API level (check Play Console's current
  minimum at submission time — this changes yearly).
- Confirm scoped storage compliance: `MANAGE_EXTERNAL_STORAGE` is only
  used for legitimate device-maintenance scanning, and the app does not
  otherwise access files outside its sandbox without permission.

## 4. Content rating

Complete the content rating questionnaire — a utility app like this
should qualify for a low/all-ages rating (Everyone / PEGI 3) as long as
no mature ad content is served (configure AdMob's content rating
settings to match).

## 5. Store listing assets checklist

- [ ] App icon (512×512 PNG, no transparency)
- [ ] Feature graphic (1024×500) — see suggested headline in
      `docs/STORE_COPY.md`
- [ ] At least 2 phone screenshots (recommend 4–8, one per feature)
- [ ] Short description (≤80 chars) — see `docs/STORE_COPY.md`
- [ ] Full description (≤4000 chars) — see `docs/STORE_COPY.md`
- [ ] Privacy policy URL
- [ ] Category: Tools

## 6. Pre-launch checklist

- [ ] Real AdMob IDs in place (see `ADMOB_SETUP_GUIDE.md`)
- [ ] IAP product `smart_cleaner_pro_remove_ads` created in Play Console
      → Monetize → Products, matching `AppConstants.removeAdsProductId`
- [ ] Signed release build (`flutter build appbundle --release`) tested
      on a physical device, not just an emulator, for storage permission
      flows
- [ ] Crash-free run through all 7 core features on at least one Android
      11-12 device (legacy storage) and one Android 13+ device (granular
      media permissions)
