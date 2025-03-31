import 'dart:ui';

class Detection {
  final Rect rect;
  final String label;
  final double confidence;

  Detection({
    required this.rect,
    required this.label,
    required this.confidence,
  });
}
