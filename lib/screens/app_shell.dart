import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/auth_gate.dart';
import '../state/app_controller.dart';
import 'donation/donation_screen.dart';
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

  Future<void> _openProfile() async {
    final app = _app ?? AppScope.of(context);
    if (!app.isAuthenticated) {
      await requireLogin(context, feature: 'Profil');
      return;
    }
    if (!mounted) return;
    unawaited(Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())));
  }

  void _select(int value) => setState(() => _index = value);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _app?.startSession();
      if (mounted) setState(() {});
    }
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _app?.endSession();
    }
  }

  Widget _page() => switch (_index) {
        0 => HomeScreen(onOpenStudy: () => _select(2), onOpenQuiz: () => _select(1), onOpenProfile: _openProfile),
        1 => const QuizCenterScreen(),
        2 => const StudyHubScreen(),
        3 => const DonationScreen(),
        _ => HomeScreen(onOpenStudy: () => _select(2), onOpenQuiz: () => _select(1), onOpenProfile: _openProfile),
      };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final destinations = const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
      NavigationDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz_rounded), label: 'Practice'),
      NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books_rounded), label: 'Library'),
      NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), selectedIcon: Icon(Icons.volunteer_activism_rounded), label: 'Donasi'),
    ];
    final railDestinations = const [
      NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: Text('Beranda')),
      NavigationRailDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz_rounded), label: Text('Practice')),
      NavigationRailDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books_rounded), label: Text('Library')),
      NavigationRailDestination(icon: Icon(Icons.volunteer_activism_outlined), selectedIcon: Icon(Icons.volunteer_activism_rounded), label: Text('Donasi')),
    ];
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final body = SafeArea(
      bottom: false,
      child: AdaptiveContent(
        child: AnimatedSwitcher(
          duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 240),
          reverseDuration: disableAnimations ? Duration.zero : const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(opacity: curved, child: ScaleTransition(scale: Tween<double>(begin: .985, end: 1).animate(curved), child: child));
          },
          child: KeyedSubtree(key: ValueKey(_index), child: _page()),
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
            leading: Padding(padding: const EdgeInsets.fromLTRB(10, 14, 10, 20), child: Image.asset('assets/branding/japanese_study_logo.png', width: 48, height: 48)),
            destinations: railDestinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
      );
    }
    return Scaffold(body: body, bottomNavigationBar: NavigationBar(selectedIndex: _index, onDestinationSelected: _select, destinations: destinations));
  }
}
