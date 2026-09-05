import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';
import '../services/ads_service.dart';

class AdmobBannerSlot extends StatefulWidget {
  const AdmobBannerSlot({super.key, this.hidden = false});

  final bool hidden;

  @override
  State<AdmobBannerSlot> createState() => _AdmobBannerSlotState();
}

class _AdmobBannerSlotState extends State<AdmobBannerSlot> {
  BannerAd? _banner;
  double _height = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.hidden &&
        AdsService.instance.enabled &&
        adsBannerUnitId.startsWith('ca-app-pub-') &&
        _banner == null) {
      unawaited(_loadBanner());
    }
  }

  Future<void> _loadBanner() async {
    await AdsService.instance.ensureInitialized();
    if (!mounted) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    AdSize size;
    try {
      size = (await AdSize.getAnchoredAdaptiveBannerAdSize(
            Orientation.portrait,
            width,
          )) ??
          AdSize.banner;
    } catch (_) {
      size = AdSize.banner;
    }
    final banner = BannerAd(
      adUnitId: adsBannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            if (_banner != null) _height = _banner!.size.height.toDouble();
          });
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _banner = banner;
    await banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _banner;
    if (widget.hidden || ad == null || _height <= 0) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(height: _height, child: AdWidget(ad: ad)),
    );
  }
}