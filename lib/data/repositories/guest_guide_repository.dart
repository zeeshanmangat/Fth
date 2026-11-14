import 'package:flutter/material.dart';
import '../models/guest_guide_item.dart';

class GuestGuideRepository {
  static List<GuestGuideItem> getGuideItems() {
    return const [
      GuestGuideItem(
        id: 'g-1',
        title: 'St. John Ambulance Service',
        category: 'Emergency & Medical',
        description:
            'Primary emergency medical response and 24/7 ambulance dispatch in Port Moresby.',
        contactNumber: '111 / +675 7111 1234',
        location: 'Port Moresby NCD',
        icon: Icons.emergency_rounded,
      ),
      GuestGuideItem(
        id: 'g-2',
        title: 'Port Moresby General Hospital',
        category: 'Emergency & Medical',
        description:
            'National referral hospital with 24-hour emergency trauma department.',
        contactNumber: '+675 324 8200',
        location: 'Taurama Road, 3 Mile, Port Moresby',
        icon: Icons.local_hospital_rounded,
      ),
      GuestGuideItem(
        id: 'g-3',
        title: 'Pacific International Hospital (PIH)',
        category: 'Emergency & Medical',
        description:
            'Private tertiary healthcare facility with 24/7 modern diagnostics and emergency care.',
        contactNumber: '+675 7998 8000',
        location: '3 Mile, Port Moresby',
        icon: Icons.health_and_safety_rounded,
      ),
      GuestGuideItem(
        id: 'g-4',
        title: 'Royal PNG Constabulary (7-Mile Police)',
        category: 'Emergency & Medical',
        description:
            'Local police station covering 7-Mile, Jacksons Airport precinct, and Kennedy Estate.',
        contactNumber: '+675 324 4331 / 112',
        location: '7 Mile, Port Moresby',
        icon: Icons.local_police_rounded,
      ),
      GuestGuideItem(
        id: 'g-5',
        title: 'Jacksons International Airport (NAC)',
        category: 'Aviation & Transport',
        description:
            'Main international and domestic airport terminal (5 minutes from Kennedy Estate).',
        contactNumber: '+675 324 4500',
        location: '7 Mile, Port Moresby',
        icon: Icons.flight_rounded,
      ),
      GuestGuideItem(
        id: 'g-6',
        title: 'Air Niugini Reservations',
        category: 'Aviation & Transport',
        description:
            'National flag carrier domestic and international flight bookings & check-in.',
        contactNumber: '+675 327 3555',
        location: 'Jacksons Airport Terminal',
        icon: Icons.airplane_ticket_rounded,
      ),
      GuestGuideItem(
        id: 'g-7',
        title: 'PNG Air Customer Service',
        category: 'Aviation & Transport',
        description:
            'Domestic airline operations connecting all major PNG provincial centers.',
        contactNumber: '+675 7411 2644',
        location: 'Jacksons Airport Domestic',
        icon: Icons.airlines_rounded,
      ),
      GuestGuideItem(
        id: 'g-8',
        title: 'Vision City Mega Mall',
        category: 'Shopping & Dining',
        description:
            'PNG\'s largest shopping center featuring RH Hypermarket, cinema, banking, and dining.',
        contactNumber: '+675 302 8555',
        location: 'Waigani Drive, Port Moresby (8 mins away)',
        icon: Icons.shopping_bag_rounded,
      ),
      GuestGuideItem(
        id: 'g-9',
        title: 'Rangeview Plaza',
        category: 'Shopping & Dining',
        description:
            'Modern shopping plaza with supermarkets, pharmacies, cafes, and bakery.',
        contactNumber: '+675 303 9888',
        location: 'Waigani, Port Moresby',
        icon: Icons.storefront_rounded,
      ),
    ];
  }
}
