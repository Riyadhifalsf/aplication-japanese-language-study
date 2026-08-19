// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:japanese_study/main.dart';
import 'package:japanese_study/services/content_repository.dart';
import 'package:japanese_study/services/tts_service.dart';
import 'package:japanese_study/state/app_controller.dart';

void main() {
  testWidgets('shows the loading screen before content is ready',
      (WidgetTester tester) async {
    final controller = AppController(
      repository: ContentRepository(),
      tts: TtsService(),
    );

    await tester.pumpWidget(JapaneseStudyBootstrap(controller: controller));

    expect(find.textContaining('Menyiapkan 5.000 kanji'), findsOneWidget);
  });
}
