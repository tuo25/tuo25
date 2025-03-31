import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/tflite_service.dart'; // Ensure this path matches where you saved it

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late CameraController _controller;
  final TFLiteService _tfliteService = TFLiteService();
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _tfliteService.loadModel();
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.medium);

    await _controller.initialize();
    if (!mounted) return;

    setState(() {});

    _controller.startImageStream((CameraImage image) async {
      if (_isDetecting) return;

      _isDetecting = true;

      _tfliteService.runModelOnFrame(image); // 👈 Process the frame

      _isDetecting = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(body: CameraPreview(_controller));
  }
}
