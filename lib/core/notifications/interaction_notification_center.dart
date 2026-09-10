import 'package:flutter/material.dart';

import '../../features/bookings/data/booking_repository.dart';
import '../../features/bookings/domain/booking.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../localization/app_locale.dart';

class InteractionNotificationCenter extends ChangeNotifier {
  InteractionNotificationCenter._();

  static final instance = InteractionNotificationCenter._();

  NotificationRepository? _repository;
  BookingRepository? _bookingRepository;
  final List<AppNotification> _items = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  int _unreadCount = 0;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;
  bool get backendConfigured => _repository != null;

  void configure({
    NotificationRepository? notificationRepository,
    BookingRepository? bookingRepository,
  }) {
    _repository = notificationRepository;
    _bookingRepository = bookingRepository;
  }

  Future<void> load({bool silent = false}) async {
    final repository = _repository;
    if (repository == null || _loading) return;
    _loading = true;
    if (!silent) notifyListeners();
    try {
      final page = await repository.list();
      _items
        ..clear()
        ..addAll(page.notifications);
      _unreadCount = page.unreadCount;
      _error = null;
      _loaded = true;
    } catch (_) {
      _error = 'تعذر تحميل الإشعارات. تحقق من الاتصال ثم حاول مجددًا.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(AppNotification item) async {
    if (item.isRead) return;
    final repository = _repository;
    if (repository == null) return;
    await repository.markRead(item.id);
    final index = _items.indexWhere((value) => value.id == item.id);
    if (index >= 0) {
      _items[index] = item.copyWith(isRead: true, readAt: DateTime.now());
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final repository = _repository;
    if (repository == null) return;
    await repository.markAllRead();
    for (var index = 0; index < _items.length; index++) {
      _items[index] = _items[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> delete(AppNotification item) async {
    final repository = _repository;
    if (repository == null) return;
    await repository.delete(item.id);
    _items.removeWhere((value) => value.id == item.id);
    if (!item.isRead && _unreadCount > 0) _unreadCount--;
    notifyListeners();
  }

  Future<Booking?> linkedBooking(AppNotification item) async {
    final id = item.bookingId;
    final repository = _bookingRepository;
    if (id == null || repository == null) return null;
    return repository.getById(id);
  }

  // يبقى متوافقًا مع الاستدعاءات المحلية القديمة دون إنشاء إشعارات وهمية
  // عند اتصال التطبيق بالخادم.
  void recordInterest(String title, {String? body}) {
    return;
    final now = DateTime.now();
    _items.insert(
      0,
      AppNotification(
        id: now.microsecondsSinceEpoch.toString(),
        type: 'local.interest',
        title: title,
        body: body ?? 'سنرسل لك تحديثات وعروضاً مرتبطة باهتمامك.',
        isRead: false,
        createdAt: now,
      ),
    );
    _unreadCount++;
    if (_items.length > 60) _items.removeRange(60, _items.length);
    notifyListeners();
  }
}

class InteractionNotificationIcon extends StatefulWidget {
  const InteractionNotificationIcon({super.key, required this.color});

  final Color color;

  @override
  State<InteractionNotificationIcon> createState() =>
      _InteractionNotificationIconState();
}

class _InteractionNotificationIconState
    extends State<InteractionNotificationIcon> {
  @override
  void initState() {
    super.initState();
    if (!InteractionNotificationCenter.instance.loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        InteractionNotificationCenter.instance.load(silent: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: InteractionNotificationCenter.instance,
    builder: (_, _) {
      final count = InteractionNotificationCenter.instance.unreadCount;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none_rounded, color: widget.color),
          if (count > 0)
            PositionedDirectional(
              top: -7,
              start: 13,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xffe53935),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class InteractionRouteObserver extends NavigatorObserver {
  void _record(Route<dynamic>? route) {
    final name = route?.settings.name ?? route?.runtimeType.toString();
    if (name == null || name == '/' || name == 'services-home') return;
    InteractionNotificationCenter.instance.recordInterest(
      'اهتمام جديد بخدمات حجوزاتكم',
      body: 'تم تسجيل زيارتك للخدمة لإرسال التنبيهات المناسبة.',
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _record(route);
  }
}

class InteractionNotificationsScreen extends StatefulWidget {
  const InteractionNotificationsScreen({super.key});

  @override
  State<InteractionNotificationsScreen> createState() =>
      _InteractionNotificationsScreenState();
}

class _InteractionNotificationsScreenState
    extends State<InteractionNotificationsScreen> {
  final center = InteractionNotificationCenter.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => center.load());
  }

  Future<void> _open(AppNotification item) async {
    try {
      await center.markRead(item);
      if (!mounted || item.bookingId == null) return;
      final booking = await center.linkedBooking(item);
      if (!mounted) return;
      if (booking == null) {
        _message('تعذر العثور على الحجز المرتبط.');
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _LinkedBookingScreen(booking: booking),
        ),
      );
    } catch (_) {
      if (mounted) _message('تعذر فتح الإشعار. حاول مجددًا.');
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: LocalizedText(value)));
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      appBar: AppBar(
        title: const LocalizedText('الإشعارات'),
        actions: [
          TextButton(
            onPressed: center.unreadCount == 0
                ? null
                : () async {
                    try {
                      await center.markAllRead();
                    } catch (_) {
                      if (mounted) _message('تعذرت قراءة جميع الإشعارات.');
                    }
                  },
            child: const LocalizedText('قراءة الكل'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: center,
        builder: (context, _) {
          if (center.loading && center.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!center.backendConfigured) {
            return const _NotificationMessage(
              icon: Icons.cloud_off_rounded,
              message: 'خادم الإشعارات غير مفعّل في هذا الإصدار.',
            );
          }
          if (center.error != null && center.items.isEmpty) {
            return _NotificationMessage(
              icon: Icons.wifi_off_rounded,
              message: center.error!,
              onRetry: center.load,
            );
          }
          if (center.items.isEmpty) {
            return const _NotificationMessage(
              icon: Icons.notifications_none_rounded,
              message: 'لا توجد إشعارات حاليًا',
            );
          }
          return RefreshIndicator(
            onRefresh: center.load,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              itemCount: center.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final item = center.items[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async => true,
                  onDismissed: (_) async {
                    try {
                      await center.delete(item);
                    } catch (_) {
                      await center.load(silent: true);
                      if (mounted) _message('تعذر حذف الإشعار.');
                    }
                  },
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsetsDirectional.only(end: 22),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  ),
                  child: Card(
                    color: item.isRead
                        ? Theme.of(context).cardColor
                        : const Color(0xffeef3ff),
                    child: ListTile(
                      onTap: () => _open(item),
                      leading: CircleAvatar(
                        backgroundColor: item.isRead
                            ? Colors.grey.shade200
                            : const Color(0xff2455e9),
                        child: Icon(
                          _iconFor(item.type),
                          color: item.isRead ? Colors.grey : Colors.white,
                        ),
                      ),
                      title: LocalizedText(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.isRead
                              ? FontWeight.w500
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          LocalizedText(item.body),
                          const SizedBox(height: 7),
                          Text(
                            _dateLabel(item.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: item.bookingId == null
                          ? (!item.isRead
                                ? const Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: Color(0xff2455e9),
                                  )
                                : null)
                          : const Icon(Icons.chevron_left_rounded),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    ),
  );

  IconData _iconFor(String type) {
    if (type.startsWith('payment')) return Icons.payment_rounded;
    if (type.startsWith('refund')) return Icons.currency_exchange_rounded;
    if (type.startsWith('booking')) return Icons.event_available_rounded;
    if (type.startsWith('service')) return Icons.alarm_rounded;
    return Icons.notifications_active_outlined;
  }

  String _dateLabel(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _NotificationMessage extends StatelessWidget {
  const _NotificationMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: Colors.grey),
          const SizedBox(height: 12),
          LocalizedText(message),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const LocalizedText('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _LinkedBookingScreen extends StatelessWidget {
  const _LinkedBookingScreen({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      appBar: AppBar(title: const LocalizedText('تفاصيل الحجز')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _BookingDetail(label: 'رقم الحجز', value: booking.id),
          _BookingDetail(label: 'الحالة', value: _statusLabel(booking.status)),
          _BookingDetail(
            label: 'المبلغ الإجمالي',
            value: '${booking.total} ${booking.currency}',
          ),
          _BookingDetail(label: 'رقم الخدمة', value: booking.serviceId),
          _BookingDetail(label: 'رقم مقدم الخدمة', value: booking.providerId),
        ],
      ),
    ),
  );

  String _statusLabel(BookingStatus status) => switch (status) {
    BookingStatus.pending => 'قيد الانتظار',
    BookingStatus.confirmed => 'مؤكد',
    BookingStatus.completed => 'مكتمل',
    BookingStatus.cancelled => 'ملغي',
  };
}

class _BookingDetail extends StatelessWidget {
  const _BookingDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: LocalizedText(label),
      subtitle: SelectableText(value),
    ),
  );
}
