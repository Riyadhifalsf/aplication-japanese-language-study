import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ads_service.dart';
import '../state/app_controller.dart';
import '../widgets/admob_banner_slot.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common_widgets.dart';
import 'donation/donation_screen.dart';
import 'home/home_screen.dart';
import 'curriculum/curriculum_path_screen.dart';
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
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = PageController(initialPage: 0);
  }
  @override
  void dispose() {
    _app?.endSession();
    _pages.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _app = AppScope.of(context); }

  Future<void> _openProfile() async {
    final app = _app ?? AppScope.of(context);
    if (!app.isAuthenticated) { await requireLogin(context, feature: 'Profil'); return; }
    if (!mounted) return;
    unawaited(Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())));
  }

  Future<void> _select(int value) async {
    final target = value.clamp(0, 4);
    setState(() => _index = target);
    if (_pages.hasClients) {
      _pages.animateToPage(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
    unawaited(AdsService.instance.onTabChange());
  }

  void _onPageChanged(int value) {
    if (value == _index) return;
    setState(() => _index = value);
    unawaited(AdsService.instance.onTabChange());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { _app?.startSession(); if (mounted) setState(() {}); }
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) _app?.endSession();
  }

  /// Urutan tab: 0 Beranda, 1 Learning, 2 Donasi (tengah),
  /// 3 Practice, 4 Library. Daftar dipakai PageView agar bisa digeser.
  List<Widget> _tabPages(AppController app) => [
        HomeScreen(
            key: const PageStorageKey('tab-beranda'),
            onOpenStudy: () => _select(1),
            onOpenQuiz: () => _select(3),
            onOpenProfile: _openProfile),
        CurriculumPathScreen(
            key: const PageStorageKey('tab-learning'),
            initialLevel: app.curriculumActiveLevelId),
        const DonationScreen(key: PageStorageKey('tab-donasi')),
        const QuizCenterScreen(key: PageStorageKey('tab-practice')),
        const StudyHubScreen(key: PageStorageKey('tab-library')),
      ];

  @override
  Widget build(BuildContext context) {
    final app = _app ?? AppScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final pages = [
      const NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: Text('Beranda')),
      const NavigationRailDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: Text('Learning')),
      const NavigationRailDestination(icon: Icon(Icons.volunteer_activism_outlined, size: 30), selectedIcon: Icon(Icons.volunteer_activism_rounded, size: 30), label: Text('Donasi')),
      const NavigationRailDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz_rounded), label: Text('Practice')),
      const NavigationRailDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books_rounded), label: Text('Library')),
    ];
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final body = SafeArea(
      bottom: false,
      child: AdaptiveContent(
        child: disableAnimations
            ? _tabPages(app)[_index]
            : PageView(
                controller: _pages,
                onPageChanged: _onPageChanged,
                children: _tabPages(app),
              ),
      ),
    );
    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(selectedIndex: _index, onDestinationSelected: _select, extended: MediaQuery.sizeOf(context).width >= 1120, leading: Padding(padding: const EdgeInsets.fromLTRB(10, 14, 10, 20), child: Image.asset('assets/branding/japanese_study_logo.png', width: 48, height: 48)), destinations: pages),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
        bottomNavigationBar: AdmobBannerSlot(hidden: false),
      );
    }
    return Scaffold(
      body: body,
      appBar: null,
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        AdmobBannerSlot(hidden: false),
        NavigationBar(selectedIndex: _index, onDestinationSelected: _select, destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Learning'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined, size: 30), selectedIcon: Icon(Icons.volunteer_activism_rounded, size: 30), label: 'Donasi'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz_rounded), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books_rounded), label: 'Library'),
        ]),
      ]),
    );
  }
}
