import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../helper/image_classification_helper.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  ImageClassificationHelper? imageClassificationHelper;
  final imagePicker = ImagePicker();
  String? imagePath;
  img.Image? image;
  Map<String, double>? classification;
  bool cameraIsAvailable = Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    imageClassificationHelper = ImageClassificationHelper();
    imageClassificationHelper!.initHelper();
    super.initState();
  }

  // Clean old results when press some take picture button
  void cleanResult() {
    imagePath = null;
    image = null;
    classification = null;
    setState(() {});
  }

  // Process picked image
  Future<void> processImage() async {
    if (imagePath != null) {
      // Read image bytes from file
      final imageData = File(imagePath!).readAsBytesSync();

      // Decode image using package:image/image.dart (https://pub.dev/image)
      image = img.decodeImage(imageData);
      setState(() {});
      classification = await imageClassificationHelper?.inferenceImage(image!);
      debugPrint("${classification.toString()} ");
      setState(() {});
    }
  }

  @override
  void dispose() {
    imageClassificationHelper?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (cameraIsAvailable)
                TextButton.icon(
                  onPressed: () async {
                    cleanResult();
                    final result = await imagePicker.pickImage(
                      source: ImageSource.camera,
                    );

                    imagePath = result?.path;
                    setState(() {});
                    processImage();
                  },
                  icon: const Icon(
                    Icons.camera,
                    size: 48,
                  ),
                  label: const Text("Take a photo"),
                ),
              TextButton.icon(
                onPressed: () async {
                  cleanResult();
                  final result = await imagePicker.pickImage(
                    source: ImageSource.gallery,
                  );

                  imagePath = result?.path;
                  setState(() {});
                  processImage();
                },
                icon: const Icon(
                  Icons.photo,
                  size: 48,
                ),
                label: const Text("Pick from gallery"),
              ),
            ],
          ),
          const Divider(color: Colors.black),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Image container
                  Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Visibility(
                      visible: imagePath != null,
                      replacement: Center(
                        child: Icon(
                          Icons.photo,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(imagePath ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Image info
                  if (image != null)
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageClassificationHelper?.inputTensor != null)
                            Text(
                              'Input: (shape: ${imageClassificationHelper?.inputTensor.shape} type: '
                              '${imageClassificationHelper?.inputTensor.type})',
                              style: const TextStyle(fontSize: 14),
                            ),
                          if (imageClassificationHelper?.outputTensor != null)
                            Text(
                              'Output: (shape: ${imageClassificationHelper?.outputTensor.shape} '
                              'type: ${imageClassificationHelper?.outputTensor.type})',
                              style: const TextStyle(fontSize: 14),
                            ),
                          const SizedBox(height: 8),
                          Text('Num channels: ${image?.numChannels}'),
                          Text('Bits per channel: ${image?.bitsPerChannel}'),
                          Text('Height: ${image?.height}'),
                          Text('Width: ${image?.width}'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Classification result
                  if (classification != null)
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: (classification!.entries.toList()
                              ..sort((a, b) => b.value.compareTo(
                                  a.value))) // Sort by descending value
                            .take(3) // Take the top 3 entries
                            .map((e) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "${(e.value * 100).toStringAsFixed(2)}%",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
