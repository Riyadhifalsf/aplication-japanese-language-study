import 'package:flutter/material.dart';

import '../state/app_controller.dart';

class WeeklyLearningPulse extends StatelessWidget {
  const WeeklyLearningPulse({required this.app, super.key});

  final AppController app;

  int _eventsFor(DateTime date) {
    final key = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return app.activityJournal.where((entry) {
      final raw = entry['at'];
      final value = DateTime.tryParse('$raw');
      if (value == null) return false;
      return value.toLocal().toIso8601String().startsWith(key);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final values = List<int>.generate(7, (index) => _eventsFor(start.add(Duration(days: index))));
    final maxValue = values.fold<int>(0, (max, value) => value > max ? value : max);
    final activeDays = values.where((value) => value > 0).length;
    final total = values.fold<int>(0, (sum, value) => sum + value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Weekly Learning Pulse',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                ),
                Flexible(
                  child: Text(
                    '$activeDays/7 hari aktif',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Konsistensi minggu ini, bukan cuma jumlah XP.', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 14),
            SizedBox(
              height: 118,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < values.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == values.length - 1 ? 0 : 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 14,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('${values[i]}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: double.infinity,
                                  constraints: const BoxConstraints(maxWidth: 22, minHeight: 8),
                                  height: maxValue == 0 ? 8 : 10 + (78 * values[i] / maxValue),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(99),
                                    color: values[i] > 0 ? cs.primary : cs.surfaceContainerHighest,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 14,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  ['S', 'S', 'R', 'K', 'J', 'S', 'M'][i],
                                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('$total event belajar tercatat minggu ini.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
