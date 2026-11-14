import 'package:flutter/material.dart';
import '../models/amenity.dart';

class AmenityRepository {
  static const List<Amenity> allAmenities = [
    Amenity(
      id: 'shuttle',
      name: 'Free Airport Shuttle',
      icon: Icons.airport_shuttle_rounded,
      description:
          'Free transfers to & from Jacksons International Airport (5 mins away).',
    ),
    Amenity(
      id: 'housekeeping',
      name: 'Daily Housekeeping',
      icon: Icons.cleaning_services_rounded,
      description:
          'Attentive housekeeping keeping your unit clean, fresh, and welcoming.',
    ),
    Amenity(
      id: 'security',
      name: '24/7 Gated Security',
      icon: Icons.security_rounded,
      description: 'Secure perimeter guardhouse and 24/7 residential patrol.',
    ),
    Amenity(
      id: 'parking',
      name: 'Free Resident Parking',
      icon: Icons.local_parking_rounded,
      description: 'Dedicated secure vehicle parking within the gated complex.',
    ),
    Amenity(
      id: 'wifi',
      name: 'Free High-Speed Wi-Fi',
      icon: Icons.wifi_rounded,
      description:
          'Fast wireless internet for streaming, video calls, and work.',
    ),
    Amenity(
      id: 'tv',
      name: 'Flat Screen TV + Netflix',
      icon: Icons.tv_rounded,
      description: '40+ free channels and Netflix entertainment access.',
    ),
    Amenity(
      id: 'kitchen',
      name: 'Fully Equipped Kitchen',
      icon: Icons.kitchen_rounded,
      description:
          'Cooking & dining utensils, stovetop, microwave, kettle, and fridge.',
    ),
    Amenity(
      id: 'laundry',
      name: 'Laundry Facilities',
      icon: Icons.local_laundry_service_rounded,
      description: 'In-unit washing machine and laundry area included.',
    ),
    Amenity(
      id: 'ac',
      name: 'Air Conditioning',
      icon: Icons.ac_unit_rounded,
      description: 'Air-conditioned bedrooms for a comfortable, restful sleep.',
    ),
    Amenity(
      id: 'balcony',
      name: 'Private Balcony',
      icon: Icons.balcony_rounded,
      description:
          'Private outdoor balcony with panoramic neighborhood and hill views.',
    ),
    Amenity(
      id: 'toiletries',
      name: 'Toiletries Provided',
      icon: Icons.soap_rounded,
      description:
          'Complimentary clean bath towels, soap, shampoo, and essentials.',
    ),
    Amenity(
      id: 'backup_power',
      name: 'Backup Generator',
      icon: Icons.bolt_rounded,
      description:
          'Automatic standby power generation for uninterrupted electricity.',
    ),
    Amenity(
      id: 'backup_water',
      name: 'Backup Water Supply',
      icon: Icons.water_drop_rounded,
      description: 'Dedicated high-capacity water reserve tanks on site.',
    ),
  ];

  static Amenity getById(String id) {
    return allAmenities.firstWhere(
      (a) => a.id == id,
      orElse: () => allAmenities.first,
    );
  }
}
