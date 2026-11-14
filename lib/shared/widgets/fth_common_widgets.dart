import 'package:flutter/material.dart';
import '../../core/constants/assets.dart';
import '../../core/constants/colors.dart';
import '../../data/models/booking.dart';

/// Official circular FTH logo badge matching the website's `<img src="images/fth_logo.png" class="rounded-full">` styling.
class FthBrandLogoBadge extends StatelessWidget {
  final double size;
  final Color borderColor;
  final double borderWidth;

  const FthBrandLogoBadge({
    super.key,
    this.size = 34,
    this.borderColor = AppColors.goldAccent,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          AppAssets.logo,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Standardized AppBar title widget featuring the circular FTH website logo badge alongside the screen title.
class FthAppBarTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color textColor;
  final double logoSize;

  const FthAppBarTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.textColor = Colors.white,
    this.logoSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FthBrandLogoBadge(size: logoSize),
        const SizedBox(width: 10),
        Flexible(
          child: subtitle == null
              ? Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Displays a subtle live system notice banner connected to the FTH Laravel 12 backend.
class PreviewModeBanner extends StatelessWidget {
  final String text;
  final IconData icon;

  const PreviewModeBanner({
    super.key,
    this.text = 'Connected to Family Transit Home PMS & Reservations System',
    this.icon = Icons.verified_outlined,
  });

  String _cleanText(String raw) {
    return raw
        .replaceAll('UI Preview Mode — ', '')
        .replaceAll('UI Preview — ', '')
        .replaceAll(' (Preview)', '')
        .replaceAll('Preview ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.emeraldGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.emeraldGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.emeraldGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _cleanText(text),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.emeraldGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standardized Booking Workflow Status Badge matching FTH PMS colors.
class BookingStatusBadge extends StatelessWidget {
  final BookingWorkflowStatus status;
  final bool compact;

  const BookingStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case BookingWorkflowStatus.pendingApproval:
        bg = AppColors.warningBg;
        fg = const Color(0xFFB45309);
        icon = Icons.hourglass_top_rounded;
        break;
      case BookingWorkflowStatus.approvedAwaitingPayment:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        icon = Icons.account_balance_wallet_outlined;
        break;
      case BookingWorkflowStatus.paymentUnderReview:
        bg = AppColors.purpleBg;
        fg = AppColors.purple;
        icon = Icons.fact_check_outlined;
        break;
      case BookingWorkflowStatus.confirmed:
        bg = AppColors.successBg;
        fg = const Color(0xFF047857);
        icon = Icons.verified_rounded;
        break;
      case BookingWorkflowStatus.checkedIn:
        bg = AppColors.emeraldSurface;
        fg = AppColors.emeraldGreen;
        icon = Icons.vpn_key_rounded;
        break;
      case BookingWorkflowStatus.checkedOut:
        bg = AppColors.surfaceMuted;
        fg = AppColors.slateNavy;
        icon = Icons.task_alt_rounded;
        break;
      case BookingWorkflowStatus.cancelled:
      case BookingWorkflowStatus.rejected:
        bg = AppColors.errorBg;
        fg = AppColors.error;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              compact ? status.shortLabel : status.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable empty state widget with action button.
class FthEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FthEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AppColors.emeraldGreen),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
