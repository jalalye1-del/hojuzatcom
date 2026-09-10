import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../storage/profile_storage_keys.dart';

/// خدمة موحدة لكل فواتير وتذاكر وعروض حجوزاتكم.
///
/// تستقبل البيانات كنصوص جاهزة من الشاشة، ثم تنشئ ملف PDF عربي يمكن حفظه
/// على الجهاز أو مشاركته كملف حقيقي بدلاً من مشاركة نص فقط.
class InvoicePdfService {
  const InvoicePdfService._();

  static const _secureStorage = FlutterSecureStorage();
  static const _customerNameLabels = [
    'اسم العميل',
    'اسم المستأجر',
    'اسم الراكب',
    'اسم المسافر',
    'اسم المرسل',
    'الاسم الرباعي',
    'الاسم',
    'العميل',
  ];
  static const _customerPhoneLabels = [
    'رقم الهاتف',
    'هاتف العميل',
    'الهاتف',
    'الجوال',
  ];

  static Future<Uint8List> build({
    required String title,
    required String reference,
    required List<(String, String)> details,
    String status = 'مؤكد',
  }) async {
    final fontData = await rootBundle.load(
      'assets/fonts/mohammad-bold-art-1.ttf',
    );
    final logoData = await rootBundle.load(
      'assets/images/hujozat_main_logo.png',
    );
    final font = pw.Font.ttf(fontData);
    final logo = pw.MemoryImage(
      logoData.buffer.asUint8List(
        logoData.offsetInBytes,
        logoData.lengthInBytes,
      ),
    );
    var customerName = _detailValue(details, _customerNameLabels);
    var phone = _detailValue(details, _customerPhoneLabels);
    if (customerName.isEmpty) {
      customerName = await _readStoredProfile(profileNameStorageKey);
    }
    if (phone.isEmpty) {
      phone = await _readStoredProfile(profilePhoneStorageKey);
    }
    final printableDetails = <(String, String)>[
      if (!_hasDetail(details, _customerNameLabels))
        ('اسم العميل', customerName.isEmpty ? '—' : customerName),
      if (!_hasDetail(details, _customerPhoneLabels))
        ('رقم الهاتف', phone.isEmpty ? '—' : phone),
      ...details,
    ];
    final date = _detailValue(details, const ['التاريخ', 'الموعد']);
    final payment = _detailValue(details, const [
      'طريقة الدفع',
      'الدفع',
      'المحفظة',
    ]);
    final amount = _detailValue(details, const [
      'الإجمالي العام',
      'الإجمالي',
      'المبلغ',
    ]);
    final serviceName = _serviceName(title);
    final document = pw.Document(
      title: title,
      author: 'Hujuzatcom',
      creator: 'تطبيق حجوزاتكم',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 54),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        textDirection: pw.TextDirection.rtl,
        footer: (_) => _footer(),
        build: (_) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(0, 10, 0, 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromHex('#155FC5'),
                  width: 1.4,
                ),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _brandLine(
                          'ألوان للإعلام والتسويق',
                          color: PdfColor.fromHex('#155FC5'),
                          fontSize: 14,
                        ),
                        _brandLine('قطاع التسويق', fontSize: 11),
                        _brandLine(
                          'تطبيق حجوزاتكم الخدمي',
                          color: PdfColor.fromHex('#F57C00'),
                          fontSize: 11,
                        ),
                        _brandLine('اليمن - صنعاء', fontSize: 10),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    height: 78,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(11),
                      border: pw.Border.all(
                        color: PdfColor.fromHex('#155FC5'),
                        width: 1.5,
                      ),
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          serviceName,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#155FC5'),
                            fontSize: 15,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'خدمة من حجوزاتكم',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#F57C00'),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Image(logo, height: 76, fit: pw.BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          _identityPanel(
            reference: reference,
            date: date,
            customerName: customerName,
            phone: phone,
          ),
          pw.SizedBox(height: 12),
          _summaryPanel(service: serviceName, payment: payment, amount: amount),
          pw.SizedBox(height: 18),
          pw.Center(
            child: pw.Container(
              width: 180,
              padding: const pw.EdgeInsets.symmetric(vertical: 7),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#155FC5'),
                borderRadius: pw.BorderRadius.circular(7),
              ),
              child: pw.Text(
                'تفاصيل الحجز',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 16),
              ),
            ),
          ),
          pw.SizedBox(height: 7),
          ...printableDetails.map(
            (item) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 9,
                horizontal: 10,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColor.fromHex('#D8E2F3')),
                  left: pw.BorderSide(
                    color: PdfColor.fromHex('#155FC5'),
                    width: .7,
                  ),
                  right: pw.BorderSide(
                    color: PdfColor.fromHex('#F57C00'),
                    width: .7,
                  ),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(flex: 2, child: pw.Text(item.$1)),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      item.$2,
                      textAlign: pw.TextAlign.left,
                      style: pw.TextStyle(font: font),
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EEF5FF'),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColor.fromHex('#155FC5')),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [pw.Text('الحالة: $status')],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'شكراً لاستخدامك تطبيق حجوزاتكم',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _identityPanel({
    required String reference,
    required String date,
    required String customerName,
    required String phone,
  }) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: PdfColor.fromHex('#155FC5'), width: 1.2),
    ),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            children: [
              _labelValue('رقم الفاتورة', reference),
              pw.SizedBox(height: 9),
              _labelValue('التاريخ', date.isEmpty ? _today() : date),
            ],
          ),
        ),
        pw.Container(
          width: 1,
          height: 57,
          margin: const pw.EdgeInsets.symmetric(horizontal: 14),
          color: PdfColors.grey400,
        ),
        pw.Expanded(
          child: pw.Column(
            children: [
              _labelValue(
                'اسم العميل',
                customerName.isEmpty ? '—' : customerName,
              ),
              pw.SizedBox(height: 9),
              _labelValue('رقم الهاتف', phone.isEmpty ? '—' : phone),
            ],
          ),
        ),
      ],
    ),
  );

  static pw.Widget _summaryPanel({
    required String service,
    required String payment,
    required String amount,
  }) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 11, horizontal: 8),
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: PdfColor.fromHex('#155FC5'), width: 1.1),
    ),
    child: pw.Row(
      children: [
        _summaryCell('الخدمة', service),
        _summaryDivider(),
        _summaryCell('طريقة الدفع', payment.isEmpty ? '—' : payment),
        _summaryDivider(),
        _summaryCell('العملة', 'ريال يمني'),
        _summaryDivider(),
        _summaryCell('المبلغ', amount.isEmpty ? '—' : amount),
      ],
    ),
  );

  static pw.Widget _summaryCell(String label, String value) => pw.Expanded(
    child: pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(color: PdfColor.fromHex('#155FC5'), fontSize: 9),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    ),
  );

  static pw.Widget _summaryDivider() =>
      pw.Container(width: .8, height: 34, color: PdfColors.grey400);

  static pw.Widget _brandLine(
    String value, {
    required double fontSize,
    PdfColor? color,
  }) => pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Text(
      value,
      textAlign: pw.TextAlign.right,
      style: pw.TextStyle(fontSize: fontSize, color: color),
    ),
  );

  static pw.Widget _labelValue(String label, String value) => pw.Row(
    children: [
      pw.Text(
        '$label: ',
        style: pw.TextStyle(color: PdfColor.fromHex('#155FC5'), fontSize: 10),
      ),
      pw.Expanded(
        child: pw.Text(
          value,
          maxLines: 1,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ),
    ],
  );

  static pw.Widget _footer() => pw.Column(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(height: 4, color: PdfColor.fromHex('#155FC5')),
          ),
          pw.Expanded(
            child: pw.Container(height: 4, color: PdfColor.fromHex('#F57C00')),
          ),
        ],
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        'شارع حدة أمام مبنى التأمينات والمعاشات  |  www.hujuzat.com  |  info@hujuzat.com  |  70000000',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    ],
  );

  static String _detailValue(
    List<(String, String)> details,
    List<String> labels,
  ) {
    for (final item in details) {
      if (labels.any((label) => item.$1.contains(label))) return item.$2;
    }
    return '';
  }

  static bool _hasDetail(List<(String, String)> details, List<String> labels) =>
      details.any((item) => labels.any((label) => item.$1.contains(label)));

  static Future<String> _readStoredProfile(String key) async {
    try {
      return (await _secureStorage.read(key: key))?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static String _serviceName(String title) =>
      title.replaceFirst(RegExp(r'^(فاتورة|حجز|تذكرة|عرض سعر)\s*'), '').trim();

  static String _today() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  static Future<String?> save({
    required String fileName,
    required String title,
    required String reference,
    required List<(String, String)> details,
    String status = 'مؤكد',
  }) async {
    final bytes = await build(
      title: title,
      reference: reference,
      details: details,
      status: status,
    );
    return FileSaver.instance.saveFile(
      name: _safeName(fileName),
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static Future<ShareResult> share({
    required String fileName,
    required String title,
    required String reference,
    required List<(String, String)> details,
    String status = 'مؤكد',
  }) async {
    final bytes = await build(
      title: title,
      reference: reference,
      details: details,
      status: status,
    );
    final name = '${_safeName(fileName)}.pdf';
    return SharePlus.instance.share(
      ShareParams(
        title: title,
        text: 'ملف $title من تطبيق حجوزاتكم',
        files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
        fileNameOverrides: [name],
      ),
    );
  }

  static String _safeName(String value) =>
      value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-\u0600-\u06ff]'), '_');
}
