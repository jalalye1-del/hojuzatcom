import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_locale.dart';

class AppMapLauncher {
  const AppMapLauncher._();

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
