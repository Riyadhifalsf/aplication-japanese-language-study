import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';
import '../services/ads_service.dart';

class AdmobNativeSlot extends StatefulWidget {
  const AdmobNativeSlot({super.key, this.hidden = false, this.templateType = TemplateType.medium});

  final bool hidden;
  final TemplateType templateType;

  @override
  State<AdmobNativeSlot> createState() => _AdmobNativeSlotState();
}

class _AdmobNativeSlotState extends State<AdmobNativeSlot> {
  NativeAd? _native;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.hidden &&
        AdsService.instance.enabled &&
        adsNativeUnitId.startsWith('ca-app-pub-') &&
        _native == null) {
      unawaited(_loadNative());
    }
  }

  Future<void> _loadNative() async {
    await AdsService.instance.ensureInitialized();
    if (!mounted) return;
    final ad = NativeAd(
      adUnitId: adsNativeUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: const Color(0x00000000),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          // Root-cause fix '!_debugDoingThisLayout': callback iklan native
          // bisa datang saat framework sedang layout. setState langsung di
          // sini memicu markNeedsLayout reentrant. Tunda ke post-frame agar
          // perubahan ukuran shrink -> fixed-height terjadi di luar fase
          // layout. Tinggi dibuat STABIL (tidak tergantung hasil ukur iklan)
          // sehingga tidak ada loop layout.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            if (_native != null) setState(() {});
          });
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
        onAdClicked: (ad) {},
        onAdImpression: (ad) {},
        onAdClosed: (ad) {},
        onAdOpened: (ad) {},
      ),
    );
    _native = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _native?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _native;
    if (widget.hidden || ad == null) return const SizedBox.shrink();
    // Tinggi TETAP untuk template medium (~300) + label. Ukuran stabil
    // sebelum/sesudah load sehingga ListView induk tidak relayout berulang.
    return Container(
      height: 340,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: ad),
    );
  }
}