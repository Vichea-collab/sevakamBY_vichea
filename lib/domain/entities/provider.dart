import 'package:flutter/material.dart';

class ProviderItem {
  final String uid;
  final String name;
  final String role;
  final double rating;
  final String imagePath;
  final Color accentColor;
  final List<String> services;

  const ProviderItem({
    this.uid = '',
    required this.name,
    required this.role,
    required this.rating,
    required this.imagePath,
    required this.accentColor,
    this.services = const <String>[],
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
