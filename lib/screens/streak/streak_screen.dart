import 'package:flutter/material.dart';
import '../../state/app_controller.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});
  static const _days = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Rentetan Belajar')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 30), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(colors: [Color(0xFFFF7A45), Color(0xFF635BFF)])),
          child: LayoutBuilder(builder: (context, constraints) {
            final details = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${app.streak} hari', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
              Text(app.streakTierName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('XP total ${app.xp} · level ${app.level}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
            ]);
            if (constraints.maxWidth < 300) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                details,
              ]);
            }
            return Row(children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 46),
              const SizedBox(width: 12),
              Expanded(child: details),
            ]);
          }),
        ),
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pekan ini', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 13),
          Row(children: [for (var i = 0; i < _days.length; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i == 6 ? 0 : 6), child: _WeekKanji(kanji: _days[i], active: app.hasStudyOnDate(now.subtract(Duration(days: now.weekday - 1 - i))), selected: i == now.weekday - 1)))]),
        ]))),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kalender belajar', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Bulan ${_jpMonth(now.month)} ${now.year}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          _Calendar(now: now, activeDates: app.studyDateKeys),
        ]))),
        const SizedBox(height: 14),
        Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.emoji_events_rounded)), title: const Text('Rekor terpanjang', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${app.streak} hari tercatat di perangkat ini'))),
      ]),
    );
  }

  static String _jpMonth(int month) => const ['', '1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'][month];
}

class _WeekKanji extends StatelessWidget {
  const _WeekKanji({required this.kanji, required this.active, required this.selected});
  final String kanji; final bool active, selected;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? scheme.primary.withValues(alpha: .14) : (active ? scheme.primaryContainer : scheme.surfaceContainerHighest.withValues(alpha: .55)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 1.6 : 1),
      ),
      child: Text(kanji, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: selected ? scheme.primary : scheme.onSurface)),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({required this.now, required this.activeDates});
  final DateTime now;
  final Set<String> activeDates;
  @override
  Widget build(BuildContext context) {
    final first = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leading = first.weekday % 7;
    final cells = <Widget>[for (var i = 0; i < leading; i++) const SizedBox()];
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final key = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final active = activeDates.contains(key);
      final today = day == now.day;
      cells.add(Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: active ? Colors.orange.withValues(alpha: .18) : null, borderRadius: BorderRadius.circular(12), border: today ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.4) : null),
        child: Center(child: Text('$day', style: TextStyle(fontWeight: active || today ? FontWeight.w900 : FontWeight.w500))),
      ));
    }
    return GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: cells);
  }
}
