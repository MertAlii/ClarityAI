import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:clarity_ai/app/router.dart';
import 'package:clarity_ai/app/theme/app_theme.dart';
import 'package:clarity_ai/app/theme/app_colors.dart';
import 'package:clarity_ai/core/services/storage_service.dart';

/// Global theme mode notifier for runtime theme switching
class ThemeModeNotifier extends Notifier<ThemeMode> {
  final ThemeMode initialMode;
  ThemeModeNotifier([this.initialMode = ThemeMode.dark]);

  @override
  ThemeMode build() => initialMode;
  
  void setMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  () => ThemeModeNotifier(),
);

/// Global seed color notifier for dynamic accent colors
class SeedColorNotifier extends Notifier<Color> {
  final Color initialColor;
  SeedColorNotifier([this.initialColor = AppColors.defaultSeed]);

  @override
  Color build() => initialColor;
  
  void setColor(Color color) {
    state = color;
  }
}

final seedColorProvider = NotifierProvider<SeedColorNotifier, Color>(
  () => SeedColorNotifier(),
);



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  
  // On-device ML initialization is now handled dynamically in LocalAiService
  try {
    // Model downloading or checking can go here later
  } catch (e) {
    if (kDebugMode) print('ML init error: $e');
  }
  
  // Read initial theme and accent color settings from storage
  final storage = StorageService();
  final themeStr = await storage.getThemeMode();
  final themeMode = themeStr == 'light' 
      ? ThemeMode.light 
      : (themeStr == 'dark' ? ThemeMode.dark : ThemeMode.system);
      
  final savedColorVal = await storage.getAccentColor();
  final initialColor = savedColorVal != null ? Color(savedColorVal) : AppColors.defaultSeed;

  final router = await createRouter();

  runApp(
    ProviderScope(
      overrides: [
        // Initialize providers with saved values
        themeModeProvider.overrideWith(() => ThemeModeNotifier(themeMode)),
        seedColorProvider.overrideWith(() => SeedColorNotifier(initialColor)),
      ],
      child: ClarityApp(router: router),
    ),
  );
}

class ClarityApp extends ConsumerStatefulWidget {
  final Object router;

  const ClarityApp({super.key, required this.router});

  @override
  ConsumerState<ClarityApp> createState() => _ClarityAppState();
}

class _ClarityAppState extends ConsumerState<ClarityApp> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final seedColor = ref.watch(seedColorProvider);

    return MaterialApp.router(
      title: 'Clarity AI',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(seedColor: seedColor),
      darkTheme: AppTheme.dark(seedColor: seedColor),
      routerConfig: widget.router as dynamic,
      builder: (context, child) {
        // Enforce scale factor for consistent UI
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
