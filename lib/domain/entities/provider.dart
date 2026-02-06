import 'package:flutter/material.dart';

class ProviderItem {
  final String name;
  final String role;
  final double rating;
  final String imagePath;
  final Color accentColor;

  const ProviderItem({
    required this.name,
    required this.role,
    required this.rating,
    required this.imagePath,
    required this.accentColor,
  });
}

class ProviderSection {
  final String title;
  final String category;
  final List<ProviderItem> providers;

  const ProviderSection({
    required this.title,
    required this.category,
    required this.providers,
  });
}
