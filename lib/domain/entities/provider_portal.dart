enum ProviderOrderState { incoming, onTheWay, started, completed, declined }

class FinderPostItem {
  final String id;
  final String clientName;
  final String message;
  final String timeLabel;
  final String category;
  final String service;
  final String location;
  final String avatarPath;

  const FinderPostItem({
    required this.id,
    required this.clientName,
    required this.message,
    required this.timeLabel,
    required this.category,
    required this.service,
    required this.location,
    required this.avatarPath,
  });
}

class ProviderOrderItem {
  final String id;
  final String clientName;
  final String clientPhone;
  final String category;
  final String serviceName;
  final String address;
  final String addressLink;
  final String scheduleDate;
  final String scheduleTime;
  final int workers;
  final int hours;
  final String homeType;
  final String paymentMethod;
  final String additionalService;
  final String finderNote;
  final Map<String, String> serviceInputs;
  final double subtotal;
  final double processingFee;
  final double discount;
  final double total;
  final ProviderOrderState state;

  const ProviderOrderItem({
    required this.id,
    required this.clientName,
    this.clientPhone = '',
    required this.category,
    required this.serviceName,
    required this.address,
    this.addressLink = '',
    required this.scheduleDate,
    required this.scheduleTime,
    required this.workers,
    required this.hours,
    this.homeType = '',
    this.paymentMethod = '',
    this.additionalService = '',
    this.finderNote = '',
    this.serviceInputs = const {},
    double? subtotal,
    double? processingFee,
    double? discount,
    required this.total,
    required this.state,
  }) : subtotal = subtotal ?? total,
       processingFee = processingFee ?? 0,
       discount = discount ?? 0;

  ProviderOrderItem copyWith({ProviderOrderState? state}) {
    return ProviderOrderItem(
      id: id,
      clientName: clientName,
      clientPhone: clientPhone,
      category: category,
      serviceName: serviceName,
      address: address,
      addressLink: addressLink,
      scheduleDate: scheduleDate,
      scheduleTime: scheduleTime,
      workers: workers,
      hours: hours,
      homeType: homeType,
      paymentMethod: paymentMethod,
      additionalService: additionalService,
      finderNote: finderNote,
      serviceInputs: serviceInputs,
      subtotal: subtotal,
      processingFee: processingFee,
      discount: discount,
      total: total,
      state: state ?? this.state,
    );
  }
}
