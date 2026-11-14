// Represents operational entities in the existing FTH PMS backend (`F:\FTH`):
// - HousekeepingTask (`housekeeping_tasks`)
// - MaintenanceTicket (`maintenance_tickets`)
// - TransferRequest (`transfer_requests`)
// - GuestServiceRequest (`guest_requests`)
// - PaymentProofRecord (`payments`)
// - RefundRequestRecord (`refunds`)
// - DailySalesReportPreview & FrontDeskTakingsPreview (`ReportingService`)

class HousekeepingTaskModel {
  final String id;
  final String roomNumber;
  final String estateName;
  final String unitType;
  final String
  taskType; // 'Checkout Turnover', 'Stayover Service', 'Deep Clean', 'Pre-Arrival Inspection'
  final String
  roomStatus; // 'dirty', 'cleaning', 'clean', 'inspected', 'out_of_service'
  final String priority; // 'high', 'normal', 'low'
  final String assignedTo;
  final String? bookingReference;
  final String notes;
  final DateTime scheduledAt;

  const HousekeepingTaskModel({
    required this.id,
    required this.roomNumber,
    required this.estateName,
    required this.unitType,
    required this.taskType,
    required this.roomStatus,
    required this.priority,
    required this.assignedTo,
    this.bookingReference,
    required this.notes,
    required this.scheduledAt,
  });

  HousekeepingTaskModel copyWith({
    String? roomStatus,
    String? assignedTo,
    String? notes,
  }) {
    return HousekeepingTaskModel(
      id: id,
      roomNumber: roomNumber,
      estateName: estateName,
      unitType: unitType,
      taskType: taskType,
      roomStatus: roomStatus ?? this.roomStatus,
      priority: priority,
      assignedTo: assignedTo ?? this.assignedTo,
      bookingReference: bookingReference,
      notes: notes ?? this.notes,
      scheduledAt: scheduledAt,
    );
  }
}

class MaintenanceTicketModel {
  final String id;
  final String ticketNumber; // e.g. MNT-2026-019
  final String roomNumber;
  final String estateName;
  final String
  category; // 'Air Conditioning', 'Plumbing', 'Electrical', 'Kitchen Appliance', 'General'
  final String title;
  final String description;
  final String priority; // 'urgent', 'high', 'normal', 'low'
  final String status; // 'open', 'in_progress', 'resolved'
  final String reportedBy;
  final String assignedTo;
  final String? attachmentFileName;
  final DateTime createdAt;

  const MaintenanceTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.roomNumber,
    required this.estateName,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.reportedBy,
    required this.assignedTo,
    this.attachmentFileName,
    required this.createdAt,
  });

  MaintenanceTicketModel copyWith({
    String? status,
    String? priority,
    String? assignedTo,
    String? attachmentFileName,
  }) {
    return MaintenanceTicketModel(
      id: id,
      ticketNumber: ticketNumber,
      roomNumber: roomNumber,
      estateName: estateName,
      category: category,
      title: title,
      description: description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      reportedBy: reportedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      attachmentFileName: attachmentFileName ?? this.attachmentFileName,
      createdAt: createdAt,
    );
  }
}

class AirportTransferModel {
  final String id;
  final String bookingReference;
  final String guestName;
  final String guestPhone;
  final int passengers;
  final String
  transferType; // 'Airport Pickup (Arrival)', 'Airport Drop-off (Departure)', 'Inter-Estate Transfer'
  final String flightNumber;
  final String estateDestination;
  final String? roomNumber;
  final DateTime scheduledDateTime;
  final String driverAssigned;
  final String vehicleLabel;
  final String status; // 'scheduled', 'en_route', 'completed', 'cancelled'
  final String? notes;

  const AirportTransferModel({
    required this.id,
    required this.bookingReference,
    required this.guestName,
    required this.guestPhone,
    required this.passengers,
    required this.transferType,
    required this.flightNumber,
    required this.estateDestination,
    this.roomNumber,
    required this.scheduledDateTime,
    required this.driverAssigned,
    this.vehicleLabel = 'FTH Shuttle HiAce (24-Seater / Coaster)',
    required this.status,
    this.notes,
  });

  AirportTransferModel copyWith({
    String? status,
    String? driverAssigned,
    String? notes,
  }) {
    return AirportTransferModel(
      id: id,
      bookingReference: bookingReference,
      guestName: guestName,
      guestPhone: guestPhone,
      passengers: passengers,
      transferType: transferType,
      flightNumber: flightNumber,
      estateDestination: estateDestination,
      roomNumber: roomNumber,
      scheduledDateTime: scheduledDateTime,
      driverAssigned: driverAssigned ?? this.driverAssigned,
      vehicleLabel: vehicleLabel,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class GuestServiceRequestModel {
  final String id;
  final String bookingReference;
  final String guestName;
  final String roomNumber;
  final String estateName;
  final String
  requestCategory; // 'Housekeeping', 'Airport Shuttle', 'Maintenance', 'Extra Amenities', 'Front Desk Inquiry'
  final String subject;
  final String details;
  final String status; // 'pending', 'in_progress', 'completed'
  final DateTime requestedAt;
  final String? staffResponseNote;

  const GuestServiceRequestModel({
    required this.id,
    required this.bookingReference,
    required this.guestName,
    required this.roomNumber,
    required this.estateName,
    required this.requestCategory,
    required this.subject,
    required this.details,
    required this.status,
    required this.requestedAt,
    this.staffResponseNote,
  });

  GuestServiceRequestModel copyWith({
    String? status,
    String? staffResponseNote,
  }) {
    return GuestServiceRequestModel(
      id: id,
      bookingReference: bookingReference,
      guestName: guestName,
      roomNumber: roomNumber,
      estateName: estateName,
      requestCategory: requestCategory,
      subject: subject,
      details: details,
      status: status ?? this.status,
      requestedAt: requestedAt,
      staffResponseNote: staffResponseNote ?? this.staffResponseNote,
    );
  }
}

class PaymentRecordModel {
  final String id;
  final String bookingReference;
  final String guestName;
  final String categoryName;
  final double amountPgk;
  final String
  paymentMethod; // 'Bank Transfer (BSP)', 'Kina Bank EFTPOS', 'Cash', 'Corporate Account'
  final String referenceNumber;
  final String proofFileName;
  final String status; // 'pending_verification', 'verified', 'rejected'
  final DateTime submittedAt;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? receiptNumber;

  const PaymentRecordModel({
    required this.id,
    required this.bookingReference,
    required this.guestName,
    required this.categoryName,
    required this.amountPgk,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.proofFileName,
    required this.status,
    required this.submittedAt,
    this.verifiedBy,
    this.verifiedAt,
    this.receiptNumber,
  });

  PaymentRecordModel copyWith({
    String? status,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? receiptNumber,
  }) {
    return PaymentRecordModel(
      id: id,
      bookingReference: bookingReference,
      guestName: guestName,
      categoryName: categoryName,
      amountPgk: amountPgk,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      proofFileName: proofFileName,
      status: status ?? this.status,
      submittedAt: submittedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      receiptNumber: receiptNumber ?? this.receiptNumber,
    );
  }
}

class RefundRequestModel {
  final String id;
  final String bookingReference;
  final String guestName;
  final double paidAmountPgk;
  final double backendCalculatedRefundPgk;
  final int refundPercentage; // 70% (>=48h before check-in) or 0% (<48h)
  final int hoursBeforeCheckIn;
  final String policyExplanation;
  final String reason;
  final String status; // 'pending_review', 'approved', 'processed', 'rejected'
  final DateTime requestedAt;

  const RefundRequestModel({
    required this.id,
    required this.bookingReference,
    required this.guestName,
    required this.paidAmountPgk,
    required this.backendCalculatedRefundPgk,
    required this.refundPercentage,
    required this.hoursBeforeCheckIn,
    required this.policyExplanation,
    required this.reason,
    required this.status,
    required this.requestedAt,
  });

  RefundRequestModel copyWith({String? status}) {
    return RefundRequestModel(
      id: id,
      bookingReference: bookingReference,
      guestName: guestName,
      paidAmountPgk: paidAmountPgk,
      backendCalculatedRefundPgk: backendCalculatedRefundPgk,
      refundPercentage: refundPercentage,
      hoursBeforeCheckIn: hoursBeforeCheckIn,
      policyExplanation: policyExplanation,
      reason: reason,
      status: status ?? this.status,
      requestedAt: requestedAt,
    );
  }
}
