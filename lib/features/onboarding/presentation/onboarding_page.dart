import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clarity_ai/core/services/storage_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  bool _isLastPage = false;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': LucideIcons.bookOpen,
      'title': 'Feynman Tekniği ile Tanışın',
      'description': 'Öğrenmenin en iyi yolu, onu bir başkasına anlatmaktır. Feynman Tekniği ile bilgiyi gerçekten öğrenin.',
    },
    {
      'icon': LucideIcons.brain,
      'title': 'Yapay Zeka Desteği',
      'description': 'Kendi kaynaklarınızı yükleyin. Sesli veya yazılı anlatın. Yapay zeka hatalarınızı bulsun.',
    },
    {
      'icon': LucideIcons.shield,
      'title': 'Gizlilik Odaklı',
      'description': 'Verileriniz sizin kontrolünüzde. İster bulut API\'leri kullanın, ister tamamen çevrimdışı çalıştırın.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _isLastPage = index == _pages.length - 1;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        page['icon'],
                        size: 64,
                        color: accentColor,
                      ),
                    ).animate().fadeIn(duration: 500.ms).scale(delay: 200.ms),
                    const SizedBox(height: 48),
                    Text(
                      page['title'],
                      style: theme.textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                    const SizedBox(height: 16),
                    Text(
                      page['description'],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 48,
            left: 32,
            right: 32,
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: _pages.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: accentColor,
                    dotColor: theme.colorScheme.onSurface.withOpacity(0.2),
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      if (_isLastPage) {
                        final storage = StorageService();
                        await storage.setOnboardingCompleted(true);
                        if (context.mounted) {
                          context.go('/setup');
                        }
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(_isLastPage ? 'Hemen Başla' : 'İleri'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
