import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';
import 'package:clarity_ai/models/ai_report.dart';
import 'package:clarity_ai/features/report/presentation/widgets/score_ring.dart';

class ReportPage extends StatelessWidget {
  final int noteId;
  const ReportPage({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    // We expect the AiReport object to be passed via GoRouter extra
    final AiReport? report = GoRouterState.of(context).extra as AiReport?;
    final theme = Theme.of(context);

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rapor Hatası')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Rapor verisi bulunamadı. Lütfen anlatımı tekrar yapın.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Ana Sayfaya Dön'),
              )
            ],
          ),
        ),
      );
    }

    String labelText;
    Color labelColor;
    if (report.score < 40) {
      labelText = "Daha fazla çalışman gerekiyor";
      labelColor = Colors.red;
    } else if (report.score < 70) {
      labelText = "İyi gidiyorsun, biraz daha geliştir";
      labelColor = Colors.orange;
    } else {
      labelText = "Harika! Konuya hakimsin";
      labelColor = Colors.green;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feynman Analizi'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ScoreRing(score: report.score),
            const SizedBox(height: 16),
            Text(labelText, style: theme.textTheme.labelLarge?.copyWith(color: labelColor)),
            
            const SizedBox(height: 48),

            if (report.gaps.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Eksikler ve Mantık Hataları', style: theme.textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 16),
              ...report.gaps.map((g) => GlassCard(
                borderColor: Colors.red,
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(g.detail, style: theme.textTheme.bodyMedium),
                  ],
                ),
              )),
              const SizedBox(height: 32),
            ],

            if (report.jargon.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Jargon Filtresi', style: theme.textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 16),
              ...report.jargon.map((j) => GlassCard(
                borderColor: Colors.orange,
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('"${j.word}"', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Öneri: ${j.suggestion}', style: theme.textTheme.bodyMedium),
                  ],
                ),
              )),
              const SizedBox(height: 32),
            ],

            if (report.analogies.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(LucideIcons.lightbulb, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Önerilen Analojiler', style: theme.textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: 16),
              ...report.analogies.map((a) => GlassCard(
                borderColor: Colors.green,
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.topic, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(a.analogy, style: theme.textTheme.bodyMedium),
                  ],
                ),
              )),
            ],

            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.go('/');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Ana Sayfa'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.pushReplacement('/studio/$noteId');
                    },
                    child: const Text('Tekrar Anlat'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
