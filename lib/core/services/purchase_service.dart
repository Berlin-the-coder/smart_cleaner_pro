import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Handles the single "Remove Ads" non-consumable purchase. Kept separate
/// from [AdsService] — this owns entitlement state, AdsService only reads
/// [isProUser] to decide whether to load/show ads.
class PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final _proStatusController = StreamController<bool>.broadcast();
  Stream<bool> get proStatusStream => _proStatusController.stream;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPro = prefs.getBool(PrefKeys.isProUser) ?? false;
    _proStatusController.add(cachedPro);

    final available = await _iap.isAvailable();
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate);
    await _iap.restorePurchases();
  }

  Future<ProductDetailsResponse> queryRemoveAdsProduct() {
    return _iap.queryProductDetails({AppConstants.removeAdsProductId});
  }

  Future<void> buyRemoveAds(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == AppConstants.removeAdsProductId) {
          await _setPro(true);
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
      if (purchase.status == PurchaseStatus.error) {
        // Surface via a dedicated error stream in a full implementation.
      }
    }
  }

  Future<void> _setPro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.isProUser, value);
    _proStatusController.add(value);
  }

  void dispose() {
    _subscription?.cancel();
    _proStatusController.close();
  }
}
