import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_theme.dart';

/// "Remove Ads" upsell. Deep-scan and interstitial-heavy screens should
/// route here when a free user hits an ad-gated action.
class PaywallView extends StatelessWidget {
  const PaywallView({super.key});

  @override
  Widget build(BuildContext context) {
    final purchaseService = getIt<PurchaseService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13131E) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E2A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        title: const Text('Go Pro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── PREMIUM ICON ────────────────────────────────────────────
            Container(
              width:  120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(
                    alpha: isDark ? 0.15 : 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size:  60,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 20),

            // ── HEADLINE ────────────────────────────────────────────────
            Text(
              'Remove all ads',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // ── DESCRIPTION ─────────────────────────────────────────────
            Text(
              'One-time purchase. No ads, ever — deep scans and all '
                  'features stay free either way.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // ── PURCHASE BUTTON ─────────────────────────────────────────
            FutureBuilder<ProductDetailsResponse>(
              future: purchaseService.queryRemoveAdsProduct(),
              builder: (context, snapshot) {
                final product = snapshot.data?.productDetails.firstOrNull;
                final isLoading = snapshot.connectionState ==
                    ConnectionState.waiting;

                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: product == null || isLoading
                        ? null
                        : () => purchaseService.buyRemoveAds(product),
                    child: Text(
                      isLoading
                          ? 'Loading…'
                          : product == null
                          ? 'Unavailable'
                          : 'Buy — ${product.price}',
                      style: const TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── OPTIONAL: CLOSE BUTTON ──────────────────────────────────
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe later',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}