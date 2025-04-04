import 'package:flutter/services.dart';

Future<List<String>> loadLabels(String assetPath) async {
  final rawLabels = await rootBundle.loadString(assetPath);
  final lines = rawLabels.split('\n');
  return lines
      .map((label) => label.trim())
      .where(
        (label) => label.isNotEmpty && label != '???',
      ) // Filter out empty lines and '???'
      .toList();
}
