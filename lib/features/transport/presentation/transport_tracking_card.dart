import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';

class TransportTrackingCard extends StatelessWidget {
  const TransportTrackingCard({
    super.key,
    required this.title,
    required this.distance,
    required this.rating,
    required this.status,
  });

  final String title;
  final String distance;
  final double rating;
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x180b2c57),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        SizedBox(
          height: 155,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _MapPainter()),
              const Positioned(
                right: 55,
                top: 52,
                child: Icon(
                  Icons.location_on_rounded,
                  color: Color(0xff155fc5),
                  size: 38,
                ),
              ),
              const Positioned(
                left: 55,
                bottom: 35,
                child: Icon(
                  Icons.flag_rounded,
                  color: Color(0xff159a61),
                  size: 32,
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: LocalizedText(
                    'التتبع المباشر غير متاح حاليًا',
                    style: const TextStyle(
                      color: Color(0xff159a61),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      title,
                      style: const TextStyle(
                        color: Color(0xff0b2c57),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const LocalizedText('بانتظار بيانات الموقع الفعلية'),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.directions_rounded),
                label: const LocalizedText('الاتجاهات'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xffeef3f7), BlendMode.src);
    final streets = Paint()
      ..color = Colors.white
      ..strokeWidth = 8;
    final minor = Paint()
      ..color = const Color(0xffd8e3eb)
      ..strokeWidth = 2;
    for (var y = 20.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 13), streets);
      canvas.drawLine(Offset(0, y + 12), Offset(size.width, y - 4), minor);
    }
    for (var x = 35.0; x < size.width; x += 70) {
      canvas.drawLine(Offset(x, 0), Offset(x - 25, size.height), streets);
    }
    final route = Paint()
      ..color = const Color(0xff155fc5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width - 65, 72)
      ..quadraticBezierTo(size.width / 2, 30, 65, size.height - 45);
    canvas.drawPath(path, route);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
