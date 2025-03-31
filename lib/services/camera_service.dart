import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];

Future<CameraController> initializeCamera() async {
  cameras = await availableCameras();
  CameraController controller = CameraController(
    cameras.first,
    ResolutionPreset.high,
  );
  await controller.initialize();
  return controller;
}
