import '../../models/estate_model.dart';
import '../../models/rate_plan_model.dart';
import '../../repositories/mock_catalog_repository.dart';
import '../models/accommodation.dart';

class AccommodationRepository {
  static final MockCatalogRepository _repo = MockCatalogRepository();

  static List<Accommodation> getAccommodations() =>
      _repo.getApartmentCategories();

  static List<EstateModel> getEstateModels() => _repo.getEstates();

  static List<RatePlanModel> getRatePlans() => _repo.getRatePlans();

  static List<String> getEstates() {
    return [
      'All Estates',
      'Kennedy Estate — 7 Mile',
      'Venezia Estate — 6 Mile',
      'Grand Eden Estate — 8 Mile',
    ];
  }
}
