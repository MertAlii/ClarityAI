import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clarity_ai/app/theme/app_colors.dart';
import 'package:clarity_ai/app/theme/app_text_styles.dart';
import 'package:clarity_ai/models/v2_models.dart';
import 'package:clarity_ai/core/services/database_service.dart';
import 'package:clarity_ai/core/providers/data_providers.dart';

Future<void> showCreateFolderDialog(BuildContext context, WidgetRef ref) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final TextEditingController controller = TextEditingController();
  String selectedColor = '#84CC16'; // Default lime accent
  
  final List<String> colorOptions = [
    '#84CC16', '#F97316', '#22C55E', '#EF4444', '#EAB308', '#3B82F6', '#A855F7'
  ];

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text("Yeni Klasör", style: AppTextStyles.headline3.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  decoration: InputDecoration(
                    hintText: "Klasör Adı",
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text("Renk Seçimi", style: AppTextStyles.label.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colorOptions.map((hex) {
                    final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                    final isSelected = selectedColor == hex;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("İptal", style: AppTextStyles.button.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    final folder = Folder(
                      name: name,
                      colorHex: selectedColor,
                      createdAt: DateTime.now(),
                    );
                    await DatabaseService.instance.insertFolder(folder);
                    ref.invalidate(foldersProvider);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: Text("Oluştur", style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ],
          );
        }
      );
    }
  );
}
