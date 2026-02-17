import 'package:flutter/material.dart';

class ProviderItem {
  final String uid;
  final String name;
  final String role;
  final double rating;
  final String imagePath;
  final Color accentColor;
  final List<String> services;
  final String providerType;
  final String companyName;
  final int maxWorkers;

  const ProviderItem({
    this.uid = '',
    required this.name,
    required this.role,
    required this.rating,
    required this.imagePath,
    required this.accentColor,
    this.services = const <String>[],
    this.providerType = 'individual',
    this.companyName = '',
    this.maxWorkers = 1,
  });

  bool get isCompany => providerType.trim().toLowerCase() == 'company';

  int get safeMaxWorkers => maxWorkers < 1 ? 1 : maxWorkers;
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
