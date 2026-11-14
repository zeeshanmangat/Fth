import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:family_transit_home/core/constants/colors.dart';
import 'package:family_transit_home/data/models/checkin_record.dart';
import 'package:family_transit_home/providers/app_state_provider.dart';
import 'package:family_transit_home/shared/widgets/fth_common_widgets.dart';
import 'package:family_transit_home/ui/widgets/custom_button.dart';

class OnlineCheckinScreen extends StatefulWidget {
  const OnlineCheckinScreen({super.key});

  @override
  State<OnlineCheckinScreen> createState() => _OnlineCheckinScreenState();
}

class _OnlineCheckinScreenState extends State<OnlineCheckinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalityController = TextEditingController(text: 'Papua New Guinea');
  final _companyController = TextEditingController();
  final _flightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = Provider.of<AppStateProvider>(context, listen: false);
      if (state.isGuestLoggedIn) {
        _nameController.text = state.userProfile.name;
        _emailController.text = state.userProfile.email;
        _phoneController.text = state.userProfile.phone;
      }
      if (state.allAccommodations.isNotEmpty) {
        final firstApt = state.allAccommodations.first;
        setState(() {
          _selectedApartment = '${firstApt.title} (${firstApt.estate})';
        });
      }
      state.fetchIdentityDocumentsAsync();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    _companyController.dispose();
    _flightController.dispose();
    super.dispose();
  }

  String _selectedApartment = '';
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 2));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 5));
  String _selectedIdType = 'PNG National ID';
  String? _selectedIdFileName;
  String? _selectedIdFileBase64;
  String _paymentMethod = 'Bank Transfer Receipt Uploaded';
  bool _isLoading = false;

  final List<String> _idDocumentTypes = const [
    'PNG National ID',
    'Passport',
    "Driver's Licence",
  ];

  final List<String> _paymentOptions = const [
    'Bank Transfer Receipt Uploaded',
    'Kina Bank Transfer Receipt Uploaded',
    'EFTPOS / Cash Paid in Full at Reception (Kennedy 16G-02)',
  ];

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
        _checkOutDate = picked.end;
      });
    }
  }

  Future<void> _submitCheckin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final state = Provider.of<AppStateProvider>(context, listen: false);
      final chosenApartment = _selectedApartment.isNotEmpty
          ? _selectedApartment
          : (state.allAccommodations.isNotEmpty
              ? '${state.allAccommodations.first.title} (${state.allAccommodations.first.estate})'
              : 'Family Transit Home Apartment');
      try {
        await state.submitOnlineCheckinAsync(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          nationality: _nationalityController.text.trim(),
          apartmentType: chosenApartment,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          companyOrAddress: _companyController.text.trim(),
          documentType: _selectedIdType,
          idDocumentName: _selectedIdFileName ?? 'Physical ID Verified at Reception',
          fileBase64: _selectedIdFileBase64,
          fileName: _selectedIdFileName,
          flightNumber: _flightController.text.trim(),
          paymentMethod: _paymentMethod,
        );
        if (!mounted) return;
        setState(() => _isLoading = false);
        final record = OnlineCheckinRecord(
          id: 'CHK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          apartmentType: chosenApartment,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          companyOrAddress: _companyController.text.trim(),
          idDocumentName: _selectedIdFileName ?? 'Physical ID Verified at Reception',
          flightNumber: _flightController.text.trim(),
          paymentMethod: _paymentMethod,
          status: 'Pre-Arrival Submitted',
        );
        _showSuccessDialog(record);
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

  void _showSuccessDialog(OnlineCheckinRecord record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Check-In Verified!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Pass Reference: ${record.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.goldDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Guest: ${record.fullName}\nApartment: ${record.apartmentType}\nCheck-in: ${DateFormat('dd MMM yyyy').format(record.checkInDate)}\nStatus: ${record.status}',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your digital pre-check-in has been recorded. Present this reference code to the reception upon arrival at Kennedy Estate.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Return to Main Menu',
            variant: ButtonVariant.primary,
            width: double.infinity,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final state = Provider.of<AppStateProvider>(context);
    final dynamicApartmentOptions = state.allAccommodations
        .map((a) => '${a.title} (${a.estate})')
        .toSet()
        .toList();
    if (dynamicApartmentOptions.isEmpty && _selectedApartment.isNotEmpty) {
      dynamicApartmentOptions.add(_selectedApartment);
    }
    final activeApartment = dynamicApartmentOptions.contains(_selectedApartment)
        ? _selectedApartment
        : (dynamicApartmentOptions.isNotEmpty
            ? dynamicApartmentOptions.first
            : '');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const FthAppBarTitle(title: 'Online Check-In / Check-Out'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryNavy.withValues(alpha: 0.15),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.badge_rounded,
                      color: AppColors.goldDark,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Website Pre-Arrival Verification',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Save time upon arrival in Port Moresby by completing digital ID registration in advance.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Guest Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone / WhatsApp Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter phone' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(
                  labelText: 'Nationality *',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter nationality' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company / Organization / Residential Address',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Stay Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: activeApartment.isEmpty ? null : activeApartment,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Apartment Category (Synced from Backend)',
                  prefixIcon: Icon(Icons.apartment_rounded),
                ),
                items: dynamicApartmentOptions.map((opt) {
                  return DropdownMenuItem(
                    value: opt,
                    child: Text(opt, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedApartment = v);
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDates,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.date_range_rounded,
                        color: AppColors.primaryNavy,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${dateFormat.format(_checkInDate)} - ${dateFormat.format(_checkOutDate)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _flightController,
                decoration: const InputDecoration(
                  labelText: 'Flight Number (e.g. PX100 / CG850 for Shuttle)',
                  prefixIcon: Icon(Icons.flight_outlined),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ID Verification, Vehicle Pass & Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedIdType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Identity Document Type',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: _idDocumentTypes.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedIdType = v);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(
                  _selectedIdFileName ??
                      'Upload Photo ID (JPG, PNG, PDF — Max 5MB)',
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
                  if (bytes.isEmpty || bytes.lengthInBytes > 5 * 1024 * 1024) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a non-empty file up to 5 MB.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _selectedIdFileName = file.name;
                    _selectedIdFileBase64 = base64Encode(bytes);
                  });
                },
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      color: AppColors.goldDark,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ID files are stored on private storage for authorized Front Desk / Supervisor review only. Guest Vehicle Passes for registered cars are issued at Kennedy Estate 24/7 guardhouse & Reception (Unit 16G-02).',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                items: _paymentOptions.map((opt) {
                  return DropdownMenuItem(
                    value: opt,
                    child: Text(opt, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: 'Submit Online Check-In',
                variant: ButtonVariant.gold,
                isLoading: _isLoading,
                width: double.infinity,
                onPressed: _submitCheckin,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
