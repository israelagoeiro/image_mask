import 'package:flutter/material.dart';
import 'widgets/overlay_mask_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: OverlayMaskPosition(),
        ),
      ),
    );
  }
}
