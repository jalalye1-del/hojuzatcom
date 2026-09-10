import '../../bookings/presentation/provider_booking_flow.dart';

class BeautyService {
  const BeautyService({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.price,
    required this.iconName,
    this.expectedSessions = 'جلسة واحدة',
    this.resultSummary = 'نتائج تدريجية حسب تقييم المختص',
  });

  final String id;
  final String name;
  final String category;
  final int durationMinutes;
  final int price;
  final String iconName;
  final String expectedSessions;
  final String resultSummary;
}

class BeautyCenter {
  const BeautyCenter({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.rating,
    required this.reviews,
    required this.description,
    required this.features,
    required this.specialists,
    required this.services,
  });

  final String id;
  final String name;
  final String city;
  final String district;
  final double rating;
  final int reviews;
  final String description;
  final List<String> features;
  final List<String> specialists;
  final List<BeautyService> services;
}

List<BeautyCenter> get beautyCenters {
  final flow = ProviderBookingFlow.current;
  if (flow == null) return const <BeautyCenter>[];
  final all = flow.loaded('beauty');
  final ids = all.map((service) => service.providerId).toSet();
  return ids.map((id) {
    final services = all.where((service) => service.providerId == id).toList();
    final provider = services.first.provider;
    return BeautyCenter(
      id: id,
      name: provider?.displayName ?? '',
      city: provider?.province ?? '',
      district: provider?.address ?? '',
      rating: 0,
      reviews: 0,
      description: '',
      features: const [],
      specialists: const [],
      services: services
          .map(
            (service) => BeautyService(
              id: service.id,
              name: service.displayName,
              category: service.category?.displayName ?? '',
              durationMinutes: service.durationMinutes ?? 0,
              price: service.basePrice,
              iconName: 'face',
            ),
          )
          .toList(),
    );
  }).toList();
}
