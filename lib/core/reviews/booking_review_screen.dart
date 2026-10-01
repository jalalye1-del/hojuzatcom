import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../network/json_parsing.dart';

class BookingReviewScreen extends StatefulWidget {
  const BookingReviewScreen({
    super.key,
    required this.api,
    required this.bookingId,
  });
  final ApiClient api;
  final String bookingId;
  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  final comment = TextEditingController();
  int rating = 5;
  bool loading = true;
  bool busy = false;
  bool saved = false;
  bool loaded = false;
  String? error;
  String get path => 'bookings/${Uri.encodeComponent(widget.bookingId)}/review';

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = expectJsonMap(await widget.api.get(path));
      if (!mounted) return;
      final data = response['data'];
      if (data != null) {
        final review = expectJsonMap(data);
        rating = review['rating'] as int;
        comment.text = review['comment'] as String? ?? '';
        saved = true;
      }
      loaded = true;
    } catch (_) {
      if (!mounted) return;
      error = 'تعذر تحميل التقييم. حاول مجددًا.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> submit() async {
    if (busy || saved || !loaded) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.api.post(
        path,
        body: {'rating': rating, 'comment': comment.text.trim()},
      );
      if (mounted) setState(() => saved = true);
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'لم يتأكد حفظ التقييم. أعد المحاولة بنفس البيانات.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('تقييم الحجز')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (error != null) Text(error!, key: const Key('review-error')),
                if (!loaded)
                  FilledButton(
                    onPressed: load,
                    child: const Text('إعادة المحاولة'),
                  ),
                if (loaded) ...[
                  Text(
                    saved
                        ? 'تقييمك محفوظ لهذا الحجز'
                        : 'قيّم تجربتك بعد اكتمال الحجز',
                  ),
                  Wrap(
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        key: Key('booking-review-star-${index + 1}'),
                        tooltip: '${index + 1}',
                        onPressed: saved || busy
                            ? null
                            : () => setState(() => rating = index + 1),
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                  TextField(
                    controller: comment,
                    readOnly: saved || busy,
                    maxLength: 2000,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'تعليقك (اختياري)',
                    ),
                  ),
                  if (!saved)
                    FilledButton(
                      onPressed: busy ? null : submit,
                      child: Text(busy ? 'جارٍ الحفظ…' : 'حفظ التقييم'),
                    ),
                ],
              ],
            ),
    ),
  );
}
