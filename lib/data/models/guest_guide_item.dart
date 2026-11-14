import 'package:flutter/material.dart';

class GuestGuideItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final String contactNumber;
  final String location;
  final IconData icon;

  const GuestGuideItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.contactNumber,
    required this.location,
    required this.icon,
  });
}
