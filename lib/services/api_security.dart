import 'dart:io';

import '../config/server_config.dart';

/// TLS policy for the app's API client.
///
/// Production/release builds reject invalid certificates by default. A local
/// self-signed certificate can only be accepted when the developer explicitly
/// compiles the app with:
///   --dart-define=ALLOW_INSECURE_LOCAL_TLS=true
/// and the certificate host matches the configured server host.
class LocalServerHttpOverrides extends HttpOverrides {
  LocalServerHttpOverrides()
      : _allowedHosts = <String>{Uri.parse(serverBaseUrl).host};

  final Set<String> _allowedHosts;
  static const _allowInsecureLocalTls = bool.fromEnvironment(
    'ALLOW_INSECURE_LOCAL_TLS',
    defaultValue: false,
  );

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    if (_allowInsecureLocalTls) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              _allowedHosts.contains(host);
    }
    return client;
  }
}
