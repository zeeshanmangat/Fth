import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../data/models/accommodation.dart';
import '../../../models/rate_plan_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../../shared/widgets/fth_common_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/fth_image.dart';
import '../confirmation/confirmation_screen.dart';

class BookingScreen extends StatefulWidget {
  final Accommodation accommodation;
  const BookingScreen({super.key, required this.accommodation});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalityController = TextEditingController(text: 'Papua New Guinea');
  final _companyController = TextEditingController();
  final _flightController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  final _requestsController = TextEditingController();

  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  int _adults = 2;
  final int _children = 0;
  int _roomsCount = 1;
  bool _requestShuttle = true;
  bool _acceptedPolicy = false;
  final String _selectedRatePlanCode = 'STANDARD';
  String _selectedPaymentMethod = 'Bank Transfer (BSP — 7014982105)';
  bool _isLoading = false;
  PricingQuotePreview? _liveQuote;
  bool _isLoadingQuote = false;
  String? _quoteError;

  @override
  void initState() {
    super.initState();
    _checkInDate = DateTime.now().add(const Duration(days: 2));
    _checkOutDate = DateTime.now().add(const Duration(days: 5));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = Provider.of<AppStateProvider>(context, listen: false);
      if (state.isGuestLoggedIn) {
        _nameController.text = state.userProfile.name;
        _emailController.text = state.userProfile.email;
        _phoneController.text = state.userProfile.phone;
      }
      _refreshLiveQuote();
    });
  }

  Future<void> _refreshLiveQuote() async {
    if (!mounted) return;
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final selectedPlan = state.ratePlans.firstWhere(
      (p) => p.code == _selectedRatePlanCode,
      orElse: () => state.ratePlans.first,
    );
    setState(() {
      _isLoadingQuote = true;
      _quoteError = null;
    });
    try {
      final quote = await state.fetchLivePricingQuote(
        category: widget.accommodation,
        ratePlan: selectedPlan,
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
        roomsCount: _roomsCount,
      );
      if (!mounted) return;
      setState(() {
        _liveQuote = quote;
        _isLoadingQuote = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quoteError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingQuote = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    _companyController.dispose();
    _flightController.dispose();
    _arrivalTimeController.dispose();
    _requestsController.dispose();
    super.dispose();
  }

  Future<void> _selectDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _checkInDate, end: _checkOutDate),
    );
    if (picked != null) {
      setState(() {
        _checkInDate = picked.start;
        _checkOutDate = picked.end.isAfter(picked.start)
            ? picked.end
            : picked.start.add(const Duration(days: 1));
      });
      _refreshLiveQuote();
    }
  }

  Future<void> _submitBookingRequest() async {
    if (!_acceptedPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept the FTH Cancellation, Payment & House Rules Policy before submitting.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final state = Provider.of<AppStateProvider>(context, listen: false);
      final selectedPlan = state.ratePlans.firstWhere(
        (p) => p.code == _selectedRatePlanCode,
        orElse: () => state.ratePlans.first,
      );

      try {
        final booking = await state.createBookingAsync(
          accommodation: widget.accommodation,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          adults: _adults,
          children: _children,
          guestName: _nameController.text.trim(),
          guestEmail: _emailController.text.trim(),
          guestPhone: _phoneController.text.trim(),
          nationality: _nationalityController.text.trim(),
          companyOrOrganization: _companyController.text.trim(),
          selectedRatePlan: selectedPlan,
          requestAirportShuttle: _requestShuttle,
          flightNumber: _flightController.text.trim(),
          flightArrivalTime: _arrivalTimeController.text.trim(),
          specialRequests: _requestsController.text.trim(),
        );

        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ConfirmationScreen(booking: booking),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final ratePlans = state.ratePlans;
    final quote = _liveQuote;

    final dateFormat = DateFormat('EEE, dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const FthAppBarTitle(title: 'Submit Booking Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Apartment Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FthImage(
                        imagePath: widget.accommodation.mainImage,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.accommodation.estate,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.goldAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.accommodation.title,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Official Rate: K${widget.accommodation.pricePerNight % 1 == 0 ? widget.accommodation.pricePerNight.toInt() : widget.accommodation.pricePerNight.toStringAsFixed(2)} / night (GST-Incl.)',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emeraldGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Step 1: Select Dates & Guests
              _sectionTitle('1. Select Stay Dates & Guests'),
              const SizedBox(height: 10),
              InkWell(
                onTap: _selectDates,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.date_range_rounded,
                        color: AppColors.emeraldGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${dateFormat.format(_checkInDate)} → ${dateFormat.format(_checkOutDate)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${_checkOutDate.difference(_checkInDate).inDays} Nights • Check-in 1:00 PM / Check-out 10:00 AM',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Change',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Guests (Max ${widget.accommodation.maxAdults} Adults, ${widget.accommodation.maxChildren} Children)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _adults > 1
                              ? () => setState(() => _adults--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        Text(
                          '$_adults Adults',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _adults < widget.accommodation.maxAdults.clamp(1, 10)
                              ? () => setState(() => _adults++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Rooms Requested (Max 5 per request)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _roomsCount > 1
                              ? () {
                                  setState(() => _roomsCount--);
                                  _refreshLiveQuote();
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        Text(
                          '$_roomsCount ${_roomsCount == 1 ? 'Room' : 'Rooms'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: _roomsCount < 5
                              ? () {
                                  setState(() => _roomsCount++);
                                  _refreshLiveQuote();
                                }
                              : null,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Step 2: Official Direct Standard Nightly Rate
              _sectionTitle('2. Official Direct Nightly Rate (GST-Inclusive)'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.emeraldGreen,
                    width: 1.4,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ratePlans.isNotEmpty
                                ? ratePlans.first.name
                                : 'Standard Nightly Rate (GST-Inclusive)',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.emeraldGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nightly Only (no discounted long-stay/promo rates). Early check-in free when available; late check-out PGK 200.00 fee. Full payment required prior to confirmation.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Step 3: Guest & Airport Shuttle Details
              _sectionTitle('3. Guest & Complimentary Shuttle Details'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Primary Guest Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(
                  labelText: 'Nationality *',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nationality required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address (For Quote & Invoice)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Valid email required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone / WhatsApp Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company / Organization (Optional)',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                tileColor: AppColors.cardWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                title: const Text(
                  'Request Free Jacksons Airport Shuttle',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Complimentary pickup & drop-off included with every stay',
                  style: TextStyle(fontSize: 11.5),
                ),
                value: _requestShuttle,
                activeThumbColor: AppColors.emeraldGreen,
                onChanged: (v) => setState(() => _requestShuttle = v),
              ),
              if (_requestShuttle) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _flightController,
                        decoration: const InputDecoration(
                          labelText: 'Flight No. (e.g. PX100)',
                          prefixIcon: Icon(Icons.flight_land_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _arrivalTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Arrival Time (ETA)',
                          prefixIcon: Icon(Icons.schedule_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentMethod,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Full Payment Method (Required Prior to Confirmation)',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Bank Transfer (BSP — 7014982105)',
                    child: Text('Bank Transfer (BSP — 7014982105)'),
                  ),
                  DropdownMenuItem(
                    value: 'Kina Bank Transfer (0011906772)',
                    child: Text('Kina Bank Transfer (0011906772)'),
                  ),
                  DropdownMenuItem(
                    value: 'EFTPOS at Reception (Kennedy 16G-02)',
                    child: Text('EFTPOS at Reception (Kennedy 16G-02)'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedPaymentMethod = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _requestsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Special Requests / Notes',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // Step 4: GST-Inclusive Pricing Quote Card
              _sectionTitle('4. Official Pricing Quote Summary'),
              const SizedBox(height: 10),
              if (_isLoadingQuote)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_quoteError != null || quote == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _quoteError ?? 'Unable to load live pricing quote from server.',
                        style: const TextStyle(color: AppColors.error, fontSize: 12.5),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _refreshLiveQuote,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry Live Quote'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.35),
                    ),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'FTH PricingEngineService Quote Contract',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emeraldGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'GST-Inclusive',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slateNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _quoteRow(
                        'Category Base Guide Rate',
                        'K${quote.baseNightlyRatePgk.toStringAsFixed(2)} / night',
                      ),
                      _quoteRow('Selected Rate Plan', quote.ratePlanName),
                      _quoteRow(
                        'Stay Duration (${quote.nights} Nights x $_roomsCount ${_roomsCount == 1 ? 'Room' : 'Rooms'})',
                        'K${quote.grossTotalPgk.toStringAsFixed(2)}',
                      ),
                      if (quote.discountAmountPgk > 0)
                        _quoteRow(
                          'Rate Plan / Promo Discount',
                          '-K${quote.discountAmountPgk.toStringAsFixed(2)}',
                          valueColor: AppColors.success,
                        ),
                      _quoteRow(
                        'PNG 10% GST Included',
                        'K${quote.gstIncludedPgk.toStringAsFixed(2)} (Included in Rate)',
                      ),
                      _quoteRow(
                        'Airport Shuttle Transfer',
                        'Complimentary (K0.00)',
                        valueColor: AppColors.emeraldGreen,
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Provisional Total (PGK)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'K${quote.totalPayablePgk.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emeraldGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        quote.pricingNotice,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              // Important Business Rule Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFFB45309),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.bookingSubmissionNotice,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF92400E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CheckboxListTile(
                value: _acceptedPolicy,
                onChanged: (v) => setState(() => _acceptedPolicy = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.emeraldGreen,
                title: const Text(
                  'I accept FTH Check-In (1:00 PM) / Check-Out (10:00 AM, late check-out PGK 200.00), Full Payment, and Cancellation / No-Show / Non-Transferable Policies.',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Submit Provisional Booking Request',
                icon: Icons.send_rounded,
                isLoading: _isLoading,
                width: double.infinity,
                onPressed: _submitBookingRequest,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
        color: AppColors.slateNavy,
      ),
    );
  }

  Widget _quoteRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
