import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../data/models/booking.dart';
import '../../../providers/app_state_provider.dart';
import '../../../shared/widgets/fth_common_widgets.dart';
import '../checkin/online_checkin_screen.dart';
import '../guide/guest_guide_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openBookingWorkspaceSheet(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GuestBookingDetailSheet(bookingId: booking.id),
    );
  }

  void _openLookupDialog(BuildContext context) {
    final refCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final state = Provider.of<AppStateProvider>(dialogCtx, listen: false);
          return AlertDialog(
            title: const Text(
              'Load Booking from FTH Reservations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your Booking Reference and registered email address:',
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
                              content: Text('Reservation $ref loaded.'),
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final upcoming = state.upcomingBookings;
    final past = state.pastBookings;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const FthAppBarTitle(title: 'My Bookings & Stay Status'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Active & Upcoming (${upcoming.length})'),
            Tab(text: 'Past & Cancelled (${past.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList(context, upcoming),
          _buildBookingList(context, past),
        ],
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, List<Booking> list) {
    final dateFormat = DateFormat('dd MMM yyyy');

    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FthEmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'No Active Bookings Loaded',
                subtitle:
                    'Already have a reservation? Enter your Booking Reference and Email to load your stay details directly from FTH Reservations.',
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text(
                  'Look Up Booking by Reference',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _openLookupDialog(context),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = list[index];
        return InkWell(
          onTap: () => _openBookingWorkspaceSheet(context, b),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b.id,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: AppColors.slateNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: BookingStatusBadge(
                        status: b.workflowStatus,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        b.accommodation.mainImage,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.accommodation.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${b.accommodation.estate}${b.assignedRoomNumber != null ? " • Unit ${b.assignedRoomNumber}" : ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emeraldGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dateFormat.format(b.checkInDate)} → ${dateFormat.format(b.checkOutDate)} (${b.totalNights} Nights)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total: K${b.totalPrice.toStringAsFixed(2)} (GST-Incl.)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            b.balanceDuePgk > 0
                                ? 'Balance Due: K${b.balanceDuePgk.toStringAsFixed(2)}'
                                : 'Paid & Verified: K${b.amountPaidPgk.toStringAsFixed(2)}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: b.balanceDuePgk > 0
                                  ? const Color(0xFFB45309)
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Manage Stay',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emeraldGreen,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppColors.emeraldGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GuestBookingDetailSheet extends StatefulWidget {
  final String bookingId;
  const _GuestBookingDetailSheet({required this.bookingId});

  @override
  State<_GuestBookingDetailSheet> createState() =>
      _GuestBookingDetailSheetState();
}

class _GuestBookingDetailSheetState extends State<_GuestBookingDetailSheet> {
  final _bankRefCtrl = TextEditingController(text: 'BSP-TXN-884920');
  String? _selectedProofFile;
  String? _selectedProofBase64;
  bool _isUploadingProof = false;
  final String _selectedPaymentMethod = 'Bank Transfer (BSP)';
  String _serviceCategory = 'Housekeeping';
  final _serviceSubjectCtrl = TextEditingController();
  final _serviceDetailsCtrl = TextEditingController();

  @override
  void dispose() {
    _bankRefCtrl.dispose();
    _serviceSubjectCtrl.dispose();
    _serviceDetailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final booking = state.bookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => state.bookings.first,
    );
    final bankDetails = state.bankDetails;
    final dateFormat = DateFormat('EEE, dd MMM yyyy');

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.id,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slateNavy,
                        ),
                      ),
                      Text(
                        booking.accommodation.title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  BookingStatusBadge(status: booking.workflowStatus),
                ],
              ),
              const SizedBox(height: 14),

              // 1. Live Workflow Status Timeline
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reservation Status Timeline',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slateNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      booking.workflowStatus.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusTimelineRow(booking.workflowStatus),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Payment Instructions & Bank Proof Upload
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_rounded,
                          size: 18,
                          color: AppColors.emeraldGreen,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Official FTH Bank Transfer Instructions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slateNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _kvRow('Bank Name', bankDetails['bank_name'] ?? 'BSP'),
                    _kvRow(
                      'Account Name',
                      bankDetails['account_name'] ??
                          'Family Transit Home Limited',
                    ),
                    _kvRow(
                      'BSP Account No.',
                      bankDetails['account_number'] ?? '7014982105',
                    ),
                    _kvRow(
                      'Secondary Bank',
                      bankDetails['secondary_bank'] ??
                          'Kina Bank — Acc: 0011906772',
                    ),
                    _kvRow('BSB / SWIFT', '088-294 / BOSPPGPM'),
                    _kvRow('Payment Narration', booking.id),
                    const Divider(height: 20),
                    const Text(
                      'Upload Bank Transfer / EFTPOS Proof',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Note: Uploading proof sets status to "Payment Proof Under Review". Reservation is confirmed only after FTH Accounts verifies the remittance.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (booking.paymentProofFileName != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 16,
                              color: AppColors.emeraldGreen,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Uploaded File: ${booking.paymentProofFileName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emeraldGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(
                        _selectedProofFile ??
                            'Choose Receipt File (JPG, PNG, PDF — Max 5MB)',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () async {
                        final files = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                        );
                        if (files.isEmpty) return;
                        final file = files.first;
                        final bytes = await file.xFile.readAsBytes();
                        if (bytes.isEmpty) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Selected file is empty.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (bytes.lengthInBytes > 5 * 1024 * 1024) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'File exceeds 5 MB maximum allowed size.',
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _selectedProofFile = file.name;
                          _selectedProofBase64 = base64Encode(bytes);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _bankRefCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Bank Transaction Reference Number',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isUploadingProof
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined, size: 18),
                        label: Text(
                          _isUploadingProof
                              ? 'Uploading...'
                              : 'Submit Payment Proof for Accounts Review',
                        ),
                        onPressed: _isUploadingProof
                            ? null
                            : () async {
                                if (_selectedProofFile == null ||
                                    _selectedProofBase64 == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a payment receipt file (JPG, PNG, or PDF).',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }
                                if (_bankRefCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter your bank transaction reference number.',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _isUploadingProof = true);
                                try {
                                  await state.uploadGuestPaymentProofAsync(
                                    bookingId: booking.id,
                                    proofFileName: _selectedProofFile!,
                                    paymentMethod: _selectedPaymentMethod,
                                    referenceNumber: _bankRefCtrl.text.trim(),
                                    proofFileBase64: _selectedProofBase64,
                                  );
                                  if (!context.mounted) return;
                                  setState(() => _isUploadingProof = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Payment proof uploaded. Status updated to Payment Proof Under Review.',
                                      ),
                                      backgroundColor: AppColors.emeraldGreen,
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  setState(() => _isUploadingProof = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Invoices, Official Receipts & Folio Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 18,
                          color: AppColors.slateNavy,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Folio, Tax Invoice & Official Receipts',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slateNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _kvRow(
                      'Stay Dates',
                      '${dateFormat.format(booking.checkInDate)} → ${dateFormat.format(booking.checkOutDate)}',
                    ),
                    _kvRow(
                      'Total Folio Charges (GST-Incl.)',
                      'K${booking.totalPrice.toStringAsFixed(2)}',
                    ),
                    _kvRow(
                      'Verified Payments Received',
                      'K${booking.amountPaidPgk.toStringAsFixed(2)}',
                    ),
                    _kvRow(
                      'Current Balance Due',
                      'K${booking.balanceDuePgk.toStringAsFixed(2)}',
                    ),
                    if (booking.invoice != null) ...[
                      const Divider(height: 18),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.surfaceMuted,
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: AppColors.slateNavy,
                          ),
                        ),
                        title: Text(
                          'Tax Invoice ${booking.invoice!.invoiceNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Total: K${booking.invoice!.totalAmountPgk.toStringAsFixed(2)} • Status: ${booking.invoice!.status.toUpperCase()}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () {
                            _showDocumentPreviewDialog(
                              context,
                              title:
                                  'Official Tax Invoice (${booking.invoice!.invoiceNumber})',
                              booking: booking,
                              isReceipt: false,
                            );
                          },
                          child: const Text('View PDF'),
                        ),
                      ),
                    ],
                    if (booking.receipts.isNotEmpty) ...[
                      for (final rcp in booking.receipts)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.successBg,
                            child: Icon(
                              Icons.verified_rounded,
                              color: AppColors.success,
                            ),
                          ),
                          title: Text(
                            'Official Receipt ${rcp.receiptNumber}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            'Verified: K${rcp.amountPgk.toStringAsFixed(2)} • ${rcp.paymentMethod}',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          trailing: OutlinedButton(
                            onPressed: () {
                              _showDocumentPreviewDialog(
                                context,
                                title:
                                    'Official Payment Receipt (${rcp.receiptNumber})',
                                booking: booking,
                                isReceipt: true,
                              );
                            },
                            child: const Text('Receipt'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Online Check-In, Airport Pickup & In-Stay Service Requests
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pre-Arrival Check-In & In-Stay Services',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slateNavy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.badge_outlined, size: 17),
                            label: const Text('Online Check-In'),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const OnlineCheckinScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.menu_book_outlined,
                              size: 17,
                            ),
                            label: const Text('Arrival Guide'),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GuestGuideScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 22),
                    const Text(
                      'Submit Housekeeping / Airport Shuttle / Maintenance Request',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _serviceCategory,
                      decoration: const InputDecoration(
                        labelText: 'Service Category',
                        prefixIcon: Icon(Icons.room_service_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Housekeeping',
                          child: Text('Housekeeping & Fresh Linens'),
                        ),
                        DropdownMenuItem(
                          value: 'Airport Shuttle',
                          child: Text('Airport Pickup / Transfer Coordination'),
                        ),
                        DropdownMenuItem(
                          value: 'Maintenance',
                          child: Text('On-Call Maintenance Assistance'),
                        ),
                        DropdownMenuItem(
                          value: 'Extra Amenities',
                          child: Text('Kitchen / Laundry / Toiletries Request'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _serviceCategory = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _serviceSubjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Request Summary (e.g. Flight PX100 Pickup)',
                        prefixIcon: Icon(Icons.short_text_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _serviceDetailsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Time / Details',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send_rounded, size: 17),
                        label: const Text('Submit Guest Service Request'),
                        onPressed: () {
                          if (_serviceSubjectCtrl.text.trim().isEmpty) return;
                          state.submitGuestServiceRequest(
                            bookingReference: booking.id,
                            guestName: booking.guestName,
                            roomNumber: booking.assignedRoomNumber ?? 'TBD',
                            estateName: booking.accommodation.estate,
                            category: _serviceCategory,
                            subject: _serviceSubjectCtrl.text.trim(),
                            details: _serviceDetailsCtrl.text.trim(),
                          );
                          _serviceSubjectCtrl.clear();
                          _serviceDetailsCtrl.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Service request logged with FTH Front Desk & Operations.',
                              ),
                              backgroundColor: AppColors.emeraldGreen,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. Cancellation Policy & Backend Refund Quote Notice
              if (booking.workflowStatus != BookingWorkflowStatus.cancelled &&
                  booking.workflowStatus != BookingWorkflowStatus.checkedOut)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cancellation & Refund Policy',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slateNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        AppStrings.cancellationPolicyNotice,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 17),
                          label: const Text(
                            'Request Cancellation & Backend Refund Quote',
                          ),
                          onPressed: () async {
                            try {
                              final res = await state.cancelBookingAsync(booking.id);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              final msg = res['message']?.toString() ??
                                  'Cancellation processed under the 48-hour FTH policy.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: AppColors.slateNavy,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusTimelineRow(BookingWorkflowStatus current) {
    final steps = [
      BookingWorkflowStatus.pendingApproval,
      BookingWorkflowStatus.approvedAwaitingPayment,
      BookingWorkflowStatus.paymentUnderReview,
      BookingWorkflowStatus.confirmed,
      BookingWorkflowStatus.checkedIn,
    ];
    final currentIdx = steps.indexOf(current);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(steps.length, (idx) {
        final s = steps[idx];
        final isDone = currentIdx >= idx;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: isDone ? AppColors.emeraldGreen : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 13,
                color: isDone ? AppColors.goldAccent : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '${idx + 1}. ${s.shortLabel}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDone ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentPreviewDialog(
    BuildContext context, {
    required String title,
    required Booking booking,
    required bool isReceipt,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking Reference: ${booking.id}'),
            Text('Guest: ${booking.guestName}'),
            Text('Accommodation: ${booking.accommodation.title}'),
            Text('Estate: ${booking.accommodation.estate}'),
            const Divider(height: 18),
            Text(
              'Total Amount (GST-Incl.): K${booking.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (isReceipt)
              Text(
                'Verified Paid: K${booking.amountPaidPgk.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.emeraldGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
