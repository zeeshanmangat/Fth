import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../providers/app_state_provider.dart';
import '../../../shared/widgets/fth_common_widgets.dart';
import '../about/about_screen.dart';
import '../checkin/online_checkin_screen.dart';
import '../contact/contact_screen.dart';
import '../guide/guest_guide_screen.dart';
import '../notifications/notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  final ValueChanged<int>? onTabChange;
  const ProfileScreen({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final user = state.userProfile;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const FthAppBarTitle(title: 'Guest Profile & Stay Tools'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.elevatedShadow,
              ),
              child: Row(
                children: [
                  const FthBrandLogoBadge(size: 58, borderWidth: 2),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.goldAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.phone,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                    onPressed: () => _openLookupBookingModal(context, state),
                    child: Text(
                      state.bookings.isNotEmpty ? 'Change' : 'Lookup',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Bookings',
                    '${state.bookings.length}',
                    Icons.calendar_month_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Saved Units',
                    '${state.favoriteIds.length}',
                    Icons.favorite_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Estates',
                    '${state.estates.length}',
                    Icons.domain_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _menuGroup(
              title: 'Guest Services & Stay Management',
              items: [
                _menuTile(
                  Icons.badge_outlined,
                  'Online Pre-Arrival Check-In',
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnlineCheckinScreen(),
                      ),
                    );
                  },
                ),
                _menuTile(
                  Icons.menu_book_rounded,
                  'Arrival Guide & Local Directory',
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GuestGuideScreen(),
                      ),
                    );
                  },
                ),
                _menuTile(
                  Icons.notifications_outlined,
                  'Notifications & Booking Alerts',
                  () {
                    if (onTabChange != null) {
                      onTabChange!(3);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                _menuTile(
                  Icons.support_agent_rounded,
                  'Contact FTH Reception & Support',
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ContactScreen()),
                    );
                  },
                ),
                _menuTile(
                  Icons.info_outline_rounded,
                  'About Family Transit Home (3 Estates)',
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Column(
                children: [
                  Text(
                    'Family Transit Home — Reception Office',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${AppStrings.primaryPhone} | ${AppStrings.secondaryPhone}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.emeraldGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    AppStrings.receptionOffice,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.emeraldGreen, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.slateNavy,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuGroup({required String title, required List<Widget> items}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.emeraldGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.emeraldGreen),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.textMuted,
      ),
    );
  }

  void _openLookupBookingModal(BuildContext context, AppStateProvider state) {
    final refCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Look Up FTH Booking',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your Booking Reference and registered email to load your reservation details:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Booking Reference *',
                  hintText: 'e.g. FTH-2026-0001',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Registered Guest Email *',
                  hintText: 'guest@example.com',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emeraldGreen,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final ref = refCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      if (ref.isEmpty || email.isEmpty) return;

                      setDialogState(() => isSubmitting = true);
                      try {
                        await state.lookupGuestBooking(
                          bookingReference: ref,
                          email: email,
                        );
                        if (!dialogCtx.mounted) return;
                        Navigator.of(dialogCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reservation $ref verified.'),
                            backgroundColor: AppColors.emeraldGreen,
                          ),
                        );
                      } catch (e) {
                        if (!dialogCtx.mounted) return;
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Verify & Load'),
            ),
          ],
        ),
      ),
    );
  }
}
