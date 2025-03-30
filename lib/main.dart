import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tuo_app/services/tflite_service.dart';
import 'dart:io';
import 'dart:async';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraHome(),
    );
  }
}

class CameraHome extends StatefulWidget {
  const CameraHome({super.key});

  @override
  State<CameraHome> createState() => _CameraHomeState();
}

class _CameraHomeState extends State<CameraHome> {
  late CameraController _controller;
  bool _isCameraInitialized = false;

  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  CameraMode _selectedMode = CameraMode.video;
  bool _isRecording = false;

  Offset? _tapPosition;
  bool _showFocusCircle = false;

  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  bool _isConnectedToTUO = false;

  final TFLiteService _tfliteService = TFLiteService();

  @override
  void initState() {
    super.initState();
    _setupCamera();
    _tfliteService.loadModel(); // 👈 Load the model
  }

  Future<void> _setupCamera() async {
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.max,
      enableAudio: _selectedMode == CameraMode.video,
    );

    try {
      await _controller.initialize();
      _minZoom = 1.0;
      _maxZoom = 5.0;

      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      print("Camera error: $e");
    }
  }

  Future<void> _switchCameraMode(CameraMode newMode) async {
    if (_selectedMode == newMode || !_isCameraInitialized) return;

    setState(() => _isCameraInitialized = false);

    try {
      if (_isRecording) {
        await _controller.stopVideoRecording();
        setState(() => _isRecording = false);
      }

      await _controller.dispose();

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.max,
        enableAudio: newMode == CameraMode.video,
      );

      await _controller.initialize();

      setState(() {
        _selectedMode = newMode;
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Error switching camera mode: $e');
      setState(() => _isCameraInitialized = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) async {
    double newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    _currentZoom = newZoom;
    await _controller.setZoomLevel(_currentZoom);
  }

  void _onTapToFocus(TapDownDetails details) async {
    if (!_controller.value.isInitialized) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPoint = box.globalToLocal(details.globalPosition);

    final double dx = localPoint.dx / box.size.width;
    final double dy = localPoint.dy / box.size.height;

    final Offset point = Offset(dx, dy);

    try {
      await _controller.setFocusPoint(point);
      await _controller.setExposurePoint(point);
      print('🔍 Focus & exposure set to $point');
    } catch (e) {
      print('❌ Failed to set focus: $e');
    }

    _showFocusIndicator(localPoint);
  }

  void _showFocusIndicator(Offset offset) {
    setState(() {
      _tapPosition = offset;
      _showFocusCircle = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _showFocusCircle = false);
    });
  }

  void _startRecordTimer() {
    _recordTimer?.cancel();
    _recordDuration = Duration.zero;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration += const Duration(seconds: 1);
      });
    });
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
    setState(() {
      _recordDuration = Duration.zero;
    });
  }

  void _onCapturePressed() async {
    if (!_controller.value.isInitialized) return;

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      print('Permission not granted. Opening settings...');
      await PhotoManager.openSetting();
      return;
    }

    try {
      if (_selectedMode == CameraMode.photo) {
        final XFile file = await _controller.takePicture();
        print("📸 Picture saved to: ${file.path}");

        await PhotoManager.editor.saveImageWithPath(file.path);
        print('✅ Photo saved to gallery!');
      } else {
        if (_isRecording) {
          final XFile videoFile = await _controller.stopVideoRecording();
          setState(() => _isRecording = false);
          _stopRecordTimer();

          print("🎥 Video saved to: ${videoFile.path}");

          await PhotoManager.editor.saveVideo(File(videoFile.path));
          print('✅ Video saved to gallery!');
        } else {
          await _controller.prepareForVideoRecording();
          await _controller.startVideoRecording();
          setState(() => _isRecording = true);
          _startRecordTimer();
        }
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  void _toggleBluetoothConnection() {
    setState(() {
      _isConnectedToTUO = !_isConnectedToTUO;
    });

    if (_isConnectedToTUO) {
      print("🔷 Connected to TUO");
      // TODO: Trigger real Bluetooth connect
    } else {
      print("❌ Disconnected from TUO");
      // TODO: Trigger real Bluetooth disconnect
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child:
                _isCameraInitialized
                    ? GestureDetector(
                      onTapDown: (TapDownDetails details) {
                        _onTapToFocus(details);
                        _showFocusIndicator(details.globalPosition);
                      },
                      onScaleStart: _handleScaleStart,
                      onScaleUpdate: _handleScaleUpdate,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller.value.previewSize?.width ?? 0,
                          height: _controller.value.previewSize?.height ?? 0,
                          child: CameraPreview(_controller),
                        ),
                      ),
                    )
                    : const Center(child: CircularProgressIndicator()),
          ),
          if (_showFocusCircle && _tapPosition != null)
            Positioned(
              left: _tapPosition!.dx - 20,
              top: _tapPosition!.dy - 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.yellow, width: 2),
                ),
              ),
            ),
          if (_isRecording)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatDuration(_recordDuration),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _onCapturePressed,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Icon(
                      _selectedMode == CameraMode.video
                          ? (_isRecording ? Icons.stop : Icons.videocam)
                          : Icons.camera_alt,
                      color:
                          _selectedMode == CameraMode.video && _isRecording
                              ? Colors.white
                              : Colors.black,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: 20,
            child: GestureDetector(
              onTap: _toggleBluetoothConnection,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _isConnectedToTUO
                          ? Colors.green
                          : Colors.black.withOpacity(0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _isConnectedToTUO
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap:
                  _isCameraInitialized
                      ? () {
                        final newMode =
                            _selectedMode == CameraMode.photo
                                ? CameraMode.video
                                : CameraMode.photo;
                        _switchCameraMode(newMode);
                      }
                      : null,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: Icon(
                  _selectedMode == CameraMode.photo
                      ? Icons.videocam
                      : Icons.camera_alt,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum CameraMode { photo, video }
