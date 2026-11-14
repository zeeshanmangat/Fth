import 'package:flutter/material.dart';

class Amenity {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final bool isComplimentary;

  const Amenity({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.isComplimentary = true,
  });
}
