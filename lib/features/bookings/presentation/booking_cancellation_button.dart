import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/network/api_exception.dart';
import '../data/booking_repository.dart';
import '../domain/booking.dart';

class BookingCancellationButton extends StatefulWidget {
  const BookingCancellationButton({
    super.key,
    required this.booking,
    required this.repository,
    required this.onCancelled,
  });

  final Booking booking;
  final BookingRepository repository;
  final ValueChanged<Booking> onCancelled;

  @override
  State<BookingCancellationButton> createState() =>
      _BookingCancellationButtonState();
}

class _BookingCancellationButtonState extends State<BookingCancellationButton> {
  bool _busy = false;
  bool _cancelled = false;

  Future<void> _cancel() async {
    if (_busy || _cancelled) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const LocalizedText('إلغاء الحجز'),
          content: const LocalizedText(
            'هل تريد إلغاء هذا الحجز؟ تخضع إمكانية الإلغاء وأي استرداد لسياسة الخدمة المعتمدة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const LocalizedText('الاحتفاظ بالحجز'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const LocalizedText('تأكيد الإلغاء'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final booking = await widget.repository.cancel(widget.booking.id);
      if (!mounted) return;
      setState(() => _cancelled = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: LocalizedText('تم إلغاء الحجز.')));
      widget.onCancelled(booking);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: LocalizedText(error.message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: LocalizedText(
            'تعذر التحقق من نتيجة الإلغاء. حدّث الحجوزات قبل المحاولة مجددًا.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cancelled ||
        (widget.booking.status != BookingStatus.pending &&
            widget.booking.status != BookingStatus.confirmed)) {
      return const SizedBox.shrink();
    }
    return OutlinedButton.icon(
      onPressed: _busy ? null : _cancel,
      icon: const Icon(Icons.cancel_outlined),
      label: LocalizedText(_busy ? 'جارٍ التحقق...' : 'إلغاء الحجز'),
    );
  }
}
