import fs from 'node:fs';

const readJson = (path) => JSON.parse(fs.readFileSync(new URL(path, import.meta.url)));
const kanji = readJson('../assets/data/kanji.json');
const vocabulary = readJson('../assets/data/vocabulary.json');
const grammar = readJson('../assets/data/grammar.json');
const phrases = readJson('../assets/data/phrases.json');
const sentences = readJson('../assets/data/sentences.json');
const culture = readJson('../assets/data/culture.json');
const readings = readJson('../assets/data/readings.json');

const expectedKanji = {N5: 200, N4: 350, N3: 890, N2: 640, N1: 2920};
const expectedVocabulary = {N5: 1500, N4: 1400, N3: 2950, N2: 3250, N1: 900};

function counts(items) {
  return items.reduce((result, item) => {
    result[item.level] = (result[item.level] ?? 0) + 1;
    return result;
  }, {});
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function normalized(value) {
  return String(value ?? '')
    .toLowerCase()
    .normalize('NFKC')
    .replace(/\s+/g, ' ')
    .trim();
}

function duplicateKeys(items, keyFn) {
  const seen = new Map();
  for (const item of items) {
    const key = keyFn(item);
    if (!key) continue;
    const ids = seen.get(key) ?? [];
    ids.push(item.id);
    seen.set(key, ids);
  }
  return [...seen.entries()]
    .filter(([, ids]) => ids.length > 1)
    .map(([key, ids]) => ({key, ids}));
}

function englishTokens(value) {
  const text = normalized(value);
  const tokens = text.match(/\b[a-z]{3,}\b/g) ?? [];
  const allow = new Set([
    'japanese', 'nihongo', 'hiragana', 'katakana', 'kanji', 'romaji',
    'jlpt', 'jft', 'n5', 'n4', 'n3', 'n2', 'n1', 'wifi', 'email', 'google',
  ]);
  return [...new Set(tokens.filter((token) => !allow.has(token)))];
}

const kanjiCounts = counts(kanji);
const vocabularyCounts = counts(vocabulary);
assert(kanji.length === 5000, `Kanji: ${kanji.length}, seharusnya 5000`);
assert(vocabulary.length === 10000, `Kosakata: ${vocabulary.length}, seharusnya 10000`);
for (const [level, expected] of Object.entries(expectedKanji)) {
  assert(kanjiCounts[level] === expected, `${level}: ${kanjiCounts[level]}, seharusnya ${expected}`);
}
for (const [level, expected] of Object.entries(expectedVocabulary)) {
  assert(vocabularyCounts[level] === expected, `${level}: ${vocabularyCounts[level]}, seharusnya ${expected}`);
}

assert(new Set(kanji.map((item) => item.id)).size === kanji.length, 'ID kanji duplikat');
assert(new Set(vocabulary.map((item) => item.id)).size === vocabulary.length, 'ID kosakata duplikat');
assert(new Set(grammar.map((item) => item.id)).size === grammar.length, 'ID bunpou duplikat');
assert(new Set(phrases.map((item) => item.id)).size === phrases.length, 'ID frasa duplikat');
assert(new Set(sentences.map((item) => item.id)).size === sentences.length, 'ID kalimat duplikat');
assert(new Set(culture.map((item) => item.id)).size === culture.length, 'ID budaya duplikat');
assert(new Set(readings.map((item) => item.id)).size === readings.length, 'ID bacaan duplikat');

const duplicateReports = [
  ['kanji', kanji, (item) => `${normalized(item.char)}|${normalized(item.meaning)}`],
  ['kosakata', vocabulary, (item) => `${normalized(item.word)}|${normalized(item.reading)}`],
  ['bunpou', grammar, (item) => normalized(item.pattern)],
  ['frasa', phrases, (item) => `${normalized(item.japanese)}|${normalized(item.meaning)}`],
  ['kalimat', sentences, (item) => `${normalized(item.japanese)}|${normalized(item.meaning)}`],
  ['budaya', culture, (item) => `${normalized(item.title)}|${normalized(item.summary)}`],
  ['bacaan', readings, (item) => `${normalized(item.japanese)}|${normalized(item.meaning)}`],
].map(([name, items, keyFn]) => ({name, duplicates: duplicateKeys(items, keyFn)}));

const duplicateCount = duplicateReports.reduce((sum, report) => sum + report.duplicates.length, 0);
if (duplicateCount > 0) {
  console.error('DUPLIKAT KONTEN TERDETEKSI:');
  for (const report of duplicateReports) {
    for (const duplicate of report.duplicates.slice(0, 20)) {
      console.error(`- ${report.name}: ${duplicate.ids.join(', ')} => ${duplicate.key}`);
    }
  }
  process.exit(2);
}

const englishReports = [];
for (const [name, items, fields] of [
  ['kanji', kanji, ['meaning', 'radicalMeaning']],
  ['kosakata', vocabulary, ['meaning']],
  ['bunpou', grammar, ['title', 'explanation', 'formation']],
  ['frasa', phrases, ['meaning', 'note', 'politeness']],
  ['kalimat', sentences, ['meaning', 'note', 'pattern']],
  ['budaya', culture, ['title', 'summary', 'detail', 'example']],
  ['bacaan', readings, ['title', 'meaning']],
]) {
  for (const item of items) {
    const hits = fields.flatMap((field) => englishTokens(item[field]).map((token) => `${field}:${token}`));
    if (hits.length) englishReports.push({name, id: item.id, hits});
  }
}

if (englishReports.length > 0) {
  console.error(`KONTEN BERBAHASA INGGRIS TERDETEKSI: ${englishReports.length} item.`);
  for (const report of englishReports.slice(0, 50)) {
    console.error(`- ${report.name}/${report.id}: ${report.hits.join(', ')}`);
  }
  process.exit(3);
}

const vocabularyIds = new Set(vocabulary.map((item) => item.id));
const brokenReferences = kanji.flatMap((item) =>
  item.vocabIds
    .filter((id) => !vocabularyIds.has(id))
    .map((id) => `${item.char}:${id}`),
);
assert(brokenReferences.length === 0, `Referensi kosakata rusak: ${brokenReferences.slice(0, 10).join(', ')}`);
assert(grammar.length >= 25, 'Materi bunpou terlalu sedikit');

console.log(JSON.stringify({
  status: 'valid',
  kanji: kanji.length,
  kanjiCounts,
  vocabulary: vocabulary.length,
  vocabularyCounts,
  grammar: grammar.length,
  phrases: phrases.length,
  sentences: sentences.length,
  culture: culture.length,
  readings: readings.length,
  duplicateCount,
  englishReports: englishReports.length,
}, null, 2));
