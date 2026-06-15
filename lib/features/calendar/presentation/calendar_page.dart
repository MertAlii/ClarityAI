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
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: Text("Yeni Etkinlik", style: GoogleFonts.outfit(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Örn: Matematik Vize",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF242424),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", style: GoogleFonts.inter(color: Colors.white)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFF84CC16),
                                    onPrimary: Colors.black,
                                    surface: Color(0xFF1A1A1A),
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        child: Text("Tarih", style: GoogleFonts.inter(color: const Color(0xFF84CC16))),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(selectedTime.format(context), style: GoogleFonts.inter(color: Colors.white)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFF84CC16),
                                    onPrimary: Colors.black,
                                    surface: Color(0xFF1A1A1A),
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        child: Text("Saat", style: GoogleFonts.inter(color: const Color(0xFF84CC16))),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("İptal", style: GoogleFonts.inter(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16)),
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
                  child: Text("Ekle", style: GoogleFonts.inter(color: Colors.black)),
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

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text("Takvim ve Etkinlikler", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    defaultTextStyle: GoogleFonts.inter(color: Colors.white),
                    weekendTextStyle: GoogleFonts.inter(color: Colors.white54),
                    outsideTextStyle: GoogleFonts.inter(color: Colors.white24),
                    selectedDecoration: const BoxDecoration(color: Color(0xFF84CC16), shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: const Color(0xFF84CC16).withOpacity(0.3), shape: BoxShape.circle),
                    markerDecoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.inter(color: Colors.white70),
                    weekendStyle: GoogleFonts.inter(color: Colors.white54),
                  ),
                ),
              ),
              
              if (selectedEvents.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Seçili Gün (${_selectedDay?.day}/${_selectedDay?.month})", style: GoogleFonts.outfit(color: const Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                ...selectedEvents.map((ev) => _buildEventCard(ev)),
              ],

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("Yaklaşanlar", style: GoogleFonts.outfit(color: const Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              
              if (upcomingEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text("Planlanmış bir sınavınız/etkinliğiniz yok.", style: GoogleFonts.inter(color: Colors.white54)),
                )
              else
                ...upcomingEvents.take(5).map((ev) => _buildEventCard(ev)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16))),
        error: (e, st) => Center(child: Text("Hata: $e", style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton(
          onPressed: _addEvent,
          backgroundColor: const Color(0xFF84CC16),
          child: const Icon(LucideIcons.plus, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildEventCard(Event ev) {
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
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.calendarClock, color: color),
        ),
        title: Text(ev.title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text("${date.day}/${date.month}/${date.year} - $timeStr", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        trailing: Text(
          diff == 0 ? "Bugün" : (diff < 0 ? "Geçti" : "$diff gün"),
          style: GoogleFonts.inter(color: diff < 3 && diff >= 0 ? const Color(0xFFEF4444) : Colors.white70, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
