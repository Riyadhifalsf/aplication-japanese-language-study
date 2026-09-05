import 'dart:io';

import '../config/server_config.dart';

class LocalServerHttpOverrides extends HttpOverrides {
  LocalServerHttpOverrides()
      : _allowedHosts = <String>{
          Uri.parse(serverBaseUrl).host,
        };

  final Set<String> _allowedHosts;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      return _allowedHosts.contains(host);
    };
    return client;
  }
}