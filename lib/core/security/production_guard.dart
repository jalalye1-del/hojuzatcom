import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../localization/app_locale.dart';

/// يمنع اعتماد نتائج الحجز أو الدفع المحلية داخل نسخة الإنتاج.
/// تبقى المحاكاة متاحة فقط في debug لتطوير الواجهات وتشغيل الاختبارات.
bool allowLocalTransactionSimulation(BuildContext context) {
  if (!kReleaseMode) return true;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: LocalizedText(
        l10n(
          'تعذر إتمام العملية: يجب ربط هذه الخدمة بالخادم وبوابة الدفع الآمنة أولاً.',
        ),
      ),
    ),
  );
  return false;
}
