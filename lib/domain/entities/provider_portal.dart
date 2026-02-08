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
  final String category;
  final String serviceName;
  final String address;
  final String scheduleDate;
  final String scheduleTime;
  final int workers;
  final int hours;
  final double total;
  final ProviderOrderState state;

  const ProviderOrderItem({
    required this.id,
    required this.clientName,
    required this.category,
    required this.serviceName,
    required this.address,
    required this.scheduleDate,
    required this.scheduleTime,
    required this.workers,
    required this.hours,
    required this.total,
    required this.state,
  });

  ProviderOrderItem copyWith({ProviderOrderState? state}) {
    return ProviderOrderItem(
      id: id,
      clientName: clientName,
      category: category,
      serviceName: serviceName,
      address: address,
      scheduleDate: scheduleDate,
      scheduleTime: scheduleTime,
      workers: workers,
      hours: hours,
      total: total,
      state: state ?? this.state,
    );
  }
}
