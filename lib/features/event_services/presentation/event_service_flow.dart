import '../../bookings/presentation/provider_booking_flow.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/documents/invoice_pdf_service.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_locale.dart';
import '../../auth/domain/auth_input_policy.dart';
import '../../catalog/data/control_panel_repository.dart';
import '../data/event_service_catalog.dart';
import '../domain/event_service.dart';
import 'event_service_admin.dart';
import 'event_service_visuals.dart';

const _ink = Color(0xff173c2a);
const _gold = Color(0xffbd8b40);
const _cream = Color(0xfffffbf4);

class EventServicesHomeScreen extends StatefulWidget {
  const EventServicesHomeScreen({
    super.key,
    required this.province,
    this.catalog,
  });
  final String province;
  final EventServiceCatalog? catalog;
  @override
  State<EventServicesHomeScreen> createState() =>
      _EventServicesHomeScreenState();
}

class _EventServicesHomeScreenState extends State<EventServicesHomeScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog ?? eventServiceCatalog;
    return EventCatalogView(
      catalog: catalog,
      builder: (context) {
        final centers = catalog
            .centersFor(widget.province)
            .where(
              (provider) => l10n(
                '${provider.name} ${provider.description}',
              ).toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        return _Page(
          title: eventServicesTitle,
          actions: [
            if (kDebugMode && ProviderBookingFlow.current == null)
              IconButton(
                key: const Key('event-open-admin'),
                tooltip: l10n('لوحة التحكم'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventServiceAdminScreen(catalog: catalog),
                  ),
                ),
                icon: const Icon(Icons.tune),
              ),
          ],
          children: [
            EventHeroBanner(
              key: const Key('event-centers-banner'),
              title: catalog.bannerTitle,
              subtitle: catalog.bannerSubtitle,
              image: catalog.bannerImage,
            ),
            const SizedBox(height: 18),
            TextField(
              key: const Key('event-center-search'),
              decoration: _input(
                'ابحث عن مركز أو مكتب',
              ).copyWith(prefixIcon: const Icon(Icons.search)),
              onChanged: (value) => setState(() => query = value.trim()),
            ),
            _Heading('المراكز والمكاتب في ${widget.province}'),
            if (catalog.loadError != null)
              ListTile(
                title: const LocalizedText('تعذر تحميل بيانات المراكز'),
                trailing: TextButton(
                  onPressed: catalog.retryLoad,
                  child: const LocalizedText('إعادة المحاولة'),
                ),
              ),
            if (centers.isEmpty)
              const LocalizedText('لا توجد نتائج مطابقة لبحثك'),
            for (final provider in centers)
              Card(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: Key('event-provider-${provider.id}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventServiceCenterScreen(
                        province: widget.province,
                        providerId: provider.id,
                        catalog: catalog,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 155, child: EventImage(provider.image)),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedText(
                              provider.name,
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 19,
                              ),
                            ),
                            const SizedBox(height: 6),
                            LocalizedText(provider.description),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Icon(
                                  Icons.celebration_outlined,
                                  color: _gold,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: LocalizedText('استعرض أقسام المركز'),
                                ),
                                Icon(Icons.arrow_forward, color: _gold),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const _DemoNotice(),
          ],
        );
      },
    );
  }
}

class EventServiceCart extends ChangeNotifier {
  EventServiceCart(this.catalog, this.providerId);
  final EventServiceCatalog catalog;
  final String providerId;
  final Map<String, int> _quantities = {};
  int quantity(String id) => _quantities[id] ?? 0;
  void setQuantity(String id, int quantity) {
    if (quantity < 0 || quantity > 9999) return;
    _quantities[id] = quantity;
    notifyListeners();
  }

  List<EventServiceLine> get lines {
    final provider = catalog.providerById(providerId);
    if (provider == null) return [];
    return [
      for (final item in catalog.itemsFor(provider))
        if (quantity(item.id) > 0)
          EventServiceLine(item: item, quantity: quantity(item.id)),
    ];
  }

  int get total => lines.fold(0, (sum, line) => sum + line.total);
}

class EventServiceCenterScreen extends StatefulWidget {
  const EventServiceCenterScreen({
    super.key,
    required this.province,
    required this.providerId,
    required this.catalog,
  });
  final String province, providerId;
  final EventServiceCatalog catalog;
  @override
  State<EventServiceCenterScreen> createState() =>
      _EventServiceCenterScreenState();
}

class _EventServiceCenterScreenState extends State<EventServiceCenterScreen> {
  late final cart = EventServiceCart(widget.catalog, widget.providerId);
  @override
  void dispose() {
    cart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.catalog, cart]),
    builder: (context, _) {
      final provider = widget.catalog.providerById(widget.providerId);
      if (provider == null) {
        return const _Page(
          title: eventServicesTitle,
          children: [LocalizedText('هذا المركز لم يعد متاحاً')],
        );
      }
      return _Page(
        title: provider.name,
        action: _cartAction(context, cart, widget.province, provider),
        children: [
          EventHeroBanner(
            title: provider.name,
            subtitle: provider.description,
            image: provider.image,
          ),
          const _Heading('أقسام المركز'),
          const LocalizedText(
            'اختر ما تحتاجه من الأقسام، واجمع خدمات المركز في حجز واحد.',
          ),
          const SizedBox(height: 12),
          for (final section in eventServiceSections)
            Card(
              color: Colors.white,
              child: ListTile(
                key: Key('event-section-${section.id}'),
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: _cream,
                  child: Icon(eventSectionIcon(section.id), color: _gold),
                ),
                title: LocalizedText(
                  section.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: LocalizedText(section.description),
                trailing: const Icon(Icons.arrow_forward, size: 20),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventServiceSelectionScreen(
                      province: widget.province,
                      providerId: provider.id,
                      section: section,
                      catalog: widget.catalog,
                      cart: cart,
                    ),
                  ),
                ),
              ),
            ),
          if (cart.lines.isNotEmpty) ...[
            const _Heading('الخدمات المختارة'),
            _LineSummary(lines: cart.lines),
          ],
        ],
      );
    },
  );
}

Widget _cartAction(
  BuildContext context,
  EventServiceCart cart,
  String province,
  EventServiceProvider provider,
) => _BottomAction(
  label: 'متابعة الحجز',
  total: cart.total,
  onPressed: cart.lines.isEmpty
      ? null
      : () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventServiceBookingScreen(
              province: province,
              provider: provider,
              lines: cart.lines,
            ),
          ),
        ),
);

class EventServiceSelectionScreen extends StatefulWidget {
  const EventServiceSelectionScreen({
    super.key,
    required this.province,
    required this.providerId,
    required this.section,
    required this.catalog,
    required this.cart,
  });
  final String province, providerId;
  final EventServiceSection section;
  final EventServiceCatalog catalog;
  final EventServiceCart cart;
  @override
  State<EventServiceSelectionScreen> createState() =>
      _EventServiceSelectionScreenState();
}

class _EventServiceSelectionScreenState
    extends State<EventServiceSelectionScreen> {
  String? selectedCategory;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.catalog, widget.cart]),
    builder: (context, _) {
      final provider = widget.catalog.providerById(widget.providerId);
      if (provider == null) {
        return const _Page(
          title: eventServicesTitle,
          children: [LocalizedText('هذا المركز لم يعد متاحاً')],
        );
      }
      final categories = widget.catalog.categoriesFor(
        provider.id,
        sectionId: widget.section.id,
      );
      final selected =
          categories.any((category) => category.id == selectedCategory)
          ? selectedCategory
          : categories.firstOrNull?.id;
      final items = widget.catalog
          .itemsFor(provider)
          .where((item) => item.category.id == selected)
          .toList();
      final content = widget.catalog.sectionFor(provider.id, widget.section.id);
      return _Page(
        title: widget.section.name,
        action: _cartAction(context, widget.cart, widget.province, provider),
        children: [
          EventHeroBanner(
            key: Key('event-section-banner-${widget.section.id}'),
            title: content.title,
            subtitle: content.subtitle,
            image: content.image,
            icon: eventSectionIcon(widget.section.id),
            label: provider.name,
          ),
          const _Heading('صور الخدمات'),
          EventServiceGallery(
            images: content.gallery,
            keyPrefix: 'event-${widget.section.id}',
          ),
          const _Heading('اختر الخدمات والكميات'),
          if (categories.isEmpty)
            const LocalizedText('لا توجد تصنيفات مضافة في هذا القسم حالياً'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                ChoiceChip(
                  key: Key('event-filter-${category.id}'),
                  label: LocalizedText(category.name),
                  selected: selected == category.id,
                  onSelected: (_) =>
                      setState(() => selectedCategory = category.id),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (categories.isNotEmpty && items.isEmpty)
            const LocalizedText('لا توجد خدمات مضافة في هذا التصنيف حالياً'),
          for (final item in items)
            Card(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (item.images.isNotEmpty)
                    SizedBox(height: 150, child: EventImage(item.images.first)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LocalizedText(
                          '${formatMoney(item.unitPrice)} ر.ي / ${item.unit}',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: Key('event-quantity-${item.id}'),
                          initialValue: '${widget.cart.quantity(item.id)}',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            _DigitsFormatter(),
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: _input('الكمية').copyWith(
                            helperText: l10n('أدخل صفراً لإزالة الخدمة'),
                            suffixText: l10n(item.unit),
                          ),
                          onChanged: (value) => widget.cart.setQuantity(
                            item.id,
                            int.tryParse(value) ?? 0,
                          ),
                        ),
                        if (item.images.length > 1) ...[
                          const SizedBox(height: 12),
                          EventServiceGallery(
                            images: item.images,
                            keyPrefix: 'event-item-${item.id}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (widget.cart.lines.isNotEmpty) ...[
            const _Heading('الخدمات المختارة'),
            _LineSummary(lines: widget.cart.lines),
          ],
        ],
      );
    },
  );
}

class EventServiceBookingScreen extends StatefulWidget {
  const EventServiceBookingScreen({
    super.key,
    required this.province,
    required this.provider,
    required this.lines,
  });
  final String province;
  final EventServiceProvider provider;
  final List<EventServiceLine> lines;

  @override
  State<EventServiceBookingScreen> createState() =>
      _EventServiceBookingScreenState();
}

class _EventServiceBookingScreenState extends State<EventServiceBookingScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final guests = TextEditingController(text: '100');
  final notes = TextEditingController();
  DateTime date = DateUtils.dateOnly(
    DateTime.now().add(const Duration(days: 1)),
  );
  TimeOfDay time = const TimeOfDay(hour: 18, minute: 0);

  DateTime get scheduledAt =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  @override
  void dispose() {
    for (final controller in [name, phone, address, guests, notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> chooseDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final value = await showDatePicker(
      context: context,
      initialDate: date.isBefore(today) ? today : date,
      firstDate: today,
      lastDate: DateTime(today.year + 2, today.month, today.day),
    );
    if (mounted && value != null) setState(() => date = value);
  }

  Future<void> chooseTime() async {
    final value = await showTimePicker(context: context, initialTime: time);
    if (mounted && value != null) setState(() => time = value);
  }

  void review() {
    if (!formKey.currentState!.validate()) return;
    if (!scheduledAt.isAfter(DateTime.now())) {
      _message(context, 'اختر موعداً قادماً للمناسبة');
      return;
    }
    final order = EventServiceOrder(
      provider: widget.provider,
      lines: widget.lines,
      province: widget.province,
      scheduledAt: scheduledAt,
      guestCount: int.parse(guests.text),
      address: address.text.trim(),
      customerName: name.text.trim(),
      phone: AuthInputPolicy.normalizePhone(_digits(phone.text)),
      notes: notes.text.trim(),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventServicePaymentScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'حجز خدمات المناسبة',
    action: _BottomAction(
      label: 'مراجعة الطلب والدفع',
      total: widget.lines.fold(0, (sum, line) => sum + line.total),
      onPressed: review,
    ),
    children: [
      _Heading(widget.provider.name),
      _LineSummary(lines: widget.lines),
      const _Heading('الموعد ومكان المناسبة'),
      OutlinedButton.icon(
        key: const Key('event-date'),
        onPressed: chooseDate,
        icon: const Icon(Icons.calendar_month),
        label: LocalizedText(eventServiceDate(scheduledAt).split(' ').first),
      ),
      OutlinedButton.icon(
        key: const Key('event-time'),
        onPressed: chooseTime,
        icon: const Icon(Icons.schedule),
        label: Text(time.format(context)),
      ),
      Form(
        key: formKey,
        child: Column(
          children: [
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('event-address'),
              controller: address,
              maxLength: 240,
              decoration: _input('مكان المناسبة والعنوان التفصيلي'),
              validator: (value) => (value?.trim().length ?? 0) < 5
                  ? l10n('أدخل عنوان المناسبة بالتفصيل')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('event-guests'),
              controller: guests,
              keyboardType: TextInputType.number,
              inputFormatters: [
                _DigitsFormatter(),
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: _input('عدد الضيوف'),
              validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                  ? l10n('أدخل عدد الضيوف')
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('event-customer-name'),
              controller: name,
              maxLength: 100,
              decoration: _input('الاسم الكامل'),
              validator: (value) => (value?.trim().length ?? 0) < 3
                  ? l10n('يرجى إدخال الاسم الكامل')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('event-phone'),
              controller: phone,
              keyboardType: TextInputType.phone,
              maxLength: 22,
              decoration: _input('رقم الهاتف'),
              validator: (value) =>
                  !AuthInputPolicy.isValidPhone(_digits(value ?? ''))
                  ? l10n('يرجى إدخال رقم هاتف صحيح')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('event-notes'),
              controller: notes,
              maxLength: 500,
              maxLines: 3,
              decoration: _input('ملاحظات المناسبة (اختياري)'),
            ),
          ],
        ),
      ),
    ],
  );
}

class EventServicePaymentScreen extends StatefulWidget {
  const EventServicePaymentScreen({super.key, required this.order});
  final EventServiceOrder order;

  @override
  State<EventServicePaymentScreen> createState() =>
      _EventServicePaymentScreenState();
}

class _EventServicePaymentScreenState extends State<EventServicePaymentScreen> with ProviderBookingState<EventServicePaymentScreen> {
  late final methods = (ProviderBookingFlow.current == null ? localControlPanelRepository.paymentMethods : const <PaymentMethodRecord>[])
      .where(
        (method) =>
            method.enabled &&
            widget.order.provider.paymentMethodIds.contains(method.id),
      )
      .toList();
  String? methodId;
  bool reviewed = false;
  bool completed = false;

  Future<void> confirm() async {
    if(!reviewed || (ProviderBookingFlow.current == null && methodId==null))return;
    await submitProviderBooking(ProviderBookingSelection(module:'halls',
      serviceName:widget.order.lines.first.item.name,providerId:widget.order.provider.id,
      scheduledAt:widget.order.scheduledAt,province:widget.order.province,
      orderItems:{for(final line in widget.order.lines)line.item.id:line.quantity},
      metadata:{'address':widget.order.address,'guest_count':widget.order.guestCount,
        'customer_name':widget.order.customerName,'phone':widget.order.phone,'notes':widget.order.notes}));
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: ProviderBookingFlow.current != null ? 'تأكيد طلب الحجز' : 'دفع خدمات المناسبة',
    action: _BottomAction(
      label: 'معاينة الحجز والفاتورة',
      total: widget.order.total,
      onPressed: reviewed && (ProviderBookingFlow.current != null || methodId != null) && !completed ? confirm : null,
    ),
    children: [
      const _Heading('مراجعة طلب الخدمات'),
      _Detail('مقدم الخدمة', widget.order.provider.name),
      _Detail('اسم العميل', widget.order.customerName),
      _Detail('رقم الهاتف', widget.order.phone),
      _Detail('المحافظة', widget.order.province),
      _Detail('الموعد', eventServiceDate(widget.order.scheduledAt)),
      _Detail('مكان المناسبة', widget.order.address),
      _Detail('عدد الضيوف', '${widget.order.guestCount}'),
      if (widget.order.notes.isNotEmpty)
        _Detail('ملاحظات المناسبة', widget.order.notes),
      _LineSummary(lines: widget.order.lines),
      const _Heading('طريقة الدفع'),
      const LocalizedText('دفع كامل لقيمة الخدمات المختارة'),
      if (methods.isEmpty)
        const LocalizedText('لا توجد وسيلة دفع متاحة لهذا المقدم حالياً.'),
      RadioGroup<String>(
        groupValue: methodId,
        onChanged: (value) => setState(() => methodId = value),
        child: Column(
          children: [
            for (final method in methods)
              RadioListTile<String>(
                key: Key('event-payment-${method.id}'),
                value: method.id,
                title: LocalizedText(method.name),
              ),
          ],
        ),
      ),
      const _DemoNotice(),
      CheckboxListTile(
        key: const Key('event-review-confirmation'),
        value: reviewed,
        onChanged: (value) => setState(() => reviewed = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: const LocalizedText(
          'راجعت الخدمات والكميات والموعد وقيمة الطلب',
        ),
      ),
    ],
  );
}

class EventServiceInvoiceScreen extends StatefulWidget {
  const EventServiceInvoiceScreen({super.key, required this.receipt});
  final EventServiceReceipt receipt;

  @override
  State<EventServiceInvoiceScreen> createState() =>
      _EventServiceInvoiceScreenState();
}

class _EventServiceInvoiceScreenState extends State<EventServiceInvoiceScreen> {
  bool exporting = false;

  Future<void> export({required bool share}) async {
    if (exporting) return;
    setState(() => exporting = true);
    final receipt = widget.receipt;
    try {
      if (share) {
        await InvoicePdfService.share(
          title: 'فاتورة تجريبية لخدمات المناسبات',
          reference: receipt.invoiceReference,
          details: receipt.invoiceDetails,
          status: receipt.status,
          fileName: receipt.invoiceReference,
        );
      } else {
        await InvoicePdfService.save(
          title: 'فاتورة تجريبية لخدمات المناسبات',
          reference: receipt.invoiceReference,
          details: receipt.invoiceDetails,
          status: receipt.status,
          fileName: receipt.invoiceReference,
        );
      }
    } catch (_) {
      if (mounted) {
        _message(context, 'تعذر تصدير الفاتورة، يرجى المحاولة مرة أخرى');
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'فاتورة خدمات المناسبات',
    children: [
      const Icon(Icons.receipt_long_rounded, color: _gold, size: 52),
      const _Heading('معاينة طلب خدمات المناسبة'),
      const _DemoNotice(),
      _Detail('رقم الفاتورة', widget.receipt.invoiceReference),
      for (final detail in widget.receipt.invoiceDetails)
        _Detail(detail.$1, detail.$2),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: exporting ? null : () => export(share: false),
        icon: const Icon(Icons.download),
        label: const LocalizedText('تحميل الفاتورة PDF'),
      ),
      OutlinedButton.icon(
        onPressed: exporting ? null : () => export(share: true),
        icon: const Icon(Icons.share),
        label: const LocalizedText('مشاركة الفاتورة'),
      ),
      TextButton(
        onPressed: () => Navigator.popUntil(
          context,
          (route) => route.isFirst || route.settings.name == eventServicesId,
        ),
        child: const LocalizedText('العودة للخدمات'),
      ),
    ],
  );
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.children,
    this.action,
    this.actions = const [],
  });
  final String title;
  final List<Widget> children;
  final Widget? action;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        actions: actions,
        backgroundColor: _cream,
        foregroundColor: _ink,
        title: LocalizedText(
          title,
          maxLines: 2,
          style: const TextStyle(fontSize: 18),
        ),
      ),
      bottomNavigationBar: action,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: children),
      ),
    ),
  );
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.total,
    required this.onPressed,
  });
  final String label;
  final int total;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocalizedText(
            'الإجمالي: ${formatMoney(total)} ر.ي',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _ink,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: onPressed,
            child: LocalizedText(label),
          ),
        ],
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 12),
    child: LocalizedText(
      text,
      style: const TextStyle(
        color: _ink,
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 14),
    child: LocalizedText(
      'بيانات تجريبية لمقدمي الخدمات والأسعار. '
      'الحجز والدفع للمعاينة، ولا يتم تحصيل أي مبلغ.',
      style: TextStyle(color: Color(0xff785b26), fontSize: 12),
    ),
  );
}

class _LineSummary extends StatelessWidget {
  const _LineSummary({required this.lines});
  final List<EventServiceLine> lines;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final line in lines)
            _Detail(
              line.item.name,
              '${line.quantity} × ${formatMoney(line.item.unitPrice)} ر.ي '
              '= ${formatMoney(line.total)} ر.ي',
            ),
        ],
      ),
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LocalizedText(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 3),
        LocalizedText(
          value,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

InputDecoration _input(String label) => InputDecoration(
  labelText: l10n(label),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
);

void _message(BuildContext context, String text) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: LocalizedText(text)));

String _digits(String value) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  for (var i = 0; i < 10; i++) {
    value = value.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
  }
  return value;
}

class _DigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => FilteringTextInputFormatter.digitsOnly.formatEditUpdate(
    oldValue,
    newValue.copyWith(text: _digits(newValue.text)),
  );
}
