import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ads_service.dart';
import '../state/app_controller.dart';
import '../widgets/admob_banner_slot.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common_widgets.dart';
import 'donation/donation_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'quiz/quiz_center_screen.dart';
import 'study/learning_experience_screen.dart';
import 'review/review_experience_screen.dart';

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

  Future<void> _select(int value) async {
    setState(() => _index = value);
    unawaited(AdsService.instance.onTabChange());
  }

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

  Widget _page(AppController app) => switch (_index) {
        0 => const LearningExperienceScreen(),
        1 => const ReviewExperienceScreen(),
        2 => const DonationScreen(),
        3 => const QuizCenterScreen(),
        _ => const ProfileScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final app = _app ?? AppScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final destinations = const [
      NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Belajar'),
      NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Ulasan'),
      NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium_rounded), label: 'Premium'),
      NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Latihan'),
      NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profil'),
    ];
    final railDestinations = const [
      NavigationRailDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: Text('Belajar')),
      NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: Text('Ulasan')),
      NavigationRailDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium_rounded), label: Text('Premium')),
      NavigationRailDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: Text('Latihan')),
      NavigationRailDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: Text('Profil')),
    ];
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final body = SafeArea(
      bottom: false,
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
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              extended: MediaQuery.sizeOf(context).width >= 1120,
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 20),
                child: Image.asset('assets/branding/japanese_study_logo.png', width: 48, height: 48),
              ),
              destinations: railDestinations,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        bottomNavigationBar: AdmobBannerSlot(hidden: false),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdmobBannerSlot(hidden: false),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: destinations,
          ),
        ],
      ),
    );
  }
}
