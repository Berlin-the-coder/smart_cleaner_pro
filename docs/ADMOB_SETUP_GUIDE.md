# AdMob Setup Guide

## 1. Create your AdMob account & app

1. Go to https://apps.admob.com and sign in with the Google account you'll
   use for the Play Console / App Store Connect.
2. **Apps → Add app** → create one entry for Android and one for iOS.
3. Note the **App ID** for each (format `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`).

## 2. Create ad units

Create these ad units per platform:

| Ad unit          | Format       | Used for                          |
|-------------------|--------------|------------------------------------|
| Interstitial      | Interstitial | Shown after a completed clean      |
| Rewarded          | Rewarded     | Unlocks "Deep Scan"                |
| Banner (optional) | Banner       | Dashboard footer, if desired       |

## 3. Wire the IDs into the app

Replace the **test** IDs in three places with your real ones:

- `lib/core/constants/app_constants.dart`
  - `admobAppIdAndroid`, `admobAppIdIOS`
  - `interstitialAdUnitIdAndroid`, `rewardedAdUnitIdAndroid`,
    `bannerAdUnitIdAndroid`
  - (Add matching iOS unit ID constants if you use different units per
    platform.)
- `android/app/src/main/AndroidManifest.xml`
  - `com.google.android.gms.ads.APPLICATION_ID` meta-data value
- `ios/Runner/Info.plist`
  - `GADApplicationIdentifier` value

**Never ship with the test IDs above** — Google will flag test-ad traffic
and your account can be suspended for invalid activity if real IDs are
swapped in after launch traffic has already started hitting test units.

## 4. Ad placement rules already implemented

- `AdsService.maybeShowInterstitial()` is called once, after a completed
  Junk Cleaner clean — not on every screen transition — and respects a
  3-minute cooldown (`AppConstants.adCooldown`) so it can't be spammed.
- `AdsService.showRewardedForDeepScan()` only unlocks the reward if the
  user watches to completion (`onUserEarnedReward` callback), per AdMob
  policy — never grant the reward optimistically.
- `AdsService.isProUser` is toggled by `PurchaseService` — once a user
  buys "Remove Ads", no further ad loads/shows happen.

## 5. Policy checklist before submission

- [ ] No ads placed on top of interactive UI elements (buttons, delete
      confirmations) — interstitials only show at natural break points.
- [ ] Rewarded ad clearly explains what the reward unlocks before the
      user opts in.
- [ ] `ca-app-pub-...` test IDs fully replaced.
- [ ] Privacy policy (see `docs/PRIVACY_POLICY_TEMPLATE.md`) discloses ad
      SDK data collection and is linked from both the Play Store listing
      and in-app settings.
- [ ] For iOS 14.5+, request App Tracking Transparency (`app_tracking_transparency`
      package) **before** initializing ad SDKs that use IDFA, if you enable
      personalized ads.
