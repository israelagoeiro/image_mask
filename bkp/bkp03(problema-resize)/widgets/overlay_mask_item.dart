import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mask_config.dart';
import '../utils/anchor_point.dart';
import 'mask_clipper.dart';
import 'mask_painter.dart';

class OverlayMaskItem extends StatelessWidget {
  final MaskConfig maskConfig;
  final double scaleFactor;
  final AssetImage imageAsset;
  final Offset? initialMousePosition;
  final Offset? currentMousePosition;
  final bool isDragging;
  final bool isSelected;
  final Function(DragUpdateDetails, double) onUpdatePosition;
  final Function(DragEndDetails) onResetMousePosition;
  final Function(DragUpdateDetails, {bool left, bool right, bool top, bool bottom, required AnchorPoint anchorPoint, required double scaleFactor}) onUpdateSize;
  final Widget Function(double deltaX, double deltaY) buildDialogMetric;
  final VoidCallback onSelect;

  const OverlayMaskItem({
    Key? key,
    required this.maskConfig,
    required this.scaleFactor,
    required this.imageAsset,
    this.initialMousePosition,
    this.currentMousePosition,
    required this.isDragging,
    required this.isSelected,
    required this.onUpdatePosition,
    required this.onResetMousePosition,
    required this.onUpdateSize,
    required this.buildDialogMetric,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Cálculo dos deltas para o tooltip
    double deltaX = 0;
    double deltaY = 0;
    if (initialMousePosition != null && currentMousePosition != null) {
      deltaX = (currentMousePosition!.dx - initialMousePosition!.dx) / scaleFactor;
      deltaY = (currentMousePosition!.dy - initialMousePosition!.dy) / scaleFactor;
    }

    return Stack(
      children: [
        // Área clicável mais ampla para melhor experiência de seleção
        Positioned(
          left: maskConfig.left * scaleFactor - 10,
          top: maskConfig.top * scaleFactor - 10,
          width: maskConfig.width * scaleFactor + 20,
          height: maskConfig.height * scaleFactor + 20,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onSelect,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // Área de máscara que mostra a imagem original
        ClipPath(
          clipper: MaskClipper(
            left: maskConfig.left * scaleFactor,
            top: maskConfig.top * scaleFactor,
            width: maskConfig.width * scaleFactor,
            height: maskConfig.height * scaleFactor,
          ),
          child: Image(
            image: imageAsset,
            fit: BoxFit.contain,
          ),
        ),

        // Retângulo e handles de controle
        CustomPaint(
          painter: MaskPainter(
            left: maskConfig.left * scaleFactor,
            top: maskConfig.top * scaleFactor,
            width: maskConfig.width * scaleFactor,
            height: maskConfig.height * scaleFactor,
            handleSize: 8 * scaleFactor,
            isSelected: isSelected,
          ),
          child: Container(),
        ),

        // Área de arraste no centro - separada dos handles para não interferir
        Positioned(
          left: maskConfig.left * scaleFactor + 20,
          top: maskConfig.top * scaleFactor + 20,
          width: maskConfig.width * scaleFactor - 40,
          height: maskConfig.height * scaleFactor - 40,
          child: GestureDetector(
            onTap: onSelect,
            onPanUpdate: isSelected 
                ? (details) => onUpdatePosition(details, scaleFactor) 
                : null,
            onPanEnd: isSelected ? onResetMousePosition : null,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // Handles de redimensionamento - só visíveis quando selecionado
        if (isSelected) ..._buildResizeHandles(),

        // Indicador de tamanho ou delta de arraste - só visível quando selecionado e arrastando
        if (isSelected && currentMousePosition != null)
          Positioned(
            left: currentMousePosition!.dx + 20,
            top: currentMousePosition!.dy - 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 3,
              ),
              child: buildDialogMetric(deltaX, deltaY),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildResizeHandles() {
    // Tamanho do handle de redimensionamento
    final handleSize = 9.0 * scaleFactor;
    final hitBoxSize = 24.0 * scaleFactor; // Área maior para interação
    final halfHitBoxSize = hitBoxSize / 2;

    // Posições escaladas
    final left = maskConfig.left * scaleFactor;
    final top = maskConfig.top * scaleFactor;
    final width = maskConfig.width * scaleFactor;
    final height = maskConfig.height * scaleFactor;

    return [
      // Canto superior esquerdo
      _buildHandle(
        left - halfHitBoxSize,
        top - halfHitBoxSize,
        hitBoxSize,
        (details) => onUpdateSize(
          details, 
          left: true, 
          top: true, 
          right: false, 
          bottom: false,
          anchorPoint: AnchorPoint.leftTop, 
          scaleFactor: scaleFactor
        ),
        SystemMouseCursors.resizeUpLeftDownRight,
      ),

      // Canto superior direito
      _buildHandle(
        left + width - halfHitBoxSize,
        top - halfHitBoxSize,
        hitBoxSize,
        (details) => onUpdateSize(
          details, 
          left: false, 
          right: true, 
          top: true, 
          bottom: false,
          anchorPoint: AnchorPoint.rightTop, 
          scaleFactor: scaleFactor
        ),
        SystemMouseCursors.resizeUpRightDownLeft,
      ),

      // Canto inferior esquerdo
      _buildHandle(
        left - halfHitBoxSize,
        top + height - halfHitBoxSize,
        hitBoxSize,
        (details) => onUpdateSize(
          details, 
          left: true, 
          right: false, 
          top: false, 
          bottom: true,
          anchorPoint: AnchorPoint.leftBottom, 
          scaleFactor: scaleFactor
        ),
        SystemMouseCursors.resizeUpRightDownLeft,
      ),

      // Canto inferior direito
      _buildHandle(
        left + width - halfHitBoxSize,
        top + height - halfHitBoxSize,
        hitBoxSize,
        (details) => onUpdateSize(
          details, 
          left: false, 
          right: true, 
          top: false, 
          bottom: true,
          anchorPoint: AnchorPoint.rightBottom, 
          scaleFactor: scaleFactor
        ),
        SystemMouseCursors.resizeUpLeftDownRight,
      ),

      // Centro superior
      _buildHandle(
        left + (width / 2) - halfHitBoxSize,
        top - halfHitBoxSize,
        hitBoxSize,
        (details) => onUpdateSize(
          details, 
          left: false, 
          right: false, 
          top: true, 
          bottom: false,
          anchorPoint: AnchorPoint.centerTop, 
          scaleFactor: scaleFactor
        ),
        SystemMouseCursors.resizeUpDown,
      ),

      // Centro inferior
      _buildHandle(
        left + (width / 2) - halfHitBoxSize,
        top + height - halfHitBoxSize,
        hitBoxSize,
        (details) => onUpdateSize(
          details, 
          left: false, 
          right: false, 
          top: false, 
          bottom: true,
          anchorPoint: AnchorPoint.centerBottom, 
          scaleFactor: scaleFactor
        ),
        SystemMouseCursors.resizeUpDown,
      ),

      // Esquerda centro
      _buildHandle(
        left - halfHitBoxSize,
        top + (height / 2) - halfHitBoxSize,
        hitBoxSize,
        (details) => onUpdateSize(
          details, 
          left: true, 
          right: false, 
          top: false, 
          bottom: false,
          anchorPoint: AnchorPoint.leftCenter, 
          scaleFactor: scaleFactor
        ),
        SystemMouseCursors.resizeLeftRight,
      ),

      // Direita centro
      _buildHandle(
        left + width - halfHitBoxSize,
        top + (height / 2) - halfHitBoxSize,
        hitBoxSize,
        (details) => onUpdateSize(
          details, 
          left: false, 
          right: true, 
          top: false, 
          bottom: false,
          anchorPoint: AnchorPoint.rightCenter, 
          scaleFactor: scaleFactor
        ),
        SystemMouseCursors.resizeLeftRight,
      ),
    ];
  }

  Widget _buildHandle(
    double left, 
    double top, 
    double size, 
    void Function(DragUpdateDetails) onPanUpdate,
    [MouseCursor cursor = MouseCursor.defer]
  ) {
    return Positioned(
      left: left,
      top: top,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            // Início do redimensionamento
          },
          onPanUpdate: onPanUpdate,
          onPanEnd: onResetMousePosition,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: Colors.transparent,
                width: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 