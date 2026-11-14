/// Represents the 7 official rate plans from `F:\FTH\app\Models\RatePlan.php`
/// and `RatePlanSeeder.php`, plus client rate plan display labels.
class RatePlanModel {
  final String code;
  final String name;
  final String shortBadge;
  final String description;
  final int minNights;
  final double previewDiscountPercent;
  final String cancellationPolicyType;
  final bool isCorporate;

  const RatePlanModel({
    required this.code,
    required this.name,
    required this.shortBadge,
    required this.description,
    required this.minNights,
    this.previewDiscountPercent = 0.0,
    this.cancellationPolicyType = 'standard',
    this.isCorporate = false,
  });
}

/// Represents a structured pricing quote response matching Laravel's
/// `PricingEngineService::calculateBookingPrice()` output contract.
/// Note: All FTH rates are GST-inclusive. Flutter never adds +10% GST on top.
class PricingQuotePreview {
  final String roomCategoryId;
  final String roomCategoryName;
  final String ratePlanCode;
  final String ratePlanName;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int nights;
  final int roomsCount;
  final double baseNightlyRatePgk;
  final double effectiveNightlyRatePgk;
  final double grossTotalPgk;
  final double discountAmountPgk;
  final double totalPayablePgk;
  final double gstIncludedPgk;
  final String? promoCodeApplied;
  final bool gstInclusive;
  final bool isPreviewEstimate;
  final String pricingNotice;

  const PricingQuotePreview({
    required this.roomCategoryId,
    required this.roomCategoryName,
    required this.ratePlanCode,
    required this.ratePlanName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.roomsCount,
    required this.baseNightlyRatePgk,
    required this.effectiveNightlyRatePgk,
    required this.grossTotalPgk,
    required this.discountAmountPgk,
    required this.totalPayablePgk,
    this.gstIncludedPgk = 0.0,
    this.promoCodeApplied,
    this.gstInclusive = true,
    this.isPreviewEstimate = true,
    required this.pricingNotice,
  });
}
