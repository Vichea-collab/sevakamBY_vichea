class ServiceItem {
  final String title;
  final String subtitle;
  final String badge;
  final String imagePath;
  final double rating;
  final String category;
  final String location;
  final bool available;
  final int etaHours;
  final String serviceTime;

  const ServiceItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.imagePath,
    required this.rating,
    this.category = 'General',
    this.location = 'Phnom Penh, Cambodia',
    this.available = true,
    this.etaHours = 2,
    this.serviceTime = '9AM - 5PM',
  });
}
