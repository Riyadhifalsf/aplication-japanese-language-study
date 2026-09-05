import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/server_config.dart';
import '../models/vocabulary.dart';

class AdminApiException implements Exception {
  const AdminApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'AdminApiException($statusCode): $message';
}

class AdminApiService {
  AdminApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const baseUrl = serverBaseUrl;
  static const token = String.fromEnvironment(
    'API_ADMIN_TOKEN',
    defaultValue: serverAdminToken,
  );

  bool get configured => baseUrl.trim().isNotEmpty;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token.trim().isNotEmpty) 'Authorization': 'Bearer ${token.trim()}',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$root/$path').replace(queryParameters: query);
  }

  dynamic _decode(http.Response response) {
    if (response.body.trim().isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decode(response);
      String message = 'Permintaan backend gagal.';
      if (body is Map<String, dynamic>) {
        message = (body['message'] ?? body['error'] ?? message).toString();
      } else if (body is String && body.trim().isNotEmpty) {
        message = body.trim();
      }
      throw AdminApiException(message, statusCode: response.statusCode);
    }
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      for (final key in const ['data', 'items', 'results', 'vocabulary']) {
        final value = body[key];
        if (value is List) return value;
        if (value is Map<String, dynamic>) {
          for (final nested in const ['data', 'items', 'results']) {
            if (value[nested] is List) return value[nested] as List;
          }
        }
      }
    }
    return const [];
  }

  Map<String, dynamic> _extractObject(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      final item = body['vocabulary'];
      if (item is Map<String, dynamic>) return item;
      return body;
    }
    throw const AdminApiException('Respons backend tidak berbentuk objek.');
  }

  Vocabulary _toVocabulary(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    if (map['id'] is String) map['id'] = int.tryParse(map['id'] as String) ?? 0;
    return Vocabulary.fromJson(map);
  }

  Future<List<Vocabulary>> fetchVocabulary({String? level, String? search}) async {
    if (!configured) throw const AdminApiException('API_BASE_URL belum diatur.');
    final query = <String, String>{
      if (level != null && level != 'Semua') 'level': level,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    http.Response response = await _client
        .get(_uri('vocabulary', query), headers: _headers)
        .timeout(const Duration(seconds: 4));
    _ensureOk(response);
    return _extractList(_decode(response)).map(_toVocabulary).toList(growable: false);
  }

  Future<Vocabulary> createVocabulary({required String word, required String reading, required String meaning, required String level}) async {
    final payload = {'word': word, 'reading': reading, 'meaning': meaning, 'level': level};
    final response = await _client.post(_uri('vocabulary'), headers: _headers, body: jsonEncode(payload)).timeout(const Duration(seconds: 8));
    _ensureOk(response);
    return _toVocabulary(_extractObject(_decode(response)));
  }

  Future<Vocabulary> updateVocabulary(Vocabulary item) async {
    final payload = {'word': item.word, 'reading': item.reading, 'meaning': item.meaning, 'level': item.level};
    http.Response response = await _client.put(_uri('vocabulary/${item.id}'), headers: _headers, body: jsonEncode(payload)).timeout(const Duration(seconds: 8));
    if (response.statusCode == 404) {
      response = await _client.put(_uri('vocabulary/${item.id}'), headers: _headers, body: jsonEncode(payload)).timeout(const Duration(seconds: 8));
    }
    _ensureOk(response);
    return _toVocabulary(_extractObject(_decode(response)));
  }

  Future<void> deleteVocabulary(int id) async {
    http.Response response = await _client.delete(_uri('vocabulary/$id'), headers: _headers).timeout(const Duration(seconds: 8));
    if (response.statusCode == 404) {
      response = await _client.delete(_uri('vocabulary/$id'), headers: _headers).timeout(const Duration(seconds: 8));
    }
    _ensureOk(response);
  }
}
