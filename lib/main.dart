import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:clarity_ai/app/router.dart';
import 'package:clarity_ai/app/theme/app_theme.dart';
import 'package:clarity_ai/core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final router = await createRouter();
  final storage = StorageService();
  final themeMode = await storage.getThemeMode();

  runApp(
    ProviderScope(
      child: ClarityApp(
        router: router,
        initialThemeMode: themeMode,
      ),
    ),
  );
}

/// Global theme mode notifier for runtime theme switching
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class ClarityApp extends ConsumerStatefulWidget {
  final GoRouter router;
  final String initialThemeMode;

  const ClarityApp({
    super.key,
    required this.router,
    required this.initialThemeMode,
  });

  @override
  ConsumerState<ClarityApp> createState() => _ClarityAppState();
}

class _ClarityAppState extends ConsumerState<ClarityApp> {
  @override
  void initState() {
    super.initState();
    // Set initial theme from stored preference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mode = switch (widget.initialThemeMode) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
      ref.read(themeModeProvider.notifier).state = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Clarity AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: widget.router,
      builder: (context, child) {
        // Apply Google Fonts globally
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}
