import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// خدمة موحدة لكل فواتير وتذاكر وعروض حجوزاتكم.
///
/// تستقبل البيانات كنصوص جاهزة من الشاشة، ثم تنشئ ملف PDF عربي يمكن حفظه
/// على الجهاز أو مشاركته كملف حقيقي بدلاً من مشاركة نص فقط.
class InvoicePdfService {
  const InvoicePdfService._();

  static Future<Uint8List> build({
    required String title,
    required String reference,
    required List<(String, String)> details,
    String status = 'مؤكد',
  }) async {
    final fontData = await rootBundle.load(
      'assets/fonts/mohammad-bold-art-1.ttf',
    );
    final font = pw.Font.ttf(fontData);
    final document = pw.Document(
      title: title,
      author: 'Hujuzatcom',
      creator: 'تطبيق حجوزاتكم',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        textDirection: pw.TextDirection.rtl,
        build: (_) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F7F1E7'),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColor.fromHex('#BC8638')),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'حجوزاتكم',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 27,
                    color: PdfColor.fromHex('#155FC5'),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(title, style: pw.TextStyle(font: font, fontSize: 20)),
                pw.Text('المرجع: $reference'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          ...details.map(
            (item) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 9),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(item.$1)),
                  pw.Text(item.$2, style: pw.TextStyle(font: font)),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EAF7F0'),
              borderRadius: pw.BorderRadius.circular(8),
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

  static String _safeName(String value) => value
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9_\-\u0600-\u06ff]'), '_');
}
