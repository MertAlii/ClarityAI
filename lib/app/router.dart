import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clarity_ai/features/onboarding/presentation/onboarding_page.dart';
import 'package:clarity_ai/features/setup/presentation/setup_page.dart';
import 'package:clarity_ai/features/dashboard/presentation/dashboard_page.dart';
import 'package:clarity_ai/features/note_creation/presentation/note_creation_page.dart';
import 'package:clarity_ai/features/studio/presentation/studio_page.dart';
import 'package:clarity_ai/features/report/presentation/report_page.dart';
import 'package:clarity_ai/features/settings/presentation/settings_page.dart';
import 'package:clarity_ai/core/services/storage_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

Future<GoRouter> createRouter() async {
  final storage = StorageService();
  final onboardingDone = await storage.isOnboardingCompleted();
  final setupDone = await storage.isSetupCompleted();

  String initialLocation;
  if (!onboardingDone) {
    initialLocation = '/onboarding';
  } else if (!setupDone) {
    initialLocation = '/setup';
  } else {
    initialLocation = '/';
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SetupPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/',
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/create',
        name: 'create',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NoteCreationPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/studio/:noteId',
        name: 'studio',
        pageBuilder: (context, state) {
          final noteId = int.parse(state.pathParameters['noteId']!);
          return CustomTransitionPage(
            key: state.pageKey,
            child: StudioPage(noteId: noteId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/report/:noteId',
        name: 'report',
        pageBuilder: (context, state) {
          final noteId = int.parse(state.pathParameters['noteId']!);
          return CustomTransitionPage(
            key: state.pageKey,
            child: ReportPage(noteId: noteId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
    ],
  );
}
