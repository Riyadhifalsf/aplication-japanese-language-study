import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/culture_item.dart';
import '../models/grammar_point.dart';
import '../models/kanji.dart';
import '../models/phrase_item.dart';
import '../models/reading_item.dart';
import '../models/sentence_item.dart';
import '../models/vocabulary.dart';

class ContentRepository {
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

  Future<void> _load() async {
    final results = await Future.wait([
      rootBundle.loadString('assets/data/kanji.json'),
      rootBundle.loadString('assets/data/vocabulary.json'),
      rootBundle.loadString('assets/data/grammar.json'),
      rootBundle.loadString('assets/data/phrases.json'),
      rootBundle.loadString('assets/data/sentences.json'),
      rootBundle.loadString('assets/data/culture.json'),
      rootBundle.loadString('assets/data/readings.json'),
    ]);
    kanji = (jsonDecode(results[0]) as List<dynamic>)
        .map((e) => Kanji.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    vocabulary = (jsonDecode(results[1]) as List<dynamic>)
        .map((e) => Vocabulary.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    grammar = (jsonDecode(results[2]) as List<dynamic>)
        .map((e) => GrammarPoint.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    phrases = (jsonDecode(results[3]) as List<dynamic>)
        .map((e) => PhraseItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    sentences = (jsonDecode(results[4]) as List<dynamic>)
        .map((e) => SentenceItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    culture = (jsonDecode(results[5]) as List<dynamic>)
        .map((e) => CultureItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    readings = (jsonDecode(results[6]) as List<dynamic>)
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

  int levelCount(String level) => _kanjiLevelCounts[level] ?? 0;

  int vocabularyLevelCount(String level) => _vocabularyLevelCounts[level] ?? 0;
}
