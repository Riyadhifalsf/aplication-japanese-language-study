import 'dart:io';

void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln(
      'AndroidManifest.xml belum ada. Jalankan flutter create terlebih dahulu.',
    );
    exitCode = 1;
    return;
  }

  var text = manifest.readAsStringSync();
  const permission =
      '<uses-permission android:name="android.permission.INTERNET"/>';
  if (!text.contains(permission)) {
    text = text.replaceFirstMapped(
      RegExp(r'(<manifest\b[^>]*>)'),
      (match) => '${match.group(0)}\n    $permission',
    );
  }
  const ttsQuery = '''
    <queries>
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
    </queries>''';
  if (!text.contains('android.intent.action.TTS_SERVICE')) {
    text = text.replaceFirstMapped(
      RegExp(r'(<application\b)'),
      (match) => '$ttsQuery\n\n    ${match.group(0)}',
    );
  }
  text = text.replaceFirst(
    RegExp(r'android:label="[^"]*"'),
    'android:label="Japanese Study"',
  );
  manifest.writeAsStringSync(text);
  stdout.writeln('AndroidManifest disiapkan untuk TTS dan KanjiVG.');
}
