import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ads_service.dart';
import '../state/app_controller.dart';
import '../widgets/admob_banner_slot.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common_widgets.dart';
import '../widgets/brand_icons.dart';
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

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void dispose() { _app?.endSession(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _app = AppScope.of(context); }

  Future<void> _openProfile() async {
    final app = _app ?? AppScope.of(context);
    if (!app.isAuthenticated) { await requireLogin(context, feature: 'Profil'); return; }
    if (!mounted) return;
    unawaited(Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())));
  }

  Future<void> _select(int value) async {
    setState(() => _index = value);
    unawaited(AdsService.instance.onTabChange());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { _app?.startSession(); if (mounted) setState(() {}); }
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) _app?.endSession();
  }

  Widget _page(AppController app) => switch (_index) {
    0 => HomeScreen(onOpenStudy: () => _select(1), onOpenQuiz: () => _select(3), onOpenProfile: _openProfile),
    1 => CurriculumPathScreen(initialLevel: app.curriculumActiveLevelId),
    2 => const DonationScreen(),
    3 => const QuizCenterScreen(),
    _ => const StudyHubScreen(),
  };

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
        child: Column(
          children: [
            if (_index != 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        app.profileName.isEmpty ? '日' : app.profileName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.profileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text(app.selectedStudyLevel, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(tooltip: 'Profil', onPressed: _openProfile, icon: const Icon(Icons.person_outline_rounded)),
                  ],
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 240),
                reverseDuration: disableAnimations ? Duration.zero : const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) {
                  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(scale: Tween<double>(begin: .985, end: 1).animate(curved), child: child),
                  );
                },
                child: KeyedSubtree(key: ValueKey(_index), child: _page(app)),
              ),
            ),
          ],
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
