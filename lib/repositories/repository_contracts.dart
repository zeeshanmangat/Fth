import '../data/models/accommodation.dart';
import '../data/models/booking.dart';
import '../models/estate_model.dart';
import '../models/operational_models.dart';
import '../models/rate_plan_model.dart';
import '../models/staff_role_model.dart';

/// Repository Contract for Estates, Official 9 Apartment Categories, 35 Physical Units, and 7 Rate Plans.
/// Implemented by `MockCatalogRepository` (Phase 1 UI) and `ApiCatalogRepository` (Future Laravel API Phase).
abstract class CatalogRepositoryContract {
  List<EstateModel> getEstates();
  List<Accommodation> getApartmentCategories();
  List<PhysicalRoomUnit> getPhysicalUnits();
  List<RatePlanModel> getRatePlans();
  Map<String, String> getOfficialBankDetails();

  /// Generates a preview pricing quote matching `PricingEngineService::calculateBookingPrice()`.
  PricingQuotePreview buildPreviewQuote({
    required Accommodation category,
    required RatePlanModel ratePlan,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    int roomsCount = 1,
    String? promoCode,
  });
}

/// Repository Contract for Guest Booking Requests, Payment Proofs, Online Check-In, and Service Requests.
abstract class GuestBookingRepositoryContract {
  List<Booking> getInitialGuestBookings(List<Accommodation> catalog);

  Booking createBookingRequest({
    required Accommodation accommodation,
    required RatePlanModel ratePlan,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int adults,
    required int children,
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    String? companyOrOrganization,
    String? promoCode,
    required bool requestAirportShuttle,
    String? flightNumber,
    String? flightArrivalTime,
    String? specialRequests,
    required PricingQuotePreview quote,
  });
}

/// Repository Contract for Staff PMS Dashboard, Calendar, Reservations, Accounts, Housekeeping,
/// Maintenance, Transfers, Reports, and Staff Invitations.
abstract class StaffPmsRepositoryContract {
  List<Booking> getInitialStaffBookings(List<Accommodation> catalog);
  List<HousekeepingTaskModel> getInitialHousekeepingTasks();
  List<MaintenanceTicketModel> getInitialMaintenanceTickets();
  List<AirportTransferModel> getInitialAirportTransfers();
  List<GuestServiceRequestModel> getInitialGuestServiceRequests();
  List<PaymentRecordModel> getInitialPaymentRecords();
  List<RefundRequestModel> getInitialRefundRequests();
  List<StaffMemberModel> getInitialStaffMembers();
}
