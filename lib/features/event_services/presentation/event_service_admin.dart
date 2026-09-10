import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/formatting/money_format.dart';
import '../../../core/localization/app_locale.dart';
import '../../halls/presentation/premium_hall_flow.dart'
    show PremiumHallHomeScreen;
import '../data/event_service_catalog.dart';
import '../domain/event_service.dart';
import 'event_service_visuals.dart';

/// إدارة محلية للتطوير؛ ربط الإدارة العامة يتطلب صلاحيات الخادم.
class EventServiceAdminScreen extends StatelessWidget {
  const EventServiceAdminScreen({super.key, required this.catalog});
  final EventServiceCatalog catalog;

  Future<void> _provider(
    BuildContext context, [
    EventServiceProvider? provider,
  ]) => _edit(
    context,
    title: provider == null ? 'إضافة مركز' : 'تعديل المركز',
    fields: [
      _Field('name', 'اسم المركز أو المكتب', value: provider?.name ?? ''),
      _Field('description', 'وصف المركز', value: provider?.description ?? ''),
      _Field(
        'image',
        'صورة المركز',
        value: provider?.image ?? eventServiceImage,
        image: true,
      ),
      _Field(
        'provinces',
        'المحافظات المتاحة',
        value: provider?.provinces.join('\n') ?? 'all',
        multiline: true,
        help: 'محافظة في كل سطر، أو all لجميع المحافظات',
      ),
    ],
    onSave: (values) => catalog.saveProvider(
      EventServiceProvider(
        id: provider?.id ?? catalog.newId('center'),
        name: values['name']!,
        description: values['description']!,
        image: values['image']!,
        provinces: _lines(values['provinces']!),
        paymentMethodIds:
            provider?.paymentMethodIds ?? const ['jawali', 'jeeb', 'onecash'],
      ),
    ),
  );

  Future<void> _promotion(
    BuildContext context, [
    EventPromotion? promotion,
  ]) => _edit(
    context,
    title: 'بنر عرض مميز',
    fields: [
      _Field('title', 'عنوان العرض', value: promotion?.title ?? ''),
      _Field('subtitle', 'وصف العرض', value: promotion?.subtitle ?? ''),
      _Field(
        'image',
        'صورة العرض',
        value: promotion?.image ?? eventServiceImage,
        image: true,
      ),
      _Field(
        'target',
        'القاعة أو المركز',
        value: promotion == null
            ? 'hall:${PremiumHallHomeScreen.halls.first}'
            : '${promotion.isHall ? 'hall' : 'center'}:${promotion.targetId}',
        options: {
          for (final hall in PremiumHallHomeScreen.halls) 'hall:$hall': hall,
          for (final center in catalog.providers)
            'center:${center.id}': center.name,
        },
      ),
    ],
    onSave: (values) {
      final target = values['target']!;
      return catalog.savePromotion(
        EventPromotion(
          id: promotion?.id ?? catalog.newId('offer'),
          title: values['title']!,
          subtitle: values['subtitle']!,
          image: values['image']!,
          isHall: target.startsWith('hall:'),
          targetId: target.substring(target.indexOf(':') + 1),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: LocalizedText('الإدارة غير متاحة في هذه النسخة')),
      );
    }
    return EventCatalogView(
      catalog: catalog,
      builder: (context) => _AdminPage(
        title: 'لوحة تحكم خدمات المناسبات',
        children: [
          const LocalizedText(
            'إدارة محلية: تُحفظ التعديلات على هذا الجهاز وتظهر مباشرة في الواجهات.',
          ),
          if (!catalog.loaded) const LinearProgressIndicator(),
          if (catalog.loadError != null)
            ListTile(
              title: const LocalizedText('تعذر تحميل البيانات المحفوظة'),
              trailing: TextButton(
                onPressed: catalog.retryLoad,
                child: const LocalizedText('إعادة المحاولة'),
              ),
            ),
          if (catalog.loaded && catalog.loadError == null) ...[
            OutlinedButton.icon(
              onPressed: catalog.saving
                  ? null
                  : () => _edit(
                      context,
                      title: 'البنر الرئيسي للمراكز',
                      fields: [
                        _Field(
                          'title',
                          'عنوان البنر',
                          value: catalog.bannerTitle,
                        ),
                        _Field(
                          'subtitle',
                          'وصف البنر',
                          value: catalog.bannerSubtitle,
                        ),
                        _Field(
                          'image',
                          'صورة البنر',
                          value: catalog.bannerImage,
                          image: true,
                        ),
                      ],
                      onSave: (values) => catalog.saveBanner(
                        title: values['title']!,
                        subtitle: values['subtitle']!,
                        image: values['image']!,
                      ),
                    ),
              icon: const Icon(Icons.image_outlined),
              label: const LocalizedText('تعديل البنر الرئيسي'),
            ),
            _Toolbar(
              'المراكز والمكاتب',
              'إضافة مركز',
              () => _provider(context),
              key: const Key('admin-add-center'),
            ),
            for (final provider in catalog.providers)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      key: Key('admin-center-${provider.id}'),
                      title: LocalizedText(provider.name),
                      subtitle: const LocalizedText(
                        'إدارة الأقسام والتصنيفات والخدمات',
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventServiceCenterAdminScreen(
                            catalog: catalog,
                            providerId: provider.id,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _provider(context, provider),
                          child: const LocalizedText('تعديل'),
                        ),
                        TextButton(
                          onPressed: () => _delete(
                            context,
                            provider.name,
                            () => catalog.deleteProvider(provider.id),
                            detail: 'سيتم حذف المركز وتصنيفاته وخدماته وعروضه.',
                          ),
                          child: const LocalizedText('حذف'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            _Toolbar('عروض مميزة', 'إضافة عرض', () => _promotion(context)),
            for (final promotion in catalog.promotions)
              Card(
                child: ListTile(
                  title: LocalizedText(promotion.title),
                  subtitle: LocalizedText(promotion.subtitle),
                  onTap: () => _promotion(context, promotion),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n('حذف'),
                    onPressed: () => _delete(
                      context,
                      promotion.title,
                      () => catalog.deletePromotion(promotion.id),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class EventServiceCenterAdminScreen extends StatefulWidget {
  const EventServiceCenterAdminScreen({
    super.key,
    required this.catalog,
    required this.providerId,
  });
  final EventServiceCatalog catalog;
  final String providerId;
  @override
  State<EventServiceCenterAdminScreen> createState() =>
      _EventServiceCenterAdminScreenState();
}

class _EventServiceCenterAdminScreenState
    extends State<EventServiceCenterAdminScreen> {
  String sectionId = 'printing';

  Future<void> categoryEditor([EventServiceCategory? category]) => _edit(
    context,
    title: category == null ? 'إضافة تصنيف' : 'تعديل التصنيف',
    fields: [_Field('name', 'اسم التصنيف', value: category?.name ?? '')],
    onSave: (values) => widget.catalog.saveCategory(
      EventServiceCategory(
        category?.id ?? widget.catalog.newId('category'),
        values['name']!,
        sectionId,
        providerId: widget.providerId,
      ),
    ),
  );

  Future<void> itemEditor(
    EventServiceCategory category, [
    EventServiceItem? item,
  ]) => _edit(
    context,
    title: item == null ? 'إضافة خدمة' : 'تعديل الخدمة',
    fields: [
      _Field('name', 'اسم الخدمة', value: item?.name ?? ''),
      _Field('unit', 'وحدة التسعير', value: item?.unit ?? 'قطعة'),
      _Field(
        'price',
        'سعر الوحدة بالريال اليمني',
        value: item?.unitPrice.toString() ?? '',
        number: true,
      ),
      _Field(
        'images',
        'صور الخدمة',
        value: item?.images.join('\n') ?? eventServiceImage,
        multiline: true,
        image: true,
        required: false,
        help: 'رابط صورة في كل سطر',
      ),
    ],
    onSave: (values) => widget.catalog.saveItem(
      EventServiceItem(
        id: item?.id ?? widget.catalog.newId('service'),
        providerId: widget.providerId,
        category: category,
        name: values['name']!,
        unit: values['unit']!,
        unitPrice: int.parse(_normalizeNumber(values['price']!)),
        images: _lines(values['images']!),
      ),
    ),
  );

  Future<void> sectionEditor() {
    final content = widget.catalog.sectionFor(widget.providerId, sectionId);
    return _edit(
      context,
      title: 'بنر وصور القسم',
      fields: [
        _Field('title', 'عنوان البنر', value: content.title),
        _Field('subtitle', 'وصف البنر', value: content.subtitle),
        _Field('image', 'صورة البنر', value: content.image, image: true),
        _Field(
          'gallery',
          'صور القسم',
          value: content.gallery.join('\n'),
          multiline: true,
          image: true,
          required: false,
          help: 'رابط صورة في كل سطر؛ احذف السطر لإزالة الصورة',
        ),
      ],
      onSave: (values) => widget.catalog.saveSection(
        EventSectionContent(
          providerId: widget.providerId,
          sectionId: sectionId,
          title: values['title']!,
          subtitle: values['subtitle']!,
          image: values['image']!,
          gallery: _lines(values['gallery']!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => EventCatalogView(
    catalog: widget.catalog,
    builder: (context) {
      final provider = widget.catalog.providerById(widget.providerId);
      if (provider == null) {
        return const _AdminPage(
          title: 'إدارة المركز',
          children: [LocalizedText('هذا المركز لم يعد متاحاً')],
        );
      }
      final categories = widget.catalog.categoriesFor(
        provider.id,
        sectionId: sectionId,
      );
      return _AdminPage(
        title: provider.name,
        children: [
          DropdownButtonFormField<String>(
            key: const Key('admin-section'),
            initialValue: sectionId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n('القسم'),
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final section in eventServiceSections)
                DropdownMenuItem(
                  value: section.id,
                  child: LocalizedText(section.name),
                ),
            ],
            onChanged: (value) => setState(() => sectionId = value!),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('admin-edit-section-media'),
            onPressed: sectionEditor,
            icon: const Icon(Icons.photo_library_outlined),
            label: const LocalizedText('تعديل بنر وصور القسم'),
          ),
          _Toolbar(
            'التصنيفات والخدمات',
            'إضافة تصنيف',
            categoryEditor,
            key: const Key('admin-add-category'),
          ),
          if (categories.isEmpty)
            const LocalizedText('أضف تصنيفاً ثم أضف الخدمات داخله'),
          for (final category in categories)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LocalizedText(
                      category.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => categoryEditor(category),
                          child: const LocalizedText('تعديل التصنيف'),
                        ),
                        TextButton(
                          key: Key('admin-delete-category-${category.id}'),
                          onPressed: () => _delete(
                            context,
                            category.name,
                            () => widget.catalog.deleteCategory(category.id),
                            detail: 'سيتم حذف التصنيف والخدمات الموجودة داخله.',
                          ),
                          child: const LocalizedText('حذف التصنيف'),
                        ),
                        TextButton.icon(
                          key: Key('admin-add-service-${category.id}'),
                          onPressed: () => itemEditor(category),
                          icon: const Icon(Icons.add),
                          label: const LocalizedText('إضافة خدمة'),
                        ),
                      ],
                    ),
                    for (final item
                        in widget.catalog
                            .itemsFor(provider)
                            .where((item) => item.category.id == category.id))
                      ListTile(
                        key: Key('admin-service-${item.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: LocalizedText(item.name),
                        subtitle: LocalizedText(
                          '${formatMoney(item.unitPrice)} ر.ي / ${item.unit}',
                        ),
                        onTap: () => itemEditor(category, item),
                        trailing: IconButton(
                          key: Key('admin-delete-service-${item.id}'),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n('حذف الخدمة'),
                          onPressed: () => _delete(
                            context,
                            item.name,
                            () => widget.catalog.deleteItem(item.id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _AdminPage extends StatelessWidget {
  const _AdminPage({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: Scaffold(
      backgroundColor: eventCream,
      appBar: AppBar(
        title: LocalizedText(title, style: const TextStyle(fontSize: 18)),
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: children),
      ),
    ),
  );
}

class _Toolbar extends StatelessWidget {
  const _Toolbar(this.title, this.action, this.onPressed, {super.key});
  final String title, action;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        LocalizedText(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          label: LocalizedText(action),
        ),
      ],
    ),
  );
}

class _Field {
  const _Field(
    this.id,
    this.label, {
    this.value = '',
    this.multiline = false,
    this.number = false,
    this.image = false,
    this.required = true,
    this.options,
    this.help,
  });
  final String id, label, value;
  final bool multiline, number, image, required;
  final Map<String, String>? options;
  final String? help;
}

Future<void> _edit(
  BuildContext context, {
  required String title,
  required List<_Field> fields,
  required Future<void> Function(Map<String, String>) onSave,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _EditorDialog(title: title, fields: fields, onSave: onSave),
);

class _EditorDialog extends StatefulWidget {
  const _EditorDialog({
    required this.title,
    required this.fields,
    required this.onSave,
  });
  final String title;
  final List<_Field> fields;
  final Future<void> Function(Map<String, String>) onSave;
  @override
  State<_EditorDialog> createState() => _EditorDialogState();
}

class _EditorDialogState extends State<_EditorDialog> {
  final formKey = GlobalKey<FormState>();
  late final controllers = {
    for (final field in widget.fields)
      field.id: TextEditingController(text: field.value),
  };
  bool saving = false;
  String? error;
  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onSave({
        for (final entry in controllers.entries)
          entry.key: entry.value.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'تعذر حفظ التعديل. يرجى المحاولة مرة أخرى.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: localizedTextDirection,
    child: PopScope(
      canPop: !saving,
      child: AlertDialog(
        title: LocalizedText(widget.title),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final field in widget.fields) ...[
                    if (field.options != null)
                      DropdownButtonFormField<String>(
                        key: Key('admin-field-${field.id}'),
                        initialValue: controllers[field.id]!.text,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n(field.label),
                        ),
                        items: field.options!.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: LocalizedText(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) => controllers[field.id]!.text = value!,
                      )
                    else
                      TextFormField(
                        key: Key('admin-field-${field.id}'),
                        controller: controllers[field.id],
                        enabled: !saving,
                        maxLines: field.multiline ? 3 : 1,
                        keyboardType: field.number
                            ? TextInputType.number
                            : TextInputType.text,
                        decoration: InputDecoration(
                          labelText: l10n(field.label),
                          helperText: field.help == null
                              ? null
                              : l10n(field.help!),
                          helperMaxLines: 3,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (field.required && text.isEmpty) {
                            return l10n('هذا الحقل مطلوب');
                          }
                          if (field.number &&
                              (int.tryParse(_normalizeNumber(text)) ?? -1) <
                                  0) {
                            return l10n('أدخل سعراً صحيحاً');
                          }
                          if (field.image &&
                              _lines(
                                text,
                              ).any((source) => !validEventImage(source))) {
                            return l10n('أدخل رابط صورة HTTPS صحيحاً');
                          }
                          return null;
                        },
                      ),
                    if (field.image)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  final source = await showDialog<String>(
                                    context: context,
                                    builder: (context) => SimpleDialog(
                                      title: const LocalizedText('اختر صورة'),
                                      children: [
                                        for (final source in [
                                          eventServiceImage,
                                          'assets/Services images/مطاعم.jpg',
                                        ])
                                          SimpleDialogOption(
                                            onPressed: () =>
                                                Navigator.pop(context, source),
                                            child: SizedBox(
                                              height: 100,
                                              width: 180,
                                              child: EventImage(source),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                  if (source != null && mounted) {
                                    final controller = controllers[field.id]!;
                                    controller.text =
                                        field.multiline &&
                                            controller.text.isNotEmpty
                                        ? '${controller.text}\n$source'
                                        : source;
                                  }
                                },
                          icon: const Icon(Icons.photo_outlined),
                          label: const LocalizedText('اختيار صورة من التطبيق'),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  if (error != null)
                    LocalizedText(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: const LocalizedText('إلغاء'),
          ),
          FilledButton(
            key: const Key('admin-save'),
            onPressed: saving ? null : save,
            child: LocalizedText(saving ? 'جارٍ الحفظ...' : 'حفظ'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _delete(
  BuildContext context,
  String name,
  Future<void> Function() action, {
  String? detail,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Directionality(
      textDirection: localizedTextDirection,
      child: AlertDialog(
        title: const LocalizedText('تأكيد الحذف'),
        content: LocalizedText('$name\n${detail ?? 'سيتم حذف هذا العنصر.'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalizedText('إلغاء'),
          ),
          FilledButton(
            key: const Key('admin-confirm-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const LocalizedText('حذف'),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true) return;
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: LocalizedText('تعذر حذف العنصر')));
    }
  }
}

List<String> _lines(String text) => text
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toSet()
    .toList();
bool validEventImage(String source) {
  if (source.startsWith('assets/') && !source.contains('..')) return true;
  final uri = Uri.tryParse(source);
  return uri?.scheme == 'https' && uri!.host.isNotEmpty && uri.userInfo.isEmpty;
}

String _normalizeNumber(String value) {
  for (var i = 0; i < 10; i++) {
    value = value
        .replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i')
        .replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i');
  }
  return value;
}
