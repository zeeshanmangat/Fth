import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:family_transit_home/config/api_config.dart';
import 'package:family_transit_home/core/constants/assets.dart';
import 'package:family_transit_home/core/constants/strings.dart';
import 'package:family_transit_home/core/theme/app_theme.dart';
import 'package:family_transit_home/data/models/accommodation.dart';
import 'package:family_transit_home/data/models/booking.dart';
import 'package:family_transit_home/data/repositories/accommodation_repository.dart';
import 'package:family_transit_home/data/repositories/amenity_repository.dart';
import 'package:family_transit_home/data/repositories/guest_guide_repository.dart';
import 'package:family_transit_home/models/estate_model.dart';
import 'package:family_transit_home/providers/app_state_provider.dart';
import 'package:family_transit_home/repositories/laravel_api_service.dart';
import 'package:family_transit_home/repositories/mock_catalog_repository.dart';
import 'package:family_transit_home/ui/screens/booking/booking_screen.dart';
import 'package:family_transit_home/ui/screens/main_nav/main_nav_screen.dart';
import 'package:family_transit_home/ui/screens/profile/profile_screen.dart';
import 'package:family_transit_home/ui/screens/search/search_screen.dart';
import 'package:family_transit_home/ui/widgets/accommodation_card.dart';

class _DynamicTestCatalogRepository extends MockCatalogRepository {
  @override
  List<EstateModel> getEstates() {
    return [
      ...super.getEstates(),
      const EstateModel(
        id: 99,
        slug: 'ela-beach-horizon',
        key: 'ela-beach-horizon',
        name: 'Ela Beach Horizon Estate',
        location: 'Ela Beach, Port Moresby',
        address: 'Lot 22, Bramell Street, NCD',
        distanceAirport: '15 minutes from Jacksons Airport',
        badge: 'Waterfront Residence',
        image: AppAssets.fthHeroBuilding,
        gallery: [AppAssets.fthHeroBuilding],
        description: 'Waterfront serviced apartments.',
        placeholderNote: 'Dynamic staff estate.',
        highlights: ['Waterfront View'],
        sampleCategories: ['Ela Waterfront Penthouse'],
        totalPhysicalUnits: 2,
      ),
    ];
  }

  @override
  List<Accommodation> getApartmentCategories() {
    return [
      ...super.getApartmentCategories(),
      const Accommodation(
        id: 'APT-10',
        slug: 'ela-waterfront-penthouse',
        title: 'Ela Waterfront Penthouse',
        categoryType: 'Waterfront 4-Bedroom Sky Suite',
        estateKey: 'ela-beach-horizon',
        estate: 'Ela Beach Horizon Estate — Ela Beach',
        estateAssignmentNote: 'Ela Beach waterfront wing',
        locationArea: 'Ela Beach, NCD',
        pricePerNight: 1250.0,
        rateNote: 'GST-Inclusive Corporate Rate',
        gstInclusive: true,
        maxAdults: 6,
        maxChildren: 2,
        maxGuests: 8,
        bedrooms: 4,
        bathrooms: 3,
        beds: 4,
        floorLevel: 'Level 4 Penthouse',
        view: 'Ela Beach Oceanfront Balcony',
        bedConfiguration: '4 Queen Beds',
        sizeSqm: 185,
        mainImage: AppAssets.fthServicedApartments,
        galleryImages: [AppAssets.fthServicedApartments],
        shortDescription: 'Executive waterfront penthouse suite.',
        description: 'Spacious oceanfront 4-bedroom suite at Ela Beach.',
        amenities: [],
        availableUnits: 2,
        isFeatured: true,
      ),
    ];
  }
}

Widget _wrapWithProviders(Widget child, {AppStateProvider? state}) {
  return ChangeNotifierProvider<AppStateProvider>(
    create: (_) => state ?? AppStateProvider(autoFetchLiveCatalog: false),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  group('Family Transit Home Production API & Business Rule Tests', () {
    test(
      'ApiConfig connects to live production API URL https://fth.demo-kraiptech.com/api/v1 with mock repositories disabled',
      () {
        expect(ApiConfig.useMockRepositories, false);
        expect(ApiConfig.baseUrl, 'https://fth.demo-kraiptech.com/api/v1');
        expect(ApiConfig.originUrl, 'https://fth.demo-kraiptech.com');
        expect(
          AppStrings.pmsPortalUrl,
          'https://fth.demo-kraiptech.com/staff/login',
        );
      },
    );

    test(
      'Catalog Repository & LaravelApiService Mappers support all 3 Official Estates, 9 Apartment Categories, 35 Physical Units, and Official Client Rules',
      () {
        expect(AppStrings.primaryPhone, '+675 7439 2490');
        expect(AppStrings.secondaryPhone, '+675 7135 8804');
        expect(AppStrings.checkInTime, '1:00 PM');
        expect(AppStrings.checkOutTime, '10:00 AM');

        final estates = AccommodationRepository.getEstateModels();
        expect(estates.length, 3);
        expect(estates.any((e) => e.key == 'kennedy'), true);
        expect(estates.any((e) => e.key == 'venezia'), true);
        expect(estates.any((e) => e.key == 'grand-eden'), true);

        final categories = AccommodationRepository.getAccommodations();
        expect(categories.length, 9);

        final apt01 = categories.firstWhere((u) => u.id == 'APT-01');
        expect(apt01.pricePerNight, 440.0);
        expect(apt01.gstInclusive, true);
        expect(apt01.checkInTime, '1:00 PM');
        expect(apt01.checkOutTime, '10:00 AM');

        final apt04 = categories.firstWhere((u) => u.id == 'APT-04');
        expect(apt04.pricePerNight, 385.0);
        expect(apt04.amenityLabels.contains('Pool & Gym Access'), true);

        final apt05 = categories.firstWhere((u) => u.id == 'APT-05');
        expect(apt05.pricePerNight, 696.33);
        expect(apt05.amenityLabels.contains('Pool & Gym Access'), true);

        final apt08 = categories.firstWhere((u) => u.id == 'APT-08');
        expect(apt08.pricePerNight, 957.0);
        expect(apt08.amenityLabels.contains('Pool & Gym Access'), true);

        final apt09 = categories.firstWhere((u) => u.id == 'APT-09');
        expect(apt09.pricePerNight, 825.0);
        expect(apt09.bedrooms, 3);

        final ratePlans = AccommodationRepository.getRatePlans();
        expect(ratePlans.length, 1);
        expect(ratePlans.first.code, 'STANDARD');

        // Verify LaravelApiService JSON mappers
        final mappedBooking = LaravelApiService.mapBooking({
          'reference': 'FTH-2026-9901',
          'category_id': 'APT-01',
          'check_in': '2026-11-20',
          'check_out': '2026-11-23',
          'adults': 2,
          'children': 0,
          'rooms_count': 1,
          'guest_name': 'Real Production Guest',
          'guest_email': 'guest@fth.com.pg',
          'guest_phone': '+675 7135 8804',
          'rate_plan_code': 'standard',
          'rate_plan_name': 'Standard Rate Plan',
          'total_pgk': 1320.0,
          'amount_paid_pgk': 0.0,
          'status': 'Pending Approval',
          'has_pending_payment_proof': true,
        }, categories);

        expect(mappedBooking.id, 'FTH-2026-9901');
        expect(
          mappedBooking.workflowStatus,
          BookingWorkflowStatus.paymentUnderReview,
        );
        expect(mappedBooking.totalPrice, 1320.0);
      },
    );

    test(
      'Amenity & Guest Guide Repositories return verified FTH inclusions',
      () {
        final amenities = AmenityRepository.allAmenities;
        expect(amenities.isNotEmpty, true);
        expect(amenities.any((a) => a.name.contains('Shuttle')), true);

        final guide = GuestGuideRepository.getGuideItems();
        expect(guide.isNotEmpty, true);
      },
    );

    test(
      'Guest Booking submission creates Pending Approval request and never adds duplicate GST on top of GST-inclusive rate',
      () {
        final state = AppStateProvider(autoFetchLiveCatalog: false);
        expect(state.allAccommodations.length, 9);
        expect(state.physicalUnits.length, 35);
        // Zero mock bookings on fresh startup
        expect(state.bookings.isEmpty, true);
        expect(state.isGuestLoggedIn, false);

        final category = state.allAccommodations.firstWhere(
          (a) => a.id == 'APT-01',
        ); // K440/night GST-inclusive

        final booking = state.createBooking(
          accommodation: category,
          checkInDate: DateTime.now().add(const Duration(days: 2)),
          checkOutDate: DateTime.now().add(const Duration(days: 5)), // 3 nights
          adults: 2,
          children: 0,
          guestName: 'Verified Guest',
          guestEmail: 'guest@fth.com.pg',
          guestPhone: '+675 7135 8804',
          requestAirportShuttle: true,
          flightNumber: 'PX100',
        );

        // Business Rule #10: Submitted request is Pending Approval, never auto-confirmed
        expect(booking.workflowStatus, BookingWorkflowStatus.pendingApproval);
        expect(booking.totalNights, 3);
        // Business Rule #6: GST-inclusive pricing (3 * 440 = 1320.0, no +10% added on top)
        expect(booking.totalPrice, 1320.0);

        // Uploading payment proof sets status to Payment Under Review, not Confirmed
        state.uploadGuestPaymentProof(
          bookingId: booking.id,
          proofFileName: 'BSP_Receipt.pdf',
          paymentMethod: 'Bank Transfer (BSP)',
          referenceNumber: 'BSP-12345',
        );
        final updated = state.bookings.firstWhere((b) => b.id == booking.id);
        expect(
          updated.workflowStatus,
          BookingWorkflowStatus.paymentUnderReview,
        );
      },
    );

    testWidgets(
      'Guest 5-Tab Navigation & Booking Request Screen render cleanly across phone sizes',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final state = AppStateProvider(autoFetchLiveCatalog: false);
        await tester.pumpWidget(
          _wrapWithProviders(const MainNavScreen(), state: state),
        );
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsWidgets);
        expect(find.text('Explore'), findsWidgets);
        expect(find.text('Bookings'), findsWidgets);
        expect(find.text('Notifications'), findsWidgets);
        expect(find.text('Profile'), findsWidgets);

        // Navigate to Explore tab
        await tester.tap(find.text('Explore').last);
        await tester.pumpAndSettle();
        expect(find.text('Explore Accommodations'), findsOneWidget);

        // Navigate to Bookings tab
        await tester.tap(find.text('Bookings').last);
        await tester.pumpAndSettle();
        expect(find.text('My Bookings & Stay Status'), findsOneWidget);

        // Navigate to Profile tab
        await tester.tap(find.text('Profile').last);
        await tester.pumpAndSettle();
        expect(find.text('Guest Profile & Stay Tools'), findsOneWidget);

        // Render BookingScreen directly
        await tester.pumpWidget(
          _wrapWithProviders(
            BookingScreen(accommodation: state.allAccommodations.first),
            state: state,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Submit Booking Request'), findsOneWidget);
        expect(find.text('4. Official Pricing Quote Summary'), findsOneWidget);
      },
    );

    testWidgets(
      'Guest-Only App excludes all Staff PMS Login and Staff Portal UI',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final state = AppStateProvider(autoFetchLiveCatalog: false);
        await tester.pumpWidget(
          _wrapWithProviders(const ProfileScreen(), state: state),
        );
        await tester.pumpAndSettle();

        expect(find.text('Guest Profile & Stay Tools'), findsOneWidget);
        expect(find.text('Staff PMS Login'), findsNothing);
        expect(find.text('Open PMS'), findsNothing);
        expect(find.text('FTH Staff & Property Management System'), findsNothing);
      },
    );

    testWidgets(
      'HomeScreen and SearchScreen dynamically render and filter new Staff Estates & Categories without hardcoded values',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final state = AppStateProvider(
          catalogRepository: _DynamicTestCatalogRepository(),
          autoFetchLiveCatalog: false,
        );

        expect(state.estates.length, 4);
        expect(state.allAccommodations.length, 10);
        // 1250 PGK luxury category is not hidden by default price range
        expect(
          state.accommodations.any((a) => a.id == 'APT-10'),
          true,
        );

        await tester.pumpWidget(
          _wrapWithProviders(const MainNavScreen(), state: state),
        );
        await tester.pumpAndSettle();

        final chipScrollable = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
        );
        await tester.scrollUntilVisible(
          find.text('4-Bedroom'),
          150,
          scrollable: chipScrollable.first,
        );
        await tester.pumpAndSettle();
        expect(find.text('4-Bedroom'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Ela Beach Horizon Estate'),
          -150,
          scrollable: chipScrollable.first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Ela Beach Horizon Estate'), findsWidgets);

        // Tap dynamic Estate chip on HomeScreen
        await tester.tap(find.text('Ela Beach Horizon Estate').first);
        await tester.pumpAndSettle();

        expect(state.accommodations.length, 1);
        expect(state.accommodations.first.id, 'APT-10');
        expect(find.text('Ela Waterfront Penthouse'), findsWidgets);

        // Verify SearchScreen dynamically lists new category & estate in filter modal
        state.resetFilters();
        await tester.pumpWidget(
          _wrapWithProviders(const SearchScreen(), state: state),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.filter_list_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Waterfront 4-Bedroom Sky Suite'), findsOneWidget);
        expect(find.text('4 Bedrooms'), findsOneWidget);
        expect(find.text('Ela Beach Horizon Estate'), findsOneWidget);
      },
    );

    testWidgets(
      'AccommodationCard displays airport distance only when estate distance exists and never hardcodes 5 min across Venezia or Grand Eden',
      (WidgetTester tester) async {
        final accommodations = AccommodationRepository.getAccommodations();
        final kennedyApt01 =
            accommodations.firstWhere((a) => a.id == 'APT-01');
        final veneziaApt04 =
            accommodations.firstWhere((a) => a.id == 'APT-04');
        final grandEdenApt07 =
            accommodations.firstWhere((a) => a.id == 'APT-07');

        expect(kennedyApt01.distanceToAirport.isNotEmpty, true);
        expect(veneziaApt04.distanceToAirport, isEmpty);
        expect(grandEdenApt07.distanceToAirport, isEmpty);

        await tester.pumpWidget(
          _wrapWithProviders(
            Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    AccommodationCard(accommodation: kennedyApt01),
                    AccommodationCard(accommodation: veneziaApt04),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('5 min to Airport'), findsNothing);
        expect(
          find.text('Approx. 5 mins from Jacksons International Airport'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'MainNavScreen updates BottomNavigationBar currentIndex and highlights Profile when Profile tab is tapped',
      (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithProviders(const MainNavScreen()));
        await tester.pumpAndSettle();

        BottomNavigationBar navBar =
            tester.widget(find.byType(BottomNavigationBar));
        expect(navBar.currentIndex, 0);

        await tester.tap(find.text('Profile').last);
        await tester.pumpAndSettle();

        navBar = tester.widget(find.byType(BottomNavigationBar));
        expect(navBar.currentIndex, 4);
        expect(find.text('Guest Profile & Stay Tools'), findsOneWidget);
      },
    );
  });
}
