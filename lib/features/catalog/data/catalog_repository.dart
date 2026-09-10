import '../../../core/network/api_client.dart';
import '../domain/catalog_models.dart';

abstract interface class CatalogRepository {
  Future<List<CatalogCategory>> listCategories({
    String? parentId,
    bool rootOnly = false,
  });

  Future<CatalogPage<CatalogProvider>> listProviders({
    String? query,
    String? categoryId,
    String? province,
    String? city,
    bool? featured,
    int page = 1,
    int perPage = 20,
  });

  Future<CatalogProvider> getProvider(String idOrSlug);

  Future<CatalogPage<CatalogService>> listServices({
    String? query,
    String? categoryId,
    String? providerId,
    String? branchId,
    String? serviceType,
    bool? featured,
    bool? requiresPayment,
    int? minPrice,
    int? maxPrice,
    String? sort,
    int page = 1,
    int perPage = 20,
  });

  Future<CatalogService> getService(String idOrSlug);

  Future<CatalogPage<CatalogAvailability>> listAvailabilities(
    String serviceIdOrSlug, {
    DateTime? from,
    DateTime? to,
    String? branchId,
    int quantity = 1,
    int page = 1,
    int perPage = 30,
  });
}

class RemoteCatalogRepository implements CatalogRepository {
  RemoteCatalogRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<CatalogCategory>> listCategories({
    String? parentId,
    bool rootOnly = false,
  }) async {
    final payload = await _api.get(
      'service-categories',
      query: {
        if (_hasText(parentId)) 'parent_id': parentId!.trim(),
        if (rootOnly) 'root_only': 1,
      },
      authenticated: false,
    );

    return _dataList(payload, CatalogCategory.fromJson);
  }

  @override
  Future<CatalogPage<CatalogProvider>> listProviders({
    String? query,
    String? categoryId,
    String? province,
    String? city,
    bool? featured,
    int page = 1,
    int perPage = 20,
  }) {
    _validatePage(page, perPage, maxPerPage: 50);
    return _page(
      _api.get(
        'providers',
        query: {
          if (_hasText(query)) 'q': query!.trim(),
          if (_hasText(categoryId)) 'category_id': categoryId!.trim(),
          if (_hasText(province)) 'province': province!.trim(),
          if (_hasText(city)) 'city': city!.trim(),
          if (featured != null) 'featured': featured ? 1 : 0,
          'page': page,
          'per_page': perPage,
        },
        authenticated: false,
      ),
      CatalogProvider.fromJson,
    );
  }

  @override
  Future<CatalogProvider> getProvider(String idOrSlug) {
    _validateIdentifier(idOrSlug, 'idOrSlug');
    return _single(
      _api.get(
        'providers/${Uri.encodeComponent(idOrSlug.trim())}',
        authenticated: false,
      ),
      CatalogProvider.fromJson,
    );
  }

  @override
  Future<CatalogPage<CatalogService>> listServices({
    String? query,
    String? categoryId,
    String? providerId,
    String? branchId,
    String? serviceType,
    bool? featured,
    bool? requiresPayment,
    int? minPrice,
    int? maxPrice,
    String? sort,
    int page = 1,
    int perPage = 20,
  }) {
    _validatePage(page, perPage, maxPerPage: 50);
    if (minPrice != null && minPrice < 0) {
      throw ArgumentError.value(minPrice, 'minPrice', 'Must not be negative.');
    }
    if (maxPrice != null && maxPrice < 0) {
      throw ArgumentError.value(maxPrice, 'maxPrice', 'Must not be negative.');
    }
    if (minPrice != null && maxPrice != null && maxPrice < minPrice) {
      throw ArgumentError.value(
        maxPrice,
        'maxPrice',
        'Must be greater than or equal to minPrice.',
      );
    }

    return _page(
      _api.get(
        'services',
        query: {
          if (_hasText(query)) 'q': query!.trim(),
          if (_hasText(categoryId)) 'category_id': categoryId!.trim(),
          if (_hasText(providerId)) 'provider_id': providerId!.trim(),
          if (_hasText(branchId)) 'branch_id': branchId!.trim(),
          if (_hasText(serviceType)) 'service_type': serviceType!.trim(),
          if (featured != null) 'featured': featured ? 1 : 0,
          if (requiresPayment != null)
            'requires_payment': requiresPayment ? 1 : 0,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
          if (_hasText(sort)) 'sort': sort!.trim(),
          'page': page,
          'per_page': perPage,
        },
        authenticated: false,
      ),
      CatalogService.fromJson,
    );
  }

  @override
  Future<CatalogService> getService(String idOrSlug) {
    _validateIdentifier(idOrSlug, 'idOrSlug');
    return _single(
      _api.get(
        'services/${Uri.encodeComponent(idOrSlug.trim())}',
        authenticated: false,
      ),
      CatalogService.fromJson,
    );
  }

  @override
  Future<CatalogPage<CatalogAvailability>> listAvailabilities(
    String serviceIdOrSlug, {
    DateTime? from,
    DateTime? to,
    String? branchId,
    int quantity = 1,
    int page = 1,
    int perPage = 30,
  }) {
    _validateIdentifier(serviceIdOrSlug, 'serviceIdOrSlug');
    _validatePage(page, perPage, maxPerPage: 100);
    if (quantity < 1 || quantity > 1000) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Must be between 1 and 1000.',
      );
    }
    if (from != null && to != null && to.isBefore(from)) {
      throw ArgumentError.value(to, 'to', 'Must not be before from.');
    }

    return _page(
      _api.get(
        'services/${Uri.encodeComponent(serviceIdOrSlug.trim())}/availabilities',
        query: {
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
          if (_hasText(branchId)) 'branch_id': branchId!.trim(),
          'quantity': quantity,
          'page': page,
          'per_page': perPage,
        },
        authenticated: false,
      ),
      CatalogAvailability.fromJson,
    );
  }

  Future<CatalogPage<T>> _page<T>(
    Future<Object?> request,
    T Function(Map<String, dynamic>) parser,
  ) async {
    final payload = await request;
    final root = _jsonMap(payload, 'catalog page');
    final items = _dataList(root, parser);
    final meta = _optionalMap(root['meta']);

    return CatalogPage<T>(
      items: items,
      currentPage: _intValue(meta?['current_page']) ?? 1,
      lastPage: _intValue(meta?['last_page']) ?? 1,
      perPage: _intValue(meta?['per_page']),
      total: _intValue(meta?['total']),
    );
  }

  Future<T> _single<T>(
    Future<Object?> request,
    T Function(Map<String, dynamic>) parser,
  ) async {
    final root = _jsonMap(await request, 'catalog item');
    return parser(_jsonMap(root['data'], 'catalog data'));
  }

  List<T> _dataList<T>(
    Object? payload,
    T Function(Map<String, dynamic>) parser,
  ) {
    final root = _jsonMap(payload, 'catalog collection');
    final data = root['data'];
    if (data is! List) {
      throw const FormatException('Catalog response has no data list.');
    }

    return data
        .map((item) => parser(_jsonMap(item, 'catalog list item')))
        .toList(growable: false);
  }

  Map<String, dynamic> _jsonMap(Object? value, String context) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('Expected a JSON object for $context.');
  }

  Map<String, dynamic>? _optionalMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  void _validateIdentifier(String value, String name) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 160) {
      throw ArgumentError.value(value, name, 'Invalid catalog identifier.');
    }
  }

  void _validatePage(int page, int perPage, {required int maxPerPage}) {
    if (page < 1) {
      throw ArgumentError.value(page, 'page', 'Must be at least 1.');
    }
    if (perPage < 1 || perPage > maxPerPage) {
      throw ArgumentError.value(
        perPage,
        'perPage',
        'Must be between 1 and $maxPerPage.',
      );
    }
  }
}
