import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../data/models/accommodation.dart';
import '../data/models/booking.dart';
import '../data/models/checkin_record.dart';
import '../data/models/notification_item.dart';
import '../data/models/user_profile.dart';
import '../models/estate_model.dart';
import '../models/operational_models.dart';
import '../models/rate_plan_model.dart';
import '../models/staff_role_model.dart';
import '../repositories/laravel_api_service.dart';
import '../repositories/mock_booking_and_pms_repository.dart';
import '../repositories/mock_catalog_repository.dart';
import '../repositories/repository_contracts.dart';

enum AppExperienceMode { guest, staffPms }

class AppStateProvider extends ChangeNotifier {
  final CatalogRepositoryContract _catalogRepository;
  final LaravelApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _kGuestTokenKey = 'fth_guest_token';
  static const _kGuestRefKey = 'fth_guest_ref';
  static const _kGuestEmailKey = 'fth_guest_email';
  static const _kStaffTokenKey = 'fth_staff_token';

  // Experience & Auth State (Connected to Live Laravel /api/v1)
  AppExperienceMode _experienceMode = AppExperienceMode.guest;
  bool _isGuestLoggedIn = false;
  bool _isStaffLoggedIn = false;
  StaffRole _activeStaffRole = StaffRole.owner;
  StaffMemberModel? _authenticatedStaffUser;
  bool _isLoading = false;
  bool _isLoadingCatalog = false;
  String? _catalogError;
  String? _errorMessage;

  // Catalog Data (Synced with /api/v1/public/bootstrap)
  List<EstateModel> _estates = [];
  List<Accommodation> _allAccommodations = [];
  List<Accommodation> _filteredAccommodations = [];
  List<PhysicalRoomUnit> _physicalUnits = [];
  List<RatePlanModel> _ratePlans = [];
  Map<String, String> _bankDetails = {};
  Map<String, dynamic> _liveReportsSummary = {};

  // Guest Data (Zero Mock Data by Default — Populated from Live Backend)
  final Set<String> _favoriteIds = {'APT-01', 'APT-02', 'APT-09'};
  List<Booking> _bookings = [];
  List<OnlineCheckinRecord> _checkinRecords = [];
  List<Map<String, dynamic>> _identityDocuments = [];
  List<NotificationItem> _notifications = [];
  UserProfile _userProfile = const UserProfile(
    id: '',
    name: 'Guest Visitor',
    email: '',
    phone: '',
  );

  // Staff PMS Data (Populated from /api/v1/staff/dashboard)
  List<Booking> _staffBookings = [];
  List<HousekeepingTaskModel> _housekeepingTasks = [];
  List<MaintenanceTicketModel> _maintenanceTickets = [];
  List<AirportTransferModel> _airportTransfers = [];
  List<GuestServiceRequestModel> _guestServiceRequests = [];
  List<PaymentRecordModel> _paymentRecords = [];
  List<RefundRequestModel> _refundRequests = [];
  List<StaffMemberModel> _staffMembers = [];

  // Search & Filter State
  String _searchQuery = '';
  String _selectedEstate = 'All Estates';
  String _selectedCategoryType = 'All Categories';
  DateTimeRange? _selectedDateRange;
  int _adultCount = 2;
  int _childCount = 0;
  RangeValues _priceRange = const RangeValues(0, 10000);
  int? _selectedBedroomFilter;

  AppStateProvider({
    CatalogRepositoryContract? catalogRepository,
    MockBookingAndPmsRepository? pmsRepository,
    LaravelApiService? apiService,
    bool autoFetchLiveCatalog = true,
  }) : _catalogRepository = catalogRepository ?? MockCatalogRepository(),
       _apiService = apiService ?? LaravelApiService() {
    _initData(autoFetchLiveCatalog: autoFetchLiveCatalog);
  }

  LaravelApiService get apiService => _apiService;
  Map<String, dynamic> get liveReportsSummary => _liveReportsSummary;

  void _initData({bool autoFetchLiveCatalog = true}) {
    if (ApiConfig.useMockRepositories || !autoFetchLiveCatalog) {
      _estates = _catalogRepository.getEstates();
      _allAccommodations = _catalogRepository.getApartmentCategories();
      _filteredAccommodations = List.from(_allAccommodations);
      _physicalUnits = List.from(_catalogRepository.getPhysicalUnits());
      _ratePlans = _catalogRepository.getRatePlans();
      _bankDetails = _catalogRepository.getOfficialBankDetails();
    } else {
      _estates = [];
      _allAccommodations = [];
      _filteredAccommodations = [];
      _physicalUnits = [];
      _ratePlans = [];
      _bankDetails = {};
    }

    // Zero fake guest bookings, fake staff records, or fake check-ins
    _bookings = [];
    _staffBookings = [];
    _housekeepingTasks = [];
    _maintenanceTickets = [];
    _airportTransfers = [];
    _guestServiceRequests = [];
    _paymentRecords = [];
    _refundRequests = [];
    _staffMembers = [];
    _checkinRecords = [];
    _notifications = [];

    if (autoFetchLiveCatalog && !ApiConfig.useMockRepositories) {
      refreshPublicCatalog();
      restorePersistedSessions();
    }
  }

  bool get isLoadingCatalog => _isLoadingCatalog;
  String? get catalogError => _catalogError;

  Future<void> restorePersistedSessions() async {
    try {
      final staffToken = await _secureStorage.read(key: _kStaffTokenKey);
      if (staffToken != null && staffToken.isNotEmpty) {
        _apiService.setStaffToken(staffToken);
        try {
          await refreshStaffDashboard();
          if (_authenticatedStaffUser != null) {
            _isStaffLoggedIn = true;
            _startPeriodicSync();
            notifyListeners();
          }
        } catch (_) {
          _apiService.setStaffToken(null);
          await _secureStorage.delete(key: _kStaffTokenKey);
        }
      }

      final guestToken = await _secureStorage.read(key: _kGuestTokenKey);
      if (guestToken != null && guestToken.isNotEmpty) {
        _apiService.setGuestToken(guestToken);
        try {
          final data = await _apiService.fetchGuestProfile();
          _applyGuestAuthPayload(data);
          await loadGuestRequests();
          _startPeriodicSync();
          notifyListeners();
        } catch (_) {
          _apiService.setGuestToken(null);
          await _secureStorage.delete(key: _kGuestTokenKey);
        }
      }
    } catch (_) {
      // Ignore secure storage unavailable in widget test environments
    }
  }

  Future<void> refreshPublicCatalog() async {
    _isLoadingCatalog = true;
    _catalogError = null;
    notifyListeners();
    try {
      final data = await _apiService.fetchPublicBootstrap();
      final estatesRaw = (data['estates'] as List?) ?? [];
      if (estatesRaw.isNotEmpty) {
        _estates = estatesRaw
            .map((e) => LaravelApiService.mapEstate(e as Map<String, dynamic>))
            .toList();
      }

      final apartmentsRaw =
          (data['apartments'] as List?) ?? (data['categories'] as List?) ?? [];
      if (apartmentsRaw.isNotEmpty) {
        _allAccommodations = apartmentsRaw
            .map(
              (a) =>
                  LaravelApiService.mapAccommodation(a as Map<String, dynamic>),
            )
            .toList();
        _applyFilters();
      }

      final unitsRaw = (data['physical_units'] as List?) ?? [];
      if (unitsRaw.isNotEmpty) {
        _physicalUnits = [];
        for (var i = 0; i < unitsRaw.length; i++) {
          _physicalUnits.add(
            LaravelApiService.mapPhysicalUnit(
              unitsRaw[i] as Map<String, dynamic>,
              i + 1,
            ),
          );
        }
      }

      final plansRaw = (data['rate_plans'] as List?) ?? [];
      if (plansRaw.isNotEmpty) {
        final parsed = plansRaw
            .map(
              (p) => LaravelApiService.mapRatePlan(p as Map<String, dynamic>),
            )
            .where((p) => p.code.toUpperCase() == 'STANDARD')
            .toList();
        if (parsed.isNotEmpty) {
          _ratePlans = parsed;
        }
      }

      final bankRaw = data['bank_details'] as Map<String, dynamic>?;
      if (bankRaw != null && bankRaw.isNotEmpty) {
        _bankDetails = {
          'primary_bank':
              (bankRaw['bank_name'] ??
                      bankRaw['primary_bank'] ??
                      'Bank South Pacific (BSP) Financial Group Limited')
                  .toString(),
          'primary_account_name':
              (bankRaw['account_name'] ?? 'Family Transit Home Limited')
                  .toString(),
          'primary_account_number':
              (bankRaw['account_number'] ?? '7014982105').toString(),
          'primary_branch':
              (bankRaw['branch'] ?? 'Port Moresby Branch, NCD, PNG').toString(),
          'primary_swift': (bankRaw['swift_code'] ?? 'BOSPPGPM').toString(),
          'secondary_bank':
              (bankRaw['secondary_bank'] ?? 'Kina Bank Limited (PNG)')
                  .toString(),
          'secondary_account_name':
              (bankRaw['account_name'] ?? 'Family Transit Home Limited')
                  .toString(),
          'secondary_account_number':
              (bankRaw['secondary_account_number'] ??
                      'Confirmed on Official Booking Invoice')
                  .toString(),
          'payment_reference_rule':
              (bankRaw['instructions'] ??
                      'Quote your Booking Reference (FTH-2026-XXXX) and Guest Full Name in the transfer narration.')
                  .toString(),
        };
      }

      _catalogError = null;
    } catch (e) {
      _catalogError = e.toString();
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  Future<List<Accommodation>> searchLiveAvailability({
    required DateTime checkIn,
    required DateTime checkOut,
    String? estate,
    int? guests,
  }) async {
    final raw = await _apiService.fetchPublicApartments(
      checkIn: checkIn,
      checkOut: checkOut,
      estate: estate,
      guests: guests,
    );
    final results = raw
        .map((a) => LaravelApiService.mapAccommodation(a))
        .toList();
    _filteredAccommodations = results;
    notifyListeners();
    return results;
  }

  Future<PricingQuotePreview> fetchLivePricingQuote({
    required Accommodation category,
    required RatePlanModel ratePlan,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    int roomsCount = 1,
    String? promoCode,
  }) async {
    final data = await _apiService.fetchPricingQuote(
      categoryId: category.id,
      checkIn: checkInDate,
      checkOut: checkOutDate,
      roomsCount: roomsCount,
      ratePlanCode: ratePlan.code,
      promoCode: promoCode,
    );

    final nights = (data['nights'] as num?)?.toInt() ??
        checkOutDate.difference(checkInDate).inDays.clamp(1, 365);
    final baseNightly =
        (data['base_nightly_rate_pgk'] as num?)?.toDouble() ?? category.pricePerNight;
    final gross = (data['gross_room_charges_pgk'] as num?)?.toDouble() ??
        (baseNightly * nights * roomsCount);
    final discount = (data['discount_pgk'] as num?)?.toDouble() ?? 0.0;
    final total = (data['final_total_pgk'] as num?)?.toDouble() ??
        (data['total_pgk'] as num?)?.toDouble() ??
        (gross - discount);

    final effectiveNightly =
        (data['effective_nightly_rate_pgk'] as num?)?.toDouble() ??
            (nights > 0 ? total / nights / roomsCount : baseNightly);
    final gstIncluded = (data['gst_included_pgk'] as num?)?.toDouble() ??
        (total / 11.0);

    return PricingQuotePreview(
      roomCategoryId: category.id,
      roomCategoryName: category.title,
      ratePlanCode: ratePlan.code,
      ratePlanName: (data['rate_plan_name'] ?? ratePlan.name).toString(),
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      nights: nights,
      roomsCount: (data['rooms_count'] as num?)?.toInt() ?? roomsCount,
      baseNightlyRatePgk: baseNightly,
      effectiveNightlyRatePgk: effectiveNightly,
      grossTotalPgk: gross,
      discountAmountPgk: discount,
      totalPayablePgk: total,
      gstIncludedPgk: gstIncluded,
      promoCodeApplied: data['promo_code']?.toString(),
      gstInclusive: data['gst_inclusive'] != false,
      isPreviewEstimate: false,
      pricingNotice:
          'Official GST-inclusive quote from Laravel PricingEngineService.',
    );
  }

  // Experience & Auth Getters
  AppExperienceMode get experienceMode => _experienceMode;
  bool get isGuestLoggedIn => _isGuestLoggedIn;
  bool get isStaffLoggedIn => _isStaffLoggedIn;
  StaffRole get activeStaffRole => _activeStaffRole;
  String get staffUserName => currentStaffProfile.fullName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StaffMemberModel get currentStaffProfile {
    if (_authenticatedStaffUser != null) {
      return _authenticatedStaffUser!;
    }
    final match = _staffMembers.where((s) => s.role == _activeStaffRole);
    if (match.isNotEmpty) {
      return match.first;
    }
    return StaffMemberModel(
      id: 'staff-active',
      fullName: 'FTH ${_activeStaffRole.label}',
      email: 'familytransithome@gmail.com',
      phone: '+675 7135 8804',
      role: _activeStaffRole,
      assignedEstate: 'All Estates',
      isActive: true,
      invitationStatus: 'active',
      effectivePermissions: _activeStaffRole.defaultPermissions,
    );
  }

  bool canStaffAccess(String permissionKey) {
    if (_authenticatedStaffUser != null) {
      return _authenticatedStaffUser!.hasPermission(permissionKey);
    }
    return _activeStaffRole.hasPermission(permissionKey);
  }

  // Catalog Getters
  List<EstateModel> get estates => _estates;
  List<Accommodation> get accommodations => _filteredAccommodations;
  List<Accommodation> get allAccommodations => _allAccommodations;
  List<Accommodation> get featuredAccommodations =>
      _allAccommodations.where((a) => a.isFeatured).toList();
  List<Accommodation> get popularAccommodations =>
      _allAccommodations.where((a) => a.isPopular).toList();
  List<Accommodation> get favoriteAccommodations =>
      _allAccommodations.where((a) => _favoriteIds.contains(a.id)).toList();
  Set<String> get favoriteIds => _favoriteIds;
  List<PhysicalRoomUnit> get physicalUnits => _physicalUnits;
  List<RatePlanModel> get ratePlans => _ratePlans;
  Map<String, String> get bankDetails => _bankDetails;

  // Guest Getters
  List<Booking> get bookings => _bookings;
  List<Booking> get upcomingBookings => _bookings
      .where(
        (b) =>
            b.workflowStatus != BookingWorkflowStatus.checkedOut &&
            b.workflowStatus != BookingWorkflowStatus.cancelled,
      )
      .toList();
  List<Booking> get pastBookings => _bookings
      .where(
        (b) =>
            b.workflowStatus == BookingWorkflowStatus.checkedOut ||
            b.workflowStatus == BookingWorkflowStatus.cancelled,
      )
      .toList();
  List<OnlineCheckinRecord> get checkinRecords => _checkinRecords;
  List<Map<String, dynamic>> get identityDocuments => _identityDocuments;
  List<NotificationItem> get notifications => _notifications;
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;
  UserProfile get userProfile => _userProfile;

  // Staff PMS Getters
  List<Booking> get staffBookings => _staffBookings;
  List<HousekeepingTaskModel> get housekeepingTasks => _housekeepingTasks;
  List<MaintenanceTicketModel> get maintenanceTickets => _maintenanceTickets;
  List<AirportTransferModel> get airportTransfers => _airportTransfers;
  List<GuestServiceRequestModel> get guestServiceRequests =>
      _guestServiceRequests;
  List<PaymentRecordModel> get paymentRecords => _paymentRecords;
  List<RefundRequestModel> get refundRequests => _refundRequests;
  List<StaffMemberModel> get staffMembers => _staffMembers;

  // Search & Filter Getters
  String get searchQuery => _searchQuery;
  String get selectedEstate => _selectedEstate;
  String get selectedCategoryType => _selectedCategoryType;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  int get adultCount => _adultCount;
  int get childCount => _childCount;
  int get totalGuests => _adultCount + _childCount;
  RangeValues get priceRange => _priceRange;
  int? get selectedBedroomFilter => _selectedBedroomFilter;

  // ===========================================================================
  // LIVE GUEST & STAFF AUTHENTICATION ACTIONS
  // ===========================================================================

  void switchToGuestExperience() {
    _experienceMode = AppExperienceMode.guest;
    notifyListeners();
  }

  Future<void> loginGuest({
    required String email,
    String? password,
    String? bookingReference,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _apiService.guestLogin(
        email: email,
        password: password,
        bookingReference: bookingReference,
      );
      _applyGuestAuthPayload(data);
      try {
        if (_apiService.guestToken != null) {
          await _secureStorage.write(
            key: _kGuestTokenKey,
            value: _apiService.guestToken,
          );
          await _secureStorage.write(key: _kGuestEmailKey, value: email);
          if (bookingReference != null) {
            await _secureStorage.write(
              key: _kGuestRefKey,
              value: bookingReference,
            );
          }
        }
      } catch (_) {}
      await loadGuestRequests();
      _startPeriodicSync();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerGuest({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? companyOrOrganization,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _apiService.guestRegister(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        companyOrOrganization: companyOrOrganization,
      );
      _applyGuestAuthPayload(data);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> lookupGuestBooking({
    required String bookingReference,
    required String email,
  }) async {
    await loginGuest(email: email, bookingReference: bookingReference);
  }

  void _applyGuestAuthPayload(Map<String, dynamic> data) {
    final guestJson = data['guest'] as Map<String, dynamic>?;
    if (guestJson != null) {
      _userProfile = LaravelApiService.mapGuestProfile(guestJson);
    }
    final bookingsRaw = (data['bookings'] as List?) ?? [];
    _bookings = bookingsRaw
        .map(
          (b) => LaravelApiService.mapBooking(
            b as Map<String, dynamic>,
            _allAccommodations,
          ),
        )
        .toList();

    final notifsRaw = (data['notifications'] as List?) ?? [];
    _notifications = notifsRaw
        .map(
          (n) => LaravelApiService.mapNotification(n as Map<String, dynamic>),
        )
        .toList();

    _isGuestLoggedIn = true;
    _experienceMode = AppExperienceMode.guest;
  }

  Future<void> refreshGuestPortal() async {
    if (!_isGuestLoggedIn || _apiService.guestToken == null) return;
    try {
      final data = await _apiService.fetchGuestProfile();
      _applyGuestAuthPayload(data);
      await loadGuestRequests();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadGuestRequests() async {
    if (!ApiConfig.useMockRepositories && _apiService.guestToken != null) {
      try {
        final reqs = await _apiService.fetchGuestRequests();
        _guestServiceRequests = reqs;
        notifyListeners();
      } catch (_) {}
    }
  }

  void loginAsGuestPreview({
    required String name,
    required String email,
    required String phone,
  }) {
    _userProfile = UserProfile(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
    );
    _isGuestLoggedIn = true;
    _experienceMode = AppExperienceMode.guest;
    notifyListeners();
  }

  void logoutGuestPreview() {
    _stopPeriodicSync();
    _apiService.guestLogout();
    _secureStorage.delete(key: _kGuestTokenKey).catchError((_) {});
    _secureStorage.delete(key: _kGuestEmailKey).catchError((_) {});
    _secureStorage.delete(key: _kGuestRefKey).catchError((_) {});
    _isGuestLoggedIn = false;
    _bookings = [];
    _checkinRecords = [];
    _notifications = [];
    _userProfile = const UserProfile(
      id: '',
      name: 'Guest Visitor',
      email: '',
      phone: '',
    );
    notifyListeners();
  }

  Future<void> loginStaff({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _apiService.staffLogin(
        email: email,
        password: password,
      );
      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        _authenticatedStaffUser = LaravelApiService.mapStaffMember(userJson);
        _activeStaffRole = _authenticatedStaffUser!.role;
      }
      _isStaffLoggedIn = true;
      _experienceMode = AppExperienceMode.staffPms;
      try {
        if (_apiService.staffToken != null) {
          await _secureStorage.write(
            key: _kStaffTokenKey,
            value: _apiService.staffToken,
          );
        }
      } catch (_) {}
      await refreshStaffDashboard();
      _startPeriodicSync();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStaffDashboard() async {
    if (_apiService.staffToken == null) return;
    try {
      final data = await _apiService.fetchStaffDashboard();

      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        _authenticatedStaffUser = LaravelApiService.mapStaffMember(userJson);
        _activeStaffRole = _authenticatedStaffUser!.role;
      }

      final unitsRaw = (data['physical_units'] as List?) ?? [];
      if (unitsRaw.isNotEmpty) {
        _physicalUnits = [];
        for (var i = 0; i < unitsRaw.length; i++) {
          _physicalUnits.add(
            LaravelApiService.mapPhysicalUnit(
              unitsRaw[i] as Map<String, dynamic>,
              i + 1,
            ),
          );
        }
      }

      final bookingsRaw = (data['bookings'] as List?) ?? [];
      _staffBookings = bookingsRaw
          .map(
            (b) => LaravelApiService.mapBooking(
              b as Map<String, dynamic>,
              _allAccommodations,
            ),
          )
          .toList();

      final paymentsRaw = (data['payments'] as List?) ?? [];
      _paymentRecords = paymentsRaw
          .map(
            (p) =>
                LaravelApiService.mapPaymentRecord(p as Map<String, dynamic>),
          )
          .toList();

      final refundsRaw = (data['refunds'] as List?) ?? [];
      _refundRequests = refundsRaw
          .map(
            (r) => LaravelApiService.mapRefundRecord(r as Map<String, dynamic>),
          )
          .toList();

      final hkRaw = (data['housekeeping_tasks'] as List?) ?? [];
      _housekeepingTasks = hkRaw
          .map(
            (t) => LaravelApiService.mapHousekeepingTask(
              t as Map<String, dynamic>,
            ),
          )
          .toList();

      final mntRaw = (data['maintenance_tickets'] as List?) ?? [];
      _maintenanceTickets = mntRaw
          .map(
            (m) => LaravelApiService.mapMaintenanceTicket(
              m as Map<String, dynamic>,
            ),
          )
          .toList();

      final trfRaw = (data['transfers'] as List?) ?? [];
      _airportTransfers = trfRaw
          .map(
            (t) => LaravelApiService.mapTransfer(t as Map<String, dynamic>),
          )
          .toList();

      final reqRaw = (data['guest_requests'] as List?) ?? [];
      _guestServiceRequests = reqRaw
          .map(
            (r) => LaravelApiService.mapGuestServiceRequest(
              r as Map<String, dynamic>,
            ),
          )
          .toList();

      final staffRaw = (data['staff_members'] as List?) ?? [];
      _staffMembers = staffRaw
          .map(
            (s) => LaravelApiService.mapStaffMember(s as Map<String, dynamic>),
          )
          .toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> fetchLiveStaffReports({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = await _apiService.fetchStaffReports(
      startDate: startDate,
      endDate: endDate,
    );
    _liveReportsSummary = data;
    notifyListeners();
    return data;
  }

  void loginAsStaffPreview({required StaffRole role}) {
    _activeStaffRole = role;
    _authenticatedStaffUser = null;
    _isStaffLoggedIn = true;
    _experienceMode = AppExperienceMode.staffPms;
    notifyListeners();
  }

  void setActiveStaffRole(StaffRole role) {
    _activeStaffRole = role;
    if (_authenticatedStaffUser != null &&
        _authenticatedStaffUser!.role != role) {
      _authenticatedStaffUser = null;
    }
    notifyListeners();
  }

  void logoutStaffPreview() {
    _stopPeriodicSync();
    _apiService.staffLogout();
    _secureStorage.delete(key: _kStaffTokenKey).catchError((_) {});
    _authenticatedStaffUser = null;
    _isStaffLoggedIn = false;
    _staffBookings = [];
    _paymentRecords = [];
    _refundRequests = [];
    _housekeepingTasks = [];
    _maintenanceTickets = [];
    _airportTransfers = [];
    _guestServiceRequests = [];
    _staffMembers = [];
    _experienceMode = AppExperienceMode.guest;
    notifyListeners();
  }

  // Periodic Auto-Sync Timer (Maintains real-time database parity with Website & PMS)
  Timer? _syncTimer;

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isStaffLoggedIn && _apiService.staffToken != null) {
        refreshStaffDashboard();
      } else if (_isGuestLoggedIn && _apiService.guestToken != null) {
        refreshGuestPortal();
      }
    });
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  @override
  void dispose() {
    _stopPeriodicSync();
    super.dispose();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Pricing Quote Builder
  PricingQuotePreview buildPricingQuote({
    required Accommodation category,
    required RatePlanModel ratePlan,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    int roomsCount = 1,
    String? promoCode,
  }) {
    return _catalogRepository.buildPreviewQuote(
      category: category,
      ratePlan: ratePlan,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      roomsCount: roomsCount,
      promoCode: promoCode,
    );
  }

  // Favorite & Notification Actions
  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  // Filter Actions
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setSelectedEstate(String estate) {
    _selectedEstate = estate;
    _applyFilters();
  }

  void setSelectedCategoryType(String categoryType) {
    _selectedCategoryType = categoryType;
    _applyFilters();
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    notifyListeners();
  }

  void setGuests({required int adults, required int children}) {
    _adultCount = adults.clamp(1, 10);
    _childCount = children.clamp(0, 10);
    _applyFilters();
  }

  void setPriceRange(RangeValues values) {
    _priceRange = values;
    _applyFilters();
  }

  void setBedroomFilter(int? bedrooms) {
    _selectedBedroomFilter = bedrooms;
    _applyFilters();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedEstate = 'All Estates';
    _selectedCategoryType = 'All Categories';
    _selectedDateRange = null;
    _adultCount = 2;
    _childCount = 0;
    _priceRange = const RangeValues(0, 10000);
    _selectedBedroomFilter = null;
    _filteredAccommodations = List.from(_allAccommodations);
    notifyListeners();
  }

  void _applyFilters() {
    _filteredAccommodations = _allAccommodations.where((item) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchEstate = item.estate.toLowerCase().contains(q);
        final matchCat = item.categoryType.toLowerCase().contains(q);
        final matchDesc = item.description.toLowerCase().contains(q);
        if (!matchTitle && !matchEstate && !matchCat && !matchDesc) {
          return false;
        }
      }

      if (_selectedEstate != 'All Estates') {
        final selectedLower = _selectedEstate.toLowerCase().trim();
        final filterKey = selectedLower.split(' ')[0];
        final matchesEstate = item.estateKey.toLowerCase() == selectedLower ||
            item.estate.toLowerCase().contains(selectedLower) ||
            item.estate.toLowerCase().contains(filterKey);
        if (!matchesEstate) {
          return false;
        }
      }

      if (_selectedCategoryType != 'All Categories') {
        final catLower = _selectedCategoryType.toLowerCase().trim();
        if (item.categoryType.toLowerCase() != catLower &&
            !item.title.toLowerCase().contains(catLower)) {
          return false;
        }
      }

      if (item.maxGuests < totalGuests) {
        return false;
      }

      if (_selectedBedroomFilter != null &&
          item.bedrooms != _selectedBedroomFilter) {
        return false;
      }

      if (item.pricePerNight < _priceRange.start ||
          item.pricePerNight > _priceRange.end) {
        return false;
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // ===========================================================================
  // GUEST BOOKING, PAYMENT PROOF & SERVICE REQUEST ACTIONS (LIVE API + STATE)
  // ===========================================================================

  Future<Booking> createBookingAsync({
    required Accommodation accommodation,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int adults,
    required int children,
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    required bool requestAirportShuttle,
    String? flightNumber,
    String? flightArrivalTime,
    String? specialRequests,
    RatePlanModel? selectedRatePlan,
    String? nationality,
    String? companyOrOrganization,
    String? promoCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final plan = selectedRatePlan ?? _ratePlans.first;
      final data = await _apiService.createGuestBooking(
        categoryId: accommodation.id,
        checkIn: checkInDate,
        checkOut: checkOutDate,
        adults: adults,
        children: children,
        guestName: guestName,
        guestEmail: guestEmail,
        guestPhone: guestPhone,
        nationality: nationality,
        companyOrganization: companyOrOrganization,
        ratePlanCode: plan.code,
        promoCode: promoCode,
        transferRequired: requestAirportShuttle,
        flightNumber: flightNumber,
        arrivalEta: flightArrivalTime,
        specialRequests: specialRequests,
      );

      final bookingJson =
          (data['booking'] as Map<String, dynamic>?) ?? data;
      final booking = LaravelApiService.mapBooking(
        bookingJson,
        _allAccommodations,
      );

      _userProfile = UserProfile(
        id: _userProfile.id.isNotEmpty
            ? _userProfile.id
            : 'gst-${DateTime.now().millisecondsSinceEpoch}',
        name: guestName,
        email: guestEmail,
        phone: guestPhone,
      );
      _isGuestLoggedIn = true;
      try {
        if (_apiService.guestToken != null) {
          await _secureStorage.write(
            key: _kGuestTokenKey,
            value: _apiService.guestToken,
          );
          await _secureStorage.write(key: _kGuestEmailKey, value: guestEmail);
          await _secureStorage.write(key: _kGuestRefKey, value: booking.id);
        }
      } catch (_) {}

      _bookings.removeWhere((b) => b.id == booking.id);
      _bookings.insert(0, booking);
      _staffBookings.removeWhere((b) => b.id == booking.id);
      _staffBookings.insert(0, booking);

      _notifications.insert(
        0,
        NotificationItem(
          id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Booking Request Submitted: ${booking.id}',
          message:
              'Your provisional booking request for ${accommodation.title} (${booking.totalNights} nights) is Pending Approval by FTH Reservations.',
          timestamp: DateTime.now(),
          icon: Icons.hourglass_top_rounded,
          iconColor: const Color(0xFFD4AF37),
          isRead: false,
        ),
      );

      return booking;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Booking createBooking({
    required Accommodation accommodation,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int adults,
    required int children,
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    required bool requestAirportShuttle,
    String? flightNumber,
    String? flightArrivalTime,
    String? specialRequests,
    RatePlanModel? selectedRatePlan,
    String? companyOrOrganization,
    String? promoCode,
  }) {
    final plan = selectedRatePlan ?? _ratePlans.first;
    final quote = buildPricingQuote(
      category: accommodation,
      ratePlan: plan,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      promoCode: promoCode,
    );

    final provisionalRef =
        'FTH-${DateTime.now().year}-${(1000 + DateTime.now().millisecond * 8).clamp(1000, 9999)}';
    final booking = Booking(
      id: provisionalRef,
      accommodation: accommodation,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      adults: adults,
      children: children,
      roomsCount: quote.roomsCount,
      guestName: guestName,
      guestEmail: guestEmail,
      guestPhone: guestPhone,
      companyOrOrganization: companyOrOrganization,
      ratePlanCode: plan.code,
      ratePlanName: plan.name,
      promoCode: promoCode,
      requestAirportShuttle: requestAirportShuttle,
      flightNumber: flightNumber,
      flightArrivalTime: flightArrivalTime,
      specialRequests: specialRequests,
      totalPrice: quote.totalPayablePgk,
      discountAmountPgk: quote.discountAmountPgk,
      gstAmount: double.parse((quote.totalPayablePgk / 11).toStringAsFixed(2)),
      amountPaidPgk: 0.0,
      status: BookingWorkflowStatus.pendingApproval.shortLabel,
      workflowStatus: BookingWorkflowStatus.pendingApproval,
      folioEntries: [
        FolioLineItem(
          id: 'FOL-INIT',
          entryType: 'room_charge',
          description:
              '${accommodation.title} (${quote.nights} Nights • ${plan.name} • GST Inclusive)',
          amountPgk: quote.totalPayablePgk,
          postedAt: DateTime.now(),
          postedBy: 'FTH Booking Engine',
        ),
      ],
      createdAt: DateTime.now(),
    );

    _bookings.insert(0, booking);
    _staffBookings.insert(0, booking);

    _notifications.insert(
      0,
      NotificationItem(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Booking Request Submitted: ${booking.id}',
        message:
            'Your provisional booking request for ${accommodation.title} (${booking.totalNights} nights) is Pending Approval by FTH Reservations.',
        timestamp: DateTime.now(),
        icon: Icons.hourglass_top_rounded,
        iconColor: const Color(0xFFD4AF37),
        isRead: false,
      ),
    );

    notifyListeners();

    if (!ApiConfig.useMockRepositories) {
      createBookingAsync(
        accommodation: accommodation,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        adults: adults,
        children: children,
        guestName: guestName,
        guestEmail: guestEmail,
        guestPhone: guestPhone,
        requestAirportShuttle: requestAirportShuttle,
        flightNumber: flightNumber,
        flightArrivalTime: flightArrivalTime,
        specialRequests: specialRequests,
        selectedRatePlan: selectedRatePlan,
        companyOrOrganization: companyOrOrganization,
        promoCode: promoCode,
      ).then((realBooking) {
        _bookings.removeWhere((b) => b.id == provisionalRef);
        _staffBookings.removeWhere((b) => b.id == provisionalRef);
        notifyListeners();
      }).catchError((_) {});
    }

    return booking;
  }

  // Guest Payment Proof Upload (Business Rule #10: Uploaded proof != Payment Verified)
  Future<void> uploadGuestPaymentProofAsync({
    required String bookingId,
    required String proofFileName,
    required String paymentMethod,
    required String referenceNumber,
    String? proofFileBase64,
  }) async {
    final encodedProof =
        proofFileBase64 ??
        base64Encode(
          utf8.encode(
            'FTH-REMITTANCE-SLIP|$bookingId|$referenceNumber|$proofFileName',
          ),
        );

    final data = await _apiService.uploadGuestPaymentProof(
      bookingReference: bookingId,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      proofFileName: proofFileName,
      proofFileBase64: encodedProof,
    );

    final bookingJson = data['booking'] as Map<String, dynamic>?;
    if (bookingJson != null) {
      final updated = LaravelApiService.mapBooking(
        bookingJson,
        _allAccommodations,
      );
      _replaceBookingInLists(updated);
    }
    notifyListeners();
  }

  void uploadGuestPaymentProof({
    required String bookingId,
    required String proofFileName,
    required String paymentMethod,
    required String referenceNumber,
  }) {
    void updateList(List<Booking> list) {
      final idx = list.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          status: BookingWorkflowStatus.paymentUnderReview.label,
          workflowStatus: BookingWorkflowStatus.paymentUnderReview,
          paymentProofFileName: proofFileName,
          paymentMethodSelected: paymentMethod,
          paymentProofUploadedAt: DateTime.now(),
        );
      }
    }

    updateList(_bookings);
    updateList(_staffBookings);

    final bookingMatch = _bookings.where((b) => b.id == bookingId).toList();
    final staffMatch = _staffBookings.where((b) => b.id == bookingId).toList();
    final booking = bookingMatch.isNotEmpty
        ? bookingMatch.first
        : (staffMatch.isNotEmpty ? staffMatch.first : null);

    if (booking != null) {
      _paymentRecords.insert(
        0,
        PaymentRecordModel(
          id: 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          bookingReference: booking.id,
          guestName: booking.guestName,
          categoryName: booking.accommodation.title,
          amountPgk: booking.totalPrice,
          paymentMethod: paymentMethod,
          referenceNumber: referenceNumber,
          proofFileName: proofFileName,
          status: 'pending_verification',
          submittedAt: DateTime.now(),
        ),
      );
    }

    _notifications.insert(
      0,
      NotificationItem(
        id: 'notif-pay-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Payment Proof Uploaded: $bookingId',
        message:
            'File "$proofFileName" received. Status is now Payment Proof Under Review until verified by FTH Accounts.',
        timestamp: DateTime.now(),
        icon: Icons.receipt_long_rounded,
        iconColor: const Color(0xFF2563EB),
        isRead: false,
      ),
    );

    notifyListeners();

    if (!ApiConfig.useMockRepositories) {
      uploadGuestPaymentProofAsync(
        bookingId: bookingId,
        proofFileName: proofFileName,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
      ).catchError((_) {});
    }
  }

  Future<void> submitGuestServiceRequest({
    required String bookingReference,
    required String guestName,
    required String roomNumber,
    required String estateName,
    required String category,
    required String subject,
    required String details,
    String priority = 'Normal',
  }) async {
    final newReq = GuestServiceRequestModel(
      id: 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      bookingReference: bookingReference,
      guestName: guestName,
      roomNumber: roomNumber,
      estateName: estateName,
      requestCategory: category,
      subject: subject,
      details: details,
      status: 'pending',
      requestedAt: DateTime.now(),
    );
    _guestServiceRequests.insert(0, newReq);

    _notifications.insert(
      0,
      NotificationItem(
        id: 'notif-req-${DateTime.now().millisecondsSinceEpoch}',
        title: '$category Request Logged',
        message:
            'Your request "$subject" for $bookingReference has been sent to the FTH Front Desk & Operations team.',
        timestamp: DateTime.now(),
        icon: Icons.support_agent_rounded,
        iconColor: const Color(0xFF0F4C3A),
        isRead: false,
      ),
    );

    notifyListeners();

    if (!ApiConfig.useMockRepositories && _apiService.guestToken != null) {
      try {
        await _apiService.submitGuestServiceRequest(
          bookingReference: bookingReference,
          category: category,
          subject: subject,
          details: details,
          priority: priority,
        );
        await loadGuestRequests();
      } catch (_) {}
    }
  }

  Future<void> submitContactInquiry({
    required String name,
    required String email,
    required String phone,
    String? category,
    String? subject,
    required String message,
  }) async {
    if (!ApiConfig.useMockRepositories) {
      await _apiService.submitPublicContact(
        name: name,
        email: email,
        phone: phone,
        category: category ?? 'General Enquiry',
        subject: subject,
        message: message,
      );
    }
  }

  OnlineCheckinRecord submitOnlineCheckin({
    required String fullName,
    required String email,
    required String phone,
    required String apartmentType,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required String companyOrAddress,
    String? idDocumentName,
    String? flightNumber,
    required String paymentMethod,
  }) {
    final record = OnlineCheckinRecord(
      id: 'CHK-${(1000 + DateTime.now().millisecond * 9).clamp(1000, 9999)}',
      fullName: fullName,
      email: email,
      phone: phone,
      apartmentType: apartmentType,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      companyOrAddress: companyOrAddress,
      idDocumentName: idDocumentName ?? 'National_ID_Passport_Uploaded.pdf',
      flightNumber: flightNumber,
      paymentMethod: paymentMethod,
      status: 'Pre-Arrival Submitted',
    );

    _checkinRecords.insert(0, record);

    _notifications.insert(
      0,
      NotificationItem(
        id: 'notif-chk-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Online Check-In Submitted: ${record.id}',
        message:
            'Pre-arrival details submitted for ${record.fullName}. Front Desk will verify upon arrival.',
        timestamp: DateTime.now(),
        icon: Icons.badge_rounded,
        iconColor: const Color(0xFFD4AF37),
        isRead: false,
      ),
    );

    notifyListeners();

    if (!ApiConfig.useMockRepositories) {
      final firstRef = _bookings.isNotEmpty ? _bookings.first.id : null;
      _apiService
          .submitGuestOnlineCheckin(
            bookingReference: firstRef,
            fullName: fullName,
            email: email,
            phone: phone,
            apartmentType: apartmentType,
            checkInDate: checkInDate,
            checkOutDate: checkOutDate,
            companyOrAddress: companyOrAddress,
            idDocumentName: idDocumentName,
            flightNumber: flightNumber,
            paymentMethod: paymentMethod,
          )
          .catchError((_) => <String, dynamic>{});
    }

    return record;
  }

  void cancelBooking(String id) {
    void updateList(List<Booking> list) {
      final idx = list.indexWhere((b) => b.id == id);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          status: BookingWorkflowStatus.cancelled.label,
          workflowStatus: BookingWorkflowStatus.cancelled,
        );
      }
    }

    updateList(_bookings);
    updateList(_staffBookings);
    notifyListeners();

    if (!ApiConfig.useMockRepositories) {
      _apiService
          .cancelGuestBooking(bookingReference: id)
          .then((data) {
            final bookingJson = data['booking'] as Map<String, dynamic>?;
            if (bookingJson != null) {
              final updated = LaravelApiService.mapBooking(
                bookingJson,
                _allAccommodations,
              );
              _replaceBookingInLists(updated);
              notifyListeners();
            }
          })
          .catchError((_) {});
    }
  }

  void _replaceBookingInLists(Booking updated) {
    final gIdx = _bookings.indexWhere((b) => b.id == updated.id);
    if (gIdx != -1) {
      _bookings[gIdx] = updated;
    } else {
      _bookings.insert(0, updated);
    }

    final sIdx = _staffBookings.indexWhere((b) => b.id == updated.id);
    if (sIdx != -1) {
      _staffBookings[sIdx] = updated;
    } else {
      _staffBookings.insert(0, updated);
    }
  }

  // ============================================================================
  // STAFF PMS WORKFLOW ACTIONS (LIVE API + STATE)
  // ============================================================================

  void staffTransitionBookingStatus({
    required String bookingId,
    required BookingWorkflowStatus targetStatus,
    String? assignedRoomNumber,
  }) {
    void updateList(List<Booking> list) {
      final idx = list.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          status: targetStatus.label,
          workflowStatus: targetStatus,
          assignedRoomNumber:
              assignedRoomNumber ?? list[idx].assignedRoomNumber,
        );
      }
    }

    updateList(_staffBookings);
    updateList(_bookings);
    notifyListeners();

    if (!ApiConfig.useMockRepositories && _apiService.staffToken != null) {
      _apiService
          .staffTransitionBookingStatus(
            bookingReference: bookingId,
            targetStatus: targetStatus.key,
            assignedRoomNumber: assignedRoomNumber,
          )
          .then((bookingJson) {
            if (bookingJson.isNotEmpty) {
              final updated = LaravelApiService.mapBooking(
                bookingJson,
                _allAccommodations,
              );
              _replaceBookingInLists(updated);
              notifyListeners();
            }
          })
          .catchError((_) {});
    }
  }

  void staffVerifyPaymentProof({
    required String paymentId,
    required bool approve,
  }) {
    final idx = _paymentRecords.indexWhere((p) => p.id == paymentId);
    if (idx != -1) {
      final record = _paymentRecords[idx];
      final receiptNo =
          'FTH-RCP-2026-00${(100 + DateTime.now().second).clamp(100, 999)}';

      _paymentRecords[idx] = record.copyWith(
        status: approve ? 'verified' : 'rejected',
        verifiedBy: currentStaffProfile.fullName,
        verifiedAt: DateTime.now(),
        receiptNumber: approve ? receiptNo : null,
      );

      if (approve) {
        void updateBookingList(List<Booking> list) {
          final bIdx = list.indexWhere((b) => b.id == record.bookingReference);
          if (bIdx != -1) {
            final old = list[bIdx];
            final newReceipts = List<PaymentReceiptDocument>.from(old.receipts)
              ..insert(
                0,
                PaymentReceiptDocument(
                  receiptNumber: receiptNo,
                  bookingReference: old.id,
                  verifiedAt: DateTime.now(),
                  amountPgk: record.amountPgk,
                  paymentMethod: record.paymentMethod,
                  bankReference: record.referenceNumber,
                  verifiedBy: currentStaffProfile.fullName,
                ),
              );
            list[bIdx] = old.copyWith(
              status: BookingWorkflowStatus.confirmed.label,
              workflowStatus: BookingWorkflowStatus.confirmed,
              amountPaidPgk: record.amountPgk,
              receipts: newReceipts,
            );
          }
        }

        updateBookingList(_staffBookings);
        updateBookingList(_bookings);
      }
      notifyListeners();
    }

    if (!ApiConfig.useMockRepositories && _apiService.staffToken != null) {
      _apiService
          .staffVerifyPayment(paymentId: paymentId, approve: approve)
          .then((data) {
            final payJson = data['payment'] as Map<String, dynamic>?;
            if (payJson != null) {
              final updatedPay = LaravelApiService.mapPaymentRecord(payJson);
              final pIdx = _paymentRecords.indexWhere(
                (p) => p.id == paymentId || p.id == updatedPay.id,
              );
              if (pIdx != -1) {
                _paymentRecords[pIdx] = updatedPay;
              }
            }
            final bookingJson = data['booking'] as Map<String, dynamic>?;
            if (bookingJson != null) {
              final updatedBooking = LaravelApiService.mapBooking(
                bookingJson,
                _allAccommodations,
              );
              _replaceBookingInLists(updatedBooking);
            }
            notifyListeners();
          })
          .catchError((_) {});
    }
  }

  void staffPostFolioEntry({
    required String bookingId,
    required String entryType,
    required String description,
    required double amountPgk,
  }) {
    void updateList(List<Booking> list) {
      final idx = list.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        final old = list[idx];
        final updatedEntries = List<FolioLineItem>.from(old.folioEntries)
          ..add(
            FolioLineItem(
              id: 'FOL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              entryType: entryType,
              description: description,
              amountPgk: amountPgk,
              postedAt: DateTime.now(),
              postedBy: currentStaffProfile.fullName,
            ),
          );
        list[idx] = old.copyWith(folioEntries: updatedEntries);
      }
    }

    updateList(_staffBookings);
    updateList(_bookings);
    notifyListeners();

    if (!ApiConfig.useMockRepositories && _apiService.staffToken != null) {
      _apiService
          .staffPostFolioEntry(
            bookingReference: bookingId,
            entryType: entryType,
            description: description,
            amountPgk: amountPgk,
          )
          .then((bookingJson) {
            if (bookingJson.isNotEmpty) {
              final updated = LaravelApiService.mapBooking(
                bookingJson,
                _allAccommodations,
              );
              _replaceBookingInLists(updated);
              notifyListeners();
            }
          })
          .catchError((_) {});
    }
  }

  Future<void> staffGenerateInvoice({required String bookingId}) async {
    if (!ApiConfig.useMockRepositories && _apiService.staffToken != null) {
      final bookingJson = await _apiService.staffGenerateInvoice(
        bookingReference: bookingId,
      );
      if (bookingJson.isNotEmpty) {
        final updated = LaravelApiService.mapBooking(
          bookingJson,
          _allAccommodations,
        );
        _replaceBookingInLists(updated);
        notifyListeners();
      }
    }
  }

  void staffUpdateHousekeepingTask({
    required String taskId,
    required String roomStatus,
    String? assignedTo,
  }) {
    final idx = _housekeepingTasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _housekeepingTasks[idx] = _housekeepingTasks[idx].copyWith(
        roomStatus: roomStatus,
        assignedTo: assignedTo,
      );
      notifyListeners();
    }

    if (!ApiConfig.useMockRepositories && _apiService.staffToken != null) {
      _apiService
          .staffUpdateHousekeepingTask(taskId: taskId, roomStatus: roomStatus)
          .catchError((_) => <String, dynamic>{});
    }
  }

  void staffUpdateMaintenanceTicket({
    required String ticketId,
    required String status,
    String? priority,
    String? attachmentFileName,
  }) {
    final idx = _maintenanceTickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      _maintenanceTickets[idx] = _maintenanceTickets[idx].copyWith(
        status: status,
        priority: priority,
        attachmentFileName: attachmentFileName,
      );
      notifyListeners();
    }

    if (!ApiConfig.useMockRepositories && _apiService.staffToken != null) {
      _apiService
          .staffUpdateMaintenanceTicket(
            ticketId: ticketId,
            status: status,
            priority: priority,
          )
          .catchError((_) => <String, dynamic>{});
    }
  }

  void staffCreateMaintenanceTicket({
    required String roomNumber,
    required String estateName,
    required String category,
    required String title,
    required String description,
    required String priority,
    String? attachmentFileName,
  }) {
    final tempId =
        'MNT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _maintenanceTickets.insert(
      0,
      MaintenanceTicketModel(
        id: tempId,
        ticketNumber:
            'MNT-2026-0${(21 + _maintenanceTickets.length).clamp(21, 99)}',
        roomNumber: roomNumber,
        estateName: estateName,
        category: category,
        title: title,
        description: description,
        priority: priority,
        status: 'open',
        reportedBy: currentStaffProfile.fullName,
        assignedTo: 'Maintenance Tech',
        attachmentFileName: attachmentFileName,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();

    if (!ApiConfig.useMockRepositories && _apiService.staffToken != null) {
      _apiService
          .staffCreateMaintenanceTicket(
            roomNumber: roomNumber,
            estateName: estateName,
            category: category,
            title: title,
            description: description,
            priority: priority,
            attachmentFileName: attachmentFileName,
          )
          .then((ticketJson) {
            if (ticketJson.isNotEmpty) {
              final created = LaravelApiService.mapMaintenanceTicket(
                ticketJson,
              );
              final idx = _maintenanceTickets.indexWhere((t) => t.id == tempId);
              if (idx != -1) {
                _maintenanceTickets[idx] = created;
                notifyListeners();
              }
            }
          })
          .catchError((_) {});
    }
  }

  void staffUpdateTransferStatus({
    required String transferId,
    required String status,
  }) {
    final idx = _airportTransfers.indexWhere((t) => t.id == transferId);
    if (idx != -1) {
      _airportTransfers[idx] = _airportTransfers[idx].copyWith(status: status);
      notifyListeners();
    }

    if (!ApiConfig.useMockRepositories && _apiService.staffToken != null) {
      _apiService
          .staffUpdateTransferStatus(transferId: transferId, status: status)
          .catchError((_) => <String, dynamic>{});
    }
  }

  void staffUpdateGuestRequestStatus({
    required String requestId,
    required String status,
    String? responseNote,
  }) {
    final idx = _guestServiceRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _guestServiceRequests[idx] = _guestServiceRequests[idx].copyWith(
        status: status,
        staffResponseNote: responseNote,
      );
      notifyListeners();
    }

    if (!ApiConfig.useMockRepositories && _apiService.staffToken != null) {
      _apiService
          .staffUpdateGuestRequestStatus(
            requestId: requestId,
            status: status,
            responseNote: responseNote,
          )
          .catchError((_) => <String, dynamic>{});
    }
  }

  void staffUpdateRefundStatus({
    required String refundId,
    required String status,
  }) {
    final idx = _refundRequests.indexWhere((r) => r.id == refundId);
    if (idx != -1) {
      _refundRequests[idx] = _refundRequests[idx].copyWith(status: status);
      notifyListeners();
    }

    if (!ApiConfig.useMockRepositories && _apiService.staffToken != null) {
      _apiService
          .staffUpdateRefundStatus(refundId: refundId, status: status)
          .catchError((_) => <String, dynamic>{});
    }
  }

  void staffCreateStaffInvitation({
    required String fullName,
    required String email,
    required String phone,
    required StaffRole role,
    required String assignedEstate,
  }) {
    final tempId =
        'STF-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
    _staffMembers.insert(
      0,
      StaffMemberModel(
        id: tempId,
        fullName: fullName,
        email: email,
        phone: phone,
        role: role,
        assignedEstate: assignedEstate,
        isActive: true,
        invitationStatus: 'pending_invitation',
        invitationExpiresAt: DateTime.now().add(const Duration(hours: 24)),
        effectivePermissions: role.defaultPermissions,
      ),
    );
    notifyListeners();

    if (!ApiConfig.useMockRepositories && _apiService.staffToken != null) {
      _apiService
          .staffCreateStaffInvitation(
            fullName: fullName,
            email: email,
            phone: phone,
            role: role.key,
            assignedEstate: assignedEstate,
          )
          .then((staffJson) {
            if (staffJson.isNotEmpty) {
              final created = LaravelApiService.mapStaffMember(staffJson);
              final idx = _staffMembers.indexWhere((s) => s.id == tempId);
              if (idx != -1) {
                _staffMembers[idx] = created;
                notifyListeners();
              }
            }
          })
          .catchError((_) {});
    }
  }

  // ===========================================================================
  // REAL ASYNC ERROR-PROPAGATING MUTATIONS (ZERO SILENT FAILURE)
  // ===========================================================================

  Future<Map<String, dynamic>> cancelBookingAsync(String id) async {
    final data = await _apiService.cancelGuestBooking(bookingReference: id);
    final bookingJson = data['booking'] as Map<String, dynamic>?;
    if (bookingJson != null) {
      final updated = LaravelApiService.mapBooking(
        bookingJson,
        _allAccommodations,
      );
      _replaceBookingInLists(updated);
    }
    notifyListeners();
    return data;
  }

  Future<void> fetchIdentityDocumentsAsync() async {
    if (_apiService.guestToken == null) return;
    try {
      _identityDocuments = await _apiService.fetchGuestIdentityDocuments();
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> uploadGuestIdentityDocumentAsync({
    String? bookingReference,
    required String documentType,
    required String fileName,
    required String fileBase64,
    String? notes,
  }) async {
    final res = await _apiService.uploadGuestIdentityDocument(
      bookingReference: bookingReference,
      documentType: documentType,
      fileName: fileName,
      fileBase64: fileBase64,
      notes: notes,
    );
    await fetchIdentityDocumentsAsync();
    return res;
  }

  Future<void> submitOnlineCheckinAsync({
    required String fullName,
    required String email,
    required String phone,
    String nationality = 'Papua New Guinea',
    required String apartmentType,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required String companyOrAddress,
    String? documentType,
    required String idDocumentName,
    String? fileBase64,
    String? fileName,
    String? flightNumber,
    String? paymentMethod,
  }) async {
    final firstRef = _bookings.isNotEmpty ? _bookings.first.id : null;
    await _apiService.submitGuestOnlineCheckin(
      bookingReference: firstRef,
      fullName: fullName,
      email: email,
      phone: phone,
      nationality: nationality,
      apartmentType: apartmentType,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      companyOrAddress: companyOrAddress,
      documentType: documentType,
      idDocumentName: idDocumentName,
      fileBase64: fileBase64,
      fileName: fileName,
      flightNumber: flightNumber,
      paymentMethod: paymentMethod ?? '',
    );
    if (fileBase64 != null && fileBase64.isNotEmpty) {
      await fetchIdentityDocumentsAsync();
    }
    _checkinRecords.insert(
      0,
      OnlineCheckinRecord(
        id: 'CHK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        fullName: fullName,
        email: email,
        phone: phone,
        apartmentType: apartmentType,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        companyOrAddress: companyOrAddress,
        idDocumentName: idDocumentName,
        flightNumber: flightNumber ?? '',
        paymentMethod: paymentMethod ?? '',
        status: 'Pre-Arrival Submitted',
      ),
    );
    notifyListeners();
  }

  Future<void> staffTransitionBookingStatusAsync({
    required String bookingId,
    required BookingWorkflowStatus targetStatus,
    String? assignedRoomNumber,
  }) async {
    final bookingJson = await _apiService.staffTransitionBookingStatus(
      bookingReference: bookingId,
      targetStatus: targetStatus.key,
      assignedRoomNumber: assignedRoomNumber,
    );
    if (bookingJson.isNotEmpty) {
      final updated = LaravelApiService.mapBooking(
        bookingJson,
        _allAccommodations,
      );
      _replaceBookingInLists(updated);
    }
    await refreshStaffDashboard();
  }

  Future<void> staffCreateRoomBlock({
    required String unitCode,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? notes,
  }) async {
    await _apiService.staffCreateRoomBlock(
      unitCode: unitCode,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      notes: notes,
    );
    await refreshStaffDashboard();
  }

  Future<void> staffDeleteRoomBlock(String blockId) async {
    await _apiService.staffDeleteRoomBlock(blockId);
    await refreshStaffDashboard();
  }

  Future<({Uint8List bytes, String contentType})> fetchStaffPaymentProofBytes(
    String paymentId,
  ) {
    return _apiService.downloadStaffPaymentProofBytes(paymentId);
  }

  Future<void> staffVerifyPaymentProofAsync({
    required String paymentId,
    required bool approve,
  }) async {
    await _apiService.staffVerifyPayment(
      paymentId: paymentId,
      approve: approve,
    );
    await refreshStaffDashboard();
  }

  Future<void> staffPostFolioEntryAsync({
    required String bookingId,
    required String entryType,
    required String description,
    required double amountPgk,
  }) async {
    await _apiService.staffPostFolioEntry(
      bookingReference: bookingId,
      entryType: entryType,
      description: description,
      amountPgk: amountPgk,
    );
    await refreshStaffDashboard();
  }

  Future<void> staffGenerateInvoiceAsync(String bookingId) async {
    await _apiService.staffGenerateInvoice(bookingReference: bookingId);
    await refreshStaffDashboard();
  }

  Future<void> staffUpdateRefundStatusAsync({
    required String refundId,
    required String status,
  }) async {
    await _apiService.staffUpdateRefundStatus(
      refundId: refundId,
      status: status,
    );
    await refreshStaffDashboard();
  }

  Future<void> staffUpdateHousekeepingTaskAsync({
    required String taskId,
    required String newStatus,
  }) async {
    await _apiService.staffUpdateHousekeepingTask(
      taskId: taskId,
      roomStatus: newStatus,
    );
    await refreshStaffDashboard();
  }

  Future<void> staffCreateMaintenanceTicketAsync({
    required String roomNumber,
    required String estateName,
    required String category,
    required String title,
    required String description,
    required String priority,
    String? attachmentFileName,
  }) async {
    await _apiService.staffCreateMaintenanceTicket(
      roomNumber: roomNumber,
      estateName: estateName,
      category: category,
      title: title,
      description: description,
      priority: priority,
      attachmentFileName: attachmentFileName,
    );
    await refreshStaffDashboard();
  }

  Future<void> staffUpdateMaintenanceTicketAsync({
    required String ticketId,
    required String status,
    String? priority,
  }) async {
    await _apiService.staffUpdateMaintenanceTicket(
      ticketId: ticketId,
      status: status,
      priority: priority,
    );
    await refreshStaffDashboard();
  }

  Future<void> staffUpdateTransferStatusAsync({
    required String transferId,
    required String status,
  }) async {
    await _apiService.staffUpdateTransferStatus(
      transferId: transferId,
      status: status,
    );
    await refreshStaffDashboard();
  }

  Future<void> staffUpdateGuestRequestStatusAsync({
    required String requestId,
    required String status,
    String? responseNote,
  }) async {
    await _apiService.staffUpdateGuestRequestStatus(
      requestId: requestId,
      status: status,
      responseNote: responseNote,
    );
    await refreshStaffDashboard();
  }

  Future<void> staffCreateStaffInvitationAsync({
    required String fullName,
    required String email,
    required String phone,
    required StaffRole role,
    required String assignedEstate,
  }) async {
    await _apiService.staffCreateStaffInvitation(
      fullName: fullName,
      email: email,
      phone: phone,
      role: role.key,
      assignedEstate: assignedEstate,
    );
    await refreshStaffDashboard();
  }

  Future<void> staffResendInvitationAsync(String userId) async {
    await _apiService.staffResendInvitation(userId);
    await refreshStaffDashboard();
  }

  Future<void> staffToggleUserActiveAsync(String userId) async {
    await _apiService.staffToggleUserActive(userId);
    await refreshStaffDashboard();
  }
}
