import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/server_config.dart';

class ApiService {
  ApiService({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  static const baseUrl = serverBaseUrl;

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<String?> get token => _storage.read(key: 'api_access_token');

  Future<void> _saveToken(String token) =>
      _storage.write(key: 'api_access_token', value: token);

  Future<void> logout() => _storage.delete(key: 'api_access_token');

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final r = await _client.post(_uri('/api/auth/register'),
      headers: {'Content-Type':'application/json'},
      body: jsonEncode({'name':name,'email':email,'password':password}));
    final data=_decode(r);
    if(r.statusCode<200 || r.statusCode>=300) throw apiError(data, r.statusCode, 'Pendaftaran gagal.');
    await _saveToken(data['token'].toString());
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final r = await _client.post(_uri('/api/auth/login'),
      headers: {'Content-Type':'application/json'},
      body: jsonEncode({'email':email,'password':password}));
    final data=_decode(r);
    if(r.statusCode<200 || r.statusCode>=300) throw apiError(data, r.statusCode, 'Login gagal.');
    await _saveToken(data['token'].toString());
    return data;
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    final r = await _client.post(_uri('/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}));
    final data = _decode(r);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw apiError(data, r.statusCode, 'Login Google gagal.');
    }
    final token = data['token']?.toString();
    if (token != null && token.isNotEmpty) await _saveToken(token);
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final t=await token;
    if(t==null) throw ApiException('Belum login.');
    final r=await _client.get(_uri('/api/me'),headers:{'Authorization':'Bearer $t'});
    final data=_decode(r);
    if(r.statusCode!=200) throw apiError(data, r.statusCode, 'Sesi tidak valid.');
    return data;
  }

  Future<void> saveProgress(Map<String,dynamic> progress) async {
    final t=await token;
    if(t==null) return;
    final r=await _client.put(_uri('/api/me/progress'),
      headers:{'Content-Type':'application/json','Authorization':'Bearer $t'},
      body:jsonEncode(progress));
    if(r.statusCode<200 || r.statusCode>=300) throw apiError(_decode(r), r.statusCode, 'Gagal menyimpan progress (${r.statusCode}).');
  }


  /// Tanya AI Sensei (proxy Gemini via backend; key aman di server).
  /// [history] opsional: [{role:'user'|'model', text:...}] maks 10.
  /// Throws [ApiException] berkode: AI_DISABLED (503, server belum isi key),
  /// AI_RATE_LIMITED (429), AUTH_* bila belum login.
  Future<String> askSensei({
    required String message,
    List<Map<String, String>> history = const [],
    String level = '',
  }) async {
    final t = await token;
    if (t == null) throw ApiException('Belum login.');
    final r = await _client.post(_uri('/api/ai/chat'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'},
        body: jsonEncode({'message': message, 'history': history, 'level': level}));
    final data = _decode(r);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw apiError(data, r.statusCode, 'Sensei tidak merespons (${r.statusCode}).');
    }
    final reply = data['reply']?.toString() ?? '';
    if (reply.isEmpty) throw ApiException('Sensei memberi jawaban kosong.');
    return reply;
  }


  Future<List<Map<String,dynamic>>> adminUsers() async {
    final t=await token;
    if(t==null) throw ApiException('Belum login.');
    final r=await _client.get(_uri('/api/admin/users'),headers:{'Authorization':'Bearer $t'});
    final data=_decode(r);
    if(r.statusCode!=200) throw apiError(data, r.statusCode, 'Gagal mengambil user.');
    return (data['users'] as List? ?? const [])
        .map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }

  Future<void> adminDeleteUser(String id) async {
    final t=await token;
    if(t==null) throw ApiException('Belum login.');
    final r=await _client.delete(_uri('/api/admin/users/$id'),headers:{'Authorization':'Bearer $t'});
    if(r.statusCode<200 || r.statusCode>=300) throw ApiException('Gagal menghapus user.');
  }

  /// Entitlement server-side: sumber kebenaran premium (jangan percaya
  /// klaim lokal). Null bila offline/belum login (fallback lokal dipakai).
  /// Ganti password akun server. Wajib tahu password saat ini.
  /// Token lama otomatis mati (backend menolak via AUTH_PASSWORD_CHANGED).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final t = await token;
    if (t == null) throw ApiException('Belum login.');
    final r = await _client.post(_uri('/api/me/password'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'},
        body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw apiError(_decode(r), r.statusCode, 'Ganti password gagal (${r.statusCode}).');
    }
  }

  /// Minta kode reset ke Gmail. Selalu sukses generik (anti-enumeration).
  Future<String> requestPasswordReset({required String email}) async {
    final r = await _client.post(_uri('/api/auth/forgot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}));
    final data = _decode(r);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw apiError(data, r.statusCode, 'Gagal meminta kode reset (${r.statusCode}).');
    }
    return data['message']?.toString() ?? 'Bila email terdaftar, kode reset telah dikirim ke Gmail.';
  }

  /// Tukar kode 6 digit menjadi password baru (sekali pakai).
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final r = await _client.post(_uri('/api/auth/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw apiError(_decode(r), r.statusCode, 'Reset password gagal (${r.statusCode}).');
    }
  }

  Future<Map<String,dynamic>?> entitlements() async {
    final t=await token;
    if(t==null) return null;
    try {
      final r=await _client.get(_uri('/api/me/entitlements'),headers:{'Authorization':'Bearer $t'});
      final data=_decode(r);
      if(r.statusCode!=200) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  Map<String,dynamic> _decode(http.Response r) {
    try { return Map<String,dynamic>.from(jsonDecode(r.body) as Map); }
    catch (_) { return {'message':r.body}; }
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.code = '', this.status = 0});

  /// Pesan Indonesia siap tampil.
  final String message;

  /// Kode mesin dari backend (`error.code`), mis. AUTH_BAD_CREDENTIALS.
  /// Kosong bila server lama / offline.
  final String code;
  final int status;

  bool get isAuthError =>
      status == 401 ||
      code == 'AUTH_BAD_TOKEN' ||
      code == 'AUTH_MISSING_TOKEN' ||
      code == 'USER_NOT_FOUND';

  @override
  String toString() => message;
}

/// Ambil kode error terstruktur bila ada (`{error:{code}}`), fallback pesan.
ApiException apiError(Map<String, dynamic> data, int status, String fallback) {
  final err = data['error'];
  final code = err is Map ? err['code']?.toString() ?? '' : '';
  return ApiException(
    data['message']?.toString() ?? fallback,
    code: code,
    status: status,
  );
}
