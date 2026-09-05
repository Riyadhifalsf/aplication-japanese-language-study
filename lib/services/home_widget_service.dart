/// Home-screen widget integration is intentionally disabled in the zero-warning build.
/// The rest of the application keeps the same API so callers do not need changes.
class HomeWidgetService {
  HomeWidgetService._();
  static final instance = HomeWidgetService._();

  Future<void> initialize() async {}

  Future<void> update({
    required int streak,
    required int xp,
    required String kanji,
  }) async {}
}
