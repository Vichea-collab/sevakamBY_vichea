import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_step.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/provider.dart';
import '../../domain/entities/provider_profile.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/provider_portal.dart';

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

  static final List<FinderPostItem> finderPosts = [
    FinderPostItem(
      id: 'fp-1',
      clientName: 'Eang Kimheng',
      message: 'I want to find cleaning service in Toul Kork.',
      timeLabel: '2 hrs ago',
      category: 'Cleaner',
      service: 'House Cleaning',
      location: 'Toul Kork, Phnom Penh',
      avatarPath: 'assets/images/profile.jpg',
      preferredDate: DateTime(2026, 2, 12),
    ),
    FinderPostItem(
      id: 'fp-2',
      clientName: 'Heng Mengly',
      message: 'My toilet broken please help!',
      timeLabel: '3 hrs ago',
      category: 'Plumber',
      service: 'Toilet Repair',
      location: 'Sen Sok, Phnom Penh',
      avatarPath: 'assets/images/profile.jpg',
      preferredDate: DateTime(2026, 2, 13),
    ),
    FinderPostItem(
      id: 'fp-3',
      clientName: 'Monich',
      message: 'Need wiring repair for 2 rooms this afternoon.',
      timeLabel: '5 hrs ago',
      category: 'Electrician',
      service: 'Wiring Repair',
      location: 'Tuol Svay Prey, Phnom Penh',
      avatarPath: 'assets/images/profile.jpg',
      preferredDate: DateTime(2026, 2, 14),
    ),
  ];

  static const List<ProviderOrderItem> providerOrdersSeed = [
    ProviderOrderItem(
      id: 'po-101',
      clientName: 'Sok Dara',
      clientPhone: '+855 12 345 678',
      category: 'Cleaner',
      serviceName: 'Indoor Cleaning',
      address: 'Toul Kork, Phnom Penh, Cambodia',
      addressLink: 'https://maps.google.com/?q=Toul+Kork,+Phnom+Penh',
      scheduleDate: 'Wed, Mar 7',
      scheduleTime: '9:00 AM - 11:00 AM',
      workers: 2,
      hours: 2,
      homeType: 'Apartment',
      paymentMethod: 'Credit Card',
      additionalService: 'Window Cleaning',
      finderNote: 'Please clean kitchen and balcony first.',
      serviceInputs: {
        'Cleaning level': 'Deep',
        'Number of rooms': '4',
        'Pets at home': 'No',
      },
      subtotal: 24,
      processingFee: 0,
      discount: 2,
      total: 22,
      state: ProviderOrderState.incoming,
    ),
    ProviderOrderItem(
      id: 'po-102',
      clientName: 'Bora',
      clientPhone: '+855 96 555 221',
      category: 'Plumber',
      serviceName: 'Pipe Leak Repair',
      address: 'Veng Sreng, Phnom Penh, Cambodia',
      addressLink: 'https://maps.google.com/?q=Veng+Sreng,+Phnom+Penh',
      scheduleDate: 'Thu, Mar 8',
      scheduleTime: '1:00 PM - 3:00 PM',
      workers: 1,
      hours: 2,
      homeType: 'Villa',
      paymentMethod: 'Cash',
      additionalService: 'Pipe insulation check',
      finderNote:
          'Leak is behind bathroom sink. Please bring replacement seal.',
      serviceInputs: {
        'Location of leak': 'Bathroom sink',
        'Pipe type': 'Metal',
        'Severity': 'Medium',
        'Water still running': 'Yes',
      },
      subtotal: 20,
      processingFee: 0,
      discount: 2,
      total: 18,
      state: ProviderOrderState.incoming,
    ),
    ProviderOrderItem(
      id: 'po-103',
      clientName: 'Sreynich',
      clientPhone: '+855 11 900 434',
      category: 'Electrician',
      serviceName: 'Wiring Repair',
      address: 'Chbar Ampov, Phnom Penh, Cambodia',
      addressLink: 'https://maps.google.com/?q=Chbar+Ampov,+Phnom+Penh',
      scheduleDate: 'Fri, Mar 9',
      scheduleTime: '9:00 AM - 11:00 AM',
      workers: 1,
      hours: 2,
      homeType: 'Flat',
      paymentMethod: 'Bank account',
      additionalService: '',
      finderNote: 'Frequent power trip in living room and bedroom.',
      serviceInputs: {
        'Area affected': 'Living room + bedroom',
        'Sparks or burn smell': 'No',
        'Power turned off': 'Yes',
      },
      subtotal: 22,
      processingFee: 0,
      discount: 2,
      total: 20,
      state: ProviderOrderState.onTheWay,
    ),
    ProviderOrderItem(
      id: 'po-107',
      clientName: 'Nisa',
      clientPhone: '+855 70 233 818',
      category: 'Cleaner',
      serviceName: 'Office Cleaning',
      address: 'Daun Penh, Phnom Penh, Cambodia',
      addressLink: 'https://maps.google.com/?q=Daun+Penh,+Phnom+Penh',
      scheduleDate: 'Sat, Mar 10',
      scheduleTime: '1:00 PM - 3:00 PM',
      workers: 2,
      hours: 2,
      homeType: 'Office',
      paymentMethod: 'Credit Card',
      additionalService: 'Deep bathroom cleaning',
      finderNote: 'Meeting room must be done before 2 PM.',
      serviceInputs: {
        'Office size': 'Medium',
        'Number of rooms': '6',
        'Frequency': 'One-time',
      },
      subtotal: 28,
      processingFee: 0,
      discount: 2,
      total: 26,
      state: ProviderOrderState.started,
    ),
    ProviderOrderItem(
      id: 'po-104',
      clientName: 'Kimly',
      clientPhone: '+855 77 419 119',
      category: 'Cleaner',
      serviceName: 'House Cleaning',
      address: 'Boeung Keng Kang, Phnom Penh, Cambodia',
      addressLink: 'https://maps.google.com/?q=Boeung+Keng+Kang,+Phnom+Penh',
      scheduleDate: 'Mon, Mar 4',
      scheduleTime: '10:00 AM - 12:00 PM',
      workers: 2,
      hours: 2,
      homeType: 'Apartment',
      paymentMethod: 'Credit Card',
      additionalService: 'Cupboard Cleaning',
      finderNote: 'Client requested eco-friendly cleaning products.',
      serviceInputs: {
        'Cleaning level': 'Normal',
        'Number of rooms': '3',
        'Pets at home': 'Yes',
      },
      subtotal: 26,
      processingFee: 0,
      discount: 2,
      total: 24,
      state: ProviderOrderState.completed,
    ),
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
      title: 'Power Outage Fixes',
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
      title: 'Move-in / Move-out Cleaning',
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
      'JackJohn',
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

  static const List<HomeAddress> homeAddresses = [
    HomeAddress(
      id: 'addr-1',
      label: 'Home',
      street: 'Veng Sreng, Phnom Penh',
      city: 'Cambodia',
      isDefault: true,
    ),
    HomeAddress(
      id: 'addr-2',
      label: 'Home 2',
      street: 'Toul Kork, Phnom Penh',
      city: 'Cambodia',
    ),
  ];

  static const List<int> bookingHourOptions = [1, 2, 3, 4, 5, 6];
  static const List<int> workerCountOptions = [1, 2, 3, 4];
  static const List<String> scheduleTimeOptions = [
    '08:00 AM - 10:00 AM',
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
    '05:00 PM - 07:00 PM',
  ];
  static const List<HomeType> homeTypeOptions = [
    HomeType.apartment,
    HomeType.flat,
    HomeType.villa,
    HomeType.office,
  ];
  static const List<String> additionalServices = [
    'Cupboard Cleaning',
    'Window Cleaning',
    'Balcony Cleaning',
    'Deep Bathroom Cleaning',
  ];
  static const List<String> cancelReasons = [
    "Don't need the service anymore",
    'Not available at this time',
    'Found a better rate elsewhere',
    'Placed the request by mistake',
    'Other',
  ];

  static const Map<String, List<BookingFieldDef>> serviceFieldsByService = {
    'Pipe Leak Repair': [
      BookingFieldDef(
        key: 'locationOfLeak',
        label: 'Location of leak',
        type: BookingFieldType.text,
        required: true,
      ),
      BookingFieldDef(
        key: 'pipeType',
        label: 'Pipe type',
        type: BookingFieldType.dropdown,
        required: true,
        options: ['PVC', 'Metal', 'Unknown'],
      ),
      BookingFieldDef(
        key: 'severity',
        label: 'Severity',
        type: BookingFieldType.dropdown,
        required: true,
        options: ['Small', 'Medium', 'Burst'],
      ),
      BookingFieldDef(
        key: 'waterStillRunning',
        label: 'Water still running',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Toilet Repair': [
      BookingFieldDef(
        key: 'problemType',
        label: 'Problem type',
        type: BookingFieldType.dropdown,
        required: true,
        options: ['Not flushing', 'Leaking', 'Blocked'],
      ),
      BookingFieldDef(
        key: 'toiletType',
        label: 'Toilet type',
        type: BookingFieldType.dropdown,
        options: ['Squat', 'Western'],
      ),
      BookingFieldDef(
        key: 'waterOverflowing',
        label: 'Water overflowing',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Water Installation': [
      BookingFieldDef(
        key: 'installationType',
        label: 'Installation type',
        type: BookingFieldType.dropdown,
        required: true,
        options: ['Sink', 'Shower', 'Pipe', 'Tank'],
      ),
      BookingFieldDef(
        key: 'numberOfPoints',
        label: 'Number of points',
        type: BookingFieldType.number,
      ),
      BookingFieldDef(
        key: 'materialProvidedBy',
        label: 'Material provided by',
        type: BookingFieldType.dropdown,
        options: ['Customer', 'Technician'],
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Wiring Repair': [
      BookingFieldDef(
        key: 'problemDescription',
        label: 'Problem description',
        type: BookingFieldType.multiline,
        required: true,
      ),
      BookingFieldDef(
        key: 'areaAffected',
        label: 'Area affected',
        type: BookingFieldType.text,
      ),
      BookingFieldDef(
        key: 'sparksOrBurnSmell',
        label: 'Sparks or burn smell',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'powerTurnedOff',
        label: 'Power turned off',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Light / Fan Installation': [
      BookingFieldDef(
        key: 'deviceType',
        label: 'Device type',
        type: BookingFieldType.dropdown,
        options: ['Light', 'Fan', 'Both'],
      ),
      BookingFieldDef(
        key: 'quantity',
        label: 'Quantity',
        type: BookingFieldType.number,
      ),
      BookingFieldDef(
        key: 'ceilingType',
        label: 'Ceiling type',
        type: BookingFieldType.dropdown,
        options: ['Concrete', 'Wood', 'Gypsum'],
      ),
      BookingFieldDef(
        key: 'deviceProvided',
        label: 'Device provided',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Power Outage Fixes': [
      BookingFieldDef(
        key: 'outageScope',
        label: 'Outage scope',
        type: BookingFieldType.dropdown,
        options: ['One room', 'Whole house'],
      ),
      BookingFieldDef(
        key: 'breakerTripped',
        label: 'Breaker tripped',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'neighborsAffected',
        label: 'Neighbors affected',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
    ],
    'House Cleaning': [
      BookingFieldDef(
        key: 'houseType',
        label: 'House type',
        type: BookingFieldType.dropdown,
        required: true,
        options: ['Apartment', 'Villa', 'Room'],
      ),
      BookingFieldDef(
        key: 'numberOfRooms',
        label: 'Number of rooms',
        type: BookingFieldType.number,
      ),
      BookingFieldDef(
        key: 'cleaningLevel',
        label: 'Cleaning level',
        type: BookingFieldType.dropdown,
        options: ['Light', 'Normal', 'Deep'],
      ),
      BookingFieldDef(
        key: 'petsAtHome',
        label: 'Pets at home',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Office Cleaning': [
      BookingFieldDef(
        key: 'officeSize',
        label: 'Office size',
        type: BookingFieldType.dropdown,
        options: ['Small', 'Medium', 'Large'],
      ),
      BookingFieldDef(
        key: 'numberOfRooms',
        label: 'Number of rooms',
        type: BookingFieldType.number,
      ),
      BookingFieldDef(
        key: 'frequency',
        label: 'Frequency',
        type: BookingFieldType.dropdown,
        options: ['One-time', 'Weekly', 'Monthly'],
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Move-in / Move-out Cleaning': [
      BookingFieldDef(
        key: 'propertySize',
        label: 'Property size',
        type: BookingFieldType.dropdown,
        options: ['Small', 'Medium', 'Large'],
      ),
      BookingFieldDef(
        key: 'furnished',
        label: 'Furnished',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'heavyStains',
        label: 'Heavy stains',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Air Conditioner Repair': [
      BookingFieldDef(
        key: 'acType',
        label: 'AC type',
        type: BookingFieldType.dropdown,
        options: ['Split', 'Window', 'Cassette'],
      ),
      BookingFieldDef(
        key: 'problemType',
        label: 'Problem type',
        type: BookingFieldType.dropdown,
        options: ['Not cooling', 'Leaking', 'No power'],
      ),
      BookingFieldDef(
        key: 'lastServiceDate',
        label: 'Last service date',
        type: BookingFieldType.text,
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Washing Machine Repair': [
      BookingFieldDef(
        key: 'machineType',
        label: 'Machine type',
        type: BookingFieldType.dropdown,
        options: ['Front load', 'Top load'],
      ),
      BookingFieldDef(
        key: 'problemType',
        label: 'Problem type',
        type: BookingFieldType.dropdown,
        options: ['Not spinning', 'Leaking', 'No power'],
      ),
      BookingFieldDef(
        key: 'brand',
        label: 'Brand',
        type: BookingFieldType.text,
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Refrigerator Repair': [
      BookingFieldDef(
        key: 'problemType',
        label: 'Problem type',
        type: BookingFieldType.dropdown,
        options: ['Not cold', 'Freezer issue', 'Noise'],
      ),
      BookingFieldDef(
        key: 'brand',
        label: 'Brand',
        type: BookingFieldType.text,
      ),
      BookingFieldDef(
        key: 'powerOn',
        label: 'Power on',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Door & Window Repair': [
      BookingFieldDef(
        key: 'materialType',
        label: 'Material type',
        type: BookingFieldType.dropdown,
        options: ['Wood', 'Aluminum', 'Glass'],
      ),
      BookingFieldDef(
        key: 'problemType',
        label: 'Problem type',
        type: BookingFieldType.dropdown,
        options: ['Broken', 'Hard to open', 'Off hinge'],
      ),
      BookingFieldDef(
        key: 'quantity',
        label: 'Quantity',
        type: BookingFieldType.number,
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Furniture Fixing': [
      BookingFieldDef(
        key: 'furnitureType',
        label: 'Furniture type',
        type: BookingFieldType.dropdown,
        options: ['Bed', 'Table', 'Chair', 'Cabinet'],
      ),
      BookingFieldDef(
        key: 'problemType',
        label: 'Problem type',
        type: BookingFieldType.dropdown,
        options: ['Loose', 'Broken', 'Assembly'],
      ),
      BookingFieldDef(
        key: 'quantity',
        label: 'Quantity',
        type: BookingFieldType.number,
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
    'Shelf / Curtain Installation': [
      BookingFieldDef(
        key: 'installationType',
        label: 'Installation type',
        type: BookingFieldType.dropdown,
        options: ['Shelf', 'Curtain rod'],
      ),
      BookingFieldDef(
        key: 'wallType',
        label: 'Wall type',
        type: BookingFieldType.dropdown,
        options: ['Concrete', 'Gypsum', 'Wood'],
      ),
      BookingFieldDef(
        key: 'quantity',
        label: 'Quantity',
        type: BookingFieldType.number,
      ),
      BookingFieldDef(
        key: 'itemProvided',
        label: 'Item provided',
        type: BookingFieldType.toggle,
      ),
      BookingFieldDef(
        key: 'photo',
        label: 'Upload photo',
        type: BookingFieldType.photo,
      ),
      BookingFieldDef(
        key: 'notes',
        label: 'Notes',
        type: BookingFieldType.multiline,
      ),
    ],
  };

  static const Map<String, List<String>> providerServiceOverrides = {
    'Ethan Iita': ['Pipe Leak Repair', 'Toilet Repair'],
    'Isabella Una': ['Toilet Repair', 'Water Installation'],
    'Jackson': ['Wiring Repair', 'Light / Fan Installation'],
    'Logan': ['Wiring Repair', 'Power Outage Fixes'],
    'Vichea Cleaning': ['House Cleaning', 'Office Cleaning'],
    'GC Cleaning': ['House Cleaning', 'Move-in / Move-out Cleaning'],
  };

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

  static List<ProviderOrderItem> providerOrders() {
    return providerOrdersSeed.toList();
  }

  static List<ProviderItem> providersByCategory(String category) {
    return providerSectionForCategory(category)?.providers ?? [];
  }

  static ProviderSection? providerSectionForCategory(String category) {
    for (final section in providerSections) {
      if (section.category.toLowerCase() == category.toLowerCase()) {
        return section;
      }
    }
    return null;
  }

  static Category? categoryByName(String category) {
    for (final item in categories) {
      if (item.name.toLowerCase() == category.toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  static BookingDraft defaultBookingDraft({
    required ProviderItem provider,
    String? serviceName,
  }) {
    final available = servicesForProvider(provider);
    final preferred = serviceName ?? _defaultServiceByRole(provider.role);
    final resolvedService = available.contains(preferred)
        ? preferred
        : (available.isNotEmpty ? available.first : preferred);
    return BookingDraft(
      provider: provider,
      categoryName: _categoryFromRole(provider.role),
      serviceName: resolvedService,
      address: homeAddresses.first,
      preferredDate: DateTime.now().add(const Duration(days: 1)),
      preferredTimeSlot: scheduleTimeOptions[1],
      hours: 2,
      homeType: HomeType.apartment,
      workers: 2,
      additionalService: '',
      paymentMethod: PaymentMethod.creditCard,
      promoCode: 'WELCOME20',
      unitPricePerHour: 11,
      serviceFields: initialFieldValuesForService(resolvedService),
    );
  }

  static List<String> servicesForCategory(String categoryName) {
    return services
        .where((service) => service.category == categoryName)
        .map((service) => service.title)
        .toList();
  }

  static List<String> servicesForProvider(ProviderItem provider) {
    final override = providerServiceOverrides[provider.name];
    if (override != null && override.isNotEmpty) return override;
    return servicesForCategory(_categoryFromRole(provider.role));
  }

  static bool providerSupportsService(
    ProviderItem provider,
    String serviceName,
  ) {
    return servicesForProvider(provider).contains(serviceName);
  }

  static final List<OrderItem> orders = [
    _seedOrder(
      id: '7890128',
      provider: cleanerProviders[6],
      serviceName: 'Indoor Cleaning',
      status: OrderStatus.started,
      hours: 2,
      workers: 2,
      dayOffset: 1,
    ),
    _seedOrder(
      id: '7890136',
      provider: plumberProviders[1],
      serviceName: 'Pipe Leak Repair',
      status: OrderStatus.onTheWay,
      hours: 2,
      workers: 1,
      dayOffset: 2,
    ),
    _seedOrder(
      id: '7890054',
      provider: cleanerProviders[0],
      serviceName: 'Indoor Cleaning',
      status: OrderStatus.completed,
      hours: 2,
      workers: 2,
      dayOffset: -3,
      rating: 4.5,
    ),
  ];

  static OrderItem createOrderFromDraft(BookingDraft draft) {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString().substring(6);
    return OrderItem(
      id: id,
      provider: draft.provider,
      serviceName: draft.serviceName,
      address: draft.address ?? homeAddresses.first,
      hours: draft.hours,
      workers: draft.workers,
      homeType: draft.homeType,
      additionalService: draft.additionalService,
      bookedAt: now,
      scheduledAt: DateTime(
        draft.preferredDate.year,
        draft.preferredDate.month,
        draft.preferredDate.day,
        9,
      ),
      timeRange: draft.preferredTimeSlot,
      paymentMethod: draft.paymentMethod,
      subtotal: draft.subtotal,
      processingFee: draft.processingFee,
      discount: draft.discount,
      status: OrderStatus.booked,
    );
  }

  static List<OrderItem> inProgressOrders([OrderItem? latest]) {
    final list = orders
        .where(
          (order) =>
              order.status != OrderStatus.completed &&
              order.status != OrderStatus.cancelled,
        )
        .toList();
    if (latest != null) list.insert(0, latest);
    return list;
  }

  static List<OrderItem> completedOrders() {
    return orders
        .where((order) => order.status == OrderStatus.completed)
        .toList();
  }

  static const List<String> _reviewComments = [
    'Very professional and on time. The work was clean and detailed.',
    'Excellent communication and quality. I will book again for sure.',
    'Quick response and fair pricing. Problem solved in one visit.',
    'Polite team and neat finishing. Highly recommended.',
    'Came prepared with tools and completed everything perfectly.',
    'Very friendly provider and clear explanation before starting work.',
    'Good service overall and finished earlier than expected.',
    'Reliable and punctual. Great attention to details.',
    'Job quality was strong and they kept the place tidy.',
    'Smooth process from booking to completion.',
  ];

  static const List<String> _reviewerNames = [
    'Kimheng',
    'Marly',
    'Hokley',
    'Sopha',
    'Nary',
    'Bunly',
    'Monich',
    'Dara',
    'Sokun',
    'Vireak',
  ];

  static ProviderProfile profileFor(ProviderItem provider) {
    final seed = _nameSeed(provider.name);
    final reviews = _buildReviews(seed: seed);
    return ProviderProfile(
      provider: provider,
      location: 'PP, Cambodia',
      available: seed % 4 != 0,
      completedJobs: 20 + (seed % 45),
      about:
          'We are a professional ${provider.role.toLowerCase()} team with years of field experience. '
          'Our service focuses on reliability, clean work, and clear communication. '
          'We use quality tools and follow safety standards to deliver consistent results.',
      projectImages: const [
        'assets/images/plumber_category.jpg',
        'assets/images/plumber_category.jpg',
        'assets/images/plumber_category.jpg',
      ],
      reviews: reviews,
    );
  }

  static List<ProviderReview> reviewsByRange(
    ProviderProfile profile,
    ReviewRange range,
  ) {
    return profile.reviews
        .where((review) => review.daysAgo <= range.maxDays)
        .toList();
  }

  static final List<ChatThread> chats = [
    _buildThread(
      id: 'vichea_cleaning',
      title: 'Vichea Cleaning',
      subtitle: 'Cleaning service',
      unreadCount: 1,
    ),
    _buildThread(
      id: 'eang_kimheng',
      title: 'Eang Kimheng',
      subtitle: 'House service',
      unreadCount: 0,
    ),
    _buildThread(
      id: 'jackson_plumber',
      title: 'Jackson',
      subtitle: 'Plumbing support',
      unreadCount: 2,
    ),
  ];

  static ChatThread chatForProvider(ProviderItem provider) {
    for (final thread in chats) {
      if (thread.title.toLowerCase() == provider.name.toLowerCase()) {
        return thread;
      }
    }
    return _buildThread(
      id: provider.name.toLowerCase().replaceAll(' ', '_'),
      title: provider.name,
      subtitle: '${provider.role} support',
      unreadCount: 0,
    );
  }

  static List<ProviderReview> _buildReviews({required int seed}) {
    final reviews = <ProviderReview>[];
    for (var i = 0; i < 10; i++) {
      final score = 4.0 + ((seed + i) % 9) * 0.1;
      final safeScore = double.parse(score.clamp(3.8, 4.9).toStringAsFixed(1));
      final name = _reviewerNames[i % _reviewerNames.length];
      final initials = name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name.toUpperCase();
      reviews.add(
        ProviderReview(
          reviewerName: name,
          reviewerInitials: initials,
          rating: safeScore,
          daysAgo: 8 + i * 11,
          comment: _reviewComments[(seed + i) % _reviewComments.length],
        ),
      );
    }
    return reviews;
  }

  static ChatThread _buildThread({
    required String id,
    required String title,
    required String subtitle,
    required int unreadCount,
  }) {
    final now = DateTime.now();
    return ChatThread(
      id: id,
      title: title,
      subtitle: subtitle,
      avatarPath: 'assets/images/profile.jpg',
      updatedAt: now.subtract(Duration(minutes: 12 + unreadCount * 8)),
      unreadCount: unreadCount,
      messages: [
        ChatMessage(
          text: 'Hello ${title.split(' ').first}!',
          fromMe: true,
          sentAt: now.subtract(const Duration(minutes: 18)),
        ),
        ChatMessage(
          text: 'Hello sir, how can I help you today?',
          fromMe: false,
          sentAt: now.subtract(const Duration(minutes: 16)),
        ),
        ChatMessage(
          text: 'I need support for cleaning this afternoon.',
          fromMe: true,
          sentAt: now.subtract(const Duration(minutes: 12)),
        ),
        ChatMessage(
          text: 'Sure. I can reach you soon.',
          fromMe: false,
          sentAt: now.subtract(const Duration(minutes: 10)),
        ),
      ],
    );
  }

  static int _nameSeed(String name) {
    return name.codeUnits.fold<int>(0, (sum, value) => sum + value);
  }

  static List<BookingFieldDef> bookingFieldsForService(String serviceName) {
    return serviceFieldsByService[serviceName] ?? const [];
  }

  static Map<String, dynamic> initialFieldValuesForService(String serviceName) {
    final values = <String, dynamic>{};
    for (final field in bookingFieldsForService(serviceName)) {
      switch (field.type) {
        case BookingFieldType.toggle:
        case BookingFieldType.photo:
          values[field.key] = false;
          break;
        case BookingFieldType.dropdown:
          values[field.key] = field.options.isNotEmpty
              ? field.options.first
              : '';
          break;
        case BookingFieldType.number:
          values[field.key] = '1';
          break;
        case BookingFieldType.text:
        case BookingFieldType.multiline:
          values[field.key] = '';
          break;
      }
    }
    return values;
  }

  static String _defaultServiceByRole(String role) {
    switch (role.toLowerCase()) {
      case 'plumber':
        return 'Pipe Leak Repair';
      case 'electrician':
        return 'Wiring Repair';
      case 'cleaner':
        return 'Indoor Cleaning';
      case 'appliance':
        return 'Air Conditioner Repair';
      default:
        return 'Home Maintenance';
    }
  }

  static String _categoryFromRole(String role) {
    switch (role.toLowerCase()) {
      case 'appliance':
        return 'Home Appliance';
      case 'maintenance':
        return 'Home Maintenance';
      default:
        return role;
    }
  }

  static OrderItem _seedOrder({
    required String id,
    required ProviderItem provider,
    required String serviceName,
    required OrderStatus status,
    required int hours,
    required int workers,
    required int dayOffset,
    double? rating,
  }) {
    final scheduled = DateTime.now().add(Duration(days: dayOffset));
    return OrderItem(
      id: id,
      provider: provider,
      serviceName: serviceName,
      address: homeAddresses.first,
      hours: hours,
      workers: workers,
      homeType: HomeType.flat,
      additionalService: additionalServices.first,
      bookedAt: scheduled.subtract(const Duration(days: 1)),
      scheduledAt: scheduled,
      timeRange: '9:00 AM - 11:00 AM',
      paymentMethod: PaymentMethod.creditCard,
      subtotal: 22,
      processingFee: 0,
      discount: 2,
      status: status,
      rating: rating,
    );
  }
}
