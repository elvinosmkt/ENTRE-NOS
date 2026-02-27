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
    Colors.yellow,
    Colors.redAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              width: isSelected ? 44 : 38,
              height: isSelected ? 44 : 38,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(isSelected ? 0.4 : 0.1),
                    blurRadius: isSelected ? 15 : 5,
                    spreadRadius: isSelected ? 2 : 0,
                    offset: isSelected ? const Offset(0, 4) : Offset.zero,
                  ),
                ],
              ),
              child: isLocked 
                  ? const Icon(Icons.lock_rounded, size: 14, color: Colors.white70)
                  : isSelected
                      ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                      : null,
            ),
          );
        },
      ),
    );
  }
}

