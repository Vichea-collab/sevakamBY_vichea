import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_step.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/provider.dart';

class MockData {
  static const List<OnboardingStep> onboarding = [
    OnboardingStep(
      title: 'Best Helping Hands for you',
      description:
          'With our on-demand services app, we give better services to you.',
      actionLabel: 'Get Started',
      iconLabel: 'tools',
    ),
    OnboardingStep(
      title: 'Choose a service',
      description:
          'Find the right service for your needs easily, with a variety of options.',
      actionLabel: 'Next',
      iconLabel: 'grid',
    ),
    OnboardingStep(
      title: 'Get a quote',
      description:
          'Request price estimates from professionals to help you make decisions.',
      actionLabel: 'Next',
      iconLabel: 'chat',
    ),
    OnboardingStep(
      title: 'Work done',
      description: 'Sit back and relax while experts take care of your tasks.',
      actionLabel: 'Start',
      iconLabel: 'map',
    ),
  ];

  static const List<Category> categories = [
    Category(name: 'Plumber', icon: 'plumber'),
    Category(name: 'Electrician', icon: 'electrician'),
    Category(name: 'Cleaner', icon: 'cleaner'),
    Category(name: 'Home Appliance', icon: 'appliance'),
    Category(name: 'Home Maintenance', icon: 'maintenance'),
  ];

  static const List<String> recentSearches = [
    'Indoor Cleaning',
    'Plumbing Drain Repair',
    'Electrical Help',
    'Interior Painting',
    'AC Repair',
    'Door Repair',
  ];

  static final List<ServiceItem> services = [
    const ServiceItem(
      title: 'Pipe Leak Repair',
      subtitle: 'Starts in \$12/hr',
      badge: 'Popular',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.8,
      category: 'Plumber',
      available: true,
      etaHours: 1,
    ),
    const ServiceItem(
      title: 'Toilet Repair',
      subtitle: 'Starts in \$11/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.6,
      category: 'Plumber',
      available: true,
      etaHours: 2,
    ),
    const ServiceItem(
      title: 'Water Installation',
      subtitle: 'Starts in \$15/hr',
      badge: 'Pro',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.7,
      category: 'Plumber',
      available: false,
      etaHours: 3,
    ),
    const ServiceItem(
      title: 'Wiring Repair',
      subtitle: 'Starts in \$16/hr',
      badge: 'Popular',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.7,
      category: 'Electrician',
      available: true,
      etaHours: 2,
    ),
    const ServiceItem(
      title: 'Light / Fan Installation',
      subtitle: 'Starts in \$14/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.5,
      category: 'Electrician',
      available: true,
      etaHours: 2,
    ),
    const ServiceItem(
      title: 'Power Outage Fix',
      subtitle: 'Starts in \$18/hr',
      badge: 'Fast',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.9,
      category: 'Electrician',
      available: false,
      etaHours: 1,
    ),
    const ServiceItem(
      title: 'House Cleaning',
      subtitle: 'Starts in \$10/hr',
      badge: 'Popular',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.9,
      category: 'Cleaner',
      available: true,
      etaHours: 2,
    ),
    const ServiceItem(
      title: 'Office Cleaning',
      subtitle: 'Starts in \$13/hr',
      badge: 'Pro',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.4,
      category: 'Cleaner',
      available: true,
      etaHours: 3,
    ),
    const ServiceItem(
      title: 'Move-in Cleaning',
      subtitle: 'Starts in \$14/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.6,
      category: 'Cleaner',
      available: false,
      etaHours: 2,
    ),
    const ServiceItem(
      title: 'Air Conditioner Repair',
      subtitle: 'Starts in \$20/hr',
      badge: 'Pro',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.8,
      category: 'Home Appliance',
      available: true,
      etaHours: 4,
    ),
    const ServiceItem(
      title: 'Washing Machine Repair',
      subtitle: 'Starts in \$19/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.5,
      category: 'Home Appliance',
      available: true,
      etaHours: 3,
    ),
    const ServiceItem(
      title: 'Refrigerator Repair',
      subtitle: 'Starts in \$21/hr',
      badge: 'Popular',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.7,
      category: 'Home Appliance',
      available: false,
      etaHours: 4,
    ),
    const ServiceItem(
      title: 'Door & Window Repair',
      subtitle: 'Starts in \$17/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.4,
      category: 'Home Maintenance',
      available: true,
      etaHours: 3,
    ),
    const ServiceItem(
      title: 'Furniture Fixing',
      subtitle: 'Starts in \$18/hr',
      badge: 'Pro',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.6,
      category: 'Home Maintenance',
      available: true,
      etaHours: 2,
    ),
    const ServiceItem(
      title: 'Shelf / Curtain Installation',
      subtitle: 'Starts in \$16/hr',
      badge: 'Fast',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.3,
      category: 'Home Maintenance',
      available: false,
      etaHours: 2,
    ),
  ];

  static final List<ServiceItem> popular = services.take(6).toList();

  static final List<ProviderItem> electricianProviders = _providers(
    role: 'Electrician',
    names: const [
      'Jackson',
      'Logan',
      'Ethan Iita',
      'Isabella Una',
      'Panama',
      'Jamalo',
      'Mehram',
      'Shatem',
      'Volt Master',
      'Bright Wire',
    ],
  );

  static final List<ProviderItem> plumberProviders = _providers(
    role: 'Plumber',
    names: const [
      'Ethan Iita',
      'Isabella Una',
      'Shams',
      'Lucas',
      'Kunal',
      'Barbeta',
      'Caleb',
      'Harper',
      'Pipe Doctor',
      'Flow Expert',
    ],
  );

  static final List<ProviderItem> cleanerProviders = _providers(
    role: 'Cleaner',
    names: const [
      'Harper',
      'Caleb',
      'Shams',
      'Mendo',
      'Zero Dirt Team',
      'GC Cleaning',
      'Vichea Cleaning',
      'Kimheng Services',
      'Sparkle Team',
      'Fresh Home',
    ],
  );

  static final List<ProviderItem> applianceProviders = _providers(
    role: 'Appliance',
    names: const [
      'CoolAir Team',
      'Fridge Pro',
      'Laundry Fix',
      'Home Tech Co',
      'Rapid Appliance',
      'VoltFix',
      'Clean Wave',
      'Smart Home Fix',
      'Tech Doctor',
      'Appliance Hero',
    ],
  );

  static final List<ProviderItem> maintenanceProviders = _providers(
    role: 'Maintenance',
    names: const [
      'Handy Kunal',
      'Barbeta Works',
      'DoorCare',
      'Fixer Crew',
      'Home Renew',
      'Cabinet Hub',
      'Curtain Fit',
      'Repair Station',
      'Fix Master',
      'Daily Repair',
    ],
  );

  static final List<ProviderSection> providerSections = [
    ProviderSection(
      title: 'Electrician Providers',
      category: 'Electrician',
      providers: electricianProviders,
    ),
    ProviderSection(
      title: 'Plumber Providers',
      category: 'Plumber',
      providers: plumberProviders,
    ),
    ProviderSection(
      title: 'Cleaner Providers',
      category: 'Cleaner',
      providers: cleanerProviders,
    ),
    ProviderSection(
      title: 'Home Appliance Providers',
      category: 'Home Appliance',
      providers: applianceProviders,
    ),
    ProviderSection(
      title: 'Home Maintenance Providers',
      category: 'Home Maintenance',
      providers: maintenanceProviders,
    ),
  ];

  static List<ProviderItem> _providers({
    required String role,
    required List<String> names,
  }) {
    const accents = [
      Color(0xFFE9D5FF),
      Color(0xFFFDE68A),
      Color(0xFFBBF7D0),
      Color(0xFFFECACA),
      Color(0xFFBAE6FD),
      Color(0xFFE0E7FF),
      Color(0xFFFBCFE8),
      Color(0xFFCFFAFE),
    ];

    return List<ProviderItem>.generate(names.length, (index) {
      final base = 4.1 + (index % 5) * 0.2;
      return ProviderItem(
        name: names[index],
        role: role,
        rating: double.parse(base.toStringAsFixed(1)),
        imagePath: 'assets/images/profile.jpg',
        accentColor: accents[index % accents.length],
      );
    });
  }

  static List<ServiceItem> servicesByCategory(String category) {
    return services.where((s) => s.category == category).toList();
  }

  static List<ProviderItem> providersByCategory(String category) {
    final section = providerSections.where((s) => s.category == category);
    if (section.isEmpty) return [];
    return section.first.providers;
  }
}
