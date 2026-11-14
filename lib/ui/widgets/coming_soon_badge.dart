import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class ComingSoonBadge extends StatelessWidget {
  final String text;
  final bool compact;

  const ComingSoonBadge({
    super.key,
    this.text = 'Coming Soon',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: compact ? 10 : 13,
            color: AppColors.goldDark,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.bold,
              color: AppColors.goldDark,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
