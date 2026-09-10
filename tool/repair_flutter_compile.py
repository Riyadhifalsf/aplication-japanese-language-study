from pathlib import Path


def read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def write(path: str, text: str) -> None:
    Path(path).write_text(text, encoding="utf-8")


# MasteryTier.color used by HomeScreen.
p = "lib/state/app_controller.dart"
s = read(p)
needle = "  String get label => 'JLPT ${name.toUpperCase()}';\n"
addition = needle + """
  Color get color {
    switch (this) {
      case MasteryTier.n5:
        return Colors.blueGrey;
      case MasteryTier.n4:
        return Colors.teal;
      case MasteryTier.n3:
        return Colors.indigo;
      case MasteryTier.n2:
        return Colors.deepPurple;
      case MasteryTier.n1:
        return Colors.amber.shade800;
    }
  }
"""
if "Color get color {" not in s:
    if needle not in s:
        raise SystemExit("MasteryTier label getter not found")
    write(p, s.replace(needle, addition, 1))


# Restore the weekly streak day widget.
p = "lib/screens/home/home_screen.dart"
s = read(p)
marker = "class _TodayKanjiCarousel extends StatelessWidget {"
widget = """class _KanjiStreak extends StatelessWidget {
  const _KanjiStreak({
    required this.item,
    required this.active,
    required this.selected,
  });

  final String item;
  final bool active;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
      decoration: BoxDecoration(
        color: active ? cs.primary : cs.surface.withValues(alpha: .48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? cs.onPrimaryContainer : cs.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: active ? cs.onPrimary : cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            active ? Icons.check_circle_rounded : Icons.remove_rounded,
            size: 15,
            color: active ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

"""
if "class _KanjiStreak extends StatelessWidget {" not in s:
    if marker not in s:
        raise SystemExit("Home streak insertion marker not found")
    write(p, s.replace(marker, widget + marker, 1))


# Fix current lesson navigation call.
p = "lib/screens/curriculum/curriculum_path_screen.dart"
s = read(p)
old = "_openChapter(context, app, currentUnit)"
if old in s:
    write(p, s.replace(old, "_openChapter(context, app, level, currentUnit)", 1))


# Remove navigation code accidentally inserted into _askComplete and restore
# unitLessons on the guided-practice state.
p = "lib/screens/curriculum/curriculum_lesson_detail_screen.dart"
s = read(p)
bad = """            if (!isTest && done && nextLesson != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _continueToNextLesson(context, nextLesson),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text('Lanjut ke ${CurriculumCatalogData.unitById(widget.lesson.unitId)?.sequence ?? ''}.${unitLessons.indexWhere((lesson) => lesson.id == nextLesson.id) + 1}'),
                ),
              ),
              const SizedBox(height: 10),
            ],
"""
if bad in s:
    s = s.replace(bad, "", 1)
needle = "  CurriculumLesson? _nextLessonInChapter() {"
helper = """  List<CurriculumLesson> get unitLessons {
    final unit = CurriculumCatalogData.unitById(widget.lesson.unitId);
    final lessons = unit?.lessons
            .where((lesson) => lesson.sequence > 0)
            .toList() ??
        <CurriculumLesson>[];
    lessons.sort((a, b) => a.sequence.compareTo(b.sequence));
    return lessons;
  }

"""
if "List<CurriculumLesson> get unitLessons {" not in s:
    if needle not in s:
        raise SystemExit("guided practice insertion marker not found")
    s = s.replace(needle, helper + needle, 1)
write(p, s)


# No unresolved merge markers in the files touched by this repair.
for path in [
    "lib/screens/curriculum/curriculum_path_screen.dart",
    "lib/screens/curriculum/curriculum_lesson_detail_screen.dart",
]:
    text = read(path)
    if any(x in text for x in ("<<<<<<<", "=======", ">>>>>>>")):
        raise SystemExit(f"Git conflict marker remains in {path}")
