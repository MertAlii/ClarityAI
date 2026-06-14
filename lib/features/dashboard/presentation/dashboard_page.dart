import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clarity_ai/app/theme/app_colors.dart';
import 'package:clarity_ai/app/theme/app_text_styles.dart';
import 'package:clarity_ai/core/widgets/floating_navbar.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';
import 'package:clarity_ai/core/providers/data_providers.dart';
import 'package:clarity_ai/models/v2_models.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const _HomeTab(),
    const Center(child: Text("Takvim ve Etkinlikler")),
    const Center(child: Text("Sohbet")),
    const Center(child: Text("Ayarlar")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
          FloatingNavbar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            icons: const [
              LucideIcons.home,
              LucideIcons.calendar,
              LucideIcons.messageCircle,
              LucideIcons.settings,
            ],
            labels: const [
              "Ana Sayfa",
              "Takvim",
              "Sohbet",
              "Ayarlar",
            ],
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 100.0), // Navbar'ın üzerinde kalması için
              child: FloatingActionButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/create');
                },
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkAccent
                    : AppColors.lightAccent,
                child: const Icon(LucideIcons.plus, color: Colors.white),
              ),
            )
          : null,
    );
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  int? _selectedFolderId;
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foldersAsync = ref.watch(foldersProvider);
    final notesAsync = ref.watch(notesProvider(_selectedFolderId));

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analitik Kartları
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.clock, size: 16, color: AppColors.streakOrange),
                            const SizedBox(width: 8),
                            Text("Bugün Çalışılan", style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("45 dk", style: AppTextStyles.headline3.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.calendarClock, size: 16, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Text("Yaklaşan Sınav", style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("3 Gün", style: AppTextStyles.headline3.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Arama ve Görünüm Değiştirici
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Notlarda ve materyallerde ara...",
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        prefixIcon: Icon(LucideIcons.search, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Icon(
                      _isGridView ? LucideIcons.list : LucideIcons.grid,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_searchQuery.isNotEmpty)
            Expanded(
              child: _buildDeepSearchResults(),
            )
          else ...[
            // Klasör Listesi
            foldersAsync.when(
              data: (folders) {
                return SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: folders.length + 2, // Tümü + Klasörler + Yeni Klasör
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedFolderId == null;
                        return _buildFolderChip(
                          "Tümü",
                          isSelected,
                          isDark,
                          () {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedFolderId = null);
                          },
                        );
                      } else if (index == folders.length + 1) {
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            // Yeni klasör oluşturma işlemi buraya eklenecek
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.plus, size: 16, color: isDark ? AppColors.darkAccent : AppColors.lightAccent),
                                const SizedBox(width: 4),
                                Text(
                                  "Yeni Klasör",
                                  style: AppTextStyles.label.copyWith(
                                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        final folder = folders[index - 1];
                        final isSelected = _selectedFolderId == folder.id;
                        return _buildFolderChip(
                          folder.name,
                          isSelected,
                          isDark,
                          () {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedFolderId = folder.id);
                          },
                        );
                      }
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text("Klasörler yüklenemedi.", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
              ),
            ),
            const SizedBox(height: 16),

            // Notlar
            Expanded(
              child: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return Center(
                      child: Text(
                        "Burada henüz not yok.",
                        style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                    );
                  }
                  
                  return _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            return _buildNoteCard(notes[index], isDark, isGrid: true);
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            return _buildNoteCard(notes[index], isDark, isGrid: false);
                          },
                        );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text("Notlar yüklenemedi.", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFolderChip(String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
              : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note, bool isDark, {required bool isGrid}) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              LucideIcons.fileText,
              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              size: 20,
            ),
            if (note.isStarred == 1)
              const Icon(LucideIcons.star, color: AppColors.premiumGold, size: 16),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          note.title,
          style: AppTextStyles.label.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (isGrid) const Spacer() else const SizedBox(height: 8),
        Text(
          "Hedef: ${note.targetAudience}",
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return GlassCard(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      onTap: () {
        context.push('/note/${note.id}');
      },
      child: content,
    );
  }

  Widget _buildDeepSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notesAsync = ref.watch(notesProvider(null));
    
    return notesAsync.when(
      data: (notes) {
        final filtered = notes.where((n) => n.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.searchX, size: 48, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                const SizedBox(height: 16),
                Text(
                  "Sonuç bulunamadı",
                  style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final note = filtered[index];
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () {
                context.push('/note/${note.id}');
              },
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.search, color: isDark ? AppColors.darkAccent : AppColors.lightAccent),
                ),
                title: Text(
                  note.title,
                  style: AppTextStyles.bodyLarge.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
                subtitle: Text(
                  "Derin Arama Eşleşmesi",
                  style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text("Arama başarısız.", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
      ),
    );
  }
}
