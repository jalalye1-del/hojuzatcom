import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../documents/invoice_pdf_service.dart';
import '../localization/app_locale.dart';
import '../../features/auth/presentation/app_session.dart';

class ServiceReviewStore {
  bool centralOnly = false;
  static const _usedPrefix = 'service_used_';
  static const _pendingPrefix = 'service_review_pending_';
  static const _secureStorage = FlutterSecureStorage();

  final _usedMemory = <String>{};
  final _pendingMemory = <String>{};

  String _normalizedService(String service) =>
      service.replaceAll(RegExp(r'\s+'), '_');

  String _key(String service) {
    final accountDigest = sha256
        .convert(utf8.encode(AppSession.currentUserIdentity))
        .toString();
    return '${accountDigest}_${_normalizedService(service)}';
  }

  String _legacyKey(String service) {
    final account = AppSession.currentUserIdentity.replaceAll(
      RegExp(r'[^a-zA-Z0-9+_-]'),
      '',
    );
    return '${account}_${_normalizedService(service)}';
  }

  Future<void> _migrateLegacyPreferences(
    SharedPreferences prefs,
    String service,
    String key,
  ) async {
    final legacyKey = _legacyKey(service);
    if (legacyKey == key) return;

    for (final prefix in const [
      _usedPrefix,
      _pendingPrefix,
      'service_review_rating_',
      'service_review_comment_',
    ]) {
      final oldStorageKey = '$prefix$legacyKey';
      final newStorageKey = '$prefix$key';
      final value = prefs.get(oldStorageKey);
      if (value != null && !prefs.containsKey(newStorageKey)) {
        if (value is bool) await prefs.setBool(newStorageKey, value);
        if (value is int) await prefs.setInt(newStorageKey, value);
        if (value is String) await prefs.setString(newStorageKey, value);
      }
      await prefs.remove(oldStorageKey);
    }

    if (kReleaseMode) {
      final oldCommentKey = 'service_review_comment_$legacyKey';
      final newCommentKey = 'service_review_comment_$key';
      final oldComment = await _secureStorage.read(key: oldCommentKey);
      if (oldComment != null &&
          await _secureStorage.read(key: newCommentKey) == null) {
        await _secureStorage.write(key: newCommentKey, value: oldComment);
      }
      await _secureStorage.delete(key: oldCommentKey);
    }
  }

  Future<bool> hasUsed(String service) async {
    if (centralOnly) return false;
    final key = _key(service);
    if (_usedMemory.contains(key)) return true;
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyPreferences(prefs, service, key);
    return prefs.getBool('$_usedPrefix$key') ?? false;
  }

  Future<bool> hasPendingReview(String service) async {
    if (centralOnly) return false;
    final key = _key(service);
    if (_pendingMemory.contains(key)) return true;
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyPreferences(prefs, service, key);
    return (prefs.getBool('$_usedPrefix$key') ?? false) &&
        (prefs.getBool('$_pendingPrefix$key') ?? false);
  }

  Future<void> markCompleted(String service) async {
    if (centralOnly) return;
    final key = _key(service);
    _usedMemory.add(key);
    _pendingMemory.add(key);
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyPreferences(prefs, service, key);
    await prefs.setBool('$_usedPrefix$key', true);
    await prefs.setBool('$_pendingPrefix$key', true);
  }

  Future<void> saveReview(
    String service, {
    required int rating,
    required String comment,
  }) async {
    if (centralOnly) throw StateError('قيّم الحجز المكتمل من حجوزاتي.');
    final key = _key(service);
    _pendingMemory.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyPreferences(prefs, service, key);
    await prefs.setBool('$_pendingPrefix$key', false);
    await prefs.setInt('service_review_rating_$key', rating);
    final commentKey = 'service_review_comment_$key';
    if (kReleaseMode) {
      await _secureStorage.write(key: commentKey, value: comment);
      await prefs.remove(commentKey);
    } else {
      await prefs.setString(commentKey, comment);
    }
  }

  Future<void> clearForTesting() async {
    _usedMemory.clear();
    _pendingMemory.clear();
    final prefs = await SharedPreferences.getInstance();
    final reviewKeys = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith(_usedPrefix) ||
              key.startsWith(_pendingPrefix) ||
              key.startsWith('service_review_rating_') ||
              key.startsWith('service_review_comment_'),
        )
        .toList();
    for (final key in reviewKeys) {
      await prefs.remove(key);
    }
  }
}

final serviceReviewStore = ServiceReviewStore();

class ServiceRatingScreen extends StatefulWidget {
  const ServiceRatingScreen({
    super.key,
    required this.serviceKey,
    required this.serviceName,
    this.isAutomaticPrompt = false,
  });

  final String serviceKey;
  final String serviceName;
  final bool isAutomaticPrompt;

  @override
  State<ServiceRatingScreen> createState() => _ServiceRatingScreenState();
}

class _ServiceRatingScreenState extends State<ServiceRatingScreen> {
  int rating = 5;
  final comment = TextEditingController();

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!allowLocalReview(context)) return;
    await serviceReviewStore.saveReview(
      widget.serviceKey,
      rating: rating,
      comment: comment.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: LocalizedText(l10n('تم حفظ تقييمك، شكراً لك'))),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: const Color(0xfff5f7ff),
      appBar: AppBar(title: LocalizedText(l10n('تقييم الخدمة'))),
      body: SafeArea(
        child: ListView(
          key: const Key('service-rating-screen'),
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Color(0x16000000), blurRadius: 18),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xffe9efff),
                    child: Icon(
                      Icons.reviews_rounded,
                      color: Color(0xff2455e9),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LocalizedText(
                    l10n('كيف كانت تجربتك؟'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff07143d),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  LocalizedText(
                    l10n(widget.serviceName),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff2455e9),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.isAutomaticPrompt) ...[
                    const SizedBox(height: 8),
                    LocalizedText(
                      l10n('أخبرنا عن تجربتك السابقة'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xff75809b)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          key: Key('service-rating-star-${index + 1}'),
                          onPressed: () => setState(() => rating = index + 1),
                          icon: Icon(
                            index < rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xffffa000),
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: comment,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: l10n('تقييم الخدمة'),
                hintText: l10n('أخبرنا عن تجربتك السابقة'),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('submit-service-rating'),
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded),
              label: LocalizedText(l10n('إرسال التقييم')),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 56),
                backgroundColor: const Color(0xff2455e9),
              ),
            ),
            if (widget.isAutomaticPrompt) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: LocalizedText(l10n('لاحقاً')),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class ServiceCompletionFooter extends StatefulWidget {
  const ServiceCompletionFooter({
    super.key,
    required this.serviceKey,
    required this.serviceName,
    required this.invoiceText,
    this.invoiceDetails,
    this.invoiceTitle,
    this.invoiceReference,
    this.invoiceStatus = 'مؤكد',
    this.onViewInvoice,
    this.rateButtonKey,
    this.ratingScreenBuilder,
  });

  final String serviceKey;
  final String serviceName;
  final String invoiceText;

  /// نفس القائمة المستخدمة لبناء معاينة الفاتورة على الشاشة.
  /// عند تمريرها لا تُستخلص بيانات مختصرة من [invoiceText] إطلاقاً.
  final List<(String, String)>? invoiceDetails;
  final String? invoiceTitle;
  final String? invoiceReference;
  final String invoiceStatus;
  final VoidCallback? onViewInvoice;
  final Key? rateButtonKey;
  final WidgetBuilder? ratingScreenBuilder;

  @override
  State<ServiceCompletionFooter> createState() =>
      _ServiceCompletionFooterState();
}

class _ServiceCompletionFooterState extends State<ServiceCompletionFooter> {
  @override
  void initState() {
    super.initState();
    serviceReviewStore.markCompleted(widget.serviceKey);
  }

  List<(String, String)> get _details {
    if (widget.invoiceDetails != null) {
      return List<(String, String)>.unmodifiable(widget.invoiceDetails!);
    }
    final lines = widget.invoiceText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return lines.map<(String, String)>((line) {
      final separator = line.indexOf(':');
      if (separator < 0) return ('التفاصيل', line);
      return (
        line.substring(0, separator).trim(),
        line.substring(separator + 1).trim(),
      );
    }).toList();
  }

  String get _reference {
    if (widget.invoiceReference?.trim().isNotEmpty == true) {
      return widget.invoiceReference!.trim();
    }
    for (final item in _details) {
      if (item.$1.contains('رقم')) return item.$2;
    }
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _saveInvoice() async {
    try {
      await InvoicePdfService.save(
        fileName: '${widget.serviceKey}_$_reference',
        title: widget.invoiceTitle ?? 'فاتورة ${widget.serviceName}',
        reference: _reference,
        details: _details,
        status: widget.invoiceStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: LocalizedText(l10n('تم حفظ الفاتورة بصيغة PDF'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: LocalizedText(l10n('تعذر حفظ ملف الفاتورة'))),
      );
    }
  }

  Future<void> _shareInvoice() async {
    try {
      await InvoicePdfService.share(
        fileName: '${widget.serviceKey}_$_reference',
        title: widget.invoiceTitle ?? 'فاتورة ${widget.serviceName}',
        reference: _reference,
        details: _details,
        status: widget.invoiceStatus,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: LocalizedText(l10n('تعذر مشاركة ملف الفاتورة'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;
          final buttons = [
            _FooterButton(
              icon: Icons.receipt_long_outlined,
              label: l10n('حفظ الفاتورة'),
              onPressed: _saveInvoice,
            ),
            _FooterButton(
              icon: Icons.share_outlined,
              label: l10n('مشاركة الفاتورة'),
              onPressed: _shareInvoice,
            ),
            _FooterButton(
              key: widget.rateButtonKey ?? const Key('service-footer-rate'),
              icon: Icons.star_outline_rounded,
              label: l10n('تقييم الخدمة'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      widget.ratingScreenBuilder ??
                      (_) => ServiceRatingScreen(
                        serviceKey: widget.serviceKey,
                        serviceName: widget.serviceName,
                      ),
                ),
              ),
            ),
          ];
          if (compact) {
            return Column(
              children: buttons
                  .map(
                    (button) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(width: double.infinity, child: button),
                    ),
                  )
                  .toList(),
            );
          }
          return Row(
            children: buttons
                .map(
                  (button) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: button,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
      const SizedBox(height: 9),
      OutlinedButton.icon(
        key: const Key('service-footer-home'),
        onPressed: () => Navigator.of(context).popUntil(
          (route) => route.settings.name == 'services-home' || route.isFirst,
        ),
        icon: const Icon(Icons.home_outlined),
        label: LocalizedText(l10n('العودة إلى الرئيسية')),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
      ),
    ],
  );
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    label: FittedBox(fit: BoxFit.scaleDown, child: LocalizedText(label)),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
  );
}

bool allowLocalReview(BuildContext context) {
  if (!serviceReviewStore.centralOnly) return true;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قيّم حجزك المكتمل من صفحة حجوزاتي.')));
  return false;
}