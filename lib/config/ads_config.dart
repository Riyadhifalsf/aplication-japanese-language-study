const String adsAppId = String.fromEnvironment(
  'ADMOB_APP_ID',
  defaultValue: 'ca-app-pub-5359721539349055~8474590614',
);

const String adsBannerUnitId = String.fromEnvironment(
  'ADMOB_BANNER_ID',
  defaultValue: 'ca-app-pub-5359721539349055/8255098763',
);

const String adsInterstitialUnitId = String.fromEnvironment(
  'ADMOB_INTERSTITIAL_ID',
  defaultValue: 'ca-app-pub-5359721539349055/6886176778',
);

const String adsRewardedUnitId = String.fromEnvironment(
  'ADMOB_REWARDED_ID',
  defaultValue: 'ca-app-pub-5359721539349055/4260013439',
);

const String adsNativeUnitId = String.fromEnvironment(
  'ADMOB_NATIVE_ID',
  defaultValue: 'ca-app-pub-5359721539349055/3002772089',
);

const bool adsEnabled = bool.fromEnvironment(
  'ADMOB_ENABLED',
  defaultValue: true,
);