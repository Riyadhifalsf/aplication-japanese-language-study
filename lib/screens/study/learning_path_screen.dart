import 'package:flutter/material.dart';

import '../curriculum/curriculum_path_screen.dart';

/// Backward-compatible entry point for older deep links.
///
/// The application now uses `CurriculumPathScreen` as the single Learning
/// surface. Keeping this wrapper avoids breaking old route names while
/// preventing the legacy, duplicate curriculum UI from drifting out of sync.
@Deprecated('Use CurriculumPathScreen instead.')
class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key, this.initialLevel = 'N5'});

  final String initialLevel;

  @override
  Widget build(BuildContext context) => CurriculumPathScreen(
        initialLevel: initialLevel,
      );
}
