import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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

  CameraMode _selectedMode = CameraMode.video; // Start in video mode
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio:
          _selectedMode == CameraMode.video, // Enable audio for video mode
    );

    try {
      await _controller.initialize();

      // Set custom zoom range (1x to 5x)
      _minZoom = 1.0;
      _maxZoom = 5.0;

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera error: $e");
    }
  }

  Future<void> _switchCameraMode(CameraMode newMode) async {
    if (_selectedMode == newMode || !_isCameraInitialized) return;

    setState(() {
      _isCameraInitialized = false;
    });

    try {
      // Stop recording if switching from video while recording
      if (_isRecording) {
        await _controller.stopVideoRecording();
        setState(() => _isRecording = false);
      }

      // Dispose the previous controller before creating a new one
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
      setState(() {
        _isCameraInitialized = true; // Ensure the UI doesn't freeze
      });
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

  void _onCapturePressed() async {
    if (_controller.value.isInitialized) {
      try {
        final XFile file = await _controller.takePicture();
        print("Picture saved to: ${file.path}");
        // You can add logic to display or save the captured image
      } catch (e) {
        print("Error capturing picture: $e");
      }
    }
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
                    : const Center(
                      child: CircularProgressIndicator(),
                    ), // Show loading indicator
          ),
          // Record/Capture Button
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
                    color:
                        _selectedMode == CameraMode.video
                            ? (_isRecording ? Colors.red : Colors.white)
                            : Colors.white,
                  ),
                  child: Center(
                    child:
                        _selectedMode == CameraMode.video
                            ? (_isRecording
                                ? const Icon(
                                  Icons.stop,
                                  color: Colors.white,
                                  size: 30,
                                )
                                : const Icon(
                                  Icons.videocam,
                                  color: Colors.black,
                                  size: 30,
                                ))
                            : const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 30,
                            ),
                  ),
                ),
              ),
            ),
          ),
          // Toggle Button
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
