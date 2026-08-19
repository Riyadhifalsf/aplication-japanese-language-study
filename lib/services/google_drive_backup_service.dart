import 'dart:convert';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleProfileResult {
  const GoogleProfileResult({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  final String name;
  final String email;
  final String photoUrl;
}

class GoogleDriveBackupService {
  GoogleDriveBackupService({GoogleSignIn? signIn, http.Client? client})
      : _signIn = signIn ??
            GoogleSignIn(
              scopes: const [
                'email',
                'profile',
                'https://www.googleapis.com/auth/drive.file',
              ],
            ),
        _client = client ?? http.Client();

  final GoogleSignIn _signIn;
  final http.Client _client;

  GoogleSignInAccount? get currentUser => _signIn.currentUser;

  Future<GoogleProfileResult?> signIn() async {
    final account = await _signIn.signInSilently() ?? await _signIn.signIn();
    if (account == null) return null;
    return GoogleProfileResult(
      name: account.displayName ?? account.email.split('@').first,
      email: account.email,
      photoUrl: account.photoUrl ?? '',
    );
  }

  Future<void> signOut() => _signIn.signOut();

  Future<String> uploadProgressJson(String jsonText) async {
    final account = _signIn.currentUser ?? await _signIn.signInSilently();
    if (account == null) {
      throw Exception('Akun Google belum terhubung.');
    }
    final headers = await account.authHeaders;
    final now = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'japanese-study-backup-$now.json';
    final boundary = 'japaneseStudyBoundary$now';
    final metadata = jsonEncode({
      'name': filename,
      'mimeType': 'application/json',
      'description': 'Cadangan kemajuan Belajar Bahasa Jepang',
    });
    final body = BytesBuilder()
      ..add(utf8.encode('--$boundary\r\n'))
      ..add(utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'))
      ..add(utf8.encode(metadata))
      ..add(utf8.encode('\r\n--$boundary\r\n'))
      ..add(utf8.encode('Content-Type: application/json\r\n\r\n'))
      ..add(utf8.encode(jsonText))
      ..add(utf8.encode('\r\n--$boundary--'));

    final response = await _client.post(
      Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,webViewLink'),
      headers: {
        ...headers,
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      body: body.toBytes(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cadangan Google Drive gagal: HTTP ${response.statusCode} ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['webViewLink'] as String? ?? data['id'] as String? ?? filename;
  }

  Future<String> downloadLatestProgressJson() async {
    final account = _signIn.currentUser ?? await _signIn.signInSilently();
    if (account == null) {
      throw Exception('Akun Google belum terhubung.');
    }
    final headers = await account.authHeaders;
    final query = "name contains 'japanese-study-backup-' and mimeType = 'application/json' and trashed = false";
    final listUri = Uri.https('www.googleapis.com', '/drive/v3/files', {
      'q': query,
      'orderBy': 'createdTime desc',
      'pageSize': '1',
      'fields': 'files(id,name,createdTime)',
    });
    final listResponse = await _client.get(listUri, headers: headers);
    if (listResponse.statusCode < 200 || listResponse.statusCode >= 300) {
      throw Exception('Gagal membaca daftar cadangan: HTTP ${listResponse.statusCode}');
    }
    final listData = jsonDecode(listResponse.body) as Map<String, dynamic>;
    final files = (listData['files'] as List<dynamic>? ?? const []);
    if (files.isEmpty) {
      throw Exception('Cadangan Google Drive belum ditemukan.');
    }
    final file = files.first as Map<String, dynamic>;
    final id = file['id'] as String;
    final mediaUri = Uri.https('www.googleapis.com', '/drive/v3/files/$id', {
      'alt': 'media',
    });
    final mediaResponse = await _client.get(mediaUri, headers: headers);
    if (mediaResponse.statusCode < 200 || mediaResponse.statusCode >= 300) {
      throw Exception('Gagal mengunduh cadangan: HTTP ${mediaResponse.statusCode}');
    }
    return mediaResponse.body;
  }

  void dispose() => _client.close();
}
