import 'package:flutter/material.dart';

import '../localization/app_locale.dart';

class AppMediaItem {
  const AppMediaItem.image(this.posterAsset, {this.label = 'صورة'})
    : isVideo = false;

  const AppMediaItem.video(this.posterAsset, {this.label = 'فيديو'})
    : isVideo = true;

  final String posterAsset;
  final String label;
  final bool isVideo;
}

/// معرض موحّد للصور ومقاطع الفيديو القادمة من بيانات الخدمة.
///
/// يستخدم صورة الغلاف كملصق للفيديو حتى يتم ربط مصدر الفيديو الذي ترسله
/// لوحة التحكم، ويقدم من الآن تجربة التنقل والتشغيل المتناسقة في كل البطاقات.
class AppMediaGallery extends StatefulWidget {
  const AppMediaGallery({
    super.key,
    required this.items,
    required this.height,
    required this.keyPrefix,
    this.accentColor = const Color(0xff2455e9),
    this.borderRadius = 0,
    this.compact = false,
  });

  final List<AppMediaItem> items;
  final double height;
  final String keyPrefix;
  final Color accentColor;
  final double borderRadius;
  final bool compact;

  @override
  State<AppMediaGallery> createState() => _AppMediaGalleryState();
}

class _AppMediaGalleryState extends State<AppMediaGallery> {
  final PageController _controller = PageController();
  int _selectedIndex = 0;
  int? _playingIndex;

  int get _firstVideoIndex => widget.items.indexWhere((item) => item.isVideo);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showVideo() {
    final index = _firstVideoIndex;
    if (index < 0) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleVideo(int index) {
    setState(() => _playingIndex = _playingIndex == index ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return SizedBox(height: widget.height);
    final hasVideo = _firstVideoIndex >= 0;
    final selectedItem = widget.items[_selectedIndex];

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              key: Key('${widget.keyPrefix}-gallery'),
              controller: _controller,
              itemCount: widget.items.length,
              onPageChanged: (index) => setState(() {
                _selectedIndex = index;
                _playingIndex = null;
              }),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final playing = _playingIndex == index;
                return Stack(
                  key: item.isVideo
                      ? Key('${widget.keyPrefix}-video-player')
                      : null,
                  fit: StackFit.expand,
                  children: [
                    Image.asset(item.posterAsset, fit: BoxFit.cover),
                    if (item.isVideo) ...[
                      const ColoredBox(color: Color(0x7207132b)),
                      Center(
                        child: Semantics(
                          button: true,
                          label: l10n(
                            playing ? 'إيقاف الفيديو' : 'تشغيل الفيديو',
                          ),
                          child: InkWell(
                            key: Key('${widget.keyPrefix}-video-toggle'),
                            onTap: () => _toggleVideo(index),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: widget.compact ? 54 : 82,
                              height: widget.compact ? 54 : 82,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .94),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x55000000),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: widget.accentColor,
                                size: widget.compact ? 36 : 54,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!widget.compact)
                        PositionedDirectional(
                          start: 20,
                          end: 20,
                          bottom: 54,
                          child: Column(
                            children: [
                              LocalizedText(
                                item.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 7),
                              if (playing)
                                TweenAnimationBuilder<double>(
                                  key: ValueKey(
                                    '${widget.keyPrefix}-$index-$playing',
                                  ),
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(seconds: 12),
                                  builder: (_, value, _) =>
                                      LinearProgressIndicator(
                                        value: value,
                                        minHeight: 5,
                                        color: Colors.white,
                                        backgroundColor: Colors.white38,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                )
                              else
                                const LocalizedText(
                                  'اضغط لتشغيل الفيديو',
                                  style: TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
            PositionedDirectional(
              end: widget.compact ? 6 : 12,
              bottom: widget.compact ? 6 : 12,
              child: _MediaBadge(
                icon: selectedItem.isVideo
                    ? Icons.videocam_rounded
                    : Icons.photo_library_outlined,
                label: '${_selectedIndex + 1}/${widget.items.length}',
                compact: widget.compact,
              ),
            ),
            if (hasVideo && !selectedItem.isVideo)
              PositionedDirectional(
                start: widget.compact ? 6 : 12,
                bottom: widget.compact ? 6 : 12,
                child: InkWell(
                  key: Key('${widget.keyPrefix}-open-video'),
                  onTap: _showVideo,
                  borderRadius: BorderRadius.circular(30),
                  child: _MediaBadge(
                    icon: Icons.play_circle_fill_rounded,
                    label: widget.compact ? l10n('فيديو') : l10n('عرض الفيديو'),
                    compact: widget.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({
    required this.icon,
    required this.label,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 6 : 10,
      vertical: compact ? 4 : 7,
    ),
    decoration: BoxDecoration(
      color: const Color(0xb8000000),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: compact ? 13 : 18),
        SizedBox(width: compact ? 3 : 5),
        LocalizedText(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 9 : 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
