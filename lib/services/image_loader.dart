import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

Future<TensorImage> loadTestImage() async {
  final byteData = await rootBundle.load('assets/images/test.jpg');
  final imageBytes = byteData.buffer.asUint8List();
  final decodedImage = img.decodeImage(imageBytes)!;

  TensorImage inputImage = TensorImage.fromImage(decodedImage);
  inputImage = ImageProcessorBuilder()
      .add(ResizeOp(300, 300, ResizeMethod.nearestNeighbor))
      .build()
      .process(inputImage);

  return inputImage;
}
