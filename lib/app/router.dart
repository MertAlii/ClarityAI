import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clarity_ai/features/onboarding/presentation/onboarding_page.dart';
import 'package:clarity_ai/features/setup/presentation/setup_page.dart';
import 'package:clarity_ai/features/dashboard/presentation/dashboard_page.dart';
import 'package:clarity_ai/features/note_creation/presentation/note_creation_page.dart';
import 'package:clarity_ai/features/studio/presentation/studio_page.dart';
import 'package:clarity_ai/features/dashboard/presentation/note_detail_page.dart';

import 'package:clarity_ai/features/settings/presentation/settings_page.dart';
import 'package:clarity_ai/core/services/storage_service.dart';
import 'package:clarity_ai/models/v2_models.dart';
import 'package:clarity_ai/features/dashboard/presentation/flashcard_quiz_page.dart';
import 'package:clarity_ai/features/dashboard/presentation/test_quiz_page.dart';
import 'package:clarity_ai/features/dashboard/presentation/classic_quiz_page.dart';
import 'package:clarity_ai/features/settings/presentation/stats_page.dart';
import 'package:clarity_ai/features/chat/presentation/chat_detail_page.dart';
import 'package:clarity_ai/features/settings/presentation/local_model_page.dart';

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
        path: '/local-models',
        name: 'local-models',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LocalModelPage(),
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
        path: '/note_detail/:noteId',
        name: 'note_detail',
        pageBuilder: (context, state) {
          final noteId = int.parse(state.pathParameters['noteId']!);
          return CustomTransitionPage(
            key: state.pageKey,
            child: NoteDetailPage(noteId: noteId),
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
      GoRoute(
        path: '/flashcard_quiz',
        name: 'flashcard_quiz',
        pageBuilder: (context, state) {
          final quiz = state.extra as QuizData;
          return CustomTransitionPage(
            key: state.pageKey,
            child: FlashcardQuizPage(quiz: quiz),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/test_quiz',
        name: 'test_quiz',
        pageBuilder: (context, state) {
          final quiz = state.extra as QuizData;
          return CustomTransitionPage(
            key: state.pageKey,
            child: TestQuizPage(quiz: quiz),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/stats',
        name: 'stats',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StatsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/chat/:sessionId',
        name: 'chat_detail',
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ChatDetailPage(sessionId: sessionId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
    ],
  );
}
