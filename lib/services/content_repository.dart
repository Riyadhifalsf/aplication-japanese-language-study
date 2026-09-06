import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/server_config.dart';
import '../models/culture_item.dart';
import '../models/grammar_point.dart';
import '../models/kanji.dart';
import '../models/phrase_item.dart';
import '../models/reading_item.dart';
import '../models/sentence_item.dart';
import '../models/vocabulary.dart';

/// Decode JSON di isolate latar agar thread UI tidak macet saat cold start.
///
/// Harus fungsi top-level (syarat `compute`). String masuk, List/Map
/// primitif keluar — keduanya transferable antar isolate.
List<List<dynamic>> _decodeBundledJson(List<String> raws) =>
    raws.map((raw) => (jsonDecode(raw) as List<dynamic>)).toList();

/// Envelope server `{'data': [...]}` -> linya saja (null bila tak sesuai).
List<dynamic>? _decodeServerEnvelope(String raw) {
  try {
    final body = jsonDecode(raw);
    if (body is! Map || body['data'] is! List) return null;
    return body['data'] as List<dynamic>;
  } catch (_) {
    return null;
  }
}

List<List<dynamic>?> _decodeEnvelopes(List<String> raws) =>
    raws.map(_decodeServerEnvelope).toList();

class ContentRepository {
  static const _vocabularyOverridesKey = 'admin_vocabulary_overrides_v1';
  static const _vocabularyDeletedKey = 'admin_vocabulary_deleted_v1';
  static const _vocabularyAddedKey = 'admin_vocabulary_added_v1';
  static const _contentTypes = [
    'kanji',
    'vocabulary',
    'grammar',
    'phrases',
    'sentences',
    'culture',
    'readings',
  ];
  List<Kanji> kanji = const [];
  List<Vocabulary> vocabulary = const [];
  List<GrammarPoint> grammar = const [];
  List<PhraseItem> phrases = const [];
  List<SentenceItem> sentences = const [];
  List<CultureItem> culture = const [];
  List<ReadingItem> readings = const [];

  Map<int, Kanji> _kanjiById = const {};
  Map<int, Vocabulary> _vocabularyById = const {};
  Map<String, List<Kanji>> _kanjiByLevel = const {};
  Map<String, List<Vocabulary>> _vocabularyByLevel = const {};
  Map<String, int> _kanjiLevelCounts = const {};
  Map<String, int> _vocabularyLevelCounts = const {};
  Map<int, String> _kanjiSearchText = const {};
  Map<int, String> _vocabularySearchText = const {};
  Map<String, String> _grammarSearchText = const {};
  Map<String, String> _phraseSearchText = const {};
  Map<String, String> _sentenceSearchText = const {};
  Map<String, String> _cultureSearchText = const {};
  Map<String, String> _readingSearchText = const {};
  Set<String> _phraseCategories = const {};
  Set<String> _sentenceCategories = const {};
  Set<String> _cultureCategories = const {};
  Set<String> _readingCategories = const {};
  Set<String> _themes = const {};
  Future<void>? _loadFuture;

  Future<void> load() => _loadFuture ??= _load();

  Future<Map<String, List<dynamic>>?> _fetchServerData() async {
    final client = http.Client();
    try {
      Future<String?> fetchOne(String type) async {
        try {
          final uri = Uri.parse('$serverBaseUrl/content/$type?limit=20000');
          final response =
              await client.get(uri).timeout(const Duration(seconds: 3));
          if (response.statusCode != 200) return null;
          return response.body;
        } catch (_) {
          return null;
        }
      }
      // Paralel (bukan sekuensial) agar total tunggu ~3 detik, bukan ~28 detik.
      final raws =
          await Future.wait([for (final type in _contentTypes) fetchOne(type)]);
      for (final raw in raws) {
        if (raw == null) return null;
      }
      // Decode di isolate latar (body bisa puluhan ribu baris).
      final decoded =
          await compute(_decodeEnvelopes, raws.cast<String>());
      final out = <String, List<dynamic>>{};
      for (var i = 0; i < _contentTypes.length; i++) {
        final items = decoded[i];
        if (items == null) return null;
        out[_contentTypes[i]] = items;
      }
      return out;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  List<dynamic> _rawAt(Map<String, List<dynamic>>? server,
      List<List<dynamic>>? decoded, int index) {
    if (server != null) return server[_contentTypes[index]] ?? const [];
    return decoded![index];
  }

  /// Dipanggil saat refresh server di background selesai.
  void Function()? onRefreshed;

  Future<void> _load() async {
    // Bundled lokal dulu (cepat, offline) — urutan layar tidak berubah.
    final results = await Future.wait([
      rootBundle.loadString('assets/data/kanji.json'),
      rootBundle.loadString('assets/data/vocabulary.json'),
      rootBundle.loadString('assets/data/grammar.json'),
      rootBundle.loadString('assets/data/phrases.json'),
      rootBundle.loadString('assets/data/sentences.json'),
      rootBundle.loadString('assets/data/culture.json'),
      rootBundle.loadString('assets/data/readings.json'),
    ]);
    // Parse 7MB JSON di isolate latar — thread UI tetap responsif.
    final decoded = await compute(_decodeBundledJson, results);
    await _buildFromRaw(null, decoded);
    // Server menyusul diam-diam di background tanpa menahan UI.
    unawaited(_refreshFromServer());
  }

  Future<void> _refreshFromServer() async {
    await refreshFromServer();
  }

  /// Paksa sinkron dari server (dipakai unduhan paket offline).
  /// true bila server memberi data segar; false = tetap pakai bundel.
  Future<bool> refreshFromServer() async {
    final serverData = await _fetchServerData();
    if (serverData == null) return false;
    await _buildFromRaw(serverData, null);
    onRefreshed?.call();
    return true;
  }

  Future<void> _buildFromRaw(
    Map<String, List<dynamic>>? serverData,
    List<List<dynamic>>? results,
  ) async {
    kanji = _rawAt(serverData, results, 0)
        .map((e) => Kanji.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final baseVocabulary = _rawAt(serverData, results, 1)
        .map((e) => Vocabulary.fromJson(e as Map<String, dynamic>))
        .toList(growable: true);
    final prefs = await SharedPreferences.getInstance();
    final rawOverrides = prefs.getString(_vocabularyOverridesKey);
    if (rawOverrides != null && rawOverrides.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawOverrides) as Map<String, dynamic>;
        final overrides = <int, Vocabulary>{};
        for (final entry in decoded.entries) {
          final id = int.tryParse(entry.key);
          if (id == null || entry.value is! Map<String, dynamic>) continue;
          overrides[id] = Vocabulary.fromJson(entry.value as Map<String, dynamic>);
        }
        for (var i = 0; i < baseVocabulary.length; i++) {
          final replacement = overrides[baseVocabulary[i].id];
          if (replacement != null) baseVocabulary[i] = replacement;
        }
      } catch (_) {
        // Override lokal yang rusak diabaikan.
      }
    }
    final deletedRaw = prefs.getStringList(_vocabularyDeletedKey) ?? const [];
    final deletedIds = deletedRaw.map(int.tryParse).whereType<int>().toSet();
    baseVocabulary.removeWhere((item) => deletedIds.contains(item.id));
    final addedRaw = prefs.getStringList(_vocabularyAddedKey) ?? const [];
    for (final raw in addedRaw) {
      try {
        final item = Vocabulary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (baseVocabulary.every((existing) => existing.id != item.id)) {
          baseVocabulary.add(item);
        }
      } catch (_) {}
    }
    vocabulary = List.unmodifiable(baseVocabulary);
    grammar = _rawAt(serverData, results, 2)
        .map((e) => GrammarPoint.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    phrases = _rawAt(serverData, results, 3)
        .map((e) => PhraseItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    sentences = _rawAt(serverData, results, 4)
        .map((e) => SentenceItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    culture = _rawAt(serverData, results, 5)
        .map((e) => CultureItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    readings = _rawAt(serverData, results, 6)
        .map((e) => ReadingItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _kanjiById = {for (final item in kanji) item.id: item};
    _vocabularyById = {
      for (final item in vocabulary) item.id: item,
    };
    _kanjiByLevel = {
      for (final level in ['N5', 'N4', 'N3', 'N2', 'N1'])
        level:
            kanji.where((item) => item.level == level).toList(growable: false),
    };
    _vocabularyByLevel = {
      for (final level in ['N5', 'N4', 'N3', 'N2', 'N1'])
        level: vocabulary
            .where((item) => item.level == level)
            .toList(growable: false),
    };
    _kanjiLevelCounts = {
      for (final entry in _kanjiByLevel.entries) entry.key: entry.value.length,
    };
    _vocabularyLevelCounts = {
      for (final entry in _vocabularyByLevel.entries)
        entry.key: entry.value.length,
    };
    _kanjiSearchText = {
      for (final item in kanji)
        item.id: [
          item.character,
          item.meaning,
          item.onyomi,
          item.kunyomi,
          ...item.themes,
        ].join(' ').toLowerCase(),
    };
    _vocabularySearchText = {
      for (final item in vocabulary)
        item.id: '${item.word} ${item.reading} ${item.meaning}'.toLowerCase(),
    };
    _grammarSearchText = {
      for (final item in grammar)
        item.id:
            '${item.pattern} ${item.title} ${item.explanation}'.toLowerCase(),
    };
    _phraseSearchText = {
      for (final item in phrases)
        item.id: [
          item.category,
          item.japanese,
          item.reading,
          item.meaning,
          item.politeness,
          item.note,
          ...item.tags,
        ].join(' ').toLowerCase(),
    };
    _sentenceSearchText = {
      for (final item in sentences)
        item.id: [
          item.level,
          item.category,
          item.japanese,
          item.reading,
          item.meaning,
          item.pattern,
          item.note,
        ].join(' ').toLowerCase(),
    };
    _cultureSearchText = {
      for (final item in culture)
        item.id: [
          item.category,
          item.title,
          item.summary,
          item.detail,
          item.example,
          ...item.tips,
        ].join(' ').toLowerCase(),
    };
    _readingSearchText = {
      for (final item in readings)
        item.id: [
          item.level,
          item.category,
          item.title,
          item.japanese,
          item.reading,
          item.meaning,
        ].join(' ').toLowerCase(),
    };
    _phraseCategories = phrases.map((item) => item.category).toSet();
    _sentenceCategories = sentences.map((item) => item.category).toSet();
    _cultureCategories = culture.map((item) => item.category).toSet();
    _readingCategories = readings.map((item) => item.category).toSet();
    _themes = kanji.expand((item) => item.themes).toSet();
  }

  Kanji? kanjiById(int id) => _kanjiById[id];

  Vocabulary? vocabularyById(int id) => _vocabularyById[id];

  List<Vocabulary> directVocabulary(Kanji item) => item.vocabularyIds
      .map(vocabularyById)
      .whereType<Vocabulary>()
      .toList(growable: false);

  List<Vocabulary> studyVocabulary(Kanji item, {int limit = 10}) {
    final output = <Vocabulary>[];
    final used = <int>{};
    void addFrom(Kanji source) {
      for (final id in source.vocabularyIds) {
        final word = vocabularyById(id);
        if (word != null && used.add(word.id)) output.add(word);
        if (output.length >= limit) return;
      }
    }

    addFrom(item);
    if (output.length < 4) {
      for (final relatedId in item.relatedIds) {
        final related = kanjiById(relatedId);
        if (related != null) addFrom(related);
        if (output.length >= limit) break;
      }
    }
    return output.take(limit).toList(growable: false);
  }

  List<Kanji> relatedKanji(Kanji item) =>
      item.relatedIds.map(kanjiById).whereType<Kanji>().toList(growable: false);

  Set<String> get themes => _themes;

  Set<String> get phraseCategories => _phraseCategories;

  Set<String> get sentenceCategories => _sentenceCategories;

  Set<String> get cultureCategories => _cultureCategories;

  Set<String> get readingCategories => _readingCategories;

  List<Kanji> kanjiForLevel(String level) => _kanjiByLevel[level] ?? const [];

  List<Vocabulary> vocabularyForLevel(String level) =>
      _vocabularyByLevel[level] ?? const [];

  String kanjiSearchText(int id) => _kanjiSearchText[id] ?? '';

  String vocabularySearchText(int id) => _vocabularySearchText[id] ?? '';

  String grammarSearchText(String id) => _grammarSearchText[id] ?? '';

  String phraseSearchText(String id) => _phraseSearchText[id] ?? '';

  String sentenceSearchText(String id) => _sentenceSearchText[id] ?? '';

  String cultureSearchText(String id) => _cultureSearchText[id] ?? '';

  String readingSearchText(String id) => _readingSearchText[id] ?? '';

  Future<void> _writeOverrides(Map<String, dynamic> overrides) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vocabularyOverridesKey, jsonEncode(overrides));
  }

  Future<Map<String, dynamic>> _readOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vocabularyOverridesKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _reindexVocabulary() async {
    vocabulary = List.unmodifiable(vocabulary);
    _vocabularyById = {for (final entry in vocabulary) entry.id: entry};
    _vocabularyByLevel = {
      for (final level in ['N5', 'N4', 'N3', 'N2', 'N1'])
        level: vocabulary.where((x) => x.level == level).toList(growable: false),
    };
    _vocabularyLevelCounts = {for (final entry in _vocabularyByLevel.entries) entry.key: entry.value.length};
    _vocabularySearchText = {for (final x in vocabulary) x.id: '${x.word} ${x.reading} ${x.meaning}'.toLowerCase()};
  }

  Future<void> updateVocabulary(Vocabulary item) async {
    final index = vocabulary.indexWhere((x) => x.id == item.id);
    if (index < 0) {
      throw StateError('Kotoba dengan ID ${item.id} tidak ditemukan.');
    }
    final updated = List<Vocabulary>.from(vocabulary)..[index] = item;
    vocabulary = updated;
    await _reindexVocabulary();
    final overrides = await _readOverrides();
    overrides[item.id.toString()] = item.toJson();
    await _writeOverrides(overrides);
  }

  Future<void> addVocabulary(Vocabulary item) async {
    if (_vocabularyById.containsKey(item.id)) {
      throw StateError('ID kotoba ${item.id} sudah digunakan.');
    }
    vocabulary = [...vocabulary, item];
    await _reindexVocabulary();
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_vocabularyAddedKey) ?? <String>[];
    existing.removeWhere((raw) {
      try {
        return Vocabulary.fromJson(jsonDecode(raw) as Map<String, dynamic>).id == item.id;
      } catch (_) {
        return false;
      }
    });
    existing.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_vocabularyAddedKey, existing);
  }

  Future<void> deleteVocabulary(int id) async {
    final exists = vocabulary.any((x) => x.id == id);
    if (!exists) return;
    vocabulary = vocabulary.where((x) => x.id != id).toList(growable: false);
    await _reindexVocabulary();
    final prefs = await SharedPreferences.getInstance();
    final deleted = prefs.getStringList(_vocabularyDeletedKey) ?? <String>[];
    if (!deleted.contains(id.toString())) deleted.add(id.toString());
    await prefs.setStringList(_vocabularyDeletedKey, deleted);
    final added = prefs.getStringList(_vocabularyAddedKey) ?? <String>[];
    added.removeWhere((raw) {
      try {
        return Vocabulary.fromJson(jsonDecode(raw) as Map<String, dynamic>).id == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_vocabularyAddedKey, added);
  }

  Future<void> resetVocabulary(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final overrides = await _readOverrides();
    overrides.remove(id.toString());
    await _writeOverrides(overrides);
    final deleted = prefs.getStringList(_vocabularyDeletedKey) ?? <String>[];
    deleted.remove(id.toString());
    await prefs.setStringList(_vocabularyDeletedKey, deleted);
    final added = prefs.getStringList(_vocabularyAddedKey) ?? <String>[];
    added.removeWhere((raw) {
      try {
        return Vocabulary.fromJson(jsonDecode(raw) as Map<String, dynamic>).id == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_vocabularyAddedKey, added);
    await loadFresh();
  }

  Future<void> loadFresh() async {
    _loadFuture = null;
    await load();
  }

  List<Kanji> kanjiUsingVocabulary(int vocabularyId) => kanji
      .where((k) => k.vocabularyIds.contains(vocabularyId))
      .toList(growable: false);

  int levelCount(String level) => _kanjiLevelCounts[level] ?? 0;

  int vocabularyLevelCount(String level) => _vocabularyLevelCounts[level] ?? 0;
}
