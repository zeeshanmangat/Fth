/// Represents the 3 official FTH Estates from `OfficialContentService::getEstates()`
/// in `F:\FTH\app\Services\OfficialContentService.php`.
class EstateModel {
  final int id;
  final String key;
  final String slug;
  final String name;
  final String location;
  final String address;
  final String distanceAirport;
  final String badge;
  final String image;
  final List<String> gallery;
  final String description;
  final String placeholderNote;
  final List<String> highlights;
  final List<String> sampleCategories;
  final int totalPhysicalUnits;

  const EstateModel({
    required this.id,
    required this.key,
    required this.slug,
    required this.name,
    required this.location,
    required this.address,
    required this.distanceAirport,
    required this.badge,
    required this.image,
    required this.gallery,
    required this.description,
    required this.placeholderNote,
    required this.highlights,
    required this.sampleCategories,
    required this.totalPhysicalUnits,
  });
}

/// Represents a physical apartment unit from the 35 official units in
/// `OfficialContentService::getOfficialUnits()`.
class PhysicalRoomUnit {
  final int rowNumber;
  final String roomNumber;
  final String estateKey;
  final String estateLocation;
  final String unitType;
  final String categorySlug;
  final String floorLevel;
  final double standardRatePgk;
  final String status; // clean, dirty, inspected, occupied, out_of_service

  const PhysicalRoomUnit({
    required this.rowNumber,
    required this.roomNumber,
    required this.estateKey,
    required this.estateLocation,
    required this.unitType,
    required this.categorySlug,
    required this.floorLevel,
    required this.standardRatePgk,
    this.status = 'clean',
  });
}
