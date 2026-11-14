import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../data/models/booking.dart';
import '../../../shared/widgets/fth_common_widgets.dart';
import '../main_nav/main_nav_screen.dart';

class ConfirmationScreen extends StatelessWidget {
  final Booking booking;
  const ConfirmationScreen({super.key, required this.booking});

  Future<void> _messageReception(BuildContext context) async {
    final cleanNum = AppStrings.secondaryPhone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final msg = Uri.encodeComponent(
      'Hello Family Transit Home, I have submitted Booking Request ${booking.id} for ${booking.accommodation.title}. '
      'Check-in: ${DateFormat('dd MMM yyyy').format(booking.checkInDate)}.',
    );
    final uri = Uri.parse('https://wa.me/$cleanNum?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.slateNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const FthAppBarTitle(title: 'Booking Request Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainNavScreen(initialIndex: 2),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.goldAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldAccent.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.slateNavy,
                size: 44,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Booking Request Submitted',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Provisional Reference: ${booking.id}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.goldAccent,
              ),
            ),
            const SizedBox(height: 10),
            BookingStatusBadge(status: booking.workflowStatus),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.elevatedShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          booking.accommodation.mainImage,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.accommodation.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.accommodation.estate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.emeraldGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.borderSubtle),
                  _voucherRow('Current Status', booking.workflowStatus.label),
                  _voucherRow('Guest Name', booking.guestName),
                  _voucherRow('Rate Plan', booking.ratePlanName),
                  _voucherRow(
                    'Check-In Date',
                    dateFormat.format(booking.checkInDate),
                  ),
                  _voucherRow(
                    'Check-Out Date',
                    dateFormat.format(booking.checkOutDate),
                  ),
                  _voucherRow(
                    'Duration & Guests',
                    '${booking.totalNights} Nights • ${booking.totalGuests} Guests',
                  ),
                  _voucherRow(
                    'Airport Shuttle',
                    booking.requestAirportShuttle
                        ? 'Requested (Complimentary)'
                        : 'Not requested',
                  ),
                  _voucherRow(
                    'Provisional Quote',
                    'K${booking.totalPrice.toStringAsFixed(2)} (GST-Inclusive)',
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What Happens Next?',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: AppColors.slateNavy,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '1. FTH Reservations reviews unit availability and approves your request.\n'
                          '2. You receive official BSP / Kina Bank payment instructions.\n'
                          '3. Upload your bank transfer proof in the Bookings tab.\n'
                          '4. Once FTH Accounts verifies payment, your reservation & arrival access guide are confirmed.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const MainNavScreen(initialIndex: 2),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldGreen,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.assignment_turned_in_outlined, size: 19),
                label: const Text(
                  'Track Booking Status & Payment Instructions',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _messageReception(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('Contact FTH Reservations via WhatsApp'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voucherRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
