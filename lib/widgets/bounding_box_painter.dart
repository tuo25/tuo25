import 'package:flutter/material.dart';

class BoundingBoxPainter extends StatelessWidget {
  final List<Map<String, dynamic>> recognitions;
  final double imageHeight;
  final double imageWidth;
  final Size previewSize;

  const BoundingBoxPainter({
    super.key,
    required this.recognitions,
    required this.imageHeight,
    required this.imageWidth,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BoxPainter(
        recognitions: recognitions,
        imageHeight: imageHeight,
        imageWidth: imageWidth,
        previewSize: previewSize,
      ),
      child: Container(),
    );
  }
}

class _BoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;
  final double imageHeight;
  final double imageWidth;
  final Size previewSize;

  _BoxPainter({
    required this.recognitions,
    required this.imageHeight,
    required this.imageWidth,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;

    final paint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final textStyle = TextStyle(
      color: Colors.redAccent,
      fontSize: 14,
      backgroundColor: Colors.white,
    );

    for (var result in recognitions) {
      final rect = result['rect'];
      final left = rect['x'] * scaleX;
      final top = rect['y'] * scaleY;
      final width = rect['w'] * scaleX;
      final height = rect['h'] * scaleY;

      canvas.drawRect(Rect.fromLTWH(left, top, width, height), paint);

      final label = result['label'] ?? '';
      final confidence = (result['confidence'] * 100).toStringAsFixed(1);

      final textSpan = TextSpan(
        text: '$label ($confidence%)',
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(left, top - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
