import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';
import 'package:clarity_ai/core/providers/data_providers.dart';
import 'package:clarity_ai/core/services/database_service.dart';
import 'package:clarity_ai/models/v2_models.dart';

class ChatSessionsPage extends ConsumerWidget {
  const ChatSessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Sohbetler', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF84CC16),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: Text('Yeni Sohbet', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        onPressed: () async {
          HapticFeedback.lightImpact();
          final newSession = ChatSession(
            id: const Uuid().v4(),
            title: 'Yeni Sohbet',
            createdAt: DateTime.now(),
          );
          await DatabaseService.instance.insertChatSession(newSession);
          ref.invalidate(chatSessionsProvider);
          if (context.mounted) {
            context.push('/chat/${newSession.id}');
          }
        },
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(child: Text('Henüz sohbet yok.', style: GoogleFonts.inter(color: Colors.white54)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () {
                  context.push('/chat/${session.id}');
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF242424),
                    child: Icon(Icons.chat_bubble_outline, color: Color(0xFF84CC16)),
                  ),
                  title: Text(session.title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text('${session.createdAt.day.toString().padLeft(2, '0')}/${session.createdAt.month.toString().padLeft(2, '0')}/${session.createdAt.year}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16))),
        error: (err, stack) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
