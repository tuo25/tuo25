import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';

late List<CameraDescription> _cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const TUOManualApp());
}

class TUOManualApp extends StatelessWidget {
  const TUOManualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const ManualBoxScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ManualBoxScreen extends StatefulWidget {
  const ManualBoxScreen({super.key});

  @override
  State<ManualBoxScreen> createState() => _ManualBoxScreenState();
}

class _ManualBoxScreenState extends State<ManualBoxScreen> {
  late CameraController _controller;
  Rect? _box;
  Offset? _startPoint;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    _controller = CameraController(_cameras.first, ResolutionPreset.high);

    try {
      await _controller.initialize();

      // 💥 Commented out zoom initialization
      /*
      final _minZoom = await _controller.getMinZoomLevel();
      final _maxZoom = await _controller.getMaxZoomLevel();
      final _currentZoom = _minZoom;
      await _controller.setZoomLevel(_currentZoom);
      */

      print("📷 Camera initialized");

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print("Camera error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              _startPoint = details.localPosition;
              _box = Rect.fromLTWH(_startPoint!.dx, _startPoint!.dy, 0, 0);
            },
            onPanUpdate: (details) {
              final currentPoint = details.localPosition;
              setState(() {
                _box = Rect.fromPoints(_startPoint!, currentPoint);
              });
            },
            onPanEnd: (details) {
              if (_box != null) {
                final size = MediaQuery.of(context).size;
                final x = _box!.left / size.width;
                final y = _box!.top / size.height;
                final w = _box!.width / size.width;
                final h = _box!.height / size.height;

                print('📦 Box Drawn: x=$x, y=$y, w=$w, h=$h');
              }
            },
            child: Stack(
              children: [
                // Camera Preview
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.previewSize?.width ?? 0,
                    height: _controller.value.previewSize?.height ?? 0,
                    child: CameraPreview(_controller),
                  ),
                ),
                // Draw Box Overlay
                if (_box != null)
                  Positioned(
                    left: _box!.left,
                    top: _box!.top,
                    child: Container(
                      width: _box!.width,
                      height: _box!.height,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
