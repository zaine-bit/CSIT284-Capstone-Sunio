import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shows a menu item's picture from an asset path
/// (e.g. 'assets/images/menu_iced_tea.png').
/// Shows a plain placeholder if the path is empty or the file is missing.
class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    required this.image,
    this.size = 76,
    this.radius = 18,
  });

  final String image;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: size * 0.45,
        color: AppColors.textMuted,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.primarySoft,
        child: image.isEmpty
            ? placeholder
            : Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}
