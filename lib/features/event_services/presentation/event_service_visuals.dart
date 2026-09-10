import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';
import '../data/event_service_catalog.dart';

const eventInk = Color(0xff173c2a);
const eventGold = Color(0xffbd8b40);
const eventCream = Color(0xfffffbf4);

class EventCatalogView extends StatefulWidget {
  const EventCatalogView({
    super.key,
    required this.catalog,
    required this.builder,
  });
  final EventServiceCatalog catalog;
  final WidgetBuilder builder;
  @override
  State<EventCatalogView> createState() => _EventCatalogViewState();
}

class _EventCatalogViewState extends State<EventCatalogView> {
  @override
  void initState() {
    super.initState();
    widget.catalog.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.catalog,
    builder: (context, _) => widget.builder(context),
  );
}

class EventImage extends StatelessWidget {
  const EventImage(this.source, {super.key, this.fit = BoxFit.cover});
  final String source;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
        const ColoredBox(
          color: Color(0xffe8ddca),
          child: Center(
            child: Icon(Icons.image_outlined, color: eventGold, size: 42),
          ),
        );
    final uri = Uri.tryParse(source);
    if (uri?.scheme == 'https' && uri!.host.isNotEmpty) {
      return Image.network(source, fit: fit, errorBuilder: fallback);
    }
    if (source.startsWith('assets/')) {
      return Image.asset(source, fit: fit, errorBuilder: fallback);
    }
    return fallback(context, StateError('Missing image'), null);
  }
}

class EventHeroBanner extends StatelessWidget {
  const EventHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    this.onTap,
    this.label = 'لمناسبتك',
    this.icon = Icons.celebration_outlined,
  });
  final String title, subtitle, image, label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Material(
      color: eventInk,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(child: EventImage(image)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      eventInk.withValues(alpha: .68),
                      eventInk.withValues(alpha: .95),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: const Color(0xffefcb87), size: 23),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LocalizedText(
                          label,
                          style: const TextStyle(
                            color: Color(0xffefcb87),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  LocalizedText(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LocalizedText(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LocalizedText(
                          'استعرض التفاصيل',
                          style: TextStyle(color: Color(0xffefcb87)),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Color(0xffefcb87),
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EventPortraitCard extends StatelessWidget {
  const EventPortraitCard({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
    required this.onTap,
  });
  final String title, description, image;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xffeadfce)),
    ),
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventImage(image),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x990b2b1b)],
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: 10,
                  start: 12,
                  child: CircleAvatar(
                    backgroundColor: eventCream,
                    child: Icon(icon, color: eventGold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    title,
                    style: const TextStyle(
                      color: eventInk,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 7),
                  LocalizedText(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward, color: eventGold, size: 21),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class EventServiceGallery extends StatelessWidget {
  const EventServiceGallery({
    super.key,
    required this.images,
    required this.keyPrefix,
  });
  final List<String> images;
  final String keyPrefix;
  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LocalizedText('لا توجد صور مضافة حالياً'),
      );
    }
    return SizedBox(
      height: 154,
      child: ListView.separated(
        key: Key('$keyPrefix-gallery'),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => SizedBox(
          width: 200,
          child: Material(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              key: Key('$keyPrefix-photo-$index'),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: SizedBox(
                    height: 480,
                    child: Column(
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            itemCount: images.length,
                            itemBuilder: (_, i) => InteractiveViewer(
                              child: EventImage(
                                images[(index + i) % images.length],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: LocalizedText('اسحب لاستعراض الصور'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EventImage(images[index]),
                  PositionedDirectional(
                    bottom: 8,
                    end: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData eventSectionIcon(String id) => switch (id) {
  'printing' => Icons.markunread_mailbox_outlined,
  'hospitality' => Icons.restaurant_outlined,
  'teams' => Icons.groups_outlined,
  'production' => Icons.camera_alt_outlined,
  'decoration' => Icons.local_florist_outlined,
  _ => Icons.celebration_outlined,
};
