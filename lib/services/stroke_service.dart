import 'dart:convert';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:path_drawing/path_drawing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StrokeService {
  StrokeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _sources = [
    'https://cdn.jsdelivr.net/gh/KanjiVG/kanjivg@master/kanji/',
    'https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/',
  ];

  Future<StrokeData> load(String character) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'stroke.${_hexName(character)}';
    final cached = prefs.getString(key);
    if (cached != null) {
      try {
        return StrokeData.fromPathStrings(
          (jsonDecode(cached) as List<dynamic>).cast<String>(),
        );
      } catch (_) {
        await prefs.remove(key);
      }
    }

    Object? lastError;
    for (final source in _sources) {
      try {
        final response = await _client
            .get(Uri.parse('$source${_hexName(character)}'))
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        final paths = RegExp(
          r'<path\b[^>]*\bd="([^"]+)"',
          caseSensitive: false,
        )
            .allMatches(response.body)
            .map((match) => match.group(1))
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
        if (paths.isEmpty) throw Exception('Data goresan kosong');
        await prefs.setString(key, jsonEncode(paths));
        return StrokeData.fromPathStrings(paths);
      } catch (error) {
        lastError = error;
      }
    }
    throw Exception(
      'Data urutan goresan belum dapat dimuat. '
      'Periksa internet lalu coba lagi. $lastError',
    );
  }

  String _hexName(String character) {
    final code = character.runes.first;
    return '${code.toRadixString(16).padLeft(5, '0')}.svg';
  }

  void dispose() => _client.close();
}

class StrokeData {
  StrokeData(this.paths)
      : metrics = paths
            .map(
              (path) => path.computeMetrics().toList(growable: false),
            )
            .toList(growable: false);

  final List<Path> paths;
  final List<List<PathMetric>> metrics;

  factory StrokeData.fromPathStrings(List<String> values) => StrokeData(
        values.map(parseSvgPathData).toList(growable: false),
      );
}
