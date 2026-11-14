import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Build-time API URL configuration.
  /// Pass `--dart-define=FTH_API_URL=https://fth.demo-kraiptech.com/api/v1`
  /// (or `FTH_API_BASE_URL`) to override at build time.
  static const String _definedApiUrl = String.fromEnvironment('FTH_API_URL');
  static const String _definedApiBaseUrl =
      String.fromEnvironment('FTH_API_BASE_URL');

  static const String localDevUrl = 'https://fth.demo-kraiptech.com/api/v1';
  static const String productionDefaultUrl =
      'https://fth.demo-kraiptech.com/api/v1';

  static String get baseUrl {
    if (_definedApiUrl.isNotEmpty) return _definedApiUrl;
    if (_definedApiBaseUrl.isNotEmpty) return _definedApiBaseUrl;
    if (!kReleaseMode) return localDevUrl;
    return productionDefaultUrl;
  }

  static String get originUrl {
    final uri = Uri.parse(baseUrl);
    if (uri.hasScheme && uri.authority.isNotEmpty) {
      return '${uri.scheme}://${uri.authority}';
    }
    return 'https://fth.demo-kraiptech.com';
  }

  static bool get hasExplicitProductionUrl =>
      _definedApiUrl.isNotEmpty || _definedApiBaseUrl.isNotEmpty;

  /// Production mode: connected to live Laravel `/api/v1/` endpoints (Zero mock fallbacks).
  static const bool useMockRepositories = false;

  /// Cloudbeds integration status notice (Always disabled/simulation per business rules).
  static const bool isCloudbedsLive = false;
  static const String cloudbedsModeLabel = 'Simulation / Disabled';

  // Official Laravel API v1 Endpoint Contracts
  static const String publicBootstrap = '/public/bootstrap';
  static const String estatesEndpoint = '/public/estates';
  static const String accommodationsEndpoint = '/public/apartments';
  static const String ratePlansEndpoint = '/public/rate-plans';
  static const String pricingQuoteEndpoint = '/public/pricing/quote';
  static const String contactEndpoint = '/public/contact';

  static const String authGuestLogin = '/guest/auth/login';
  static const String authGuestLookup = '/guest/auth/lookup';
  static const String authGuestRegister = '/guest/auth/register';
  static const String authGuestLogout = '/guest/auth/logout';
  static const String guestProfileEndpoint = '/guest/profile';
  static const String guestBookingsEndpoint = '/guest/bookings';
  static const String guestRequestsEndpoint = '/guest/requests';
  static const String guestCheckinEndpoint = '/guest/checkin';
  static const String guestIdDocumentsEndpoint = '/guest/id-documents';
  static const String guestNotificationsEndpoint = '/guest/notifications';

  static const String authStaffLogin = '/staff/auth/login';
  static const String authStaffLogout = '/staff/auth/logout';
  static const String staffMeEndpoint = '/staff/me';
  static const String staffDashboardEndpoint = '/staff/dashboard';
  static const String staffCalendarEndpoint = '/staff/calendar';
  static const String staffBookingsEndpoint = '/staff/bookings';
  static const String staffReportsEndpoint = '/staff/reports';
  static const String staffUsersEndpoint = '/staff/users';
}
