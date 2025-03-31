import 'dart:ui';

import '../models/detection.dart'; // Import the shared Detection class

List<Detection> processDetections({
  required List<List<List<double>>> boxes,
  required List<List<double>> scores,
  required List<List<double>> classes,
  required double imageHeight,
  required double imageWidth,
  required List<String> labels,
  double threshold = 0.5,
}) {
  final List<Detection> results = [];

  for (int i = 0; i < scores[0].length; i++) {
    final double score = scores[0][i];
    if (score > threshold) {
      final double ymin = boxes[0][i][0] * imageHeight;
      final double xmin = boxes[0][i][1] * imageWidth;
      final double ymax = boxes[0][i][2] * imageHeight;
      final double xmax = boxes[0][i][3] * imageWidth;

      final rect = Rect.fromLTRB(xmin, ymin, xmax, ymax);

      final labelIndex = classes[0][i].toInt();
      final label = labelIndex < labels.length ? labels[labelIndex] : "unknown";

      results.add(Detection(rect: rect, label: label, confidence: score));
    }
  }

  return results;
}
