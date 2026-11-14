import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/repositories/guest_guide_repository.dart';
import '../../../providers/app_state_provider.dart';
import '../../../shared/widgets/fth_common_widgets.dart';
import '../checkin/online_checkin_screen.dart';

class GuestGuideScreen extends StatefulWidget {
  final int initialTabIndex;
  const GuestGuideScreen({super.key, this.initialTabIndex = 0});

  @override
  State<GuestGuideScreen> createState() => _GuestGuideScreenState();
}

class _GuestGuideScreenState extends State<GuestGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Lookup controllers
  final _lookupRefCtrl = TextEditingController();
  final _lookupEmailCtrl = TextEditingController();

  // In-House Service Request form controllers
  final _requestFormKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  String _selectedCategory = 'Airport Pickup';
  String _selectedPriority = 'Normal';
  bool _isSubmittingRequest = false;
  bool _isLookingUp = false;

  final List<String> _serviceCategories = [
    'Airport Pickup',
    'City Transfer',
    'Maintenance',
    'Food Delivery',
    'Special Request',
    'General Enquiry',
  ];

  final List<String> _urgencyLevels = ['Normal', 'Low', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppStateProvider>(context, listen: false);
      if (state.isGuestLoggedIn && state.bookings.isNotEmpty) {
        _lookupRefCtrl.text = state.bookings.first.id;
        _lookupEmailCtrl.text = state.userProfile.email;
        state.loadGuestRequests();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lookupRefCtrl.dispose();
    _lookupEmailCtrl.dispose();
    _subjectCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String number) async {
    final cleanNum = number.split('/')[0].trim();
    final uri = Uri.parse('tel:$cleanNum');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _handleLookup(AppStateProvider state) async {
    final ref = _lookupRefCtrl.text.trim();
    final email = _lookupEmailCtrl.text.trim();

    if (ref.isEmpty || email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter both your Booking Reference (e.g. FTH-2026-0001) and registered email.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLookingUp = true);
    try {
      await state.lookupGuestBooking(bookingReference: ref, email: email);
      await state.loadGuestRequests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reservation $ref verified successfully.'),
          backgroundColor: AppColors.emeraldGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  Future<void> _handleSubmitRequest(
    AppStateProvider state,
    Booking booking,
  ) async {
    if (!_requestFormKey.currentState!.validate()) return;

    setState(() => _isSubmittingRequest = true);
    try {
      await state.submitGuestServiceRequest(
        bookingReference: booking.id,
        guestName: booking.guestName,
        roomNumber: booking.assignedRoomNumber ?? 'Unassigned',
        estateName: booking.accommodation.estate,
        category: _selectedCategory,
        subject: _subjectCtrl.text.trim(),
        details: _detailsCtrl.text.trim(),
        priority: _selectedPriority,
      );

      if (!mounted) return;
      _subjectCtrl.clear();
      _detailsCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your $_selectedCategory request has been sent directly to the Front Desk.',
          ),
          backgroundColor: AppColors.emeraldGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingRequest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.emeraldGreen,
        title: const FthAppBarTitle(title: 'Guest Guide & My Stay Portal'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.room_service_rounded, size: 18),
              text: 'My Stay (Concierge)',
            ),
            Tab(
              icon: Icon(Icons.badge_outlined, size: 18),
              text: 'Pre-Check-In Notice',
            ),
            Tab(
              icon: Icon(Icons.airport_shuttle_rounded, size: 18),
              text: 'Airport Shuttle Guide',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyStayTab(context, state),
          _buildPreCheckInTab(context),
          _buildArrivalGuideTab(context, state),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: IN-HOUSE GUEST SERVICES (MY STAY)
  // ===========================================================================
  Widget _buildMyStayTab(BuildContext context, AppStateProvider state) {
    final activeBooking = state.bookings.isNotEmpty ? state.bookings.first : null;
    final requests = state.guestServiceRequests;

    return RefreshIndicator(
      onRefresh: () async {
        await state.refreshGuestPortal();
        await state.loadGuestRequests();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Notice matching website header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.goldDark,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Direct Front Desk Connectivity',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slateNavy,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Verify your booking reference and email to submit real-time stay requests (airport pickup, transfers, maintenance, food delivery) directly to Front Desk Operations.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Booking Lookup / Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activeBooking != null
                    ? AppColors.emeraldGreen.withValues(alpha: 0.3)
                    : AppColors.borderSubtle,
              ),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reservation Verification',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slateNavy,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: activeBooking != null
                            ? AppColors.emeraldGreen.withValues(alpha: 0.12)
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        activeBooking != null ? 'Verified Stay' : 'Unverified',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: activeBooking != null
                              ? AppColors.emeraldGreen
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (activeBooking == null) ...[
                  const Text(
                    'Enter your Booking Reference and registered email to load your reservation:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _lookupRefCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Booking Reference *',
                      hintText: 'e.g. FTH-2026-0001',
                      prefixIcon: Icon(Icons.bookmark_border_rounded, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lookupEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Registered Guest Email *',
                      hintText: 'guest@example.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLookingUp ? null : () => _handleLookup(state),
                      child: _isLookingUp
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Verify & Load My Stay Status',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ] else ...[
                  // Verified Booking Active Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              activeBooking.id,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: AppColors.emeraldGreen,
                              ),
                            ),
                            BookingStatusBadge(
                              status: activeBooking.workflowStatus,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${activeBooking.accommodation.title} • ${activeBooking.accommodation.estate}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slateNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${activeBooking.checkInDate.toLocal().toString().split(" ")[0]} → ${activeBooking.checkOutDate.toLocal().toString().split(" ")[0]} • Assigned Unit: ${activeBooking.assignedRoomNumber ?? "At Reception (16G-02)"}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        state.logoutGuestPreview();
                      },
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text(
                        'Change Booking',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Submit Stay Request Form
          if (activeBooking != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppColors.softShadow,
              ),
              child: Form(
                key: _requestFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Submit an In-House Guest Request',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slateNavy,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Front Desk Live',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emeraldGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Service Category *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            items: _serviceCategories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Urgency / Priority *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            items: _urgencyLevels
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      p,
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedPriority = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Request Subject *',
                        hintText: 'e.g. Flight PX102 Pickup, Extra Linens, AC Check',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _detailsCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Request Description *',
                        hintText:
                            'Provide flight arrival time, destination, issue details, or special preferences...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isSubmittingRequest
                            ? null
                            : () => _handleSubmitRequest(state, activeBooking),
                        child: _isSubmittingRequest
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Send Request to Front Desk',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submitted Service Requests History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Submitted Service Requests (${requests.length})',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slateNavy,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh Requests',
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () => state.loadGuestRequests(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (requests.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Center(
                  child: Text(
                    'No service requests submitted yet for this booking.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final r = requests[idx];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  r.id,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: AppColors.emeraldGreen,
                                  ),
                                ),
                                const Text(' • '),
                                Text(
                                  r.requestCategory,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.slateNavy,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(r.status)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                r.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _getStatusColor(r.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.details,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (r.staffResponseNote != null &&
                            r.staffResponseNote!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.emeraldGreen
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.reply_rounded,
                                  size: 16,
                                  color: AppColors.emeraldGreen,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Response: ${r.staffResponseNote}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.emeraldGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: ONLINE CHECK-IN & SAFE IDENTITY VERIFICATION NOTICE
  // ===========================================================================
  Widget _buildPreCheckInTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Official Notice Banner matching website
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Color(0xFFB45309),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Pre-Check-In ID Verification, Hours & Vehicle Pass:',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'You can securely upload your valid photo ID (PNG National ID, Passport, or Driver\'s Licence — JPG/PNG/PDF max 5 MB) in Online Pre-Check-In for Front Desk / Supervisor review on private storage.\n• Check-In: 1:00 PM (Early check-in free when unit is available) | Check-Out: 10:00 AM (Late check-out PGK 200.00 fee).\n• Guest Vehicle Pass: Issued for registered vehicles at Kennedy Estate 24/7 guardhouse & Reception (Unit 16G-02).',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF78350F),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3 Process Steps
        _buildStepCard(
          step: 'Step 1 • Reservation Verification',
          title: 'Booking Approval & Full Payment',
          description:
              'Ensure your booking request has been approved by our Sales/Front Desk team and full payment has been verified by Accounts prior to check-in.',
          icon: Icons.check_circle_outline_rounded,
          badgeColor: AppColors.emeraldGreen,
        ),
        const SizedBox(height: 12),
        _buildStepCard(
          step: 'Step 2 • Flight & Shuttle Details',
          title: 'Confirm Airport Pickup Time',
          description:
              'Provide your flight number (e.g. Air Niugini / Qantas) and arrival time at least 24 hours before arrival so our driver is dispatched on schedule.',
          icon: Icons.flight_land_rounded,
          badgeColor: AppColors.emeraldGreen,
        ),
        const SizedBox(height: 12),
        _buildStepCard(
          step: 'Step 3 • Front Desk Check-In',
          title: 'In-Person ID Verification',
          description:
              'Present your photo identification at the estate reception to receive your apartment keys, gate security pass, and Wi-Fi credentials.',
          icon: Icons.key_rounded,
          badgeColor: AppColors.goldDark,
        ),
        const SizedBox(height: 20),

        // Action Button: Online Pre-Check-In
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emeraldGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.badge_rounded, size: 18),
            label: const Text(
              'Complete Online Pre-Check-In Form',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OnlineCheckinScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slateNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: ARRIVAL & AIRPORT SHUTTLE GUIDE
  // ===========================================================================
  Widget _buildArrivalGuideTab(BuildContext context, AppStateProvider state) {
    final items = GuestGuideRepository.getGuideItems();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Duty Desk Hotline Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.emeraldGreen,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.elevatedShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Arrival & Complimentary Airport Shuttle',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'How to connect with our shuttle driver at Jacksons International Airport and check in smoothly.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: AppColors.slateNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                label: const Text(
                  'Call Duty Desk: +675 7135 8804',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                onPressed: () => _makeCall('+67571358804'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 Rapid Arrival Steps
        const Text(
          '4-Step Rapid Transfer Process',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.slateNavy,
          ),
        ),
        const SizedBox(height: 10),
        _buildShuttleStep(
          number: '1',
          title: 'Share Flight Schedule',
          text:
              'Include your flight number when booking or email reservations@familytransithome.com.',
        ),
        const SizedBox(height: 8),
        _buildShuttleStep(
          number: '2',
          title: 'Terminal Pickup Point',
          text:
              'Our driver meets arriving guests outside the International or Domestic Arrivals exit at Jacksons Airport.',
        ),
        const SizedBox(height: 8),
        _buildShuttleStep(
          number: '3',
          title: 'Rapid Estate Transfer',
          text:
              'Kennedy Estate (7 Mile) is approx. 5 mins away; Venezia (6 Mile) and Grand Eden (8 Mile) are 7–12 mins away.',
        ),
        const SizedBox(height: 8),
        _buildShuttleStep(
          number: '4',
          title: '24/7 Gated Security',
          text:
              'Security guards verify your arrival at the estate entrance and escort you to Front Desk reception.',
        ),
        const SizedBox(height: 20),

        // Local Emergency Directory
        const Text(
          'Port Moresby Emergency & Local Directory',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.slateNavy,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      color: AppColors.emeraldGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.category,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _makeCall(item.contactNumber),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.phone_rounded,
                                  size: 13,
                                  color: AppColors.emeraldGreen,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  item.contactNumber,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.emeraldGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShuttleStep({
    required String number,
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.emeraldGreen,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: AppColors.slateNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'resolved':
        return AppColors.emeraldGreen;
      case 'in_progress':
        return AppColors.goldDark;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.slateNavy;
    }
  }
}
