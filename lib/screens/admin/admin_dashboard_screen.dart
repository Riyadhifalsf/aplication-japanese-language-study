import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/admin_analytics_service.dart';
import '../../state/app_controller.dart';
import '../auth/login_screen.dart';
import '../exams/exam_hub_screen.dart';
import '../study/learning_path_screen.dart';
import '../app_shell.dart';
import '../../services/feature_flags_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final analytics = AdminAnalyticsService();
  Timer? timer;
  bool loading = true;
  int tab = 0;
  AdminAnalyticsData _ad = AdminAnalyticsData.empty();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAnalytics();
    if (!mounted) return;
    setState(() => loading = false);
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    final result = await analytics.fetchAnalytics();
    if (!mounted) return;
    setState(() => _ad = result);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [
      _overview(context, app),
      _contentTab(context, app),
      _settingsTab(context, app),
    ];
    final labels = ['Overview', 'Content', 'Settings'];
    final icons = [
      Icons.dashboard_outlined,
      Icons.library_books_outlined,
      Icons.settings_outlined,
    ];
    final wide = MediaQuery.sizeOf(context).width >= 920;
    final content = Scaffold(
      appBar: AppBar(
        title: Text(labels[tab]),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _loadAnalytics(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') _logout(context, app);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Keluar')),
            ],
          ),
        ],
      ),
      body: pages[tab],
    );
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: tab,
              extended: MediaQuery.sizeOf(context).width >= 1180,
              onDestinationSelected: (i) => setState(() => tab = i),
              leading: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset('assets/branding/japanese_study_logo.png', width: 48, height: 48),
              ),
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationRailDestination(icon: Icon(icons[i]), selectedIcon: Icon(icons[i]), label: Text(labels[i])),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }
    return Scaffold(
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab > 2 ? 2 : tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.library_books_outlined), label: 'Content'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _overview(BuildContext context, AppController app) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ADMIN ANALYTICS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              const SizedBox(height: 8),
              const Text('Dashboard Overview', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                'Pantau pengguna, konten, dan aktivitas aplikasi secara real-time dari server.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050 ? 4 : constraints.maxWidth >= 620 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: columns == 1 ? 104 : 96,
              ),
              itemBuilder: (_, index) => [
                _metric('Total users', '${_ad.totalUsers}', Icons.people_rounded),
                _metric('Total admins', '${_ad.totalAdmins}', Icons.admin_panel_settings_rounded),
                _metric('Total content', '${_ad.totalContent}', Icons.library_books_rounded),
                _metric('Open reports', '${_ad.openReports}', Icons.report_problem_rounded, danger: _ad.openReports > 0),
              ][index],
            );
          },
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Registrations (14 hari)',
          child: _ad.registrations.isEmpty
              ? const SizedBox(height: 120, child: Center(child: Text('Belum ada data')))
              : SizedBox(height: 180, child: _lineChart(_ad.registrations)),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Logins (14 hari)',
          child: _ad.logins.isEmpty
              ? const SizedBox(height: 120, child: Center(child: Text('Belum ada data')))
              : SizedBox(height: 180, child: _lineChart(_ad.logins, color: Colors.teal)),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'User Roles',
          child: _ad.roles.isEmpty
              ? const SizedBox(height: 100, child: Center(child: Text('Belum ada data')))
              : SizedBox(height: 140, child: _pieChart(_ad.roles)),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Recent Activity',
          child: _ad.recentActivities.isEmpty
              ? const Text('Belum ada aktivitas.')
              : Column(
                  children: _ad.recentActivities.take(6).map((a) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(radius: 16, child: Icon(_activityIcon(a.type), size: 17)),
                      title: Text(a.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(_when(a.createdAt)),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Quick Actions',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _action('Learning Path', Icons.route_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningPathScreen()))),
              _action('Exam Hub', Icons.assignment_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamHubScreen()))),
              _action('App Preview', Icons.open_in_new_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppShell()))),
              _action('Feature Flags', Icons.science_rounded, () => _featureDialog(context, app)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contentTab(BuildContext context, AppController app) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Content Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        _card(
          title: 'Content by Type',
          child: _ad.totalContent == 0
              ? const Text('Belum ada data konten dari server.')
              : Column(
                  children: [
                    _contentRow('Kanji', _ad.kanji, Icons.translate_rounded),
                    _contentRow('Vocabulary', _ad.vocabularyContent, Icons.abc_rounded),
                    _contentRow('Grammar', _ad.grammar, Icons.menu_book_rounded),
                    _contentRow('Phrases', _ad.phrases, Icons.chat_rounded),
                    _contentRow('Sentences', _ad.sentences, Icons.short_text_rounded),
                    _contentRow('Culture', _ad.culture, Icons.language_rounded),
                    _contentRow('Readings', _ad.readings, Icons.auto_stories_rounded),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Content by Level',
          child: _ad.contentByLevel.isEmpty
              ? const SizedBox(height: 120, child: Center(child: Text('Belum ada data')))
              : SizedBox(height: 220, child: _barChart(_ad.contentByLevel)),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Database Content',
          child: Column(
            children: [
              _contentRow('Vocabularies (catalog)', _ad.totalVocabularies, Icons.book_rounded),
              _contentRow('Posts', _ad.totalPosts, Icons.forum_rounded),
              _contentRow('Comments', _ad.totalComments, Icons.comment_rounded),
              _contentRow('Announcements', _ad.totalAnnouncements, Icons.campaign_rounded),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Server Health',
          child: Column(
            children: [
              _health('Backend API', analytics.configured ? 'Connected' : 'Not configured', analytics.configured),
              _health('Analytics endpoint', _ad.totalUsers > 0 ? 'OK' : 'Awaiting data', _ad.totalUsers > 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsTab(BuildContext context, AppController app) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          title: 'Feature Control',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kelola fitur beta aplikasi.', style: TextStyle(height: 1.4)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _featureDialog(context, app),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Kelola feature flags'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Akses Cepat',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _action('Learning Path', Icons.route_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningPathScreen()))),
              _action('Exam Hub', Icons.assignment_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamHubScreen()))),
              _action('App Preview', Icons.open_in_new_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppShell()))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Dashboard Users',
          child: _ad.dashboardUsers.isEmpty
              ? const Text('Tidak ada data user.')
              : Column(
                  children: _ad.dashboardUsers.take(8).map((u) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(child: Text(u.name.isEmpty ? '?' : u.name.substring(0, 1).toUpperCase())),
                      title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${u.email} • ${u.role.toUpperCase()}'),
                      trailing: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: u.online ? Colors.green : Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _featureDialog(BuildContext context, AppController app) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheetState) {
          final defs = FeatureFlagsService.definitions;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.82),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Feature Control', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      const Text('Fitur beta default OFF.', style: TextStyle(height: 1.4)),
                      const SizedBox(height: 12),
                      ...defs.map((f) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: app.featureEnabled(f.key),
                        onChanged: (value) async {
                          await app.setFeatureFlag(f.key, value);
                          if (!context.mounted) return;
                          setSheetState(() {});
                          if (mounted) setState(() {});
                        },
                        title: Row(children: [
                          Expanded(child: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w900))),
                          if (f.beta)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text('BETA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onTertiaryContainer)),
                            ),
                        ]),
                        subtitle: Text(f.description),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    if (!mounted) return;
    await app.reloadFeatureFlags();
  }

  Widget _metric(String label, String value, IconData icon, {bool live = false, bool danger = false}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: danger ? Colors.red : live ? Colors.green : null),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, maxLines: 1, style: const TextStyle(fontSize: 24, height: 1.0, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 2),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.0, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _action(String t, IconData i, VoidCallback onTap) => ActionChip(avatar: Icon(i, size: 17), label: Text(t), onPressed: onTap);

  Widget _health(String a, String b, bool good) => ListTile(
    dense: true,
    leading: Icon(good ? Icons.check_circle : Icons.warning_amber_rounded, color: good ? Colors.green : Colors.orange),
    title: Text(a),
    subtitle: Text(b),
  );

  Widget _contentRow(String label, int count, IconData icon) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(label),
      trailing: Text('$count', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
    );
  }

  Widget _lineChart(List<ChartPoint> points, {Color color = Colors.blue}) {
    if (points.isEmpty) return const SizedBox.shrink();
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].count.toDouble()));
    }
    final maxY = points.map((p) => p.count).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= points.length) return const SizedBox.shrink();
              final label = points[i].day;
              if (label.length < 10) return Text(label, style: const TextStyle(fontSize: 9));
              return Text(label.substring(5), style: const TextStyle(fontSize: 9));
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: maxY < 1 ? 5 : (maxY * 1.2).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pieChart(List<RoleCount> roles) {
    final colors = [Colors.blue, Colors.teal, Colors.orange, Colors.purple, Colors.red];
    final total = roles.fold<int>(0, (s, r) => s + r.count);
    if (total == 0) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              sections: roles.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                final pct = (r.count / total * 100).toStringAsFixed(0);
                return PieChartSectionData(
                  value: r.count.toDouble(),
                  title: '$pct%',
                  color: colors[i % colors.length],
                  radius: 36,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: roles.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: colors[i % colors.length])),
                  const SizedBox(width: 6),
                  Text('${r.role} (${r.count})', style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _barChart(List<LevelCount> levels) {
    final colors = [Colors.blue, Colors.teal, Colors.orange, Colors.purple, Colors.red];
    final maxY = levels.map((l) => l.total).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY < 1 ? 5 : (maxY * 1.2).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= levels.length) return const SizedBox.shrink();
              return Text(levels[i].level, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700));
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: levels.asMap().entries.map((entry) {
          final i = entry.key;
          final l = entry.value;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: l.total.toDouble(),
                color: colors[i % colors.length],
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  IconData _activityIcon(String t) => switch (t) {
    'user' => Icons.person,
    'community' => Icons.forum,
    'comment' => Icons.comment,
    'report' => Icons.report,
    'system' => Icons.settings,
    _ => Icons.bolt,
  };

  String _when(DateTime? d) {
    if (d == null) return '-';
    final x = DateTime.now().difference(d);
    if (x.inSeconds < 60) return 'baru saja';
    if (x.inMinutes < 60) return '${x.inMinutes}m lalu';
    if (x.inHours < 24) return '${x.inHours}j lalu';
    return '${x.inDays}h lalu';
  }

  Future<void> _logout(BuildContext context, AppController app) async {
    await app.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }
}
