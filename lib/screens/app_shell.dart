import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ads_service.dart';
import '../state/app_controller.dart';
import '../widgets/admob_banner_slot.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common_widgets.dart';
import 'curriculum/curriculum_path_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'quiz/quiz_center_screen.dart';
import 'study/study_hub_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  AppController? _app;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _app?.endSession();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
  }

  /// Buka Profil dari avatar beranda (ala Busuu: tanpa tab Profil).
  /// Tamu diarahkan login dulu; yang login masuk halaman Profil.
  Future<void> _openProfile() async {
    final app = _app ?? AppScope.of(context);
    if (!app.isAuthenticated) {
      await requireLogin(context, feature: 'Profil');
      return;
    }
    if (!mounted) return;
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ));
  }

  /// IA: 0 Home, 1 Learn (Learning Path), 2 Practice (Quiz/Review),
  /// 3 Library (Independent Study). SEMUA tab terbuka untuk semua pengguna
  /// (tamu maupun login) — tidak ada lock fitur. Satu-satunya urutan adalah
  /// pedagogis di dalam Learning Path (lesson-per-lesson).
  Future<void> _select(int value) async {
    setState(() => _index = value);
    // Iklan tetap jalan, tidak tergantung status apapun.
    unawaited(AdsService.instance.onTabChange());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _app?.startSession();
      if (mounted) setState(() {});
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) _app?.endSession();
  }

  Widget _page(AppController app) => switch (_index) {
        0 => HomeScreen(
            onOpenStudy: () => _select(1),
            onOpenQuiz: () => _select(2),
            onOpenProfile: _openProfile),
        // Learn murni Learning Path (bukan library).
        1 => CurriculumPathScreen(
            initialLevel: app.curriculumActiveLevelId),
        // Practice: latihan bebas + review + mistakes + exam.
        2 => const QuizCenterScreen(),
        // Library: independent study (Vocab/Kanji/Grammar/Kana/dll).
        _ => const StudyHubScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final app = _app ?? AppScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final pages = [
      const NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Beranda')),
      const NavigationRailDestination(
          icon: Icon(Icons.route_outlined),
          selectedIcon: Icon(Icons.route_rounded),
          label: Text('Learn')),
      const NavigationRailDestination(
          icon: Icon(Icons.quiz_outlined),
          selectedIcon: Icon(Icons.quiz_rounded),
          label: Text('Practice')),
      const NavigationRailDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books_rounded),
          label: Text('Library')),
    ];

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final body = SafeArea(
      bottom: false,
      child: AdaptiveContent(
        child: AnimatedSwitcher(
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 240),
          reverseDuration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 180),
          // Pindah tab: fade + scale super halus. TANPA slide horizontal
          // (slide tiap ganti tab terlihat seperti bug, bukan animasi).
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: .985, end: 1).animate(curved),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(key: ValueKey(_index), child: _page(app)),
        ),
      ),
    );
    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: _select,
            extended: MediaQuery.sizeOf(context).width >= 1120,
            leading: Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 20),
                child: Image.asset('assets/branding/japanese_study_logo.png',
                    width: 48, height: 48)),
            destinations: pages,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
        // Phase 1: tidak ada tier premium, iklan selalu tampil.
        bottomNavigationBar: AdmobBannerSlot(hidden: false),
      );
    }
    return Scaffold(
      body: body,
      appBar: null,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdmobBannerSlot(hidden: false),
          NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route_rounded),
              label: 'Learn'),
          NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz_rounded),
              label: 'Practice'),
          NavigationDestination(
              icon: Icon(Icons.library_books_outlined),
              selectedIcon: Icon(Icons.library_books_rounded),
              label: 'Library'),
        ],
      ),
        ],
      ),
    );
  }
}
