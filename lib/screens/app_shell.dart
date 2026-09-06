import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ads_service.dart';
import '../state/app_controller.dart';
import '../widgets/admob_banner_slot.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common_widgets.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'quiz/quiz_center_screen.dart';
import 'study/study_hub_screen.dart';
import 'kanji/kanji_study_screen.dart';

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

  Future<void> _select(int value) async {
    final app = _app ?? AppScope.of(context);
    // Tamu: Beranda + Belajar bebas; Quiz + Kanji mode pratinjau terbatas;
    // Profil wajib login.
    if (!app.isAuthenticated && value == 4) {
      await requireLogin(context, feature: 'Profil');
      return;
    }
    // Kunci XP hanya berlaku untuk yang sudah login; tamu lewat pratinjau
    // dengan batas sesi di tiap layar.
    if (app.isAuthenticated && value == 2 && !app.canAccessFeature('quiz_center')) {
      _lock(context, 'Quiz Center', app.featureXpRequirement('quiz_center'));
      return;
    }
    if (app.isAuthenticated && value == 3 && !app.canAccessFeature('kanji')) {
      _lock(context, 'Kanji', app.featureXpRequirement('kanji'));
      return;
    }
    setState(() => _index = value);
    if (!app.isPremium) unawaited(AdsService.instance.onTabChange());
  }

  void _lock(BuildContext context, String feature, int xp) {
    final app = AppScope.of(context);
    showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('$feature belum terbuka'),
              content: Text(app.hasFullAccess
                  ? 'Fitur ini sedang dikunci oleh aturan progres.'
                  : 'Login untuk membuka lebih banyak materi gratis. Premium membuka seluruh aplikasi.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'))
              ],
            ));
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
            onOpenProfile: () => _select(4)),
        1 => const StudyHubScreen(),
        2 => const QuizCenterScreen(),
        3 => const KanjiStudyScreen(),
        _ => const ProfileScreen(),
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
          icon: Icon(Icons.auto_stories_outlined),
          selectedIcon: Icon(Icons.auto_stories_rounded),
          label: Text('Belajar')),
      const NavigationRailDestination(
          icon: Icon(Icons.quiz_outlined),
          selectedIcon: Icon(Icons.quiz_rounded),
          label: Text('Quiz')),
      const NavigationRailDestination(
          icon: Icon(Icons.wb_sunny_outlined),
          selectedIcon: Icon(Icons.wb_sunny_rounded),
          label: Text('Kanji')),
      const NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('Profil')),
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
        bottomNavigationBar: AdmobBannerSlot(hidden: app.isPremium),
      );
    }
    return Scaffold(
      body: body,
      appBar: null,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdmobBannerSlot(hidden: app.isPremium),
          NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded),
              label: 'Belajar'),
          NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz_rounded),
              label: 'Quiz'),
          NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny_rounded),
              label: 'Kanji'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil'),
        ],
      ),
        ],
      ),
    );
  }
}
