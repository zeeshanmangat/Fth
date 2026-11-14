import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../data/models/amenity.dart';

class AmenityChip extends StatelessWidget {
  final Amenity amenity;
  final bool isSelected;
  final VoidCallback? onTap;

  const AmenityChip({
    super.key,
    required this.amenity,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              amenity.icon,
              size: 18,
              color: isSelected ? AppColors.goldAccent : AppColors.primaryNavy,
            ),
            const SizedBox(width: 8),
            Text(
              amenity.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
