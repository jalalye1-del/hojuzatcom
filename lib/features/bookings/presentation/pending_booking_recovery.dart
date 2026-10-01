import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/network/api_exception.dart';
import '../data/booking_repository.dart';
import '../domain/booking.dart';

Future<void> recoverPendingBookings(
  BuildContext context,
  BookingRepository? repository,
) async {
  if (repository is! RemoteBookingRepository) return;
  try {
    final attempts = await repository.pendingAttempts();
    for (final attempt in attempts) {
      if (!context.mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PendingBookingRecoveryDialog(
          attempt: attempt,
          retry: () => repository.retryPending(attempt.id),
          lookup: () => repository.lookupLegacyHotelAttempt(attempt.id),
          discard: () => repository.discardLegacyHotelAttempt(attempt.id),
        ),
      );
      if (proceed != true) return;
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: LocalizedText(
          'تعذر استعادة المحاولات المعلقة الآن. يمكنك المحاولة عند تسجيل الدخول مجددًا.',
        ),
      ),
    );
  }
}

class PendingBookingRecoveryDialog extends StatefulWidget {
  const PendingBookingRecoveryDialog({
    super.key,
    required this.attempt,
    required this.retry,
    this.lookup,
    this.discard,
  });
  final PendingBookingAttempt attempt;
  final Future<Booking> Function() retry;
  final Future<Booking> Function()? lookup;
  final Future<void> Function()? discard;

  @override
  State<PendingBookingRecoveryDialog> createState() =>
      _PendingBookingRecoveryDialogState();
}

class _PendingBookingRecoveryDialogState
    extends State<PendingBookingRecoveryDialog> {
  bool busy = false;
  bool lookupNotFound = false;
  String? error;
  Booking? booking;

  @override
  void initState() {
    super.initState();
    if (widget.attempt.needsFreshHotelQuote) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) checkLegacyHotelBooking();
      });
    }
  }

  Future<void> checkLegacyHotelBooking() async {
    if (widget.lookup == null) {
      setState(() => error = 'تعذر التحقق من الحجز. احتفظنا بالمحاولة.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      lookupNotFound = false;
    });
    try {
      final found = await widget.lookup!();
      if (mounted) setState(() => booking = found);
    } on ApiException catch (failure) {
      if (mounted) {
        setState(() {
          if (failure.statusCode == 404 &&
              failure.code == 'booking_not_found') {
            lookupNotFound = true;
          } else {
            error = 'تعذر التحقق من وجود الحجز. احتفظنا بالمحاولة ومفتاحها.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = 'تعذر التحقق من وجود الحجز. احتفظنا بالمحاولة ومفتاحها.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> discard() async {
    if (widget.discard == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.discard!();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر حذف المحاولة. حاول مجددًا.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resume() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.retry();
      if (mounted) setState(() => booking = result);
    } on ApiException catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = 'تعذرت متابعة الحجز. احتُفظ بالمحاولة لتتمكن من إعادتها.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.attempt.body;
    final needsFreshHotelQuote = widget.attempt.needsFreshHotelQuote;
    final metadata = body['metadata'];
    final name = metadata is Map ? metadata['service_name'] : null;
    final provider = metadata is Map ? metadata['provider_name'] : null;
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: LocalizedText(
          booking != null
              ? needsFreshHotelQuote
                    ? 'الحجز موجود على الخادم'
                    : 'تم استرجاع الحجز'
              : needsFreshHotelQuote
              ? 'حجز فندق يحتاج معاينة سعر جديدة'
              : 'متابعة حجز سابق',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (booking == null) ...[
                LocalizedText(
                  needsFreshHotelQuote
                      ? lookupNotFound
                            ? 'لم نجد حجزًا بهذه المحاولة. افحص «حجوزاتي» أولًا، ثم احذف المحاولة المحلية وابدأ حجزًا جديدًا من صفحة الفندق لمعاينة السعر الحالي.'
                            : 'هذه محاولة فندق قديمة بلا سعر مُعاين. لن نعيد إرسالها؛ نتحقق أولًا مما إذا سُجل الحجز بالفعل.'
                      : 'لم يصل تأكيد هذه المحاولة. يمكنك متابعتها بنفس البيانات، وقد يكون الخادم قد سجّلها بالفعل.',
                ),
                if (name != null) Text(name.toString()),
                if (provider != null) Text(provider.toString()),
                if (!needsFreshHotelQuote)
                  Text('${body['total']} ${body['currency']}'),
                if (!needsFreshHotelQuote && body['scheduled_at'] != null)
                  Text(body['scheduled_at'].toString()),
              ] else ...[
                const LocalizedText('رقم الحجز'),
                Text(booking!.id),
                if (needsFreshHotelQuote)
                  const LocalizedText(
                    'الحجز موجود على الخادم. حذف المحاولة المحلية لا يلغي الحجز.',
                  )
                else
                  const LocalizedText('لم يتم تنفيذ أي دفع.'),
              ],
              if (error != null) LocalizedText(error!),
              if (busy) const CircularProgressIndicator(),
            ],
          ),
        ),
        actions: needsFreshHotelQuote
            ? [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(context, false),
                  child: const LocalizedText('لاحقًا'),
                ),
                if (booking == null && !lookupNotFound)
                  TextButton(
                    onPressed: busy ? null : checkLegacyHotelBooking,
                    child: const LocalizedText('إعادة التحقق'),
                  ),
                if ((booking != null || lookupNotFound) &&
                    widget.discard != null)
                  FilledButton(
                    onPressed: busy ? null : discard,
                    child: LocalizedText(
                      lookupNotFound
                          ? 'فحصت حجوزاتي، احذف المحلي'
                          : 'حذف المحاولة المحلية',
                    ),
                  ),
              ]
            : booking != null
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const LocalizedText('متابعة'),
                ),
              ]
            : [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(context, false),
                  child: const LocalizedText('لاحقًا'),
                ),
                FilledButton(
                  onPressed: busy ? null : resume,
                  child: const LocalizedText('متابعة المحاولة'),
                ),
              ],
      ),
    );
  }
}
