import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';

class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  bool _initialized = false;
  InterstitialAd? _interstitial;
  Future<RewardedAd>? _rewardedLoading;
  RewardedAd? _rewarded;
  int _tabChangeCount = 0;

  bool get enabled => adsEnabled && adsAppId.isNotEmpty;

  Future<void> ensureInitialized() async {
    if (!enabled || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaited(_preloadInterstitial());
    } catch (_) {
      // Iklan tidak tersedia di platform ini; aplikasi tetap berjalan normal.
    }
  }

  Future<void> _preloadInterstitial() async {
    if (!enabled || !adsInterstitialUnitId.startsWith('ca-app-pub-')) return;
    _interstitial?.dispose();
    _interstitial = null;
    InterstitialAd.load(
      adUnitId: adsInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              _preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitial = null;
            },
          );
        },
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Dipanggil saat pengguna pindah tab; interval antar interstitial dikontrol di sini.
  Future<void> onTabChange() async {
    if (!enabled || _interstitial == null) return;
    _tabChangeCount++;
    if (_tabChangeCount < 4) return;
    _tabChangeCount = 0;
    final ad = _interstitial;
    _interstitial = null;
    try {
      await ad?.show();
    } catch (_) {
      // Abaikan bila iklan gagal dimunculkan.
    }
    unawaited(_preloadInterstitial());
  }

  Future<void> _preloadRewarded() async {
    if (!enabled || !adsRewardedUnitId.startsWith('ca-app-pub-')) return;
    if (_rewardedLoading != null) return;
    final future = Future<RewardedAd>(() async {
      final completer = Completer<RewardedAd>();
      RewardedAd.load(
        adUnitId: adsRewardedUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) => completer.complete(ad),
          onAdFailedToLoad: (_) => completer.completeError(StateError('load')),
        ),
      );
      return completer.future;
    });
    _rewardedLoading = future;
    try {
      _rewarded = await future;
    } catch (_) {
      _rewarded = null;
    } finally {
      _rewardedLoading = null;
    }
  }

  /// Menampilkan iklan rewarded (tonton untuk reward). Mengembalikan `true`
  /// bila pengguna menyelesaikan iklan, `false` bila gagal/dibatalkan.
  Future<bool> showRewarded() async {
    if (!enabled) return false;
    await _preloadRewarded();
    var ad = _rewarded;
    if (ad == null) await _preloadRewarded();
    ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(earned);
        unawaited(_preloadRewarded());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    try {
      await ad.show(onUserEarnedReward: (ad, reward) {
        earned = true;
      });
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
      return false;
    }
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => earned,
    );
  }
}