import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clarity_ai/app/theme/app_colors.dart';
import 'package:clarity_ai/app/theme/app_text_styles.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';
import 'package:clarity_ai/core/providers/data_providers.dart';
import 'package:clarity_ai/models/v2_models.dart';
import 'package:clarity_ai/core/services/database_service.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});
  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  Future<void> _addEvent() async {
    final titleCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text("Yeni Sınav / Etkinlik"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(hintText: "Örn: Matematik Vize"),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar),
                      const SizedBox(width: 8),
                      Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        child: const Text("Tarih Seç"),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isNotEmpty) {
                      final event = Event(
                        title: titleCtrl.text,
                        dateStr: selectedDate.toIso8601String(),
                        type: 'exam',
                        colorHex: '#EAB308',
                      );
                      await DatabaseService.instance.insertEvent(event);
                      ref.invalidate(eventsProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text("Ekle"),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Takvim ve Sınavlar", style: AppTextStyles.headline3.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: eventsAsync.when(
        data: (events) {
          // sort by date
          final sortedEvents = List<Event>.from(events);
          sortedEvents.sort((a, b) => DateTime.parse(a.dateStr).compareTo(DateTime.parse(b.dateStr)));
          
          if (sortedEvents.isEmpty) {
            return Center(
              child: Text("Planlanmış bir sınavınız yok.", 
                style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              )
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 120),
            itemCount: sortedEvents.length,
            itemBuilder: (context, index) {
              final ev = sortedEvents[index];
              final date = DateTime.parse(ev.dateStr);
              final diff = date.difference(DateTime.now()).inDays;
              final color = Color(int.parse(ev.colorHex.replaceFirst('#', '0xFF')));

              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(LucideIcons.calendarClock, color: color),
                  ),
                  title: Text(ev.title, style: AppTextStyles.bodyLarge.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                  subtitle: Text("${date.day}/${date.month}/${date.year}", style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  trailing: Text(
                    diff == 0 ? "Bugün" : (diff < 0 ? "${-diff} gün geçti" : "$diff gün kaldı"),
                    style: AppTextStyles.bodyMedium.copyWith(color: diff < 3 ? AppColors.error : AppColors.warning),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Hata: $e")),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton(
          onPressed: _addEvent,
          backgroundColor: AppColors.darkAccent,
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
    );
  }
}
