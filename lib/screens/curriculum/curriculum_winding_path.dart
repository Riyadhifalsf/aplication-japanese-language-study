import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_models.dart';

/// View-model satu node Bab pada learning roadmap.
class UnitPathNode {
  const UnitPathNode({
    required this.unit,
    required this.done,
    required this.total,
    required this.locked,
    required this.isCurrent,
    required this.nextLesson,
  });

  final CurriculumUnit unit;
  final int done;
  final int total;
  final bool locked;
  final bool isCurrent;
  final CurriculumLesson? nextLesson;

  bool get completed => total > 0 && done >= total;
}

/// Learning roadmap vertikal.
///
/// Setiap Bab tampil terus ke bawah. Setiap Bab membuka ringkasan sub-bab,
/// progress, dan satu aksi utama. Tidak ada jalur zig-zag yang membuat posisi
/// materi sulit dipindai pada layar ponsel.
class CurriculumWindingPath extends StatelessWidget {
  const CurriculumWindingPath({
    super.key,
    required this.nodes,
    required this.onOpen,
  });

  final List<UnitPathNode> nodes;
  final ValueChanged<UnitPathNode> onOpen;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < nodes.length; i++) ...[
          _ChapterRoadmapCard(
            node: nodes[i],
            chapterNumber: i + 1,
            onOpen: () => onOpen(nodes[i]),
          ),
          if (i < nodes.length - 1)
            Container(
              width: 4,
              height: 16,
              margin: const EdgeInsets.symmetric(vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
        ],
      ],
    );
  }
}

class _ChapterRoadmapCard extends StatelessWidget {
  const _ChapterRoadmapCard({
    required this.node,
    required this.chapterNumber,
    required this.onOpen,
  });

  final UnitPathNode node;
  final int chapterNumber;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed = node.completed;
    final progress = node.total == 0 ? 0.0 : (node.done / node.total).clamp(0.0, 1.0);
    final accent = completed ? const Color(0xFF17A673) : cs.primary;
    final lessons = [...node.unit.lessons]..sort((a, b) => a.sequence.compareTo(b.sequence));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: node.locked ? null : onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: completed
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: accent, size: 24),
                            const SizedBox(width: 7),
                            Text(
                              'BAB $chapterNumber',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: accent),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_rounded, color: accent, size: 24),
                            const SizedBox(width: 7),
                            Text(
                              'BAB $chapterNumber',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: accent),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(node.unit.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, height: 1.18, fontWeight: FontWeight.w900)),
                    if (node.unit.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(node.unit.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant, height: 1.25)),
                    ],
                  ]),
                ),
                const SizedBox(width: 8),
                Icon(node.locked ? Icons.lock_rounded : Icons.chevron_right_rounded, color: node.locked ? cs.onSurfaceVariant : accent),
              ]),
              const SizedBox(height: 13),
              Row(children: [
                Expanded(child: Text('Pelajaran selesai ${node.done}/${node.total}', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700, fontSize: 12))),
                if (node.nextLesson != null && !completed)
                  Text('Lanjut: ${node.nextLesson!.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 11)),
              ]),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: 9),
              if (lessons.isNotEmpty)
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (var i = 0; i < lessons.length && i < 5; i++)
                      _LessonChip(
                        number: '$chapterNumber.${i + 1}',
                        title: lessons[i].title,
                        highlighted: node.nextLesson?.id == lessons[i].id,
                      ),
                    if (lessons.length > 5)
                      _LessonChip(number: '+${lessons.length - 5}', title: 'sub-bab lainnya', highlighted: false),
                  ],
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: node.locked ? null : onOpen,
                  icon: Icon(completed ? Icons.replay_rounded : Icons.arrow_forward_rounded, size: 18),
                  label: Text(completed ? 'Ulangi Bab' : 'Lanjut'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonChip extends StatelessWidget {
  const _LessonChip({required this.number, required this.title, required this.highlighted});
  final String number;
  final String title;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted ? cs.primaryContainer.withValues(alpha: .76) : cs.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(12),
        border: highlighted ? Border.all(color: cs.primary.withValues(alpha: .18)) : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(number, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: highlighted ? cs.primary : cs.onSurfaceVariant)),
        const SizedBox(width: 7),
        Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

IconData _unitIcon(String icon) => switch (icon) {
      'waving' => Icons.waving_hand_rounded,
      'kana' => Icons.grid_view_rounded,
      'vocab' => Icons.menu_book_rounded,
      'kanji' => Icons.translate_rounded,
      'grammar' => Icons.account_tree_rounded,
      'chat' => Icons.forum_rounded,
      'reading' => Icons.auto_stories_rounded,
      'listening' => Icons.headphones_rounded,
      'trophy' => Icons.workspace_premium_rounded,
      'badge' => Icons.badge_rounded,
      'work' => Icons.work_rounded,
      'review' => Icons.refresh_rounded,
      _ => Icons.book_rounded,
    };

/// Dipertahankan untuk kompatibilitas kode lama; banner saat ini sengaja kosong.
class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
