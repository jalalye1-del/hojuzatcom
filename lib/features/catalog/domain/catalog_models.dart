class CatalogPage<T> {
  const CatalogPage({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage,
    this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int? perPage;
  final int? total;

  bool get hasMore => currentPage < lastPage;
}

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.nameAr,
    this.parentId,
    this.nameEn,
    this.slug,
    this.icon,
    this.descriptionAr,
    this.descriptionEn,
    this.sortOrder = 0,
    this.childrenCount,
    this.servicesCount,
  });

  final String id;
  final String? parentId;
  final String nameAr;
  final String? nameEn;
  final String? slug;
  final String? icon;
  final String? descriptionAr;
  final String? descriptionEn;
  final int sortOrder;
  final int? childrenCount;
  final int? servicesCount;

  String get displayName => nameAr.trim().isNotEmpty ? nameAr : (nameEn ?? id);

  factory CatalogCategory.fromJson(Map<String, dynamic> json) =>
      CatalogCategory(
        id: _requiredString(json, 'id'),
        parentId: _optionalString(json, 'parent_id'),
        nameAr: _optionalString(json, 'name_ar') ?? '',
        nameEn: _optionalString(json, 'name_en'),
        slug: _optionalString(json, 'slug'),
        icon: _optionalString(json, 'icon'),
        descriptionAr: _optionalString(json, 'description_ar'),
        descriptionEn: _optionalString(json, 'description_en'),
        sortOrder: _intValue(json['sort_order']) ?? 0,
        childrenCount: _intValue(json['children_count']),
        servicesCount: _intValue(json['services_count']),
      );
}

class CatalogBranch {
  const CatalogBranch({
    required this.id,
    required this.providerId,
    this.code,
    this.nameAr,
    this.nameEn,
    this.phone,
    this.whatsapp,
    this.email,
    this.province,
    this.city,
    this.address,
    this.latitude,
    this.longitude,
    this.timezone,
    this.operatingHours,
    this.isMain = false,
  });

  final String id;
  final String providerId;
  final String? code;
  final String? nameAr;
  final String? nameEn;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? province;
  final String? city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final Map<String, dynamic>? operatingHours;
  final bool isMain;

  String get displayName =>
      (nameAr?.trim().isNotEmpty ?? false) ? nameAr! : (nameEn ?? code ?? id);

  factory CatalogBranch.fromJson(Map<String, dynamic> json) => CatalogBranch(
    id: _requiredString(json, 'id'),
    providerId: _requiredString(json, 'provider_id'),
    code: _optionalString(json, 'code'),
    nameAr: _optionalString(json, 'name_ar'),
    nameEn: _optionalString(json, 'name_en'),
    phone: _optionalString(json, 'phone'),
    whatsapp: _optionalString(json, 'whatsapp'),
    email: _optionalString(json, 'email'),
    province: _optionalString(json, 'province'),
    city: _optionalString(json, 'city'),
    address: _optionalString(json, 'address'),
    latitude: _doubleValue(json['latitude']),
    longitude: _doubleValue(json['longitude']),
    timezone: _optionalString(json, 'timezone'),
    operatingHours: _optionalMap(json['operating_hours']),
    isMain: _boolValue(json['is_main']),
  );
}

class CatalogProviderSummary {
  const CatalogProviderSummary({
    required this.id,
    required this.displayNameAr,
    this.primaryCategoryId,
    this.displayNameEn,
    this.slug,
    this.province,
    this.city,
    this.address,
    this.logoPath,
    this.coverImagePath,
    this.defaultCurrency,
    this.isFeatured = false,
  });

  final String id;
  final String? primaryCategoryId;
  final String displayNameAr;
  final String? displayNameEn;
  final String? slug;
  final String? province;
  final String? city;
  final String? address;
  final String? logoPath;
  final String? coverImagePath;
  final String? defaultCurrency;
  final bool isFeatured;

  String get displayName =>
      displayNameAr.trim().isNotEmpty ? displayNameAr : (displayNameEn ?? id);

  factory CatalogProviderSummary.fromJson(Map<String, dynamic> json) =>
      CatalogProviderSummary(
        id: _requiredString(json, 'id'),
        primaryCategoryId: _optionalString(json, 'primary_category_id'),
        displayNameAr: _optionalString(json, 'display_name_ar') ?? '',
        displayNameEn: _optionalString(json, 'display_name_en'),
        slug: _optionalString(json, 'slug'),
        province: _optionalString(json, 'province'),
        city: _optionalString(json, 'city'),
        address: _optionalString(json, 'address'),
        logoPath: _optionalString(json, 'logo_path'),
        coverImagePath: _optionalString(json, 'cover_image_path'),
        defaultCurrency: _optionalString(json, 'default_currency'),
        isFeatured: _boolValue(json['is_featured']),
      );
}

class CatalogProvider {
  const CatalogProvider({
    required this.id,
    required this.displayNameAr,
    this.primaryCategoryId,
    this.displayNameEn,
    this.slug,
    this.descriptionAr,
    this.descriptionEn,
    this.phone,
    this.whatsapp,
    this.email,
    this.website,
    this.province,
    this.city,
    this.address,
    this.latitude,
    this.longitude,
    this.logoPath,
    this.coverImagePath,
    this.defaultCurrency,
    this.timezone,
    this.isFeatured = false,
    this.primaryCategory,
    this.branches = const [],
    this.services = const [],
    this.branchesCount,
    this.servicesCount,
  });

  final String id;
  final String? primaryCategoryId;
  final String displayNameAr;
  final String? displayNameEn;
  final String? slug;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? website;
  final String? province;
  final String? city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? logoPath;
  final String? coverImagePath;
  final String? defaultCurrency;
  final String? timezone;
  final bool isFeatured;
  final CatalogCategory? primaryCategory;
  final List<CatalogBranch> branches;
  final List<CatalogService> services;
  final int? branchesCount;
  final int? servicesCount;

  String get displayName =>
      displayNameAr.trim().isNotEmpty ? displayNameAr : (displayNameEn ?? id);

  CatalogProviderSummary get summary => CatalogProviderSummary(
    id: id,
    primaryCategoryId: primaryCategoryId,
    displayNameAr: displayNameAr,
    displayNameEn: displayNameEn,
    slug: slug,
    province: province,
    city: city,
    address: address,
    logoPath: logoPath,
    coverImagePath: coverImagePath,
    defaultCurrency: defaultCurrency,
    isFeatured: isFeatured,
  );

  factory CatalogProvider.fromJson(Map<String, dynamic> json) =>
      CatalogProvider(
        id: _requiredString(json, 'id'),
        primaryCategoryId: _optionalString(json, 'primary_category_id'),
        displayNameAr: _optionalString(json, 'display_name_ar') ?? '',
        displayNameEn: _optionalString(json, 'display_name_en'),
        slug: _optionalString(json, 'slug'),
        descriptionAr: _optionalString(json, 'description_ar'),
        descriptionEn: _optionalString(json, 'description_en'),
        phone: _optionalString(json, 'phone'),
        whatsapp: _optionalString(json, 'whatsapp'),
        email: _optionalString(json, 'email'),
        website: _optionalString(json, 'website'),
        province: _optionalString(json, 'province'),
        city: _optionalString(json, 'city'),
        address: _optionalString(json, 'address'),
        latitude: _doubleValue(json['latitude']),
        longitude: _doubleValue(json['longitude']),
        logoPath: _optionalString(json, 'logo_path'),
        coverImagePath: _optionalString(json, 'cover_image_path'),
        defaultCurrency: _optionalString(json, 'default_currency'),
        timezone: _optionalString(json, 'timezone'),
        isFeatured: _boolValue(json['is_featured']),
        primaryCategory: _modelOrNull(
          json['primary_category'],
          CatalogCategory.fromJson,
        ),
        branches: _modelList(json['branches'], CatalogBranch.fromJson),
        services: _modelList(json['services'], CatalogService.fromJson),
        branchesCount: _intValue(json['branches_count']),
        servicesCount: _intValue(json['services_count']),
      );
}

class CatalogService {
  const CatalogService({
    required this.id,
    required this.providerId,
    required this.serviceCategoryId,
    required this.nameAr,
    required this.basePrice,
    required this.currency,
    this.branchId,
    this.code,
    this.slug,
    this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.serviceType,
    this.bookingMode,
    this.pricingUnit,
    this.durationMinutes,
    this.capacity,
    this.minimumAdvanceMinutes,
    this.maximumAdvanceDays,
    this.requiresPayment = false,
    this.depositPercentage,
    this.isCancellationAllowed = false,
    this.bookingGracePeriodMinutes,
    this.freeCancellationBeforeMinutes,
    this.refundPercentageBeforeDeadline,
    this.refundPercentageAfterDeadline,
    this.noShowRefundPercentage,
    this.cancellationPolicyAr,
    this.cancellationPolicyEn,
    this.isFeatured = false,
    this.provider,
    this.category,
    this.branch,
    this.availabilities = const [],
  });

  final String id;
  final String providerId;
  final String? branchId;
  final String serviceCategoryId;
  final String? code;
  final String? slug;
  final String nameAr;
  final String? nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? serviceType;
  final String? bookingMode;
  final int basePrice;
  final String currency;
  final String? pricingUnit;
  final int? durationMinutes;
  final int? capacity;
  final int? minimumAdvanceMinutes;
  final int? maximumAdvanceDays;
  final bool requiresPayment;
  final double? depositPercentage;
  final bool isCancellationAllowed;
  final int? bookingGracePeriodMinutes;
  final int? freeCancellationBeforeMinutes;
  final double? refundPercentageBeforeDeadline;
  final double? refundPercentageAfterDeadline;
  final double? noShowRefundPercentage;
  final String? cancellationPolicyAr;
  final String? cancellationPolicyEn;
  final bool isFeatured;
  final CatalogProviderSummary? provider;
  final CatalogCategory? category;
  final CatalogBranch? branch;
  final List<CatalogAvailability> availabilities;

  String get displayName => nameAr.trim().isNotEmpty ? nameAr : (nameEn ?? id);

  factory CatalogService.fromJson(Map<String, dynamic> json) => CatalogService(
    id: _requiredString(json, 'id'),
    providerId: _requiredString(json, 'provider_id'),
    branchId: _optionalString(json, 'branch_id'),
    serviceCategoryId: _requiredString(json, 'service_category_id'),
    code: _optionalString(json, 'code'),
    slug: _optionalString(json, 'slug'),
    nameAr: _optionalString(json, 'name_ar') ?? '',
    nameEn: _optionalString(json, 'name_en'),
    descriptionAr: _optionalString(json, 'description_ar'),
    descriptionEn: _optionalString(json, 'description_en'),
    serviceType: _optionalString(json, 'service_type'),
    bookingMode: _optionalString(json, 'booking_mode'),
    basePrice: _intValue(json['base_price']) ?? 0,
    currency: _optionalString(json, 'currency') ?? 'YER',
    pricingUnit: _optionalString(json, 'pricing_unit'),
    durationMinutes: _intValue(json['duration_minutes']),
    capacity: _intValue(json['capacity']),
    minimumAdvanceMinutes: _intValue(json['minimum_advance_minutes']),
    maximumAdvanceDays: _intValue(json['maximum_advance_days']),
    requiresPayment: _boolValue(json['requires_payment']),
    depositPercentage: _doubleValue(json['deposit_percentage']),
    isCancellationAllowed: _boolValue(json['is_cancellation_allowed']),
    bookingGracePeriodMinutes: _intValue(json['booking_grace_period_minutes']),
    freeCancellationBeforeMinutes: _intValue(
      json['free_cancellation_before_minutes'],
    ),
    refundPercentageBeforeDeadline: _doubleValue(
      json['refund_percentage_before_deadline'],
    ),
    refundPercentageAfterDeadline: _doubleValue(
      json['refund_percentage_after_deadline'],
    ),
    noShowRefundPercentage: _doubleValue(json['no_show_refund_percentage']),
    cancellationPolicyAr: _optionalString(json, 'cancellation_policy_ar'),
    cancellationPolicyEn: _optionalString(json, 'cancellation_policy_en'),
    isFeatured: _boolValue(json['is_featured']),
    provider: _modelOrNull(json['provider'], CatalogProviderSummary.fromJson),
    category: _modelOrNull(json['category'], CatalogCategory.fromJson),
    branch: _modelOrNull(json['branch'], CatalogBranch.fromJson),
    availabilities: _modelList(
      json['availabilities'],
      CatalogAvailability.fromJson,
    ),
  );
}

class CatalogAvailability {
  const CatalogAvailability({
    required this.id,
    required this.serviceId,
    required this.availableQuantity,
    required this.price,
    required this.currency,
    this.branchId,
    this.startsAt,
    this.endsAt,
    this.branch,
  });

  final String id;
  final String serviceId;
  final String? branchId;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int availableQuantity;
  final int price;
  final String currency;
  final CatalogBranch? branch;

  factory CatalogAvailability.fromJson(Map<String, dynamic> json) =>
      CatalogAvailability(
        id: _requiredString(json, 'id'),
        serviceId: _requiredString(json, 'service_id'),
        branchId: _optionalString(json, 'branch_id'),
        startsAt: _dateTime(json['starts_at']),
        endsAt: _dateTime(json['ends_at']),
        availableQuantity: _intValue(json['available_quantity']) ?? 0,
        price: _intValue(json['price']) ?? 0,
        currency: _optionalString(json, 'currency') ?? 'YER',
        branch: _modelOrNull(json['branch'], CatalogBranch.fromJson),
      );
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _optionalString(json, key);
  if (value == null || value.isEmpty) {
    throw FormatException('Catalog response is missing "$key".');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _doubleValue(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool _boolValue(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  return text == '1' || text == 'true';
}

DateTime? _dateTime(Object? value) {
  final text = value?.toString();
  return text == null ? null : DateTime.tryParse(text);
}

Map<String, dynamic>? _optionalMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

T? _modelOrNull<T>(Object? value, T Function(Map<String, dynamic>) parser) {
  final map = _optionalMap(value);
  return map == null ? null : parser(map);
}

List<T> _modelList<T>(Object? value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => parser(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}
