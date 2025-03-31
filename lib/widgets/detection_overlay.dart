import 'package:flutter/material.dart';
import '../models/detection.dart'; // Import the shared Detection class

class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;

  const DetectionOverlay({super.key, required this.detections});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children:
          detections.map((detection) {
            return Positioned(
              left: detection.rect.left,
              top: detection.rect.top,
              child: Container(
                width: detection.rect.width,
                height: detection.rect.height,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Text(
                  '${detection.label} ${(detection.confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
