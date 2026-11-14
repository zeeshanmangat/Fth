import 'amenity.dart';

class Accommodation {
  final String id; // e.g. 'APT-01' .. 'APT-09'
  final String slug;
  final String title;
  final String categoryType;
  final String estateKey; // 'kennedy', 'venezia', 'grand-eden'
  final String estate; // e.g. 'Kennedy Estate — 7 Mile'
  final String estateAssignmentNote;
  final String locationArea;
  final String distanceToAirport;
  final double pricePerNight; // Provisional GST-inclusive PGK rate
  final double? altRatePgk;
  final String rateNote;
  final bool gstInclusive;
  final int maxAdults;
  final int maxChildren;
  final int maxGuests;
  final int bedrooms;
  final int bathrooms;
  final int beds;
  final String floorLevel;
  final String view;
  final String bedConfiguration;
  final double sizeSqm;
  final String mainImage;
  final List<String> galleryImages;
  final String shortDescription;
  final String description;
  final List<Amenity> amenities;
  final List<String> amenityLabels;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final bool isPopular;
  final String checkInTime;
  final String checkOutTime;
  final String cancellationPolicy;
  final int? availableUnits;

  const Accommodation({
    required this.id,
    this.slug = '',
    required this.title,
    this.categoryType = 'Serviced Apartment',
    this.estateKey = 'kennedy',
    required this.estate,
    this.estateAssignmentNote =
        'Primary Estate Assignment (Confirmed upon reservation)',
    required this.locationArea,
    this.distanceToAirport = '',
    required this.pricePerNight,
    this.altRatePgk,
    this.rateNote =
        'Guide Rate GST-Incl. (Confirmed by FTH Reservations upon quote)',
    this.gstInclusive = true,
    this.maxAdults = 2,
    this.maxChildren = 1,
    required this.maxGuests,
    required this.bedrooms,
    required this.bathrooms,
    required this.beds,
    this.floorLevel = 'Ground / Level 1',
    this.view = 'Estate Courtyard View',
    required this.bedConfiguration,
    required this.sizeSqm,
    required this.mainImage,
    required this.galleryImages,
    this.shortDescription = '',
    required this.description,
    required this.amenities,
    this.amenityLabels = const [],
    this.rating = 4.8,
    this.reviewCount = 42,
    this.isFeatured = false,
    this.isPopular = false,
    this.checkInTime = '1:00 PM',
    this.checkOutTime = '10:00 AM',
    this.cancellationPolicy =
        'Cancellation 48 or more hours before check-in: 70% refund (30% cancellation fee). Cancellation within 48 hours of check-in: no refund. No refund for no-show guests and bookings are non-transferable.',
    this.availableUnits,
  });
}
