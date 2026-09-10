import '../../../core/formatting/money_format.dart';
import '../../bookings/domain/booking.dart';

const eventServicesId = 'event-services';
const eventServicesTitle = 'مراكز تقديم خدمات المناسبات المتعددة';
const eventServiceImage = 'assets/Services images/قاعات الافراح والمناسبات.jpg';

class EventServiceSection {
  const EventServiceSection(this.id, this.name, this.description);
  final String id, name, description;
}

const eventServiceSections = [
  EventServiceSection(
    'printing',
    'المطبوعات',
    'دعوات وبطاقات وتفاصيل تحمل طابع مناسبتك',
  ),
  EventServiceSection(
    'hospitality',
    'الضيافة',
    'وجبات ومشروبات وحلويات لضيوفك',
  ),
  EventServiceSection(
    'teams',
    'فرق المناسبة',
    'فرق التنظيم والضيافة والأمن والزفات',
  ),
  EventServiceSection(
    'production',
    'التصوير والتجهيزات الصوتية',
    'توثيق لحظاتك وتجهيز الصوت لمناسبتك',
  ),
  EventServiceSection(
    'decoration',
    'التنسيق والكوش',
    'زهور وكوش وتنسيقات تصنع أجواء المناسبة',
  ),
];

class EventServiceCategory {
  const EventServiceCategory(
    this.id,
    this.name,
    this.group, {
    required this.providerId,
  });

  final String id;
  final String name;
  final String group;
  final String providerId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'section_id': group,
    'provider_id': providerId,
  };
  factory EventServiceCategory.fromJson(Map<String, dynamic> json) =>
      EventServiceCategory(
        json['id'] as String,
        json['name'] as String,
        json['section_id'] as String,
        providerId: json['provider_id'] as String,
      );
}

class EventServiceProvider {
  const EventServiceProvider({
    required this.id,
    required this.name,
    this.description = 'خدمات متكاملة لتفاصيل مناسبتك',
    this.image = eventServiceImage,
    this.provinces = const ['all'],
    this.paymentMethodIds = const ['jawali', 'jeeb', 'onecash'],
    this.enabled = true,
  });

  final String id;
  final String name;
  final String description, image;
  final List<String> provinces;
  final List<String> paymentMethodIds;
  final bool enabled;

  bool serves(String province) =>
      provinces.contains('all') || provinces.contains(province);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'image': image,
    'provinces': provinces,
    'payment_method_ids': paymentMethodIds,
    'enabled': enabled,
  };
  factory EventServiceProvider.fromJson(Map<String, dynamic> json) =>
      EventServiceProvider(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        image: json['image'] as String,
        provinces: List<String>.from(json['provinces'] as List),
        paymentMethodIds: List<String>.from(json['payment_method_ids'] as List),
        enabled: json['enabled'] as bool,
      );
}

class EventServiceItem {
  const EventServiceItem({
    required this.id,
    required this.providerId,
    required this.category,
    required this.name,
    required this.unit,
    required this.unitPrice,
    this.images = const [],
  });

  final String id;
  final String providerId;
  final EventServiceCategory category;
  final String name;
  final String unit;
  final int unitPrice;
  final List<String> images;

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider_id': providerId,
    'category_id': category.id,
    'name': name,
    'unit': unit,
    'unit_price': unitPrice,
    'images': images,
  };
}

class EventSectionContent {
  const EventSectionContent({
    required this.providerId,
    required this.sectionId,
    required this.title,
    required this.subtitle,
    this.image = eventServiceImage,
    this.gallery = const [eventServiceImage],
  });
  final String providerId, sectionId, title, subtitle, image;
  final List<String> gallery;
  String get id => '$providerId/$sectionId';
  Map<String, dynamic> toJson() => {
    'provider_id': providerId,
    'section_id': sectionId,
    'title': title,
    'subtitle': subtitle,
    'image': image,
    'gallery': gallery,
  };
  factory EventSectionContent.fromJson(Map<String, dynamic> json) =>
      EventSectionContent(
        providerId: json['provider_id'] as String,
        sectionId: json['section_id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        image: json['image'] as String,
        gallery: List<String>.from(json['gallery'] as List),
      );
}

class EventPromotion {
  const EventPromotion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetId,
    this.isHall = false,
    this.image = eventServiceImage,
  });
  final String id, title, subtitle, targetId, image;
  final bool isHall;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'target_id': targetId,
    'is_hall': isHall,
    'image': image,
  };
  factory EventPromotion.fromJson(Map<String, dynamic> json) => EventPromotion(
    id: json['id'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    targetId: json['target_id'] as String,
    isHall: json['is_hall'] as bool,
    image: json['image'] as String,
  );
}

class EventServiceLine {
  EventServiceLine({required this.item, required this.quantity}) {
    if (quantity < 1 || quantity > 9999 || item.unitPrice < 0) {
      throw ArgumentError('Invalid event service quantity or price.');
    }
  }

  final EventServiceItem item;
  final int quantity;
  int get total => item.unitPrice * quantity;
}

/// لقطة مستقلة للأسعار والبيانات عند مراجعة الطلب؛ لا ترتبط بباقة قاعة.
class EventServiceOrder {
  EventServiceOrder({
    required this.provider,
    required List<EventServiceLine> lines,
    required this.province,
    required this.scheduledAt,
    required this.guestCount,
    required this.address,
    required this.customerName,
    required this.phone,
    this.notes = '',
  }) : lines = List.unmodifiable(lines) {
    if (lines.isEmpty ||
        lines.any((line) => line.item.providerId != provider.id) ||
        guestCount < 1 ||
        address.trim().isEmpty ||
        customerName.trim().isEmpty ||
        phone.trim().isEmpty) {
      throw ArgumentError('Invalid event service order.');
    }
  }

  final EventServiceProvider provider;
  final List<EventServiceLine> lines;
  final String province;
  final DateTime scheduledAt;
  final int guestCount;
  final String address;
  final String customerName;
  final String phone;
  final String notes;

  int get total => lines.fold(0, (sum, line) => sum + line.total);

  BookingDraft toBookingDraft() => BookingDraft(
    providerId: provider.id,
    serviceId: eventServicesId,
    total: total,
    currency: 'YER',
    scheduledAt: scheduledAt,
    metadata: {
      'provider_name': provider.name,
      'province': province,
      'address': address,
      'guest_count': guestCount,
      'customer_name': customerName,
      'phone': phone,
      'notes': notes,
      'items': [
        for (final line in lines)
          {
            'item_id': line.item.id,
            'category_id': line.item.category.id,
            'name': line.item.name,
            'unit': line.item.unit,
            'unit_price': line.item.unitPrice,
            'quantity': line.quantity,
            'total': line.total,
          },
      ],
    },
  );
}

class EventServiceReceipt {
  const EventServiceReceipt({
    required this.order,
    required this.reference,
    required this.paymentMethodName,
    required this.createdAt,
  });

  final EventServiceOrder order;
  final String reference;
  final String paymentMethodName;
  final DateTime createdAt;

  String get invoiceReference => 'INV-$reference';
  String get status => 'تجريبي — لم يتم تحصيل مبلغ';

  List<(String, String)> get invoiceDetails => [
    ('التصنيف', eventServicesTitle),
    ('مقدم الخدمة', order.provider.name),
    ('رقم الحجز', reference),
    ('تاريخ الإصدار', eventServiceDate(createdAt)),
    ('اسم العميل', order.customerName),
    ('رقم الهاتف', order.phone),
    ('المحافظة', order.province),
    ('الموعد', eventServiceDate(order.scheduledAt)),
    ('مكان المناسبة', order.address),
    ('عدد الضيوف', '${order.guestCount}'),
    for (final line in order.lines)
      (
        '${line.item.category.name} • ${line.item.name}',
        '${line.quantity} × ${formatMoney(line.item.unitPrice)} ر.ي '
            '(${line.item.unit}) = ${formatMoney(line.total)} ر.ي',
      ),
    ('الإجمالي', '${formatMoney(order.total)} ر.ي'),
    ('طريقة الدفع', paymentMethodName),
    ('نوع الدفع', 'دفع كامل لقيمة الخدمات المختارة'),
    ('المبلغ المحصل فعلياً', '0 ر.ي'),
    if (order.notes.isNotEmpty) ('ملاحظات المناسبة', order.notes),
  ];
}

String eventServiceDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}/${two(value.month)}/${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}
