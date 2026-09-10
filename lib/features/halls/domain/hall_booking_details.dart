import '../../bookings/presentation/provider_booking_flow.dart';

class HallBookingDetails {
  HallBookingDetails({
    required this.name,
    this.serviceId,
    required this.province,
    required this.date,
    required this.period,
    required this.event,
    required this.guests,
    required this.package,
  }) : reference = ProviderBookingFlow.current == null
           ? 'HALL-${DateTime.now().microsecondsSinceEpoch}'
           : 'يصدر بعد إرسال الطلب';
  final String name, province, period, event, package, reference;
  final String? serviceId;
  final DateTime date;
  final int guests;
  int get total {
    final flow = ProviderBookingFlow.current;
    if (flow != null) {
      final services = flow
          .loaded('halls')
          .where(
            (service) =>
                service.serviceType == 'event_hall' &&
                (serviceId == null
                    ? service.displayName == name
                    : service.id == serviceId) &&
                service.provider?.province == province,
          )
          .toList();
      return services.length == 1 ? services.single.basePrice : 0;
    }
    return switch (package) {
      'الأساسية' => 450000,
      'الملكية' => 850000,
      _ => 620000,
    };
  }

  String get dateLabel =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  DateTime get start =>
      DateTime(date.year, date.month, date.day, period == 'صباحية' ? 9 : 14);
  DateTime get end => start.add(Duration(hours: period == 'صباحية' ? 4 : 10));
}
