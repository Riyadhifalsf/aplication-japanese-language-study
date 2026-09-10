import 'package:flutter_test/flutter_test.dart';

import 'package:japanese_study/main.dart';
import 'package:japanese_study/services/content_repository.dart';
import 'package:japanese_study/services/tts_service.dart';
import 'package:japanese_study/state/app_controller.dart';

void main() {
  testWidgets('shows the branded startup screen before state is ready',
      (WidgetTester tester) async {
    final controller = AppController(
      repository: ContentRepository(),
      tts: TtsService(),
    );

    await tester.pumpWidget(JapaneseStudyBootstrap(controller: controller));

    expect(find.text('Japanese Study'), findsOneWidget);
    expect(find.textContaining('Menyiapkan pengalaman'), findsOneWidget);
  });
}
