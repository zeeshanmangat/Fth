import '../data/models/accommodation.dart';
import '../data/models/booking.dart';
import '../models/operational_models.dart';
import '../models/rate_plan_model.dart';
import '../models/staff_role_model.dart';
import 'repository_contracts.dart';

/// Mock implementation of [GuestBookingRepositoryContract] & [StaffPmsRepositoryContract].
/// Strictly adheres to FTH business rules:
/// - New guest bookings are created as `Pending Approval (Preview)` (never auto-confirmed).
/// - Payment proof upload sets status to `Payment Proof Under Review` (never auto-verified).
/// - All rates are GST-inclusive (no extra +10% GST added on top).
/// - Demo/preview data is explicitly labelled.
class MockBookingAndPmsRepository
    implements GuestBookingRepositoryContract, StaffPmsRepositoryContract {
  @override
  List<Booking> getInitialGuestBookings(List<Accommodation> catalog) {
    final apt02 = catalog.firstWhere(
      (a) => a.id == 'APT-02',
      orElse: () => catalog.first,
    );
    final apt01 = catalog.firstWhere(
      (a) => a.id == 'APT-01',
      orElse: () => catalog.first,
    );
    final apt09 = catalog.firstWhere(
      (a) => a.id == 'APT-09',
      orElse: () => catalog.first,
    );

    return [
      // 1. Confirmed booking with verified payment, invoice & receipt (shows full arrival guide)
      Booking(
        id: 'FTH-2026-0841',
        accommodation: apt02,
        checkInDate: DateTime.now().add(const Duration(days: 2)),
        checkOutDate: DateTime.now().add(const Duration(days: 5)),
        adults: 2,
        children: 1,
        roomsCount: 1,
        guestName: 'Mr. L. Damore',
        guestEmail: 'l.damore@2sonns.com.pg',
        guestPhone: '+675 7135 8804',
        guestNationality: 'Papua New Guinean',
        companyOrOrganization: '2 Sonns Enterprise Ltd',
        ratePlanCode: 'STANDARD',
        ratePlanName: 'Standard Daily',
        requestAirportShuttle: true,
        flightNumber: 'PX100 (Air Niugini)',
        flightArrivalTime: '14:30 PM',
        specialRequests:
            'Complimentary airport pickup from Jacksons International Terminal.',
        totalPrice: 1815.0, // 3 nights * K605 GST-Inclusive
        discountAmountPgk: 0.0,
        gstAmount: 165.0, // Included 1/11th GST component
        amountPaidPgk: 1815.0,
        status: 'Confirmed (Preview)',
        workflowStatus: BookingWorkflowStatus.confirmed,
        assignedRoomNumber: 'G2-6',
        paymentProofFileName: 'BSP_Remittance_FTH20260841.pdf',
        paymentMethodSelected: 'Bank Transfer (BSP)',
        paymentProofUploadedAt: DateTime.now().subtract(
          const Duration(days: 1, hours: 4),
        ),
        onlineCheckInCompleted: true,
        folioEntries: [
          FolioLineItem(
            id: 'FOL-01',
            entryType: 'room_charge',
            description:
                '3 Nights — Double-Bedroom Executive Apartment (K605/night GST-Incl.)',
            amountPgk: 1815.0,
            postedAt: DateTime.now().subtract(const Duration(days: 2)),
            postedBy: 'PricingEngineService',
          ),
          FolioLineItem(
            id: 'FOL-02',
            entryType: 'payment',
            description:
                'Verified Bank Transfer (BSP Ref: BSP-9928410) — Receipt FTH-RCP-2026-00038',
            amountPgk: -1815.0,
            postedAt: DateTime.now().subtract(const Duration(days: 1)),
            postedBy: 'Accounts Officer',
          ),
        ],
        invoice: InvoiceDocument(
          invoiceNumber: 'FTH-INV-2026-00042',
          bookingReference: 'FTH-2026-0841',
          issuedDate: DateTime.now().subtract(const Duration(days: 2)),
          totalAmountPgk: 1815.0,
          paidAmountPgk: 1815.0,
          balanceDuePgk: 0.0,
          status: 'paid',
        ),
        receipts: [
          PaymentReceiptDocument(
            receiptNumber: 'FTH-RCP-2026-00038',
            bookingReference: 'FTH-2026-0841',
            verifiedAt: DateTime.now().subtract(const Duration(days: 1)),
            amountPgk: 1815.0,
            paymentMethod: 'Bank Transfer (BSP)',
            bankReference: 'BSP-9928410',
            verifiedBy: 'Accounts Officer (Preview)',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),

      // 2. Approved — Awaiting Payment booking (demonstrates bank instructions & proof upload)
      Booking(
        id: 'FTH-2026-0854',
        accommodation: apt01,
        checkInDate: DateTime.now().add(const Duration(days: 9)),
        checkOutDate: DateTime.now().add(const Duration(days: 12)),
        adults: 2,
        children: 0,
        roomsCount: 1,
        guestName: 'Mr. L. Damore',
        guestEmail: 'l.damore@2sonns.com.pg',
        guestPhone: '+675 7135 8804',
        guestNationality: 'Papua New Guinean',
        companyOrOrganization: '2 Sonns Enterprise Ltd',
        ratePlanCode: 'CORPORATE',
        ratePlanName: 'Corporate Partner',
        requestAirportShuttle: true,
        flightNumber: 'CG850 (PNG Air)',
        flightArrivalTime: '11:15 AM',
        specialRequests: 'Ground floor preferred if available.',
        totalPrice: 1254.0, // 3 nights * K440 less 5% corporate preview
        discountAmountPgk: 66.0,
        gstAmount: 114.0,
        amountPaidPgk: 0.0,
        status: 'Approved — Awaiting Payment',
        workflowStatus: BookingWorkflowStatus.approvedAwaitingPayment,
        paymentMethodSelected: 'Bank Transfer (BSP)',
        folioEntries: [
          FolioLineItem(
            id: 'FOL-03',
            entryType: 'room_charge',
            description:
                '3 Nights — Single-Bedroom Executive Apartment (Corporate Partner Rate)',
            amountPgk: 1254.0,
            postedAt: DateTime.now().subtract(const Duration(hours: 8)),
            postedBy: 'PricingEngineService',
          ),
        ],
        invoice: InvoiceDocument(
          invoiceNumber: 'FTH-INV-2026-00049',
          bookingReference: 'FTH-2026-0854',
          issuedDate: DateTime.now().subtract(const Duration(hours: 8)),
          totalAmountPgk: 1254.0,
          paidAmountPgk: 0.0,
          balanceDuePgk: 1254.0,
          status: 'issued',
        ),
        receipts: const [],
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),

      // 3. Past Checked-Out Booking
      Booking(
        id: 'FTH-2026-0719',
        accommodation: apt09,
        checkInDate: DateTime.now().subtract(const Duration(days: 16)),
        checkOutDate: DateTime.now().subtract(const Duration(days: 13)),
        adults: 4,
        children: 1,
        roomsCount: 1,
        guestName: 'Mr. L. Damore',
        guestEmail: 'l.damore@2sonns.com.pg',
        guestPhone: '+675 7135 8804',
        companyOrOrganization: '2 Sonns Enterprise Ltd',
        ratePlanCode: 'STANDARD',
        ratePlanName: 'Standard Daily',
        requestAirportShuttle: true,
        flightNumber: 'PX101 (Air Niugini)',
        totalPrice: 2475.0, // 3 nights * K825 GST-Inclusive
        discountAmountPgk: 0.0,
        gstAmount: 212.73,
        amountPaidPgk: 2340.0,
        status: 'Checked Out — Completed',
        workflowStatus: BookingWorkflowStatus.checkedOut,
        assignedRoomNumber: 'S2-5',
        paymentProofFileName: 'BSP_Receipt_0719.pdf',
        onlineCheckInCompleted: true,
        invoice: InvoiceDocument(
          invoiceNumber: 'FTH-INV-2026-00018',
          bookingReference: 'FTH-2026-0719',
          issuedDate: DateTime.now().subtract(const Duration(days: 17)),
          totalAmountPgk: 2340.0,
          paidAmountPgk: 2340.0,
          balanceDuePgk: 0.0,
          status: 'paid',
        ),
        receipts: [
          PaymentReceiptDocument(
            receiptNumber: 'FTH-RCP-2026-00015',
            bookingReference: 'FTH-2026-0719',
            verifiedAt: DateTime.now().subtract(const Duration(days: 17)),
            amountPgk: 2340.0,
            paymentMethod: 'Bank Transfer (BSP)',
            bankReference: 'BSP-7741902',
            verifiedBy: 'Accounts Officer (Preview)',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
      ),
    ];
  }

  @override
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
  }) {
    final includedGst = double.parse(
      (quote.totalPayablePgk / 11.0).toStringAsFixed(2),
    );
    final refNumber =
        'FTH-2026-${(1000 + DateTime.now().millisecond * 8).clamp(1000, 9999)}';

    return Booking(
      id: refNumber,
      accommodation: accommodation,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      adults: adults,
      children: children,
      roomsCount: quote.roomsCount,
      guestName: guestName,
      guestEmail: guestEmail,
      guestPhone: guestPhone,
      companyOrOrganization: companyOrOrganization,
      ratePlanCode: ratePlan.code,
      ratePlanName: ratePlan.name,
      promoCode: promoCode,
      requestAirportShuttle: requestAirportShuttle,
      flightNumber: flightNumber,
      flightArrivalTime: flightArrivalTime,
      specialRequests: specialRequests,
      totalPrice: quote.totalPayablePgk,
      discountAmountPgk: quote.discountAmountPgk,
      gstAmount: includedGst,
      amountPaidPgk: 0.0,
      // Business Rule #10: A submitted booking request is NEVER automatically confirmed.
      status: BookingWorkflowStatus.pendingApproval.label,
      workflowStatus: BookingWorkflowStatus.pendingApproval,
      folioEntries: [
        FolioLineItem(
          id: 'FOL-${DateTime.now().millisecondsSinceEpoch}',
          entryType: 'room_charge',
          description:
              '${quote.nights} Nights — ${accommodation.title} (${ratePlan.name}, GST-Incl. Preview)',
          amountPgk: quote.totalPayablePgk,
          postedAt: DateTime.now(),
          postedBy: 'Provisional Quote Preview',
        ),
      ],
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Booking> getInitialStaffBookings(List<Accommodation> catalog) {
    final guestList = getInitialGuestBookings(catalog);
    final apt03 = catalog.firstWhere(
      (a) => a.id == 'APT-03',
      orElse: () => catalog.first,
    );
    final apt07 = catalog.firstWhere(
      (a) => a.id == 'APT-07',
      orElse: () => catalog.first,
    );
    final apt08 = catalog.firstWhere(
      (a) => a.id == 'APT-08',
      orElse: () => catalog.first,
    );

    return [
      // Pending Approval Request needing Staff review
      Booking(
        id: 'FTH-2026-0862',
        accommodation: apt03,
        checkInDate: DateTime.now().add(const Duration(days: 1)),
        checkOutDate: DateTime.now().add(const Duration(days: 4)),
        adults: 2,
        children: 0,
        guestName: 'Ms. Grace Kila',
        guestEmail: 'gkila@pngpower.com.pg',
        guestPhone: '+675 7201 4419',
        companyOrOrganization: 'PNG Power Limited',
        ratePlanCode: 'CORPORATE',
        ratePlanName: 'Corporate Partner',
        requestAirportShuttle: true,
        flightNumber: 'PX205 (Air Niugini)',
        flightArrivalTime: '15:10 PM',
        specialRequests: 'Requesting ground floor unit near reception.',
        totalPrice: 1155.0, // 3 nights * K385
        gstAmount: 105.0,
        status: BookingWorkflowStatus.pendingApproval.label,
        workflowStatus: BookingWorkflowStatus.pendingApproval,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),

      // Payment Proof Under Review needing Accounts verification
      Booking(
        id: 'FTH-2026-0859',
        accommodation: apt08,
        checkInDate: DateTime.now().add(const Duration(days: 1)),
        checkOutDate: DateTime.now().add(const Duration(days: 6)),
        adults: 2,
        children: 1,
        guestName: 'Dr. Samuel Vele',
        guestEmail: 's.vele@upng.ac.pg',
        guestPhone: '+675 7099 3182',
        companyOrOrganization: 'University of Papua New Guinea',
        ratePlanCode: 'STANDARD',
        ratePlanName: 'Standard Daily',
        requestAirportShuttle: true,
        flightNumber: 'PX108 (Air Niugini)',
        flightArrivalTime: '13:00 PM',
        totalPrice: 3025.0, // 5 nights * K605
        gstAmount: 275.0,
        status: BookingWorkflowStatus.paymentUnderReview.label,
        workflowStatus: BookingWorkflowStatus.paymentUnderReview,
        paymentProofFileName: 'BSP_Transfer_SVele_3025PGK.jpg',
        paymentMethodSelected: 'Bank Transfer (BSP)',
        paymentProofUploadedAt: DateTime.now().subtract(
          const Duration(minutes: 45),
        ),
        invoice: InvoiceDocument(
          invoiceNumber: 'FTH-INV-2026-00051',
          bookingReference: 'FTH-2026-0859',
          issuedDate: DateTime.now().subtract(const Duration(hours: 5)),
          totalAmountPgk: 3025.0,
          paidAmountPgk: 0.0,
          balanceDuePgk: 3025.0,
          status: 'issued',
        ),
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),

      // Checked-In Guest currently In-House (for Front Desk checkout & folio demo)
      Booking(
        id: 'FTH-2026-0835',
        accommodation: apt07,
        checkInDate: DateTime.now().subtract(const Duration(days: 2)),
        checkOutDate: DateTime.now().add(const Duration(days: 2)),
        adults: 4,
        children: 1,
        guestName: 'Mr. Peter Nali & Family',
        guestEmail: 'peter.nali@oktedi.com',
        guestPhone: '+675 7344 9012',
        companyOrOrganization: 'Ok Tedi Mining Limited',
        ratePlanCode: 'STANDARD',
        ratePlanName: 'Standard Daily',
        requestAirportShuttle: true,
        flightNumber: 'PX181',
        totalPrice: 2420.0, // 4 nights * K605
        gstAmount: 220.0,
        amountPaidPgk: 2420.0,
        status: BookingWorkflowStatus.checkedIn.label,
        workflowStatus: BookingWorkflowStatus.checkedIn,
        assignedRoomNumber: '22A',
        paymentProofFileName: 'Corporate_EFT_OkTedi.pdf',
        onlineCheckInCompleted: true,
        folioEntries: [
          FolioLineItem(
            id: 'FOL-835-1',
            entryType: 'room_charge',
            description:
                '4 Nights — 2-Bedroom, Ground Level, Parking View (Grand Eden — Unit 22A)',
            amountPgk: 2420.0,
            postedAt: DateTime.now().subtract(const Duration(days: 3)),
            postedBy: 'PricingEngineService',
          ),
          FolioLineItem(
            id: 'FOL-835-2',
            entryType: 'payment',
            description:
                'Verified Corporate Transfer — Receipt FTH-RCP-2026-00034',
            amountPgk: -2420.0,
            postedAt: DateTime.now().subtract(const Duration(days: 2)),
            postedBy: 'Accounts Officer',
          ),
        ],
        invoice: InvoiceDocument(
          invoiceNumber: 'FTH-INV-2026-00039',
          bookingReference: 'FTH-2026-0835',
          issuedDate: DateTime.now().subtract(const Duration(days: 3)),
          totalAmountPgk: 2420.0,
          paidAmountPgk: 2420.0,
          balanceDuePgk: 0.0,
          status: 'paid',
        ),
        receipts: [
          PaymentReceiptDocument(
            receiptNumber: 'FTH-RCP-2026-00034',
            bookingReference: 'FTH-2026-0835',
            verifiedAt: DateTime.now().subtract(const Duration(days: 2)),
            amountPgk: 2420.0,
            paymentMethod: 'Bank Transfer (BSP)',
            bankReference: 'OTML-884120',
            verifiedBy: 'Accounts Officer (Preview)',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),

      ...guestList,
    ];
  }

  @override
  List<HousekeepingTaskModel> getInitialHousekeepingTasks() {
    return [
      HousekeepingTaskModel(
        id: 'HK-101',
        roomNumber: 'G1-6',
        estateName: 'Kennedy Estate — 7 Mile',
        unitType: 'Single-Bedroom Executive (Ground Floor)',
        taskType: 'Checkout Turnover',
        roomStatus: 'dirty',
        priority: 'high',
        assignedTo: 'Martha K. (Housekeeping)',
        bookingReference: 'FTH-2026-0829',
        notes:
            'Full linen change, sanitize bathroom & kitchen utensils before 1:00 PM check-in.',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      ),
      HousekeepingTaskModel(
        id: 'HK-102',
        roomNumber: '16G-4',
        estateName: 'Kennedy Estate — 7 Mile',
        unitType: '1-Bedroom Studio (Ground Level)',
        taskType: 'Pre-Arrival Inspection',
        roomStatus: 'clean',
        priority: 'high',
        assignedTo: 'Martha K. (Housekeeping)',
        bookingReference: 'FTH-2026-0862',
        notes:
            'Check starter toiletries, Netflix remote batteries, and A/C temperature.',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      ),
      HousekeepingTaskModel(
        id: 'HK-103',
        roomNumber: '203',
        estateName: 'Venezia Estate — 6 Mile',
        unitType: '2-Bedroom, Level 1, Balcony View',
        taskType: 'Checkout Turnover',
        roomStatus: 'dirty',
        priority: 'normal',
        assignedTo: 'Esther M. (Housekeeping)',
        notes: 'Deep clean kitchen stove and balcony seating area.',
        scheduledAt: DateTime.now().add(const Duration(hours: 3)),
      ),
      HousekeepingTaskModel(
        id: 'HK-104',
        roomNumber: '22A',
        estateName: 'Grand Eden Estate — 8 Mile',
        unitType: '2-Bedroom, Ground Level, Parking View',
        taskType: 'Stayover Service',
        roomStatus: 'inspected',
        priority: 'normal',
        assignedTo: 'Sarah T. (Housekeeping)',
        bookingReference: 'FTH-2026-0835',
        notes: 'Fresh bath towels and daily tidy requested by guest.',
        scheduledAt: DateTime.now().add(const Duration(hours: 4)),
      ),
    ];
  }

  @override
  List<MaintenanceTicketModel> getInitialMaintenanceTickets() {
    return [
      MaintenanceTicketModel(
        id: 'MNT-01',
        ticketNumber: 'MNT-2026-019',
        roomNumber: '16F-1',
        estateName: 'Kennedy Estate — 7 Mile',
        category: 'Air Conditioning',
        title: 'Split A/C compressor filter & gas pressure check',
        description:
            'Master bedroom split air-conditioner cooling slowly. Room placed on temporary maintenance hold until inspected.',
        priority: 'urgent',
        status: 'in_progress',
        reportedBy: 'Housekeeping Supervisor',
        assignedTo: 'Joe W. (Maintenance Tech)',
        attachmentFileName: 'unit_16F1_ac_serial.jpg',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      MaintenanceTicketModel(
        id: 'MNT-02',
        ticketNumber: 'MNT-2026-020',
        roomNumber: '214',
        estateName: 'Venezia Estate — 6 Mile',
        category: 'Plumbing',
        title: 'Kitchen sink mixer tap washer replacement',
        description:
            'Minor drip reported on kitchen cold tap. Schedule replacement after guest morning departure.',
        priority: 'normal',
        status: 'open',
        reportedBy: 'Front Desk Officer',
        assignedTo: 'Joe W. (Maintenance Tech)',
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      ),
      MaintenanceTicketModel(
        id: 'MNT-03',
        ticketNumber: 'MNT-2026-017',
        roomNumber: 'G4-8',
        estateName: 'Kennedy Estate — 7 Mile',
        category: 'Electrical',
        title: 'Balcony security floodlight bulb replaced',
        description:
            'Replaced 20W LED courtyard sensor lamp and tested circuit breaker.',
        priority: 'low',
        status: 'resolved',
        reportedBy: 'Operations Manager',
        assignedTo: 'Joe W. (Maintenance Tech)',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  @override
  List<AirportTransferModel> getInitialAirportTransfers() {
    return [
      AirportTransferModel(
        id: 'TRF-301',
        bookingReference: 'FTH-2026-0841',
        guestName: 'Mr. L. Damore',
        guestPhone: '+675 7135 8804',
        passengers: 3,
        transferType: 'Airport Pickup (Arrival)',
        flightNumber: 'PX100 (Air Niugini — Domestic)',
        estateDestination: 'Kennedy Estate — 7 Mile (Unit G2-6)',
        roomNumber: 'G2-6',
        scheduledDateTime: DateTime.now().add(const Duration(hours: 3)),
        driverAssigned: 'David K. (Shuttle Driver)',
        status: 'scheduled',
        notes:
            'Meet guest at Jacksons Domestic Arrivals exit with FTH signboard.',
      ),
      AirportTransferModel(
        id: 'TRF-302',
        bookingReference: 'FTH-2026-0859',
        guestName: 'Dr. Samuel Vele',
        guestPhone: '+675 7099 3182',
        passengers: 3,
        transferType: 'Airport Pickup (Arrival)',
        flightNumber: 'PX108 (Air Niugini)',
        estateDestination: 'Venezia Estate — 6 Mile (Unit 214)',
        roomNumber: '214',
        scheduledDateTime: DateTime.now().add(const Duration(hours: 5)),
        driverAssigned: 'David K. (Shuttle Driver)',
        status: 'scheduled',
        notes:
            'Awaiting final payment verification confirmation from Accounts.',
      ),
      AirportTransferModel(
        id: 'TRF-303',
        bookingReference: 'FTH-2026-0835',
        guestName: 'Mr. Peter Nali & Family',
        guestPhone: '+675 7344 9012',
        passengers: 5,
        transferType: 'Airport Drop-off (Departure)',
        flightNumber: 'PX180 (06:30 AM Early Flight)',
        estateDestination: 'Grand Eden Estate (Unit 22A) → Jacksons Airport',
        roomNumber: '22A',
        scheduledDateTime: DateTime.now().add(
          const Duration(days: 1, hours: 6),
        ),
        driverAssigned: 'David K. (Shuttle Driver)',
        status: 'scheduled',
        notes: 'Early morning departure pickup at 05:00 AM sharp.',
      ),
    ];
  }

  @override
  List<GuestServiceRequestModel> getInitialGuestServiceRequests() {
    return [
      GuestServiceRequestModel(
        id: 'REQ-501',
        bookingReference: 'FTH-2026-0835',
        guestName: 'Mr. Peter Nali',
        roomNumber: '22A',
        estateName: 'Grand Eden Estate — 8 Mile',
        requestCategory: 'Housekeeping',
        subject: 'Extra bath towels & laundry detergent pods',
        details:
            'Please deliver 2 extra bath towels and washing machine detergent before 4:00 PM.',
        status: 'in_progress',
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
        staffResponseNote:
            'Assigned to Sarah T. (Housekeeping) for afternoon delivery.',
      ),
      GuestServiceRequestModel(
        id: 'REQ-502',
        bookingReference: 'FTH-2026-0841',
        guestName: 'Mr. L. Damore',
        roomNumber: 'G2-6',
        estateName: 'Kennedy Estate — 7 Mile',
        requestCategory: 'Airport Shuttle',
        subject: 'Confirm pickup for flight PX100',
        details:
            'Landing at 2:30 PM with 2 suitcases. Please confirm shuttle driver contact.',
        status: 'completed',
        requestedAt: DateTime.now().subtract(const Duration(hours: 5)),
        staffResponseNote:
            'Confirmed! Driver David K. (+675 7135 8804) will meet you at Domestic Arrivals.',
      ),
    ];
  }

  @override
  List<PaymentRecordModel> getInitialPaymentRecords() {
    return [
      PaymentRecordModel(
        id: 'PAY-901',
        bookingReference: 'FTH-2026-0859',
        guestName: 'Dr. Samuel Vele',
        categoryName: '2-Bedroom, Level 1, Balcony View (Venezia Estate)',
        amountPgk: 3025.0,
        paymentMethod: 'Bank Transfer (BSP)',
        referenceNumber: 'BSP-TXN-4491820',
        proofFileName: 'BSP_Transfer_SVele_3025PGK.jpg',
        status: 'pending_verification',
        submittedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      PaymentRecordModel(
        id: 'PAY-902',
        bookingReference: 'FTH-2026-0841',
        guestName: 'Mr. L. Damore',
        categoryName: 'Double-Bedroom Executive Apartment (Kennedy Estate)',
        amountPgk: 1815.0,
        paymentMethod: 'Bank Transfer (BSP)',
        referenceNumber: 'BSP-9928410',
        proofFileName: 'BSP_Remittance_FTH20260841.pdf',
        status: 'verified',
        submittedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        verifiedBy: 'Accounts Officer',
        verifiedAt: DateTime.now().subtract(const Duration(days: 1)),
        receiptNumber: 'FTH-RCP-2026-00038',
      ),
      PaymentRecordModel(
        id: 'PAY-903',
        bookingReference: 'FTH-2026-0835',
        guestName: 'Mr. Peter Nali (Ok Tedi Mining)',
        categoryName: '2-Bedroom, Ground Level, Parking View (Grand Eden)',
        amountPgk: 2420.0,
        paymentMethod: 'Corporate Account / BSP EFT',
        referenceNumber: 'OTML-884120',
        proofFileName: 'Corporate_EFT_OkTedi.pdf',
        status: 'verified',
        submittedAt: DateTime.now().subtract(const Duration(days: 3)),
        verifiedBy: 'Accounts Officer',
        verifiedAt: DateTime.now().subtract(const Duration(days: 2)),
        receiptNumber: 'FTH-RCP-2026-00034',
      ),
    ];
  }

  @override
  List<RefundRequestModel> getInitialRefundRequests() {
    return [
      RefundRequestModel(
        id: 'RFD-01',
        bookingReference: 'FTH-2026-0812',
        guestName: 'Mr. Thomas Yama',
        paidAmountPgk: 1320.0,
        backendCalculatedRefundPgk: 924.0, // 70% refund quote from FolioService
        refundPercentage: 70,
        hoursBeforeCheckIn: 76,
        policyExplanation:
            'Cancelled 76 hours before check-in (>= 48 hours threshold). Eligible for 70% refund (K924.00) per FTH FolioService policy.',
        reason: 'Flight rescheduled by airline due to weather.',
        status: 'pending_review',
        requestedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      RefundRequestModel(
        id: 'RFD-02',
        bookingReference: 'FTH-2026-0798',
        guestName: 'Ms. Helen Mondo',
        paidAmountPgk: 880.0,
        backendCalculatedRefundPgk: 0.0,
        refundPercentage: 0,
        hoursBeforeCheckIn: 18,
        policyExplanation:
            'Cancelled 18 hours before check-in (< 48 hours threshold). 0% refund per official FTH policy.',
        reason: 'Same-day travel change.',
        status: 'processed',
        requestedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }

  @override
  List<StaffMemberModel> getInitialStaffMembers() {
    return [
      StaffMemberModel(
        id: 'STF-01',
        fullName: 'FTH Executive Owner',
        email: 'familytransithome@gmail.com',
        phone: '+675 7135 8804',
        role: StaffRole.owner,
        assignedEstate: 'All Estates (Kennedy, Venezia, Grand Eden)',
        isActive: true,
        invitationStatus: 'active',
        lastLoginAt: DateTime.now().subtract(const Duration(minutes: 15)),
        effectivePermissions: StaffRole.owner.defaultPermissions,
      ),
      StaffMemberModel(
        id: 'STF-02',
        fullName: 'Michael T. — Operations Manager',
        email: 'operations@familytransithome.com',
        phone: '+675 7439 2490',
        role: StaffRole.operationsManager,
        assignedEstate: 'All Estates',
        isActive: true,
        invitationStatus: 'active',
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 1)),
        effectivePermissions: StaffRole.operationsManager.defaultPermissions,
      ),
      StaffMemberModel(
        id: 'STF-03',
        fullName: 'Rachel P. — Sales & Reservations',
        email: 'reservations@familytransithome.com',
        phone: '+675 7135 8804',
        role: StaffRole.sales,
        assignedEstate: 'Kennedy Estate — Reception 16G-02',
        isActive: true,
        invitationStatus: 'active',
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
        effectivePermissions: StaffRole.sales.defaultPermissions,
      ),
      StaffMemberModel(
        id: 'STF-04',
        fullName: 'Pauline K. — Front Desk Officer',
        email: 'frontdesk@familytransithome.com',
        phone: '+675 7135 8804',
        role: StaffRole.frontDesk,
        assignedEstate: 'Kennedy Estate — Reception 16G-02',
        isActive: true,
        invitationStatus: 'active',
        lastLoginAt: DateTime.now().subtract(const Duration(minutes: 40)),
        effectivePermissions: StaffRole.frontDesk.defaultPermissions,
      ),
      StaffMemberModel(
        id: 'STF-05',
        fullName: 'Steven M. — Accounts & Finance',
        email: 'accounts@familytransithome.com',
        phone: '+675 7439 2490',
        role: StaffRole.accounts,
        assignedEstate: 'All Estates',
        isActive: true,
        invitationStatus: 'active',
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 3)),
        effectivePermissions: StaffRole.accounts.defaultPermissions,
      ),
      StaffMemberModel(
        id: 'STF-06',
        fullName: 'Martha K. — Housekeeping Supervisor',
        email: 'housekeeping@familytransithome.com',
        phone: '+675 7135 8804',
        role: StaffRole.housekeeping,
        assignedEstate: 'Kennedy Estate — 7 Mile',
        isActive: true,
        invitationStatus: 'active',
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 4)),
        effectivePermissions: StaffRole.housekeeping.defaultPermissions,
      ),
      StaffMemberModel(
        id: 'STF-07',
        fullName: 'David K. — Airport Shuttle Driver',
        email: 'transport@familytransithome.com',
        phone: '+675 7135 8804',
        role: StaffRole.driver,
        assignedEstate: 'All Estates & Jacksons Airport',
        isActive: true,
        invitationStatus: 'active',
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
        effectivePermissions: StaffRole.driver.defaultPermissions,
      ),
      StaffMemberModel(
        id: 'STF-08',
        fullName: 'Joe W. — Maintenance Technician',
        email: 'maintenance@familytransithome.com',
        phone: '+675 7439 2490',
        role: StaffRole.maintenance,
        assignedEstate: 'All Estates',
        isActive: true,
        invitationStatus: 'pending_invitation',
        invitationExpiresAt: DateTime.now().add(const Duration(hours: 36)),
        effectivePermissions: StaffRole.maintenance.defaultPermissions,
      ),
    ];
  }
}
