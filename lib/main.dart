import 'package:flutter/material.dart';
import 'package:image_mask/image_mask_editor.dart';


void main() {
  runApp(const ImageMaskMain());
}

class ImageMaskMain extends StatelessWidget {
  const ImageMaskMain({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ImageMaskEditor(),
      ),
    );
  }
}






