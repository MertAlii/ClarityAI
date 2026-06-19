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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Sohbetler', style: GoogleFonts.outfit(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton.extended(
          heroTag: null,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
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
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(child: Text('Henüz sohbet yok.', style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.54))));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Dismissible(
                key: Key(session.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.delete_outline, color: colorScheme.onError),
                ),
                onDismissed: (direction) async {
                  // TODO: Implement deleteChatSession in DatabaseService if not exists
                  // await DatabaseService.instance.deleteChatSession(session.id);
                  // For now we will try to call it, or we will implement it shortly.
                  await DatabaseService.instance.deleteChatSession(session.id);
                  ref.invalidate(chatSessionsProvider);
                },
                child: GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  onTap: () {
                    context.push('/chat/${session.id}');
                  },
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.chat_bubble_outline, color: colorScheme.primary),
                    ),
                    title: Text(session.title, style: GoogleFonts.inter(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    subtitle: Text('${session.createdAt.day.toString().padLeft(2, '0')}/${session.createdAt.month.toString().padLeft(2, '0')}/${session.createdAt.year}', style: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.54)),
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (err, stack) => Center(child: Text('Hata: $err', style: TextStyle(color: colorScheme.error))),
      ),
    );
  }
}
