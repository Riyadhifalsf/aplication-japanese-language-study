import fs from 'node:fs';

const kanji = JSON.parse(
  fs.readFileSync(new URL('../assets/data/kanji.json', import.meta.url)),
);
const vocabulary = JSON.parse(
  fs.readFileSync(new URL('../assets/data/vocabulary.json', import.meta.url)),
);
const grammar = JSON.parse(
  fs.readFileSync(new URL('../assets/data/grammar.json', import.meta.url)),
);

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

const kanjiCounts = counts(kanji);
const vocabularyCounts = counts(vocabulary);
assert(kanji.length === 5000, `Kanji: ${kanji.length}, seharusnya 5000`);
assert(
  vocabulary.length === 10000,
  `Kosakata: ${vocabulary.length}, seharusnya 10000`,
);
for (const [level, expected] of Object.entries(expectedKanji)) {
  assert(
    kanjiCounts[level] === expected,
    `${level}: ${kanjiCounts[level]}, seharusnya ${expected}`,
  );
}
for (const [level, expected] of Object.entries(expectedVocabulary)) {
  assert(
    vocabularyCounts[level] === expected,
    `${level}: ${vocabularyCounts[level]}, seharusnya ${expected}`,
  );
}
assert(new Set(kanji.map((item) => item.id)).size === kanji.length, 'ID kanji duplikat');
assert(
  new Set(vocabulary.map((item) => item.id)).size === vocabulary.length,
  'ID kosakata duplikat',
);
assert(grammar.length >= 25, 'Materi bunpou terlalu sedikit');

const vocabularyIds = new Set(vocabulary.map((item) => item.id));
const brokenReferences = kanji.flatMap((item) =>
  item.vocabIds
    .filter((id) => !vocabularyIds.has(id))
    .map((id) => `${item.char}:${id}`),
);
assert(
  brokenReferences.length === 0,
  `Referensi kosakata rusak: ${brokenReferences.slice(0, 10).join(', ')}`,
);

console.log(
  JSON.stringify(
    {
      status: 'valid',
      kanji: kanji.length,
      kanjiCounts,
      vocabulary: vocabulary.length,
      vocabularyCounts,
      grammar: grammar.length,
    },
    null,
    2,
  ),
);
