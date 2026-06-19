import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Future<void> _addEvent() async {
    final titleCtrl = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              title: Text("Yeni Etkinlik", style: GoogleFonts.outfit(color: colorScheme.onSurface)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: GoogleFonts.inter(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Örn: Matematik Vize",
                      hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.54)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", style: GoogleFonts.inter(color: colorScheme.onSurface)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        child: Text("Tarih", style: GoogleFonts.inter(color: colorScheme.primary)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Text(selectedTime.format(context), style: GoogleFonts.inter(color: colorScheme.onSurface)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        child: Text("Saat", style: GoogleFonts.inter(color: colorScheme.primary)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("İptal", style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.54))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
                  onPressed: () async {
                    if (titleCtrl.text.isNotEmpty) {
                      final finalDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      final event = Event(
                        title: titleCtrl.text,
                        dateStr: finalDateTime.toIso8601String(),
                        type: 'exam',
                        colorHex: '#EAB308',
                      );
                      await DatabaseService.instance.insertEvent(event);
                      ref.invalidate(eventsProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Text("Ekle", style: GoogleFonts.inter(color: colorScheme.onPrimary)),
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
    final eventsAsync = ref.watch(eventsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Takvim ve Etkinlikler", style: GoogleFonts.outfit(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: eventsAsync.when(
        data: (events) {
          // Takvimde seçili güne ait etkinlikleri al
          final selectedEvents = events.where((e) {
            final d = DateTime.parse(e.dateStr);
            return _selectedDay != null && isSameDay(d, _selectedDay);
          }).toList();
          
          selectedEvents.sort((a, b) => DateTime.parse(a.dateStr).compareTo(DateTime.parse(b.dateStr)));

          // Yaklaşanlar (Bugünden sonraki tüm etkinlikler)
          final upcomingEvents = events.where((e) {
            final d = DateTime.parse(e.dateStr);
            return d.isAfter(DateTime.now().subtract(const Duration(days: 1)));
          }).toList();
          upcomingEvents.sort((a, b) => DateTime.parse(a.dateStr).compareTo(DateTime.parse(b.dateStr)));

          return ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              GlassCard(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) {
                    return events.where((e) => isSameDay(DateTime.parse(e.dateStr), day)).toList();
                  },
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: GoogleFonts.inter(color: colorScheme.onSurface),
                    weekendTextStyle: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.54)),
                    outsideTextStyle: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.24)),
                    selectedDecoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.3), shape: BoxShape.circle),
                    markerDecoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.outfit(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w500),
                    leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
                    rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.onSurface),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    weekendStyle: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.54)),
                  ),
                ),
              ),
              
              if (selectedEvents.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Seçili Gün (${_selectedDay?.day}/${_selectedDay?.month})", style: GoogleFonts.outfit(color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                ...selectedEvents.map((ev) => _buildEventCard(ev, theme)),
              ],

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("Yaklaşanlar", style: GoogleFonts.outfit(color: colorScheme.primary, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              
              if (upcomingEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text("Planlanmış bir sınavınız/etkinliğiniz yok.", style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.54))),
                )
              else
                ...upcomingEvents.take(5).map((ev) => _buildEventCard(ev, theme)),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (e, st) => Center(child: Text("Hata: $e", style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: _addEvent,
          backgroundColor: colorScheme.primary,
          child: Icon(LucideIcons.plus, color: colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildEventCard(Event ev, ThemeData theme) {
    final date = DateTime.parse(ev.dateStr);
    final diff = date.difference(DateTime.now()).inDays;
    
    String colorHex = ev.colorHex ?? '#EAB308';
    if (!colorHex.startsWith('#')) colorHex = '#$colorHex';
    
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.calendarClock, color: color),
        ),
        title: Text(ev.title, style: GoogleFonts.inter(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
        subtitle: Text("${date.day}/${date.month}/${date.year} - $timeStr", style: GoogleFonts.inter(color: theme.colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
        trailing: Text(
          diff == 0 ? "Bugün" : (diff < 0 ? "Geçti" : "$diff gün"),
          style: GoogleFonts.inter(color: diff < 3 && diff >= 0 ? const Color(0xFFEF4444) : theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
