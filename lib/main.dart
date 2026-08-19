import 'dart:async';

import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/app_shell.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/content_repository.dart';
import 'services/notification_service.dart';
import 'services/tts_service.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(
    repository: ContentRepository(),
    tts: TtsService(),
  );
  runApp(JapaneseStudyBootstrap(controller: controller));
  unawaited(controller.load());
  unawaited(NotificationService.instance.initialize());
}

class JapaneseStudyBootstrap extends StatelessWidget {
  const JapaneseStudyBootstrap({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) => AppScope(
        controller: controller,
        child: AnimatedBuilder(
          animation: controller.bootstrapRevision,
          builder: (context, _) => MaterialApp(
            title: 'Belajar Bahasa Jepang',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: controller.darkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              final scale = media.textScaler
                  .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.0);
              return MediaQuery(
                data: media.copyWith(textScaler: scale),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const _BootstrapGate(),
          ),
        ),
      );
}

class _BootstrapGate extends StatelessWidget {
  const _BootstrapGate();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final Widget page;
    final Key pageKey;

    if (!controller.ready) {
      page = const _StartupSplash();
      pageKey = const ValueKey('startup-splash');
    } else if (controller.isAdmin) {
      page = const AdminDashboardScreen();
      pageKey = const ValueKey('admin');
    } else if (controller.isAuthenticated && !controller.onboardingComplete) {
      page = const OnboardingScreen();
      pageKey = const ValueKey('onboarding');
    } else {
      page = const AppShell();
      pageKey = const ValueKey('app-shell');
    }

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration:
          disableAnimations ? Duration.zero : const Duration(milliseconds: 260),
      reverseDuration:
          disableAnimations ? Duration.zero : const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      ),
      child: KeyedSubtree(key: pageKey, child: page),
    );
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Japanese Study sedang dibuka',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: .14),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/branding/japanese_study_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      '日本語',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Japanese Study',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Menyiapkan pengalaman belajarmu…',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
