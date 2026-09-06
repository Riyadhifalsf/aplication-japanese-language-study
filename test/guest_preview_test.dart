import 'package:flutter_test/flutter_test.dart';

import 'package:japanese_study/state/app_controller.dart';

void main() {
  group('AppController.previewSessionSize', () {
    test('tamu dibatasi 5 soal per sesi', () {
      expect(AppController.previewSessionSize(true, 15), 5);
      expect(AppController.previewSessionSize(true, 30), 5);
      expect(AppController.previewSessionSize(true, 5), 5);
      expect(AppController.previewSessionSize(true, 3), 3);
    });

    test('yang login tidak dibatasi', () {
      expect(AppController.previewSessionSize(false, 15), 15);
      expect(AppController.previewSessionSize(false, 30), 30);
    });
  });
}
