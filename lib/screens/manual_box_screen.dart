import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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
    _controller = CameraController(_cameras[0], ResolutionPreset.high);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    setState(() {
      _startPoint = details.focalPoint;
      _box = Rect.fromLTWH(
        _startPoint!.dx,
        _startPoint!.dy,
        0,
        0,
      ); // 💥 Initialize box
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final currentPoint = details.focalPoint;
    setState(() {
      _box = Rect.fromPoints(_startPoint!, currentPoint); // 💥 Update box
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_box != null) {
      final size = MediaQuery.of(context).size;
      final x = _box!.left / size.width;
      final y = _box!.top / size.height;
      final w = _box!.width / size.width;
      final h = _box!.height / size.height;

      print('📦 Box Drawn: x=$x, y=$y, w=$w, h=$h');

      // TODO: Send these values to TUO tracking logic
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
          CameraPreview(_controller),
          GestureDetector(
            behavior: HitTestBehavior.opaque, // 💥 Ensure touches are detected
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            onDoubleTap:
                () => setState(() => _box = null), // 💥 Reset box on double-tap
            child: Stack(
              children: [
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
