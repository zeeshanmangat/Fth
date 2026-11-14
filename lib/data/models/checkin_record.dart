class OnlineCheckinRecord {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String apartmentType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String companyOrAddress;
  final String? idDocumentName;
  final String? flightNumber;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  OnlineCheckinRecord({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.apartmentType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.companyOrAddress,
    this.idDocumentName,
    this.flightNumber,
    required this.paymentMethod,
    this.status = 'Verified (Demo)',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
