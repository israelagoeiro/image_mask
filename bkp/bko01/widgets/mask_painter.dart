import 'package:flutter/material.dart';

// CustomPainter para desenhar a borda e os handles
class MaskPainter extends CustomPainter {
  final double left;
  final double top;
  final double width;
  final double height;
  final double handleSize;
  final Color borderColor = const Color(0xFF558EF0);

  MaskPainter({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.handleSize = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = false;

    // Desenha o retângulo da seleção
    final rect = Rect.fromLTWH(left, top, width, height);
    canvas.drawRect(rect, paint);

    // Desenha os 8 pontos de controle (handles)
    _drawHandle(canvas, left, top); // leftTop
    _drawHandle(canvas, left + width, top); // rightTop
    _drawHandle(canvas, left, top + height); // leftBottom
    _drawHandle(canvas, left + width, top + height); // rightBottom
    _drawHandle(canvas, left + width / 2, top); // centerTop
    _drawHandle(canvas, left + width / 2, top + height); // centerBottom
    _drawHandle(canvas, left, top + height / 2); // leftCenter
    _drawHandle(canvas, left + width, top + height / 2); // rightCenter
  }

  void _drawHandle(Canvas canvas, double x, double y) {
    // Quadrado branco preenchido
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Borda azul
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final halfSize = handleSize / 2;
    final handleRect = Rect.fromCenter(center: Offset(x, y), width: handleSize, height: handleSize);
    canvas.drawRect(handleRect, fillPaint);
    canvas.drawRect(handleRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 