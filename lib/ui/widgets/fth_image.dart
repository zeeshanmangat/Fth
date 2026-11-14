import 'package:flutter/material.dart';
import 'package:family_transit_home/core/constants/assets.dart';
import 'package:family_transit_home/core/constants/colors.dart';

/// Renders either an uploaded remote network photo (`http://` / `https://`)
/// or a bundled FTH local asset with a graceful fallback icon.
class FthImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData fallbackIcon;

  const FthImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackIcon = Icons.apartment_rounded,
  });

  Widget _buildFallback() {
    return Image.asset(
      AppAssets.fthServicedApartments,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (ctx, err, stack) => Container(
        width: width,
        height: height,
        color: AppColors.surfaceMuted,
        child: Center(
          child: Icon(
            fallbackIcon,
            color: AppColors.textMuted,
            size: 40,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = imagePath.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _buildFallback(),
      );
    }

    return Image.asset(
      trimmed.isNotEmpty ? trimmed : AppAssets.fthServicedApartments,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (ctx, err, stack) => _buildFallback(),
    );
  }
}
