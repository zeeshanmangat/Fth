import '../../repositories/mock_booking_and_pms_repository.dart';
import '../models/booking.dart';
import 'accommodation_repository.dart';

class BookingRepository {
  static final MockBookingAndPmsRepository _repo =
      MockBookingAndPmsRepository();

  static List<Booking> getInitialBookings() {
    final catalog = AccommodationRepository.getAccommodations();
    return _repo.getInitialGuestBookings(catalog);
  }
}
