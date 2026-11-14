import 'accommodation.dart';

/// Official 8 Booking Statuses matching `F:\FTH\app\Models\Booking.php`.
enum BookingWorkflowStatus {
  pendingApproval(
    key: 'pending_approval',
    label: 'Pending Approval',
    shortLabel: 'Pending Approval',
    description:
        'Provisional booking request received. Awaiting FTH Reservations review & availability approval.',
  ),
  approvedAwaitingPayment(
    key: 'approved_awaiting_payment',
    label: 'Approved — Awaiting Payment',
    shortLabel: 'Awaiting Payment',
    description:
        'Approved by FTH Reservations. Please complete bank transfer or EFTPOS payment and upload your payment proof.',
  ),
  paymentUnderReview(
    key: 'payment_under_review',
    label: 'Payment Proof Under Review',
    shortLabel: 'Payment Review',
    description:
        'Payment remittance proof uploaded. Awaiting verification by FTH Accounts before reservation confirmation.',
  ),
  confirmed(
    key: 'confirmed',
    label: 'Confirmed',
    shortLabel: 'Confirmed',
    description:
        'Payment verified by FTH Accounts. Your apartment reservation and airport shuttle are confirmed.',
  ),
  checkedIn(
    key: 'checked_in',
    label: 'Checked In — In House',
    shortLabel: 'Checked In',
    description:
        'Welcome to Family Transit Home! Digital arrival guide and in-stay service requests are active.',
  ),
  checkedOut(
    key: 'checked_out',
    label: 'Checked Out — Completed',
    shortLabel: 'Checked Out',
    description:
        'Thank you for staying with Family Transit Home in Port Moresby.',
  ),
  cancelled(
    key: 'cancelled',
    label: 'Cancelled',
    shortLabel: 'Cancelled',
    description: 'This booking request or reservation has been cancelled.',
  ),
  rejected(
    key: 'rejected',
    label: 'Declined / Unavailable',
    shortLabel: 'Declined',
    description:
        'Requested dates or category could not be accommodated. Please review alternative options.',
  );

  final String key;
  final String label;
  final String shortLabel;
  final String description;

  const BookingWorkflowStatus({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.description,
  });

  bool get isConfirmedOrCheckedIn =>
      this == BookingWorkflowStatus.confirmed ||
      this == BookingWorkflowStatus.checkedIn;

  static BookingWorkflowStatus fromKey(String raw) {
    final normalized = raw.toLowerCase().trim();
    for (final s in BookingWorkflowStatus.values) {
      if (s.key == normalized ||
          s.label.toLowerCase() == normalized ||
          s.shortLabel.toLowerCase() == normalized) {
        return s;
      }
    }
    if (normalized.contains('pending')) {
      return BookingWorkflowStatus.pendingApproval;
    }
    if (normalized.contains('awaiting')) {
      return BookingWorkflowStatus.approvedAwaitingPayment;
    }
    if (normalized.contains('review')) {
      return BookingWorkflowStatus.paymentUnderReview;
    }
    if (normalized.contains('check_in') || normalized.contains('checked in')) {
      return BookingWorkflowStatus.checkedIn;
    }
    if (normalized.contains('check_out') ||
        normalized.contains('checked out') ||
        normalized.contains('completed')) {
      return BookingWorkflowStatus.checkedOut;
    }
    if (normalized.contains('cancel')) {
      return BookingWorkflowStatus.cancelled;
    }
    if (normalized.contains('confirm')) {
      return BookingWorkflowStatus.confirmed;
    }
    return BookingWorkflowStatus.pendingApproval;
  }
}

class FolioLineItem {
  final String id;
  final String
  entryType; // 'room_charge', 'extra_charge', 'adjustment', 'payment', 'refund'
  final String description;
  final double amountPgk; // Positive for charges, negative for payments/credits
  final DateTime postedAt;
  final String postedBy;

  const FolioLineItem({
    required this.id,
    required this.entryType,
    required this.description,
    required this.amountPgk,
    required this.postedAt,
    required this.postedBy,
  });
}

class InvoiceDocument {
  final String invoiceNumber; // e.g. FTH-INV-2026-00042
  final String bookingReference;
  final DateTime issuedDate;
  final double totalAmountPgk;
  final double paidAmountPgk;
  final double balanceDuePgk;
  final String status; // 'issued', 'paid', 'partially_paid'

  const InvoiceDocument({
    required this.invoiceNumber,
    required this.bookingReference,
    required this.issuedDate,
    required this.totalAmountPgk,
    required this.paidAmountPgk,
    required this.balanceDuePgk,
    required this.status,
  });
}

class PaymentReceiptDocument {
  final String receiptNumber; // e.g. FTH-RCP-2026-00038
  final String bookingReference;
  final DateTime verifiedAt;
  final double amountPgk;
  final String
  paymentMethod; // 'Bank Transfer (BSP)', 'EFTPOS', 'Cash', 'Corporate Account'
  final String bankReference;
  final String verifiedBy;

  const PaymentReceiptDocument({
    required this.receiptNumber,
    required this.bookingReference,
    required this.verifiedAt,
    required this.amountPgk,
    required this.paymentMethod,
    required this.bankReference,
    required this.verifiedBy,
  });
}

class Booking {
  final String id; // Booking Reference e.g. FTH-2026-0841
  final Accommodation accommodation;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int adults;
  final int children;
  final int roomsCount;
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final String guestNationality;
  final String? companyOrOrganization;
  final String ratePlanCode;
  final String ratePlanName;
  final String? promoCode;
  final bool requestAirportShuttle;
  final String? flightNumber;
  final String? flightArrivalTime;
  final String? specialRequests;
  final double totalPrice; // GST-inclusive PGK total from PricingEngineService
  final double discountAmountPgk;
  final double
  gstAmount; // Included GST component (display only, never added on top)
  final double amountPaidPgk;
  final String status; // Human label
  final BookingWorkflowStatus workflowStatus;
  final String? assignedRoomNumber; // e.g. 'G2-6', '16G-2', '214'
  final String? paymentProofFileName;
  final String? paymentMethodSelected;
  final DateTime? paymentProofUploadedAt;
  final bool onlineCheckInCompleted;
  final List<FolioLineItem> folioEntries;
  final InvoiceDocument? invoice;
  final List<PaymentReceiptDocument> receipts;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.accommodation,
    required this.checkInDate,
    required this.checkOutDate,
    required this.adults,
    required this.children,
    this.roomsCount = 1,
    required this.guestName,
    required this.guestEmail,
    required this.guestPhone,
    this.guestNationality = 'Papua New Guinean',
    this.companyOrOrganization,
    this.ratePlanCode = 'STANDARD',
    this.ratePlanName = 'Standard Daily Rate',
    this.promoCode,
    required this.requestAirportShuttle,
    this.flightNumber,
    this.flightArrivalTime,
    this.specialRequests,
    required this.totalPrice,
    this.discountAmountPgk = 0.0,
    required this.gstAmount,
    this.amountPaidPgk = 0.0,
    this.status = 'Pending Approval',
    this.workflowStatus = BookingWorkflowStatus.pendingApproval,
    this.assignedRoomNumber,
    this.paymentProofFileName,
    this.paymentMethodSelected = 'Bank Transfer (BSP)',
    this.paymentProofUploadedAt,
    this.onlineCheckInCompleted = false,
    this.folioEntries = const [],
    this.invoice,
    this.receipts = const [],
    required this.createdAt,
  });

  int get totalNights =>
      checkOutDate.difference(checkInDate).inDays.clamp(1, 90);
  int get totalGuests => adults + children;
  double get balanceDuePgk => (totalPrice - amountPaidPgk).clamp(0.0, 999999.0);

  Booking copyWith({
    String? status,
    BookingWorkflowStatus? workflowStatus,
    String? assignedRoomNumber,
    String? paymentProofFileName,
    String? paymentMethodSelected,
    DateTime? paymentProofUploadedAt,
    double? amountPaidPgk,
    bool? onlineCheckInCompleted,
    String? flightNumber,
    String? flightArrivalTime,
    List<FolioLineItem>? folioEntries,
    InvoiceDocument? invoice,
    List<PaymentReceiptDocument>? receipts,
  }) {
    return Booking(
      id: id,
      accommodation: accommodation,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      adults: adults,
      children: children,
      roomsCount: roomsCount,
      guestName: guestName,
      guestEmail: guestEmail,
      guestPhone: guestPhone,
      guestNationality: guestNationality,
      companyOrOrganization: companyOrOrganization,
      ratePlanCode: ratePlanCode,
      ratePlanName: ratePlanName,
      promoCode: promoCode,
      requestAirportShuttle: requestAirportShuttle,
      flightNumber: flightNumber ?? this.flightNumber,
      flightArrivalTime: flightArrivalTime ?? this.flightArrivalTime,
      specialRequests: specialRequests,
      totalPrice: totalPrice,
      discountAmountPgk: discountAmountPgk,
      gstAmount: gstAmount,
      amountPaidPgk: amountPaidPgk ?? this.amountPaidPgk,
      status: status ?? this.status,
      workflowStatus: workflowStatus ?? this.workflowStatus,
      assignedRoomNumber: assignedRoomNumber ?? this.assignedRoomNumber,
      paymentProofFileName: paymentProofFileName ?? this.paymentProofFileName,
      paymentMethodSelected:
          paymentMethodSelected ?? this.paymentMethodSelected,
      paymentProofUploadedAt:
          paymentProofUploadedAt ?? this.paymentProofUploadedAt,
      onlineCheckInCompleted:
          onlineCheckInCompleted ?? this.onlineCheckInCompleted,
      folioEntries: folioEntries ?? this.folioEntries,
      invoice: invoice ?? this.invoice,
      receipts: receipts ?? this.receipts,
      createdAt: createdAt,
    );
  }
}
