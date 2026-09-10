/// Lightweight Hepburn-style romaji conversion for beginner N5 hints.
class Romaji {
  Romaji._();

  static const _table = <String, String>{
    'きゃ':'kya','きゅ':'kyu','きょ':'kyo','ぎゃ':'gya','ぎゅ':'gyu','ぎょ':'gyo',
    'しゃ':'sha','しゅ':'shu','しょ':'sho','じゃ':'ja','じゅ':'ju','じょ':'jo',
    'ちゃ':'cha','ちゅ':'chu','ちょ':'cho','ぢゃ':'ja','ぢゅ':'ju','ぢょ':'jo',
    'にゃ':'nya','にゅ':'nyu','にょ':'nyo','ひゃ':'hya','ひゅ':'hyu','ひょ':'hyo',
    'びゃ':'bya','びゅ':'byu','びょ':'byo','ぴゃ':'pya','ぴゅ':'pyu','ぴょ':'pyo',
    'みゃ':'mya','みゅ':'myu','みょ':'myo','りゃ':'rya','りゅ':'ryu','りょ':'ryo',
    'てぃ':'ti','でぃ':'di','とぅ':'tu','どぅ':'du','ふぁ':'fa','ふぃ':'fi','ふぇ':'fe','ふぉ':'fo',
    'うぃ':'wi','うぇ':'we','うぉ':'wo','しぇ':'she','ちぇ':'che','じぇ':'je',
    'あ':'a','い':'i','う':'u','え':'e','お':'o','か':'ka','き':'ki','く':'ku','け':'ke','こ':'ko',
    'が':'ga','ぎ':'gi','ぐ':'gu','げ':'ge','ご':'go','さ':'sa','し':'shi','す':'su','せ':'se','そ':'so',
    'ざ':'za','じ':'ji','ず':'zu','ぜ':'ze','ぞ':'zo','た':'ta','ち':'chi','つ':'tsu','て':'te','と':'to',
    'だ':'da','ぢ':'ji','づ':'zu','で':'de','ど':'do','な':'na','に':'ni','ぬ':'nu','ね':'ne','の':'no',
    'は':'ha','ひ':'hi','ふ':'fu','へ':'he','ほ':'ho','ば':'ba','び':'bi','ぶ':'bu','べ':'be','ぼ':'bo',
    'ぱ':'pa','ぴ':'pi','ぷ':'pu','ぺ':'pe','ぽ':'po','ま':'ma','み':'mi','む':'mu','め':'me','も':'mo',
    'や':'ya','ゆ':'yu','よ':'yo','ら':'ra','り':'ri','る':'ru','れ':'re','ろ':'ro','わ':'wa','を':'o','ん':'n',
    'ぁ':'a','ぃ':'i','ぅ':'u','ぇ':'e','ぉ':'o','っ':'',
    'ア':'a','イ':'i','ウ':'u','エ':'e','オ':'o','カ':'ka','キ':'ki','ク':'ku','ケ':'ke','コ':'ko',
    'サ':'sa','シ':'shi','ス':'su','セ':'se','ソ':'so','タ':'ta','チ':'chi','ツ':'tsu','テ':'te','ト':'to',
    'ナ':'na','ニ':'ni','ヌ':'nu','ネ':'ne','ノ':'no','ハ':'ha','ヒ':'hi','フ':'fu','ヘ':'he','ホ':'ho',
    'マ':'ma','ミ':'mi','ム':'mu','メ':'me','モ':'mo','ヤ':'ya','ユ':'yu','ヨ':'yo','ラ':'ra','リ':'ri','ル':'ru','レ':'re','ロ':'ro','ワ':'wa','ヲ':'o','ン':'n',
    'ガ':'ga','ギ':'gi','グ':'gu','ゲ':'ge','ゴ':'go','ザ':'za','ジ':'ji','ズ':'zu','ゼ':'ze','ゾ':'zo',
    'ダ':'da','ヂ':'ji','ヅ':'zu','デ':'de','ド':'do','バ':'ba','ビ':'bi','ブ':'bu','ベ':'be','ボ':'bo','パ':'pa','ピ':'pi','プ':'pu','ペ':'pe','ポ':'po',
  };

  static String toRomaji(String text) {
    final out = StringBuffer();
    for (var i = 0; i < text.length;) {
      if (text[i] == 'っ' || text[i] == 'ッ') {
        if (i + 1 < text.length) {
          final next = _readToken(text, i + 1);
          if (next.isNotEmpty) out.write(next[0]);
        }
        i++;
        continue;
      }
      final pair = i + 1 < text.length ? text.substring(i, i + 2) : '';
      if (_table.containsKey(pair)) {
        out.write(_table[pair]);
        i += 2;
        continue;
      }
      final token = _readToken(text, i);
      out.write(token.isEmpty ? text[i] : token);
      i += 1;
    }
    return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _readToken(String text, int index) {
    if (index >= text.length) return '';
    if (index + 1 < text.length) {
      final pair = text.substring(index, index + 2);
      if (_table.containsKey(pair)) return _table[pair]!;
    }
    return _table[text[index]] ?? text[index];
  }
}
