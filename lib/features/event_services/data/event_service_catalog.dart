import '../../bookings/presentation/provider_booking_flow.dart';
import 'package:flutter/foundation.dart';

import '../../catalog/data/control_panel_repository.dart';
import '../domain/event_service.dart';

/// مصدر واحد للعرض والإدارة؛ يحفظ التغييرات قبل نشرها إلى الواجهات.
class EventServiceCatalog extends ChangeNotifier {
  EventServiceCatalog({ControlPanelRepository? source})
    : _source = source ?? localControlPanelRepository {
    _seed();
  }

  final ControlPanelRepository _source;
  List<EventServiceProvider> _providers = [];
  List<EventServiceCategory> _categories = [];
  List<EventServiceItem> _items = [];
  List<EventSectionContent> _sections = [];
  List<EventPromotion> _promotions = [];
  String bannerTitle = 'كل تفاصيل مناسبتك في مكان واحد';
  String bannerSubtitle = 'مراكز متخصصة، خيارات متنوعة، ولمسات تستحقها مناسبتك';
  String bannerImage = eventServiceImage;
  Future<void>? _loading;
  Object? loadError;
  bool saving = false;
  bool loaded = false;

  List<EventServiceProvider> get providers => List.unmodifiable(_providers);
  List<EventServiceCategory> get categories => List.unmodifiable(_categories);
  List<EventPromotion> get promotions => List.unmodifiable(_promotions);

  List<EventServiceProvider> centersFor(String province) => _providers
      .where((provider) => provider.enabled && provider.serves(province))
      .toList();

  EventServiceProvider? providerById(String id) {
    for (final provider in _providers) {
      if (provider.id == id) return provider;
    }
    return null;
  }

  List<EventServiceCategory> categoriesFor(
    String providerId, {
    String? sectionId,
  }) => _categories
      .where(
        (category) =>
            category.providerId == providerId &&
            (sectionId == null || category.group == sectionId),
      )
      .toList();

  List<EventServiceItem> itemsFor(EventServiceProvider provider) {
    final categories = {
      for (final category in categoriesFor(provider.id)) category.id: category,
    };
    if (providerById(provider.id) == null) return [];
    return [
      for (final item in _items)
        if (item.providerId == provider.id &&
            categories.containsKey(item.category.id))
          EventServiceItem(
            id: item.id,
            providerId: provider.id,
            category: categories[item.category.id]!,
            name: item.name,
            unit: item.unit,
            unitPrice: item.unitPrice,
            images: item.images,
          ),
    ];
  }

  EventSectionContent sectionFor(String providerId, String sectionId) =>
      _sections.firstWhere(
        (section) =>
            section.providerId == providerId && section.sectionId == sectionId,
        orElse: () {
          final section = eventServiceSections.firstWhere(
            (item) => item.id == sectionId,
          );
          return EventSectionContent(
            providerId: providerId,
            sectionId: sectionId,
            title: section.name,
            subtitle: section.description,
          );
        },
      );

  Future<void> load() => ProviderBookingFlow.current != null ? _loadProviderServices() : (_loading ??= _load());
  Future<void> _loadProviderServices() async {
    final all=ProviderBookingFlow.current!.loaded('halls').where((s)=>s.serviceType=='event_service').toList();
    _providers=all.map((s)=>s.providerId).toSet().map((id){
      final service=all.firstWhere((s)=>s.providerId==id);
      return EventServiceProvider(id:id,name:service.provider?.displayName ?? '',
        description:'',provinces:[service.provider?.province ?? '']);
    }).toList();
    _categories=[];_items=[];_sections=[];_promotions=[];
    for(final service in all){
      final group=service.category?.slug;
      if(!eventServiceSections.any((section)=>section.id==group))continue;
      final category=EventServiceCategory(service.serviceCategoryId,service.category!.displayName,group!,providerId:service.providerId);
      if(!_categories.any((c)=>c.id==category.id && c.providerId==category.providerId))_categories.add(category);
      _items.add(EventServiceItem(id:service.id,providerId:service.providerId,category:category,
        name:service.displayName,unit:service.pricingUnit ?? '',unitPrice:service.basePrice));
    }
    loaded=true;loadError=null;
  }
  Future<void> _load() async {
    try {
      final json = await _source.getEventServiceCatalog();
      if (json != null) _restore(json);
      loadError = null;
    } catch (error) {
      loadError = error;
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> retryLoad() {
    _loading = null;
    return load();
  }

  String newId(String kind) => '$kind-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> saveProvider(EventServiceProvider provider) {
    if (provider.id.isEmpty || provider.name.trim().isEmpty) {
      throw ArgumentError('Invalid provider.');
    }
    return _write(
      providers: [
        ..._providers.where((item) => item.id != provider.id),
        provider,
      ],
    );
  }

  Future<void> deleteProvider(String id) => _write(
    providers: _providers.where((item) => item.id != id).toList(),
    categories: _categories.where((item) => item.providerId != id).toList(),
    items: _items.where((item) => item.providerId != id).toList(),
    sections: _sections.where((item) => item.providerId != id).toList(),
    promotions: _promotions
        .where((item) => item.isHall || item.targetId != id)
        .toList(),
  );

  Future<void> saveCategory(EventServiceCategory category) {
    if (providerById(category.providerId) == null ||
        category.name.trim().isEmpty ||
        !eventServiceSections.any((item) => item.id == category.group)) {
      throw ArgumentError('Invalid category.');
    }
    return _write(
      categories: [
        ..._categories.where((item) => item.id != category.id),
        category,
      ],
    );
  }

  Future<void> deleteCategory(String id) => _write(
    categories: _categories.where((item) => item.id != id).toList(),
    items: _items.where((item) => item.category.id != id).toList(),
  );

  Future<void> saveItem(EventServiceItem item) {
    if (item.name.trim().isEmpty ||
        item.unit.trim().isEmpty ||
        item.unitPrice < 0 ||
        !_categories.any(
          (category) =>
              category.id == item.category.id &&
              category.providerId == item.providerId,
        )) {
      throw ArgumentError('Invalid service.');
    }
    return _write(
      items: [..._items.where((entry) => entry.id != item.id), item],
    );
  }

  Future<void> deleteItem(String id) =>
      _write(items: _items.where((item) => item.id != id).toList());
  Future<void> saveSection(EventSectionContent section) => _write(
    sections: [..._sections.where((item) => item.id != section.id), section],
  );
  Future<void> savePromotion(EventPromotion promotion) => _write(
    promotions: [
      ..._promotions.where((item) => item.id != promotion.id),
      promotion,
    ],
  );
  Future<void> deletePromotion(String id) =>
      _write(promotions: _promotions.where((item) => item.id != id).toList());
  Future<void> saveBanner({
    required String title,
    required String subtitle,
    required String image,
  }) => _write(banner: {'title': title, 'subtitle': subtitle, 'image': image});

  Future<void> _write({
    List<EventServiceProvider>? providers,
    List<EventServiceCategory>? categories,
    List<EventServiceItem>? items,
    List<EventSectionContent>? sections,
    List<EventPromotion>? promotions,
    Map<String, String>? banner,
  }) async {
    if(ProviderBookingFlow.current!=null)throw StateError('تدار الخدمات من لوحة مقدم الخدمة.');
    if (!loaded) throw StateError('Load the catalog before editing it.');
    if (loadError != null) throw StateError('Catalog could not be loaded.');
    if (saving) throw StateError('Another catalog change is being saved.');
    saving = true;
    notifyListeners();
    try {
      final json = {
        'version': 2,
        'banner':
            banner ??
            {
              'title': bannerTitle,
              'subtitle': bannerSubtitle,
              'image': bannerImage,
            },
        'providers': (providers ?? _providers)
            .map((item) => item.toJson())
            .toList(),
        'categories': (categories ?? _categories)
            .map((item) => item.toJson())
            .toList(),
        'items': (items ?? _items).map((item) => item.toJson()).toList(),
        'sections': (sections ?? _sections)
            .map((item) => item.toJson())
            .toList(),
        'promotions': (promotions ?? _promotions)
            .map((item) => item.toJson())
            .toList(),
      };
      await _source.saveEventServiceCatalog(json);
      _restore(json);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void _restore(Map<String, dynamic> json) {
    if (json['version'] != 2) {
      throw const FormatException('Unsupported event catalog version.');
    }
    List<Map<String, dynamic>> rows(String key) => (json[key] as List)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
    final providers = rows(
      'providers',
    ).map(EventServiceProvider.fromJson).toList();
    final categories = rows(
      'categories',
    ).map(EventServiceCategory.fromJson).toList();
    final byId = {for (final category in categories) category.id: category};
    final items = rows('items')
        .map(
          (item) => EventServiceItem(
            id: item['id'] as String,
            providerId: item['provider_id'] as String,
            category: byId[item['category_id']]!,
            name: item['name'] as String,
            unit: item['unit'] as String,
            unitPrice: item['unit_price'] as int,
            images: List<String>.from(item['images'] as List),
          ),
        )
        .toList();
    final sections = rows(
      'sections',
    ).map(EventSectionContent.fromJson).toList();
    final promotions = rows('promotions').map(EventPromotion.fromJson).toList();
    final banner = json['banner'] as Map;
    final title = banner['title'] as String;
    final subtitle = banner['subtitle'] as String;
    final image = banner['image'] as String;
    _providers = providers;
    _categories = categories;
    _items = items;
    _sections = sections;
    _promotions = promotions;
    bannerTitle = title;
    bannerSubtitle = subtitle;
    bannerImage = image;
  }

  void _seed() {
    _providers = const [
      EventServiceProvider(
        id: 'event-hospitality',
        name: 'مركز إتقان لخدمات المناسبات',
        description: 'من الدعوة الأولى إلى آخر تفاصيل الحفل',
      ),
      EventServiceProvider(
        id: 'event-buffet',
        name: 'مكتب لمسة فرح للمناسبات',
        description: 'ضيافة وتنسيق وفرق متخصصة لمناسبتك',
      ),
      EventServiceProvider(
        id: 'event-elegance',
        name: 'مركز تميّز للمناسبات المتعددة',
        description: 'خدمات متنوعة تجمعها تجربة حجز واحدة',
      ),
    ];
    const templates = [
      ('invitations', 'بطاقات الدعوة', 'printing'),
      ('printed-bags', 'الأكياس والمطبوعات', 'printing'),
      ('meals', 'وجبة ضيافة', 'hospitality'),
      ('soft-drinks', 'مشروبات غازية', 'hospitality'),
      ('water-juice', 'الماء والعصائر', 'hospitality'),
      ('bags', 'كيس الضيافة', 'hospitality'),
      ('sweets', 'حلويات', 'hospitality'),
      ('cake', 'ترتة المناسبة', 'hospitality'),
      ('men-security', 'فريق أمن رجال', 'teams'),
      ('women-security', 'فريق أمن نساء', 'teams'),
      ('organizers', 'فريق تنظيم', 'teams'),
      ('dance', 'فرقة رقص', 'teams'),
      ('hosts', 'فريق ضيافة', 'teams'),
      ('photography', 'التصوير الفوتوغرافي', 'production'),
      ('sound', 'النظام الصوتي', 'production'),
      ('flowers', 'تنسيق الزهور والكوش', 'decoration'),
    ];
    final itemTemplates = [
      ...localControlPanelRepository.hallAddonItems,
      const HallAddonItemRecord(
        id: 'invitation',
        category: 'بطاقات الدعوة',
        name: 'بطاقة دعوة مطبوعة',
        size: 'بطاقة',
        unitPrice: 350,
      ),
      const HallAddonItemRecord(
        id: 'invitation-digital',
        category: 'بطاقات الدعوة',
        name: 'تصميم دعوة إلكترونية',
        size: 'تصميم',
        unitPrice: 15000,
      ),
      const HallAddonItemRecord(
        id: 'printed-bag',
        category: 'الأكياس والمطبوعات',
        name: 'كيس مطبوع باسم المناسبة',
        size: 'كيس',
        unitPrice: 400,
      ),
      const HallAddonItemRecord(
        id: 'cake-classic',
        category: 'ترتة المناسبة',
        name: 'ترتة كلاسيكية',
        size: 'ترتة',
        unitPrice: 75000,
      ),
      const HallAddonItemRecord(
        id: 'cake-premium',
        category: 'ترتة المناسبة',
        name: 'ترتة فاخرة',
        size: 'ترتة',
        unitPrice: 95000,
      ),
      const HallAddonItemRecord(
        id: 'cake-royal',
        category: 'ترتة المناسبة',
        name: 'ترتة ملكية',
        size: 'ترتة',
        unitPrice: 120000,
      ),
      const HallAddonItemRecord(
        id: 'flowers-classic',
        category: 'تنسيق الزهور والكوش',
        name: 'تنسيق زهور وكوشة كلاسيكية',
        size: 'تنسيق',
        unitPrice: 95000,
      ),
      const HallAddonItemRecord(
        id: 'flowers-premium',
        category: 'تنسيق الزهور والكوش',
        name: 'تنسيق زهور وكوشة فاخرة',
        size: 'تنسيق',
        unitPrice: 110000,
      ),
      const HallAddonItemRecord(
        id: 'flowers-royal',
        category: 'تنسيق الزهور والكوش',
        name: 'تنسيق زهور وكوشة ملكية',
        size: 'تنسيق',
        unitPrice: 140000,
      ),
    ];
    for (final provider in _providers) {
      for (final template in templates) {
        final category = EventServiceCategory(
          '${provider.id}/${template.$1}',
          template.$2,
          template.$3,
          providerId: provider.id,
        );
        _categories.add(category);
        for (final item in itemTemplates.where(
          (item) => item.enabled && item.category == category.name,
        )) {
          _items.add(
            EventServiceItem(
              id: '${provider.id}/${item.id}',
              providerId: provider.id,
              category: category,
              name: item.name,
              unit: item.size,
              unitPrice: item.unitPrice,
              images: [
                template.$3 == 'hospitality'
                    ? 'assets/Services images/مطاعم.jpg'
                    : eventServiceImage,
              ],
            ),
          );
        }
      }
    }
    _promotions = const [
      EventPromotion(
        id: 'hall-featured',
        title: 'ليلتك تبدأ من المكان المناسب',
        subtitle: 'اكتشف قاعة لافندر الملكية وباقاتها',
        targetId: 'قاعة لافندر الملكية',
        isHall: true,
      ),
      EventPromotion(
        id: 'center-featured',
        title: 'تفاصيل متكاملة لمناسبتك',
        subtitle: 'اكتشف خدمات مركز إتقان',
        targetId: 'event-hospitality',
      ),
    ];
  }
}

final eventServiceCatalog = EventServiceCatalog();
