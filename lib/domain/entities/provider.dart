import 'package:flutter/material.dart';
import '../../core/utils/category_utils.dart';
import 'provider_portal.dart';

class ProviderItem {
  final String uid;
  final String name;
  final String bio;
  final String role;
  final double rating;
  final String imagePath;
  final Color accentColor;
  final List<String> services;
  final bool isVerified;
  final double? latitude;
  final double? longitude;
  final List<DateTime> blockedDates;

  const ProviderItem({
    this.uid = '',
    required this.name,
    this.bio = '',
    required this.role,
    required this.rating,
    required this.imagePath,
    required this.accentColor,
    this.services = const <String>[],
    this.isVerified = false,
    this.latitude,
    this.longitude,
    this.blockedDates = const [],
  });

  factory ProviderItem.fromPost(ProviderPostItem post) {
    final role = post.category.trim().isEmpty ? 'Cleaner' : post.category;
    return ProviderItem(
      uid: post.providerUid,
      name: post.providerName.trim().isEmpty ? 'Service Provider' : post.providerName,
      bio: post.providerBio,
      role: role,
      rating: post.rating,
      imagePath: post.avatarPath,
      accentColor: accentForCategory(role),
      services: post.serviceList,
      blockedDates: post.blockedDates,
    );
  }
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
