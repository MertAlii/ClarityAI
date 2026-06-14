import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';
import 'package:clarity_ai/core/providers/data_providers.dart';
import 'package:clarity_ai/core/services/database_service.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  final String _selectedProvider = 'Groq';
  final TextEditingController _quotaController = TextEditingController();
  bool _quotaInitialized = false;

  @override
  Widget build(BuildContext context) {
    final usageAsync = ref.watch(tokenUsageProvider(_selectedProvider));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('İstatistikler', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: usageAsync.when(
        data: (usage) {
          if (usage != null && !_quotaInitialized) {
            _quotaController.text = usage.quotaLimit.toString();
            _quotaInitialized = true;
          }
          final tokens = usage?.tokensUsed ?? 0;
          final requests = usage?.requestsCount ?? 0;
          final limit = usage?.quotaLimit ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('$_selectedProvider Kullanımı', style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harcanan Toplam Token', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(tokens.toString(), style: GoogleFonts.outfit(color: const Color(0xFF84CC16), fontSize: 28, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Atılan İstek (Request)', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(requests.toString(), style: GoogleFonts.outfit(color: const Color(0xFFF97316), fontSize: 28, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Aylık Kota Sınırı', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.data_usage, color: Colors.white70),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _quotaController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Limit belirleyin (örn. 50000)',
                          hintStyle: const TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF84CC16),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final newQuota = int.tryParse(_quotaController.text) ?? 0;
                        await DatabaseService.instance.updateQuota(_selectedProvider, newQuota);
                        ref.invalidate(tokenUsageProvider(_selectedProvider));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Kota güncellendi', style: GoogleFonts.inter()),
                            backgroundColor: const Color(0xFF242424),
                          ));
                        }
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
              if (limit > 0) ...[
                const SizedBox(height: 24),
                Text('Kullanım Durumu', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (tokens / limit).clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  color: (tokens / limit) > 0.9 ? const Color(0xFFEF4444) : const Color(0xFF84CC16),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text('%${((tokens / limit) * 100).toStringAsFixed(1)} kullanıldı', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              ]
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16))),
        error: (err, stack) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
