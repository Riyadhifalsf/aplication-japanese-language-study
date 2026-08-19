import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class Web3PassportService {
  Web3PassportService._();
  static final instance = Web3PassportService._();

  String identityFrom(String stableSeed) {
    final digest = sha256.convert(utf8.encode('japanese-study:web3:$stableSeed')).toString();
    return 'js1${digest.substring(0, 40)}';
  }

  String credentialId({required String identity, required String event, required DateTime issuedAt}) {
    final payload = '$identity|$event|${issuedAt.toIso8601String()}';
    final digest = sha256.convert(utf8.encode(payload)).toString();
    return 'cred_${digest.substring(0, 32)}';
  }

  String achievementHash(Map<String, Object?> payload) {
    final canonical = jsonEncode(payload);
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  String shortIdentity(String identity) => identity.length <= 16
      ? identity
      : '${identity.substring(0, 10)}…${identity.substring(identity.length - 6)}';

  int proofNonce() => Random().nextInt(1 << 30);
}
