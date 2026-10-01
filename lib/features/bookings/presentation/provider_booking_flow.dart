import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/network/api_exception.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog_models.dart';
import '../data/booking_repository.dart';
import '../domain/booking.dart';

class ProviderBookingSelection {
  const ProviderBookingSelection({
    required this.module,
    required this.serviceName,
    this.serviceId,
    this.providerName,
    this.providerId,
    this.orderItems = const {},
    this.province,
    this.quantity = 1,
    this.scheduledAt,
    this.expectedTotal,
    this.metadata = const {},
  });

  final String module;
  final String serviceName;
  final String? serviceId;
  final String? providerName;
  final String? providerId;
  final Map<String, int> orderItems;
  final String? province;
  final int quantity;
  final DateTime? scheduledAt;
  final int? expectedTotal;
  final Map<String, Object?> metadata;
}

class ProviderBookingFlow {
  ProviderBookingFlow({required this.catalog, required this.bookings});

  final CatalogRepository catalog;
  final BookingRepository bookings;
  static ProviderBookingFlow? current;
  final Map<String, List<CatalogService>> snapshots = {};
  List<CatalogService> loaded(String module) => snapshots[module] ?? const [];
  Future<void> load(String module, {String? province}) async {
    snapshots[module] = await services(module, province: province);
  }

  String? providerFor(String module, String id) {
    for (final item in loaded(module)) {
      if (item.id == id) return item.provider?.displayName;
    }
    return null;
  }

  static const serviceTypes = <String, List<String>>{
    'hotels': ['hotel_room'],
    'restaurants': [
      'restaurant_order',
      'restaurant_table',
      'restaurant_reservation',
    ],
    'delivery': ['delivery', 'quick_delivery'],
    'apartments': ['apartment', 'furnished_apartment'],
    'car_rental': ['car_rental', 'vehicle_rental'],
    'land_transport': ['land_transport'],
    'freight': ['shipping', 'domestic_shipping'],
    'halls': ['event_hall', 'event_service'],
    'travel': [
      'travel_service',
      'travel_package',
      'flight_ticket',
      'tourist_visa',
      'work_visa',
      'administrative',
    ],
    'chalets': ['chalet'],
    'resorts': ['resort'],
    'beauty': ['beauty'],
  };
  Future<List<CatalogService>> services(
    String module, {
    String? province,
  }) async {
    final result = <String, CatalogService>{};
    for (final type in serviceTypes[module] ?? const <String>[]) {
      var page = 1;
      while (true) {
        final response = await catalog.listServices(
          serviceType: type,
          page: page,
          perPage: 50,
        );
        for (final item in response.items) {
          if ((item.serviceType == null || item.serviceType == type) &&
              (province == null ||
                  province.isEmpty ||
                  item.provider?.province == province)) {
            result[item.id] = item;
          }
        }
        if (!response.hasMore) break;
        page++;
      }
    }
    return result.values.toList();
  }

  Future<CatalogService> resolve(ProviderBookingSelection selection) async {
    final candidates = await services(
      selection.module,
      province: selection.province,
    );
    final matches = candidates.where((service) {
      if (selection.providerId != null &&
          service.providerId != selection.providerId) {
        return false;
      }
      if (selection.serviceId != null) {
        return service.id == selection.serviceId;
      }
      return service.displayName.trim() == selection.serviceName.trim() &&
          selection.module != 'hotels' &&
          (selection.providerName == null ||
              service.provider?.displayName.trim() ==
                  selection.providerName!.trim());
    }).toList();
    if (matches.length != 1) {
      throw const ApiException(
        code: 'service_not_available',
        message:
            'هذه الخدمة غير متاحة للحجز بعد. يرجى اختيار خدمة أضافها مقدم الخدمة.',
      );
    }
    return catalog.getService(matches.single.id);
  }

  int quantityFor(CatalogService service, int requestedQuantity) =>
      service.pricingUnit == 'per_booking' ? 1 : requestedQuantity;

  Future<Booking> create(
    ProviderBookingSelection selection, {
    String? availabilityId,
  }) async {
    final orderItems = <Map<String, Object?>>[];
    if (selection.orderItems.isNotEmpty) {
      final all = await services(
        selection.module,
        province: selection.province,
      );
      for (final item in selection.orderItems.entries) {
        final matches = all
            .where(
              (s) =>
                  (s.id == item.key || s.displayName == item.key) &&
                  (selection.providerId == null ||
                      s.providerId == selection.providerId) &&
                  (selection.providerName == null ||
                      s.provider?.displayName == selection.providerName),
            )
            .toList();
        if (matches.length != 1) {
          throw const ApiException(
            code: 'invalid_items',
            message:
                'أحد الأصناف غير متاح لدى مقدم الخدمة المحدد. حدّث السلة وحاول مجددًا.',
          );
        }
        orderItems.add({
          'service_id': matches.single.id,
          'quantity': item.value,
        });
      }
    }
    final service = orderItems.isEmpty
        ? await resolve(selection)
        : await catalog.getService(orderItems.first['service_id']! as String);
    final isHotelRoom = service.serviceType == 'hotel_room';
    if (isHotelRoom && selection.expectedTotal == null) {
      throw const ApiException(
        code: 'hotel_quote_required',
        message: 'يجب معاينة سعر الإقامة قبل تأكيد الحجز.',
      );
    }
    final quantity = isHotelRoom ? 1 : quantityFor(service, selection.quantity);
    return bookings.create(
      BookingDraft(
        providerId: service.providerId,
        serviceId: service.id,
        total: service.basePrice * quantity,
        currency: service.currency,
        quantity: quantity,
        items: orderItems,
        serviceAvailabilityId: availabilityId,
        scheduledAt:
            (isHotelRoom ||
                service.pricingUnit == 'per_day' ||
                service.pricingUnit == 'per_night')
            ? null
            : selection.scheduledAt,
        expectedTotal: selection.expectedTotal,
        metadata: {
          ...selection.metadata,
          'module': selection.module,
          'source': 'flutter_provider_booking',
          'service_name': service.displayName,
          'provider_name': service.provider?.displayName,
        },
      ),
    );
  }
}

int providerQuotedTotal(
  String module,
  String? serviceId,
  int fallbackPrice,
  int quantity,
) {
  final flow = ProviderBookingFlow.current;
  if (flow != null && serviceId != null) {
    for (final service in flow.loaded(module)) {
      if (service.id == serviceId) {
        final estimatedUnits =
            module == 'hotels' && service.serviceType == 'hotel_room'
            ? quantity
            : flow.quantityFor(service, quantity);
        return service.basePrice * estimatedUnits;
      }
    }
  }
  return fallbackPrice * quantity;
}

Future<({bool cancelled, String? id})> selectProviderAvailability(
  BuildContext context,
  ProviderBookingFlow flow,
  CatalogService service, {
  int quantity = 1,
  DateTime? scheduledAt,
}) async {
  String? availabilityId;
  final slots = <CatalogAvailability>[];
  var page = 1;
  while (true) {
    final response = await flow.catalog.listAvailabilities(
      service.id,
      quantity: quantity,
      from: scheduledAt == null ? null : DateUtils.dateOnly(scheduledAt),
      to: scheduledAt == null
          ? null
          : DateUtils.dateOnly(scheduledAt)
                .add(const Duration(days: 1))
                .subtract(const Duration(microseconds: 1)),
      page: page,
    );
    slots.addAll(
      response.items.where((slot) => slot.availableQuantity >= quantity),
    );
    if (!response.hasMore) break;
    page++;
  }
  if (!context.mounted) return (cancelled: true, id: null);
  if (slots.isNotEmpty) {
    availabilityId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const LocalizedText('اختر الموعد المتاح لدى مقدم الخدمة'),
        children: slots
            .map(
              (slot) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, slot.id),
                child: Text(
                  '${slot.startsAt?.toLocal().toString() ?? "متاح"} — ${slot.price} ${slot.currency}',
                ),
              ),
            )
            .toList(),
      ),
    );
    if (availabilityId == null || !context.mounted) {
      return (cancelled: true, id: null);
    }
  }
  return (cancelled: false, id: availabilityId);
}

mixin ProviderBookingState<T extends StatefulWidget> on State<T> {
  Booking? providerBooking;
  bool providerBookingBusy = false;

  Future<void> submitProviderBooking(ProviderBookingSelection selection) async {
    if (providerBookingBusy) return;
    final flow = ProviderBookingFlow.current;
    if (flow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText('تعذر الاتصال بخدمة الحجوزات. حاول مجددًا.'),
        ),
      );
      return;
    }
    setState(() => providerBookingBusy = true);
    try {
      if (providerBooking == null) {
        String? availabilityId;
        if (selection.orderItems.isEmpty) {
          final service = await flow.resolve(selection);
          if (!mounted) return;
          if (service.serviceType != 'hotel_room') {
            final choice = await selectProviderAvailability(
              context,
              flow,
              service,
              quantity: flow.quantityFor(service, selection.quantity),
              scheduledAt: selection.scheduledAt,
            );
            if (choice.cancelled || !mounted) return;
            availabilityId = choice.id;
          }
        }
        providerBooking = await flow.create(
          selection,
          availabilityId: availabilityId,
        );
      }
      if (!mounted) return;
      final booking = providerBooking!;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const LocalizedText('تم إرسال طلب الحجز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText('رقم الحجز: ${booking.id}'),
              const SizedBox(height: 10),
              LocalizedText(
                'الإجمالي المعتمد: ${booking.total} ${booking.currency}',
              ),
              const SizedBox(height: 10),
              LocalizedText(
                booking.status == BookingStatus.pending
                    ? 'بانتظار موافقة مقدم الخدمة. الدفع غير متاح حاليًا، ولم يتم خصم أي مبلغ.'
                    : 'حالة الحجز: ${booking.status.name}، الدفع غير متاح حاليًا، ولم يتم خصم أي مبلغ.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const LocalizedText('حسنًا'),
            ),
          ],
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText(
            error.isUnauthorized
                ? 'يرجى تسجيل الدخول لإرسال طلب الحجز.'
                : error.message,
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText(
            'تعذر إرسال الحجز. تحقق من الاتصال وحاول مجددًا.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => providerBookingBusy = false);
    }
  }
}
