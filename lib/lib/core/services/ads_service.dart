import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

import '../constants/app_constants.dart';

/// All AdMob logic lives here so feature code never touches the SDK
/// directly — this makes it trivial to no-op ads entirely for Pro users
/// by checking [isProUser] before any load/show call.
class AdsService {
  final Logger _logger = Logger();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  DateTime? _lastInterstitialShown;

  bool isProUser = false; // set by PurchaseService on app start / purchase

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
  }

  void _loadInterstitial() {
    if (isProUser) return;
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitIdAndroid,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) =>
            _logger.w('Interstitial failed to load: $error'),
      ),
    );
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitIdAndroid,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) =>
            _logger.w('Rewarded ad failed to load: $error'),
      ),
    );
  }

  /// Call after a successful clean/scan action completes. Respects a
  /// cooldown and Pro status so free users aren't interrupted mid-flow.
  Future<void> maybeShowInterstitial() async {
    if (isProUser || _interstitialAd == null) return;
    final now = DateTime.now();
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) < AppConstants.adCooldown) {
      return;
    }
    _lastInterstitialShown = now;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
    );
    await _interstitialAd!.show();
  }

  /// Used to unlock the "Deep Scan" option in Junk Cleaner / Duplicate
  /// Finder. [onReward] only fires if the user actually watches to
  /// completion, per AdMob policy.
  Future<void> showRewardedForDeepScan({
    required void Function() onReward,
    required void Function() onUnavailable,
  }) async {
    if (_rewardedAd == null) {
      onUnavailable();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewarded();
      },
    );
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) => onReward(),
    );
  }
}
