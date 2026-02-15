import '../../domain/entities/order.dart';
import '../../domain/entities/provider.dart';
import 'catalog_state.dart';

class BookingCatalogState {
  static const List<HomeAddress> homeAddresses = <HomeAddress>[
    HomeAddress(
      id: 'addr-home',
      label: 'Home',
      street: 'Phnom Penh',
      city: 'Cambodia',
      isDefault: true,
    ),
    HomeAddress(
      id: 'addr-work',
      label: 'Work',
      street: 'Sen Sok, Phnom Penh',
      city: 'Cambodia',
    ),
  ];

  static const List<int> bookingHourOptions = <int>[1, 2, 3, 4, 5, 6];
  static const List<int> workerCountOptions = <int>[1, 2, 3, 4];
  static const List<String> scheduleTimeOptions = <String>[
    '08:00 AM - 10:00 AM',
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
    '05:00 PM - 07:00 PM',
  ];
  static const List<HomeType> homeTypeOptions = <HomeType>[
    HomeType.apartment,
    HomeType.flat,
    HomeType.villa,
    HomeType.office,
  ];
  static const List<String> cancelReasons = <String>[
    "Don't need the service anymore",
    'Not available at this time',
    'Found a better rate elsewhere',
    'Placed the request by mistake',
    'Other',
  ];

  static BookingDraft defaultBookingDraft({
    required ProviderItem provider,
    String? serviceName,
  }) {
    final categoryName = CatalogState.categoryForProviderRole(provider.role);
    final providerServices = provider.services
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final available = providerServices.isNotEmpty
        ? providerServices
        : CatalogState.servicesForCategory(categoryName);
    final preferred = serviceName?.trim() ?? '';
    final resolvedService = available.contains(preferred)
        ? preferred
        : (available.isNotEmpty
              ? available.first
              : _defaultServiceFor(categoryName));

    return BookingDraft(
      provider: provider,
      categoryName: categoryName,
      serviceName: resolvedService,
      address: homeAddresses.first,
      preferredDate: DateTime.now().add(const Duration(days: 1)),
      preferredTimeSlot: scheduleTimeOptions[1],
      hours: 2,
      homeType: HomeType.apartment,
      workers: 1,
      paymentMethod: PaymentMethod.creditCard,
      additionalService: '',
      promoCode: '',
      unitPricePerHour: 12,
      serviceFields: initialFieldValuesForService(resolvedService),
    );
  }

  static List<BookingFieldDef> bookingFieldsForService(String serviceName) {
    final canonical = _canonicalServiceName(serviceName);
    return _serviceFieldsByService[canonical] ?? _genericServiceFields;
  }

  static Map<String, dynamic> initialFieldValuesForService(String serviceName) {
    final defs = bookingFieldsForService(serviceName);
    final values = <String, dynamic>{};
    for (final field in defs) {
      switch (field.type) {
        case BookingFieldType.toggle:
        case BookingFieldType.photo:
          values[field.key] = false;
          break;
        case BookingFieldType.dropdown:
          values[field.key] = field.options.isEmpty ? '' : field.options.first;
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

  static String _defaultServiceFor(String categoryName) {
    final value = categoryName.trim().toLowerCase();
    if (value.contains('plumb')) return 'Pipe Leak Repair';
    if (value.contains('electric')) return 'Wiring Repair';
    if (value.contains('clean')) return 'House Cleaning';
    if (value.contains('appliance')) return 'Air Conditioner Repair';
    return 'Door & Window Repair';
  }

  static String _canonicalServiceName(String serviceName) {
    switch (serviceName.trim()) {
      case 'AC Repair':
        return 'Air Conditioner Repair';
      case 'Door Repair':
        return 'Door & Window Repair';
      default:
        return serviceName.trim();
    }
  }

  static const List<BookingFieldDef> _genericServiceFields = <BookingFieldDef>[
    BookingFieldDef(
      key: 'issueSummary',
      label: 'Issue summary',
      type: BookingFieldType.multiline,
      required: true,
    ),
    BookingFieldDef(
      key: 'urgent',
      label: 'Urgent request',
      type: BookingFieldType.toggle,
    ),
    BookingFieldDef(
      key: 'photo',
      label: 'Upload photo',
      type: BookingFieldType.photo,
    ),
  ];

  static const Map<String, List<BookingFieldDef>> _serviceFieldsByService =
      <String, List<BookingFieldDef>>{
        'Pipe Leak Repair': <BookingFieldDef>[
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
            options: <String>['PVC', 'Metal', 'Unknown'],
          ),
          BookingFieldDef(
            key: 'severity',
            label: 'Severity',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Small', 'Medium', 'Burst'],
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
        ],
        'Toilet Repair': <BookingFieldDef>[
          BookingFieldDef(
            key: 'problemType',
            label: 'Problem type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Not flushing', 'Leaking', 'Blocked'],
          ),
          BookingFieldDef(
            key: 'toiletType',
            label: 'Toilet type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Squat', 'Western'],
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
        'Water Installation': <BookingFieldDef>[
          BookingFieldDef(
            key: 'installationType',
            label: 'Installation type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Sink', 'Shower', 'Pipe', 'Tank'],
          ),
          BookingFieldDef(
            key: 'numberOfPoints',
            label: 'Number of points',
            type: BookingFieldType.number,
            required: true,
          ),
          BookingFieldDef(
            key: 'materialProvidedBy',
            label: 'Material provided by',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Customer', 'Technician'],
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
        'Wiring Repair': <BookingFieldDef>[
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
            required: true,
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
        ],
        'Light / Fan Installation': <BookingFieldDef>[
          BookingFieldDef(
            key: 'deviceType',
            label: 'Device type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Light', 'Fan', 'Both'],
          ),
          BookingFieldDef(
            key: 'quantity',
            label: 'Quantity',
            type: BookingFieldType.number,
            required: true,
          ),
          BookingFieldDef(
            key: 'ceilingType',
            label: 'Ceiling type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Concrete', 'Wood', 'Gypsum'],
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
        ],
        'Power Outage Fixes': <BookingFieldDef>[
          BookingFieldDef(
            key: 'outageScope',
            label: 'Outage scope',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['One room', 'Whole house'],
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
        'House Cleaning': <BookingFieldDef>[
          BookingFieldDef(
            key: 'houseType',
            label: 'House type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Apartment', 'Villa', 'Room'],
          ),
          BookingFieldDef(
            key: 'cleaningLevel',
            label: 'Cleaning level',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Light', 'Normal', 'Deep'],
          ),
          BookingFieldDef(
            key: 'numberOfRooms',
            label: 'Number of rooms',
            type: BookingFieldType.number,
            required: true,
          ),
          BookingFieldDef(
            key: 'petsAtHome',
            label: 'Pets at home',
            type: BookingFieldType.toggle,
          ),
        ],
        'Office Cleaning': <BookingFieldDef>[
          BookingFieldDef(
            key: 'officeSize',
            label: 'Office size',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Small', 'Medium', 'Large'],
          ),
          BookingFieldDef(
            key: 'numberOfRooms',
            label: 'Number of rooms',
            type: BookingFieldType.number,
            required: true,
          ),
          BookingFieldDef(
            key: 'frequency',
            label: 'Frequency',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['One-time', 'Weekly', 'Monthly'],
          ),
          BookingFieldDef(
            key: 'notes',
            label: 'Notes',
            type: BookingFieldType.multiline,
          ),
        ],
        'Move-in / Move-out Cleaning': <BookingFieldDef>[
          BookingFieldDef(
            key: 'propertySize',
            label: 'Property size',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Small', 'Medium', 'Large'],
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
        'Air Conditioner Repair': <BookingFieldDef>[
          BookingFieldDef(
            key: 'acType',
            label: 'AC type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Split', 'Window', 'Cassette'],
          ),
          BookingFieldDef(
            key: 'problemType',
            label: 'Problem type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Not cooling', 'Leaking', 'No power'],
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
        ],
        'Washing Machine Repair': <BookingFieldDef>[
          BookingFieldDef(
            key: 'machineType',
            label: 'Machine type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Front load', 'Top load'],
          ),
          BookingFieldDef(
            key: 'problemType',
            label: 'Problem type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Not spinning', 'Leaking', 'No power'],
          ),
          BookingFieldDef(
            key: 'brand',
            label: 'Brand',
            type: BookingFieldType.text,
            required: true,
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
        'Refrigerator Repair': <BookingFieldDef>[
          BookingFieldDef(
            key: 'problemType',
            label: 'Problem type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Not cold', 'Freezer issue', 'Noise'],
          ),
          BookingFieldDef(
            key: 'brand',
            label: 'Brand',
            type: BookingFieldType.text,
            required: true,
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
        'Door & Window Repair': <BookingFieldDef>[
          BookingFieldDef(
            key: 'materialType',
            label: 'Material type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Wood', 'Aluminum', 'Glass'],
          ),
          BookingFieldDef(
            key: 'problemType',
            label: 'Problem type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Broken', 'Hard to open', 'Off hinge'],
          ),
          BookingFieldDef(
            key: 'quantity',
            label: 'Quantity',
            type: BookingFieldType.number,
            required: true,
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
        'Furniture Fixing': <BookingFieldDef>[
          BookingFieldDef(
            key: 'furnitureType',
            label: 'Furniture type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Bed', 'Table', 'Chair', 'Cabinet'],
          ),
          BookingFieldDef(
            key: 'problemType',
            label: 'Problem type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Loose', 'Broken', 'Assembly'],
          ),
          BookingFieldDef(
            key: 'quantity',
            label: 'Quantity',
            type: BookingFieldType.number,
            required: true,
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
        'Shelf / Curtain Installation': <BookingFieldDef>[
          BookingFieldDef(
            key: 'installationType',
            label: 'Installation type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Shelf', 'Curtain rod'],
          ),
          BookingFieldDef(
            key: 'wallType',
            label: 'Wall type',
            type: BookingFieldType.dropdown,
            required: true,
            options: <String>['Concrete', 'Gypsum', 'Wood'],
          ),
          BookingFieldDef(
            key: 'quantity',
            label: 'Quantity',
            type: BookingFieldType.number,
            required: true,
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
}
