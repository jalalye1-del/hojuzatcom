import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_locale.dart';
import '../../features/catalog/data/catalog_repository.dart';
import '../../features/catalog/domain/catalog_models.dart';

class AppMapLauncher {
  const AppMapLauncher._();

  static String? providerQuery(CatalogProvider provider) {
    final latitude = provider.latitude;
    final longitude = provider.longitude;
    if (latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180) {
      return '$latitude,$longitude';
    }
    if (provider.address == null || provider.address!.trim().isEmpty) {
      return null;
    }
    return [provider.address, provider.city, provider.province]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join('، ');
  }

  static bool isValidCoordinates(double latitude, double longitude) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  static String coordinatesQuery(double latitude, double longitude) {
    if (!isValidCoordinates(latitude, longitude)) {
      throw ArgumentError('Invalid map coordinates.');
    }
    return '$latitude,$longitude';
  }

  static Future<void> openCoordinates(
    BuildContext context, {
    required double latitude,
    required double longitude,
  }) async {
    if (!isValidCoordinates(latitude, longitude)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: LocalizedText('إحداثيات الموقع غير صحيحة.')),
        );
      }
      return;
    }

    await open(context, query: coordinatesQuery(latitude, longitude));
  }

  static Future<void> directionsToCoordinates(
    BuildContext context, {
    required double latitude,
    required double longitude,
  }) async {
    if (!isValidCoordinates(latitude, longitude)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: LocalizedText('إحداثيات الوجهة غير صحيحة.')),
        );
      }
      return;
    }

    await directions(
      context,
      destination: coordinatesQuery(latitude, longitude),
    );
  }

  static Future<void> openProvider(
    BuildContext context, {
    required CatalogRepository? catalog,
    required String? providerId,
  }) async {
    String? query;
    if (catalog != null && providerId != null && providerId.trim().isNotEmpty) {
      try {
        query = providerQuery(await catalog.getProvider(providerId));
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText('تعذر تحميل موقع مقدم الخدمة. حاول مجددًا.'),
          ),
        );
        return;
      }
    }
    if (!context.mounted) return;
    if (query == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText('لم يحدد مقدم الخدمة موقعه بعد.'),
        ),
      );
      return;
    }
    await open(context, query: query);
  }

  static Future<void> _launch(
    BuildContext context,
    Uri uri,
    String errorMessage,
  ) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: LocalizedText(errorMessage)));
    }
  }

  static Future<void> open(
    BuildContext context, {
    required String query,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    await _launch(context, uri, 'تعذر فتح تطبيق الخرائط على هذا الجهاز.');
  }

  static Future<void> directions(
    BuildContext context, {
    required String destination,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}&travelmode=driving&dir_action=navigate',
    );
    await _launch(context, uri, 'تعذر فتح الاتجاهات على هذا الجهاز.');
  }
}
