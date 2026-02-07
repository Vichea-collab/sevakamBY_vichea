import 'provider.dart';

enum ReviewRange {
  last30('Last 30 days', 30),
  last60('Last 60 days', 60),
  last90('Last 90 days', 90),
  last120('Last 120 days', 120);

  final String label;
  final int maxDays;

  const ReviewRange(this.label, this.maxDays);
}

class ProviderReview {
  final String reviewerName;
  final String reviewerInitials;
  final double rating;
  final int daysAgo;
  final String comment;

  const ProviderReview({
    required this.reviewerName,
    required this.reviewerInitials,
    required this.rating,
    required this.daysAgo,
    required this.comment,
  });
}

class ProviderProfile {
  final ProviderItem provider;
  final String location;
  final bool available;
  final int completedJobs;
  final String about;
  final List<String> projectImages;
  final List<ProviderReview> reviews;

  const ProviderProfile({
    required this.provider,
    required this.location,
    required this.available,
    required this.completedJobs,
    required this.about,
    required this.projectImages,
    required this.reviews,
  });

  double get averageRating {
    if (reviews.isEmpty) return provider.rating;
    final total = reviews.fold<double>(0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }
}
