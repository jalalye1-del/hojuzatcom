import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_locale.dart';

class AppMapLauncher {
  const AppMapLauncher._();

  static Future<void> open(
    BuildContext context, {
    required String query,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText('تعذر فتح تطبيق الخرائط على هذا الجهاز.'),
        ),
      );
    }
  }

  static Future<void> directions(
    BuildContext context, {
    required String destination,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}&travelmode=driving&dir_action=navigate',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText('تعذر فتح الاتجاهات على هذا الجهاز.'),
        ),
      );
    }
  }
}
