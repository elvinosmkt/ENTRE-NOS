import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  final bool isPremium;
  final VoidCallback onPremiumLocked;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    required this.isPremium,
    required this.onPremiumLocked,
  });

  final List<Color> colors = const [
    AppColors.neonPink,
    AppColors.neonBlue,
    AppColors.neonPurple,
    AppColors.neonGreen,
    AppColors.primary,
    Colors.white,
    Colors.yellow, // Contrast
    Colors.redAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = color == selectedColor;
          final isPremiumColor = index >= colors.length - 3;
          final isLocked = isPremiumColor && !isPremium;
          
          return GestureDetector(
            onTap: () {
              if (isLocked) {
                onPremiumLocked();
              } else {
                onColorSelected(color);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: isLocked 
                  ? const Icon(Icons.stars_rounded, size: 16, color: Colors.white70)
                  : isSelected
                      ? const Icon(Icons.check, size: 20, color: Colors.white)
                      : null,
            ),
          );
        },
      ),
    );
  }
}
