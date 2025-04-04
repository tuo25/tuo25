import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../widgets/bounding_box_painter.dart'; // Ensure this path matches your project structure

class TUOCameraScreen extends StatelessWidget {
  final CameraController _controller;
  final List<Map<String, dynamic>> _recognitions;
  final double _imageHeight;
  final double _imageWidth;

  const TUOCameraScreen({
    super.key,
    required CameraController controller,
    required List<Map<String, dynamic>> recognitions,
    required double imageHeight,
    required double imageWidth,
  }) : _controller = controller,
       _recognitions = recognitions,
       _imageHeight = imageHeight,
       _imageWidth = imageWidth;

  @override
  Widget build(BuildContext context) {
    final previewSize = _controller.value.previewSize;
    if (!_controller.value.isInitialized || previewSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller),
          if (_recognitions.isNotEmpty)
            BoundingBoxPainter(
              recognitions: _recognitions,
              imageHeight: _imageHeight,
              imageWidth: _imageWidth,
              previewSize: previewSize,
            ),
        ],
      ),
    );
  }
}
