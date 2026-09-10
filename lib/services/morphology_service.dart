import '../models/vocabulary.dart';

class MorphologyForm {
  const MorphologyForm(this.label, this.value, this.note);
  final String label;
  final String value;
  final String note;
}

class MorphologyService {
  static List<MorphologyForm> forms(Vocabulary word) {
    final w = word.word;
    final r = word.reading;
    if (w.isEmpty) return const [];

    if (w == 'する' || r == 'する') return _suru();
    if (w == '来る' || r == 'くる') return _kuru();
    if (_looksIAdjective(w, word.meaning)) return _iAdjective(w);
    if (_looksNaAdjective(word)) return _naAdjective(w);

    if (_looksVerb(w, r)) return _verb(w, r);
    return _noun(w);
  }

  static bool _looksIAdjective(String w, String meaning) =>
      w.endsWith('い') && !w.endsWith('ない') && !meaning.contains('saya');

  static bool _looksNaAdjective(Vocabulary v) {
    final m = v.meaning.toLowerCase();
    return m.contains('kata sifat') ||
        m.contains('bersifat') ||
        const {'静か', '元気', '便利', '有名', '好き', '嫌い', '上手', '下手', '大切'}
            .contains(v.word);
  }

  static bool _looksVerb(String w, String r) {
    if (r.endsWith('る') || r.endsWith('く') || r.endsWith('ぐ') ||
        r.endsWith('す') || r.endsWith('つ') || r.endsWith('ぬ') ||
        r.endsWith('ぶ') || r.endsWith('む') || r.endsWith('う')) {
      return true;
    }
    return w.endsWith('る') || w.endsWith('く') || w.endsWith('す') ||
        w.endsWith('む') || w.endsWith('ぶ') || w.endsWith('う');
  }

  static List<MorphologyForm> _verb(String w, String r) {
    // Prefer reading for inflection when the kanji spelling differs.
    final base = r.isNotEmpty ? r : w;
    const irregular = {'行く': '行っ', 'いく': 'いっ'};
    final isIchidan = base.endsWith('る') &&
        base.length >= 2 &&
        'いえ'.contains(base[base.length - 2]);

    String masu;
    String nai;
    String te;
    String ta;
    String nakereba;
    String potential;
    String volitional;
    String imperative;
    String conditional;

    if (isIchidan) {
      final stem = base.substring(0, base.length - 1);
      masu = '$stemます';
      nai = '$stemない';
      te = '$stemて';
      ta = '$stemた';
      nakereba = '$stemなければなりません';
      potential = '$stemられる';
      volitional = '$stemよう';
      imperative = '$stemろ';
      conditional = '$stemれば';
    } else {
      final last = base.substring(base.length - 1);
      final stem = base.substring(0, base.length - 1);
      const a = {'う':'わ','く':'か','ぐ':'が','す':'さ','つ':'た','ぬ':'な','ぶ':'ば','む':'ま','る':'ら'};
      const i = {'う':'い','く':'き','ぐ':'ぎ','す':'し','つ':'ち','ぬ':'に','ぶ':'び','む':'み','る':'り'};
      const e = {'う':'え','く':'け','ぐ':'げ','す':'せ','つ':'て','ぬ':'ね','ぶ':'べ','む':'め','る':'れ'};
      const o = {'う':'お','く':'こ','ぐ':'ご','す':'そ','つ':'と','ぬ':'の','ぶ':'ぼ','む':'も','る':'ろ'};
      final ai = a[last] ?? last;
      final ii = i[last] ?? last;
      final ei = e[last] ?? last;
      final oi = o[last] ?? last;
      masu = '$stem$iiます';
      nai = '$stem$aiない';
      nakereba = '$stem$aiなければなりません';
      potential = '$stem$eiる';
      volitional = '$stem$oiう';
      imperative = '$stem$ei';
      conditional = '$stem$eiば';

      if (irregular.containsKey(w)) {
        te = '${irregular[w]}て';
        ta = '${irregular[w]}た';
      } else if (last == 'う' || last == 'つ' || last == 'る') {
        te = '$stemって';
        ta = '$stemった';
      } else if (last == 'む' || last == 'ぶ' || last == 'ぬ') {
        te = '$stemんで';
        ta = '$stemんだ';
      } else if (last == 'く') {
        te = '$stemいて';
        ta = '$stemいた';
      } else if (last == 'ぐ') {
        te = '$stemいで';
        ta = '$stemいだ';
      } else if (last == 'す') {
        te = '$stemして';
        ta = '$stemした';
      } else {
        te = '$stemて';
        ta = '$stemた';
      }
    }

    return [
      MorphologyForm('Bentuk kamus', w, '辞書形 · bentuk dasar'),
      MorphologyForm('Masu', _replaceReading(w, r, masu), 'ます形 · sopan'),
      MorphologyForm('Nai', _replaceReading(w, r, nai), 'ない形 · negatif'),
      MorphologyForm('Te', _replaceReading(w, r, te), 'て形 · penghubung/perintah ringan'),
      MorphologyForm('Ta', _replaceReading(w, r, ta), 'た形 · lampau'),
      MorphologyForm('Nakereba narimasen', _replaceReading(w, r, nakereba), 'なければなりません · harus'),
      MorphologyForm('Potential', _replaceReading(w, r, potential), '可能形 · bisa'),
      MorphologyForm('Volitional', _replaceReading(w, r, volitional), '意向形 · mari/akan'),
      MorphologyForm('Imperative', _replaceReading(w, r, imperative), '命令形 · perintah tegas'),
      MorphologyForm('Conditional', _replaceReading(w, r, conditional), 'ば形 · jika'),
    ];
  }

  static List<MorphologyForm> _suru() => const [
    MorphologyForm('Bentuk kamus', 'する', '辞書形'),
    MorphologyForm('Masu', 'します', 'sopan'),
    MorphologyForm('Nai', 'しない', 'negatif'),
    MorphologyForm('Te', 'して', 'penghubung'),
    MorphologyForm('Ta', 'した', 'lampau'),
    MorphologyForm('Nakereba narimasen', 'しなければなりません', 'harus'),
    MorphologyForm('Potential', 'できる', 'bisa'),
    MorphologyForm('Volitional', 'しよう', 'mari/akan'),
    MorphologyForm('Imperative', 'しろ', 'perintah'),
    MorphologyForm('Conditional', 'すれば', 'jika'),
  ];

  static List<MorphologyForm> _kuru() => const [
    MorphologyForm('Bentuk kamus', '来る（くる）', '辞書形'),
    MorphologyForm('Masu', '来ます（きます）', 'sopan'),
    MorphologyForm('Nai', '来ない（こない）', 'negatif'),
    MorphologyForm('Te', '来て（きて）', 'penghubung'),
    MorphologyForm('Ta', '来た（きた）', 'lampau'),
    MorphologyForm('Nakereba narimasen', '来なければなりません（こなければなりません）', 'harus'),
    MorphologyForm('Potential', '来られる（こられる）', 'bisa datang'),
    MorphologyForm('Volitional', '来よう（こよう）', 'mari/akan datang'),
    MorphologyForm('Imperative', '来い（こい）', 'perintah'),
    MorphologyForm('Conditional', '来れば（くれば）', 'jika datang'),
  ];

  static List<MorphologyForm> _iAdjective(String w) {
    final stem = w.endsWith('い') ? w.substring(0, w.length - 1) : w;
    return [
      MorphologyForm('Bentuk dasar', w, 'い形容詞'),
      MorphologyForm('Negatif', '$stemくない', 'tidak ...'),
      MorphologyForm('Lampau', '$stemかった', 'dulu/telah ...'),
      MorphologyForm('Lampau negatif', '$stemくなかった', 'tidak ... dulu'),
      MorphologyForm('Te', '$stemくて', 'menghubungkan sifat'),
      MorphologyForm('Nakereba', '$stemければならない', 'harus ...'),
      MorphologyForm('Conditional', '$stemければ', 'jika ...'),
      MorphologyForm('Adverb', '$stemく', 'dengan cara ...'),
      MorphologyForm('Sopan', '$wです', 'penutup sopan'),
      MorphologyForm('Keterangan', 'とても$w', 'sangat ...'),
    ];
  }

  static List<MorphologyForm> _naAdjective(String w) => [
    MorphologyForm('Bentuk dasar', w, 'な形容詞'),
    MorphologyForm('Atributif', '$wな', 'sebelum kata benda'),
    MorphologyForm('Sopan', '$wです', 'deskripsi sopan'),
    MorphologyForm('Negatif', '$wではありません', 'tidak ...'),
    MorphologyForm('Lampau', '$wでした', 'dulu/telah ...'),
    MorphologyForm('Lampau negatif', '$wではありませんでした', 'tidak ... dulu'),
    MorphologyForm('Te', '$wで', 'menghubungkan sifat'),
    MorphologyForm('Conditional', '$wなら', 'jika/kalau ...'),
    MorphologyForm('Keharusan', '$wでなければなりません', 'harus ...'),
    MorphologyForm('Adverb', '$wに', 'secara ...'),
  ];

  static List<MorphologyForm> _noun(String w) => [
    MorphologyForm('Bentuk kamus', w, '名詞 · kata benda'),
    MorphologyForm('Sopan', '$wです', 'adalah ...'),
    MorphologyForm('Negatif', '$wではありません', 'bukan/tidak ...'),
    MorphologyForm('Lampau', '$wでした', 'dulu/telah ...'),
    MorphologyForm('Lampau negatif', '$wではありませんでした', 'bukan ... dulu'),
    MorphologyForm('Te', '$wで', 'menghubungkan keadaan'),
    MorphologyForm('Conditional', '$wなら', 'kalau ...'),
    MorphologyForm('Keharusan', '$wでなければなりません', 'harus berupa ...'),
    MorphologyForm('Kutipan', '$wだと言いました', 'mengatakan bahwa ...'),
    MorphologyForm('Sopan lampau', '$wでした', 'bentuk sopan lampau'),
  ];

  static String _replaceReading(String original, String reading, String generated) {
    // When the reading is available, preserve kanji and replace only the
    // kana suffix where possible. For difficult mixed words, display the
    // generated kana form so the learner sees the morphology clearly.
    if (reading.isEmpty || generated == reading) return generated;
    if (original == reading) return generated;
    return '$original → $generated';
  }
}
