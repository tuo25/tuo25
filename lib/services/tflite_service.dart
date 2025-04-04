import 'package:tflite_flutter_local/tflite_flutter.dart';
import 'package:flutter/services.dart'; // Added for rootBundle
import 'package:camera/camera.dart'; // Added for CameraImage
import 'package:image/image.dart' as img; // Added for img.Image

enum ResizeMethod { bilinear, nearest }

class ResizeOp {
  final int targetHeight;
  final int targetWidth;
  final ResizeMethod method;

  ResizeOp(this.targetHeight, this.targetWidth, this.method);
}

class ImageProcessor {
  final List<ResizeOp> operations;

  ImageProcessor(this.operations);

  TensorImage process(TensorImage input) {
    return input; // Stubbed out
  }
}

class ImageProcessorBuilder {
  final List<ResizeOp> _ops = [];

  ImageProcessorBuilder add(ResizeOp op) {
    _ops.add(op);
    return this;
  }

  ImageProcessor build() {
    return ImageProcessor(_ops);
  }
}

class TFLiteService {
  late Interpreter _interpreter;
  List<String> _labels = [];

  Future<void> loadModel() async {
    try {
      // Load labels
      final labelData = await rootBundle.loadString(
        'assets/models/labelmap.txt',
      );
      _labels = labelData.split('\n').where((e) => e.isNotEmpty).toList();

      // Load model
      _interpreter = await Interpreter.fromAsset('detect.tflite');
      _interpreter.allocateTensors();

      print('✅ Model & labels loaded successfully');
      print('Labels: $_labels');
    } catch (e) {
      print('❌ Failed to load model: $e');
    }
  }

  List<String> get labels => _labels;

  void runModelOnFrame(CameraImage image) {
    final inputImage = _convertCameraImage(image);
    if (inputImage == null) return;

    // Model input shape
    var inputShape = _interpreter.getInputTensor(0).shape;
    var inputSize = inputShape[1]; // Assuming square input

    // Resize input
    ImageProcessor imageProcessor =
        ImageProcessorBuilder()
            .add(ResizeOp(inputSize, inputSize, ResizeMethod.bilinear))
            .build();
    TensorImage tensorImage = imageProcessor.process(inputImage);

    // Create output buffer
    TensorBuffer outputLocations = TensorBuffer.createFixedSize(
      [1, 10, 4], // Example shape for bounding boxes
      TfLiteType.float32, // Replace with the correct constant or define it
    );
    TensorBuffer outputClasses = TensorBuffer.createFixedSize(
      [1, 10], // Example shape for class indices
      TfLiteType.float32,
    );
    TensorBuffer outputScores = TensorBuffer.createFixedSize(
      [1, 10], // Example shape for confidence scores
      TfLiteType.float32,
    );
    TensorBuffer numDetections = TensorBuffer.createFixedSize(
      [1], // Example shape for number of detections
      TfLiteType.float32,
    );
    // Run inference
    final outputs = {
      0: outputLocations.getBuffer(),
      1: outputClasses.getBuffer(),
      2: outputScores.getBuffer(),
      3: numDetections.getBuffer(),
    };

    _interpreter.runForMultipleInputs([tensorImage.buffer], outputs);

    // Print detections
    final scores = outputScores.getDoubleList();
    final classes = outputClasses.getDoubleList();

    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > 0.5) {
        final labelIndex = classes[i].toInt();
        final label = _labels[labelIndex];
        print("🧠 Detected: $label (${(scores[i] * 100).toStringAsFixed(1)}%)");
      }
    }
  }

  TensorImage? _convertCameraImage(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;

      // Convert YUV420 to RGB image
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;

      final img.Image imgRGB = img.Image(width, height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);

          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];

          int r = (yp + 1.370705 * (vp - 128)).round();
          int g = (yp - 0.337633 * (up - 128) - 0.698001 * (vp - 128)).round();
          int b = (yp + 1.732446 * (up - 128)).round();

          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          imgRGB.setPixel(x, y, img.getColor(r, g, b));
        }
      }

      final img.Image resizedImage = img.copyResize(
        imgRGB,
        width: 300,
        height: 300,
      );

      TensorImage tensorImage = TensorImage(TfLiteType.uint8);
      tensorImage.loadImage(resizedImage);
      return tensorImage;
    } catch (e) {
      print("❌ Error converting CameraImage to RGB: $e");
      return null;
    }
  }
}

class TfLiteType {
  static const float32 = TfLiteType._(
    'float32',
  ); // Define float32 as a TfLiteType instance
  static const uint8 = TfLiteType._(
    'uint8',
  ); // Define uint8 as a TfLiteType instance

  final String name;

  const TfLiteType._(this.name);

  @override
  String toString() => name;
}

class TensorImage {
  final TfLiteType type;
  late img.Image _image;

  TensorImage(this.type);

  void loadImage(img.Image image) {
    _image = image;
  }

  TensorBuffer get buffer {
    // Convert _image to TensorBuffer (implementation depends on your use case)
    return TensorBuffer.createFixedSize([_image.width, _image.height, 3], type);
  }
}

class TensorBuffer {
  final List<int> shape;
  final TfLiteType type;
  late List<double> _buffer;

  TensorBuffer._(this.shape, this.type) {
    _buffer = List.filled(shape.reduce((a, b) => a * b), 0.0);
  }

  static TensorBuffer createFixedSize(List<int> shape, TfLiteType type) {
    return TensorBuffer._(shape, type);
  }

  List<double> getBuffer() {
    return _buffer;
  }

  List<double> getDoubleList() {
    return _buffer;
  }
}
