import 'package:flutter/material.dart';

// Clipper personalizado para recortar apenas a área selecionada
class ImageMaskClipper extends CustomClipper<Path> {
  final double left;
  final double top;
  final double width;
  final double height;

  ImageMaskClipper({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(left, top, width, height));
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
} 