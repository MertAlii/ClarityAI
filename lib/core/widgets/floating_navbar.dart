import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clarity_ai/app/theme/app_text_styles.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Positioned(
      bottom: 24,
      left: 32,
      right: 32,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withOpacity(0.6)
                  : colorScheme.surfaceContainer.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : colorScheme.outlineVariant.withOpacity(0.5),
                width: 0.5,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavBarItem(
                  icon: LucideIcons.layoutGrid,
                  label: 'Ana Sayfa',
                  isSelected: currentIndex == 0,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(0);
                  },
                ),
                _NavBarItem(
                  icon: LucideIcons.calendar,
                  label: 'Takvim',
                  isSelected: currentIndex == 1,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(1);
                  },
                ),
                _NavBarItem(
                  icon: LucideIcons.messageSquare,
                  label: 'Sohbet',
                  isSelected: currentIndex == 2,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(2);
                  },
                ),
                _NavBarItem(
                  icon: LucideIcons.settings,
                  label: 'Ayarlar',
                  isSelected: currentIndex == 3,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(3);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
