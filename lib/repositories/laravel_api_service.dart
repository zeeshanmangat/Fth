import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../core/constants/assets.dart';
import '../data/models/accommodation.dart';
import '../data/models/amenity.dart';
import '../data/models/booking.dart';
import '../data/models/notification_item.dart';
import '../data/models/user_profile.dart';
import '../models/estate_model.dart';
import '../models/operational_models.dart';
import '../models/rate_plan_model.dart';
import '../models/staff_role_model.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, {this.statusCode = 500});

  @override
  String toString() => message;
}

class LaravelApiService {
  final http.Client _httpClient;
  String _baseUrl;
  String? _guestToken;
  String? _staffToken;

  LaravelApiService({
    http.Client? httpClient,
    String? baseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  String get baseUrl => _baseUrl;
  String? get guestToken => _guestToken;
  String? get staffToken => _staffToken;

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  void setGuestToken(String? token) {
    _guestToken = token;
  }

  void setStaffToken(String? token) {
    _staffToken = token;
  }

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    String? token,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    var uri = Uri.parse('$_baseUrl$endpoint');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    late http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: _headers(token: token))
              .timeout(const Duration(seconds: 20));
          break;
        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: _headers(token: token),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 25));
          break;
        case 'PUT':
          response = await _httpClient
              .put(
                uri,
                headers: _headers(token: token),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 20));
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: _headers(token: token))
              .timeout(const Duration(seconds: 20));
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const ApiException(
        'Unable to reach Family Transit Home server. Please check your internet connection and tap Retry.',
        statusCode: 0,
      );
    }

    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) {
          decoded = raw;
        }
      } catch (_) {
        throw ApiException(
          'Unexpected server response (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final msg =
        decoded['message']?.toString() ??
        (decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty
            ? (decoded['errors'] as List).first.toString()
            : 'Request failed (HTTP ${response.statusCode}).');
    throw ApiException(msg, statusCode: response.statusCode);
  }

  // ===========================================================================
  // PUBLIC CATALOG & PRICING ENDPOINTS
  // ===========================================================================

  Future<Map<String, dynamic>> fetchPublicBootstrap() async {
    final res = await _request('GET', ApiConfig.publicBootstrap);
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<List<Map<String, dynamic>>> fetchPublicApartments({
    DateTime? checkIn,
    DateTime? checkOut,
    String? estate,
    int? guests,
  }) async {
    final res = await _request(
      'GET',
      ApiConfig.accommodationsEndpoint,
      queryParameters: {
        if (checkIn != null) 'check_in': _fmtDate(checkIn),
        if (checkOut != null) 'check_out': _fmtDate(checkOut),
        if (estate != null && estate.isNotEmpty && estate != 'All')
          'estate': estate,
        if (guests != null && guests > 0) 'guests': guests.toString(),
      },
    );
    final raw = (res['data'] as List?) ?? [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> fetchPricingQuote({
    required String categoryId,
    required DateTime checkIn,
    required DateTime checkOut,
    int roomsCount = 1,
    String? ratePlanCode,
    String? promoCode,
  }) async {
    final res = await _request(
      'POST',
      ApiConfig.pricingQuoteEndpoint,
      body: {
        'category_id': categoryId,
        'check_in': _fmtDate(checkIn),
        'check_out': _fmtDate(checkOut),
        'rooms_count': roomsCount,
        'rate_plan_code': ratePlanCode?.toLowerCase(),
        if (promoCode != null && promoCode.trim().isNotEmpty)
          'promo_code': promoCode.trim(),
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> submitPublicContact({
    required String name,
    required String email,
    required String phone,
    String? category,
    String? subject,
    required String message,
    String? bookingReference,
  }) async {
    return _request(
      'POST',
      ApiConfig.contactEndpoint,
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'category': category ?? 'General Inquiry',
        'subject': subject,
        'message': message,
        'booking_reference': bookingReference,
      },
    );
  }

  // ===========================================================================
  // GUEST AUTH & PORTAL ENDPOINTS
  // ===========================================================================

  Future<Map<String, dynamic>> guestLogin({
    required String email,
    String? password,
    String? bookingReference,
  }) async {
    final res = await _request(
      'POST',
      ApiConfig.authGuestLogin,
      body: {
        'email': email.trim(),
        if (password != null && password.isNotEmpty) 'password': password,
        if (bookingReference != null && bookingReference.trim().isNotEmpty)
          'booking_reference': bookingReference.trim().toUpperCase(),
      },
    );
    final data = (res['data'] as Map<String, dynamic>?) ?? {};
    if (data['token'] != null) {
      _guestToken = data['token'].toString();
    }
    return data;
  }

  Future<Map<String, dynamic>> guestRegister({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? companyOrOrganization,
  }) async {
    final res = await _request(
      'POST',
      ApiConfig.authGuestRegister,
      body: {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'company_or_organization': companyOrOrganization,
      },
    );
    final data = (res['data'] as Map<String, dynamic>?) ?? {};
    if (data['token'] != null) {
      _guestToken = data['token'].toString();
    }
    return data;
  }

  Future<void> guestLogout() async {
    if (_guestToken != null) {
      try {
        await _request('POST', ApiConfig.authGuestLogout, token: _guestToken);
      } catch (_) {}
      _guestToken = null;
    }
  }

  Future<Map<String, dynamic>> fetchGuestProfile() async {
    final res = await _request(
      'GET',
      ApiConfig.guestProfileEndpoint,
      token: _guestToken,
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> createGuestBooking({
    required String categoryId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    String? nationality,
    String? companyOrganization,
    String? ratePlanCode,
    String? promoCode,
    String? paymentMethodChoice,
    required bool transferRequired,
    String? flightNumber,
    String? arrivalEta,
    String? specialRequests,
  }) async {
    final res = await _request(
      'POST',
      ApiConfig.guestBookingsEndpoint,
      token: _guestToken,
      body: {
        'category_id': categoryId,
        'check_in': _fmtDate(checkIn),
        'check_out': _fmtDate(checkOut),
        'adults': adults,
        'children': children,
        'guest_name': guestName,
        'guest_email': guestEmail,
        'guest_phone': guestPhone,
        if (nationality != null && nationality.trim().isNotEmpty)
          'nationality': nationality.trim(),
        'company_organization': companyOrganization,
        'rate_plan_code': ratePlanCode?.toLowerCase(),
        if (promoCode != null && promoCode.trim().isNotEmpty)
          'promo_code': promoCode.trim(),
        'payment_method_choice': paymentMethodChoice,
        'transfer_required': transferRequired,
        'flight_number': flightNumber,
        'arrival_eta': arrivalEta,
        'special_requests': specialRequests,
      },
    );
    final data = (res['data'] as Map<String, dynamic>?) ?? {};
    if (data['token'] != null &&
        (_guestToken == null || _guestToken!.isEmpty)) {
      _guestToken = data['token'].toString();
    }
    return data;
  }

  Future<Map<String, dynamic>> uploadGuestPaymentProof({
    required String bookingReference,
    required String paymentMethod,
    required String referenceNumber,
    required String proofFileName,
    required String proofFileBase64,
  }) async {
    final res = await _request(
      'POST',
      '${ApiConfig.guestBookingsEndpoint}/$bookingReference/payment-proof',
      token: _guestToken,
      body: {
        'payment_method': paymentMethod,
        'reference_number': referenceNumber,
        'proof_file_name': proofFileName,
        'proof_file_base64': proofFileBase64,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> cancelGuestBooking({
    required String bookingReference,
    String? reason,
  }) async {
    final res = await _request(
      'POST',
      '${ApiConfig.guestBookingsEndpoint}/$bookingReference/cancel',
      token: _guestToken,
      body: {
        'reason': reason ?? 'Cancelled by guest via FTH Mobile App',
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> submitGuestServiceRequest({
    String? bookingReference,
    required String category,
    required String subject,
    required String details,
    String? priority,
  }) async {
    final res = await _request(
      'POST',
      ApiConfig.guestRequestsEndpoint,
      token: _guestToken,
      body: {
        'booking_reference': bookingReference,
        'category': category,
        'subject': subject,
        'details': details,
        if (priority != null && priority.isNotEmpty) 'priority': priority,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<List<GuestServiceRequestModel>> fetchGuestRequests() async {
    final res = await _request(
      'GET',
      ApiConfig.guestRequestsEndpoint,
      token: _guestToken,
    );
    final raw = (res['data'] as List?) ?? [];
    return raw
        .map((r) => mapGuestServiceRequest(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchGuestIdentityDocuments() async {
    final res = await _request(
      'GET',
      ApiConfig.guestIdDocumentsEndpoint,
      token: _guestToken,
    );
    final raw = (res['data'] as List?) ?? [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> uploadGuestIdentityDocument({
    String? bookingReference,
    required String documentType,
    required String fileName,
    required String fileBase64,
    String? notes,
  }) async {
    final res = await _request(
      'POST',
      ApiConfig.guestIdDocumentsEndpoint,
      token: _guestToken,
      body: {
        if (bookingReference != null && bookingReference.trim().isNotEmpty)
          'booking_reference': bookingReference.trim(),
        'document_type': documentType,
        'file_name': fileName,
        'file_base64': fileBase64,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> submitGuestOnlineCheckin({
    String? bookingReference,
    required String fullName,
    required String email,
    required String phone,
    String nationality = 'Papua New Guinea',
    required String apartmentType,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required String companyOrAddress,
    String? documentType,
    String? idDocumentName,
    String? fileBase64,
    String? fileName,
    String? flightNumber,
    required String paymentMethod,
  }) async {
    final res = await _request(
      'POST',
      ApiConfig.guestCheckinEndpoint,
      token: _guestToken,
      body: {
        'booking_reference': bookingReference,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'nationality': nationality,
        'apartment_type': apartmentType,
        'check_in_date': _fmtDate(checkInDate),
        'check_out_date': _fmtDate(checkOutDate),
        'company_or_address': companyOrAddress,
        if (documentType != null && documentType.isNotEmpty)
          'document_type': documentType,
        'id_document_name': idDocumentName,
        if (fileBase64 != null && fileBase64.isNotEmpty) ...{
          'file_base64': fileBase64,
          'file_name': fileName ?? idDocumentName ?? 'id_document.jpg',
        },
        'flight_number': flightNumber,
        'payment_method': paymentMethod,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  // ===========================================================================
  // STAFF PMS & OWNER PORTAL ENDPOINTS
  // ===========================================================================

  Future<Map<String, dynamic>> staffLogin({
    required String email,
    required String password,
  }) async {
    final res = await _request(
      'POST',
      ApiConfig.authStaffLogin,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );
    final data = (res['data'] as Map<String, dynamic>?) ?? {};
    if (data['token'] != null) {
      _staffToken = data['token'].toString();
    }
    return data;
  }

  Future<void> staffLogout() async {
    if (_staffToken != null) {
      try {
        await _request('POST', ApiConfig.authStaffLogout, token: _staffToken);
      } catch (_) {}
      _staffToken = null;
    }
  }

  Future<Map<String, dynamic>> fetchStaffDashboard() async {
    final res = await _request(
      'GET',
      ApiConfig.staffDashboardEndpoint,
      token: _staffToken,
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffTransitionBookingStatus({
    required String bookingReference,
    required String targetStatus,
    String? assignedRoomNumber,
    String? reason,
  }) async {
    final res = await _request(
      'POST',
      '${ApiConfig.staffBookingsEndpoint}/$bookingReference/status',
      token: _staffToken,
      body: {
        'target_status': targetStatus,
        'assigned_room_number': ?assignedRoomNumber,
        'reason': ?reason,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffVerifyPayment({
    required String paymentId,
    required bool approve,
    String? notes,
  }) async {
    final res = await _request(
      'POST',
      '/staff/payments/$paymentId/verify',
      token: _staffToken,
      body: {
        'approve': approve,
        'notes': ?notes,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffPostFolioEntry({
    required String bookingReference,
    required String entryType,
    required String description,
    required double amountPgk,
  }) async {
    final res = await _request(
      'POST',
      '${ApiConfig.staffBookingsEndpoint}/$bookingReference/folio',
      token: _staffToken,
      body: {
        'entry_type': entryType,
        'description': description,
        'amount_pgk': amountPgk,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffGenerateInvoice({
    required String bookingReference,
  }) async {
    final res = await _request(
      'POST',
      '${ApiConfig.staffBookingsEndpoint}/$bookingReference/invoices',
      token: _staffToken,
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffUpdateRefundStatus({
    required String refundId,
    required String status,
  }) async {
    final res = await _request(
      'POST',
      '/staff/refunds/$refundId/status',
      token: _staffToken,
      body: {'status': status},
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffUpdateHousekeepingTask({
    required String taskId,
    required String roomStatus,
  }) async {
    final res = await _request(
      'POST',
      '/staff/housekeeping/$taskId/status',
      token: _staffToken,
      body: {'room_status': roomStatus},
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffCreateMaintenanceTicket({
    required String roomNumber,
    required String estateName,
    required String category,
    required String title,
    required String description,
    required String priority,
    String? attachmentFileName,
  }) async {
    final res = await _request(
      'POST',
      '/staff/maintenance',
      token: _staffToken,
      body: {
        'room_number': roomNumber,
        'estate_name': estateName,
        'category': category,
        'title': title,
        'description': description,
        'priority': priority,
        'attachment_file_name': ?attachmentFileName,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffUpdateMaintenanceTicket({
    required String ticketId,
    required String status,
    String? priority,
  }) async {
    final res = await _request(
      'POST',
      '/staff/maintenance/$ticketId/status',
      token: _staffToken,
      body: {
        'status': status,
        'priority': ?priority,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffUpdateTransferStatus({
    required String transferId,
    required String status,
  }) async {
    final res = await _request(
      'POST',
      '/staff/transfers/$transferId/status',
      token: _staffToken,
      body: {'status': status},
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffUpdateGuestRequestStatus({
    required String requestId,
    required String status,
    String? responseNote,
  }) async {
    final res = await _request(
      'POST',
      '/staff/guest-requests/$requestId/status',
      token: _staffToken,
      body: {
        'status': status,
        'response_note': ?responseNote,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> fetchStaffReports({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await _request(
      'GET',
      ApiConfig.staffReportsEndpoint,
      token: _staffToken,
      queryParameters: {
        if (startDate != null) 'start_date': _fmtDate(startDate),
        if (endDate != null) 'end_date': _fmtDate(endDate),
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffCreateStaffInvitation({
    required String fullName,
    required String email,
    required String phone,
    required String role,
    required String assignedEstate,
  }) async {
    final res = await _request(
      'POST',
      ApiConfig.staffUsersEndpoint,
      token: _staffToken,
      body: {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'assigned_estate': assignedEstate,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> staffResendInvitation(String userId) async {
    await _request(
      'POST',
      '${ApiConfig.staffUsersEndpoint}/$userId/resend-invitation',
      token: _staffToken,
    );
  }

  Future<Map<String, dynamic>> staffToggleUserActive(String userId) async {
    final res = await _request(
      'POST',
      '${ApiConfig.staffUsersEndpoint}/$userId/toggle',
      token: _staffToken,
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> staffCreateRoomBlock({
    required String unitCode,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? notes,
  }) async {
    final res = await _request(
      'POST',
      '/staff/calendar/blocks',
      token: _staffToken,
      body: {
        'unit_code': unitCode,
        'start_date': _fmtDate(startDate),
        'end_date': _fmtDate(endDate),
        'reason': reason,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> staffDeleteRoomBlock(String blockId) async {
    await _request(
      'DELETE',
      '/staff/calendar/blocks/$blockId',
      token: _staffToken,
    );
  }

  Future<({Uint8List bytes, String contentType})> downloadStaffPaymentProofBytes(
    String paymentId,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/staff/payments/$paymentId/proof');
    final res = await _httpClient
        .get(uri, headers: {
          'Accept': '*/*',
          if (_staffToken != null && _staffToken!.isNotEmpty)
            'Authorization': 'Bearer $_staffToken',
        })
        .timeout(const Duration(seconds: 25));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        'Failed to load payment proof (HTTP ${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    return (
      bytes: res.bodyBytes,
      contentType: res.headers['content-type'] ?? 'application/octet-stream',
    );
  }

  // ===========================================================================
  // JSON TO DOMAIN MODEL MAPPERS
  // ===========================================================================

  static EstateModel mapEstate(Map<String, dynamic> json) {
    final rawPath = (json['image_path'] ?? json['image'] ?? '').toString();
    final fullUrl = json['image']?.toString();
    final galleryRaw = (json['gallery'] as List?) ?? [];

    return EstateModel(
      id: _toInt(json['id'], 1),
      key: (json['key'] ?? 'kennedy').toString(),
      slug: (json['slug'] ?? 'kennedy-estate').toString(),
      name: (json['name'] ?? 'Kennedy Estate').toString(),
      location: (json['location'] ?? '7 Mile, Port Moresby').toString(),
      address: (json['address'] ?? '').toString(),
      distanceAirport: (json['distance_airport'] ?? '').toString(),
      badge: (json['badge'] ?? 'FTH Residence').toString(),
      image: resolveCatalogImagePath(rawPath, fullUrl: fullUrl),
      gallery: galleryRaw
          .map((e) => resolveCatalogImagePath(e.toString(), fullUrl: e.toString()))
          .toList(),
      description: (json['description'] ?? '').toString(),
      placeholderNote: (json['placeholder_note'] ?? '').toString(),
      highlights: ((json['highlights'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      sampleCategories: ((json['sample_categories'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      totalPhysicalUnits: _toInt(json['unit_count'], 0),
    );
  }

  static Accommodation mapAccommodation(Map<String, dynamic> json) {
    final rawImg = (json['image_path'] ?? json['image'] ?? '').toString();
    final fullImgUrl = json['image']?.toString();
    final galleryRaw = (json['gallery'] as List?) ?? [];
    final amenityList = ((json['amenities'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    final bedrooms = _toInt(json['bedrooms'], 1);

    return Accommodation(
      id: (json['code'] ?? json['id'] ?? 'APT-01').toString(),
      slug: (json['slug'] ?? '').toString(),
      title: (json['name'] ?? 'Serviced Apartment').toString(),
      categoryType: (json['category_type'] ?? 'Serviced Apartment').toString(),
      estateKey: (json['estate_key'] ?? 'kennedy').toString(),
      estate: (json['estate_name'] ?? 'Kennedy Estate — 7 Mile').toString(),
      estateAssignmentNote:
          (json['estate_assignment_note'] ??
                  'Confirmed upon reservation assignment')
              .toString(),
      locationArea:
          (json['estate_location'] ?? 'Port Moresby, NCD').toString(),
      distanceToAirport: (json['distance_airport'] ?? '').toString().trim(),
      pricePerNight: _toDouble(json['rate_pgk'], 440.0),
      altRatePgk: json['rate_alt_pgk'] != null
          ? _toDouble(json['rate_alt_pgk'], 0)
          : null,
      rateNote: (json['rate_alt_note'] ?? 'GST-Inclusive Rate').toString(),
      gstInclusive: json['gst_inclusive'] != false,
      maxAdults: _toInt(json['max_adults'], 2),
      maxChildren: _toInt(json['max_children'], 1),
      maxGuests: _toInt(
        json['max_guests'],
        _toInt(json['max_adults'], 2) + _toInt(json['max_children'], 1),
      ),
      bedrooms: bedrooms,
      bathrooms: _toInt(json['bathrooms'], 1),
      beds: bedrooms,
      floorLevel: (json['floor_level'] ?? 'Ground / Level 1').toString(),
      view: (json['view'] ?? 'Estate Courtyard View').toString(),
      bedConfiguration: bedrooms >= 3
          ? '1 Master Queen + 2 Queen Beds'
          : (bedrooms == 2 ? '2 Queen Beds' : '1 Queen Bed'),
      sizeSqm: bedrooms >= 3 ? 135 : (bedrooms == 2 ? 95 : 62),
      mainImage: resolveCatalogImagePath(rawImg, fullUrl: fullImgUrl),
      galleryImages: galleryRaw.isNotEmpty
          ? galleryRaw
              .map((e) => resolveCatalogImagePath(e.toString(), fullUrl: e.toString()))
              .toList()
          : [resolveCatalogImagePath(rawImg, fullUrl: fullImgUrl)],
      shortDescription: (json['short_description'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      amenities: amenityList
          .map<Amenity>(
            (label) => Amenity(
              id: label.toLowerCase().replaceAll(' ', '_'),
              name: label,
              icon: _iconForAmenity(label),
              description: label,
            ),
          )
          .toList(),
      amenityLabels: amenityList,
      isFeatured: json['featured'] == true,
      isPopular: true,
    );
  }

  static PhysicalRoomUnit mapPhysicalUnit(
    Map<String, dynamic> json,
    int rowNumber,
  ) {
    final rawStatus = (json['status'] ?? 'Available').toString().toLowerCase();
    final hkStatus =
        (json['housekeeping_status'] ?? 'Clean').toString().toLowerCase();

    String mappedStatus = 'clean';
    if (rawStatus.contains('occup') || rawStatus.contains('check')) {
      mappedStatus = 'occupied';
    } else if (rawStatus.contains('maint') || rawStatus.contains('out')) {
      mappedStatus = 'out_of_service';
    } else if (hkStatus.contains('dirty')) {
      mappedStatus = 'dirty';
    } else if (hkStatus.contains('inspect')) {
      mappedStatus = 'inspected';
    }

    return PhysicalRoomUnit(
      rowNumber: rowNumber,
      roomNumber: (json['unit_code'] ?? '').toString(),
      estateKey: (json['estate_key'] ?? 'kennedy').toString(),
      estateLocation:
          (json['estate_name'] ?? 'Kennedy Estate — 7 Mile').toString(),
      unitType: (json['category_name'] ?? 'Serviced Apartment').toString(),
      categorySlug:
          (json['category_slug'] ?? json['category_id'] ?? 'APT-01').toString(),
      floorLevel: (json['floor_level'] ?? 'Ground Floor').toString(),
      standardRatePgk: _toDouble(json['standard_rate_pgk'], 440.0),
      status: mappedStatus,
    );
  }

  static RatePlanModel mapRatePlan(Map<String, dynamic> json) {
    final code = (json['code'] ?? 'standard').toString().toUpperCase();
    final modType = (json['modifier_type'] ?? 'none').toString();
    final modVal = _toDouble(json['modifier_value'], 0.0);

    double discountPct = 0.0;
    if (modType == 'percentage_discount') {
      discountPct = modVal;
    }

    return RatePlanModel(
      code: code,
      name: (json['name'] ?? 'Standard Rate').toString(),
      shortBadge: discountPct > 0
          ? '${discountPct.toInt()}% OFF'
          : 'GST-Incl.',
      description: (json['description'] ?? '').toString(),
      minNights: _toInt(json['min_nights'], 2),
      previewDiscountPercent: discountPct,
      cancellationPolicyType:
          (json['cancellation_policy_type'] ?? 'standard_48h').toString(),
      isCorporate: code.contains('CORP'),
    );
  }

  static Booking mapBooking(
    Map<String, dynamic> json,
    List<Accommodation> catalog,
  ) {
    final catId = (json['category_id'] ?? 'APT-01').toString();
    final acc = catalog.firstWhere(
      (a) => a.id == catId,
      orElse: () => catalog.isNotEmpty
          ? catalog.first
          : const Accommodation(
              id: 'APT-01',
              title: 'Single-Bedroom Executive Apartment',
              estate: 'Kennedy Estate — 7 Mile',
              locationArea: '7 Mile, Port Moresby',
              pricePerNight: 440,
              maxGuests: 3,
              bedrooms: 1,
              bathrooms: 1,
              beds: 1,
              bedConfiguration: '1 Queen Bed',
              sizeSqm: 62,
              mainImage: AppAssets.fthQueenBedroom,
              galleryImages: [AppAssets.fthQueenBedroom],
              description: 'Executive Apartment at Family Transit Home.',
              amenities: [],
            ),
    );

    final rawStatus = (json['status'] ?? 'Pending Approval').toString();
    final hasPendingProof = json['has_pending_payment_proof'] == true;
    BookingWorkflowStatus wfStatus = BookingWorkflowStatus.fromKey(rawStatus);
    if (hasPendingProof &&
        (wfStatus == BookingWorkflowStatus.pendingApproval ||
            wfStatus == BookingWorkflowStatus.approvedAwaitingPayment)) {
      wfStatus = BookingWorkflowStatus.paymentUnderReview;
    }

    final totalPgk = _toDouble(json['total_pgk'], acc.pricePerNight * 2);
    final paymentsList = (json['payments'] as List?) ?? [];
    String? latestProofFile;
    if (paymentsList.isNotEmpty) {
      final firstPay = paymentsList.first as Map<String, dynamic>;
      latestProofFile = firstPay['proof_file_name']?.toString();
    }

    final folioRaw = (json['folio_entries'] as List?) ?? [];
    final folioItems = folioRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return FolioLineItem(
        id: (m['id'] ?? 'FOL').toString(),
        entryType: (m['entry_type'] ?? 'room_charge').toString(),
        description: (m['description'] ?? '').toString(),
        amountPgk: _toDouble(m['amount_pgk'], 0),
        postedAt: _parseDate(m['posted_at']),
        postedBy: (m['posted_by'] ?? 'FTH PMS').toString(),
      );
    }).toList();

    final invoicesRaw = (json['invoices'] as List?) ?? [];
    InvoiceDocument? invoiceDoc;
    if (invoicesRaw.isNotEmpty) {
      final inv = invoicesRaw.first as Map<String, dynamic>;
      invoiceDoc = InvoiceDocument(
        invoiceNumber: (inv['invoice_number'] ?? '').toString(),
        bookingReference:
            (inv['booking_reference'] ?? json['reference'] ?? '').toString(),
        issuedDate: _parseDate(inv['issued_at']),
        totalAmountPgk: _toDouble(
          inv['total_gst_inclusive_pgk'],
          totalPgk,
        ),
        paidAmountPgk: _toDouble(inv['amount_paid_pgk'], 0),
        balanceDuePgk: _toDouble(inv['balance_due_pgk'], totalPgk),
        status: (inv['status'] ?? 'issued').toString(),
      );
    }

    final receiptsRaw = (json['receipts'] as List?) ?? [];
    final receiptDocs = receiptsRaw.map((e) {
      final r = e as Map<String, dynamic>;
      return PaymentReceiptDocument(
        receiptNumber: (r['receipt_number'] ?? '').toString(),
        bookingReference:
            (r['booking_reference'] ?? json['reference'] ?? '').toString(),
        verifiedAt: _parseDate(r['verified_at']),
        amountPgk: _toDouble(r['amount_pgk'], 0),
        paymentMethod: (r['payment_method'] ?? 'Bank Transfer').toString(),
        bankReference: (r['bank_reference'] ?? 'Verified').toString(),
        verifiedBy: (r['verified_by'] ?? 'FTH Accounts').toString(),
      );
    }).toList();

    return Booking(
      id: (json['reference'] ?? json['id'] ?? '').toString(),
      accommodation: acc,
      checkInDate: _parseDate(json['check_in']),
      checkOutDate: _parseDate(
        json['check_out'],
        fallback: DateTime.now().add(const Duration(days: 2)),
      ),
      adults: _toInt(json['adults'], 2),
      children: _toInt(json['children'], 0),
      roomsCount: _toInt(json['rooms_count'], 1),
      guestName: (json['guest_name'] ?? 'Guest').toString(),
      guestEmail: (json['guest_email'] ?? '').toString(),
      guestPhone: (json['guest_phone'] ?? '').toString(),
      companyOrOrganization: json['company_organization']?.toString(),
      ratePlanCode:
          (json['rate_plan_code'] ?? 'STANDARD').toString().toUpperCase(),
      ratePlanName:
          (json['rate_plan_name'] ?? 'Standard Rate Plan').toString(),
      promoCode: json['promo_code']?.toString(),
      requestAirportShuttle: json['transfer_required'] == true,
      flightNumber: json['flight_number']?.toString(),
      flightArrivalTime: json['arrival_eta']?.toString(),
      specialRequests: json['special_requests']?.toString(),
      totalPrice: totalPgk,
      discountAmountPgk: _toDouble(json['discount_pgk'], 0.0),
      gstAmount: double.parse((totalPgk / 11).toStringAsFixed(2)),
      amountPaidPgk: _toDouble(json['amount_paid_pgk'], 0.0),
      status: wfStatus.shortLabel,
      workflowStatus: wfStatus,
      assignedRoomNumber: json['assigned_room_number']?.toString(),
      paymentProofFileName: latestProofFile,
      paymentMethodSelected:
          (json['payment_method_choice'] ?? 'Bank Transfer (BSP)').toString(),
      folioEntries: folioItems,
      invoice: invoiceDoc,
      receipts: receiptDocs,
      createdAt: _parseDate(json['created_at']),
    );
  }

  static UserProfile mapGuestProfile(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      name: (json['full_name'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }

  static NotificationItem mapNotification(Map<String, dynamic> json) {
    final type = (json['type'] ?? '').toString();
    IconData icon = Icons.notifications_active_outlined;
    Color color = const Color(0xFF0F4C3A);
    if (type.contains('verified') || type.contains('confirmed')) {
      icon = Icons.verified_rounded;
      color = const Color(0xFF10B981);
    } else if (type.contains('pending') || type.contains('awaiting')) {
      icon = Icons.account_balance_rounded;
      color = const Color(0xFFD4AF37);
    }

    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'FTH Notification').toString(),
      message: (json['message'] ?? '').toString(),
      timestamp: _parseDate(json['timestamp']),
      icon: icon,
      iconColor: color,
      isRead: json['is_read'] == true,
    );
  }

  static StaffMemberModel mapStaffMember(Map<String, dynamic> json) {
    final roleKey = (json['role'] ?? 'front_desk').toString();
    final role = StaffRole.fromKey(roleKey);
    final permsRaw = (json['effective_permissions'] as List?) ?? [];

    return StaffMemberModel(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '+675 7135 8804').toString(),
      role: role,
      assignedEstate: (json['assigned_estate'] ?? 'All Estates').toString(),
      isActive: json['is_active'] != false,
      invitationStatus: (json['invitation_status'] ?? 'active').toString(),
      invitationExpiresAt: json['invitation_expires_at'] != null
          ? _parseDate(json['invitation_expires_at'])
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? _parseDate(json['last_login_at'])
          : null,
      effectivePermissions: permsRaw.isNotEmpty
          ? permsRaw.map((e) => e.toString()).toList()
          : role.defaultPermissions,
    );
  }

  static PaymentRecordModel mapPaymentRecord(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: (json['id'] ?? '').toString(),
      bookingReference: (json['booking_reference'] ?? '').toString(),
      guestName: (json['guest_name'] ?? 'Guest').toString(),
      categoryName: (json['category_name'] ?? 'Serviced Apartment').toString(),
      amountPgk: _toDouble(json['amount_pgk'], 0.0),
      paymentMethod: (json['payment_method'] ?? 'Bank Transfer').toString(),
      referenceNumber: (json['reference_number'] ?? '').toString(),
      proofFileName: (json['proof_file_name'] ?? 'Payment_Proof.pdf').toString(),
      status: (json['status'] ?? 'pending_verification').toString(),
      submittedAt: _parseDate(json['submitted_at']),
      verifiedBy: json['verified_by']?.toString(),
      verifiedAt: json['verified_at'] != null
          ? _parseDate(json['verified_at'])
          : null,
      receiptNumber: json['receipt_number']?.toString(),
    );
  }

  static RefundRequestModel mapRefundRecord(Map<String, dynamic> json) {
    return RefundRequestModel(
      id: (json['id'] ?? '').toString(),
      bookingReference: (json['booking_reference'] ?? '').toString(),
      guestName: (json['guest_name'] ?? 'Guest').toString(),
      paidAmountPgk: _toDouble(json['original_paid_pgk'], 0.0),
      backendCalculatedRefundPgk: _toDouble(json['refundable_amount_pgk'], 0.0),
      refundPercentage: _toInt(json['refund_percentage'], 70),
      hoursBeforeCheckIn: _toInt(json['hours_before_check_in'], 72),
      policyExplanation:
          (json['policy_applied'] ??
                  '48-Hour / 70% Refund Policy (Calculated by FolioService)')
              .toString(),
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? 'pending_review').toString(),
      requestedAt: _parseDate(json['requested_at']),
    );
  }

  static HousekeepingTaskModel mapHousekeepingTask(Map<String, dynamic> json) {
    return HousekeepingTaskModel(
      id: (json['id'] ?? '').toString(),
      roomNumber: (json['room_number'] ?? '').toString(),
      estateName: (json['estate_name'] ?? 'Kennedy Estate').toString(),
      unitType: (json['category_name'] ?? 'Serviced Apartment').toString(),
      taskType: (json['task_type'] ?? 'Daily Room Turnover').toString(),
      roomStatus: (json['room_status'] ?? 'clean').toString(),
      priority: (json['priority'] ?? 'normal').toString(),
      assignedTo: (json['assigned_to'] ?? 'FTH Housekeeping').toString(),
      notes: (json['notes'] ?? 'Standard inspection & sanitization').toString(),
      scheduledAt: DateTime.now(),
    );
  }

  static MaintenanceTicketModel mapMaintenanceTicket(
    Map<String, dynamic> json,
  ) {
    return MaintenanceTicketModel(
      id: (json['id'] ?? '').toString(),
      ticketNumber: (json['ticket_number'] ?? json['id'] ?? 'MNT').toString(),
      roomNumber: (json['room_number'] ?? '').toString(),
      estateName: (json['estate_name'] ?? 'Kennedy Estate').toString(),
      category: (json['category'] ?? 'General').toString(),
      title: (json['title'] ?? 'Maintenance Request').toString(),
      description: (json['description'] ?? '').toString(),
      priority: (json['priority'] ?? 'normal').toString(),
      status: (json['status'] ?? 'open').toString(),
      reportedBy: (json['reported_by'] ?? 'FTH Staff').toString(),
      assignedTo: (json['assigned_to'] ?? 'Maintenance Tech').toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static AirportTransferModel mapTransfer(Map<String, dynamic> json) {
    final dir = (json['direction'] ?? 'arrival_pickup').toString();
    return AirportTransferModel(
      id: (json['id'] ?? '').toString(),
      bookingReference: (json['booking_reference'] ?? 'N/A').toString(),
      guestName: (json['guest_name'] ?? 'Guest').toString(),
      guestPhone: (json['guest_phone'] ?? '+675 7135 8804').toString(),
      passengers: _toInt(json['passengers'], 2),
      transferType: dir.contains('drop')
          ? 'Airport Drop-off (Departure)'
          : 'Airport Pickup (Arrival)',
      flightNumber: (json['flight_number'] ?? 'PX Flight').toString(),
      estateDestination: (json['estate_name'] ?? 'Kennedy Estate').toString(),
      scheduledDateTime: _parseDate(json['scheduled_time']),
      driverAssigned: (json['driver_name'] ?? 'FTH Shuttle Driver').toString(),
      vehicleLabel: (json['vehicle_plate'] ?? 'FTH HiAce Shuttle').toString(),
      status: (json['status'] ?? 'scheduled').toString(),
    );
  }

  static GuestServiceRequestModel mapGuestServiceRequest(
    Map<String, dynamic> json,
  ) {
    return GuestServiceRequestModel(
      id: (json['id'] ?? '').toString(),
      bookingReference: (json['booking_reference'] ?? 'N/A').toString(),
      guestName: (json['guest_name'] ?? 'Guest').toString(),
      roomNumber: (json['room_number'] ?? 'Unassigned').toString(),
      estateName: (json['estate_name'] ?? 'Kennedy Estate').toString(),
      requestCategory: (json['request_category'] ?? 'Front Desk').toString(),
      subject: (json['subject'] ?? 'Stay Request').toString(),
      details: (json['details'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      requestedAt: _parseDate(json['requested_at']),
      staffResponseNote: json['staff_response_note']?.toString(),
    );
  }

  static String resolveCatalogImagePath(String rawPath, {String? fullUrl}) {
    final lower = rawPath.toLowerCase();
    const knownTokens = [
      'queen-bedroom',
      'spacious-lounge',
      '3bedroom-master',
      'private-bathroom',
      'equipped-kitchen',
      'safe-neighborhood',
      'balcony-views',
      'airport-shuttle',
      'hero-building',
      'about-interior',
      'living-dining',
      'serviced-apartments',
    ];

    for (final token in knownTokens) {
      if (lower.contains(token)) {
        return mapImagePathToAsset(rawPath);
      }
    }

    final candidate = (fullUrl != null && fullUrl.trim().isNotEmpty)
        ? fullUrl.trim()
        : rawPath.trim();

    if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
      return candidate;
    }

    if (candidate.startsWith('/')) {
      final apiUri = Uri.parse(ApiConfig.baseUrl);
      final origin = '${apiUri.scheme}://${apiUri.authority}';
      return '$origin$candidate';
    }

    return mapImagePathToAsset(rawPath);
  }

  static String mapImagePathToAsset(String rawPath) {
    final lower = rawPath.toLowerCase();
    if (lower.contains('queen-bedroom')) return AppAssets.fthQueenBedroom;
    if (lower.contains('spacious-lounge')) return AppAssets.fthSpaciousLounge;
    if (lower.contains('3bedroom-master')) {
      return AppAssets.fth3BedroomMasterEnsuite;
    }
    if (lower.contains('private-bathroom')) return AppAssets.fthPrivateBathroom;
    if (lower.contains('equipped-kitchen')) return AppAssets.fthEquippedKitchen;
    if (lower.contains('safe-neighborhood')) {
      return AppAssets.fthSafeNeighborhood;
    }
    if (lower.contains('balcony-views')) return AppAssets.fthBalconyViews;
    if (lower.contains('airport-shuttle')) return AppAssets.fthAirportShuttle;
    if (lower.contains('hero-building')) return AppAssets.fthHeroBuilding;
    if (lower.contains('about-interior')) return AppAssets.fthAboutInterior;
    if (lower.contains('living-dining')) return AppAssets.fthLivingDiningSuite;
    return AppAssets.fthServicedApartments;
  }

  static IconData _iconForAmenity(String label) {
    final l = label.toLowerCase();
    if (l.contains('shuttle') || l.contains('airport')) {
      return Icons.airport_shuttle_rounded;
    }
    if (l.contains('wifi') || l.contains('wi-fi')) return Icons.wifi_rounded;
    if (l.contains('kitchen') || l.contains('cooking')) {
      return Icons.kitchen_rounded;
    }
    if (l.contains('security')) return Icons.security_rounded;
    if (l.contains('laundry') || l.contains('washing')) {
      return Icons.local_laundry_service_rounded;
    }
    if (l.contains('tv') || l.contains('netflix')) return Icons.tv_rounded;
    if (l.contains('air-condition') || l.contains('ac')) {
      return Icons.ac_unit_rounded;
    }
    if (l.contains('parking')) return Icons.local_parking_rounded;
    return Icons.check_circle_outline_rounded;
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static int _toInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v != null) return int.tryParse(v.toString()) ?? fallback;
    return fallback;
  }

  static double _toDouble(dynamic v, double fallback) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v != null) return double.tryParse(v.toString()) ?? fallback;
    return fallback;
  }

  static DateTime _parseDate(dynamic v, {DateTime? fallback}) {
    if (v != null) {
      final parsed = DateTime.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    return fallback ?? DateTime.now();
  }
}
