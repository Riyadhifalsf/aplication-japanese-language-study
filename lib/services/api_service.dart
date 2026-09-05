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
    if(r.statusCode<200 || r.statusCode>=300) throw ApiException(data['message']?.toString() ?? 'Pendaftaran gagal.');
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
    if(r.statusCode<200 || r.statusCode>=300) throw ApiException(data['message']?.toString() ?? 'Login gagal.');
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
      throw ApiException(
          data['message']?.toString() ?? 'Login Google gagal.');
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
    if(r.statusCode!=200) throw ApiException(data['message']?.toString() ?? 'Sesi tidak valid.');
    return data;
  }

  Future<void> saveProgress(Map<String,dynamic> progress) async {
    final t=await token;
    if(t==null) return;
    final r=await _client.put(_uri('/api/me/progress'),
      headers:{'Content-Type':'application/json','Authorization':'Bearer $t'},
      body:jsonEncode(progress));
    if(r.statusCode<200 || r.statusCode>=300) throw ApiException('Gagal menyimpan progress (${r.statusCode}).');
  }


  Future<List<Map<String,dynamic>>> adminUsers() async {
    final t=await token;
    if(t==null) throw ApiException('Belum login.');
    final r=await _client.get(_uri('/api/admin/users'),headers:{'Authorization':'Bearer $t'});
    final data=_decode(r);
    if(r.statusCode!=200) throw ApiException(data['message']?.toString() ?? 'Gagal mengambil user.');
    return (data['users'] as List? ?? const [])
        .map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }

  Future<void> adminDeleteUser(String id) async {
    final t=await token;
    if(t==null) throw ApiException('Belum login.');
    final r=await _client.delete(_uri('/api/admin/users/$id'),headers:{'Authorization':'Bearer $t'});
    if(r.statusCode<200 || r.statusCode>=300) throw ApiException('Gagal menghapus user.');
  }

  Map<String,dynamic> _decode(http.Response r) {
    try { return Map<String,dynamic>.from(jsonDecode(r.body) as Map); }
    catch (_) { return {'message':r.body}; }
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override String toString() => message;
}
