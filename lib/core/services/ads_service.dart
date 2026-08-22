import 'package:logger/logger.dart';

/// Ads are temporarily disabled app-wide. Every method below is a no-op
/// so call sites (JunkCleanerViewModel, DuplicateFinderViewModel, DI
/// setup) don't need to change — nothing loads, nothing shows, nothing
/// initializes the AdMob SDK. Re-enabling later is a matter of
/// restoring the google_mobile_ads calls in this file only.
class AdsService {
  final Logger _logger = Logger();

  bool isProUser = false;

  Future<void> initialize() async {
    _logger.i('AdsService.initialize(): ads temporarily disabled — no-op');
  }

  /// Call after a successful clean/scan action completes. No-op while
  /// ads are disabled.
  Future<void> maybeShowInterstitial() async {}

  /// Used to unlock the "Deep Scan" option in Junk Cleaner / Duplicate
  /// Finder. While ads are disabled, always reports "unavailable" so
  /// callers fall back to their normal (non-rewarded) behavior instead
  /// of hanging waiting for an ad that will never load.
  Future<void> showRewardedForDeepScan({
    required void Function() onReward,
    required void Function() onUnavailable,
  }) async {
    onUnavailable();
  }
}
