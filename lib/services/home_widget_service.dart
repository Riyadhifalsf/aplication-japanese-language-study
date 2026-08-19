import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  HomeWidgetService._();
  static final instance = HomeWidgetService._();
  static const widgetName = 'JapaneseStudyWidgetProvider';

  Future<void> initialize() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await HomeWidget.setAppGroupId('group.japanese.study');
    } catch (_) {}
  }

  Future<void> update({required int streak, required int xp, required String kanji}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await initialize();
      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.saveWidgetData<int>('xp', xp);
      await HomeWidget.saveWidgetData<String>('kanji', kanji);
      await HomeWidget.updateWidget(androidName: widgetName, name: widgetName);
    } catch (_) {}
  }
}
