import 'dart:async';

import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/app_shell.dart';
import 'screens/auth/login_screen.dart';
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
  unawaited(NotificationService.instance.initialize());
  unawaited(controller.load());
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
            themeMode:
                controller.darkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              final scale = media.textScaler
                  .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.0);
              return MediaQuery(
                data: media.copyWith(textScaler: scale),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: controller.ready
                ? (controller.isAdmin
                    ? const AdminDashboardScreen()
                    : (controller.isAuthenticated && !controller.onboardingComplete ? const OnboardingScreen() : const AppShell()))
                : const _LoadingScreen(),
          ),
        ),
      );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 164,
                height: 164,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/branding/japanese_study_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text(
                      '日本語',
                      style: TextStyle(
                        color: Color(0xFFB11226),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 12),
              const Text('Membuka Japanese Study…', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}
